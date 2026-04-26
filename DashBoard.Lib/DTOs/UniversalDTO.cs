

namespace DashBoard.Lib.DTOs
{
    public class DateFilter
    {
        public int? Year { get; set; }
        public int? Month { get; set; }
        public int? Quarter { get; set; }
    }

    public class UniversalChartResponseV3
    {
        public string RobotName { get; set; }
        public string Block { get; set; }
        public string Title { get; set; } = default!;
        public int? Total { get; set; }

        public ChartTypeRobot Type { get; set; }


        public List<UniversalChartItemV3> Items { get; set; } = new();

        public bool IsRaw { get; set; }
    }

    public class UniversalChartItemV3
    {
        public string Key { get; set; } = default!;
        public double Value { get; set; }
    }

    public enum ChartTypeRobot { 
        Bar,
        Pie,
        Line
    }
}
