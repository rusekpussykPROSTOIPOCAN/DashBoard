using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/autocomplete-robots")]
    public class RobotsController : BaseController
    {
        public RobotsController(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet]
        public async Task<IActionResult> GetDetails(string? search)
        {
            try
            {
                var query = _dashboard.robots.AsQueryable();

                if (!string.IsNullOrWhiteSpace(search))
                {
                    query = query.Where(x => EF.Functions.ILike(x.name, $"%{search}%"));
                }

                var result = await query
                    .OrderBy(x => x.name)
                    .Select(x => new RobotDto
                    {
                        Id = x.id,
                        Name = x.name
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