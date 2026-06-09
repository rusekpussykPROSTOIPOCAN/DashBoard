using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Models;

public partial class UserEvent
{
    public int Id { get; set; }

    public string? UserId { get; set; }

    public string Title { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime EventDate { get; set; }

    public string? Color { get; set; }

    public DateTime? CreatedAt { get; set; }
    public string? AssignedToUserId { get; set; }
    public string? Status { get; set; } = "new";
}
