using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System.Data;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StatisticsController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<StatisticsController> _logger;

        public StatisticsController(IConfiguration configuration, ILogger<StatisticsController> logger)
        {
            _configuration = configuration;
            _logger = logger;
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        }

        /// <summary>
        /// Export báo cáo thống kê ra file Excel
        /// GET: api/Statistics/export-excel?year=2025&startDate=2025-01-01&endDate=2025-12-31
        /// </summary>
        [HttpGet("export-excel")]
        public IActionResult ExportStatisticsToExcel(
            [FromQuery] int? year,
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate)
        {
            try
            {
                _logger.LogInformation($"Export Excel request: year={year}, startDate={startDate}, endDate={endDate}");
                
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                if (string.IsNullOrEmpty(connectionString))
                {
                    _logger.LogError("Connection string is null or empty");
                    return StatusCode(500, new { error = "Database connection string not configured" });
                }
                
                using var package = new ExcelPackage();
                
                // Sheet 1: Tổng quan
                var overviewSheet = package.Workbook.Worksheets.Add("Tổng quan");
                CreateOverviewSheet(overviewSheet, connectionString);
                
                // Sheet 2: Doanh thu theo tháng
                var monthlyRevenueSheet = package.Workbook.Worksheets.Add("Doanh thu theo tháng");
                CreateMonthlyRevenueSheet(monthlyRevenueSheet, connectionString, year ?? DateTime.Now.Year);
                
                // Sheet 3: Đơn hàng theo trạng thái
                var orderStatusSheet = package.Workbook.Worksheets.Add("Đơn hàng theo trạng thái");
                CreateOrderStatusSheet(orderStatusSheet, connectionString);
                
                // Sheet 4: Sản phẩm bán chạy
                var topProductsSheet = package.Workbook.Worksheets.Add("Sản phẩm bán chạy");
                CreateTopProductsSheet(topProductsSheet, connectionString);
                
                // Sheet 5: Thống kê theo khoảng thời gian (nếu có)
                if (startDate.HasValue && endDate.HasValue)
                {
                    var dateRangeSheet = package.Workbook.Worksheets.Add("Thống kê theo khoảng thời gian");
                    CreateDateRangeSheet(dateRangeSheet, connectionString, startDate.Value, endDate.Value);
                }
                
                // Sheet 6: Người dùng
                var usersSheet = package.Workbook.Worksheets.Add("Người dùng");
                CreateUsersSheet(usersSheet, connectionString);
                
                var fileName = $"BaoCaoThongKe_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                var fileBytes = package.GetAsByteArray();
                
                _logger.LogInformation($"Excel file generated: {fileName}, size: {fileBytes.Length} bytes");
                
                if (fileBytes.Length == 0)
                {
                    _logger.LogError("Generated Excel file is empty");
                    return StatusCode(500, new { error = "Generated Excel file is empty" });
                }
                
                return File(fileBytes, 
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                    fileName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting statistics to Excel");
                return StatusCode(500, new { error = ex.Message, details = ex.ToString() });
            }
        }

        private void CreateOverviewSheet(ExcelWorksheet sheet, string connectionString)
        {
            // Header
            sheet.Cells[1, 1].Value = "BÁO CÁO TỔNG QUAN";
            sheet.Cells[1, 1, 1, 2].Merge = true;
            sheet.Cells[1, 1].Style.Font.Size = 16;
            sheet.Cells[1, 1].Style.Font.Bold = true;
            sheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            sheet.Cells[2, 1].Value = $"Ngày xuất báo cáo: {DateTime.Now:dd/MM/yyyy HH:mm:ss}";
            sheet.Cells[2, 1, 2, 2].Merge = true;
            
            int row = 4;
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                
                // Tổng đơn hàng
                var totalOrdersQuery = "SELECT COUNT(*) FROM DonHang";
                var totalOrders = ExecuteScalar<int>(connection, totalOrdersQuery);
                sheet.Cells[row, 1].Value = "Tổng số đơn hàng:";
                sheet.Cells[row, 2].Value = totalOrders;
                row++;
                
                // Đơn hàng đã hoàn thành
                var completedOrdersQuery = @"SELECT COUNT(*) FROM DonHang 
                    WHERE TrangThai IN ('Hoàn thành', 'Đã giao hàng', 'complete', 'completed')";
                var completedOrders = ExecuteScalar<int>(connection, completedOrdersQuery);
                sheet.Cells[row, 1].Value = "Đơn hàng đã hoàn thành:";
                sheet.Cells[row, 2].Value = completedOrders;
                row++;
                
                // Tổng doanh thu
                var revenueQuery = @"SELECT ISNULL(SUM(ct.GiaBan * ct.SoLuong), 0) 
                    FROM DonHang dh
                    LEFT JOIN ChiTietDonHang ct ON dh.MaDonHang = ct.MaDonHang
                    WHERE dh.TrangThai IN ('Hoàn thành', 'Đã giao hàng', 'complete', 'completed')";
                var totalRevenue = ExecuteScalar<decimal>(connection, revenueQuery);
                sheet.Cells[row, 1].Value = "Tổng doanh thu (VND):";
                sheet.Cells[row, 2].Value = totalRevenue;
                sheet.Cells[row, 2].Style.Numberformat.Format = "#,##0";
                row++;
                
                // Tổng người dùng
                var totalUsersQuery = "SELECT COUNT(*) FROM NguoiDung";
                var totalUsers = ExecuteScalar<int>(connection, totalUsersQuery);
                sheet.Cells[row, 1].Value = "Tổng số người dùng:";
                sheet.Cells[row, 2].Value = totalUsers;
                row++;
                
                // Tổng sản phẩm
                var totalProductsQuery = "SELECT COUNT(*) FROM SanPham WHERE (IsDeleted = 0 OR IsDeleted IS NULL)";
                var totalProducts = ExecuteScalar<int>(connection, totalProductsQuery);
                sheet.Cells[row, 1].Value = "Tổng số sản phẩm:";
                sheet.Cells[row, 2].Value = totalProducts;
            }
            
            // Format header
            sheet.Cells[4, 1, row, 1].Style.Font.Bold = true;
            sheet.Columns[1].Width = 30;
            sheet.Columns[2].Width = 20;
        }

        private void CreateMonthlyRevenueSheet(ExcelWorksheet sheet, string connectionString, int year)
        {
            sheet.Cells[1, 1].Value = $"DOANH THU THEO THÁNG - NĂM {year}";
            sheet.Cells[1, 1, 1, 3].Merge = true;
            sheet.Cells[1, 1].Style.Font.Size = 14;
            sheet.Cells[1, 1].Style.Font.Bold = true;
            sheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            // Header row
            sheet.Cells[3, 1].Value = "Tháng";
            sheet.Cells[3, 2].Value = "Số đơn";
            sheet.Cells[3, 3].Value = "Doanh thu (VND)";
            
            var headerRange = sheet.Cells[3, 1, 3, 3];
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.PatternType = ExcelFillStyle.Solid;
            headerRange.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
            headerRange.Style.Border.BorderAround(ExcelBorderStyle.Thin);
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                
                string query = @"SELECT 
                    MONTH(dh.NgayDat) as Thang,
                    COUNT(DISTINCT dh.MaDonHang) as SoDon,
                    SUM(ISNULL(ct.GiaBan * ct.SoLuong, 0)) as DoanhThu
                FROM DonHang dh
                LEFT JOIN ChiTietDonHang ct ON dh.MaDonHang = ct.MaDonHang
                WHERE YEAR(dh.NgayDat) = @Year
                    AND dh.TrangThai IN ('Hoàn thành', 'Đã giao hàng', 'complete', 'completed', N'Hoàn thành', N'Đã giao hàng')
                GROUP BY MONTH(dh.NgayDat)
                ORDER BY MONTH(dh.NgayDat)";
                
                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@Year", year);
                    
                    int row = 4;
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            sheet.Cells[row, 1].Value = $"Tháng {reader["Thang"]}";
                            sheet.Cells[row, 2].Value = reader["SoDon"];
                            sheet.Cells[row, 3].Value = Convert.ToDecimal(reader["DoanhThu"]);
                            sheet.Cells[row, 3].Style.Numberformat.Format = "#,##0";
                            row++;
                        }
                    }
                    
                    // Tổng
                    sheet.Cells[row, 1].Value = "TỔNG";
                    sheet.Cells[row, 1].Style.Font.Bold = true;
                    sheet.Cells[row, 2].Formula = $"SUM(B4:B{row - 1})";
                    sheet.Cells[row, 3].Formula = $"SUM(C4:C{row - 1})";
                    sheet.Cells[row, 3].Style.Numberformat.Format = "#,##0";
                    sheet.Cells[row, 1, row, 3].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    sheet.Cells[row, 1, row, 3].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
                }
            }
            
            sheet.Columns[1].Width = 15;
            sheet.Columns[2].Width = 15;
            sheet.Columns[3].Width = 20;
        }

        private void CreateOrderStatusSheet(ExcelWorksheet sheet, string connectionString)
        {
            sheet.Cells[1, 1].Value = "ĐƠN HÀNG THEO TRẠNG THÁI";
            sheet.Cells[1, 1, 1, 3].Merge = true;
            sheet.Cells[1, 1].Style.Font.Size = 14;
            sheet.Cells[1, 1].Style.Font.Bold = true;
            sheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            sheet.Cells[3, 1].Value = "Trạng thái";
            sheet.Cells[3, 2].Value = "Số lượng";
            sheet.Cells[3, 3].Value = "Doanh thu (VND)";
            
            var headerRange = sheet.Cells[3, 1, 3, 3];
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.PatternType = ExcelFillStyle.Solid;
            headerRange.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
            headerRange.Style.Border.BorderAround(ExcelBorderStyle.Thin);
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                
                string query = @"SELECT 
                    dh.TrangThai,
                    COUNT(*) as SoLuong,
                    SUM(ISNULL(ct.GiaBan * ct.SoLuong, 0)) as DoanhThu
                FROM DonHang dh
                LEFT JOIN ChiTietDonHang ct ON dh.MaDonHang = ct.MaDonHang
                GROUP BY dh.TrangThai
                ORDER BY SoLuong DESC";
                
                int row = 4;
                using (var command = new SqlCommand(query, connection))
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        sheet.Cells[row, 1].Value = reader["TrangThai"].ToString();
                        sheet.Cells[row, 2].Value = Convert.ToInt32(reader["SoLuong"]);
                        sheet.Cells[row, 3].Value = Convert.ToDecimal(reader["DoanhThu"]);
                        sheet.Cells[row, 3].Style.Numberformat.Format = "#,##0";
                        row++;
                    }
                }
            }
            
            sheet.Columns[1].Width = 25;
            sheet.Columns[2].Width = 15;
            sheet.Columns[3].Width = 20;
        }

        private void CreateTopProductsSheet(ExcelWorksheet sheet, string connectionString)
        {
            sheet.Cells[1, 1].Value = "TOP 20 SẢN PHẨM BÁN CHẠY";
            sheet.Cells[1, 1, 1, 4].Merge = true;
            sheet.Cells[1, 1].Style.Font.Size = 14;
            sheet.Cells[1, 1].Style.Font.Bold = true;
            sheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            sheet.Cells[3, 1].Value = "Tên sản phẩm";
            sheet.Cells[3, 2].Value = "Giá (VND)";
            sheet.Cells[3, 3].Value = "Tồn kho";
            sheet.Cells[3, 4].Value = "Tổng bán";
            
            var headerRange = sheet.Cells[3, 1, 3, 4];
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.PatternType = ExcelFillStyle.Solid;
            headerRange.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
            headerRange.Style.Border.BorderAround(ExcelBorderStyle.Thin);
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                
                string query = @"SELECT TOP 20
                    s.TenSanPham,
                    s.GiaBan,
                    s.SoLuongTon,
                    ISNULL(SUM(ct.SoLuong), 0) as TongBan
                FROM SanPham s
                LEFT JOIN ChiTietDonHang ct ON s.MaSanPham = ct.MaSanPham
                WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                GROUP BY s.MaSanPham, s.TenSanPham, s.GiaBan, s.SoLuongTon
                ORDER BY TongBan DESC";
                
                int row = 4;
                using (var command = new SqlCommand(query, connection))
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        sheet.Cells[row, 1].Value = reader["TenSanPham"].ToString();
                        sheet.Cells[row, 2].Value = Convert.ToDecimal(reader["GiaBan"]);
                        sheet.Cells[row, 2].Style.Numberformat.Format = "#,##0";
                        sheet.Cells[row, 3].Value = Convert.ToInt32(reader["SoLuongTon"]);
                        sheet.Cells[row, 4].Value = Convert.ToInt32(reader["TongBan"]);
                        row++;
                    }
                }
            }
            
            sheet.Columns[1].Width = 30;
            sheet.Columns[2].Width = 15;
            sheet.Columns[3].Width = 15;
            sheet.Columns[4].Width = 15;
        }

        private void CreateDateRangeSheet(ExcelWorksheet sheet, string connectionString, DateTime startDate, DateTime endDate)
        {
            sheet.Cells[1, 1].Value = $"THỐNG KÊ TỪ {startDate:dd/MM/yyyy} ĐẾN {endDate:dd/MM/yyyy}";
            sheet.Cells[1, 1, 1, 2].Merge = true;
            sheet.Cells[1, 1].Style.Font.Size = 14;
            sheet.Cells[1, 1].Style.Font.Bold = true;
            sheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            int row = 3;
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                
                string query = @"SELECT 
                    COUNT(DISTINCT dh.MaDonHang) as SoDon,
                    COUNT(DISTINCT dh.MaTaiKhoan) as SoKhachHang,
                    SUM(ISNULL(ct.GiaBan * ct.SoLuong, 0)) as DoanhThu
                FROM DonHang dh
                LEFT JOIN ChiTietDonHang ct ON dh.MaDonHang = ct.MaDonHang
                WHERE dh.NgayDat BETWEEN @StartDate AND @EndDate
                    AND dh.TrangThai IN ('Hoàn thành', 'Đã giao hàng', 'complete', 'completed', N'Hoàn thành', N'Đã giao hàng')";
                
                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@StartDate", startDate);
                    command.Parameters.AddWithValue("@EndDate", endDate);
                    
                    using (var reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            sheet.Cells[row, 1].Value = "Số đơn hàng:";
                            sheet.Cells[row, 2].Value = Convert.ToInt32(reader["SoDon"]);
                            row++;
                            
                            sheet.Cells[row, 1].Value = "Số khách hàng:";
                            sheet.Cells[row, 2].Value = Convert.ToInt32(reader["SoKhachHang"]);
                            row++;
                            
                            sheet.Cells[row, 1].Value = "Doanh thu (VND):";
                            sheet.Cells[row, 2].Value = Convert.ToDecimal(reader["DoanhThu"]);
                            sheet.Cells[row, 2].Style.Numberformat.Format = "#,##0";
                        }
                    }
                }
            }
            
            sheet.Cells[3, 1, row, 1].Style.Font.Bold = true;
            sheet.Columns[1].Width = 25;
            sheet.Columns[2].Width = 20;
        }

        private void CreateUsersSheet(ExcelWorksheet sheet, string connectionString)
        {
            sheet.Cells[1, 1].Value = "THỐNG KÊ NGƯỜI DÙNG";
            sheet.Cells[1, 1, 1, 2].Merge = true;
            sheet.Cells[1, 1].Style.Font.Size = 14;
            sheet.Cells[1, 1].Style.Font.Bold = true;
            sheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            sheet.Cells[3, 1].Value = "Vai trò";
            sheet.Cells[3, 2].Value = "Số lượng";
            
            var headerRange = sheet.Cells[3, 1, 3, 2];
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.PatternType = ExcelFillStyle.Solid;
            headerRange.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
            headerRange.Style.Border.BorderAround(ExcelBorderStyle.Thin);
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                
                string query = @"SELECT 
                    VaiTro,
                    COUNT(*) as SoLuong
                FROM NguoiDung
                GROUP BY VaiTro
                ORDER BY SoLuong DESC";
                
                int row = 4;
                using (var command = new SqlCommand(query, connection))
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        sheet.Cells[row, 1].Value = reader["VaiTro"].ToString();
                        sheet.Cells[row, 2].Value = Convert.ToInt32(reader["SoLuong"]);
                        row++;
                    }
                }
            }
            
            sheet.Columns[1].Width = 20;
            sheet.Columns[2].Width = 15;
        }

        private T ExecuteScalar<T>(SqlConnection connection, string query)
        {
            using (var command = new SqlCommand(query, connection))
            {
                var result = command.ExecuteScalar();
                if (result == null || result == DBNull.Value)
                    return default(T);
                return (T)Convert.ChangeType(result, typeof(T));
            }
        }
    }
}

