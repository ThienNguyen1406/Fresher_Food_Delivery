using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.Linq;

namespace FressFood.Filters
{
    /// <summary>
    /// Filter để xử lý lỗi khi generate Swagger document
    /// </summary>
    public class SwaggerDocumentFilter : IDocumentFilter
    {
        public void Apply(OpenApiDocument swaggerDoc, DocumentFilterContext context)
        {
            try
            {
                // Loại bỏ các path có vấn đề
                var pathsToRemove = swaggerDoc.Paths
                    .Where(path => path.Value.Operations == null || !path.Value.Operations.Any())
                    .Select(path => path.Key)
                    .ToList();
                
                foreach (var path in pathsToRemove)
                {
                    swaggerDoc.Paths.Remove(path);
                }
                
                // Đảm bảo các schema hợp lệ
                var schemasToRemove = swaggerDoc.Components?.Schemas?
                    .Where(schema => schema.Value == null)
                    .Select(schema => schema.Key)
                    .ToList();
                
                if (schemasToRemove != null && swaggerDoc.Components?.Schemas != null)
                {
                    foreach (var schemaKey in schemasToRemove)
                    {
                        swaggerDoc.Components.Schemas.Remove(schemaKey);
                    }
                }
            }
            catch (Exception)
            {
                // Bỏ qua lỗi và tiếp tục generate document
            }
        }
    }
}

