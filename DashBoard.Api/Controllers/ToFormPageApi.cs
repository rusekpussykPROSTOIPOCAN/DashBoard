using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Text.Json;
using static DashBoard.Lib.DTOs.AddWorkProgressRequest;
namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api")]
    [IgnoreAntiforgeryToken]
    public class ToFormPageApi : BaseController
    {
        public ToFormPageApi(dashboardContext dashboard) : base(dashboard)
        {
        }
        [HttpGet("articles")]
        public async Task<IActionResult> GetArticles()
        {
            var article = await _dashboard.articles.ToListAsync();
            return Ok(article);
        }
        [HttpGet("sources")]
        public async Task<IActionResult> GetSourse()
        {
            var sourse = await _dashboard.sourses.ToListAsync();
            return Ok(sourse);
        }
        [HttpPost("form")]
        public async Task<IActionResult> AddForm([FromBody] AddWorkProgressRequest request)
        {
            try
            {
                

                if (request == null)
                {
                    return BadRequest("Request is null");
                }

                if (request.IdSourse == 0)
                {
                    return BadRequest("No source");
                }

                if (request.Violations == null || request.Violations.Count == 0)
                {
                    return BadRequest("No Violations");
                }

                var violationsJson = JsonSerializer.Serialize(request.Violations);
                var result = await _dashboard
    .Set<AddWorkProgressResult>()
    .FromSqlRaw(@"
        SELECT * FROM add_work_progress_simple(
            {0}, {1}, {2}, {3}, {4}, {5}::jsonb
        )",
        request.IdSourse,
        request.AllPerimeter,
        request.CompletePerimeter,
        request.RemainedPerimeter,
        request.Comment,
        JsonSerializer.Serialize(request.Violations)
    )
    .AsNoTracking()
    .FirstOrDefaultAsync();





                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return StatusCode(500, ex.Message);
            }
        }
    }
}
