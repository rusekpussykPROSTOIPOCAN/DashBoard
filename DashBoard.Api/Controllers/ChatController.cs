using DashBoard.Api.Controllers;
using DashBoard.Lib.Data;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/chat")]
public class ChatController : BaseController
{
    public ChatController(dashboardContext dashboard) : base(dashboard) { }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory()
    {
        var messages = await _dashboard.ChatMessages
            .OrderByDescending(m => m.CreatedAt)
            .Take(50)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new { m.UserName, m.Message, m.CreatedAt })
            .ToListAsync();
        return Ok(messages);
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
    {
        _dashboard.ChatMessages.Add(new ChatMessageEntity
        {
            UserId = request.UserId,
            UserName = request.UserName ?? "Гость",
            Message = request.Message,
            CreatedAt = DateTime.UtcNow
        });
        await _dashboard.SaveChangesAsync();
        return Ok();
    }
    [HttpGet("count")]
    public async Task<IActionResult> GetNewMessagesCount([FromQuery] string? since)
    {
        var count = 0;

        if (!string.IsNullOrEmpty(since) && DateTime.TryParse(since, null, System.Globalization.DateTimeStyles.RoundtripKind, out var sinceDate))
        {
            count = await _dashboard.ChatMessages
                .Where(m => m.CreatedAt > sinceDate.ToUniversalTime())
                .CountAsync();
        }
        else
        {
            count = await _dashboard.ChatMessages.CountAsync();
        }

        return Ok(new { Count = count });
    }
}

public class SendMessageRequest
{
    public string? UserId { get; set; }
    public string? UserName { get; set; }
    public string Message { get; set; } = "";
}