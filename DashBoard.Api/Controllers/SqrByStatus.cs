
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SqrByStatus:BaseController
    {
        public SqrByStatus(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet]
        public async Task<IActionResult> GetSqrByStatus()
        {
           var result = await _dashboard.overfly_block2s.Include(o => o.id_statusNavigation)
                .Where(o => o.id_statusNavigation.name != "ОТМЕНЕНА КАК ДУБЛЬ")
                .GroupBy(o => o.id_statusNavigation.name)
                .Select(g => new StatusSquare
                {
                    Name = g.Key,
                    Squer = (double)(g.Sum(x => x.square) / 1000000)
                }).ToListAsync();
            return Ok(result);
        }
    }
}
