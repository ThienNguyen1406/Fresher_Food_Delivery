"""
Function Handler Service - Xử lý function calling từ AI
Kết nối với SQL Server để lấy dữ liệu real-time
"""
import json
import logging
import os
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
import pyodbc

logger = logging.getLogger(__name__)


class FunctionHandler:
    """Handler để xử lý các function calls từ AI"""
    
    def __init__(self, connection_string: str):
        """
        Khởi tạo Function Handler với connection string
        
        Args:
            connection_string: SQL Server connection string
        """
        self.connection_string = connection_string
        logger.info("FunctionHandler initialized")
    
    async def execute_function(self, function_name: str, arguments: Dict[str, Any]) -> str:
        """
        Thực thi function call và trả về kết quả dưới dạng JSON string
        
        Args:
            function_name: Tên function cần thực thi
            arguments: Arguments của function (dictionary)
            
        Returns:
            JSON string chứa kết quả
        """
        try:
            logger.info(f"Executing function: {function_name} with arguments: {arguments}")
            
            if function_name == "getProductExpiry":
                return await self._get_product_expiry(arguments)
            elif function_name == "getProductsExpiringSoon":
                return await self._get_products_expiring_soon(arguments)
            elif function_name == "getMonthlyRevenue":
                return await self._get_monthly_revenue(arguments)
            elif function_name == "getRevenueStatistics":
                return await self._get_revenue_statistics(arguments)
            elif function_name == "getBestSellingProductImage":
                return await self._get_best_selling_product_image(arguments)
            else:
                return json.dumps({
                    "error": f"Unknown function: {function_name}"
                })
        except Exception as ex:
            logger.error(f"Error executing function {function_name}: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi thực thi function {function_name}: {str(ex)}"
            })
    
    async def _get_product_expiry(self, args: Dict[str, Any]) -> str:
        """Lấy thông tin hạn sử dụng của sản phẩm"""
        try:
            product_name = args.get("productName")
            product_id = args.get("productId")
            
            if not product_name and not product_id:
                return json.dumps({
                    "error": "Cần cung cấp productName hoặc productId"
                })
            
            conn = pyodbc.connect(self.connection_string)
            cursor = conn.cursor()
            
            if product_id:
                query = """
                    SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                    FROM SanPham
                    WHERE MaSanPham = ?
                """
                cursor.execute(query, product_id)
            else:
                query = """
                    SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                    FROM SanPham
                    WHERE TenSanPham LIKE ?
                    ORDER BY TenSanPham
                """
                cursor.execute(query, f"%{product_name}%")
            
            row = cursor.fetchone()
            cursor.close()
            conn.close()
            
            if not row:
                return json.dumps({
                    "error": f"Không tìm thấy sản phẩm '{product_name or product_id}' trong hệ thống."
                })
            
            ma_san_pham, ten_san_pham, ngay_san_xuat, ngay_het_han = row
            
            # Tính toán thời gian còn lại
            now = datetime.now()
            if ngay_het_han:
                expiry_date = ngay_het_han
                days_remaining = (expiry_date.date() - now.date()).days
                
                if days_remaining > 0:
                    status = "Sắp hết hạn" if days_remaining <= 3 else "Còn hạn"
                else:
                    status = "Đã hết hạn"
            else:
                days_remaining = None
                status = "Chưa có thông tin"
            
            result = {
                "maSanPham": ma_san_pham,
                "tenSanPham": ten_san_pham,
                "ngaySanXuat": ngay_san_xuat.strftime("%d/%m/%Y") if ngay_san_xuat else None,
                "ngayHetHan": ngay_het_han.strftime("%d/%m/%Y") if ngay_het_han else None,
                "daysRemaining": days_remaining,
                "status": status
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_product_expiry: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy thông tin hạn sử dụng: {str(ex)}"
            })
    
    async def _get_products_expiring_soon(self, args: Dict[str, Any]) -> str:
        """Lấy danh sách sản phẩm sắp hết hạn"""
        try:
            days = args.get("days", 7)
            
            conn = pyodbc.connect(self.connection_string)
            cursor = conn.cursor()
            
            cutoff_date = datetime.now().date() + timedelta(days=days)
            
            query = """
                SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                FROM SanPham
                WHERE NgayHetHan IS NOT NULL
                    AND CAST(NgayHetHan AS DATE) <= ?
                    AND CAST(NgayHetHan AS DATE) >= CAST(GETDATE() AS DATE)
                ORDER BY NgayHetHan ASC
            """
            
            cursor.execute(query, cutoff_date)
            rows = cursor.fetchall()
            cursor.close()
            conn.close()
            
            products = []
            now = datetime.now().date()
            
            for row in rows:
                ma_san_pham, ten_san_pham, ngay_san_xuat, ngay_het_han = row
                if ngay_het_han:
                    days_remaining = (ngay_het_han.date() - now).days
                    products.append({
                        "maSanPham": ma_san_pham,
                        "tenSanPham": ten_san_pham,
                        "ngaySanXuat": ngay_san_xuat.strftime("%d/%m/%Y") if ngay_san_xuat else None,
                        "ngayHetHan": ngay_het_han.strftime("%d/%m/%Y"),
                        "daysRemaining": days_remaining,
                        "status": "Sắp hết hạn" if days_remaining <= 3 else "Còn hạn"
                    })
            
            result = {
                "days": days,
                "totalProducts": len(products),
                "products": products
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_products_expiring_soon: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy danh sách sản phẩm sắp hết hạn: {str(ex)}"
            })
    
    async def _get_monthly_revenue(self, args: Dict[str, Any]) -> str:
        """Lấy doanh thu theo tháng trong năm"""
        try:
            year = args.get("year")
            if not year:
                year = datetime.now().year
            
            conn = pyodbc.connect(self.connection_string)
            cursor = conn.cursor()
            
            query = """
                SELECT 
                    MONTH(dh.NgayDat) as Thang,
                    ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as DoanhThu
                FROM DonHang dh
                LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                WHERE YEAR(dh.NgayDat) = ?
                    AND (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng', 'completed', 'completed')
                         OR dh.TrangThai LIKE '%complete%'
                         OR dh.TrangThai LIKE '%Complete%')
                GROUP BY MONTH(dh.NgayDat)
                ORDER BY MONTH(dh.NgayDat)
            """
            
            cursor.execute(query, year)
            rows = cursor.fetchall()
            cursor.close()
            conn.close()
            
            monthly_revenue = {}
            for row in rows:
                thang, doanh_thu = row
                monthly_revenue[thang] = float(doanh_thu)
            
            # Đảm bảo có đủ 12 tháng
            month_names = [
                "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
                "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
            ]
            
            monthly_data = []
            total_revenue = 0
            for month in range(1, 13):
                doanh_thu = monthly_revenue.get(month, 0)
                total_revenue += doanh_thu
                monthly_data.append({
                    "thang": month,
                    "tenThang": month_names[month - 1],
                    "doanhThu": doanh_thu
                })
            
            result = {
                "year": year,
                "totalRevenue": total_revenue,
                "monthlyData": monthly_data,
                "message": f"Tổng doanh thu năm {year}: {total_revenue:,.0f} VND"
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_monthly_revenue: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy doanh thu theo tháng: {str(ex)}"
            })
    
    async def _get_revenue_statistics(self, args: Dict[str, Any]) -> str:
        """Lấy thống kê doanh thu theo khoảng thời gian"""
        try:
            start_date = args.get("startDate")
            end_date = args.get("endDate")
            
            conn = pyodbc.connect(self.connection_string)
            cursor = conn.cursor()
            
            # Xây dựng query với điều kiện lọc theo ngày
            base_condition = ""
            params = []
            
            if start_date:
                base_condition += " AND CAST(dh.NgayDat AS DATE) >= ?"
                params.append(start_date)
            
            if end_date:
                base_condition += " AND CAST(dh.NgayDat AS DATE) <= ?"
                params.append(end_date)
            
            # Query cho doanh thu
            revenue_query = f"""
                SELECT 
                    ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as TongDoanhThu,
                    COUNT(DISTINCT dh.MaDonHang) as TongDonHang,
                    COUNT(DISTINCT dh.MaTaiKhoan) as TongKhachHang
                FROM DonHang dh
                LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                WHERE (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng')
                       OR dh.TrangThai LIKE '%complete%'
                       OR dh.TrangThai LIKE '%Complete%')
                    {base_condition}
            """
            
            cursor.execute(revenue_query, params)
            row = cursor.fetchone()
            
            tong_doanh_thu = float(row[0]) if row else 0
            tong_don_hang = row[1] if row else 0
            tong_khach_hang = row[2] if row else 0
            
            # Query cho số đơn thành công và bị hủy
            status_query = f"""
                SELECT 
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
                WHERE 1=1 {base_condition}
            """
            
            cursor.execute(status_query, params)
            row = cursor.fetchone()
            
            don_thanh_cong = row[0] if row and row[0] else 0
            don_bi_huy = row[1] if row and row[1] else 0
            
            cursor.close()
            conn.close()
            
            result = {
                "tongDoanhThu": tong_doanh_thu,
                "tongDonHang": tong_don_hang,
                "tongKhachHang": tong_khach_hang,
                "donThanhCong": don_thanh_cong,
                "donBiHuy": don_bi_huy,
                "message": f"Tổng doanh thu: {tong_doanh_thu:,.0f} VND, Tổng đơn hàng: {tong_don_hang}, Tổng khách hàng: {tong_khach_hang}"
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_revenue_statistics: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy thống kê doanh thu: {str(ex)}"
            })
    
    async def _get_best_selling_product_image(self, args: Dict[str, Any]) -> str:
        """Lấy hình ảnh sản phẩm bán chạy nhất"""
        try:
            conn = pyodbc.connect(self.connection_string)
            cursor = conn.cursor()
            
            query = """
                SELECT TOP 1
                    s.MaSanPham,
                    s.TenSanPham,
                    s.Anh,
                    s.GiaBan,
                    s.SoLuongTon,
                    ISNULL(SUM(ct.SoLuong), 0) as TongBan
                FROM SanPham s
                LEFT JOIN ChiTietDonHang ct ON s.MaSanPham = ct.MaSanPham
                WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                GROUP BY s.MaSanPham, s.TenSanPham, s.Anh, s.GiaBan, s.SoLuongTon
                ORDER BY TongBan DESC
            """
            
            cursor.execute(query)
            row = cursor.fetchone()
            cursor.close()
            conn.close()
            
            if not row:
                return json.dumps({
                    "error": "Không tìm thấy sản phẩm bán chạy nhất trong hệ thống."
                }, ensure_ascii=False)
            
            ma_san_pham, ten_san_pham, anh, gia_ban, so_luong_ton, tong_ban = row
            
            # Lấy base URL từ environment variable hoặc sử dụng giá trị mặc định
            base_url = os.getenv("APP_BASE_URL", "https://localhost:7240")
            image_url = None
            if anh:
                image_url = f"{base_url}/images/products/{anh}"
            
            result = {
                "maSanPham": ma_san_pham,
                "tenSanPham": ten_san_pham,
                "anh": anh,
                "anhUrl": image_url,
                "giaBan": float(gia_ban) if gia_ban else 0,
                "soLuongTon": so_luong_ton if so_luong_ton else 0,
                "tongBan": tong_ban if tong_ban else 0,
                "message": f"Sản phẩm bán chạy nhất là {ten_san_pham} với tổng số lượng đã bán là {tong_ban}.",
                "imagePath": image_url if image_url else "Sản phẩm này chưa có hình ảnh."
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_best_selling_product_image: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy hình ảnh sản phẩm bán chạy nhất: {str(ex)}"
            }, ensure_ascii=False)

