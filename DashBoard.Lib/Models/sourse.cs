using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class sourse
{
    public int id { get; set; }

    public string? source { get; set; }

    public virtual ICollection<work_progress> work_progresses { get; set; } = new List<work_progress>();
}
