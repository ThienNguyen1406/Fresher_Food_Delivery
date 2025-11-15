using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Collections.Generic;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public OrdersController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/orders/monthly-revenue?year=2024
        [HttpGet("monthly-revenue")]
        public IActionResult GetMonthlyRevenue([FromQuery] int? year)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("✅ GetMonthlyRevenue endpoint called!");
                System.Diagnostics.Debug.WriteLine($"Year parameter: {year}");
                
                // Nếu không có year, lấy năm hiện tại
                if (!year.HasValue)
                {
                    year = DateTime.Now.Year;
                }
                
                System.Diagnostics.Debug.WriteLine($"Processing for year: {year.Value}");

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var monthlyRevenueDict = new Dictionary<int, decimal>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Query để lấy doanh thu theo từng tháng trong năm
                    string query = @"SELECT 
                                        MONTH(dh.NgayDat) as Thang,
                                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as DoanhThu
                                    FROM DonHang dh
                                    LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                                    WHERE YEAR(dh.NgayDat) = @Year
                                    GROUP BY MONTH(dh.NgayDat)
                                    ORDER BY MONTH(dh.NgayDat)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Year", year.Value);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var thang = Convert.ToInt32(reader["Thang"]);
                                var doanhThu = reader["DoanhThu"] != DBNull.Value
                                    ? Convert.ToDecimal(reader["DoanhThu"])
                                    : 0;
                                monthlyRevenueDict[thang] = doanhThu;
                            }
                        }
                    }
                }

                // Đảm bảo có đủ 12 tháng (nếu tháng nào không có dữ liệu thì trả về 0)
                var result = new List<object>();
                for (int month = 1; month <= 12; month++)
                {
                    result.Add(new
                    {
                        thang = month,
                        doanhThu = monthlyRevenueDict.ContainsKey(month) 
                            ? monthlyRevenueDict[month] 
                            : 0
                    });
                }

                return Ok(new 
                { 
                    message = "Lấy thống kê doanh thu theo tháng thành công", 
                    data = result,
                    year = year.Value
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in GetMonthlyRevenue: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack Trace: {ex.StackTrace}");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/orders/revenue/statistics?startDate=2024-01-01&endDate=2024-12-31
        [HttpGet("revenue/statistics")]
        public IActionResult GetRevenueStatistics([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Xây dựng query với điều kiện lọc theo ngày
                    // Sử dụng LEFT JOIN để vẫn tính được đơn hàng ngay cả khi chưa có chi tiết
                    string query = @"SELECT 
                                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as TongDoanhThu,
                                        COUNT(DISTINCT dh.MaDonHang) as TongDonHang,
                                        COUNT(DISTINCT dh.MaTaiKhoan) as TongKhachHang
                                    FROM DonHang dh
                                    LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                                    WHERE 1=1";

                    // Thêm điều kiện lọc theo ngày nếu có
                    if (startDate.HasValue)
                    {
                        query += " AND CAST(dh.NgayDat AS DATE) >= @StartDate";
                    }

                    if (endDate.HasValue)
                    {
                        query += " AND CAST(dh.NgayDat AS DATE) <= @EndDate";
                    }

                    using (var command = new SqlCommand(query, connection))
                    {
                        if (startDate.HasValue)
                        {
                            command.Parameters.AddWithValue("@StartDate", startDate.Value.Date);
                        }

                        if (endDate.HasValue)
                        {
                            command.Parameters.AddWithValue("@EndDate", endDate.Value.Date);
                        }

                        // Debug: Log query để kiểm tra
                        System.Diagnostics.Debug.WriteLine($"Revenue Statistics Query: {query}");
                        if (startDate.HasValue)
                            System.Diagnostics.Debug.WriteLine($"StartDate: {startDate.Value.Date}");
                        if (endDate.HasValue)
                            System.Diagnostics.Debug.WriteLine($"EndDate: {endDate.Value.Date}");

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                var tongDoanhThu = reader["TongDoanhThu"] != DBNull.Value 
                                    ? Convert.ToDecimal(reader["TongDoanhThu"]) 
                                    : 0;
                                var tongDonHang = reader["TongDonHang"] != DBNull.Value 
                                    ? Convert.ToInt32(reader["TongDonHang"]) 
                                    : 0;
                                var tongKhachHang = reader["TongKhachHang"] != DBNull.Value 
                                    ? Convert.ToInt32(reader["TongKhachHang"]) 
                                    : 0;

                                var statistics = new
                                {
                                    tongDoanhThu = tongDoanhThu,
                                    tongDonHang = tongDonHang,
                                    tongKhachHang = tongKhachHang,
                                    startDate = startDate?.ToString("yyyy-MM-dd"),
                                    endDate = endDate?.ToString("yyyy-MM-dd")
                                };

                                System.Diagnostics.Debug.WriteLine($"Revenue Statistics Result: DoanhThu={tongDoanhThu}, DonHang={tongDonHang}, KhachHang={tongKhachHang}");

                                return Ok(new { message = "Lấy thống kê doanh thu thành công", data = statistics });
                            }
                        }
                    }
                }

                return Ok(new { 
                    message = "Lấy thống kê doanh thu thành công", 
                    data = new { 
                        tongDoanhThu = 0, 
                        tongDonHang = 0, 
                        tongKhachHang = 0,
                        startDate = startDate?.ToString("yyyy-MM-dd"),
                        endDate = endDate?.ToString("yyyy-MM-dd")
                    } 
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in GetRevenueStatistics: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack Trace: {ex.StackTrace}");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/orders
        [HttpGet]
        public IActionResult GetAllOrders()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var orders = new List<Order>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaDonHang, MaTaiKhoan, NgayDat, TrangThai, 
                                    DiaChiGiaoHang, SoDienThoai, GhiChu, PhuongThucThanhToan, TrangThaiThanhToan, id_phieugiamgia, id_Pay 
                                    FROM DonHang ORDER BY NgayDat DESC";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            orders.Add(new Order
                            {
                                MaDonHang = reader["MaDonHang"].ToString(),
                                MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                NgayDat = Convert.ToDateTime(reader["NgayDat"]),
                                TrangThai = reader["TrangThai"].ToString(),
                                DiaChiGiaoHang = reader["DiaChiGiaoHang"] as string,
                                SoDienThoai = reader["SoDienThoai"] as string,
                                GhiChu = reader["GhiChu"] as string,
                                PhuongThucThanhToan = reader["PhuongThucThanhToan"] as string,
                                TrangThaiThanhToan = reader["TrangThaiThanhToan"].ToString(),
                                id_phieugiamgia = reader["id_phieugiamgia"] as string,
                                id_Pay = reader["id_Pay"] as string
                            });
                        }
                    }
                }

                return Ok(new { message = "Lấy danh sách đơn hàng thành công", data = orders });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/orders/{maDonHang}
        [HttpGet("{maDonHang}")]
        public IActionResult GetOrderById(string maDonHang)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Order order = null;
                var orderDetails = new List<OrderDetail>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Lấy thông tin đơn hàng
                    string orderQuery = @"SELECT MaDonHang, MaTaiKhoan, NgayDat, TrangThai, 
                                        DiaChiGiaoHang, SoDienThoai, GhiChu, PhuongThucThanhToan, 
                                        TrangThaiThanhToan, id_phieugiamgia, id_Pay 
                                        FROM DonHang WHERE MaDonHang = @MaDonHang";

                    using (var command = new SqlCommand(orderQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaDonHang", maDonHang);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                order = new Order
                                {
                                    MaDonHang = reader["MaDonHang"].ToString(),
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                    NgayDat = Convert.ToDateTime(reader["NgayDat"]),
                                    TrangThai = reader["TrangThai"].ToString(),
                                    DiaChiGiaoHang = reader["DiaChiGiaoHang"] as string,
                                    SoDienThoai = reader["SoDienThoai"] as string,
                                    GhiChu = reader["GhiChu"] as string,
                                    PhuongThucThanhToan = reader["PhuongThucThanhToan"] as string,
                                    TrangThaiThanhToan = reader["TrangThaiThanhToan"].ToString(),
                                    id_phieugiamgia = reader["id_phieugiamgia"] as string,
                                    id_Pay = reader["id_Pay"] as string
                                };
                            }
                        }
                    }

                    if (order == null)
                    {
                        return NotFound(new { error = "Không tìm thấy đơn hàng" });
                    }

                    // Lấy chi tiết đơn hàng
                    string detailsQuery = @"SELECT od.MaDonHang, od.MaSanPham, p.TenSanPham, od.GiaBan, od.SoLuong
                                           FROM ChiTietDonHang od
                                           LEFT JOIN SanPham p ON od.MaSanPham = p.MaSanPham
                                           WHERE od.MaDonHang = @MaDonHang";

                    using (var command = new SqlCommand(detailsQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaDonHang", maDonHang);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                orderDetails.Add(new OrderDetail
                                {
                                    MaDonHang = reader["MaDonHang"].ToString(),
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    TenSanPham = reader["TenSanPham"] as string,
                                    GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                                    SoLuong = Convert.ToInt32(reader["SoLuong"])
                                });
                            }
                        }
                    }
                }

                return Ok(new
                {
                    message = "Lấy thông tin đơn hàng thành công",
                    data = new { order, orderDetails }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/orders
        [HttpPost]
        public IActionResult CreateOrder([FromBody] OrderRequest request)
        {
            try
            {
                if (request?.Order == null || request.OrderDetails == null || !request.OrderDetails.Any())
                {
                    return BadRequest(new { error = "Dữ liệu đơn hàng không hợp lệ" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    using (var transaction = connection.BeginTransaction())
                    {
                        try
                        {
                            // KIỂM TRA TỒN KHO TRƯỚC KHI TẠO ĐƠN HÀNG
                            foreach (var detail in request.OrderDetails)
                            {
                                if (!KiemTraTonKho(detail.MaSanPham, detail.SoLuong, connection, transaction))
                                {
                                    transaction.Rollback();
                                    return BadRequest(new { error = $"Sản phẩm {detail.MaSanPham} không đủ số lượng tồn kho" });
                                }
                            }

                            // XỬ LÝ LINH HOẠT CHO TRƯỜNG id_phieugiamgia CÓ THỂ NULL
                            string orderQuery;
                            SqlCommand command;

                            // Nếu không có phiếu giảm giá, không chèn vào cột id_phieugiamgia
                            if (string.IsNullOrEmpty(request.Order.id_phieugiamgia))
                            {
                                orderQuery = @"INSERT INTO DonHang (MaTaiKhoan, NgayDat, TrangThai, 
                                            DiaChiGiaoHang, SoDienThoai, GhiChu, PhuongThucThanhToan, 
                                            TrangThaiThanhToan, id_Pay)
                                            OUTPUT INSERTED.MaDonHang
                                            VALUES (@MaTaiKhoan, @NgayDat, @TrangThai, 
                                            @DiaChiGiaoHang, @SoDienThoai, @GhiChu, @PhuongThucThanhToan, 
                                            @TrangThaiThanhToan, @id_Pay)";

                                command = new SqlCommand(orderQuery, connection, transaction);
                            }
                            else
                            {
                                // Nếu có phiếu giảm giá, chèn cả id_phieugiamgia
                                orderQuery = @"INSERT INTO DonHang (MaTaiKhoan, NgayDat, TrangThai, 
                                            DiaChiGiaoHang, SoDienThoai, GhiChu, PhuongThucThanhToan, 
                                            TrangThaiThanhToan, id_phieugiamgia, id_Pay)
                                            OUTPUT INSERTED.MaDonHang
                                            VALUES (@MaTaiKhoan, @NgayDat, @TrangThai, 
                                            @DiaChiGiaoHang, @SoDienThoai, @GhiChu, @PhuongThucThanhToan, 
                                            @TrangThaiThanhToan, @id_phieugiamgia, @id_Pay)";

                                command = new SqlCommand(orderQuery, connection, transaction);
                                command.Parameters.AddWithValue("@id_phieugiamgia", request.Order.id_phieugiamgia);
                            }

                            // THÊM CÁC THAM SỐ CHUNG
                            command.Parameters.AddWithValue("@MaTaiKhoan", request.Order.MaTaiKhoan);
                            command.Parameters.AddWithValue("@NgayDat", request.Order.NgayDat);
                            command.Parameters.AddWithValue("@TrangThai", request.Order.TrangThai);
                            command.Parameters.AddWithValue("@DiaChiGiaoHang", (object?)request.Order.DiaChiGiaoHang ?? DBNull.Value);
                            command.Parameters.AddWithValue("@SoDienThoai", (object?)request.Order.SoDienThoai ?? DBNull.Value);
                            command.Parameters.AddWithValue("@GhiChu", (object?)request.Order.GhiChu ?? DBNull.Value);
                            command.Parameters.AddWithValue("@PhuongThucThanhToan", (object?)request.Order.PhuongThucThanhToan ?? DBNull.Value);
                            command.Parameters.AddWithValue("@TrangThaiThanhToan", request.Order.TrangThaiThanhToan);
                            command.Parameters.AddWithValue("@id_Pay", (object?)request.Order.id_Pay ?? DBNull.Value);

                            // Lấy mã đơn hàng vừa được tạo
                            string maDonHang = command.ExecuteScalar()?.ToString();

                            if (string.IsNullOrEmpty(maDonHang))
                            {
                                transaction.Rollback();
                                return StatusCode(500, new { error = "Không thể tạo mã đơn hàng" });
                            }

                            // Thêm chi tiết đơn hàng
                            foreach (var detail in request.OrderDetails)
                            {
                                string detailQuery = @"INSERT INTO ChiTietDonHang (MaDonHang, MaSanPham, GiaBan, SoLuong)
                                                     VALUES (@MaDonHang, @MaSanPham, @GiaBan, @SoLuong)";

                                using (var detailCommand = new SqlCommand(detailQuery, connection, transaction))
                                {
                                    detailCommand.Parameters.AddWithValue("@MaDonHang", maDonHang);
                                    detailCommand.Parameters.AddWithValue("@MaSanPham", detail.MaSanPham);
                                    detailCommand.Parameters.AddWithValue("@GiaBan", detail.GiaBan);
                                    detailCommand.Parameters.AddWithValue("@SoLuong", detail.SoLuong);

                                    detailCommand.ExecuteNonQuery();
                                }

                                // GIẢM SỐ LƯỢNG TỒN KHO
                                GiamSoLuongTon(detail.MaSanPham, detail.SoLuong, connection, transaction);
                            }

                            transaction.Commit();

                            // Cập nhật mã đơn hàng cho response
                            request.Order.MaDonHang = maDonHang;
                            foreach (var detail in request.OrderDetails)
                            {
                                detail.MaDonHang = maDonHang;
                            }

                            return Ok(new
                            {
                                message = "Tạo đơn hàng thành công",
                                data = new { order = request.Order, orderDetails = request.OrderDetails }
                            });
                        }
                        catch (Exception ex)
                        {
                            transaction.Rollback();
                            return StatusCode(500, new { error = $"Lỗi khi tạo đơn hàng: {ex.Message}" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/orders/{maDonHang}/status
        [HttpPut("{maDonHang}/status")]
        public IActionResult UpdateOrderStatus(string maDonHang, [FromBody] StatusUpdateRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request?.TrangThai))
                {
                    return BadRequest(new { error = "Trạng thái không hợp lệ" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "UPDATE DonHang SET TrangThai = @TrangThai WHERE MaDonHang = @MaDonHang";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDonHang", maDonHang);
                        command.Parameters.AddWithValue("@TrangThai", request.TrangThai);

                        int rowsAffected = command.ExecuteNonQuery();

                        if (rowsAffected > 0)
                        {
                            return Ok(new { message = "Cập nhật trạng thái đơn hàng thành công", trangThai = request.TrangThai });
                        }
                        else
                        {
                            return NotFound(new { error = "Không tìm thấy đơn hàng" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/orders/{maDonHang}/payment-status
        [HttpPut("{maDonHang}/payment-status")]
        public IActionResult UpdatePaymentStatus(string maDonHang, [FromBody] PaymentStatusUpdateRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request?.TrangThaiThanhToan))
                {
                    return BadRequest(new { error = "Trạng thái thanh toán không hợp lệ" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "UPDATE DonHang SET TrangThaiThanhToan = @TrangThaiThanhToan WHERE MaDonHang = @MaDonHang";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDonHang", maDonHang);
                        command.Parameters.AddWithValue("@TrangThaiThanhToan", request.TrangThaiThanhToan);

                        int rowsAffected = command.ExecuteNonQuery();

                        if (rowsAffected > 0)
                        {
                            return Ok(new { message = "Cập nhật trạng thái thanh toán thành công", trangThaiThanhToan = request.TrangThaiThanhToan });
                        }
                        else
                        {
                            return NotFound(new { error = "Không tìm thấy đơn hàng" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/orders/user/{maTaiKhoan}
        [HttpGet("user/{maTaiKhoan}")]
        public IActionResult GetOrdersByUser(string maTaiKhoan)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var orders = new List<Order>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaDonHang, MaTaiKhoan, NgayDat, TrangThai, 
                                    DiaChiGiaoHang, SoDienThoai, GhiChu, PhuongThucThanhToan, 
                                    TrangThaiThanhToan, id_phieugiamgia, id_Pay 
                                    FROM DonHang WHERE MaTaiKhoan = @MaTaiKhoan 
                                    ORDER BY NgayDat DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                orders.Add(new Order
                                {
                                    MaDonHang = reader["MaDonHang"].ToString(),
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                    NgayDat = Convert.ToDateTime(reader["NgayDat"]),
                                    TrangThai = reader["TrangThai"].ToString(),
                                    DiaChiGiaoHang = reader["DiaChiGiaoHang"] as string,
                                    SoDienThoai = reader["SoDienThoai"] as string,
                                    GhiChu = reader["GhiChu"] as string,
                                    PhuongThucThanhToan = reader["PhuongThucThanhToan"] as string,
                                    TrangThaiThanhToan = reader["TrangThaiThanhToan"].ToString(),
                                    id_phieugiamgia = reader["id_phieugiamgia"] as string,
                                    id_Pay = reader["id_Pay"] as string
                                });
                            }
                        }
                    }
                }

                return Ok(new { message = "Lấy danh sách đơn hàng của người dùng thành công", data = orders });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }


        #region Helper Methods

        /// <summary>
        /// Kiểm tra số lượng tồn kho
        /// </summary>
        private bool KiemTraTonKho(string maSanPham, int soLuong, SqlConnection connection, SqlTransaction transaction)
        {
            string query = "SELECT SoLuongTon FROM SanPham WHERE MaSanPham = @MaSanPham";

            using (var command = new SqlCommand(query, connection, transaction))
            {
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                var result = command.ExecuteScalar();

                if (result == null)
                {
                    throw new Exception($"Không tìm thấy sản phẩm với mã: {maSanPham}");
                }

                int soLuongTon = Convert.ToInt32(result);
                return soLuongTon >= soLuong;
            }
        }

        /// <summary>
        /// Giảm số lượng tồn kho
        /// </summary>
        private void GiamSoLuongTon(string maSanPham, int soLuong, SqlConnection connection, SqlTransaction transaction)
        {
            string query = @"UPDATE SanPham 
                            SET SoLuongTon = SoLuongTon - @SoLuong 
                            WHERE MaSanPham = @MaSanPham AND SoLuongTon >= @SoLuong";

            using (var command = new SqlCommand(query, connection, transaction))
            {
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                command.Parameters.AddWithValue("@SoLuong", soLuong);

                int rowsAffected = command.ExecuteNonQuery();

                if (rowsAffected == 0)
                {
                    throw new Exception($"Không thể cập nhật tồn kho cho sản phẩm {maSanPham}. Số lượng tồn kho không đủ.");
                }
            }
        }

        #endregion
    }

    // Model cho request tạo đơn hàng
    public class OrderRequest
    {
        public Order Order { get; set; }
        public List<OrderDetail> OrderDetails { get; set; }
    }

    // Model cho request cập nhật trạng thái
    public class StatusUpdateRequest
    {
        public string TrangThai { get; set; }
    }

    // Model cho request cập nhật trạng thái thanh toán
    public class PaymentStatusUpdateRequest
    {
        public string TrangThaiThanhToan { get; set; }
    }
}