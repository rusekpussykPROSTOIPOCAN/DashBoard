using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DashBoard.Lib.Models;

public partial class sourse
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int id { get; set; }

    public string? source { get; set; }

    public virtual ICollection<work_progress> work_progresses { get; set; } = new List<work_progress>();
}
