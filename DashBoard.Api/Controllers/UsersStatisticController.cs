using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/tasks")]
    public class UsersStatisticController:BaseController
    {
        public UsersStatisticController(dashboardContext dashboard) : base(dashboard)
        {
        }
   
     

            [HttpGet("my")]
            public async Task<IActionResult> GetMyTasks([FromQuery] string userId)
            {
                var tasks = await _dashboard.Set<UserEvent>()
                    .Where(e => e.AssignedToUserId == userId)
                    .OrderByDescending(e => e.CreatedAt)
                    .Select(e => new
                    {
                        e.Id,
                        Title = e.Title ?? "",
                        Description = e.Description ?? "",
                        Status = e.Status ?? "new",
                        e.CreatedAt,
                        AssignedUserName = _dashboard.Users
                            .Where(u => u.Id == e.UserId)
                            .Select(u => u.FullName)
                            .FirstOrDefault() ?? ""
                    })
                    .ToListAsync();
                return Ok(tasks);
            }

            [HttpGet("stats")]
            public async Task<IActionResult> GetStats([FromQuery] string userId)
            {
                var total = await _dashboard.Set<UserEvent>().CountAsync(e => e.AssignedToUserId == userId);
                var inProgress = await _dashboard.Set<UserEvent>().CountAsync(e => e.AssignedToUserId == userId && e.Status == "in_progress");
                var completed = await _dashboard.Set<UserEvent>().CountAsync(e => e.AssignedToUserId == userId && e.Status == "done");

                return Ok(new { TotalTasks = total, InProgressTasks = inProgress, CompletedTasks = completed });
            }

            [HttpPost("update-status")]
            public async Task<IActionResult> UpdateStatus([FromBody] UpdateStatusRequest request)
            {
                var task = await _dashboard.Set<UserEvent>().FindAsync(request.TaskId);
                if (task == null) return NotFound();
                task.Status = request.Status;
                await _dashboard.SaveChangesAsync();
                return Ok();
            }
        }

        
    }

