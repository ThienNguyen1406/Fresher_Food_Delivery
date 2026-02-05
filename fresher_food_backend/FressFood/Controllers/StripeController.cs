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
        // ✅ Flow chuẩn: Hỗ trợ cả thẻ mới và thẻ đã lưu
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

                // ✅ Nếu có PaymentMethodId (thẻ đã lưu), sử dụng Customer và PaymentMethod
                if (!string.IsNullOrEmpty(request.PaymentMethodId) && !string.IsNullOrEmpty(request.UserId))
                {
                    try
                    {
                        var paymentMethodService = new PaymentMethodService();
                        var getOptions = new PaymentMethodGetOptions
                        {
                            Expand = new List<string> { "customer" }
                        };
                        var paymentMethod = paymentMethodService.Get(request.PaymentMethodId, getOptions);
                        
                        System.Diagnostics.Debug.WriteLine($"🔍 PaymentMethod {request.PaymentMethodId} - Customer: {paymentMethod.Customer?.Id ?? "null"}");
                        
                        string customerId;
                        
                        // QUAN TRỌNG: Luôn kiểm tra xem PaymentMethod đã có Customer chưa
                        // Nếu có, PHẢI dùng Customer đó, không được attach vào Customer khác
                        if (paymentMethod.Customer != null)
                        {
                            customerId = paymentMethod.Customer.Id;
                            System.Diagnostics.Debug.WriteLine($"✅ PaymentMethod {request.PaymentMethodId} already attached to Customer {customerId} - using this Customer");
                        }
                        else
                        {
                            // PaymentMethod chưa có Customer, tạo/lấy Customer và attach
                            customerId = GetOrCreateCustomer(request.UserId);
                            
                            // Thử attach PaymentMethod vào Customer
                            // Nếu đã attach rồi (race condition hoặc attach vào Customer khác), lấy lại PaymentMethod để có Customer ID
                            try
                            {
                                var attachOptions = new PaymentMethodAttachOptions
                                {
                                    Customer = customerId
                                };
                                paymentMethodService.Attach(request.PaymentMethodId, attachOptions);
                                System.Diagnostics.Debug.WriteLine($"✅ Attached PaymentMethod {request.PaymentMethodId} to Customer {customerId}");
                                
                                // Sau khi attach thành công, lấy lại PaymentMethod để đảm bảo có Customer ID
                                var verifyOptions = new PaymentMethodGetOptions
                                {
                                    Expand = new List<string> { "customer" }
                                };
                                paymentMethod = paymentMethodService.Get(request.PaymentMethodId, verifyOptions);
                                if (paymentMethod.Customer != null)
                                {
                                    customerId = paymentMethod.Customer.Id;
                                    System.Diagnostics.Debug.WriteLine($"✅ Verified Customer {customerId} for PaymentMethod {request.PaymentMethodId}");
                                }
                            }
                            catch (StripeException attachEx)
                            {
                                // Nếu PaymentMethod đã được attach vào Customer (có thể là Customer khác),
                                // BẮT BUỘC phải lấy Customer ID từ PaymentMethod thực tế
                                // KHÔNG được dùng Customer từ GetOrCreateCustomer vì sẽ gây lỗi "does not belong to Customer"
                                if (attachEx.Message.Contains("already been attached") || 
                                    attachEx.Message.Contains("already attached") ||
                                    attachEx.Message.Contains("does not belong to"))
                                {
                                    System.Diagnostics.Debug.WriteLine($"⚠️ PaymentMethod {request.PaymentMethodId} attachment issue: {attachEx.Message}");
                                    System.Diagnostics.Debug.WriteLine($"⚠️ Getting Customer ID from PaymentMethod...");
                                    
                                    // Retry nhiều lần với expand parameter để đảm bảo Customer được trả về
                                    PaymentMethod? updatedPaymentMethod = null;
                                    var retryGetOptions = new PaymentMethodGetOptions
                                    {
                                        Expand = new List<string> { "customer" }
                                    };
                                    
                                    for (int retry = 0; retry < 10; retry++)
                                    {
                                        if (retry > 0)
                                        {
                                            System.Threading.Thread.Sleep(500); // Đợi 500ms giữa các lần retry
                                        }
                                        try
                                        {
                                            updatedPaymentMethod = paymentMethodService.Get(request.PaymentMethodId, retryGetOptions);
                                            if (updatedPaymentMethod != null && updatedPaymentMethod.Customer != null)
                                            {
                                                break;
                                            }
                                        }
                                        catch (Exception retryEx)
                                        {
                                            System.Diagnostics.Debug.WriteLine($"⏳ Retry {retry + 1}/10: Error getting PaymentMethod: {retryEx.Message}");
                                        }
                                        System.Diagnostics.Debug.WriteLine($"⏳ Retry {retry + 1}/10: PaymentMethod {request.PaymentMethodId} has no Customer yet");
                                    }
                                    
                                    // Nếu vẫn không lấy được Customer từ PaymentMethod, thử cách khác
                                    if (updatedPaymentMethod == null || updatedPaymentMethod.Customer == null)
                                    {
                                        // Thử lấy Customer ID từ StripeException message nếu có
                                        var customerIdMatch = System.Text.RegularExpressions.Regex.Match(
                                            attachEx.Message, 
                                            @"Customer\s+['""]?([a-z0-9_]+)['""]?",
                                            System.Text.RegularExpressions.RegexOptions.IgnoreCase
                                        );
                                        
                                        if (customerIdMatch.Success && customerIdMatch.Groups.Count > 1)
                                        {
                                            customerId = customerIdMatch.Groups[1].Value;
                                            System.Diagnostics.Debug.WriteLine($"✅ Extracted Customer {customerId} from error message");
                                        }
                                        else
                                        {
                                            // Nếu vẫn không có Customer sau khi retry, throw error rõ ràng
                                            System.Diagnostics.Debug.WriteLine($"❌ Cannot retrieve Customer ID from PaymentMethod after retries");
                                            throw new Exception($"PaymentMethod {request.PaymentMethodId} is attached to a different Customer, but we cannot retrieve the Customer ID. Please try again or use a different payment method.");
                                        }
                                    }
                                    else
                                    {
                                        customerId = updatedPaymentMethod.Customer.Id;
                                        System.Diagnostics.Debug.WriteLine($"✅ Using existing Customer {customerId} for PaymentMethod {request.PaymentMethodId}");
                                    }
                                }
                                else
                                {
                                    throw; // Re-throw nếu là lỗi khác
                                }
                            }
                        }
                        
                        // Set Customer và PaymentMethod vào PaymentIntent options
                        options.Customer = customerId;
                        options.PaymentMethod = request.PaymentMethodId;
                        options.ConfirmationMethod = "automatic";
                        options.Confirm = false; // Không confirm ngay, để frontend confirm
                        
                        System.Diagnostics.Debug.WriteLine($"✅ Using PaymentMethod {request.PaymentMethodId} with Customer {customerId}");
                        
                        // Đảm bảo PaymentMethod được set
                        if (string.IsNullOrEmpty(options.PaymentMethod))
                        {
                            throw new Exception("Failed to set PaymentMethod in PaymentIntent options");
                        }
                    }
                    catch (StripeException ex)
                    {
                        // Nếu PaymentMethod đã bị detach và không thể sử dụng lại, thông báo lỗi rõ ràng
                        if (ex.Message.Contains("may not be used again") || 
                            ex.Message.Contains("was previously used without being attached") ||
                            ex.Message.Contains("was detached from a Customer"))
                        {
                            System.Diagnostics.Debug.WriteLine($"❌ PaymentMethod {request.PaymentMethodId} has been detached and cannot be reused");
                            return BadRequest(new { 
                                error = "Thẻ thanh toán này đã bị vô hiệu hóa và không thể sử dụng lại. Vui lòng xóa thẻ này và thêm thẻ mới.",
                                code = "PAYMENT_METHOD_DETACHED"
                            });
                        }
                        
                        // Nếu lỗi là "does not belong to Customer", thử lấy Customer từ PaymentMethod
                        if (ex.Message.Contains("does not belong to"))
                        {
                            System.Diagnostics.Debug.WriteLine($"⚠️ PaymentMethod belongs to different Customer, getting Customer from PaymentMethod...");
                            try
                            {
                                var paymentMethodService = new PaymentMethodService();
                                var errorGetOptions = new PaymentMethodGetOptions
                                {
                                    Expand = new List<string> { "customer" }
                                };
                                
                                PaymentMethod? paymentMethod = null;
                                for (int retry = 0; retry < 10; retry++)
                                {
                                    if (retry > 0)
                                    {
                                        System.Threading.Thread.Sleep(500);
                                    }
                                    try
                                    {
                                        paymentMethod = paymentMethodService.Get(request.PaymentMethodId, errorGetOptions);
                                        if (paymentMethod != null && paymentMethod.Customer != null)
                                        {
                                            break;
                                        }
                                    }
                                    catch (Exception retryEx)
                                    {
                                        System.Diagnostics.Debug.WriteLine($"⏳ Retry {retry + 1}/10: Error getting PaymentMethod: {retryEx.Message}");
                                    }
                                }
                                
                                // Nếu vẫn không lấy được Customer từ PaymentMethod, thử extract từ error message
                                if (paymentMethod == null || paymentMethod.Customer == null)
                                {
                                    var customerIdMatch = System.Text.RegularExpressions.Regex.Match(
                                        ex.Message, 
                                        @"Customer\s+['""]?([a-z0-9_]+)['""]?",
                                        System.Text.RegularExpressions.RegexOptions.IgnoreCase
                                    );
                                    
                                    if (customerIdMatch.Success && customerIdMatch.Groups.Count > 1)
                                    {
                                        var correctCustomerId = customerIdMatch.Groups[1].Value;
                                        System.Diagnostics.Debug.WriteLine($"✅ Extracted Customer {correctCustomerId} from error message");
                                        
                                        options.Customer = correctCustomerId;
                                        options.PaymentMethod = request.PaymentMethodId;
                                        options.ConfirmationMethod = "automatic";
                                        options.Confirm = false;
                                        
                                        System.Diagnostics.Debug.WriteLine($"✅ Using extracted Customer {correctCustomerId} for PaymentMethod {request.PaymentMethodId}");
                                    }
                                    else
                                    {
                                        throw new Exception($"Cannot retrieve Customer ID from PaymentMethod {request.PaymentMethodId}");
                                    }
                                }
                                else
                                {
                                    var correctCustomerId = paymentMethod.Customer.Id;
                                    System.Diagnostics.Debug.WriteLine($"✅ Found Customer {correctCustomerId} for PaymentMethod {request.PaymentMethodId}");
                                    
                                    // Set Customer và PaymentMethod vào PaymentIntent options với Customer đúng
                                    options.Customer = correctCustomerId;
                                    options.PaymentMethod = request.PaymentMethodId;
                                    options.ConfirmationMethod = "automatic";
                                    options.Confirm = false;
                                    
                                    System.Diagnostics.Debug.WriteLine($"✅ Using correct Customer {correctCustomerId} for PaymentMethod {request.PaymentMethodId}");
                                    // Continue to create PaymentIntent below
                                }
                            }
                            catch (Exception getEx)
                            {
                                System.Diagnostics.Debug.WriteLine($"❌ Error getting Customer from PaymentMethod: {getEx.Message}");
                                return BadRequest(new { error = $"Error processing saved PaymentMethod: {getEx.Message}" });
                            }
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine($"❌ StripeException: Error processing saved PaymentMethod: {ex.Message}");
                            System.Diagnostics.Debug.WriteLine($"❌ StackTrace: {ex.StackTrace}");
                            return BadRequest(new { error = $"Error processing saved PaymentMethod: {ex.Message}" });
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"❌ Exception: Error processing saved PaymentMethod: {ex.Message}");
                        System.Diagnostics.Debug.WriteLine($"❌ StackTrace: {ex.StackTrace}");
                        // Không fallback - throw error để frontend biết
                        return BadRequest(new { error = $"Error processing saved PaymentMethod: {ex.Message}" });
                    }
                }
                // Nếu không có PaymentMethodId (thẻ mới), tạo PaymentIntent không có Customer/PaymentMethod
                // Stripe sẽ tự động tạo PaymentMethod mới từ CardFormField khi confirm

                var service = new PaymentIntentService();
                PaymentIntent paymentIntent;
                
                try
                {
                    paymentIntent = service.Create(options);
                }
                catch (StripeException createEx)
                {
                    // Nếu lỗi là "does not belong to Customer", lấy Customer ID từ PaymentMethod và dùng Customer đó
                    // KHÔNG detach PaymentMethod vì sẽ làm PaymentMethod không thể sử dụng lại
                    if ((createEx.Message.Contains("does not belong to the Customer") || 
                         createEx.Message.Contains("does not belong to Customer")) &&
                        !string.IsNullOrEmpty(request.PaymentMethodId) && 
                        !string.IsNullOrEmpty(request.UserId))
                    {
                        System.Diagnostics.Debug.WriteLine($"⚠️ PaymentMethod belongs to different Customer, getting Customer from PaymentMethod...");
                        try
                        {
                            var paymentMethodService = new PaymentMethodService();
                            var createErrorGetOptions = new PaymentMethodGetOptions
                            {
                                Expand = new List<string> { "customer" }
                            };
                            
                            // Retry nhiều lần để lấy Customer ID từ PaymentMethod
                            PaymentMethod? paymentMethod = null;
                            for (int retry = 0; retry < 10; retry++) // Tăng retry lên 10 lần
                            {
                                if (retry > 0)
                                {
                                    System.Threading.Thread.Sleep(500); // Đợi 500ms giữa các lần retry
                                }
                                try
                                {
                                    paymentMethod = paymentMethodService.Get(request.PaymentMethodId, createErrorGetOptions);
                                    if (paymentMethod != null && paymentMethod.Customer != null)
                                    {
                                        break;
                                    }
                                }
                                catch (Exception retryEx)
                                {
                                    System.Diagnostics.Debug.WriteLine($"⏳ Retry {retry + 1}/10: Error getting PaymentMethod: {retryEx.Message}");
                                }
                                System.Diagnostics.Debug.WriteLine($"⏳ Retry {retry + 1}/10: PaymentMethod {request.PaymentMethodId} has no Customer yet");
                            }
                            
                            // Nếu vẫn không lấy được Customer từ PaymentMethod, thử extract từ error message
                            if (paymentMethod == null || paymentMethod.Customer == null)
                            {
                                var customerIdMatch = System.Text.RegularExpressions.Regex.Match(
                                    createEx.Message, 
                                    @"Customer\s+['""]?([a-z0-9_]+)['""]?",
                                    System.Text.RegularExpressions.RegexOptions.IgnoreCase
                                );
                                
                                if (customerIdMatch.Success && customerIdMatch.Groups.Count > 1)
                                {
                                    var correctCustomerId = customerIdMatch.Groups[1].Value;
                                    System.Diagnostics.Debug.WriteLine($"✅ Extracted Customer {correctCustomerId} from error message");
                                    
                                    options.Customer = correctCustomerId;
                                    options.PaymentMethod = request.PaymentMethodId;
                                    paymentIntent = service.Create(options);
                                    System.Diagnostics.Debug.WriteLine($"✅ Created PaymentIntent {paymentIntent.Id} with extracted Customer");
                                }
                                else
                                {
                                    // Nếu vẫn không lấy được Customer, throw error
                                    throw new Exception($"PaymentMethod {request.PaymentMethodId} is attached to a Customer, but we cannot retrieve the Customer ID after multiple retries.");
                                }
                            }
                            else
                            {
                                var correctCustomerId = paymentMethod.Customer.Id;
                                System.Diagnostics.Debug.WriteLine($"✅ Found Customer {correctCustomerId} for PaymentMethod {request.PaymentMethodId}");
                                
                                // Dùng Customer mà PaymentMethod đã được attach vào
                                options.Customer = correctCustomerId;
                                options.PaymentMethod = request.PaymentMethodId;
                                paymentIntent = service.Create(options);
                                System.Diagnostics.Debug.WriteLine($"✅ Created PaymentIntent {paymentIntent.Id} with correct Customer");
                            }
                        }
                        catch (Exception getEx)
                        {
                            System.Diagnostics.Debug.WriteLine($"❌ Error getting Customer from PaymentMethod: {getEx.Message}");
                            return BadRequest(new { error = $"Error processing saved PaymentMethod: {createEx.Message}" });
                        }
                    }
                    else
                    {
                        throw; // Re-throw nếu là lỗi khác
                    }
                }

                System.Diagnostics.Debug.WriteLine($"✅ Created PaymentIntent {paymentIntent.Id}");
                System.Diagnostics.Debug.WriteLine($"🔍 PaymentIntent Customer: {paymentIntent.Customer?.Id ?? "null"}");
                System.Diagnostics.Debug.WriteLine($"🔍 PaymentIntent PaymentMethod: {paymentIntent.PaymentMethod?.Id ?? paymentIntent.PaymentMethodId ?? "null"}");

                return Ok(new
                {
                    clientSecret = paymentIntent.ClientSecret,
                    paymentIntentId = paymentIntent.Id
                });
            }
            catch (StripeException ex)
            {
                // Nếu PaymentMethod đã bị detach và không thể sử dụng lại, thông báo lỗi rõ ràng
                if (ex.Message.Contains("may not be used again") || 
                    ex.Message.Contains("was previously used without being attached") ||
                    ex.Message.Contains("was detached from a Customer"))
                {
                    System.Diagnostics.Debug.WriteLine($"❌ PaymentMethod has been detached and cannot be reused");
                    return BadRequest(new { 
                        error = "Thẻ thanh toán này đã bị vô hiệu hóa và không thể sử dụng lại. Vui lòng xóa thẻ này và thêm thẻ mới.",
                        code = "PAYMENT_METHOD_DETACHED"
                    });
                }
                
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Stripe/create-customer
        // Tạo Stripe Customer cho user mới đăng ký
        [HttpPost("create-customer")]
        public IActionResult CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            try
            {
                var customerId = GetOrCreateCustomer(request.UserId);
                return Ok(new { customerId });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // Helper method: Tạo hoặc lấy Customer ID cho user
        [ApiExplorerSettings(IgnoreApi = true)]
        public string GetOrCreateCustomer(string userId)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            string? customerId = null;

            // Kiểm tra xem user đã có Customer ID chưa
            try
            {
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    // Kiểm tra xem cột StripeCustomerId có tồn tại không
                    bool columnExists = false;
                    try
                    {
                        string checkColumnQuery = @"
                            SELECT COUNT(*) 
                            FROM INFORMATION_SCHEMA.COLUMNS 
                            WHERE TABLE_NAME = 'TaiKhoan' AND COLUMN_NAME = 'StripeCustomerId'";
                        using (var checkCommand = new SqlCommand(checkColumnQuery, connection))
                        {
                            var count = (int)checkCommand.ExecuteScalar();
                            columnExists = count > 0;
                        }
                    }
                    catch
                    {
                        columnExists = false;
                    }

                    if (columnExists)
                    {
                        string selectQuery = "SELECT StripeCustomerId FROM TaiKhoan WHERE MaTaiKhoan = @MaTaiKhoan";
                        using (var selectCommand = new SqlCommand(selectQuery, connection))
                        {
                            selectCommand.Parameters.AddWithValue("@MaTaiKhoan", userId);
                            var result = selectCommand.ExecuteScalar();
                            if (result != null && result != DBNull.Value && !string.IsNullOrEmpty(result.ToString()))
                            {
                                customerId = result.ToString();
                            }
                        }
                    }

                    // Nếu chưa có Customer ID, tạo mới
                    if (string.IsNullOrEmpty(customerId))
                    {
                        var customerService = new CustomerService();
                        var customerOptions = new CustomerCreateOptions
                        {
                            Metadata = new Dictionary<string, string>
                            {
                                { "userId", userId }
                            }
                        };
                        var customer = customerService.Create(customerOptions);
                        customerId = customer.Id;

                        // Lưu Customer ID vào database nếu cột tồn tại
                        if (columnExists)
                        {
                            try
                            {
                                string updateQuery = "UPDATE TaiKhoan SET StripeCustomerId = @StripeCustomerId WHERE MaTaiKhoan = @MaTaiKhoan";
                                using (var updateCommand = new SqlCommand(updateQuery, connection))
                                {
                                    updateCommand.Parameters.AddWithValue("@StripeCustomerId", customerId);
                                    updateCommand.Parameters.AddWithValue("@MaTaiKhoan", userId);
                                    updateCommand.ExecuteNonQuery();
                                }
                            }
                            catch (Exception ex)
                            {
                                // Log lỗi nhưng vẫn trả về customerId
                                System.Diagnostics.Debug.WriteLine($"Warning: Could not save StripeCustomerId to database: {ex.Message}");
                            }
                        }
                        else
                        {
                            // Nếu cột chưa tồn tại, tạo cột
                            try
                            {
                                string alterTableQuery = "ALTER TABLE TaiKhoan ADD StripeCustomerId NVARCHAR(255) NULL";
                                using (var alterCommand = new SqlCommand(alterTableQuery, connection))
                                {
                                    alterCommand.ExecuteNonQuery();
                                }
                                
                                // Sau khi tạo cột, lưu Customer ID
                                string updateQuery = "UPDATE TaiKhoan SET StripeCustomerId = @StripeCustomerId WHERE MaTaiKhoan = @MaTaiKhoan";
                                using (var updateCommand = new SqlCommand(updateQuery, connection))
                                {
                                    updateCommand.Parameters.AddWithValue("@StripeCustomerId", customerId);
                                    updateCommand.Parameters.AddWithValue("@MaTaiKhoan", userId);
                                    updateCommand.ExecuteNonQuery();
                                }
                            }
                            catch (Exception ex)
                            {
                                // Log lỗi nhưng vẫn trả về customerId
                                System.Diagnostics.Debug.WriteLine($"Warning: Could not create StripeCustomerId column: {ex.Message}");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Nếu có lỗi khi truy cập database, vẫn tạo Customer mới
                System.Diagnostics.Debug.WriteLine($"Warning: Error accessing database, creating new customer: {ex.Message}");
                if (string.IsNullOrEmpty(customerId))
                {
                    var customerService = new CustomerService();
                    var customerOptions = new CustomerCreateOptions
                    {
                        Metadata = new Dictionary<string, string>
                        {
                            { "userId", userId }
                        }
                    };
                    var customer = customerService.Create(customerOptions);
                    customerId = customer.Id;
                }
            }

            return customerId ?? throw new Exception("Failed to create or retrieve Stripe customer");
        }

        // PUT: api/Stripe/update-payment-intent
        [HttpPut("update-payment-intent")]
        public IActionResult UpdatePaymentIntent([FromBody] UpdatePaymentIntentRequest request)
        {
            try
            {
                var service = new PaymentIntentService();
                
                // Lấy PaymentIntent hiện tại để kiểm tra Customer
                var currentPaymentIntent = service.Get(request.PaymentIntentId);
                
                // Lấy PaymentMethod để biết Customer ID (nếu có)
                var paymentMethodService = new PaymentMethodService();
                var paymentMethod = paymentMethodService.Get(request.PaymentMethodId);
                
                var updateOptions = new PaymentIntentUpdateOptions
                {
                    PaymentMethod = request.PaymentMethodId
                };
                
                // ✅ QUAN TRỌNG: Nếu PaymentMethod đã được attach vào Customer, 
                // phải set Customer ID trong PaymentIntent
                if (paymentMethod.Customer != null)
                {
                    // Nếu PaymentIntent chưa có Customer, hoặc Customer khác với Customer của PaymentMethod,
                    // thì set Customer từ PaymentMethod
                    if (currentPaymentIntent.Customer == null || 
                        currentPaymentIntent.Customer.Id != paymentMethod.Customer.Id)
                    {
                        updateOptions.Customer = paymentMethod.Customer.Id;
                        System.Diagnostics.Debug.WriteLine($"✅ Updating PaymentIntent {request.PaymentIntentId} with PaymentMethod {request.PaymentMethodId} and Customer {paymentMethod.Customer.Id}");
                    }
                    else
                    {
                        // PaymentIntent đã có đúng Customer, không cần set lại
                        System.Diagnostics.Debug.WriteLine($"✅ PaymentIntent {request.PaymentIntentId} already has correct Customer {paymentMethod.Customer.Id}");
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine($"⚠️ PaymentMethod {request.PaymentMethodId} is not attached to a Customer");
                }

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
                System.Diagnostics.Debug.WriteLine($"❌ StripeException in UpdatePaymentIntent: {ex.Message}");
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Exception in UpdatePaymentIntent: {ex.Message}");
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

                    // ✅ Flow chuẩn: Attach PaymentMethod vào Customer để có thể dùng lại
                    string? customerId = null;
                    if (!string.IsNullOrEmpty(paymentMethodId) && !string.IsNullOrEmpty(request.UserId))
                    {
                        try
                        {
                            // Tạo hoặc lấy Customer cho user
                            customerId = GetOrCreateCustomer(request.UserId);
                            
                            // Attach PaymentMethod vào Customer
                            var paymentMethodService = new PaymentMethodService();
                            var paymentMethod = paymentMethodService.Get(paymentMethodId);
                            
                            // Chỉ attach nếu PaymentMethod chưa có Customer
                            if (paymentMethod.Customer == null)
                            {
                                var attachOptions = new PaymentMethodAttachOptions
                                {
                                    Customer = customerId
                                };
                                paymentMethodService.Attach(paymentMethodId, attachOptions);
                                System.Diagnostics.Debug.WriteLine($"✅ PaymentMethod {paymentMethodId} attached to Customer {customerId}");
                            }
                            else
                            {
                                System.Diagnostics.Debug.WriteLine($"ℹ️ PaymentMethod {paymentMethodId} already attached to Customer {paymentMethod.Customer.Id}");
                            }
                        }
                        catch (StripeException ex)
                        {
                            // Log lỗi nhưng vẫn trả về success vì thanh toán đã thành công
                            System.Diagnostics.Debug.WriteLine($"⚠️ Warning: Could not attach PaymentMethod to Customer: {ex.Message}");
                        }
                    }

                    return Ok(new
                    {
                        success = true,
                        message = "Thanh toán thành công",
                        paymentIntentId = paymentIntent.Id,
                        paymentMethodId = paymentMethodId,
                        customerId = customerId
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

                // ✅ QUAN TRỌNG: Attach PaymentMethod vào Customer ngay khi lưu thẻ
                // Điều này cho phép PaymentMethod được sử dụng lại nhiều lần
                string? customerId = null;
                try
                {
                    customerId = GetOrCreateCustomer(request.UserId);
                    
                    // Attach PaymentMethod vào Customer nếu chưa được attach
                    if (paymentMethod.Customer == null || paymentMethod.Customer.Id != customerId)
                    {
                        var attachOptions = new PaymentMethodAttachOptions
                        {
                            Customer = customerId
                        };
                        paymentMethodService.Attach(request.PaymentMethodId, attachOptions);
                        System.Diagnostics.Debug.WriteLine($"✅ PaymentMethod {request.PaymentMethodId} attached to Customer {customerId}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"ℹ️ PaymentMethod {request.PaymentMethodId} already attached to Customer {customerId}");
                    }
                }
                catch (StripeException ex)
                {
                    // Nếu không thể attach (ví dụ: PaymentMethod đã được sử dụng trước đó)
                    // Vẫn cho phép lưu thẻ, nhưng sẽ không thể dùng lại PaymentMethod này
                    System.Diagnostics.Debug.WriteLine($"⚠️ Warning: Could not attach PaymentMethod to Customer: {ex.Message}");
                    // Không throw error, vẫn tiếp tục lưu thông tin thẻ vào DB
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
        public string? UserId { get; set; }
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

    public class CreateCustomerRequest
    {
        public string UserId { get; set; } = string.Empty;
    }
}

