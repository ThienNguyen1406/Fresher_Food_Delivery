# Hướng dẫn tích hợp AI cho Chatbot

## Mô tả
Chatbot của Fresher Food đã được tích hợp với AI bên ngoài (OpenAI) để xử lý các câu hỏi phức tạp mà rule-based không thể trả lời.

## Cách hoạt động

### 1. Rule-based (Ưu tiên)
- Chatbot sẽ kiểm tra các pattern đã định nghĩa trước
- Nếu match pattern → trả lời ngay lập tức (nhanh, miễn phí)

### 2. AI Service (Fallback)
- Nếu không match pattern → gọi OpenAI API
- Xử lý câu hỏi phức tạp bằng AI
- Trả về câu trả lời thông minh hơn

## Cấu hình

### Bước 1: Lấy OpenAI API Key
1. Đăng ký tài khoản tại: https://platform.openai.com/
2. Tạo API Key tại: https://platform.openai.com/api-keys
3. Copy API Key của bạn

### Bước 2: Cấu hình trong appsettings.json
Thêm cấu hình OpenAI vào file `appsettings.json`:

```json
{
  "OpenAI": {
    "ApiKey": "sk-your-openai-api-key-here",
    "Model": "gpt-3.5-turbo"
  }
}
```

**Lưu ý:**
- `ApiKey`: API key từ OpenAI (bắt đầu bằng `sk-`)
- `Model`: Model AI sử dụng (mặc định: `gpt-3.5-turbo`)
  - `gpt-3.5-turbo`: Rẻ hơn, nhanh hơn
  - `gpt-4`: Thông minh hơn nhưng đắt hơn
  - `gpt-4-turbo`: Cân bằng giữa chất lượng và chi phí

### Bước 3: Không muốn dùng AI?
Nếu không muốn sử dụng AI, chỉ cần:
- Không thêm `OpenAI:ApiKey` vào appsettings.json
- Chatbot sẽ chỉ sử dụng rule-based
- Vẫn hoạt động bình thường với các câu hỏi đơn giản

## Chi phí

### OpenAI Pricing (tính đến 2025):
- **gpt-3.5-turbo**: ~$0.002 per 1K tokens (rất rẻ)
- **gpt-4**: ~$0.03 per 1K tokens
- **gpt-4-turbo**: ~$0.01 per 1K tokens

**Ví dụ:**
- 1 câu trả lời ~100 tokens
- 1000 câu hỏi = 100,000 tokens
- Chi phí với gpt-3.5-turbo: ~$0.20 (rất rẻ!)

## Các tùy chọn AI khác

Nếu muốn sử dụng AI service khác, bạn có thể:

### 1. Azure OpenAI
- Tích hợp với Azure
- Có thể dùng trong môi trường enterprise
- Cần cập nhật `OpenAIService.cs` để sử dụng Azure endpoint

### 2. Google Gemini
- Tạo service mới `GeminiService` implement `IAIService`
- Sử dụng Google AI Studio API

### 3. Anthropic Claude
- Tạo service mới `ClaudeService` implement `IAIService`
- Sử dụng Anthropic API

## Kiểm tra hoạt động

Sau khi cấu hình:
1. Gửi câu hỏi đơn giản → Chatbot trả lời bằng rule-based
2. Gửi câu hỏi phức tạp → Chatbot gọi AI và trả lời thông minh hơn
3. Kiểm tra logs để xem AI có được gọi không

## Troubleshooting

### Lỗi: "OpenAI API key not configured"
- Kiểm tra `appsettings.json` có `OpenAI:ApiKey` chưa
- Đảm bảo API key đúng format (bắt đầu bằng `sk-`)

### Lỗi: "OpenAI API error: 401"
- API key không đúng hoặc đã hết hạn
- Kiểm tra lại API key trên OpenAI dashboard

### Lỗi: "OpenAI API error: 429"
- Đã vượt quá rate limit
- Đợi một chút hoặc nâng cấp plan

### AI không được gọi
- Kiểm tra logs để xem có lỗi gì không
- Đảm bảo rule-based không match trước (AI chỉ được gọi khi không match pattern)

## Bảo mật

⚠️ **QUAN TRỌNG:**
- **KHÔNG** commit API key vào git
- Thêm `appsettings.json` vào `.gitignore`
- Sử dụng `appsettings.example.json` làm template
- Sử dụng Azure Key Vault hoặc Environment Variables cho production
