
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
        public async Task<List<RobotPeriods>> GetDate([FromQuery] int idRobot)
        {
            return await _dashboard.robots_analitics
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
        }
    }
}
