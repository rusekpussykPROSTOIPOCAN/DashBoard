

namespace DashBoard.Lib.DTOs
{
    public class CreateUserRequest
    {
        public string Email { get; set; } = "";
        public string FullName { get; set; } = "";
        public string? Department { get; set; }
        public string Role { get; set; } = "Viewer";
    }
    public class LoginResult
    {
        public bool Success { get; set; }
        public string? Token { get; set; }
        public string? Email { get; set; }
        public string? FullName { get; set; }
        public string? UserId { get; set; }
        public List<string>? Roles { get; set; }
    }
    public class RegisterRequest
    {
        public string? UserId { get; set; }
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
        public string FullName { get; set; } = "";
        public string? Department{ get; set; } = "";
    }
    public class LoginRequest
    {
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
        public bool RememberMe { get; set; } 

    }

    public class AuthResponse
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public string? Token {  get; set; }
        public string? Email { get; set; }
        public string? UserId { get; set; }
        public string? FullName { get; set; }
        public List<string>? Roles { get; set; } 

    }

    public class ConfirmEmailRequest
    {
        public string UserId { get; set; } = "";
        public string? Token { get; set; } = "";

    }
    public class ForgotPasswordRequest
    {
        public string Email { get; set; }
    }

    public class AdminResetPasswordRequest
    {
        public string Email { get; set; } = "";
        public string NewPassword { get; set; } = "";
    }



}
