using DashBoard.Lib.Data;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace DashBoard.Api.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly dashboardContext _db;

        public ChatHub(dashboardContext db)
        {
            _db = db;
        }

        public async Task SendMessage(string message)
        {
            var userName = Context.User?.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value ?? "Гость";
            var userId = Context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            
            _db.ChatMessages.Add(new ChatMessageEntity
            {
                UserId = userId,
                UserName = userName,
                Message = message,
                CreatedAt = DateTime.UtcNow
            });
            await _db.SaveChangesAsync();

            await Clients.All.SendAsync("ReceiveMessage", userName, message, DateTime.Now.ToString("HH:mm"));
        }
    }
}