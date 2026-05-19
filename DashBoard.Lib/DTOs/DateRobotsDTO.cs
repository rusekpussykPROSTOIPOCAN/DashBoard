using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class DateRobotsDTO
    {
        public int robotId {  get; set; }
        public List<RobotPeriods> Period {  get; set; }
        public string? UserId { get; set; }

    }
    public class RobotPeriods {
        public int Year { get; set; }
        public int Month { get; set; }
    }

}
