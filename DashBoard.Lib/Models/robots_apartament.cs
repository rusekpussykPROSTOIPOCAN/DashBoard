using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class robots_apartament
{
    public int id { get; set; }

    public DateOnly? date_start { get; set; }

    public int? worked_out_by_the_algorithm { get; set; }

    public int? doubles { get; set; }

    public int? violations_detected_by_the_algorithm { get; set; }

    public int? no_violations_were_detected { get; set; }

    public int? vri_was_not_found { get; set; }

    public int? count_transferred_ka { get; set; }

    public bool? is_transferred_to_ka { get; set; }

    public DateOnly? date_transferred { get; set; }

    public DateOnly? date_receipt { get; set; }

    public int? total_objects_worked_out { get; set; }

    public int? confirmed_violations_new { get; set; }

    public int? confirmed_violations_previously { get; set; }

    public string? comment { get; set; }

    public int? object_id { get; set; }

    public virtual objects_for_apartmen? _object { get; set; }
}
