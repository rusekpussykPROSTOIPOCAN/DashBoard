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
            try
            {
                var robot = await _dashboard.robots
                    .FirstOrDefaultAsync(r => r.id == id);

                if (robot == null)
                    return NotFound($"Робот с ID {id} не найден");
                var analityc = await _dashboard.robots_analitics.Where(x => x.idrobots == id).ToListAsync();
                if(analityc != null)
                {
                    _dashboard.robots_analitics.RemoveRange(analityc);
                }
               var robots =  await _dashboard.robots.FindAsync(id);
                if(robots != null)
                _dashboard.robots.Remove(robots);

               await _dashboard.SaveChangesAsync();
                

                return Ok(new { message = "Робот успешно удален" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка при удалении: {ex.Message}");
            }
        }
    }
}