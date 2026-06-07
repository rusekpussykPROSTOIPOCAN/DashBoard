using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class EventItemDto
    {
        public object UserName { get; set; }
        public string Action { get; set; }
        public string Description { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
    public class AddCalendarEventRequest
        {
            public string? UserId { get; set; }
            public string Title { get; set; } = "";
            public string? Description { get; set; }
            public string EventDate { get; set; } = "";
            public string? Color { get; set; }
        }
    
}
