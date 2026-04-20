using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class photo
{
    public int id { get; set; }

    public DateOnly? date_discharge { get; set; }

    public int? confirmed_signs_of_violations { get; set; }

    public int? other_violations { get; set; }

    public int? new_violations { get; set; }

    public int? id_type { get; set; }

    public virtual ICollection<photo> Inverseid_typeNavigation { get; set; } = new List<photo>();

    public virtual photo? id_typeNavigation { get; set; }
}
