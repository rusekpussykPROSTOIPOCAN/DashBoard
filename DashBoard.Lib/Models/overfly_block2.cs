using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class overfly_block2
{
    public int id { get; set; }

    public int? num_p_p { get; set; }

    public int? id_status { get; set; }

    public int? id_adress { get; set; }

    public int? id_distric { get; set; }

    public double? square { get; set; }

    public virtual address? id_adressNavigation { get; set; }

    public virtual district? id_districNavigation { get; set; }
}
