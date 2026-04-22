using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Text.Json;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RobotsUKONController : BaseController
    {
        public RobotsUKONController(dashboardContext dashboard) : base(dashboard)
        {
        }
        [HttpGet]
        public async Task<IActionResult> GetDetails(int? year, int? month, int? quarter)
        {
            var yearParam = new NpgsqlParameter<int?>("year", year);
            var monthParam = new NpgsqlParameter<int?>("month", month);
            var quarterParam = new NpgsqlParameter<int?>("quarter", quarter);

            // 1. УКОН проверки
            var checks = await _dashboard.Set<RobotUkon>()
                .FromSqlRaw("""
           SELECT 
            regexp_replace(key, '^УКОН по ', '') AS "Name",
            SUM(value::int) AS "Count"
        FROM public.robots_analitic ra
        CROSS JOIN LATERAL jsonb_each_text(
            ra.data_analize->'количество_проведенных_проверок'->'детали'
        )
        WHERE key LIKE 'УКОН%'
          AND (@year IS NULL OR EXTRACT(YEAR FROM ra.datestatistic) = @year::int)
          AND (@month IS NULL OR EXTRACT(MONTH FROM ra.datestatistic) = @month::int)
          AND (@quarter IS NULL OR EXTRACT(QUARTER FROM ra.datestatistic) = @quarter::int)
        GROUP BY regexp_replace(key, '^УКОН по ', '')
        ORDER BY 1;
        """, yearParam, monthParam, quarterParam)
                .AsNoTracking()
                .ToListAsync();

            // 2. Результаты проверок (без УКОН фильтра)
            var results = await _dashboard.Set<RobotUkon>()
                .FromSqlRaw("""
            SELECT 
                key AS "Name",
                SUM(value::int) AS "Count"
            FROM public.robots_analitic ra
            CROSS JOIN LATERAL jsonb_each_text(
                ra.data_analize->'результаты_проверок'->'детали'
            )
            WHERE (@year IS NULL OR EXTRACT(YEAR FROM ra.datestatistic) = @year::int)
              AND (@month IS NULL OR EXTRACT(MONTH FROM ra.datestatistic) = @month::int)
              AND (@quarter IS NULL OR EXTRACT(QUARTER FROM ra.datestatistic) = @quarter::int)
            GROUP BY key
            ORDER BY key;
        """, yearParam, monthParam, quarterParam)
                .AsNoTracking()
                .ToListAsync();

            // 3. Отчёты
            var reports = await _dashboard.Set<RobotUkon>()
                .FromSqlRaw("""
            SELECT 
                key AS "Name",
                SUM(value::int) AS "Count"
            FROM public.robots_analitic ra
            CROSS JOIN LATERAL jsonb_each_text(
                ra.data_analize->'количество_сформированных_отчетов'->'детали'
            )
            WHERE (@year IS NULL OR EXTRACT(YEAR FROM ra.datestatistic) = @year::int)
              AND (@month IS NULL OR EXTRACT(MONTH FROM ra.datestatistic) = @month::int)
              AND (@quarter IS NULL OR EXTRACT(QUARTER FROM ra.datestatistic) = @quarter::int)
            GROUP BY key
            ORDER BY key;
        """, yearParam, monthParam, quarterParam)
                .AsNoTracking()
                .ToListAsync();

            return Ok(new RobotsUKONDetails
            {
                Checks = checks,
                Results = results,
                Reports = reports
            });
        }
    }
   


}
