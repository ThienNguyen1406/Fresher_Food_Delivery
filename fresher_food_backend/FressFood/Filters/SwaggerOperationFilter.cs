using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.Collections.Generic;
using System.Linq;

namespace FressFood.Filters
{
    /// <summary>
    /// Filter Ä‘á»ƒ xá»­ lÃ½ cÃ¡c operation cÃ³ váº¥n Ä‘á» trong Swagger
    /// </summary>
    public class SwaggerOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            try
            {
                // Xá»­ lÃ½ cÃ¡c parameter cÃ³ váº¥n Ä‘á»
                if (operation.Parameters != null)
                {
                    foreach (var parameter in operation.Parameters.ToList())
                    {
                        try
                        {
                            // Kiá»ƒm tra náº¿u parameter schema cÃ³ váº¥n Ä‘á»
                            if (parameter.Schema == null)
                            {
                                parameter.Schema = new OpenApiSchema
                                {
                                    Type = "string"
                                };
                            }
                        }
                        catch
                        {
                            // Bá» qua parameter cÃ³ váº¥n Ä‘á»
                            operation.Parameters.Remove(parameter);
                        }
                    }
                }

                // Xá»­ lÃ½ request body
                if (operation.RequestBody != null)
                {
                    try
                    {
                        if (operation.RequestBody.Content != null)
                        {
                            foreach (var content in operation.RequestBody.Content.ToList())
                            {
                                if (content.Value?.Schema == null)
                                {
                                    operation.RequestBody.Content.Remove(content.Key);
                                }
                            }
                        }
                    }
                    catch
                    {
                        // Náº¿u request body cÃ³ váº¥n Ä‘á», Ä‘áº·t láº¡i
                        operation.RequestBody = null;
                    }
                }

                // Xá»­ lÃ½ responses
                if (operation.Responses != null)
                {
                    foreach (var response in operation.Responses.ToList())
                    {
                        try
                        {
                            if (response.Value?.Content != null)
                            {
                                foreach (var content in response.Value.Content.ToList())
                                {
                                    if (content.Value?.Schema == null)
                                    {
                                        response.Value.Content.Remove(content.Key);
                                    }
                                }
                            }
                        }
                        catch
                        {
                            // Náº¿u response cÃ³ váº¥n Ä‘á», bá» qua vÃ  Ä‘á»ƒ Swagger xá»­ lÃ½ máº·c Ä‘á»‹nh
                            // KhÃ´ng thá»ƒ reassign Content vÃ¬ nÃ³ cÃ³ thá»ƒ lÃ  read-only
                        }
                    }
                }
            }
            catch (Exception)
            {
                // Bá» qua lá»—i vÃ  tiáº¿p tá»¥c
            }
        }
    }
}