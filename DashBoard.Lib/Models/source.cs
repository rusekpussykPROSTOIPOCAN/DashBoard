using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class source
{
    public int id { get; set; }

    public string? name { get; set; }

    public virtual ICollection<bpla> bplas { get; set; } = new List<bpla>();
}
