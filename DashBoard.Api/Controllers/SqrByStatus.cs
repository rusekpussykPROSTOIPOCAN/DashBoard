using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SqrByStatus : BaseController
    {
        public SqrByStatus(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet]
        public async Task<IActionResult> GetSqrByStatus(int? year = null, int? month = null, int? quarter = null)
        {
            try
            {
                var query = _dashboard.overfly_block2s
                    .Include(o => o.id_statusNavigation)
                    .Where(o => o.id_statusNavigation.name != "ОТМЕНЕНА КАК ДУБЛЬ")
                    .AsQueryable();

                if (year.HasValue)
                {
                    query = query.Where(o => o.date_get_materials.HasValue &&
                                          o.date_get_materials.Value.Year == year.Value);
                }

                if (month.HasValue)
                {
                    query = query.Where(o => o.date_get_materials.HasValue &&
                                          o.date_get_materials.Value.Month == month.Value);
                }

                if (quarter.HasValue)
                {
                    var startMonth = (quarter.Value - 1) * 3 + 1;
                    var endMonth = startMonth + 2;
                    query = query.Where(o => o.date_get_materials.HasValue &&
                                          o.date_get_materials.Value.Month >= startMonth &&
                                          o.date_get_materials.Value.Month <= endMonth);
                }

                var result = await query
                    .GroupBy(o => o.id_statusNavigation.name)
                    .Select(g => new StatusSquare
                    {
                        Name = g.Key,
                        Squer = (double)(g.Sum(x => x.square) / 1000000)
                    })
                    .ToListAsync();

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка: {ex.Message}");
            }
        }
    }
}