using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api")]
    public class ToAnaliticPageApi : BaseController
    {
        public ToAnaliticPageApi(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet("getTableAnalitic")]
        public async Task<IActionResult> GetDashboardData(
            DateTime? dateFrom = null,
            DateTime? dateTo = null,
            int? year = null,
            int? month = null,
            int? quarter = null)
        {
            try
            {
                var query = _dashboard.work_progresses
                    .Include(wp => wp.id_sourseNavigation)
                    .Include(wp => wp.work_progress_violations)
                        .ThenInclude(v => v.id_articleNavigation)
                    .Where(wp => wp.created_at.HasValue)
                    .AsQueryable();

                if (dateFrom.HasValue)
                    query = query.Where(wp => wp.created_at >= dateFrom.Value);

                if (dateTo.HasValue)
                    query = query.Where(wp => wp.created_at <= dateTo.Value);

                if (year.HasValue)
                    query = query.Where(wp => wp.created_at.Value.Year == year.Value);

                if (month.HasValue)
                    query = query.Where(wp => wp.created_at.Value.Month == month.Value);

                if (quarter.HasValue)
                {
                    var startMonth = (quarter.Value - 1) * 3 + 1;
                    var endMonth = startMonth + 2;
                    query = query.Where(wp => wp.created_at.Value.Month >= startMonth &&
                                             wp.created_at.Value.Month <= endMonth);
                }

                var workProgresses = await query.ToListAsync();

                var perimeterBySource = workProgresses
                    .GroupBy(wp => wp.id_sourseNavigation?.source ?? "Неизвестно")
                    .Select(g => new PerimeterBySourceDto
                    {
                        Source = g.Key,
                        Sum = g.Sum(wp => wp.all_perimeter ?? 0)
                    })
                    .ToList();

                var dailyStats = workProgresses
                    .GroupBy(wp => wp.created_at?.Date)
                    .Select(g => new DailyStatsDto
                    {
                        Date = g.Key,
                        AllPerimeter = g.Sum(wp => wp.all_perimeter ?? 0),
                        CompletePerimeter = g.Sum(wp => wp.complete_perimeter ?? 0),
                        RemainedPerimeter = g.Sum(wp => wp.remained_perimeter ?? 0)
                    })
                    .OrderBy(d => d.Date)
                    .ToList();

                var violations = workProgresses
                    .SelectMany(wp => wp.work_progress_violations, (wp, v) => new ViolationDto
                    {
                        WorkProgressId = wp.id,
                        ArticleId = v.id_article ?? 0,
                        Article = v.id_articleNavigation?.article1 ?? "Неизвестно",
                        ObjectAWeek = v.object_a_week ?? 0,
                        NewViolations = v.new_violations ?? 0,
                        OldViolations = v.old_violations ?? 0
                    })
                    .ToList();

                var result = new AnaliticPageDTO
                {
                    PerimeterBySource = perimeterBySource,
                    DailyStats = dailyStats,
                    Violations = violations
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка при получении данных: {ex.Message}");
            }
        }
    }
}