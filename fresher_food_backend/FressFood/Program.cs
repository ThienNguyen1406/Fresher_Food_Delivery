var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Cấu hình JSON để chấp nhận camelCase từ frontend
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
        options.JsonSerializerOptions.WriteIndented = true;
    });

// Thêm CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .AllowAnyOrigin() // Cho phép mọi origin (tạm thời để test)
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});


// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpContextAccessor();

// Đăng ký BlockchainService
builder.Services.AddScoped<FressFood.Services.IBlockchainService, FressFood.Services.BlockchainService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Thêm middleware CORS
//app.UseCors("AllowLocalhost5500");
app.UseCors("AllowAll");

app.UseAuthorization();

app.UseStaticFiles();// Ảnh

app.MapControllers();

app.Run();
