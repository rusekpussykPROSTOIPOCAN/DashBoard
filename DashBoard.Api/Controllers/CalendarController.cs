using DashBoard.Api.Controllers;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/calendar")]
public class CalendarController : BaseController
{
    public CalendarController(dashboardContext dashboard) : base(dashboard) { }




    [HttpPost("events")]
    public async Task<IActionResult> AddEvent([FromBody] AddCalendarEventRequest request)
    {
        
        var userName = "Пользователь";
        if (!string.IsNullOrEmpty(request.UserId))
        {
            var user = await _dashboard.Users.FindAsync(request.UserId);
            userName = user?.FullName ?? "Пользователь";
        }

        var description = $"[{userName}] {request.Title}";
        if (!string.IsNullOrEmpty(request.Description))
            description += $": {request.Description}";

        DateTime eventDate;
        if (!DateTime.TryParse(request.EventDate, out eventDate))
            eventDate = DateTime.UtcNow;

        var evt = new UserEvent
        {
            UserId = request.UserId,
            Title = request.Title,
            Description = $"{request.Title}: {request.Description}",
            EventDate = DateTime.SpecifyKind(eventDate, DateTimeKind.Utc),
            AssignedToUserId = request.AssignedToUserId,
            Status = "new", 
            CreatedAt = DateTime.UtcNow
        };

        _dashboard.Set<UserEvent>().Add(evt);
        await _dashboard.SaveChangesAsync();

        return Ok(evt);
    }

    [HttpGet("events")]
    public async Task<IActionResult> GetUserEvents([FromQuery] DateTime? date)
    {
        var query = _dashboard.Set<UserEvent>().AsQueryable();

        if (date.HasValue)
        {
            var utcDate = DateTime.SpecifyKind(date.Value.Date, DateTimeKind.Utc);
            query = query.Where(e => e.EventDate.Date == utcDate.Date);
        }

        var events = await query.OrderBy(e => e.EventDate).ToListAsync();
        return Ok(events);
    }
}

