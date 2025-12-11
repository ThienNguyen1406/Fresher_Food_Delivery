class AppConfig {
  // Development URL (localhost)
  static const String devBaseUrl = "https://10.0.2.2:7240/api";

  // Production URL - THAY ĐỔI KHI DEPLOY LÊN SERVER
  // Ví dụ: "https://your-domain.com/api" hoặc "https://api.your-domain.com"
  static const String prodBaseUrl = "https://your-domain.com/api";

  // Chế độ hiện tại: true = Production, false = Development
  static const bool isProduction = false;

  // Base URL được sử dụng
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // URL công khai để hiển thị trong QR code (không có /api)
  static String get publicBaseUrl {
    if (isProduction) {
      return prodBaseUrl.replaceAll('/api', '');
    }
    // Development: sử dụng localhost hoặc IP công khai
    // Nếu test trên mạng local, thay bằng IP máy tính của bạn
    // Ví dụ: "http://192.168.1.100:7240" hoặc "https://your-ngrok-url.ngrok.io"
    return "http://localhost:7240"; // Thay bằng IP công khai nếu cần
  }
}
