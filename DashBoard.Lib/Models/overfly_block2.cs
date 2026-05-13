using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class overfly_block2
{
    public int id { get; set; }

    public int? id_status { get; set; }

    public int? id_address { get; set; }

    public int? id_district { get; set; }

    public double? square { get; set; }

    public DateOnly? date_get_materials { get; set; }

    public virtual address? id_addressNavigation { get; set; }

    public virtual district? id_districtNavigation { get; set; }

    public virtual statusapplication? id_statusNavigation { get; set; }
}
