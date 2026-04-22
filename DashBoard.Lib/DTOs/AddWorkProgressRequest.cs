using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class AddWorkProgressRequest
    {
        public int IdSourse { get; set; }
        public int AllPerimeter { get; set; }
        public int CompletePerimeter { get; set; }
        public int RemainedPerimeter { get; set; }
        public string? Comment { get; set; }

        public List<ViolationItem> Violations { get; set; } = new();
    }
    public class AddWorkProgressResult
    {
        public int id { get; set; }
        public string message { get; set; }
        public int violations_count { get; set; }
    }
    public class ViolationItem
    {
        public int IdArticle { get; set; }
        public int? ViolationsWeek { get; set; }
        public int? NewViolations { get; set; }
        public int? OldViolations { get; set; }
    }
}
