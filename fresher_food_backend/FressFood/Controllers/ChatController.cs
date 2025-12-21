using FressFood.Models;
using FressFood.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Text;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChatController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatController> _logger;
        private readonly ChatbotService _chatbotService;

        public ChatController(IConfiguration configuration, ILogger<ChatController> logger, ChatbotService chatbotService)
        {
            _configuration = configuration;
            _logger = logger;
            _chatbotService = chatbotService;
        }

        /// <summary>
        /// Tạo cuộc trò chuyện mới
        /// POST: api/Chat
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateChat([FromBody] CreateChatRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var maChat = $"CHAT-{Guid.NewGuid().ToString().Substring(0, 8)}";

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Tạo chat
                    string chatQuery = @"
                        INSERT INTO Chat (MaChat, MaNguoiDung, TieuDe, TrangThai, NgayTao)
                        VALUES (@MaChat, @MaNguoiDung, @TieuDe, @TrangThai, @NgayTao)";

                    using (var command = new SqlCommand(chatQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaChat", maChat);
                        command.Parameters.AddWithValue("@MaNguoiDung", request.MaNguoiDung);
                        command.Parameters.AddWithValue("@TieuDe", (object)request.TieuDe ?? DBNull.Value);
                        command.Parameters.AddWithValue("@TrangThai", "Open");
                        command.Parameters.AddWithValue("@NgayTao", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }

                    // Nếu có tin nhắn đầu tiên, tạo message
                    if (!string.IsNullOrEmpty(request.NoiDungTinNhanDau))
                    {
                        var maTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";
                        string messageQuery = @"
                            INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                            VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                        using (var command = new SqlCommand(messageQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaTinNhan", maTinNhan);
                            command.Parameters.AddWithValue("@MaChat", maChat);
                            command.Parameters.AddWithValue("@MaNguoiGui", request.MaNguoiDung);
                            command.Parameters.AddWithValue("@LoaiNguoiGui", "User");
                            command.Parameters.AddWithValue("@NoiDung", request.NoiDungTinNhanDau);
                            command.Parameters.AddWithValue("@DaDoc", false);
                            command.Parameters.AddWithValue("@NgayGui", DateTime.Now);

                            await command.ExecuteNonQueryAsync();
                        }

                        // Cập nhật tin nhắn cuối trong Chat
                        string updateChatQuery = @"
                            UPDATE Chat 
                            SET TinNhanCuoi = @TinNhanCuoi, NgayTinNhanCuoi = @NgayTinNhanCuoi
                            WHERE MaChat = @MaChat";

                        using (var command = new SqlCommand(updateChatQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaChat", maChat);
                            command.Parameters.AddWithValue("@TinNhanCuoi", request.NoiDungTinNhanDau.Length > 100 
                                ? request.NoiDungTinNhanDau.Substring(0, 100) 
                                : request.NoiDungTinNhanDau);
                            command.Parameters.AddWithValue("@NgayTinNhanCuoi", DateTime.Now);

                            await command.ExecuteNonQueryAsync();
                        }
                    }
                }

                return Ok(new { maChat = maChat, message = "Chat created successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating chat");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách chat của user
        /// GET: api/Chat/user/{maNguoiDung}
        /// </summary>
        [HttpGet("user/{maNguoiDung}")]
        public async Task<IActionResult> GetUserChats(string maNguoiDung)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var chats = new List<Chat>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = @"
                        SELECT c.MaChat, c.MaNguoiDung, c.MaAdmin, c.TieuDe, c.TrangThai, 
                               c.NgayTao, c.NgayCapNhat, c.TinNhanCuoi, c.NgayTinNhanCuoi,
                               (SELECT COUNT(*) FROM Message m WHERE m.MaChat = c.MaChat AND m.DaDoc = 0 AND m.MaNguoiGui != @MaNguoiDung) AS SoTinNhanChuaDoc
                        FROM Chat c
                        WHERE c.MaNguoiDung = @MaNguoiDung
                        ORDER BY c.NgayTinNhanCuoi DESC, c.NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaNguoiDung", maNguoiDung);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                chats.Add(new Chat
                                {
                                    MaChat = reader["MaChat"].ToString(),
                                    MaNguoiDung = reader["MaNguoiDung"].ToString(),
                                    MaAdmin = reader["MaAdmin"]?.ToString(),
                                    TieuDe = reader["TieuDe"]?.ToString(),
                                    TrangThai = reader["TrangThai"].ToString(),
                                    NgayTao = reader.GetDateTime(reader.GetOrdinal("NgayTao")),
                                    NgayCapNhat = reader.IsDBNull(reader.GetOrdinal("NgayCapNhat")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayCapNhat")),
                                    TinNhanCuoi = reader["TinNhanCuoi"]?.ToString(),
                                    NgayTinNhanCuoi = reader.IsDBNull(reader.GetOrdinal("NgayTinNhanCuoi")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayTinNhanCuoi")),
                                    SoTinNhanChuaDoc = reader["SoTinNhanChuaDoc"] == DBNull.Value
                                        ? 0
                                        : Convert.ToInt32(reader["SoTinNhanChuaDoc"])
                                });
                            }
                        }
                    }
                }

                return Ok(chats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user chats");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách chat cho admin (tất cả các chat)
        /// GET: api/Chat/admin
        /// </summary>
        [HttpGet("admin")]
        public async Task<IActionResult> GetAdminChats()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var chats = new List<Chat>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = @"
                        SELECT c.MaChat, c.MaNguoiDung, c.MaAdmin, c.TieuDe, c.TrangThai, 
                               c.NgayTao, c.NgayCapNhat, c.TinNhanCuoi, c.NgayTinNhanCuoi,
                               u.HoTen AS TenNguoiDung,
                               (SELECT COUNT(*) FROM Message m WHERE m.MaChat = c.MaChat AND m.DaDoc = 0 AND m.LoaiNguoiGui = 'User') AS SoTinNhanChuaDoc
                        FROM Chat c
                        LEFT JOIN NguoiDung u ON c.MaNguoiDung = u.MaTaiKhoan
                        ORDER BY c.NgayTinNhanCuoi DESC, c.NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            chats.Add(new Chat
                            {
                                MaChat = reader["MaChat"].ToString(),
                                MaNguoiDung = reader["MaNguoiDung"].ToString(),
                                MaAdmin = reader["MaAdmin"]?.ToString(),
                                TieuDe = reader["TieuDe"]?.ToString(),
                                TrangThai = reader["TrangThai"].ToString(),
                                NgayTao = reader.GetDateTime(reader.GetOrdinal("NgayTao")),
                                NgayCapNhat = reader.IsDBNull(reader.GetOrdinal("NgayCapNhat")) 
                                    ? null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgayCapNhat")),
                                TinNhanCuoi = reader["TinNhanCuoi"]?.ToString(),
                                NgayTinNhanCuoi = reader.IsDBNull(reader.GetOrdinal("NgayTinNhanCuoi")) 
                                    ? null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgayTinNhanCuoi")),
                                SoTinNhanChuaDoc = reader["SoTinNhanChuaDoc"] == DBNull.Value
                                    ? 0
                                    : Convert.ToInt32(reader["SoTinNhanChuaDoc"]),
                                NguoiDung = reader["TenNguoiDung"] != DBNull.Value 
                                    ? new User { HoTen = reader["TenNguoiDung"].ToString() } 
                                    : null
                            });
                        }
                    }
                }

                return Ok(chats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting admin chats");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy tin nhắn của một chat
        /// GET: api/Chat/{maChat}/messages
        /// </summary>
        [HttpGet("{maChat}/messages")]
        public async Task<IActionResult> GetMessages(string maChat)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var messages = new List<Message>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = @"
                        SELECT m.MaTinNhan, m.MaChat, m.MaNguoiGui, m.LoaiNguoiGui, m.NoiDung, 
                               m.DaDoc, m.NgayGui, m.NgayDoc, u.HoTen AS TenNguoiGui
                        FROM Message m
                        LEFT JOIN NguoiDung u ON m.MaNguoiGui = u.MaTaiKhoan
                        WHERE m.MaChat = @MaChat
                        ORDER BY m.NgayGui ASC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaChat", maChat);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                messages.Add(new Message
                                {
                                    MaTinNhan = reader["MaTinNhan"].ToString(),
                                    MaChat = reader["MaChat"].ToString(),
                                    MaNguoiGui = reader["MaNguoiGui"].ToString(),
                                    LoaiNguoiGui = reader["LoaiNguoiGui"].ToString(),
                                    NoiDung = reader["NoiDung"].ToString(),
                                    DaDoc = Convert.ToBoolean(reader["DaDoc"]),
                                    NgayGui = reader.GetDateTime(reader.GetOrdinal("NgayGui")),
                                    NgayDoc = reader.IsDBNull(reader.GetOrdinal("NgayDoc")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayDoc")),
                                    NguoiGui = reader["TenNguoiGui"] != DBNull.Value 
                                        ? new User { HoTen = reader["TenNguoiGui"].ToString() } 
                                        : null
                                });
                            }
                        }
                    }
                }

                return Ok(messages);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting messages");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Gửi tin nhắn
        /// POST: api/Chat/message
        /// </summary>
        [HttpPost("message")]
        public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var maTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Tạo message
                    string messageQuery = @"
                        INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                        VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                    using (var command = new SqlCommand(messageQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTinNhan", maTinNhan);
                        command.Parameters.AddWithValue("@MaChat", request.MaChat);
                        command.Parameters.AddWithValue("@MaNguoiGui", request.MaNguoiGui);
                        command.Parameters.AddWithValue("@LoaiNguoiGui", request.LoaiNguoiGui);
                        command.Parameters.AddWithValue("@NoiDung", request.NoiDung);
                        command.Parameters.AddWithValue("@DaDoc", false);
                        command.Parameters.AddWithValue("@NgayGui", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }

                    // Cập nhật tin nhắn cuối trong Chat
                    string updateChatQuery = @"
                        UPDATE Chat 
                        SET TinNhanCuoi = @TinNhanCuoi, 
                            NgayTinNhanCuoi = @NgayTinNhanCuoi,
                            NgayCapNhat = @NgayCapNhat
                        WHERE MaChat = @MaChat";

                    using (var command = new SqlCommand(updateChatQuery, connection))
                    {
                        var preview = request.NoiDung.Length > 100 
                            ? request.NoiDung.Substring(0, 100) 
                            : request.NoiDung;

                        command.Parameters.AddWithValue("@MaChat", request.MaChat);
                        command.Parameters.AddWithValue("@TinNhanCuoi", preview);
                        command.Parameters.AddWithValue("@NgayTinNhanCuoi", DateTime.Now);
                        command.Parameters.AddWithValue("@NgayCapNhat", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }

                    // Nếu admin gửi tin nhắn đầu tiên, cập nhật MaAdmin
                    if (request.LoaiNguoiGui == "Admin")
                    {
                        string updateAdminQuery = @"
                            UPDATE Chat 
                            SET MaAdmin = @MaAdmin
                            WHERE MaChat = @MaChat AND MaAdmin IS NULL";

                        using (var command = new SqlCommand(updateAdminQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaChat", request.MaChat);
                            command.Parameters.AddWithValue("@MaAdmin", request.MaNguoiGui);
                            await command.ExecuteNonQueryAsync();
                        }
                    }

                    // Nếu user gửi tin nhắn, chatbot tự động trả lời sau 2 giây
                    if (request.LoaiNguoiGui == "User")
                    {
                        // Xử lý tin nhắn bằng chatbot trong background (không block response)
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                await Task.Delay(2000); // Đợi 2 giây trước khi trả lời (tự nhiên hơn)
                                
                                // Xử lý tin nhắn bằng chatbot (có thể gọi AI nếu cần)
                                var botResponse = await _chatbotService.ProcessMessageAsync(request.NoiDung, request.MaChat);
                                
                                if (!string.IsNullOrEmpty(botResponse))
                                {
                                    var botMaTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";
                                    
                                    using (var botConnection = new SqlConnection(connectionString))
                                    {
                                        await botConnection.OpenAsync();
                                        
                                        // Tạo tin nhắn từ chatbot
                                        string botMessageQuery = @"
                                            INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                                            VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                                        using (var botCommand = new SqlCommand(botMessageQuery, botConnection))
                                        {
                                            botCommand.Parameters.AddWithValue("@MaTinNhan", botMaTinNhan);
                                            botCommand.Parameters.AddWithValue("@MaChat", request.MaChat);
                                            botCommand.Parameters.AddWithValue("@MaNguoiGui", "BOT"); // Mã chatbot
                                            botCommand.Parameters.AddWithValue("@LoaiNguoiGui", "Admin"); // Hiển thị như admin
                                            botCommand.Parameters.AddWithValue("@NoiDung", botResponse);
                                            botCommand.Parameters.AddWithValue("@DaDoc", false);
                                            botCommand.Parameters.AddWithValue("@NgayGui", DateTime.Now);

                                            await botCommand.ExecuteNonQueryAsync();
                                        }

                                        // Cập nhật tin nhắn cuối trong Chat
                                        string updateChatQuery = @"
                                            UPDATE Chat 
                                            SET TinNhanCuoi = @TinNhanCuoi, 
                                                NgayTinNhanCuoi = @NgayTinNhanCuoi,
                                                NgayCapNhat = @NgayCapNhat
                                            WHERE MaChat = @MaChat";

                                        using (var updateCommand = new SqlCommand(updateChatQuery, botConnection))
                                        {
                                            var preview = botResponse.Length > 100 
                                                ? botResponse.Substring(0, 100) 
                                                : botResponse;

                                            updateCommand.Parameters.AddWithValue("@MaChat", request.MaChat);
                                            updateCommand.Parameters.AddWithValue("@TinNhanCuoi", preview);
                                            updateCommand.Parameters.AddWithValue("@NgayTinNhanCuoi", DateTime.Now);
                                            updateCommand.Parameters.AddWithValue("@NgayCapNhat", DateTime.Now);

                                            await updateCommand.ExecuteNonQueryAsync();
                                        }
                                    }
                                    
                                    _logger.LogInformation($"Chatbot auto-replied to chat {request.MaChat}");
                                }
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"Error sending chatbot auto-reply for chat {request.MaChat}");
                            }
                        });
                    }
                }

                return Ok(new { maTinNhan = maTinNhan, message = "Message sent successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Đánh dấu tin nhắn đã đọc
        /// PUT: api/Chat/{maChat}/read
        /// </summary>
        [HttpPut("{maChat}/read")]
        public async Task<IActionResult> MarkAsRead(string maChat, [FromBody] MarkAsReadRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Đánh dấu tất cả tin nhắn của đối phương là đã đọc
                    string query = @"
                        UPDATE Message 
                        SET DaDoc = 1, NgayDoc = @NgayDoc
                        WHERE MaChat = @MaChat 
                          AND MaNguoiGui != @MaNguoiDoc
                        AND DaDoc = 0";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaChat", maChat);
                        command.Parameters.AddWithValue("@MaNguoiDoc", request.MaNguoiDoc);
                        command.Parameters.AddWithValue("@NgayDoc", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }
                }

                return Ok(new { message = "Messages marked as read" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking messages as read");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Đóng chat
        /// PUT: api/Chat/{maChat}/close
        /// </summary>
        [HttpPut("{maChat}/close")]
        public async Task<IActionResult> CloseChat(string maChat)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = @"
                        UPDATE Chat 
                        SET TrangThai = 'Closed', NgayCapNhat = @NgayCapNhat
                        WHERE MaChat = @MaChat";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaChat", maChat);
                        command.Parameters.AddWithValue("@NgayCapNhat", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }
                }

                return Ok(new { message = "Chat closed successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing chat");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class MarkAsReadRequest
    {
        public string MaNguoiDoc { get; set; }
    }
}

