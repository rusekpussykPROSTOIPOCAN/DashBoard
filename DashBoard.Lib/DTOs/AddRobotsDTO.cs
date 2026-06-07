

namespace DashBoard.Lib.DTOs
{
    public class UpdateUserRequest
    {
        public string UserId { get; set; } = "";
        public string FullName { get; set; } = "";
        public string? Department { get; set; }
        public string Role { get; set; } = "";
        public string Email { get; set; } = "";
    }
    public class SendPasswordRequest
    {
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
    }
    public class ChangeRoleRequest
    {
        public string UserId { get; set; } = "";
        public string Role { get; set; } = "";
    }
    public class AddRobotDTO
    {
        public string Name { get; set; } = string.Empty;
        public string ShortName { get; set; } = string.Empty;

    }
    public class ImportResult
    {
        public string Message { get; set; } = "";
        public List<string>? Errors { get; set; }
    }
    public class AddDetailsRobot
    {
        public int IdRobot { get; set; }
        public DateOnly DateStatistic {  get; set; }
        public List<ChartBlockDto> Blocks { get; set; } = new();

    }
    public class UpdateRobotRequest
    {
        public int RobotId { get; set; }
        public AddRobotDTO Robot { get; set; }
        public string? UserId { get; set; }

        public List<PeriodGroup> Periods { get; set; }
    }
    public class DetailItem
    {
        public string DetailName { get; set; } = string.Empty;
        public double Value { get; set; } = 0;
    }
    public class PeriodGroup
    {
        public DateTime? Month { get; set; }
        public int? CountApplications { get; set; }
        public List<NewChartBlockDto> Charts { get; set; } = new();
    }
    public class NewChartBlockDto
    {
        public string Title { get; set; } = string.Empty;
        public ChartTypeRobot Type { get; set; }
        public double Sum { get; set; }
        public DetailItem NewDetail { get; set; } = new();
        public Dictionary<string, double> Details { get; set; } = new();
    }

    public class CreateRobotRequest
    {
        public AddRobotDTO Robot { get; set; } = new();

        public List<PeriodGroup> Periods { get; set; } = new();

        public string? UserId { get; set; }
    }


    public class EditRobot
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string ShortName { get; set; }
        public int? CountApplications { get; set; }
        public List<PeriodGroupDTO> Periods { get; set; }
    }
    public class PeriodGroupDTO
    {
        public int? CountApplications { get; set; }
        public DateTime? Month { get; set; }
        public List<NewChartBlockDto> Charts { get; set; }
    }

    
    
}
