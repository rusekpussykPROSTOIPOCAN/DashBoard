using MimeKit;
using System.Net.Mail;
using MailKit.Net.Smtp;

namespace DashBoard.Api.Service
{
    public class EmailService
    {
        private readonly IConfiguration _config;
        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            var email = new MimeMessage();
            email.From.Add(new MailboxAddress("Dashboard", _config["Email:From"]));
            email.To.Add(new MailboxAddress("", to));
            email.Subject = subject;
            email.Body = new TextPart("html") { Text = body };
            using var smtp = new MailKit.Net.Smtp.SmtpClient();
            await smtp.ConnectAsync(_config["Email:Host"], int.Parse(_config["Email:Port"]!), false);
            await smtp.AuthenticateAsync(_config["Email:Username"], _config["Email:Password"]);
            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);
        }
    }
}
