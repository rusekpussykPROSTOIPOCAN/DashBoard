using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class objects_for_apartmen
{
    public int id { get; set; }

    public string? name { get; set; }

    public virtual ICollection<robots_apartament> robots_apartaments { get; set; } = new List<robots_apartament>();
}
