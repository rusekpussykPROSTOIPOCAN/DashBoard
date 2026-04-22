using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ApplicatonsHomeDKN : BaseController
    {
        public ApplicatonsHomeDKN(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet]
        public async Task<IActionResult> GetApplications(int? year, int? month, int? quarter)
        {
            var result = await _dashboard.Set<ApplicationDKN>()
    .FromSqlRaw(@"
        SELECT r.name AS ""Name"", 
       SUM(count_application)::int AS ""CountApplications""
FROM public.robots_analitic ra 
LEFT JOIN robots r ON r.id = ra.idrobots 
WHERE 
    (@year::int IS NULL OR EXTRACT(YEAR FROM ra.datestatistic) = @year::int)
    AND (@month::int IS NULL OR EXTRACT(MONTH FROM ra.datestatistic) = @month::int)
    AND (@quarter::int IS NULL OR EXTRACT(QUARTER FROM ra.datestatistic) = @quarter::int)
    AND EXTRACT(DAY FROM ra.datestatistic) <> 31
GROUP BY r.name 
ORDER BY r.name;
    ",
    new NpgsqlParameter("year", year ?? (object)DBNull.Value),
    new NpgsqlParameter("month", month ?? (object)DBNull.Value),
    new NpgsqlParameter("quarter", quarter ?? (object)DBNull.Value)
)
.ToListAsync();
            return Ok(result);
        }
    }
}
