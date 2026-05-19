using DashBoard.Lib.Data;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
namespace DashBoard.Api.Controllers
{
    public abstract class BaseController:ControllerBase
    {
        protected readonly dashboardContext _dashboard;
        protected BaseController(dashboardContext dashboard)
        {
            _dashboard = dashboard;
        }
        protected string? CurrentUserId =>
            User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        protected string? CurrentUserName =>
    User.FindFirst(ClaimTypes.Name)?.Value ??
    User.FindFirst("FullName")?.Value;

        protected async Task LogEvent(string action, string description, string? userId = null)
        {
            var uid = userId ?? CurrentUserId;
            var userName = "Система";

            if (!string.IsNullOrEmpty(uid))
            {
                var user = await _dashboard.Users.FindAsync(uid);
                userName = user?.FullName ?? "Пользователь";
            }

            var log = new EventLog
            {
                UserId = uid,
                Action = action,
                Description = description,
                CreatedAt = DateTime.UtcNow
            };
            _dashboard.Set<EventLog>().Add(log);
            await _dashboard.SaveChangesAsync();
        }
        protected string? GetUserId(string? requestUserId = null)
        {
            return requestUserId ?? CurrentUserId;
        }
    }
}
