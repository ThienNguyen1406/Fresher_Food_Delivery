using System.Text.RegularExpressions;

namespace FressFood.Services
{
    public class ChatbotService
    {
        private readonly ILogger<ChatbotService> _logger;
        private readonly IAIService? _aiService;

        public ChatbotService(ILogger<ChatbotService> logger, IAIService? aiService = null)
        {
            _logger = logger;
            _aiService = aiService;
        }

        /// <summary>
        /// Xử lý tin nhắn và trả về câu trả lời tự động
        /// </summary>
        public async Task<string?> ProcessMessageAsync(string userMessage, string? maChat = null)
        {
            if (string.IsNullOrWhiteSpace(userMessage))
                return null;

            var message = userMessage.ToLower().Trim();

            // Chào hỏi
            if (IsGreeting(message))
            {
                return "Xin chào! Tôi là trợ lý tự động của Fresher Food. Tôi có thể giúp gì cho bạn? 😊";
            }

            // Hỏi về sản phẩm
            if (IsProductQuestion(message))
            {
                return "Chúng tôi có nhiều sản phẩm thực phẩm tươi ngon như rau củ, trái cây, thịt cá và các sản phẩm khác. Bạn có thể xem danh sách sản phẩm trong ứng dụng hoặc tìm kiếm theo tên sản phẩm. Bạn muốn tìm sản phẩm gì cụ thể không?";
            }

            // Hỏi về đơn hàng
            if (IsOrderQuestion(message))
            {
                return "Bạn có thể xem trạng thái đơn hàng trong phần 'Đơn hàng của tôi' trong ứng dụng. Nếu bạn có mã đơn hàng, vui lòng cung cấp để tôi hỗ trợ bạn tốt hơn.";
            }

            // Hỏi về giá
            if (IsPriceQuestion(message))
            {
                return "Giá sản phẩm được hiển thị trên từng sản phẩm trong ứng dụng. Chúng tôi thường xuyên có các chương trình khuyến mãi và giảm giá. Bạn có thể xem chi tiết giá và khuyến mãi khi xem sản phẩm.";
            }

            // Hỏi về giao hàng
            if (IsDeliveryQuestion(message))
            {
                return "Chúng tôi giao hàng tận nơi trong khu vực thành phố. Thời gian giao hàng thường từ 1-3 ngày làm việc. Phí giao hàng sẽ được tính dựa trên khoảng cách và địa chỉ giao hàng của bạn.";
            }

            // Hỏi về thanh toán
            if (IsPaymentQuestion(message))
            {
                return "Chúng tôi hỗ trợ nhiều phương thức thanh toán: tiền mặt khi nhận hàng, chuyển khoản ngân hàng, và thanh toán online qua thẻ tín dụng/ghi nợ. Bạn có thể chọn phương thức thanh toán khi đặt hàng.";
            }

            // Hỏi về chất lượng
            if (IsQualityQuestion(message))
            {
                return "Tất cả sản phẩm của chúng tôi đều được kiểm tra chất lượng kỹ lưỡng, có nguồn gốc rõ ràng và đảm bảo tươi ngon. Chúng tôi cam kết mang đến cho bạn những sản phẩm tốt nhất.";
            }

            // Hỏi về ngày sản xuất/hết hạn
            if (IsExpiryQuestion(message))
            {
                return "Thông tin ngày sản xuất và hạn sử dụng được hiển thị trên từng sản phẩm. Chúng tôi đảm bảo tất cả sản phẩm đều còn hạn sử dụng và tươi ngon khi giao đến bạn.";
            }

            // Hỏi về khuyến mãi
            if (IsPromotionQuestion(message))
            {
                return "Chúng tôi thường xuyên có các chương trình khuyến mãi và giảm giá đặc biệt. Ngoài ra, các sản phẩm gần hết hạn (còn ≤ 7 ngày) sẽ được giảm giá 30% tự động. Bạn có thể xem các khuyến mãi trong ứng dụng.";
            }

            // Hỏi về đổi trả
            if (IsReturnQuestion(message))
            {
                return "Nếu sản phẩm không đúng chất lượng hoặc bị hỏng, bạn có thể liên hệ với chúng tôi trong vòng 24 giờ sau khi nhận hàng để được đổi trả hoặc hoàn tiền. Vui lòng cung cấp mã đơn hàng và hình ảnh sản phẩm.";
            }

            // Hỏi về tài khoản
            if (IsAccountQuestion(message))
            {
                return "Bạn có thể quản lý thông tin tài khoản, xem đơn hàng, sản phẩm yêu thích và cài đặt trong phần 'Tài khoản' của ứng dụng. Nếu cần hỗ trợ thêm, vui lòng mô tả chi tiết vấn đề của bạn.";
            }

            // Cảm ơn
            if (IsThankYou(message))
            {
                return "Cảm ơn bạn đã liên hệ với chúng tôi! Nếu bạn cần hỗ trợ thêm, đừng ngần ngại hỏi tôi nhé! 😊";
            }

            // Tạm biệt
            if (IsGoodbye(message))
            {
                return "Chúc bạn một ngày tốt lành! Nếu có thắc mắc gì, hãy liên hệ lại với chúng tôi nhé! 👋";
            }

            // Hỏi về hỗ trợ/khiếu nại
            if (IsSupportQuestion(message))
            {
                return "Nếu bạn cần hỗ trợ hoặc có khiếu nại, vui lòng mô tả chi tiết vấn đề của bạn. Admin sẽ xem xét và phản hồi sớm nhất có thể. Bạn cũng có thể cung cấp mã đơn hàng nếu liên quan đến đơn hàng.";
            }

            // Câu hỏi không xác định - thử dùng AI nếu có
            if (_aiService != null)
            {
                try
                {
                    var context = $"Ngữ cảnh: Khách hàng đang chat trong ứng dụng Fresher Food. Mã chat: {maChat}";
                    var aiResponse = await _aiService.GetAIResponseAsync(userMessage, context);
                    
                    if (!string.IsNullOrEmpty(aiResponse))
                    {
                        _logger.LogInformation($"AI service provided response for message: {userMessage.Substring(0, Math.Min(50, userMessage.Length))}");
                        return aiResponse;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error calling AI service, falling back to default response");
                }
            }

            // Fallback: Câu trả lời mặc định nếu AI không khả dụng
            return "Cảm ơn bạn đã liên hệ! Tôi là trợ lý tự động và có thể giúp bạn về: sản phẩm, đơn hàng, giao hàng, thanh toán, khuyến mãi. Nếu câu hỏi của bạn phức tạp hơn, admin sẽ phản hồi sớm nhất có thể. Bạn có thể mô tả chi tiết hơn không?";
        }

        /// <summary>
        /// Xử lý tin nhắn (synchronous version - giữ để tương thích)
        /// </summary>
        public string? ProcessMessage(string userMessage, string? maChat = null)
        {
            // Gọi async method và đợi kết quả
            return ProcessMessageAsync(userMessage, maChat).GetAwaiter().GetResult();
        }

        private bool IsSupportQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(hỗ trợ|support|help|giúp đỡ)\b",
                @"\b(khiếu nại|complaint|phàn nàn|vấn đề|problem|issue)\b",
                @"\b(lỗi|error|bug|sai|wrong)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        // Kiểm tra các loại câu hỏi
        private bool IsGreeting(string message)
        {
            var patterns = new[] { @"\b(chào|hello|hi|xin chào|chào bạn)\b", @"\b(bắt đầu|start)\b" };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsProductQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(sản phẩm|món|đồ ăn|thực phẩm|rau|củ|trái cây|thịt|cá)\b",
                @"\b(có gì|bán gì|món nào|sản phẩm nào)\b",
                @"\b(tìm|tìm kiếm|search)\b.*\b(sản phẩm|món)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsOrderQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(đơn hàng|order|đặt hàng)\b",
                @"\b(trạng thái|status|tình trạng)\b.*\b(đơn|hàng)\b",
                @"\b(khi nào|bao giờ|lúc nào)\b.*\b(giao|nhận)\b",
                @"\b(mã đơn|mã hàng|order id)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsPriceQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(giá|price|cost|tiền|phí)\b",
                @"\b(bao nhiêu|nhiều tiền|chi phí)\b",
                @"\b(rẻ|đắt|giá cả)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsDeliveryQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(giao hàng|delivery|ship|vận chuyển)\b",
                @"\b(khi nào|bao giờ|lúc nào)\b.*\b(giao|nhận|ship)\b",
                @"\b(địa chỉ|address|nơi giao)\b",
                @"\b(phí ship|phí giao|shipping fee)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsPaymentQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(thanh toán|payment|pay|trả tiền)\b",
                @"\b(cách thanh toán|phương thức|payment method)\b",
                @"\b(tiền mặt|cash|chuyển khoản|bank transfer|thẻ)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsQualityQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(chất lượng|quality|tươi|ngon|fresh)\b",
                @"\b(đảm bảo|guarantee|uy tín)\b",
                @"\b(nguồn gốc|origin|xuất xứ)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsExpiryQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(hết hạn|expiry|expire|hạn sử dụng)\b",
                @"\b(ngày sản xuất|production date|ngày hết hạn)\b",
                @"\b(còn hạn|tươi|fresh)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsPromotionQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(khuyến mãi|promotion|sale|discount|giảm giá)\b",
                @"\b(giảm|discount|off|%)",
                @"\b(chương trình|program|event)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsReturnQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(đổi|trả|return|refund|hoàn tiền)\b",
                @"\b(hỏng|bad|defect|sai|wrong)\b",
                @"\b(không đúng|not correct|wrong product)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsAccountQuestion(string message)
        {
            var patterns = new[] { 
                @"\b(tài khoản|account|profile)\b",
                @"\b(đổi mật khẩu|change password|thông tin)\b",
                @"\b(cập nhật|update|edit)\b.*\b(tài khoản|thông tin)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsThankYou(string message)
        {
            var patterns = new[] { 
                @"\b(cảm ơn|thank|thanks|thank you|cám ơn)\b",
                @"\b(cảm ơn bạn|thanks a lot)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }

        private bool IsGoodbye(string message)
        {
            var patterns = new[] { 
                @"\b(tạm biệt|goodbye|bye|chào|see you)\b",
                @"\b(kết thúc|end|finish)\b"
            };
            return patterns.Any(p => Regex.IsMatch(message, p, RegexOptions.IgnoreCase));
        }
    }
}
