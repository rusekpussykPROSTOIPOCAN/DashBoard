using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/date-controller")]
    public class DateControllerToRobots : BaseController
    {
        public DateControllerToRobots(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet]
        public async Task<IActionResult> GetDate([FromQuery] int idRobot)
        {
            try
            {
                if (idRobot <= 0)
                    return BadRequest("Неверный ID робота");

                var result = await _dashboard.robots_analitics
                    .Where(o => o.idrobots == idRobot)
                    .Select(g => new RobotPeriods
                    {
                        Year = g.datestatistic.Year,
                        Month = g.datestatistic.Month
                    })
                    .Distinct()
                    .OrderBy(x => x.Year)
                    .ThenBy(x => x.Month)
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