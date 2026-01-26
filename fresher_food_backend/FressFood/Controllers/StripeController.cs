using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Stripe;
using Stripe.Checkout;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StripeController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public StripeController(IConfiguration configuration)
        {
            _configuration = configuration;
            StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];
        }

        // POST: api/Stripe/create-payment-intent
        [HttpPost("create-payment-intent")]
        public IActionResult CreatePaymentIntent([FromBody] CreatePaymentIntentRequest request)
        {
            try
            {
                // Stripe không hỗ trợ VND, sử dụng USD và chuyển đổi
                // 1 USD ≈ 25,000 VND (có thể cập nhật tỷ giá thực tế)
                // Amount đã là VND, chuyển sang USD (smallest unit = cents)
                var usdAmount = (long)((request.Amount / 25000) * 100); // Chuyển VND sang USD cents
                if (usdAmount < 50) usdAmount = 50; // Minimum $0.50
                
                var options = new PaymentIntentCreateOptions
                {
                    Amount = usdAmount,
                    Currency = "usd", // Stripe không hỗ trợ VND, dùng USD
                    PaymentMethodTypes = new List<string> { "card" },
                    // Với CardFormField, khi confirm payment với PaymentMethodParams.card(),
                    // Stripe sẽ tự động lấy card details từ CardFormField và tạo PaymentMethod
                    // Không cần automatic_payment_methods - chỉ cần payment_method_types
                    Metadata = new Dictionary<string, string>
                    {
                        { "orderId", request.OrderId ?? "" },
                        { "userId", request.UserId ?? "" }
                    }
                };

                // Nếu có payment method ID (thẻ đã lưu), attach vào payment intent
                if (!string.IsNullOrEmpty(request.PaymentMethodId))
                {
                    options.PaymentMethod = request.PaymentMethodId;
                }

                var service = new PaymentIntentService();
                var paymentIntent = service.Create(options);

                return Ok(new
                {
                    clientSecret = paymentIntent.ClientSecret,
                    paymentIntentId = paymentIntent.Id
                });
            }
            catch (StripeException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Stripe/update-payment-intent
        [HttpPut("update-payment-intent")]
        public IActionResult UpdatePaymentIntent([FromBody] UpdatePaymentIntentRequest request)
        {
            try
            {
                var service = new PaymentIntentService();
                var updateOptions = new PaymentIntentUpdateOptions
                {
                    PaymentMethod = request.PaymentMethodId
                };

                var paymentIntent = service.Update(request.PaymentIntentId, updateOptions);

                return Ok(new
                {
                    success = true,
                    paymentIntentId = paymentIntent.Id,
                    clientSecret = paymentIntent.ClientSecret
                });
            }
            catch (StripeException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Stripe/confirm-payment
        [HttpPost("confirm-payment")]
        public IActionResult ConfirmPayment([FromBody] ConfirmPaymentRequest request)
        {
            try
            {
                var service = new PaymentIntentService();
                var paymentIntent = service.Get(request.PaymentIntentId);

                if (paymentIntent.Status == "succeeded")
                {
                    // Lấy payment method ID từ payment intent
                    string? paymentMethodId = null;
                    if (paymentIntent.PaymentMethodId != null)
                    {
                        paymentMethodId = paymentIntent.PaymentMethodId;
                    }
                    else if (paymentIntent.PaymentMethod != null)
                    {
                        paymentMethodId = paymentIntent.PaymentMethod.Id;
                    }

                    return Ok(new
                    {
                        success = true,
                        message = "Thanh toán thành công",
                        paymentIntentId = paymentIntent.Id,
                        paymentMethodId = paymentMethodId
                    });
                }
                else
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = $"Thanh toán chưa hoàn tất. Trạng thái: {paymentIntent.Status}"
                    });
                }
            }
            catch (StripeException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Stripe/publishable-key
        [HttpGet("publishable-key")]
        public IActionResult GetPublishableKey()
        {
            try
            {
                var publishableKey = _configuration["Stripe:PublishableKey"];
                
                if (string.IsNullOrEmpty(publishableKey))
                {
                    return BadRequest(new { error = "Publishable key is not configured in appsettings.json" });
                }
                
                System.Diagnostics.Debug.WriteLine($"✅ Returning publishable key: {publishableKey.Substring(0, Math.Min(20, publishableKey.Length))}...");
                
                return Ok(new { publishableKey });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error getting publishable key: {ex.Message}");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Stripe/save-card
        [HttpPost("save-card")]
        public IActionResult SaveCard([FromBody] SaveCardRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                
                // Lấy thông tin thẻ từ Stripe Payment Method
                var paymentMethodService = new PaymentMethodService();
                var paymentMethod = paymentMethodService.Get(request.PaymentMethodId);
                
                if (paymentMethod.Card == null)
                {
                    return BadRequest(new { error = "Payment method không có thông tin thẻ" });
                }

                var cardId = $"CARD-{Guid.NewGuid().ToString().Substring(0, 8)}";
                var last4 = paymentMethod.Card.Last4;
                var brand = paymentMethod.Card.Brand ?? "unknown";
                var expMonth = paymentMethod.Card.ExpMonth;
                var expYear = paymentMethod.Card.ExpYear;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    // Nếu đặt làm mặc định, bỏ mặc định của các thẻ khác
                    if (request.IsDefault)
                    {
                        string updateQuery = "UPDATE SavedCard SET IsDefault = 0 WHERE MaTaiKhoan = @MaTaiKhoan";
                        using (var updateCommand = new SqlCommand(updateQuery, connection))
                        {
                            updateCommand.Parameters.AddWithValue("@MaTaiKhoan", request.UserId);
                            updateCommand.ExecuteNonQuery();
                        }
                    }

                    string query = @"INSERT INTO SavedCard 
                        (Id, MaTaiKhoan, PaymentMethodId, Last4, Brand, ExpMonth, ExpYear, CardholderName, NgayTao, IsDefault)
                        VALUES (@Id, @MaTaiKhoan, @PaymentMethodId, @Last4, @Brand, @ExpMonth, @ExpYear, @CardholderName, GETDATE(), @IsDefault)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id", cardId);
                        command.Parameters.AddWithValue("@MaTaiKhoan", request.UserId);
                        command.Parameters.AddWithValue("@PaymentMethodId", request.PaymentMethodId);
                        command.Parameters.AddWithValue("@Last4", last4);
                        command.Parameters.AddWithValue("@Brand", brand);
                        command.Parameters.AddWithValue("@ExpMonth", expMonth);
                        command.Parameters.AddWithValue("@ExpYear", expYear);
                        command.Parameters.AddWithValue("@CardholderName", (object?)request.CardholderName ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsDefault", request.IsDefault);
                        
                        command.ExecuteNonQuery();
                    }
                }

                return Ok(new
                {
                    id = cardId,
                    userId = request.UserId,
                    paymentMethodId = request.PaymentMethodId,
                    last4 = last4,
                    brand = brand,
                    expMonth = expMonth,
                    expYear = expYear,
                    cardholderName = request.CardholderName,
                    createdAt = DateTime.Now,
                    isDefault = request.IsDefault
                });
            }
            catch (StripeException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Stripe/saved-cards?userId=
        [HttpGet("saved-cards")]
        public IActionResult GetSavedCards([FromQuery] string userId)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var cards = new List<object>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT Id, MaTaiKhoan, PaymentMethodId, Last4, Brand, ExpMonth, ExpYear, CardholderName, NgayTao, IsDefault
                                   FROM SavedCard 
                                   WHERE MaTaiKhoan = @MaTaiKhoan
                                   ORDER BY IsDefault DESC, NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", userId);
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                cards.Add(new
                                {
                                    id = reader["Id"].ToString(),
                                    userId = reader["MaTaiKhoan"].ToString(),
                                    paymentMethodId = reader["PaymentMethodId"].ToString(),
                                    last4 = reader["Last4"].ToString(),
                                    brand = reader["Brand"].ToString(),
                                    expMonth = (int)reader["ExpMonth"],
                                    expYear = (int)reader["ExpYear"],
                                    cardholderName = reader["CardholderName"] as string,
                                    createdAt = ((DateTime)reader["NgayTao"]).ToString("yyyy-MM-ddTHH:mm:ss"),
                                    isDefault = (bool)reader["IsDefault"]
                                });
                            }
                        }
                    }
                }

                return Ok(cards);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Stripe/saved-cards/{id}
        [HttpDelete("saved-cards/{id}")]
        public IActionResult DeleteSavedCard(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "DELETE FROM SavedCard WHERE Id = @Id";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id", id);
                        int rowsAffected = command.ExecuteNonQuery();
                        
                        if (rowsAffected == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy thẻ" });
                        }
                    }
                }

                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Stripe/saved-cards/{id}/set-default
        [HttpPut("saved-cards/{id}/set-default")]
        public IActionResult SetDefaultCard(string id, [FromBody] SetDefaultCardRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    // Bỏ mặc định của tất cả thẻ của user
                    string updateQuery = "UPDATE SavedCard SET IsDefault = 0 WHERE MaTaiKhoan = @MaTaiKhoan";
                    using (var updateCommand = new SqlCommand(updateQuery, connection))
                    {
                        updateCommand.Parameters.AddWithValue("@MaTaiKhoan", request.UserId);
                        updateCommand.ExecuteNonQuery();
                    }

                    // Đặt thẻ này làm mặc định
                    string query = "UPDATE SavedCard SET IsDefault = 1 WHERE Id = @Id AND MaTaiKhoan = @MaTaiKhoan";
                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id", id);
                        command.Parameters.AddWithValue("@MaTaiKhoan", request.UserId);
                        int rowsAffected = command.ExecuteNonQuery();
                        
                        if (rowsAffected == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy thẻ" });
                        }
                    }
                }

                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class CreatePaymentIntentRequest
    {
        public decimal Amount { get; set; }
        public string? OrderId { get; set; }
        public string? UserId { get; set; }
        public string? PaymentMethodId { get; set; }
    }

    public class ConfirmPaymentRequest
    {
        public string PaymentIntentId { get; set; } = string.Empty;
    }

    public class SaveCardRequest
    {
        public string PaymentMethodId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string? CardholderName { get; set; }
        public bool IsDefault { get; set; } = false;
    }

    public class SetDefaultCardRequest
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class UpdatePaymentIntentRequest
    {
        public string PaymentIntentId { get; set; } = string.Empty;
        public string PaymentMethodId { get; set; } = string.Empty;
    }
}

