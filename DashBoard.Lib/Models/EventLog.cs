using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.Models
{
    public class EventLogItem
    {
        public string UserName { get; set; } = "";
        public string Action { get; set; } = "";
        public string Description { get; set; } = "";
        public DateTime CreatedAt { get; set; }
    }
    public class EventItemDto
    {
        public string UserName { get; set; } = "";
        public string Action { get; set; } = "";
        public string Description { get; set; } = "";
        public DateTime CreatedAt { get; set; }
    }
    public class AddEventRequest
    {
        public string? UserId { get; set; }
        public string Action { get; set; } = "";
        public string Description { get; set; } = "";
    }
    public class UserEvent
    {
        public int Id { get; set; }
        public string? UserId { get; set; }
        public string Title { get; set; } = "";
        public string? Description { get; set; }
        public DateTime EventDate { get; set; }
        public string Color { get; set; } = "#1976d2"; // Синий
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
    public class EventLog
    {
        public int Id { get; set; }
        public string? UserId { get; set; }
        public string Action { get; set; } = "";
        public string Description { get; set; } = "";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("UserId")]
        public ApplicationUser? User { get; set; }
    }
}
