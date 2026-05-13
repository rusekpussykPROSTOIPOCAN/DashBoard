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

                // Деактивируем аналитики одним запросом (без загрузки в память)
                await _dashboard.robots_analitics
                    .Where(a => a.idrobots == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(a => a.isactive, false));

                return Ok(new { message = "Робот успешно удален" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка при удалении: {ex.Message}");
            }
        }
    }
}