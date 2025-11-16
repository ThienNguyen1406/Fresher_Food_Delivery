# Hướng dẫn Deploy Backend lên Server

## 📋 Tổng quan

Để QR code có thể quét được từ mọi thiết bị, bạn cần deploy backend API lên server công khai.

## 🚀 Các phương án Deploy

### 1. Azure App Service (Khuyến nghị)

#### Bước 1: Chuẩn bị
```bash
# Publish project
cd fresher_food_backend/FressFood
dotnet publish -c Release -o ./publish
```

#### Bước 2: Tạo Azure App Service
1. Đăng nhập Azure Portal: https://portal.azure.com
2. Tạo App Service mới:
   - Name: `fressfood-api` (hoặc tên bạn muốn)
   - Runtime: `.NET 8`
   - OS: Windows hoặc Linux
   - Plan: Basic B1 (hoặc cao hơn)

#### Bước 3: Deploy
- Sử dụng Visual Studio: Right-click project → Publish → Azure
- Hoặc sử dụng Azure CLI:
```bash
az webapp deployment source config-zip --resource-group <resource-group> --name <app-name> --src publish.zip
```

#### Bước 4: Cấu hình
- **Connection String**: Thêm vào Configuration → Connection strings
- **App Settings**: Thêm Stripe keys, Blockchain config
- **CORS**: Đã được cấu hình trong code (AllowAll)

#### Bước 5: Cập nhật Flutter App
```dart
// lib/utils/config.dart
static const String prodBaseUrl = "https://fressfood-api.azurewebsites.net/api";
static const bool isProduction = true;
```

---

### 2. AWS Elastic Beanstalk

#### Bước 1: Chuẩn bị
```bash
dotnet publish -c Release
```

#### Bước 2: Tạo Elastic Beanstalk
1. Đăng nhập AWS Console
2. Tạo Elastic Beanstalk application
3. Platform: .NET Core on Linux
4. Upload file publish

#### Bước 3: Cấu hình Environment Variables
- ConnectionStrings__DefaultConnection
- Stripe__SecretKey
- Stripe__PublishableKey

---

### 3. VPS/Server riêng (Ubuntu/Linux)

#### Bước 1: Cài đặt .NET 8 trên server
```bash
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version 8.0.0
```

#### Bước 2: Deploy ứng dụng
```bash
# Copy files lên server
scp -r publish/* user@your-server:/var/www/fressfood-api

# Trên server, tạo systemd service
sudo nano /etc/systemd/system/fressfood-api.service
```

**File service:**
```ini
[Unit]
Description=FressFood API
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/dotnet /var/www/fressfood-api/FressFood.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=fressfood-api
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://localhost:5000

[Install]
WantedBy=multi-user.target
```

#### Bước 3: Cấu hình Nginx (Reverse Proxy)
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### Bước 4: Cài đặt SSL (Let's Encrypt)
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

---

### 4. Docker + Cloud (Docker Hub, Azure Container Instances)

#### Bước 1: Tạo Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["FressFood/FressFood.csproj", "FressFood/"]
RUN dotnet restore "FressFood/FressFood.csproj"
COPY . .
WORKDIR "/src/FressFood"
RUN dotnet build "FressFood.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "FressFood.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "FressFood.dll"]
```

#### Bước 2: Build và Push
```bash
docker build -t fressfood-api .
docker tag fressfood-api your-dockerhub/fressfood-api:latest
docker push your-dockerhub/fressfood-api:latest
```

---

## 🔧 Cấu hình sau khi Deploy

### 1. Cập nhật Connection String
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=your-server;Database=FressFood;User Id=sa;Password=your-password;TrustServerCertificate=true;"
  }
}
```

### 2. Cấu hình CORS (nếu cần)
Trong `Program.cs`, có thể giới hạn origins:
```csharp
options.AddPolicy("AllowSpecificOrigins", policy =>
{
    policy.WithOrigins("https://your-app-domain.com")
          .AllowAnyMethod()
          .AllowAnyHeader();
});
```

### 3. Cấu hình Static Files
Đảm bảo thư mục `wwwroot/images` được serve công khai.

---

## 📱 Cập nhật Flutter App

### 1. Cập nhật Config
```dart
// lib/utils/config.dart
static const String prodBaseUrl = "https://your-api-domain.com/api";
static const bool isProduction = true;
```

### 2. Build và Test
```bash
flutter build apk --release
# hoặc
flutter build ios --release
```

---

## 🔍 Kiểm tra sau khi Deploy

### 1. Test API
```bash
curl https://your-api-domain.com/api/Product
```

### 2. Test QR Code
- Tạo QR code từ app
- Quét bằng điện thoại khác
- Kiểm tra xem có mở được trang thông tin truy xuất không

### 3. Test CORS
- Mở app từ thiết bị khác
- Kiểm tra API calls có hoạt động không

---

## 🛠️ Troubleshooting

### Lỗi CORS
- Kiểm tra CORS policy trong `Program.cs`
- Đảm bảo `AllowAnyOrigin()` hoặc thêm domain của bạn

### Lỗi Connection String
- Kiểm tra SQL Server có accessible từ server không
- Sử dụng Azure SQL Database nếu deploy lên Azure

### Lỗi Static Files
- Kiểm tra `app.UseStaticFiles()` trong `Program.cs`
- Đảm bảo thư mục `wwwroot` được copy khi publish

---

## 📝 Checklist Deploy

- [ ] Backend đã được publish
- [ ] Deploy lên server thành công
- [ ] Connection string đã được cấu hình
- [ ] Stripe keys đã được thêm vào App Settings
- [ ] CORS đã được cấu hình đúng
- [ ] SSL certificate đã được cài đặt (HTTPS)
- [ ] Flutter app đã cập nhật baseUrl
- [ ] Test QR code từ thiết bị khác thành công
- [ ] Test API calls từ app thành công

---

## 💡 Gợi ý

1. **Sử dụng Environment Variables** thay vì hardcode trong code
2. **Sử dụng Azure Key Vault** hoặc AWS Secrets Manager cho sensitive data
3. **Setup CI/CD** với GitHub Actions hoặc Azure DevOps
4. **Monitor** với Application Insights hoặc CloudWatch
5. **Backup database** định kỳ

---

## 🔗 Tài liệu tham khảo

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [AWS Elastic Beanstalk .NET](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_NET.html)
- [Deploy ASP.NET Core to Linux](https://docs.microsoft.com/aspnet/core/host-and-deploy/linux-nginx)

