using FressFood.Filters;
using Microsoft.AspNetCore.Http;
using System.IO;

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
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "FressFood API",
        Version = "v1",
        Description = "API for Fresher Food Delivery System"
    });
    // Ignore lỗi khi generate schema - dùng FullName để tránh conflict
    c.CustomSchemaIds(type =>
    {
        try
        {
            if (type == null) return "Unknown";
            return type.FullName?.Replace("+", ".") ?? type.Name;
        }
        catch
        {
            return type?.Name ?? "Unknown";
        }
    });
    // Ignore các model có vấn đề
    c.IgnoreObsoleteActions();
    c.IgnoreObsoleteProperties();
    // Xử lý nullable reference types
    c.SupportNonNullableReferenceTypes();
    
    // Xử lý IFormFile - map thành file upload type
    c.MapType<IFormFile>(() => new Microsoft.OpenApi.Models.OpenApiSchema
    {
        Type = "string",
        Format = "binary"
    });
    
    // Xử lý Stream - map thành file type
    c.MapType<Stream>(() => new Microsoft.OpenApi.Models.OpenApiSchema
    {
        Type = "string",
        Format = "binary"
    });
    
    // Xử lý FileStream - map thành file type
    c.MapType<FileStream>(() => new Microsoft.OpenApi.Models.OpenApiSchema
    {
        Type = "string",
        Format = "binary"
    });
    
    // Bỏ qua các type không thể serialize
    c.SchemaFilter<SwaggerSchemaFilter>();
    
    // Xử lý lỗi khi generate document
    c.DocumentFilter<SwaggerDocumentFilter>();
    
    // Xử lý các operation có vấn đề
    c.OperationFilter<SwaggerOperationFilter>();
    
    // Bỏ qua các action có lỗi
    c.ResolveConflictingActions(apiDescriptions => apiDescriptions.First());
});
builder.Services.AddHttpContextAccessor();

// Đăng ký BlockchainService
builder.Services.AddScoped<FressFood.Services.IBlockchainService, FressFood.Services.BlockchainService>();

// Đăng ký HttpClient cho AI Service
builder.Services.AddHttpClient();

// Đăng ký AI Service (OpenAI) với Function Handler
builder.Services.AddScoped<FressFood.Services.IAIService>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var logger = sp.GetRequiredService<ILogger<FressFood.Services.OpenAIService>>();
    var httpClientFactory = sp.GetRequiredService<IHttpClientFactory>();
    var functionHandler = sp.GetRequiredService<FressFood.Services.IFunctionHandler>();
    return new FressFood.Services.OpenAIService(config, logger, httpClientFactory, functionHandler);
});

// Đăng ký Python RAG Service (gọi Python service qua HTTP) 
builder.Services.AddScoped<FressFood.Services.PythonRAGService>();

// Đăng ký Function Handler Service (gọi Python function handler qua HTTP)
builder.Services.AddScoped<FressFood.Services.IFunctionHandler, FressFood.Services.FunctionHandlerService>();

// Đăng ký ChatbotService
builder.Services.AddScoped<FressFood.Services.ChatbotService>();

// Đăng ký EmailService
builder.Services.AddScoped<FressFood.Services.EmailService>();

var app = builder.Build();

// Thêm error handling middleware sớm để catch lỗi Swagger
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception ex)
    {
        var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Unhandled exception: {Path}", context.Request.Path);
        
        if (context.Request.Path.StartsWithSegments("/swagger"))
        {
            // Log full exception details for debugging
            logger.LogError(ex, "Swagger error: {Message}", ex.Message);
            logger.LogError(ex, "Swagger error details: {StackTrace}", ex.StackTrace);
            if (ex.InnerException != null)
            {
                logger.LogError(ex.InnerException, "Swagger inner exception: {Message}", ex.InnerException.Message);
            }
            
            context.Response.StatusCode = 500;
            context.Response.ContentType = "application/json";
            var errorJson = System.Text.Json.JsonSerializer.Serialize(new { 
                error = "Swagger generation failed", 
                message = ex.Message,
                type = ex.GetType().Name,
                innerException = ex.InnerException?.Message,
                innerExceptionType = ex.InnerException?.GetType().Name,
                stackTrace = app.Environment.IsDevelopment() ? ex.StackTrace : null,
                innerStackTrace = app.Environment.IsDevelopment() ? ex.InnerException?.StackTrace : null
            });
            await context.Response.WriteAsync(errorJson);
            return;
        }
        throw;
    }
});

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger(c =>
    {
        c.RouteTemplate = "swagger/{documentName}/swagger.json";
    });
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "FressFood API v1");
        c.RoutePrefix = "swagger";
        c.DisplayRequestDuration();
    });
}

app.UseHttpsRedirection();

// Thêm middleware CORS
//app.UseCors("AllowLocalhost5500");
app.UseCors("AllowAll");

app.UseAuthorization();

app.UseStaticFiles();// Ảnh

app.MapControllers();

// Kiểm tra Python RAG service có đang chạy không (chạy bất đồng bộ trong background)
_ = Task.Run(async () =>
{
    await Task.Delay(2000); // Đợi app khởi động xong
    using (var scope = app.Services.CreateScope())
    {
        var ragService = scope.ServiceProvider.GetRequiredService<FressFood.Services.PythonRAGService>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        
        try
        {
            var isAvailable = await ragService.IsServiceAvailableAsync();
            if (isAvailable)
            {
                logger.LogInformation("Python RAG service is available");
            }
            else
            {
                logger.LogWarning("Python RAG service is not available. Please start the Python service at http://localhost:8000");
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error checking Python RAG service availability");
        }
    }
});

app.Run();
