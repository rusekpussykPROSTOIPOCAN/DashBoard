
namespace DashBoard.Lib.DTOs
{
    public class ChartBlockDto
    {
        public ChartTypeRobot Type { get; set; } 
        public double Sum { get; set; }
        public Dictionary<string, double> Details { get; set; } = new();
    }
}
