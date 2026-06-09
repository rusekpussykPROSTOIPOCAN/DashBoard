using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class UpdateStatusRequest
    {
        public int TaskId { get; set; }
        public string Status { get; set; } = "";
    }
    public class TaskItem
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Description { get; set; } = "";
        public string Status { get; set; } = "new";
        public DateTime CreatedAt { get; set; }
    }

    public class TaskStats
    {
        public int TotalTasks { get; set; }
        public int InProgressTasks { get; set; }
        public int CompletedTasks { get; set; }
    }
    public class EventItemDto
    {
        public object UserName { get; set; }
        public string Action { get; set; }
        public string Description { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
    public class AddCalendarEventRequest
    {
        public string? AssignedToUserId { get; set; }
        public string? UserId { get; set; }
        public string Title { get; set; } = "";
        public string? Description { get; set; }
        public string EventDate { get; set; } = "";
        public string? Color { get; set; }
    }

}
