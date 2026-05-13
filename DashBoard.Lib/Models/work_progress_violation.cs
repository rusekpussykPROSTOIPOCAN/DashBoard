using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace DashBoard.Lib.Models;

public partial class work_progress_violation
{
    public int id { get; set; }

    public int? id_work_progress { get; set; }

    public int? id_article { get; set; }

    public int? object_a_week { get; set; }

    public int? new_violations { get; set; }

    public int? old_violations { get; set; }

    [ForeignKey("id_work_progress")]
    public virtual work_progress? id_work_progressNavigation { get; set; }
    [ForeignKey("id_article")]
    public virtual article? id_articleNavigation { get; set; }
}
