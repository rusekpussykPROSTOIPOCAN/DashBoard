using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class overfly_block1
{
    public int id { get; set; }

    public int? iddistric { get; set; }

    public int? idadress { get; set; }

    public int? quantitynewviolation { get; set; }

    public int? idviolation { get; set; }

    public virtual address? idadressNavigation { get; set; }

    public virtual district? iddistricNavigation { get; set; }

    public virtual violation? idviolationNavigation { get; set; }
}
