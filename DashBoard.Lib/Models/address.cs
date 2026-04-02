using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class address
{
    public int id { get; set; }

    public string? address1 { get; set; }

    public virtual ICollection<overfly_block1> overfly_block1s { get; set; } = new List<overfly_block1>();

    public virtual ICollection<overfly_block2> overfly_block2s { get; set; } = new List<overfly_block2>();
}
