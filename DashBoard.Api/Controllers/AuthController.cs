using DashBoard.Api.Service;
using DashBoard.Api.Services;
using DashBoard.Lib.Data;
using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Web; 

namespace DashBoard.Api.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : BaseController
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly EmailService _emailService;
        private readonly IConfiguration _config;

        public AuthController(dashboardContext dashboard,
            UserManager<ApplicationUser> userManager,
            SignInManager<ApplicationUser> signInManager,
            RoleManager<IdentityRole> roleManager,
            EmailService emailService,
            IConfiguration config): base(dashboard)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _roleManager = roleManager;
            _emailService = emailService;
            _config = config;
        }
        [HttpGet("profile")]
        [Authorize]
        public async Task<IActionResult> GetProfile()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return NotFound();

            var roles = await _userManager.GetRolesAsync(user);

            return Ok(new
            {
                user.FullName,
                user.Email,
                user.Department,
                user.CreatedAt,
                Roles = roles
            });
        }
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var user = new ApplicationUser
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                Department = request.Department,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, request.Password);

            if (!result.Succeeded)
                return BadRequest(new AuthResponse { Success = false, Message = string.Join(", ", result.Errors.Select(e => e.Description)) });

           
            await _userManager.AddToRoleAsync(user, AppRoles.Viewer);


            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var encodedToken = Uri.EscapeDataString(token);
            var confirmLink = $"http://localhost:8080/api/auth/confirm-email?userId={user.Id}&token={encodedToken}";
            await LogEvent("Регистрация", $"Новый пользователь {user.UserName} добавлен", user.UserName);
            await _emailService.SendEmailAsync(user.Email, "Подтверждение регистрации",
                $"<h2>Добро пожаловать!</h2><p>Подтвердите email: <a href='{confirmLink}'>нажмите здесь</a></p>");

            return Ok(new AuthResponse { Success = true, Message = "Регистрация успешна. Проверьте почту для подтверждения." });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null)
                return BadRequest(new AuthResponse { Success = false, Message = "Неверный email или пароль" });

            if (!user.EmailConfirmed)
                return BadRequest(new AuthResponse { Success = false, Message = "Email не подтверждён" });

            var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
            if (!result.Succeeded)
                return BadRequest(new AuthResponse { Success = false, Message = "Неверный email или пароль" });

            var roles = await _userManager.GetRolesAsync(user);
            var token = GenerateJwtToken(user, roles);

            return Ok(new AuthResponse
            {
                Success = true,
                Token = token,
                Email = user.Email,
                UserId = user.Id,
                FullName = user.FullName,
                Roles = roles.ToList()
            });
        }
        [HttpGet("confirm-email")]
        public async Task<IActionResult> ConfirmEmail(string userId, string token)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return Content("Пользователь не найден");

            var decodedToken = Uri.UnescapeDataString(token);
            var result = await _userManager.ConfirmEmailAsync(user, decodedToken);

            if (result.Succeeded)
                return Content("<html><body><h2>✅ Email подтверждён!</h2><p>Можете закрыть страницу и войти в приложение.</p></body></html>", "text/html; charset=utf-8");

            return BadRequest("Ошибка подтверждения");
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null) return Ok(new { message = "Если email существует, письмо отправлено" });

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var encodedToken = HttpUtility.UrlEncode(token);
            var link = $"http://localhost:5000/reset-password?email={user.Email}&token={encodedToken}";

            await _emailService.SendEmailAsync(user.Email, "Сброс пароля",
                $"<p>Для сброса пароля: <a href='{link}'>нажмите здесь</a></p>");

            return Ok(new { message = "Письмо отправлено" });
        }
        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var user = await _userManager.FindByIdAsync(userId!);

            if (user == null)
                return NotFound();

            var result = await _userManager.ChangePasswordAsync(user, request.OldPassword, request.NewPassword);

            if (result.Succeeded)
                return Ok(new { message = "Пароль изменён" });

            return BadRequest(string.Join(", ", result.Errors.Select(e => e.Description)));
        }

        public class ChangePasswordRequest
        {
            public string OldPassword { get; set; } = "";
            public string NewPassword { get; set; } = "";
        }
        private string GenerateJwtToken(ApplicationUser user, IList<string> roles)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id),
                new(ClaimTypes.Email, user.Email!),
                new(ClaimTypes.Name, user.FullName ?? "")
            };

            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                claims: claims,
                expires: DateTime.UtcNow.AddDays(int.Parse(_config["Jwt:ExpireDays"]!)),
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}