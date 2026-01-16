using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace FressFood.Services
{
    public class EmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;
        private readonly string? _smtpHost;
        private readonly int _smtpPort;
        private readonly string? _smtpUsername;
        private readonly string? _smtpPassword;
        private readonly string? _fromEmail;
        private readonly string? _fromName;
        private readonly bool _isEnabled;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
            _smtpHost = _configuration["Email:SmtpHost"];
            
            // Parse SMTP port safely
            if (int.TryParse(_configuration["Email:SmtpPort"], out int port))
            {
                _smtpPort = port;
            }
            else
            {
                _smtpPort = 587; // Default port
            }
            
            _smtpUsername = _configuration["Email:SmtpUsername"];
            _smtpPassword = _configuration["Email:SmtpPassword"];
            _fromEmail = _configuration["Email:FromEmail"];
            _fromName = _configuration["Email:FromName"] ?? "Fresher Food";
            _isEnabled = !string.IsNullOrEmpty(_smtpHost) && 
                       !string.IsNullOrEmpty(_smtpUsername) && 
                       !string.IsNullOrEmpty(_smtpPassword) && 
                       !string.IsNullOrEmpty(_fromEmail);

            if (!_isEnabled)
            {
                _logger.LogWarning("Email service is not configured. Email sending will be disabled.");
                _logger.LogWarning("To enable email service, please configure the following in appsettings.json:");
                _logger.LogWarning("  - Email:SmtpHost (e.g., smtp.gmail.com)");
                _logger.LogWarning("  - Email:SmtpPort (e.g., 587)");
                _logger.LogWarning("  - Email:SmtpUsername (your email address)");
                _logger.LogWarning("  - Email:SmtpPassword (your app password or email password)");
                _logger.LogWarning("  - Email:FromEmail (sender email address)");
                _logger.LogWarning("  - Email:FromName (optional, default: 'Fresher Food')");
            }
            else
            {
                _logger.LogInformation($"Email service initialized successfully. SMTP Host: {_smtpHost}, Port: {_smtpPort}, From: {_fromEmail}");
            }
        }

        /// <summary>
        /// Gửi email mật khẩu mới cho user
        /// </summary>
        public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string userName, string newPassword)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning("Email service is disabled. Cannot send password reset email.");
                return false;
            }

            try
            {
                var subject = "Mật khẩu mới - Fresher Food";
                var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
        .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
        .password-box {{ background-color: #fff; border: 2px solid #4CAF50; padding: 15px; margin: 20px 0; text-align: center; border-radius: 5px; }}
        .password {{ font-size: 24px; font-weight: bold; color: #4CAF50; letter-spacing: 2px; }}
        .warning {{ background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>Fresher Food</h1>
        </div>
        <div class='content'>
            <p>Xin chào <strong>{userName}</strong>,</p>
            
            <p>Yêu cầu đặt lại mật khẩu của bạn đã được admin xác nhận.</p>
            
            <p>Mật khẩu mới của bạn là:</p>
            
            <div class='password-box'>
                <div class='password'>{newPassword}</div>
            </div>
            
            <div class='warning'>
                <strong>⚠️ Lưu ý:</strong> Vui lòng đăng nhập và đổi mật khẩu ngay sau khi nhận được email này để bảo mật tài khoản của bạn.
            </div>
            
            <p>Bạn có thể đăng nhập bằng email và mật khẩu mới này.</p>
            
            <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng liên hệ với chúng tôi ngay lập tức.</p>
            
            <p>Trân trọng,<br>
            <strong>Đội ngũ Fresher Food</strong></p>
        </div>
        <div class='footer'>
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            <p>© 2026 Fresher Food. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";

                return await SendEmailAsync(toEmail, subject, body);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending password reset email to {toEmail}");
                return false;
            }
        }

        /// <summary>
        /// Gửi email thông báo request đã bị từ chối
        /// </summary>
        public async Task<bool> SendPasswordResetRejectedEmailAsync(string toEmail, string userName)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning("Email service is disabled. Cannot send rejection email.");
                return false;
            }

            try
            {
                var subject = "Yêu cầu đặt lại mật khẩu - Fresher Food";
                var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #dc3545; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
        .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>Fresher Food</h1>
        </div>
        <div class='content'>
            <p>Xin chào <strong>{userName}</strong>,</p>
            
            <p>Yêu cầu đặt lại mật khẩu của bạn đã bị từ chối bởi admin.</p>
            
            <p>Nếu bạn cần hỗ trợ, vui lòng liên hệ với chúng tôi qua:</p>
            <ul>
                <li>Email: support@fresherfood.com</li>
                <li>Hotline: 1900-xxxx</li>
            </ul>
            
            <p>Trân trọng,<br>
            <strong>Đội ngũ Fresher Food</strong></p>
        </div>
        <div class='footer'>
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            <p>© 2024 Fresher Food. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";

                return await SendEmailAsync(toEmail, subject, body);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending rejection email to {toEmail}");
                return false;
            }
        }

        /// <summary>
        /// Gửi email thông báo cho admin về request mới
        /// </summary>
        public async Task<bool> NotifyAdminNewPasswordResetRequestAsync(string adminEmail, string userEmail, string userName, DateTime requestTime)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning("Email service is disabled. Cannot send admin notification.");
                return false;
            }

            try
            {
                var subject = $"Yêu cầu đặt lại mật khẩu mới - {userEmail}";
                var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #ff9800; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
        .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
        .info-box {{ background-color: #fff; border-left: 4px solid #ff9800; padding: 15px; margin: 20px 0; }}
        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>Thông báo Admin</h1>
        </div>
        <div class='content'>
            <p>Xin chào Admin,</p>
            
            <p>Có một yêu cầu đặt lại mật khẩu mới:</p>
            
            <div class='info-box'>
                <p><strong>Email người dùng:</strong> {userEmail}</p>
                <p><strong>Tên người dùng:</strong> {userName}</p>
                <p><strong>Thời gian yêu cầu:</strong> {requestTime:dd/MM/yyyy HH:mm:ss}</p>
            </div>
            
            <p>Vui lòng đăng nhập vào hệ thống để xem xét và xử lý yêu cầu này.</p>
            
            <p>Trân trọng,<br>
            <strong>Hệ thống Fresher Food</strong></p>
        </div>
        <div class='footer'>
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            <p>© 2024 Fresher Food. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";

                return await SendEmailAsync(adminEmail, subject, body);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending admin notification to {adminEmail}");
                return false;
            }
        }

        /// <summary>
        /// Gửi email chung
        /// </summary>
        private async Task<bool> SendEmailAsync(string toEmail, string subject, string body)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning($"Email service is disabled. Cannot send email to {toEmail}. Please configure Email settings in appsettings.json (SmtpHost, SmtpUsername, SmtpPassword, FromEmail).");
                return false;
            }

            try
            {
                using (var client = new SmtpClient(_smtpHost, _smtpPort))
                {
                    client.EnableSsl = true;
                    client.Credentials = new NetworkCredential(_smtpUsername, _smtpPassword);

                    using (var message = new MailMessage())
                    {
                        message.From = new MailAddress(_fromEmail!, _fromName);
                        message.To.Add(toEmail);
                        message.Subject = subject;
                        message.Body = body;
                        message.IsBodyHtml = true;

                        await client.SendMailAsync(message);
                        _logger.LogInformation($"Email sent successfully to {toEmail}");
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send email to {toEmail}: {ex.Message}");
                return false;
            }
        }
    }
}

