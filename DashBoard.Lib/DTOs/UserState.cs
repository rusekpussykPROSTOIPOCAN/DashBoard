using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DashBoard.Lib.DTOs
{
    public class EmployeeItem
    {
        public string Id { get; set; } = "";
        public string FullName { get; set; } = "";
        public string Department { get; set; } = "";
    }
    public class UserState
    {
        public bool IsAdmin { get; private set; }
        public string Role { get; private set; } = "";
        public string Email { get; private set; } = "";
        public string Department { get; private set; } = "";
        public string UserId { get; private set; } = "";
        public string UserName { get; private set; } = "";
        public bool IsLoggedIn { get; private set; }

        public void SetUser(string role, string department, string userId, string userName)
        {
            Role = role;
            Department = department;
            UserId = userId;
            UserName = userName;
            IsLoggedIn = true;
            IsAdmin = role == "Администратор" || role == "Admin";
        }

        public void Clear()
        {
            IsAdmin = false;
            Role = "";
            Department = "";
            UserId = "";
            UserName = "";
            IsLoggedIn = false;
        }



    }
}
