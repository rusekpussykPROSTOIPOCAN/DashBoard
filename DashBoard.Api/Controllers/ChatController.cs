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

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteMessage(int id)
    {
        var message = await _dashboard.ChatMessages.FindAsync(id);
        if (message == null) return NotFound();

        _dashboard.ChatMessages.Remove(message);
        await _dashboard.SaveChangesAsync();
        return Ok();
    }
    [HttpPost("upload-file")]
    public async Task<IActionResult> UploadFile(IFormFile file, [FromForm] string userId, [FromForm] string userName)
    {
        if (file == null || file.Length == 0)
            return BadRequest("Файл не выбран");

        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "chat");
        Directory.CreateDirectory(uploadsFolder);

        var fileName = $"{Guid.NewGuid()}_{file.FileName}";
        var filePath = Path.Combine(uploadsFolder, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var fileUrl = $"/uploads/chat/{fileName}";
        var message = $"📎 <a href='{fileUrl}' target='_blank'>{file.FileName}</a> ({file.Length / 1024} КБ)";

        _dashboard.ChatMessages.Add(new ChatMessageEntity
        {
            UserId = userId,
            UserName = userName ?? "Гость",
            Message = message,
            CreatedAt = DateTime.UtcNow
        });
        await _dashboard.SaveChangesAsync();

        return Ok(new { fileUrl, fileName = file.FileName });
    }
    [HttpGet("history")]
    public async Task<IActionResult> GetHistory()
    {
        var messages = await _dashboard.ChatMessages
            .OrderByDescending(m => m.CreatedAt)
            .Take(50)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new { m.Id, m.UserName, m.Message, m.CreatedAt })
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