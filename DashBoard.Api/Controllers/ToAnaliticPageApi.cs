using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Data;
namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api")]
    
    public class ToAnaliticPageApi : BaseController
    {
        public ToAnaliticPageApi(dashboardContext dashboard) : base(dashboard)
        {
        }
        [HttpGet("export-analitic")]
        public async Task<IActionResult> ExportAnalitic(
     [FromServices] ExcelExportService excelService,
     int? year = null, int? month = null, int? quarter = null, DateTime? dateFrom = null, DateTime? dateTo = null)
        {
            try
            {
                var query = _dashboard.work_progresses
                    .Include(wp => wp.id_sourseNavigation)
                     .Include(wp => wp.CreatedByUser)
                    .Include(wp => wp.work_progress_violations)
                        .ThenInclude(v => v.id_articleNavigation)
                    .Where(wp => wp.created_at.HasValue)
                    .AsQueryable();
                if (dateFrom.HasValue && dateTo.HasValue)
                {
                    
                    query = query.Where(o => o.created_at.HasValue && o.created_at.Value >= dateFrom.Value && o.created_at.Value <= dateTo.Value);
                }
                else
                {
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

                }

                var workProgresses = await query.ToListAsync();

                var rows = new List<Dictionary<string, object>>();

                foreach (var wp in workProgresses)
                {
                    foreach (var v in wp.work_progress_violations)
                    {
                        rows.Add(new Dictionary<string, object>
                        {
                            ["Источник"] = wp.id_sourseNavigation?.source ?? "Неизвестно",
                            ["Статья"] = v.id_articleNavigation?.article1 ?? "Неизвестно",
                            ["Всего периметр"] = wp.all_perimeter ?? 0,
                            ["Выполнено"] = wp.complete_perimeter ?? 0,
                            ["Осталось"] = wp.remained_perimeter ?? 0,
                            ["За неделю"] = v.object_a_week ?? 0,
                            ["Новых"] = v.new_violations ?? 0,
                            ["Старых"] = v.old_violations ?? 0,
                            ["Дата"] = wp.created_at?.ToString("dd.MM.yyyy") ?? ""
                        });
                    }
                }

                var fileBytes = excelService.ExportToExcel(rows, "Аналитика");
                var base64 = Convert.ToBase64String(fileBytes);
                var fileName = $"analitic_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";

                return Ok(new { base64, fileName });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, innerError = ex.InnerException?.Message });
            }
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
                     .Include(wp => wp.CreatedByUser)
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
        OldViolations = v.old_violations ?? 0,
        CreatedByUser = wp.CreatedByUser?.FullName ?? "Неизвестно" 
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