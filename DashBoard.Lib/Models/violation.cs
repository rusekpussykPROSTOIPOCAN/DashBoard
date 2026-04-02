using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class violation
{
    public int id { get; set; }

    public string? name { get; set; }

    public virtual ICollection<overfly_block1> overfly_block1s { get; set; } = new List<overfly_block1>();
}
