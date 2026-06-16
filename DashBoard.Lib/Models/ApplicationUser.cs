

using Microsoft.AspNetCore.Identity;

namespace DashBoard.Lib.Models
{
    public class ApplicationUser:IdentityUser
    {
        public string? FullName { get; set; }
        public string? Department { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsApproved { get; set; } = false;
    }

    public static class AppRoles
    {
        public const string Admin = "Администратор";
        public const string Editor = "Руководитель";
        public const string Viewer = "Сотрудник";
    }
}
