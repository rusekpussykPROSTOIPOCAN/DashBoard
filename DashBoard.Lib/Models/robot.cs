using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class robot
{
    public int id { get; set; }

    public string? name { get; set; }

    public string? short_name { get; set; }

    public virtual ICollection<robots_analitic> robots_analitics { get; set; } = new List<robots_analitic>();
}
