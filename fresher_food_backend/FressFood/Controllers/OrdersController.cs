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
                    // CHỈ tính đơn hàng đã hoàn thành (complete)
                    string query = @"SELECT 
                                        MONTH(dh.NgayDat) as Thang,
                                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as DoanhThu
                                    FROM DonHang dh
                                    LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                                    WHERE YEAR(dh.NgayDat) = @Year
                                        AND (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng')
                                             OR dh.TrangThai LIKE '%complete%'
                                             OR dh.TrangThai LIKE '%Complete%')
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
                    // CHỈ tính đơn hàng đã hoàn thành (complete) cho doanh thu
                    // Sử dụng LEFT JOIN để vẫn tính được đơn hàng ngay cả khi chưa có chi tiết
                    string baseCondition = "";
                    if (startDate.HasValue)
                    {
                        baseCondition += " AND CAST(dh.NgayDat AS DATE) >= @StartDate";
                    }
                    if (endDate.HasValue)
                    {
                        baseCondition += " AND CAST(dh.NgayDat AS DATE) <= @EndDate";
                    }

                    // Query cho doanh thu (chỉ đơn hoàn thành)
                    string revenueQuery = @"SELECT 
                                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as TongDoanhThu,
                                        COUNT(DISTINCT dh.MaDonHang) as TongDonHang,
                                        COUNT(DISTINCT dh.MaTaiKhoan) as TongKhachHang
                                    FROM DonHang dh
                                    LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                                    WHERE (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng')
                                           OR dh.TrangThai LIKE '%complete%'
                                           OR dh.TrangThai LIKE '%Complete%')" + baseCondition;

                    // Query cho số đơn thành công và bị hủy
                    string statusQuery = @"SELECT 
                                        SUM(CASE WHEN (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng')
                                                      OR dh.TrangThai LIKE '%complete%'
                                                      OR dh.TrangThai LIKE '%Complete%') THEN 1 ELSE 0 END) as DonThanhCong,
                                        SUM(CASE WHEN (dh.TrangThai LIKE N'%hủy%' 
                                                      OR dh.TrangThai LIKE N'%Hủy%'
                                                      OR dh.TrangThai LIKE '%cancel%'
                                                      OR dh.TrangThai LIKE '%Cancel%'
                                                      OR dh.TrangThai LIKE '%cancelled%'
                                                      OR dh.TrangThai LIKE '%Cancelled%') THEN 1 ELSE 0 END) as DonBiHuy
                                    FROM DonHang dh
                                    WHERE 1=1" + baseCondition;

                    decimal tongDoanhThu = 0;
                    int tongDonHang = 0;
                    int tongKhachHang = 0;
                    int donThanhCong = 0;
                    int donBiHuy = 0;

                    using (var command = new SqlCommand(revenueQuery, connection))
                    {
                        if (startDate.HasValue)
                        {
                            command.Parameters.AddWithValue("@StartDate", startDate.Value.Date);
                        }
                        if (endDate.HasValue)
                        {
                            command.Parameters.AddWithValue("@EndDate", endDate.Value.Date);
                        }

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                tongDoanhThu = reader["TongDoanhThu"] != DBNull.Value 
                                    ? Convert.ToDecimal(reader["TongDoanhThu"]) 
                                    : 0;
                                tongDonHang = reader["TongDonHang"] != DBNull.Value 
                                    ? Convert.ToInt32(reader["TongDonHang"]) 
                                    : 0;
                                tongKhachHang = reader["TongKhachHang"] != DBNull.Value 
                                    ? Convert.ToInt32(reader["TongKhachHang"]) 
                                    : 0;
                            }
                        }
                    }

                    // Lấy số đơn thành công và bị hủy
                    using (var command = new SqlCommand(statusQuery, connection))
                    {
                        if (startDate.HasValue)
                        {
                            command.Parameters.AddWithValue("@StartDate", startDate.Value.Date);
                        }
                        if (endDate.HasValue)
                        {
                            command.Parameters.AddWithValue("@EndDate", endDate.Value.Date);
                        }

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                donThanhCong = reader["DonThanhCong"] != DBNull.Value 
                                    ? Convert.ToInt32(reader["DonThanhCong"]) 
                                    : 0;
                                donBiHuy = reader["DonBiHuy"] != DBNull.Value 
                                    ? Convert.ToInt32(reader["DonBiHuy"]) 
                                    : 0;
                            }
                        }
                    }

                    var statistics = new
                    {
                        tongDoanhThu = tongDoanhThu,
                        tongDonHang = tongDonHang,
                        tongKhachHang = tongKhachHang,
                        donThanhCong = donThanhCong,
                        donBiHuy = donBiHuy,
                        startDate = startDate?.ToString("yyyy-MM-dd"),
                        endDate = endDate?.ToString("yyyy-MM-dd")
                    };

                    System.Diagnostics.Debug.WriteLine($"Revenue Statistics Result: DoanhThu={tongDoanhThu}, DonHang={tongDonHang}, KhachHang={tongKhachHang}, ThanhCong={donThanhCong}, BiHuy={donBiHuy}");

                    return Ok(new { message = "Lấy thống kê doanh thu thành công", data = statistics });
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

        // GET: api/orders/status-distribution?startDate=2025-01-01&endDate=2025-12-31
        // Lấy tỉ lệ phân bố trạng thái đơn hàng (cho pie chart)
        [HttpGet("status-distribution")]
        public IActionResult GetOrderStatusDistribution([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                
                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string baseCondition = "";
                    if (startDate.HasValue)
                    {
                        baseCondition += " AND CAST(dh.NgayDat AS DATE) >= @StartDate";
                    }
                    if (endDate.HasValue)
                    {
                        baseCondition += " AND CAST(dh.NgayDat AS DATE) <= @EndDate";
                    }

                    // Query để đếm số đơn hàng theo từng trạng thái
                    string query = @"SELECT 
                                        dh.TrangThai,
                                        COUNT(*) as SoLuong
                                    FROM DonHang dh
                                    WHERE 1=1" + baseCondition + @"
                                    GROUP BY dh.TrangThai
                                    ORDER BY COUNT(*) DESC";

                    var statusList = new List<object>();

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

                        using (var reader = command.ExecuteReader())
                        {
                            int totalOrders = 0;
                            var tempStatusList = new List<(string Status, int Count)>();

                            while (reader.Read())
                            {
                                var trangThai = reader["TrangThai"].ToString();
                                var soLuong = Convert.ToInt32(reader["SoLuong"]);
                                totalOrders += soLuong;
                                tempStatusList.Add((trangThai, soLuong));
                            }

                            // Phân loại trạng thái thành các nhóm
                            foreach (var item in tempStatusList)
                            {
                                string category = "";
                                if (item.Status.Contains("chờ") || item.Status.Contains("Chờ") || 
                                    item.Status.Contains("pending") || item.Status.Contains("Pending"))
                                {
                                    category = "Đang chờ xác nhận";
                                }
                                else if (item.Status.Contains("xử") || item.Status.Contains("Xử") || 
                                         item.Status.Contains("processing") || item.Status.Contains("Processing"))
                                {
                                    category = "Đang xử lí";
                                }
                                else if (item.Status.Contains("giao") || item.Status.Contains("Giao") || 
                                         item.Status.Contains("delivering") || item.Status.Contains("Delivering"))
                                {
                                    category = "Đang giao";
                                }
                                else if (item.Status.Contains("Hoàn thành") || item.Status.Contains("Đã giao hàng") || 
                                         item.Status.Contains("complete") || item.Status.Contains("Complete"))
                                {
                                    category = "Đã hoàn thành";
                                }
                                else if (item.Status.Contains("hủy") || item.Status.Contains("Hủy") || 
                                         item.Status.Contains("cancel") || item.Status.Contains("Cancel"))
                                {
                                    category = "Bị hủy";
                                }
                                else
                                {
                                    category = item.Status; // Giữ nguyên nếu không khớp
                                }

                                var existing = statusList.FirstOrDefault(s => 
                                    (s as dynamic).category == category) as dynamic;
                                
                                if (existing != null)
                                {
                                    existing.count += item.Count;
                                }
                                else
                                {
                                    statusList.Add(new
                                    {
                                        category = category,
                                        count = item.Count,
                                        percentage = totalOrders > 0 ? Math.Round((double)item.Count / totalOrders * 100, 2) : 0
                                    });
                                }
                            }

                            // Tính lại phần trăm sau khi gộp
                            foreach (dynamic item in statusList)
                            {
                                item.percentage = totalOrders > 0 ? Math.Round((double)item.count / totalOrders * 100, 2) : 0;
                            }
                        }
                    }

                    return Ok(new { 
                        message = "Lấy phân bố trạng thái đơn hàng thành công", 
                        data = statusList 
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in GetOrderStatusDistribution: {ex.Message}");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/orders/monthly-growth?year=2025
        // Lấy tăng trưởng đơn hàng theo tháng (cho line chart)
        [HttpGet("monthly-growth")]
        public IActionResult GetMonthlyOrderGrowth([FromQuery] int? year)
        {
            try
            {
                if (!year.HasValue)
                {
                    year = DateTime.Now.Year;
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var monthlyGrowth = new Dictionary<int, int>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Query để đếm số đơn hàng theo từng tháng
                    string query = @"SELECT 
                                        MONTH(dh.NgayDat) as Thang,
                                        COUNT(*) as SoDonHang
                                    FROM DonHang dh
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
                                var soDonHang = Convert.ToInt32(reader["SoDonHang"]);
                                monthlyGrowth[thang] = soDonHang;
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
                        soDonHang = monthlyGrowth.ContainsKey(month) ? monthlyGrowth[month] : 0
                    });
                }

                return Ok(new 
                { 
                    message = "Lấy tăng trưởng đơn hàng theo tháng thành công", 
                    data = result,
                    year = year.Value
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in GetMonthlyOrderGrowth: {ex.Message}");
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

                            // KIỂM TRA VÀ XỬ LÝ VOUCHER NẾU CÓ
                            if (!string.IsNullOrEmpty(request.Order.id_phieugiamgia))
                            {
                                // Kiểm tra voucher có tồn tại và còn sử dụng được không
                                string checkVoucherQuery = @"SELECT SoLuongToiDa, ISNULL(SoLuongDaSuDung, 0) as SoLuongDaSuDung 
                                                              FROM PhieuGiamGia 
                                                              WHERE Id_phieugiamgia = @Id_phieugiamgia";
                                using (var checkVoucherCommand = new SqlCommand(checkVoucherQuery, connection, transaction))
                                {
                                    checkVoucherCommand.Parameters.AddWithValue("@Id_phieugiamgia", request.Order.id_phieugiamgia);
                                    using (var voucherReader = checkVoucherCommand.ExecuteReader())
                                    {
                                        if (!voucherReader.Read())
                                        {
                                            transaction.Rollback();
                                            return BadRequest(new { error = "Mã giảm giá không tồn tại" });
                                        }

                                        int? soLuongToiDa = voucherReader["SoLuongToiDa"] != DBNull.Value ? (int?)Convert.ToInt32(voucherReader["SoLuongToiDa"]) : null;
                                        int soLuongDaSuDung = voucherReader["SoLuongDaSuDung"] != DBNull.Value ? Convert.ToInt32(voucherReader["SoLuongDaSuDung"]) : 0;

                                        // Kiểm tra xem voucher còn sử dụng được không
                                        if (soLuongToiDa.HasValue && soLuongDaSuDung >= soLuongToiDa.Value)
                                        {
                                            transaction.Rollback();
                                            return BadRequest(new { error = "Mã giảm giá đã hết lượt sử dụng" });
                                        }
                                    }
                                }

                                // Kiểm tra xem user đã sử dụng voucher này chưa
                                string checkUserUsedQuery = @"SELECT COUNT(*) FROM LichSuSuDungVoucher 
                                                               WHERE MaTaiKhoan = @MaTaiKhoan 
                                                                 AND Id_phieugiamgia = @Id_phieugiamgia";
                                using (var checkUserCommand = new SqlCommand(checkUserUsedQuery, connection, transaction))
                                {
                                    // Convert MaTaiKhoan sang INT nếu cần
                                    if (int.TryParse(request.Order.MaTaiKhoan, out int maTaiKhoanInt))
                                    {
                                        checkUserCommand.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoanInt);
                                    }
                                    else
                                    {
                                        checkUserCommand.Parameters.AddWithValue("@MaTaiKhoan", request.Order.MaTaiKhoan);
                                    }
                                    checkUserCommand.Parameters.AddWithValue("@Id_phieugiamgia", request.Order.id_phieugiamgia);
                                    int userUsedCount = Convert.ToInt32(checkUserCommand.ExecuteScalar());
                                    
                                    if (userUsedCount > 0)
                                    {
                                        transaction.Rollback();
                                        return BadRequest(new { error = "Bạn đã sử dụng mã giảm giá này rồi" });
                                    }
                                }

                                // Tăng số lượng đã sử dụng
                                string updateVoucherQuery = @"UPDATE PhieuGiamGia 
                                                              SET SoLuongDaSuDung = ISNULL(SoLuongDaSuDung, 0) + 1 
                                                              WHERE Id_phieugiamgia = @Id_phieugiamgia";
                                using (var updateVoucherCommand = new SqlCommand(updateVoucherQuery, connection, transaction))
                                {
                                    updateVoucherCommand.Parameters.AddWithValue("@Id_phieugiamgia", request.Order.id_phieugiamgia);
                                    updateVoucherCommand.ExecuteNonQuery();
                                }

                                // Kiểm tra xem voucher đã hết chưa, nếu hết thì xóa
                                string checkVoucherExhaustedQuery = @"SELECT SoLuongToiDa, ISNULL(SoLuongDaSuDung, 0) as SoLuongDaSuDung 
                                                                      FROM PhieuGiamGia 
                                                                      WHERE Id_phieugiamgia = @Id_phieugiamgia";
                                using (var checkExhaustedCommand = new SqlCommand(checkVoucherExhaustedQuery, connection, transaction))
                                {
                                    checkExhaustedCommand.Parameters.AddWithValue("@Id_phieugiamgia", request.Order.id_phieugiamgia);
                                    using (var exhaustedReader = checkExhaustedCommand.ExecuteReader())
                                    {
                                        if (exhaustedReader.Read())
                                        {
                                            int? soLuongToiDa = exhaustedReader["SoLuongToiDa"] != DBNull.Value ? (int?)Convert.ToInt32(exhaustedReader["SoLuongToiDa"]) : null;
                                            int soLuongDaSuDung = exhaustedReader["SoLuongDaSuDung"] != DBNull.Value ? Convert.ToInt32(exhaustedReader["SoLuongDaSuDung"]) : 0;

                                            // Nếu voucher đã hết (SoLuongDaSuDung >= SoLuongToiDa), xóa voucher
                                            if (soLuongToiDa.HasValue && soLuongDaSuDung >= soLuongToiDa.Value)
                                            {
                                                string deleteVoucherQuery = "DELETE FROM PhieuGiamGia WHERE Id_phieugiamgia = @Id_phieugiamgia";
                                                using (var deleteVoucherCommand = new SqlCommand(deleteVoucherQuery, connection, transaction))
                                                {
                                                    deleteVoucherCommand.Parameters.AddWithValue("@Id_phieugiamgia", request.Order.id_phieugiamgia);
                                                    deleteVoucherCommand.ExecuteNonQuery();
                                                }
                                            }
                                        }
                                    }
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

                            // Lưu lịch sử sử dụng voucher nếu có
                            if (!string.IsNullOrEmpty(request.Order.id_phieugiamgia))
                            {
                                try
                                {
                                    string insertHistoryQuery = @"INSERT INTO LichSuSuDungVoucher (MaTaiKhoan, Id_phieugiamgia, MaDonHang, NgaySuDung)
                                                                  VALUES (@MaTaiKhoan, @Id_phieugiamgia, @MaDonHang, GETDATE())";
                                    using (var historyCommand = new SqlCommand(insertHistoryQuery, connection, transaction))
                                    {
                                        // Convert MaTaiKhoan sang INT nếu cần (vì có thể là string trong model nhưng INT trong DB)
                                        if (int.TryParse(request.Order.MaTaiKhoan, out int maTaiKhoanInt))
                                        {
                                            historyCommand.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoanInt);
                                        }
                                        else
                                        {
                                            // Nếu không parse được, thử dùng trực tiếp (có thể là NVARCHAR)
                                            historyCommand.Parameters.AddWithValue("@MaTaiKhoan", request.Order.MaTaiKhoan);
                                        }
                                        historyCommand.Parameters.AddWithValue("@Id_phieugiamgia", request.Order.id_phieugiamgia);
                                        historyCommand.Parameters.AddWithValue("@MaDonHang", maDonHang);
                                        historyCommand.ExecuteNonQuery();
                                    }
                                }
                                catch (Exception historyEx)
                                {
                                    // Log lỗi nhưng không rollback transaction
                                    Console.WriteLine($"Warning: Could not save voucher usage history: {historyEx.Message}");
                                }
                            }

                            transaction.Commit();

                            // Tạo thông báo cho admin về đơn hàng mới
                            try
                            {
                                TaoThongBaoDonHangMoi(maDonHang, request.Order.MaTaiKhoan, connectionString);
                            }
                            catch (Exception notifEx)
                            {
                                // Log lỗi nhưng không ảnh hưởng đến việc tạo đơn hàng
                                System.Diagnostics.Debug.WriteLine($"Lỗi khi tạo thông báo: {notifEx.Message}");
                            }

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


        // GET: api/orders/completed-products/{maTaiKhoan}
        // Lấy danh sách sản phẩm từ đơn hàng đã hoàn thành để đánh giá
        [HttpGet("completed-products/{maTaiKhoan}")]
        public IActionResult GetCompletedOrderProducts(string maTaiKhoan)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var products = new List<object>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    // Lấy danh sách sản phẩm từ đơn hàng đã hoàn thành
                    // Loại bỏ trùng lặp và chỉ lấy sản phẩm chưa được đánh giá
                    // Hỗ trợ nhiều format trạng thái: 'Hoàn thành', 'Đã giao hàng', 'Complete', 'completed', etc.
                    string query = @"SELECT DISTINCT 
                                    sp.MaSanPham,
                                    sp.TenSanPham,
                                    sp.Anh,
                                    sp.GiaBan,
                                    sp.DonViTinh,
                                    sp.XuatXu
                                FROM ChiTietDonHang ctdh
                                INNER JOIN DonHang dh ON ctdh.MaDonHang = dh.MaDonHang
                                INNER JOIN SanPham sp ON ctdh.MaSanPham = sp.MaSanPham
                                LEFT JOIN DanhGia dg ON sp.MaSanPham = dg.MaSanPham AND dg.MaTaiKhoan = @MaTaiKhoan
                                WHERE dh.MaTaiKhoan = @MaTaiKhoan
                                    AND (sp.IsDeleted = 0 OR sp.IsDeleted IS NULL)
                                    AND (
                                        dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng')
                                        OR dh.TrangThai LIKE '%complete%'
                                        OR dh.TrangThai LIKE '%Complete%'
                                        OR dh.TrangThai LIKE '%hoàn thành%'
                                        OR dh.TrangThai LIKE '%giao hàng%'
                                    )
                                    AND dg.MaSanPham IS NULL  -- Chưa đánh giá
                                ORDER BY sp.TenSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var fileName = reader["Anh"]?.ToString();
                                var product = new
                                {
                                    maSanPham = reader["MaSanPham"].ToString(),
                                    tenSanPham = reader["TenSanPham"].ToString(),
                                    anh = string.IsNullOrEmpty(fileName) ? null :
                                          $"{Request.Scheme}://{Request.Host}/images/products/{fileName}",
                                    giaBan = Convert.ToDecimal(reader["GiaBan"]),
                                    donViTinh = reader["DonViTinh"]?.ToString(),
                                    xuatXu = reader["XuatXu"]?.ToString()
                                };
                                products.Add(product);
                            }
                        }
                    }
                }

                return Ok(new
                {
                    message = "Lấy danh sách sản phẩm từ đơn hàng đã hoàn thành thành công",
                    data = products
                });
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
            string query = "SELECT SoLuongTon FROM SanPham WHERE MaSanPham = @MaSanPham AND (IsDeleted = 0 OR IsDeleted IS NULL)";

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

        /// <summary>
        /// Tạo thông báo cho tất cả admin về đơn hàng mới
        /// </summary>
        private void TaoThongBaoDonHangMoi(string maDonHang, string maTaiKhoan, string connectionString)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                // Lấy thông tin khách hàng
                string customerName = "";
                string customerQuery = "SELECT HoTen, TenNguoiDung FROM NguoiDung WHERE MaTaiKhoan = @MaTaiKhoan";
                using (var customerCmd = new SqlCommand(customerQuery, connection))
                {
                    customerCmd.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                    using (var reader = customerCmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            customerName = reader["HoTen"]?.ToString() ?? reader["TenNguoiDung"]?.ToString() ?? "Khách hàng";
                        }
                    }
                }

                // Lấy danh sách tất cả admin
                var adminList = new List<string>();
                string adminQuery = "SELECT MaTaiKhoan FROM NguoiDung WHERE VaiTro = N'Admin' OR VaiTro = 'Admin'";
                using (var adminCmd = new SqlCommand(adminQuery, connection))
                {
                    using (var reader = adminCmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            adminList.Add(reader["MaTaiKhoan"].ToString());
                        }
                    }
                }

                // Tạo thông báo cho mỗi admin
                foreach (var adminId in adminList)
                {
                    string maThongBao = $"NOTIF_{maDonHang}_{adminId}_{DateTime.Now:yyyyMMddHHmmss}";
                    string tieuDe = "Đơn hàng mới";
                    string noiDung = $"Khách hàng {customerName} vừa đặt đơn hàng mới. Mã đơn hàng: {maDonHang}";

                    string insertQuery = @"INSERT INTO Notification 
                                          (MaThongBao, LoaiThongBao, MaDonHang, MaNguoiNhan, TieuDe, NoiDung, DaDoc, NgayTao)
                                          VALUES (@MaThongBao, @LoaiThongBao, @MaDonHang, @MaNguoiNhan, @TieuDe, @NoiDung, 0, GETDATE())";

                    using (var insertCmd = new SqlCommand(insertQuery, connection))
                    {
                        insertCmd.Parameters.AddWithValue("@MaThongBao", maThongBao);
                        insertCmd.Parameters.AddWithValue("@LoaiThongBao", "NewOrder");
                        insertCmd.Parameters.AddWithValue("@MaDonHang", maDonHang);
                        insertCmd.Parameters.AddWithValue("@MaNguoiNhan", adminId);
                        insertCmd.Parameters.AddWithValue("@TieuDe", tieuDe);
                        insertCmd.Parameters.AddWithValue("@NoiDung", noiDung);
                        insertCmd.ExecuteNonQuery();
                    }
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