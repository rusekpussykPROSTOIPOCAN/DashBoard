using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace DashBoard.Lib.Models;

public partial class work_progress
{
    public int id { get; set; }
    public int? id_sourse { get; set; }
    public int? all_perimeter { get; set; }
    public int? complete_perimeter { get; set; }
    public int? remained_perimeter { get; set; }
    public DateTime? created_at { get; set; }
    public string? comment { get; set; }

    
    public string? created_by_user_id { get; set; }

    [ForeignKey("id_sourse")]
    public virtual sourse? id_sourseNavigation { get; set; }

    [ForeignKey("created_by_user_id")]
    public virtual ApplicationUser? CreatedByUser { get; set; }

    public virtual ICollection<work_progress_violation> work_progress_violations { get; set; } = new List<work_progress_violation>();
}