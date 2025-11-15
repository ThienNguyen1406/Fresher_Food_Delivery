var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

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

app.MapControllers();

app.UseStaticFiles();// ?nh
app.MapControllers(); // hoặc app.MapDefaultControllerRoute();

app.Run();
