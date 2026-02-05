using Microsoft.AspNetCore.Http;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.IO;
using System.Threading.Tasks;

namespace FressFood.Filters
{
    /// <summary>
    /// Filter để xử lý các schema có vấn đề trong Swagger
    /// </summary>
    public class SwaggerSchemaFilter : ISchemaFilter
    {
        public void Apply(OpenApiSchema schema, SchemaFilterContext context)
        {
            try
            {
                var type = context.Type;
                
                // Kiểm tra null type
                if (type == null)
                {
                    return;
                }
                
                // Bỏ qua các type không thể serialize
                if (type == typeof(IFormFile) || 
                    type == typeof(Stream) || 
                    type == typeof(FileStream) ||
                    type == typeof(MemoryStream))
                {
                    schema.Type = "string";
                    schema.Format = "binary";
                    return;
                }
                
                // Xử lý các type generic phức tạp
                if (type.IsGenericType)
                {
                    try
                    {
                        var genericTypeDefinition = type.GetGenericTypeDefinition();
                        if (genericTypeDefinition == typeof(Task<>) || 
                            genericTypeDefinition == typeof(ValueTask<>))
                        {
                            // Swagger sẽ tự động xử lý Task<T>
                            return;
                        }
                    }
                    catch
                    {
                        // Bỏ qua nếu không thể lấy generic type definition
                    }
                }
                
                // Xử lý nullable types
                if (type.IsGenericType)
                {
                    try
                    {
                        if (type.GetGenericTypeDefinition() == typeof(Nullable<>))
                        {
                            var underlyingType = Nullable.GetUnderlyingType(type);
                            if (underlyingType != null)
                            {
                                schema.Nullable = true;
                            }
                        }
                    }
                    catch
                    {
                        // Bỏ qua nếu không thể xử lý nullable type
                    }
                }
            }
            catch (Exception)
            {
                // Bỏ qua lỗi và để Swagger xử lý mặc định
            }
        }
    }
}

