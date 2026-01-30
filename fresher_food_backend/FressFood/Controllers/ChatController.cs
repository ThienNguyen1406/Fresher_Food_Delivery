using FressFood.Models;
using FressFood.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Text;
using System.Linq;
using System.Text.Json;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChatController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatController> _logger;
        private readonly ChatbotService _chatbotService;
        private readonly PythonRAGService _ragService;
        private readonly IFunctionHandler _functionHandler;

        public ChatController(
            IConfiguration configuration,
            ILogger<ChatController> logger,
            ChatbotService chatbotService,
            PythonRAGService ragService,
            IFunctionHandler functionHandler)
        {
            _configuration = configuration;
            _logger = logger;
            _chatbotService = chatbotService;
            _ragService = ragService;
            _functionHandler = functionHandler;
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
                string? initialTitle = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Phân biệt 2 loại chat:
                    // 1. User chat với admin (có noiDungTinNhanDau) → TieuDe = tên user
                    // 2. RAG chat (không có noiDungTinNhanDau) → TieuDe = null (sẽ cập nhật từ tin nhắn đầu tiên)
                    if (!string.IsNullOrEmpty(request.NoiDungTinNhanDau))
                    {
                        // Đây là user chat với admin → lấy tên user làm TieuDe
                        string getUserNameQuery = @"
                            SELECT HoTen, TenNguoiDung 
                            FROM NguoiDung 
                            WHERE MaTaiKhoan = @MaTaiKhoan";
                        
                        using (var command = new SqlCommand(getUserNameQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaTaiKhoan", request.MaNguoiDung);
                            using (var reader = await command.ExecuteReaderAsync())
                            {
                                if (await reader.ReadAsync())
                                {
                                    initialTitle = reader["HoTen"]?.ToString() ?? reader["TenNguoiDung"]?.ToString();
                                }
                            }
                        }
                    }
                    else
                    {
                        // Đây là RAG chat → để TieuDe null hoặc mặc định (sẽ cập nhật từ tin nhắn đầu tiên)
                        initialTitle = request.TieuDe;
                    }

                    // Tạo chat
                    // Nếu là RAG chat (không có noiDungTinNhanDau), set MaAdmin = 'BOT' để đánh dấu đây là RAG chat
                    // Nếu là user chat với admin, để MaAdmin = NULL (sẽ được set khi admin nhận chat)
                    string? maAdminForRagChat = string.IsNullOrEmpty(request.NoiDungTinNhanDau) ? "BOT" : null;
                    
                    string chatQuery = @"
                        INSERT INTO Chat (MaChat, MaNguoiDung, MaAdmin, TieuDe, TrangThai, NgayTao)
                        VALUES (@MaChat, @MaNguoiDung, @MaAdmin, @TieuDe, @TrangThai, @NgayTao)";

                    using (var command = new SqlCommand(chatQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaChat", maChat);
                        command.Parameters.AddWithValue("@MaNguoiDung", request.MaNguoiDung);
                        command.Parameters.AddWithValue("@MaAdmin", (object)maAdminForRagChat ?? DBNull.Value);
                        command.Parameters.AddWithValue("@TieuDe", (object)initialTitle ?? DBNull.Value);
                        command.Parameters.AddWithValue("@TrangThai", "Open");
                        command.Parameters.AddWithValue("@NgayTao", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }

                    _logger.LogInformation($"Created chat: MaChat={maChat}, isRagChat={string.IsNullOrEmpty(request.NoiDungTinNhanDau)}, MaAdmin={maAdminForRagChat ?? "NULL"}");

                    // Tự động tạo tin nhắn chào từ bot (chỉ cho RAG chat, không cho user chat với admin)
                    if (string.IsNullOrEmpty(request.NoiDungTinNhanDau))
                    {
                        var greetingMessage = "Xin chào hôm nay mình có thể giúp gì cho bạn";
                        var botMaTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";
                        string botMessageQuery = @"
                            INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                            VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                        using (var command = new SqlCommand(botMessageQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaTinNhan", botMaTinNhan);
                            command.Parameters.AddWithValue("@MaChat", maChat);
                            command.Parameters.AddWithValue("@MaNguoiGui", "BOT");
                            command.Parameters.AddWithValue("@LoaiNguoiGui", "Admin");
                            command.Parameters.AddWithValue("@NoiDung", greetingMessage);
                            command.Parameters.AddWithValue("@DaDoc", false);
                            command.Parameters.AddWithValue("@NgayGui", DateTime.Now);

                            await command.ExecuteNonQueryAsync();
                        }

                        // Cập nhật TinNhanCuoi là tin nhắn chào
                        string updateChatQuery = @"
                            UPDATE Chat 
                            SET TinNhanCuoi = @TinNhanCuoi, NgayTinNhanCuoi = @NgayTinNhanCuoi
                            WHERE MaChat = @MaChat";

                        using (var command = new SqlCommand(updateChatQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaChat", maChat);
                            command.Parameters.AddWithValue("@TinNhanCuoi", greetingMessage);
                            command.Parameters.AddWithValue("@NgayTinNhanCuoi", DateTime.Now);

                            await command.ExecuteNonQueryAsync();
                        }
                    }

                    // Nếu có tin nhắn đầu tiên từ user (user chat với admin), tạo message
                    if (!string.IsNullOrEmpty(request.NoiDungTinNhanDau))
                    {
                        var userMaTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";
                        string userMessageQuery = @"
                            INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                            VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                        using (var command = new SqlCommand(userMessageQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaTinNhan", userMaTinNhan);
                            command.Parameters.AddWithValue("@MaChat", maChat);
                            command.Parameters.AddWithValue("@MaNguoiGui", request.MaNguoiDung);
                            command.Parameters.AddWithValue("@LoaiNguoiGui", "User");
                            command.Parameters.AddWithValue("@NoiDung", request.NoiDungTinNhanDau);
                            command.Parameters.AddWithValue("@DaDoc", false);
                            command.Parameters.AddWithValue("@NgayGui", DateTime.Now);

                            await command.ExecuteNonQueryAsync();
                        }

                        // Cập nhật TinNhanCuoi
                        string updateChatQuery = @"
                            UPDATE Chat 
                            SET TinNhanCuoi = @TinNhanCuoi, NgayTinNhanCuoi = @NgayTinNhanCuoi
                            WHERE MaChat = @MaChat";

                        using (var command = new SqlCommand(updateChatQuery, connection))
                        {
                            var lastMessagePreview = request.NoiDungTinNhanDau.Length > 100 
                                ? request.NoiDungTinNhanDau.Substring(0, 100) 
                                : request.NoiDungTinNhanDau;

                            command.Parameters.AddWithValue("@MaChat", maChat);
                            command.Parameters.AddWithValue("@TinNhanCuoi", lastMessagePreview);
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
                                        ? (DateTime?)null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayCapNhat")),
                                    TinNhanCuoi = reader["TinNhanCuoi"]?.ToString(),
                                    NgayTinNhanCuoi = reader.IsDBNull(reader.GetOrdinal("NgayTinNhanCuoi")) 
                                        ? (DateTime?)null 
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
        /// Lấy danh sách chat cho admin (chỉ chat của user, không bao gồm RAG chat)
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

                    // Chỉ lấy chat của user (VaiTro != 'Admin')
                    // Loại bỏ RAG chat (chat có tin nhắn chào từ BOT)
                    string query = @"
                        SELECT DISTINCT c.MaChat, c.MaNguoiDung, c.MaAdmin, c.TieuDe, c.TrangThai, 
                               c.NgayTao, c.NgayCapNhat, c.TinNhanCuoi, c.NgayTinNhanCuoi,
                               u.HoTen AS TenNguoiDung,
                               (SELECT COUNT(*) FROM Message m WHERE m.MaChat = c.MaChat AND m.DaDoc = 0 AND m.LoaiNguoiGui = 'User') AS SoTinNhanChuaDoc
                        FROM Chat c
                        LEFT JOIN NguoiDung u ON c.MaNguoiDung = u.MaTaiKhoan
                        WHERE (u.VaiTro IS NULL OR (u.VaiTro <> 'Admin' AND u.VaiTro <> N'Admin'))
                          AND c.MaChat NOT IN (
                              SELECT DISTINCT m.MaChat 
                              FROM Message m 
                              WHERE m.MaNguoiGui = 'BOT' 
                                AND m.NoiDung LIKE '%Xin chào hôm nay mình có thể giúp gì cho bạn%'
                          )
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
                                    ? (DateTime?)null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgayCapNhat")),
                                TinNhanCuoi = reader["TinNhanCuoi"]?.ToString(),
                                NgayTinNhanCuoi = reader.IsDBNull(reader.GetOrdinal("NgayTinNhanCuoi")) 
                                    ? (DateTime?)null 
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

                _logger.LogInformation($"Retrieved {chats.Count} user chats for admin management (RAG chats excluded)");
                return Ok(chats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting admin chats");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy tin nhắn của một chat với pagination
        /// GET: api/Chat/{maChat}/messages?limit=10&beforeMessageId=xxx
        /// </summary>
        [HttpGet("{maChat}/messages")]
        public async Task<IActionResult> GetMessages(string maChat, [FromQuery] int limit = 10, [FromQuery] string? beforeMessageId = null)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var messages = new List<Message>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Lấy tổng số tin nhắn để biết còn tin nhắn cũ hơn không
                    string countQuery = @"SELECT COUNT(*) FROM Message WHERE MaChat = @MaChat";
                    int totalMessages = 0;
                    using (var countCommand = new SqlCommand(countQuery, connection))
                    {
                        countCommand.Parameters.AddWithValue("@MaChat", maChat);
                        totalMessages = Convert.ToInt32(await countCommand.ExecuteScalarAsync());
                    }

                    // Query với pagination - lấy N tin nhắn gần nhất
                    string query;
                    if (!string.IsNullOrEmpty(beforeMessageId))
                    {
                        // Load more: lấy tin nhắn cũ hơn tin nhắn có ID = beforeMessageId
                        query = @"
                            SELECT TOP (@Limit) m.MaTinNhan, m.MaChat, m.MaNguoiGui, m.LoaiNguoiGui, m.NoiDung, 
                               m.DaDoc, m.NgayGui, m.NgayDoc, u.HoTen AS TenNguoiGui
                        FROM Message m
                        LEFT JOIN NguoiDung u ON m.MaNguoiGui = u.MaTaiKhoan
                        WHERE m.MaChat = @MaChat
                              AND m.NgayGui < (SELECT NgayGui FROM Message WHERE MaTinNhan = @BeforeMessageId)
                            ORDER BY m.NgayGui DESC";
                    }
                    else
                    {
                        // Lần đầu: lấy N tin nhắn gần nhất
                        query = @"
                            SELECT TOP (@Limit) m.MaTinNhan, m.MaChat, m.MaNguoiGui, m.LoaiNguoiGui, m.NoiDung, 
                                   m.DaDoc, m.NgayGui, m.NgayDoc, u.HoTen AS TenNguoiGui
                            FROM Message m
                            LEFT JOIN NguoiDung u ON m.MaNguoiGui = u.MaTaiKhoan
                            WHERE m.MaChat = @MaChat
                            ORDER BY m.NgayGui DESC";
                    }

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaChat", maChat);
                        command.Parameters.AddWithValue("@Limit", limit);
                        if (!string.IsNullOrEmpty(beforeMessageId))
                        {
                            command.Parameters.AddWithValue("@BeforeMessageId", beforeMessageId);
                        }

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
                                        ? (DateTime?)null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayDoc")),
                                    NguoiGui = reader["TenNguoiGui"] != DBNull.Value 
                                        ? new User { HoTen = reader["TenNguoiGui"].ToString() } 
                                        : null
                                });
                            }
                        }
                    }

                    // Đảo ngược để tin nhắn cũ nhất lên đầu (cho frontend hiển thị đúng)
                    messages.Reverse();

                    // Tính hasMore: còn tin nhắn cũ hơn không?
                    bool hasMore = false;
                    if (messages.Count > 0)
                    {
                        // Nếu số tin nhắn trả về = limit, có thể còn tin nhắn cũ hơn
                        if (messages.Count == limit)
                        {
                            // Kiểm tra xem còn tin nhắn cũ hơn tin nhắn đầu tiên không
                            var oldestMessage = messages[0];
                            string checkQuery = @"SELECT COUNT(*) FROM Message 
                                                WHERE MaChat = @MaChat 
                                                AND NgayGui < @OldestDate";
                            using (var checkCommand = new SqlCommand(checkQuery, connection))
                            {
                                checkCommand.Parameters.AddWithValue("@MaChat", maChat);
                                checkCommand.Parameters.AddWithValue("@OldestDate", oldestMessage.NgayGui);
                                var olderCount = Convert.ToInt32(await checkCommand.ExecuteScalarAsync());
                                hasMore = olderCount > 0;
                            }
                        }
                        else
                        {
                            // Nếu số tin nhắn < limit, không còn tin nhắn cũ hơn
                            hasMore = false;
                        }
                    }

                    // Trả về với metadata về pagination
                    return Ok(new
                    {
                        messages = messages,
                        hasMore = hasMore,
                        totalCount = totalMessages
                    });
                }
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

                    // Nếu user gửi tin nhắn, kiểm tra xem có cần cập nhật TieuDe không
                    if (request.LoaiNguoiGui == "User")
                    {
                        // Kiểm tra xem đây có phải là tin nhắn đầu tiên của user không
                        string checkFirstMessageQuery = @"
                            SELECT COUNT(*) 
                            FROM Message 
                            WHERE MaChat = @MaChat AND LoaiNguoiGui = 'User'";
                        
                        int userMessageCount = 0;
                        using (var checkCommand = new SqlCommand(checkFirstMessageQuery, connection))
                        {
                            checkCommand.Parameters.AddWithValue("@MaChat", request.MaChat);
                            userMessageCount = (int)await checkCommand.ExecuteScalarAsync();
                        }
                        
                        // Kiểm tra xem TieuDe hiện tại có phải là tên user không (user chat với admin)
                        // Nếu TieuDe là null hoặc rỗng → đây là RAG chat → cập nhật từ tin nhắn đầu tiên
                        string getCurrentTitleQuery = @"
                            SELECT TieuDe 
                            FROM Chat 
                            WHERE MaChat = @MaChat";
                        
                        string? currentTitle = null;
                        using (var getTitleCommand = new SqlCommand(getCurrentTitleQuery, connection))
                        {
                            getTitleCommand.Parameters.AddWithValue("@MaChat", request.MaChat);
                            var titleResult = await getTitleCommand.ExecuteScalarAsync();
                            currentTitle = titleResult?.ToString();
                        }
                        
                        // Nếu đây là tin nhắn đầu tiên của user VÀ TieuDe là null/rỗng (RAG chat)
                        // → cập nhật TieuDe từ tin nhắn
                        if (userMessageCount == 1 && string.IsNullOrEmpty(currentTitle))
                        {
                            string updateTitleQuery = @"
                                UPDATE Chat 
                                SET TieuDe = @TieuDe, 
                                    TinNhanCuoi = @TinNhanCuoi, 
                                    NgayTinNhanCuoi = @NgayTinNhanCuoi,
                                    NgayCapNhat = @NgayCapNhat
                                WHERE MaChat = @MaChat";

                            using (var command = new SqlCommand(updateTitleQuery, connection))
                            {
                                var titlePreview = request.NoiDung.Length > 50 
                                    ? request.NoiDung.Substring(0, 50) 
                                    : request.NoiDung;
                                
                                var lastMessagePreview = request.NoiDung.Length > 100 
                                    ? request.NoiDung.Substring(0, 100) 
                                    : request.NoiDung;

                                command.Parameters.AddWithValue("@MaChat", request.MaChat);
                                command.Parameters.AddWithValue("@TieuDe", titlePreview);
                                command.Parameters.AddWithValue("@TinNhanCuoi", lastMessagePreview);
                                command.Parameters.AddWithValue("@NgayTinNhanCuoi", DateTime.Now);
                                command.Parameters.AddWithValue("@NgayCapNhat", DateTime.Now);

                                await command.ExecuteNonQueryAsync();
                            }
                        }
                        else
                        {
                            // Chỉ cập nhật tin nhắn cuối
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
                        }
                    }
                    else
                    {
                        // Admin gửi tin nhắn, chỉ cập nhật tin nhắn cuối
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
                    // Phân biệt 2 trường hợp:
                    // 1. User chat với admin (admin chat management) → không dùng RAG
                    // 2. RAG chat (admin tạo conversation để query RAG) → dùng RAG
                    if (request.LoaiNguoiGui == "User")
                    {
                        _logger.LogInformation($"[SendMessage] User message received. MaChat={request.MaChat}, Message='{request.NoiDung}'");
                        
                        // Đơn giản hóa logic: Bot sẽ LUÔN phản hồi trừ khi đã có admin thật trả lời
                        // Điều này đảm bảo user luôn nhận được phản hồi, kể cả khi không có RAG context
                        bool hasRealAdminMessage = false;
                        
                        try
                        {
                            _logger.LogInformation($"[SendMessage] Checking if admin has replied for MaChat={request.MaChat}");
                            
                            // Chỉ kiểm tra xem có tin nhắn từ admin thật (không phải BOT) trong chat chưa
                            // Nếu đã có tin nhắn từ admin thật → không cần bot tự động phản hồi
                            string checkAdminMessageQuery = @"
                                SELECT COUNT(*) 
                                FROM Message m
                                WHERE m.MaChat = @MaChat 
                                  AND m.LoaiNguoiGui = 'Admin' 
                                  AND m.MaNguoiGui != 'BOT'
                                  AND m.MaNguoiGui IS NOT NULL
                                  AND m.MaNguoiGui != ''";
                            
                            using (var checkAdminMessageCommand = new SqlCommand(checkAdminMessageQuery, connection))
                            {
                                checkAdminMessageCommand.Parameters.AddWithValue("@MaChat", request.MaChat);
                                var adminMessageCount = (int)await checkAdminMessageCommand.ExecuteScalarAsync();
                                hasRealAdminMessage = adminMessageCount > 0;
                                _logger.LogInformation($"[SendMessage] Admin message check: hasRealAdminMessage={hasRealAdminMessage}, count={adminMessageCount}");
                            }
                        }
                        catch (Exception checkEx)
                        {
                            _logger.LogWarning(checkEx, "Failed to check admin messages, defaulting to allow bot reply");
                            // Nếu không kiểm tra được, mặc định cho phép bot phản hồi (an toàn hơn cho user)
                            hasRealAdminMessage = false;
                        }
                        
                        // Bot sẽ tự động phản hồi TRỪ KHI đã có admin thật trả lời
                        // Điều này đảm bảo user luôn nhận được phản hồi, kể cả khi không có RAG context
                        if (!hasRealAdminMessage)
                        {
                            _logger.LogInformation($"Starting auto-reply process. hasRealAdminMessage={hasRealAdminMessage}, MaChat={request.MaChat}, Message='{request.NoiDung}'");
                            
                            // Capture connectionString để dùng trong Task.Run
                            var capturedConnectionString = connectionString;
                            var capturedMaChat = request.MaChat;
                            var capturedNoiDung = request.NoiDung;
                            
                        // Xử lý tin nhắn bằng chatbot trong background (không block response)
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                    _logger.LogInformation($"[Task.Run] Started for chat {capturedMaChat}, waiting 2 seconds...");
                                await Task.Delay(2000); // Đợi 2 giây trước khi trả lời (tự nhiên hơn)
                                    _logger.LogInformation($"[Task.Run] Starting to process message for chat {capturedMaChat}: '{capturedNoiDung}'");
                                    
                                    // Lấy conversation history để có context
                                    List<Message> conversationHistory = new List<Message>();
                                    try
                                    {
                                        _logger.LogInformation($"[Task.Run] Loading conversation history for chat {capturedMaChat}");
                                        using (var historyConnection = new SqlConnection(capturedConnectionString))
                                        {
                                            await historyConnection.OpenAsync();
                                            string historyQuery = @"
                                                SELECT TOP 10 m.MaTinNhan, m.MaChat, m.MaNguoiGui, m.LoaiNguoiGui, m.NoiDung, 
                                                       m.DaDoc, m.NgayGui, m.NgayDoc
                                                FROM Message m
                                                WHERE m.MaChat = @MaChat
                                                ORDER BY m.NgayGui DESC";

                                            using (var historyCommand = new SqlCommand(historyQuery, historyConnection))
                                            {
                                                historyCommand.Parameters.AddWithValue("@MaChat", capturedMaChat);
                                                using (var reader = await historyCommand.ExecuteReaderAsync())
                                                {
                                                    while (await reader.ReadAsync())
                                                    {
                                                        conversationHistory.Add(new Message
                                                        {
                                                            MaTinNhan = reader["MaTinNhan"].ToString(),
                                                            MaChat = reader["MaChat"].ToString(),
                                                            MaNguoiGui = reader["MaNguoiGui"].ToString(),
                                                            LoaiNguoiGui = reader["LoaiNguoiGui"].ToString(),
                                                            NoiDung = reader["NoiDung"].ToString(),
                                                            DaDoc = Convert.ToBoolean(reader["DaDoc"]),
                                                            NgayGui = reader.GetDateTime(reader.GetOrdinal("NgayGui")),
                                                            NgayDoc = reader.IsDBNull(reader.GetOrdinal("NgayDoc"))
                                                                ? (DateTime?)null
                                                                : reader.GetDateTime(reader.GetOrdinal("NgayDoc"))
                                                        });
                                                    }
                                                }
                                            }
                                        }
                                        // Đảo ngược để có thứ tự từ cũ đến mới
                                        conversationHistory.Reverse();
                                    }
                                    catch (Exception historyEx)
                                    {
                                        _logger.LogWarning(historyEx, "Failed to retrieve conversation history");
                                    }
                                    
                                    // ✅ ƯU TIÊN: Kiểm tra nếu user yêu cầu "top sản phẩm bán chạy" (kể cả có từ 'hình ảnh')
                                    if (_chatbotService.IsTopProductsRequest(capturedNoiDung))
                                    {
                                        var limit = _chatbotService.ExtractTopProductsLimit(capturedNoiDung, defaultLimit: 3);
                                        _logger.LogInformation($"[Task.Run] User requested top products: limit={limit}, question='{capturedNoiDung}'");

                                        try
                                        {
                                            var functionResultRaw = await _functionHandler.ExecuteFunctionAsync(
                                                "getBestSellingProductImage",
                                                new Dictionary<string, object> { { "limit", limit } }
                                            );

                                            if (!string.IsNullOrWhiteSpace(functionResultRaw))
                                            {
                                                // FunctionHandlerService trả về JSON: { result: "...", success: true/false, ... }
                                                using var doc = JsonDocument.Parse(functionResultRaw);
                                                var root = doc.RootElement;

                                                if (root.TryGetProperty("success", out var successProp) && successProp.GetBoolean()
                                                    && root.TryGetProperty("result", out var resultProp))
                                                {
                                                    var inner = resultProp.GetString() ?? "";
                                                    using var innerDoc = JsonDocument.Parse(inner);
                                                    var innerRoot = innerDoc.RootElement;

                                                    // products có thể là object (limit=1) hoặc array (limit>1)
                                                    var productsElement = innerRoot.GetProperty("products");
                                                    var productsList = new List<object>();

                                                    if (productsElement.ValueKind == JsonValueKind.Array)
                                                    {
                                                        foreach (var p in productsElement.EnumerateArray())
                                                        {
                                                            productsList.Add(new
                                                            {
                                                                productId = p.GetProperty("maSanPham").GetString() ?? "",
                                                                productName = p.GetProperty("tenSanPham").GetString() ?? "",
                                                                categoryId = "",
                                                                categoryName = null as string,
                                                                price = p.TryGetProperty("giaBan", out var priceProp) ? priceProp.GetDouble() : (double?)null,
                                                                description = (string?)null,
                                                                imageData = p.TryGetProperty("imageData", out var imgProp) ? imgProp.GetString() : null,
                                                                imageMimeType = p.TryGetProperty("imageMimeType", out var mimeProp) ? mimeProp.GetString() : null,
                                                                similarity = 1.0
                                                            });
                                                        }
                                                    }
                                                    else if (productsElement.ValueKind == JsonValueKind.Object)
                                                    {
                                                        var p = productsElement;
                                                        productsList.Add(new
                                                        {
                                                            productId = p.GetProperty("maSanPham").GetString() ?? "",
                                                            productName = p.GetProperty("tenSanPham").GetString() ?? "",
                                                            categoryId = "",
                                                            categoryName = null as string,
                                                            price = p.TryGetProperty("giaBan", out var priceProp) ? priceProp.GetDouble() : (double?)null,
                                                            description = (string?)null,
                                                            imageData = p.TryGetProperty("imageData", out var imgProp) ? imgProp.GetString() : null,
                                                            imageMimeType = p.TryGetProperty("imageMimeType", out var mimeProp) ? mimeProp.GetString() : null,
                                                            similarity = 1.0
                                                        });
                                                    }

                                                    var answer = innerRoot.TryGetProperty("message", out var msgProp) ? msgProp.GetString() : null;
                                                    if (string.IsNullOrWhiteSpace(answer))
                                                    {
                                                        answer = $"Tôi tìm thấy {productsList.Count} sản phẩm bán chạy nhất.";
                                                    }

                                                    // Tạo tin nhắn bot với products (JSON format để frontend parse)
                                                    var productsJson = System.Text.Json.JsonSerializer.Serialize(new
                                                    {
                                                        message = answer,
                                                        hasImages = true,
                                                        products = productsList
                                                    });

                                                    // Tạo message content: Text message + JSON data (frontend sẽ parse)
                                                    var botMessageContent = $"{answer}\n\n[PRODUCTS_DATA]{productsJson}[/PRODUCTS_DATA]";

                                                    // Lưu tin nhắn bot vào database
                                                    using (var botConnection = new SqlConnection(capturedConnectionString))
                                                    {
                                                        await botConnection.OpenAsync();
                                                        string insertBotMessageQuery = @"
                                                            INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                                                            VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                                                        using (var botCommand = new SqlCommand(insertBotMessageQuery, botConnection))
                                                        {
                                                            botCommand.Parameters.AddWithValue("@MaTinNhan", $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}");
                                                            botCommand.Parameters.AddWithValue("@MaChat", capturedMaChat);
                                                            botCommand.Parameters.AddWithValue("@MaNguoiGui", "BOT");
                                                            botCommand.Parameters.AddWithValue("@LoaiNguoiGui", "Bot");
                                                            botCommand.Parameters.AddWithValue("@NoiDung", botMessageContent);
                                                            botCommand.Parameters.AddWithValue("@DaDoc", false);
                                                            botCommand.Parameters.AddWithValue("@NgayGui", DateTime.Now);
                                                            await botCommand.ExecuteNonQueryAsync();
                                                        }
                                                    }

                                                    _logger.LogInformation($"[Task.Run] Bot replied with {productsList.Count} top products (with images)");
                                                    return; // Exit early, không cần xử lý tiếp
                                                }
                                            }
                                        }
                                        catch (Exception topEx)
                                        {
                                            _logger.LogError(topEx, $"[Task.Run] Error getting top products: {topEx.Message}");
                                            // Fall through to normal processing
                                        }
                                    }
                                    
                                    // Kiểm tra nếu user yêu cầu ảnh sản phẩm
                                    if (_chatbotService.IsImageRequest(capturedNoiDung))
                                    {
                                        _logger.LogInformation($"[Task.Run] User requested product image: '{capturedNoiDung}'");
                                        
                                        try
                                        {
                                            // Extract product name từ message
                                            var productName = _chatbotService.ExtractProductNameFromImageRequest(capturedNoiDung);
                                            var searchQuery = productName ?? capturedNoiDung;
                                            
                                            _logger.LogInformation($"[Task.Run] Searching products for: '{searchQuery}'");
                                            
                                            // Search products từ RAG service
                                            var productsResponse = await _ragService.SearchProductsForChatAsync(searchQuery, categoryId: null, topK: 5);
                                            
                                            if (productsResponse != null && productsResponse.Products != null && productsResponse.Products.Count > 0)
                                            {
                                                // Tạo tin nhắn bot với products (JSON format để frontend parse)
                                                var productsJson = System.Text.Json.JsonSerializer.Serialize(new
                                                {
                                                    message = productsResponse.Message,
                                                    hasImages = productsResponse.HasImages,
                                                    products = productsResponse.Products.Select(p => new
                                                    {
                                                        productId = p.ProductId,
                                                        productName = p.ProductName,
                                                        categoryId = p.CategoryId,
                                                        categoryName = p.CategoryName,
                                                        price = p.Price,
                                                        description = p.Description,
                                                        imageData = p.ImageData,  // Base64 encoded image
                                                        imageMimeType = p.ImageMimeType,  // MIME type
                                                        similarity = p.Similarity
                                                    }).ToList()
                                                });
                                                
                                                // Tạo message content: Text message + JSON data (frontend sẽ parse)
                                                var botMessageContent = $"{productsResponse.Message}\n\n[PRODUCTS_DATA]{productsJson}[/PRODUCTS_DATA]";
                                                
                                                // Lưu tin nhắn bot vào database
                                                using (var botConnection = new SqlConnection(capturedConnectionString))
                                                {
                                                    await botConnection.OpenAsync();
                                                    string insertBotMessageQuery = @"
                                                        INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                                                        VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";
                                                    
                                                    using (var botCommand = new SqlCommand(insertBotMessageQuery, botConnection))
                                                    {
                                                        botCommand.Parameters.AddWithValue("@MaTinNhan", $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}");
                                                        botCommand.Parameters.AddWithValue("@MaChat", capturedMaChat);
                                                        botCommand.Parameters.AddWithValue("@MaNguoiGui", "BOT");
                                                        botCommand.Parameters.AddWithValue("@LoaiNguoiGui", "Bot");
                                                        botCommand.Parameters.AddWithValue("@NoiDung", botMessageContent);
                                                        botCommand.Parameters.AddWithValue("@DaDoc", false);
                                                        botCommand.Parameters.AddWithValue("@NgayGui", DateTime.Now);
                                                        await botCommand.ExecuteNonQueryAsync();
                                                    }
                                                }
                                                
                                                _logger.LogInformation($"[Task.Run] Bot replied with {productsResponse.Products.Count} products (with images)");
                                                return; // Exit early, không cần xử lý tiếp
                                            }
                                            else
                                            {
                                                _logger.LogInformation($"[Task.Run] No products found for query: '{searchQuery}'");
                                                // Fall through to normal processing
                                            }
                                        }
                                        catch (Exception imageEx)
                                        {
                                            _logger.LogError(imageEx, $"[Task.Run] Error searching products: {imageEx.Message}");
                                            // Fall through to normal processing
                                        }
                                    }
                                    
                                    // 🔥 FIX: Kiểm tra nếu message có [IMAGE_DATA] tag
                                    // Frontend đang xử lý image search riêng, backend không nên trả về response
                                    var hasImageData = !string.IsNullOrEmpty(capturedNoiDung) && 
                                                       System.Text.RegularExpressions.Regex.IsMatch(
                                                           capturedNoiDung, 
                                                           @"\[IMAGE_DATA\].*?\[/IMAGE_DATA\]", 
                                                           System.Text.RegularExpressions.RegexOptions.Singleline);
                                    
                                    if (hasImageData)
                                    {
                                        _logger.LogInformation($"[Task.Run] Message contains [IMAGE_DATA] tag. Frontend is handling image search separately. Skipping chatbot response.");
                                        return; // Exit early - frontend sẽ xử lý image search riêng
                                    }
                                    
                                    // Thử retrieve context từ RAG nếu có
                                    string? ragContext = null;
                                    try
                                    {
                                        // Loại bỏ [IMAGE_DATA] tag trước khi gửi đến RAG
                                        // Base64 image data quá dài sẽ gây lỗi token limit khi tạo embedding
                                        var queryForRAG = System.Text.RegularExpressions.Regex.Replace(
                                            capturedNoiDung ?? string.Empty,
                                            @"\[IMAGE_DATA\].*?\[/IMAGE_DATA\]",
                                            string.Empty,
                                            System.Text.RegularExpressions.RegexOptions.Singleline
                                        ).Trim();
                                        
                                        _logger.LogInformation($"[Task.Run] Attempting to retrieve RAG context for query: '{queryForRAG}'");
                                        var ragResponse = await _ragService.RetrieveContextAsync(queryForRAG, topK: 5);
                                        
                                        if (ragResponse != null)
                                        {
                                            // Kiểm tra cả HasContext và Chunks
                                            var hasChunks = ragResponse.Chunks != null && ragResponse.Chunks.Count > 0;
                                            var hasContextString = !string.IsNullOrWhiteSpace(ragResponse.Context);
                                            
                                            _logger.LogInformation($"RAG response: hasChunks={hasChunks} ({ragResponse.Chunks?.Count ?? 0} chunks), hasContextString={hasContextString}, contextLength={ragResponse.Context?.Length ?? 0}");
                                            
                                            if (hasChunks || hasContextString)
                                            {
                                                // Ưu tiên build context từ chunks vì chunks có đầy đủ thông tin hơn
                                                if (hasChunks)
                                                {
                                                    _logger.LogInformation($"Building context from {ragResponse.Chunks.Count} chunks");
                                                    var contextBuilder = new System.Text.StringBuilder();
                                                    contextBuilder.AppendLine("Thông tin liên quan từ tài liệu:");
                                                    
                                                    // Sắp xếp chunks theo similarity (cao nhất trước)
                                                    var sortedChunks = ragResponse.Chunks.OrderByDescending(c => c.Similarity).ToList();
                                                    
                                                    foreach (var chunk in sortedChunks)
                                                    {
                                                        contextBuilder.AppendLine($"\n[File: {chunk.FileName}, Chunk {chunk.ChunkIndex}, Similarity: {chunk.Similarity:F4}]");
                                                        contextBuilder.AppendLine(chunk.Text);
                                                        contextBuilder.AppendLine("");
                                                    }
                                                    ragContext = contextBuilder.ToString();
                                                    _logger.LogInformation($"Built context from chunks: {ragContext.Length} chars");
                                                }
                                                else if (hasContextString)
                                                {
                                                    // Nếu không có chunks nhưng có context string, dùng context string
                                                    ragContext = ragResponse.Context;
                                                    _logger.LogInformation($"Using context string from RAG: {ragContext.Length} chars");
                                                }
                                                
                                                _logger.LogInformation($"Final RAG context length: {ragContext?.Length ?? 0} chars");
                                            }
                                            else
                                            {
                                                _logger.LogWarning("RAG response has no context and no chunks");
                                            }
                                        }
                                        else
                                        {
                                            _logger.LogWarning("RAG service returned null response");
                                        }
                                    }
                                    catch (Exception ragEx)
                                    {
                                        _logger.LogError(ragEx, "RAG retrieval failed, using standard processing");
                                    }
                                    
                                    // Xử lý tin nhắn bằng chatbot với conversation history
                                    // Luôn gọi ProcessMessageWithRAGAndHistoryAsync vì nó đã xử lý cả trường hợp RAG context rỗng
                                    string? botResponse = null;
                                    _logger.LogInformation($"[Task.Run] Processing message with RAG context (length: {ragContext?.Length ?? 0} chars) and {conversationHistory.Count} history messages");
                                    botResponse = await _chatbotService.ProcessMessageWithRAGAndHistoryAsync(
                                        capturedNoiDung, 
                                        ragContext ?? string.Empty, 
                                        capturedMaChat,
                                        conversationHistory);
                                    _logger.LogInformation($"[Task.Run] Bot response from RAG+History: {(string.IsNullOrEmpty(botResponse) ? "NULL/EMPTY" : $"{botResponse.Length} chars")}");
                                
                                // Đảm bảo luôn có response - nếu null thì dùng fallback
                                if (string.IsNullOrEmpty(botResponse))
                                {
                                    _logger.LogWarning($"[Task.Run] Bot response is null or empty for chat {capturedMaChat}. Using fallback response. RAG context was {(string.IsNullOrEmpty(ragContext) ? "empty" : "available")}");
                                    botResponse = "Xin chào! Tôi là trợ lý tự động của Fresher Food. Tôi có thể giúp bạn về sản phẩm, đơn hàng, giao hàng, thanh toán, khuyến mãi. Bạn cần hỗ trợ gì không?";
                                }
                                
                                // Lưu bot response vào database
                                _logger.LogInformation($"[Task.Run] Saving bot response to database: {botResponse.Length} chars");
                                var botMaTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";
                                
                                using (var botConnection = new SqlConnection(capturedConnectionString))
                                {
                                    await botConnection.OpenAsync();
                                    
                                    // Tạo tin nhắn từ chatbot
                                    string botMessageQuery = @"
                                        INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                                        VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                                    using (var botCommand = new SqlCommand(botMessageQuery, botConnection))
                                    {
                                        botCommand.Parameters.AddWithValue("@MaTinNhan", botMaTinNhan);
                                        botCommand.Parameters.AddWithValue("@MaChat", capturedMaChat);
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

                                        updateCommand.Parameters.AddWithValue("@MaChat", capturedMaChat);
                                        updateCommand.Parameters.AddWithValue("@TinNhanCuoi", preview);
                                        updateCommand.Parameters.AddWithValue("@NgayTinNhanCuoi", DateTime.Now);
                                        updateCommand.Parameters.AddWithValue("@NgayCapNhat", DateTime.Now);

                                        await updateCommand.ExecuteNonQueryAsync();
                                    }
                                }
                                
                                _logger.LogInformation($"[Task.Run] Chatbot auto-replied to chat {capturedMaChat} successfully");
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"[Task.Run] Error sending chatbot auto-reply for chat {capturedMaChat}. Exception: {ex.Message}");
                                _logger.LogError(ex, $"[Task.Run] Stack trace: {ex.StackTrace}");
                                
                                // Đảm bảo luôn có phản hồi, ngay cả khi có lỗi
                                try
                                {
                                    using (var errorConnection = new SqlConnection(capturedConnectionString))
                                    {
                                        await errorConnection.OpenAsync();
                                        
                                        var fallbackResponse = "Xin chào! Tôi là trợ lý tự động của Fresher Food. Tôi có thể giúp bạn về sản phẩm, đơn hàng, giao hàng, thanh toán, khuyến mãi. Bạn cần hỗ trợ gì không?";
                                        var botMaTinNhan = $"MSG-{Guid.NewGuid().ToString().Substring(0, 8)}";
                                        
                                        string botMessageQuery = @"
                                            INSERT INTO Message (MaTinNhan, MaChat, MaNguoiGui, LoaiNguoiGui, NoiDung, DaDoc, NgayGui)
                                            VALUES (@MaTinNhan, @MaChat, @MaNguoiGui, @LoaiNguoiGui, @NoiDung, @DaDoc, @NgayGui)";

                                        using (var botCommand = new SqlCommand(botMessageQuery, errorConnection))
                                        {
                                            botCommand.Parameters.AddWithValue("@MaTinNhan", botMaTinNhan);
                                            botCommand.Parameters.AddWithValue("@MaChat", capturedMaChat);
                                            botCommand.Parameters.AddWithValue("@MaNguoiGui", "BOT");
                                            botCommand.Parameters.AddWithValue("@LoaiNguoiGui", "Admin");
                                            botCommand.Parameters.AddWithValue("@NoiDung", fallbackResponse);
                                            botCommand.Parameters.AddWithValue("@DaDoc", false);
                                            botCommand.Parameters.AddWithValue("@NgayGui", DateTime.Now);

                                            await botCommand.ExecuteNonQueryAsync();
                                        }
                                        
                                        _logger.LogInformation($"[Task.Run] Fallback response saved after error for chat {capturedMaChat}");
                                    }
                                }
                                catch (Exception fallbackEx)
                                {
                                    _logger.LogError(fallbackEx, $"[Task.Run] Failed to save fallback response for chat {capturedMaChat}");
                                }
                            }
                        });
                        }
                        else
                        {
                            _logger.LogInformation($"Skipping auto-reply: hasRealAdminMessage={hasRealAdminMessage} (admin has already responded, no need for bot auto-reply)");
                        }
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

        /// <summary>
        /// Upload file để xử lý RAG
        /// POST: api/Chat/upload-document
        /// </summary>
        [HttpPost("upload-document")]
        public async Task<IActionResult> UploadDocument(IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                {
                    return BadRequest(new { error = "No file uploaded" });
                }

                var allowedExtensions = new[] { ".txt", ".docx", ".pdf", ".xlsx" };
                var extension = Path.GetExtension(file.FileName).ToLower();
                
                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest(new { error = $"File type {extension} is not supported. Allowed types: txt, docx, pdf, xlsx" });
                }

                // Giới hạn kích thước file (50MB)
                if (file.Length > 50 * 1024 * 1024)
                {
                    return BadRequest(new { error = "File size exceeds 50MB limit" });
                }

                using var stream = file.OpenReadStream();
                var result = await _ragService.ProcessAndStoreDocumentAsync(stream, file.FileName);

                if (result == null)
                {
                    return StatusCode(500, new { error = "Failed to process document. Please check if Python RAG service is running." });
                }

                return Ok(new { 
                    fileId = result.FileId, 
                    fileName = result.FileName,
                    totalChunks = result.TotalChunks,
                    message = result.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading document");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Hỏi đáp với file (RAG)
        /// POST: api/Chat/ask-with-document
        /// </summary>
        [HttpPost("ask-with-document")]
        public async Task<IActionResult> AskWithDocument([FromBody] AskWithDocumentRequest request)
        {
            try
            {
                _logger.LogInformation($"Received RAG query request: Question='{request.Question}', FileId={request.FileId}, MaChat={request.MaChat}");
                
                if (string.IsNullOrWhiteSpace(request.Question))
                {
                    return BadRequest(new { error = "Question is required" });
                }

                // Kiểm tra phân quyền: Lấy thông tin user từ MaChat
                string? userRole = null;
                string? userId = null;
                bool isQuickChat = string.IsNullOrEmpty(request.MaChat); // Quick chatbot không có MaChat
                
                if (!isQuickChat)
                {
                    var connectionString = _configuration.GetConnectionString("DefaultConnection");
                    using (var connection = new SqlConnection(connectionString))
                    {
                        await connection.OpenAsync();
                        
                        // Lấy MaNguoiDung và VaiTro từ Chat
                        string getUserInfoQuery = @"
                            SELECT c.MaNguoiDung, u.VaiTro
                            FROM Chat c
                            LEFT JOIN NguoiDung u ON c.MaNguoiDung = u.MaTaiKhoan
                            WHERE c.MaChat = @MaChat";
                        
                        using (var command = new SqlCommand(getUserInfoQuery, connection))
                        {
                            command.Parameters.AddWithValue("@MaChat", request.MaChat);
                            using (var reader = await command.ExecuteReaderAsync())
                            {
                                if (await reader.ReadAsync())
                                {
                                    userId = reader["MaNguoiDung"]?.ToString();
                                    userRole = reader["VaiTro"]?.ToString();
                                    _logger.LogInformation($"User info from chat: UserId={userId}, Role={userRole}");
                                }
                            }
                        }
                    }
                }
                else
                {
                    _logger.LogInformation("Quick chatbot query (no MaChat) - treating as user query");
                    // Quick chatbot mặc định là user (không có thông tin user)
                    userRole = "User";
                }
                
                // Phân quyền câu hỏi
                var question = request.Question.ToLower();
                bool isAdminQuery = userRole != null && (userRole.Equals("Admin", StringComparison.OrdinalIgnoreCase));
                bool isUserQuery = !isAdminQuery;
                
                // Danh sách từ khóa chỉ dành cho admin (thống kê, doanh thu, báo cáo)
                var adminOnlyKeywords = new[] { 
                    "doanh thu", "revenue", "thống kê", "statistics", "báo cáo", "report",
                    "tổng doanh thu", "doanh số", "sales", "tài chính", "finance",
                    "người dùng", "users", "số lượng người dùng", "tổng số", "tổng đơn hàng",
                    "đơn hàng đã hoàn thành", "completed orders", "số lượng sản phẩm", "total products"
                };
                
                bool containsAdminKeyword = adminOnlyKeywords.Any(keyword => question.Contains(keyword));
                
                // Nếu user hỏi về thông tin chỉ dành cho admin
                if (isUserQuery && containsAdminKeyword)
                {
                    _logger.LogWarning($"User {userId ?? "QuickChat"} attempted to ask admin-only question: {request.Question}");
                    return StatusCode(403, new { 
                        error = "Bạn không có quyền truy cập thông tin này. Vui lòng liên hệ admin để được hỗ trợ.",
                        answer = "Xin lỗi, bạn không có quyền truy cập thông tin thống kê và doanh thu. Vui lòng hỏi về sản phẩm, đơn hàng của bạn, hoặc các thông tin khác mà chúng tôi có thể hỗ trợ.",
                        hasContext = false,
                        chunks = new List<RetrievedChunkInfo>()
                    });
                }
                
                _logger.LogInformation($"Question authorized. UserId={userId ?? "QuickChat"}, Role={userRole}, IsAdmin={isAdminQuery}, ContainsAdminKeyword={containsAdminKeyword}, IsQuickChat={isQuickChat}");

                // Kiểm tra RAG service có available không
                var isAvailable = await _ragService.IsServiceAvailableAsync();
                if (!isAvailable)
                {
                    _logger.LogWarning("Python RAG service is not available");
                    return StatusCode(503, new { 
                        error = "RAG service is not available. Please check if Python RAG service is running.",
                        answer = "Xin lỗi, hệ thống RAG đang không khả dụng. Vui lòng thử lại sau.",
                        hasContext = false,
                        chunks = new List<RetrievedChunkInfo>()
                    });
                }

                // ✅ Ưu tiên xử lý "top sản phẩm bán chạy" (kể cả có từ 'hình ảnh')
                if (_chatbotService.IsTopProductsRequest(request.Question))
                {
                    var limit = _chatbotService.ExtractTopProductsLimit(request.Question, defaultLimit: 3);
                    _logger.LogInformation($"User requested top products: limit={limit}, question='{request.Question}'");

                    var functionResultRaw = await _functionHandler.ExecuteFunctionAsync(
                        "getBestSellingProductImage",
                        new Dictionary<string, object> { { "limit", limit } }
                    );

                    if (!string.IsNullOrWhiteSpace(functionResultRaw))
                    {
                        try
                        {
                            // FunctionHandlerService trả về JSON: { result: "...", success: true/false, ... }
                            using var doc = JsonDocument.Parse(functionResultRaw);
                            var root = doc.RootElement;

                            if (root.TryGetProperty("success", out var successProp) && successProp.GetBoolean()
                                && root.TryGetProperty("result", out var resultProp))
                            {
                                var inner = resultProp.GetString() ?? "";
                                using var innerDoc = JsonDocument.Parse(inner);
                                var innerRoot = innerDoc.RootElement;

                                // products có thể là object (limit=1) hoặc array (limit>1)
                                var productsElement = innerRoot.GetProperty("products");
                                var productsList = new List<object>();

                                if (productsElement.ValueKind == JsonValueKind.Array)
                                {
                                    foreach (var p in productsElement.EnumerateArray())
                                    {
                                        productsList.Add(new
                                        {
                                            productId = p.GetProperty("maSanPham").GetString() ?? "",
                                            productName = p.GetProperty("tenSanPham").GetString() ?? "",
                                            categoryId = "", // function không trả category
                                            categoryName = null as string,
                                            price = p.TryGetProperty("giaBan", out var priceProp) ? priceProp.GetDouble() : (double?)null,
                                            description = (string?)null,
                                            imageData = p.TryGetProperty("imageData", out var imgProp) ? imgProp.GetString() : null,
                                            imageMimeType = p.TryGetProperty("imageMimeType", out var mimeProp) ? mimeProp.GetString() : null,
                                            similarity = 1.0
                                        });
                                    }
                                }
                                else if (productsElement.ValueKind == JsonValueKind.Object)
                                {
                                    var p = productsElement;
                                    productsList.Add(new
                                    {
                                        productId = p.GetProperty("maSanPham").GetString() ?? "",
                                        productName = p.GetProperty("tenSanPham").GetString() ?? "",
                                        categoryId = "",
                                        categoryName = null as string,
                                        price = p.TryGetProperty("giaBan", out var priceProp) ? priceProp.GetDouble() : (double?)null,
                                        description = (string?)null,
                                        imageData = p.TryGetProperty("imageData", out var imgProp) ? imgProp.GetString() : null,
                                        imageMimeType = p.TryGetProperty("imageMimeType", out var mimeProp) ? mimeProp.GetString() : null,
                                        similarity = 1.0
                                    });
                                }

                                var answer = innerRoot.TryGetProperty("message", out var msgProp) ? msgProp.GetString() : null;
                                if (string.IsNullOrWhiteSpace(answer))
                                {
                                    answer = $"Tôi tìm thấy {productsList.Count} sản phẩm bán chạy nhất.";
                                }

                                return Ok(new
                                {
                                    answer,
                                    hasContext = true,
                                    chunks = new List<RetrievedChunkInfo>(),
                                    products = productsList,
                                    hasImages = true
                                });
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error parsing function result for getBestSellingProductImage");
                        }
                    }
                }

                // Kiểm tra nếu user yêu cầu ảnh sản phẩm
                if (_chatbotService.IsImageRequest(request.Question))
                {
                    _logger.LogInformation($"User requested product image: '{request.Question}'");
                    
                    // Extract product name từ message
                    var productName = _chatbotService.ExtractProductNameFromImageRequest(request.Question);
                    var searchQuery = productName ?? request.Question;
                    
                    _logger.LogInformation($"Searching products for: '{searchQuery}'");
                    
                    // Search products từ RAG service
                    var productsResponse = await _ragService.SearchProductsForChatAsync(searchQuery, categoryId: null, topK: 5);
                    
                    if (productsResponse != null && productsResponse.Products != null && productsResponse.Products.Count > 0)
                    {
                        // Trả về products với image data (base64)
                        return Ok(new { 
                            answer = productsResponse.Message,
                            hasContext = true,
                            chunks = new List<RetrievedChunkInfo>(),
                            products = productsResponse.Products.Select(p => new {
                                productId = p.ProductId,
                                productName = p.ProductName,
                                categoryId = p.CategoryId,
                                categoryName = p.CategoryName,
                                price = p.Price,
                                description = p.Description,
                                imageData = p.ImageData,  // Base64 encoded image
                                imageMimeType = p.ImageMimeType,  // MIME type
                                similarity = p.Similarity
                            }).ToList(),
                            hasImages = productsResponse.HasImages
                        });
                    }
                    else
                    {
                        // Không tìm thấy products, trả về message thông thường
                        return Ok(new { 
                            answer = productsResponse?.Message ?? $"Xin lỗi, tôi không tìm thấy sản phẩm nào liên quan đến '{searchQuery}'. Bạn có thể thử tìm kiếm với từ khóa khác.",
                            hasContext = false,
                            chunks = new List<RetrievedChunkInfo>(),
                            products = new List<object>(),
                            hasImages = false
                        });
                    }
                }

                // Retrieve context từ RAG
                // Loại bỏ [IMAGE_DATA] tag trước khi gửi đến RAG
                // Base64 image data quá dài sẽ gây lỗi token limit khi tạo embedding
                var questionForRAG = System.Text.RegularExpressions.Regex.Replace(
                    request.Question ?? string.Empty,
                    @"\[IMAGE_DATA\].*?\[/IMAGE_DATA\]",
                    string.Empty,
                    System.Text.RegularExpressions.RegexOptions.Singleline
                ).Trim();
                
                _logger.LogInformation($"Retrieving context from RAG service... (original length: {request.Question?.Length ?? 0}, after removing image data: {questionForRAG.Length})");
                var ragResponse = await _ragService.RetrieveContextAsync(questionForRAG, topK: 5, request.FileId);

                string? context = null;
                bool hasContext = false;
                
                if (ragResponse != null)
                {
                    // Kiểm tra có chunks không (quan trọng hơn HasContext flag)
                    var hasChunks = ragResponse.Chunks != null && ragResponse.Chunks.Count > 0;
                    var hasContextString = !string.IsNullOrWhiteSpace(ragResponse.Context);
                    
                    hasContext = hasChunks || hasContextString;
                    
                    if (hasContext)
                    {
                        context = ragResponse.Context;
                        _logger.LogInformation($"Retrieved context with {ragResponse.Chunks?.Count ?? 0} chunks. Context length: {context?.Length ?? 0} chars");
                        
                        // Nếu context rỗng nhưng có chunks, tạo context từ chunks
                        if (string.IsNullOrWhiteSpace(context) && hasChunks)
                        {
                            _logger.LogWarning("Context string is empty but chunks exist. Building context from chunks...");
                            var contextBuilder = new System.Text.StringBuilder();
                            contextBuilder.AppendLine("Thông tin liên quan từ tài liệu:");
                            foreach (var chunk in ragResponse.Chunks)
                            {
                                contextBuilder.AppendLine($"\n[File: {chunk.FileName}, Chunk {chunk.ChunkIndex}]");
                                contextBuilder.AppendLine(chunk.Text);
                                contextBuilder.AppendLine("");
                            }
                            context = contextBuilder.ToString();
                            _logger.LogInformation($"Built context from chunks: {context.Length} chars");
                        }
                    }
                    else
                    {
                        _logger.LogWarning("No context retrieved from RAG service (no chunks and no context string)");
                    }
                }
                else
                {
                    _logger.LogWarning("RAG service returned null response");
                }

                // Sử dụng ChatbotService với context từ RAG
                _logger.LogInformation($"Processing message with chatbot service... Context available: {!string.IsNullOrWhiteSpace(context)}");
                var response = await _chatbotService.ProcessMessageWithRAGAsync(
                    request.Question, 
                    context ?? string.Empty, 
                    request.MaChat);

                _logger.LogInformation("Successfully processed RAG query");
                
                // Log chunks info
                var chunksToReturn = ragResponse?.Chunks ?? new List<RetrievedChunkInfo>();
                _logger.LogInformation($"Returning {chunksToReturn.Count} chunks to frontend");
                if (chunksToReturn.Count > 0)
                {
                    var firstChunk = chunksToReturn[0];
                    _logger.LogInformation($"First chunk: ChunkId={firstChunk.ChunkId}, FileName={firstChunk.FileName}, ChunkIndex={firstChunk.ChunkIndex}, TextLength={firstChunk.Text?.Length ?? 0}");
                }

                return Ok(new { 
                    answer = response,
                    hasContext = hasContext,
                    chunks = chunksToReturn
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing question with document");
                return StatusCode(500, new { 
                    error = ex.Message,
                    answer = "Xin lỗi, có lỗi xảy ra khi xử lý câu hỏi. Vui lòng thử lại sau.",
                    hasContext = false,
                    chunks = new List<RetrievedChunkInfo>()
                });
            }
        }

        /// <summary>
        /// Lấy danh sách tất cả documents đã upload
        /// GET: api/Chat/documents
        /// </summary>
        [HttpGet("documents")]
        public async Task<IActionResult> GetDocuments()
        {
            try
            {
                var documents = await _ragService.GetAllDocumentsAsync();
                return Ok(documents);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting documents");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Xóa document
        /// <summary>
        /// Xóa cuộc trò chuyện
        /// DELETE: api/Chat/{maChat}?maNguoiDung={maNguoiDung}
        /// Chỉ cho phép user xóa chat của chính mình
        /// </summary>
        [HttpDelete("{maChat}")]
        public async Task<IActionResult> DeleteChat(string maChat, [FromQuery] string? maNguoiDung = null)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(maChat))
                {
                    return BadRequest(new { error = "Mã chat không được để trống" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Kiểm tra quyền: chỉ cho phép user xóa chat của chính mình
                    if (!string.IsNullOrWhiteSpace(maNguoiDung))
                    {
                        string checkPermissionQuery = @"
                            SELECT MaNguoiDung 
                            FROM Chat 
                            WHERE MaChat = @MaChat";
                        
                        using (var checkCommand = new SqlCommand(checkPermissionQuery, connection))
                        {
                            checkCommand.Parameters.AddWithValue("@MaChat", maChat);
                            var chatOwner = await checkCommand.ExecuteScalarAsync();
                            
                            if (chatOwner == null || chatOwner == DBNull.Value)
                            {
                                return NotFound(new { error = "Không tìm thấy cuộc trò chuyện" });
                            }
                            
                            if (chatOwner.ToString() != maNguoiDung)
                            {
                                return Forbid("Bạn không có quyền xóa cuộc trò chuyện này");
                            }
                        }
                    }

                    // Xóa tất cả tin nhắn trong chat trước
                    string deleteMessagesQuery = @"DELETE FROM Message WHERE MaChat = @MaChat";
                    using (var deleteMessagesCommand = new SqlCommand(deleteMessagesQuery, connection))
                    {
                        deleteMessagesCommand.Parameters.AddWithValue("@MaChat", maChat);
                        await deleteMessagesCommand.ExecuteNonQueryAsync();
                    }

                    // Xóa chat
                    string deleteChatQuery = @"DELETE FROM Chat WHERE MaChat = @MaChat";
                    using (var deleteChatCommand = new SqlCommand(deleteChatQuery, connection))
                    {
                        deleteChatCommand.Parameters.AddWithValue("@MaChat", maChat);
                        int affectedRows = await deleteChatCommand.ExecuteNonQueryAsync();

                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy cuộc trò chuyện" });
                        }
                    }
                }

                _logger.LogInformation($"Chat deleted successfully: {maChat} by user: {maNguoiDung ?? "admin"}");
                return Ok(new { message = "Xóa cuộc trò chuyện thành công" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting chat: {maChat}");
                return StatusCode(500, new { error = $"Lỗi: {ex.Message}" });
            }
        }

        /// <summary>
        /// DELETE: api/Chat/documents/{fileId}
        /// </summary>
        [HttpDelete("documents/{fileId}")]
        public async Task<IActionResult> DeleteDocument(string fileId)
        {
            try
            {
                var success = await _ragService.DeleteDocumentAsync(fileId);
                if (success)
                {
                    return Ok(new { message = "Document deleted successfully" });
                }
                else
                {
                    return StatusCode(500, new { error = "Failed to delete document. Please check if Python RAG service is running." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting document");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class MarkAsReadRequest
    {
        public string MaNguoiDoc { get; set; }
    }

    public class AskWithDocumentRequest
    {
        public string Question { get; set; } = string.Empty;
        public string? FileId { get; set; }
        public string? MaChat { get; set; }
    }
}

