using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class work_progress_violation
{
    public int id { get; set; }

    public int? id_work_progress { get; set; }

    public int? id_article { get; set; }

    public int? object_a_week { get; set; }

    public int? new_violations { get; set; }

    public int? old_violations { get; set; }

    public virtual work_progress? id_work_progressNavigation { get; set; }
}
