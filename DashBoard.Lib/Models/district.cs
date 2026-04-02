using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class district
{
    public int id { get; set; }

    public string? name { get; set; }

    public virtual ICollection<overfly_block1> overfly_block1s { get; set; } = new List<overfly_block1>();

    public virtual ICollection<overfly_block2> overfly_block2s { get; set; } = new List<overfly_block2>();
}
