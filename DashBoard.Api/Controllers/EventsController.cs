using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;


namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/events")]
    public class EventsController : BaseController
    {
        public EventsController(dashboardContext dashboard) : base(dashboard)
        {
        }

        [HttpGet]
        public async Task<IActionResult> GetEvents([FromQuery] string? date = null)
        {
            var systemEvents = await _dashboard.Set<EventLog>()
                .Select(e => new Lib.DTOs.EventItemDto
                {
                    UserName = e.User != null ? e.User.FullName : "Система",
                    Action = e.Action,
                    Description = e.Description,
                    CreatedAt = e.CreatedAt
                })
                .ToListAsync();

            var userEvents = await _dashboard.Set<UserEvent>()
     .Select(e => new Lib.DTOs.EventItemDto
     {
         UserName = _dashboard.Users.Where(u => u.Id == e.UserId).Select(u => u.FullName).FirstOrDefault() ?? "Пользователь",
         Action = "Событие",
         Description = e.Description,
         CreatedAt = e.EventDate
     })
     .ToListAsync();


            var allEvents = systemEvents.Concat(userEvents)
                .OrderByDescending(e => e.CreatedAt)
                .Take(100)
                .ToList();

            return Ok(allEvents);
        }

       
        [HttpPost]
        public async Task<IActionResult> AddEvent([FromBody] AddCalendarEventRequest request)
        {
            
            var userName = "Пользователь";
            if (!string.IsNullOrEmpty(request.UserId))
            {
                var user = await _dashboard.Users.FindAsync(request.UserId);
                userName = user?.FullName ?? "Пользователь";
            }

            DateTime eventDate;
            if (!DateTime.TryParse(request.EventDate, out eventDate))
                eventDate = DateTime.UtcNow;

            var evt = new UserEvent
            {
                UserId = request.UserId,
                Title = request.Title,
                Description = $"[{request.Title}: {request.Description}]",
                EventDate = DateTime.SpecifyKind(eventDate, DateTimeKind.Utc),
                Color = request.Color ?? "#1976d2",
                CreatedAt = DateTime.UtcNow
            };

            _dashboard.Set<UserEvent>().Add(evt);
            await _dashboard.SaveChangesAsync();

            await LogEvent("Добавлено событие", $"{request.Title}: {request.Description}");

            return Ok(evt);
        }
    }

    
}