using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

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
            var result = await _dashboard
    .Set<JsonResultDto>()
    .FromSqlRaw(
        @"SELECT get_dashboard_data(
                {0}::timestamp,
                {1}::timestamp,
                {2}::int,
                {3}::int,
                {4}::int
            ) AS ""Data""",
        dateFrom ?? (object)DBNull.Value,
        dateTo ?? (object)DBNull.Value,
        year ?? (object)DBNull.Value,
        month ?? (object)DBNull.Value,
        quarter ?? (object)DBNull.Value
    )
    .AsNoTracking()
    .FirstOrDefaultAsync();

            if (result?.Data == null || string.IsNullOrWhiteSpace(result.Data))
            {
                return Ok(new AnaliticPageDTO());
            }

            AnaliticPageDTO? data;

            try
            {
                data = JsonSerializer.Deserialize<AnaliticPageDTO>(
                    result.Data,
                    new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    }
                );
            }
            catch
            {
              
                return Ok(new AnaliticPageDTO());
            }

            return Ok(data ?? new AnaliticPageDTO());
        }
    }
}
