using Microsoft.AspNetCore.Mvc;
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
                    Metadata = new Dictionary<string, string>
                    {
                        { "orderId", request.OrderId ?? "" },
                        { "userId", request.UserId ?? "" }
                    }
                };

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
                    return Ok(new
                    {
                        success = true,
                        message = "Thanh toán thành công",
                        paymentIntentId = paymentIntent.Id
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
    }

    public class CreatePaymentIntentRequest
    {
        public decimal Amount { get; set; }
        public string? OrderId { get; set; }
        public string? UserId { get; set; }
    }

    public class ConfirmPaymentRequest
    {
        public string PaymentIntentId { get; set; } = string.Empty;
    }
}

