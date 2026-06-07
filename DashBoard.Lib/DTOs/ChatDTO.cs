using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class SendMessageRequest
    {
        public string? UserId { get; set; }
        public string? UserName { get; set; }
        public string Message { get; set; } = "";
    }
    public class ChatMessage
    {
        public int Id { get; set; }
        public string User { get; set; } = "";
        public string Text { get; set; } = "";
        public string Time { get; set; } = "";
        public bool IsFile { get; set; }
        public string FileUrl { get; set; } = "";
        public string FileName { get; set; } = "";
        public string FileSize { get; set; } = "";
    }

    public class ChatHistoryItem
    {
        public int Id { get; set; }
        public string UserName { get; set; } = "";
        public string Message { get; set; } = "";
        public DateTime CreatedAt { get; set; }
    }
}
