namespace DashBoard.Lib.DTOs
{
    public class RobotUkon
    {
        public string Name { get; set; } = "";
        public int Count { get; set; }
    }
    public class RobotsUKONDetails
    {
        public List<RobotUkon> Checks { get; set; } = new();
        public List<RobotUkon> Results { get; set; } = new();
        public List<RobotUkon> Reports { get; set; } = new();
    }
}
