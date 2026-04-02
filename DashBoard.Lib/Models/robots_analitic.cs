using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class robots_analitic
{
    public int id { get; set; }

    public int? idrobots { get; set; }

    public DateOnly? datestatistic { get; set; }

    public int? count_application { get; set; }

    public bool? isactive { get; set; }

    public string? data_analize { get; set; }

    public virtual robot? idrobotsNavigation { get; set; }
}
