using DashBoard.Lib.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/robot-delete")]
    public class DeleteRobot : BaseController
    {
        public DeleteRobot(dashboardContext dashboard) : base(dashboard)
        {

        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRobots(int id)
        {
            var robot = await _dashboard.robots.FirstOrDefaultAsync(x=>x.id== id);
            if (robot == null)
                return NotFound();
            _dashboard.robots.Remove(robot);
            await _dashboard.SaveChangesAsync();

            return Ok();
        }
    }
}
