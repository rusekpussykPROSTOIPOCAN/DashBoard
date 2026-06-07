using DashBoard.Api.Service;
using DashBoard.Api.Service;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/admin")]
   
    public class AdminsController:BaseController
    {
        private readonly EmailService _emailService;
        private readonly UserManager<ApplicationUser> _userManager;
        public AdminsController(UserManager<ApplicationUser> userManager,
            EmailService emailService,dashboardContext dashboard) : base(dashboard)
        {
            _userManager = userManager;
            _emailService = emailService;
        }
        [HttpGet("users")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _userManager.Users
                .OrderBy(u => u.Email)
                .Select(u => new
                {
                    u.Id,
                    u.Email,
                    u.FullName,
                    u.Department,
                    u.EmailConfirmed
                })
                .ToListAsync();
            return Ok(users);
        }

        [HttpGet("user-roles")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> GetUserRoles()
        {
            var users = await _userManager.Users.ToListAsync();
            var result = new Dictionary<string, string>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                result[user.Id] = roles.FirstOrDefault() ?? "";
            }

            return Ok(result);
        }

        [HttpPost("change-role")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> ChangeRole([FromBody] ChangeRoleRequest request)
        {
            var user = await _userManager.FindByIdAsync(request.UserId);
            if (user == null) return NotFound();

            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);
            await _userManager.AddToRoleAsync(user, request.Role);

            return Ok();
        }
        [HttpPost("delete-user")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> DeleteUser([FromBody] DeleteUserRequest request)
        {
            var user = await _userManager.FindByIdAsync(request.UserId);
            if (user == null) return NotFound();

            
            var roles = await _userManager.GetRolesAsync(user);
            if (roles.Any())
                await _userManager.RemoveFromRolesAsync(user, roles);

           
            var result = await _userManager.DeleteAsync(user);
            if (!result.Succeeded)
                return BadRequest(result.Errors);

            return Ok();
        }

        public class DeleteUserRequest
        {
            public string UserId { get; set; } = "";
        }
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] AdminResetPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email); 
            if (user == null) return NotFound();

            var passwordHasher = new PasswordHasher<ApplicationUser>();
            user.PasswordHash = passwordHasher.HashPassword(user, request.NewPassword);
            await _userManager.UpdateAsync(user);

            return Ok();
        }
        [HttpGet("roles")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> GetRoles()
        {
            var roles =  _dashboard.Roles.ToList();
            return Ok(roles);
        }
        [HttpPost("send-password")]
        public async Task<IActionResult> SendPassword([FromBody] SendPasswordRequest request)
        {
            await _emailService.SendEmailAsync(request.Email, "Ваш пароль",
                $"<h2>Пароль для входа в систему:</h2><h1 style='font-size:28px;'>{request.Password}</h1>");
            return Ok();
        }
        [HttpPost("create-user")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            var existing = await _userManager.FindByEmailAsync(request.Email);
            if (existing != null)
                return BadRequest(new { message = "Пользователь уже существует" });
            var user = new ApplicationUser
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                Department = request.Department,
                EmailConfirmed = true,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user);
            if (!result.Succeeded)
                return BadRequest(result.Errors);

            await _userManager.AddToRoleAsync(user, request.Role);

            return Ok(new { user.Id, user.Email });
        }
        [HttpPost("update-user")]
        [Authorize(Roles = "Администратор")]
        public async Task<IActionResult> UpdateUser([FromBody] UpdateUserRequest request)
        {
            var user = await _userManager.FindByIdAsync(request.UserId);
            if (user == null) return NotFound();

            var oldEmail = user.Email;

            user.FullName = request.FullName;
            user.Department = request.Department;

           
            if (!string.IsNullOrEmpty(request.Email) && oldEmail != request.Email)
            {
               
                var existing = await _userManager.FindByEmailAsync(request.Email);
                if (existing != null && existing.Id != request.UserId)
                    return BadRequest("Email уже используется");

                user.Email = request.Email;
                user.UserName = request.Email;
                user.NormalizedEmail = request.Email.ToUpper();
                user.NormalizedUserName = request.Email.ToUpper();

                
                await _emailService.SendEmailAsync(oldEmail!, "Email изменён",
                    $"<p>Ваш email был изменён на <b>{request.Email}</b></p>");

               
                await _emailService.SendEmailAsync(request.Email, "Email изменён",
                    $"<p>Ваш email был изменён. Если это были не вы — обратитесь к администратору.</p>");

                await LogEvent("Изменение email", $"Пользователь {oldEmail} → {request.Email}");
            }

            await _userManager.UpdateAsync(user);

            
            var currentRoles = await _userManager.GetRolesAsync(user);
            if (!currentRoles.Contains(request.Role))
            {
                await _userManager.RemoveFromRolesAsync(user, currentRoles);
                await _userManager.AddToRoleAsync(user, request.Role);
            }

            return Ok();
        }

        
    }
}
