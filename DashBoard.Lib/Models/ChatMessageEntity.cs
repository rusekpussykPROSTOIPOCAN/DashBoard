namespace DashBoard.Lib.Models
{
    public class ChatMessageEntity
    {
        public int Id { get; set; }
        public string? UserId { get; set; }
        public string UserName { get; set; } = "";
        public string Message { get; set; } = "";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}