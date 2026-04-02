using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class bpla
{
    public int id { get; set; }

    public int? detector_id { get; set; }

    public int? district_id { get; set; }

    public DateOnly? date_overfly_start { get; set; }

    public DateOnly? date_overfly_end { get; set; }

    public DateOnly? date_discharge { get; set; }

    public int? sourse_id { get; set; }

    public int? all_count_photo_ins { get; set; }

    public int? transferred_ka { get; set; }

    public int? _double { get; set; }

    public DateOnly? got_a_job_date { get; set; }

    public int? responsible_id { get; set; }

    public DateOnly? complete_the_work_date { get; set; }

    public int? tr { get; set; }

    public int? fp { get; set; }

    public double? procent_acuracy { get; set; }

    public int? confirmed_signs_of_violations { get; set; }

    public int? other_violations { get; set; }

    public int? new_violations { get; set; }

    public string? comment { get; set; }

    public DateOnly? transfer_of_results_to_dit_date { get; set; }

    public virtual detector? detector { get; set; }

    public virtual source? sourse { get; set; }
}
