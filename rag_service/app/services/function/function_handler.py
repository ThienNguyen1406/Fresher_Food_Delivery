import json
import logging
import os
import re
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from contextlib import contextmanager
from functools import lru_cache
import pyodbc
import hashlib

logger = logging.getLogger(__name__)

# ⚡ Cache cho function results (TTL: 5 phút)
_function_cache: Dict[str, tuple] = {}  # key: (result, expiry_time)
CACHE_TTL_SECONDS = 300  # 5 phút


class FunctionHandler:
    """Handler để xử lý các function calls từ AI"""
    
    def __init__(self, connection_string: str):
        """
        Khởi tạo Function Handler với connection string
        """
        if not connection_string:
            raise ValueError("Connection string không được để trống")
        # Convert connection string sang ODBC format nếu cần
        self.connection_string = self._convert_to_odbc_connection_string(connection_string)
        logger.info("FunctionHandler initialized successfully")
    
    def _convert_to_odbc_connection_string(self, conn_str: str) -> str:
        """
        Convert connection string từ .NET format sang ODBC format
        """
        if "DRIVER=" in conn_str.upper():
            return conn_str
        
        # Parse .NET format connection string
        params = {}
        
        # Split theo dấu ; và parse từng phần
        parts = [p.strip() for p in conn_str.split(';') if p.strip()]
        for part in parts:
            if '=' in part:
                key, value = part.split('=', 1)
                key = key.strip().lower()
                value = value.strip()
                params[key] = value
        
        # Map .NET parameters sang ODBC parameters
        server = params.get('server', '')
        database = params.get('database', '')
        user_id = params.get('user id', params.get('uid', ''))
        password = params.get('password', params.get('pwd', ''))
        trust_cert = params.get('trustservercertificate', 'True').lower() == 'true'
        
        # Thử các driver theo thứ tự ưu tiên
        drivers_to_try = [
            "ODBC Driver 18 for SQL Server",
            "ODBC Driver 17 for SQL Server",
            "SQL Server Native Client 11.0",
            "SQL Server"
        ]
        
        # Tạo connection string với driver đầu tiên
        # Nếu không kết nối được, sẽ thử các driver khác trong _get_connection
        driver = drivers_to_try[0]
        
        odbc_conn_str = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};"
        if user_id:
            odbc_conn_str += f"UID={user_id};PWD={password};"
        if trust_cert:
            odbc_conn_str += "TrustServerCertificate=yes;"
        
        return odbc_conn_str
    
    @contextmanager
    def _get_connection(self):
        """Context manager để quản lý database connection"""
        conn = None
        
        # Danh sách các driver để thử
        drivers_to_try = [
            "ODBC Driver 18 for SQL Server",
            "ODBC Driver 17 for SQL Server",
            "SQL Server Native Client 11.0",
            "SQL Server"
        ]
        
        # Parse connection string để lấy các tham số
        params = {}
        # Split theo dấu ; và parse từng phần
        parts = [p.strip() for p in self.connection_string.split(';') if p.strip()]
        for part in parts:
            if '=' in part:
                key, value = part.split('=', 1)
                key = key.strip().lower()
                value = value.strip()
                params[key] = value
        
        server = params.get('server', '')
        database = params.get('database', '')
        user_id = params.get('uid', '')
        password = params.get('pwd', '')
        trust_cert = params.get('trustservercertificate', 'yes')
        
        # Thử kết nối với các driver khác nhau
        last_error = None
        for driver in drivers_to_try:
            try:
                # Tạo connection string với driver hiện tại
                conn_str = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};"
                if user_id:
                    conn_str += f"UID={user_id};PWD={password};"
                if trust_cert:
                    conn_str += "TrustServerCertificate=yes;"
                
                logger.info(f"Đang thử kết nối với driver: {driver}")
                conn = pyodbc.connect(conn_str, timeout=10)
                logger.info(f"Kết nối thành công với driver: {driver}")
                break
            except pyodbc.Error as e:
                last_error = e
                logger.warning(f"Không thể kết nối với driver {driver}: {str(e)}")
                if conn:
                    conn.close()
                    conn = None
                continue
        
        if conn is None:
            error_msg = f"Không thể kết nối database với bất kỳ driver nào. Lỗi cuối cùng: {str(last_error)}"
            logger.error(error_msg)
            raise pyodbc.Error(error_msg)
        
        try:
            yield conn
        except pyodbc.Error as e:
            logger.error(f"Database connection error: {str(e)}", exc_info=True)
            raise
        finally:
            if conn:
                conn.close()
    
    async def execute_function(self, function_name: str, arguments: Dict[str, Any]) -> str:
        """
        Thực thi function call và trả về kết quả dưới dạng JSON string
        """
        try:
            logger.info(f"Executing function: {function_name} with arguments: {arguments}")
            
            # Mapping các function names
            function_map = {
                "getProductExpiry": self._get_product_expiry,
                "getProductsExpiringSoon": self._get_products_expiring_soon,
                "getMonthlyRevenue": self._get_monthly_revenue,
                "getRevenueStatistics": self._get_revenue_statistics,
                "getProductMonthlyRevenue": self._get_product_monthly_revenue,  # Doanh thu theo product_id
                "getBestSellingProductImage": self._get_best_selling_product_image,
                "getProductInfo": self._get_product_info,
                "getOrderStatus": self._get_order_status,
                "getCustomerOrders": self._get_customer_orders,
                "getTopProducts": self._get_top_products,
                "getInventoryStatus": self._get_inventory_status,
                "getCategoryProducts": self._get_category_products,
                "getActivePromotions": self._get_active_promotions,  # Khuyến mãi đang hoạt động
            }
            
            handler = function_map.get(function_name)
            if not handler:
                return json.dumps({
                    "error": f"Unknown function: {function_name}",
                    "availableFunctions": list(function_map.keys())
                }, ensure_ascii=False)
            
            result = await handler(arguments)
            return result
            
        except Exception as ex:
            logger.error(f"Error executing function {function_name}: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi thực thi function {function_name}: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_product_expiry(self, args: Dict[str, Any]) -> str:
        """Lấy thông tin hạn sử dụng của sản phẩm"""
        try:
            product_name = args.get("productName")
            product_id = args.get("productId")
            
            if not product_name and not product_id:
                return json.dumps({
                    "error": "Cần cung cấp productName hoặc productId"
                }, ensure_ascii=False)
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                if product_id:
                    query = """
                        SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                        FROM SanPham
                        WHERE MaSanPham = ? AND (IsDeleted = 0 OR IsDeleted IS NULL)
                    """
                    cursor.execute(query, product_id)
                else:
                    query = """
                        SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                        FROM SanPham
                        WHERE TenSanPham LIKE ? AND (IsDeleted = 0 OR IsDeleted IS NULL)
                        ORDER BY TenSanPham
                    """
                    cursor.execute(query, f"%{product_name}%")
                
                row = cursor.fetchone()
                cursor.close()
            
            if not row:
                return json.dumps({
                    "error": f"Không tìm thấy sản phẩm '{product_name or product_id}' trong hệ thống."
                }, ensure_ascii=False)
            
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
            }, ensure_ascii=False)
    
    async def _get_products_expiring_soon(self, args: Dict[str, Any]) -> str:
        """Lấy danh sách sản phẩm sắp hết hạn"""
        try:
            days = args.get("days", 7)
            if not isinstance(days, int) or days < 1:
                days = 7
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                cutoff_date = datetime.now().date() + timedelta(days=days)
                
                query = """
                    SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                    FROM SanPham
                    WHERE NgayHetHan IS NOT NULL
                        AND CAST(NgayHetHan AS DATE) <= ?
                        AND CAST(NgayHetHan AS DATE) >= CAST(GETDATE() AS DATE)
                        AND (IsDeleted = 0 OR IsDeleted IS NULL)
                    ORDER BY NgayHetHan ASC
                """
                
                cursor.execute(query, cutoff_date)
                rows = cursor.fetchall()
                cursor.close()
            
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
            }, ensure_ascii=False)
    
    async def _get_monthly_revenue(self, args: Dict[str, Any]) -> str:
        """Lấy doanh thu theo tháng trong năm"""
        try:
            year = args.get("year")
            if not year:
                year = datetime.now().year
            elif not isinstance(year, int) or year < 2000 or year > 2100:
                year = datetime.now().year
            
            with self._get_connection() as conn:
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
            }, ensure_ascii=False)
    
    async def _get_revenue_statistics(self, args: Dict[str, Any]) -> str:
        """Lấy thống kê doanh thu theo khoảng thời gian"""
        try:
            start_date = args.get("startDate")
            end_date = args.get("endDate")
            
            with self._get_connection() as conn:
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
            }, ensure_ascii=False)
    
    def _get_cache_key(self, function_name: str, args: Dict[str, Any]) -> str:
        """Tạo cache key từ function name và arguments"""
        # Sort args để đảm bảo cùng arguments tạo cùng key
        sorted_args = json.dumps(args, sort_keys=True, ensure_ascii=False)
        cache_str = f"{function_name}:{sorted_args}"
        return hashlib.md5(cache_str.encode()).hexdigest()
    
    def _get_cached_result(self, cache_key: str) -> Optional[str]:
        """Lấy kết quả từ cache nếu còn hiệu lực"""
        global _function_cache
        if cache_key in _function_cache:
            result, expiry_time = _function_cache[cache_key]
            if datetime.now() < expiry_time:
                logger.debug(f"✅ Cache hit for key: {cache_key[:8]}...")
                return result
            else:
                # Cache expired
                del _function_cache[cache_key]
                logger.debug(f"⏰ Cache expired for key: {cache_key[:8]}...")
        return None
    
    def _set_cached_result(self, cache_key: str, result: str, ttl_seconds: int = CACHE_TTL_SECONDS):
        """Lưu kết quả vào cache"""
        global _function_cache
        expiry_time = datetime.now() + timedelta(seconds=ttl_seconds)
        _function_cache[cache_key] = (result, expiry_time)
        logger.debug(f"💾 Cached result for key: {cache_key[:8]}... (TTL: {ttl_seconds}s)")
    
    async def _get_product_monthly_revenue(self, args: Dict[str, Any]) -> str:
        """Lấy doanh thu theo tháng của một sản phẩm cụ thể (⚡ CACHED)"""
        try:
            product_id = args.get("productId")
            year = args.get("year")
            
            if not product_id:
                return json.dumps({
                    "error": "Cần cung cấp productId"
                }, ensure_ascii=False)
            
            if not year:
                year = datetime.now().year
            elif not isinstance(year, int) or year < 2000 or year > 2100:
                year = datetime.now().year
            
            # ⚡ Kiểm tra cache
            cache_key = self._get_cache_key("getProductMonthlyRevenue", {"productId": product_id, "year": year})
            cached_result = self._get_cached_result(cache_key)
            if cached_result:
                return cached_result
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                # Query doanh thu theo tháng của sản phẩm
                query = """
                    SELECT 
                        MONTH(dh.NgayDat) as Thang,
                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as DoanhThu,
                        ISNULL(SUM(od.SoLuong), 0) as SoLuongBan
                    FROM DonHang dh
                    INNER JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                    WHERE YEAR(dh.NgayDat) = ?
                        AND od.MaSanPham = ?
                        AND (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng', 'completed', 'completed')
                             OR dh.TrangThai LIKE '%complete%'
                             OR dh.TrangThai LIKE '%Complete%')
                    GROUP BY MONTH(dh.NgayDat)
                    ORDER BY MONTH(dh.NgayDat)
                """
                
                cursor.execute(query, (year, product_id))
                rows = cursor.fetchall()
                
                # Lấy tên sản phẩm
                product_query = """
                    SELECT TenSanPham
                    FROM SanPham
                    WHERE MaSanPham = ? AND (IsDeleted = 0 OR IsDeleted IS NULL)
                """
                cursor.execute(product_query, product_id)
                product_row = cursor.fetchone()
                product_name = product_row[0] if product_row else "N/A"
                
                cursor.close()
            
            monthly_revenue = {}
            for row in rows:
                thang, doanh_thu, so_luong = row
                monthly_revenue[thang] = {
                    "doanhThu": float(doanh_thu),
                    "soLuongBan": int(so_luong)
                }
            
            # Đảm bảo có đủ 12 tháng
            month_names = [
                "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
                "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
            ]
            
            monthly_data = []
            total_revenue = 0
            max_month = 0
            max_revenue = 0
            
            for month in range(1, 13):
                data = monthly_revenue.get(month, {"doanhThu": 0, "soLuongBan": 0})
                doanh_thu = data["doanhThu"]
                total_revenue += doanh_thu
                
                if doanh_thu > max_revenue:
                    max_revenue = doanh_thu
                    max_month = month
                
                monthly_data.append({
                    "thang": month,
                    "tenThang": month_names[month - 1],
                    "doanhThu": doanh_thu,
                    "soLuongBan": data["soLuongBan"]
                })
            
            result = {
                "productId": product_id,
                "productName": product_name,
                "year": year,
                "totalRevenue": total_revenue,
                "monthlyData": monthly_data,
                "bestMonth": {
                    "thang": max_month,
                    "tenThang": month_names[max_month - 1] if max_month > 0 else None,
                    "doanhThu": max_revenue
                } if max_month > 0 else None,
                "message": f"Doanh thu của {product_name} năm {year}: {total_revenue:,.0f} VND"
            }
            
            result_json = json.dumps(result, ensure_ascii=False)
            
            # ⚡ Lưu vào cache
            self._set_cached_result(cache_key, result_json)
            
            return result_json
            
        except Exception as ex:
            logger.error(f"Error in _get_product_monthly_revenue: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy doanh thu theo tháng của sản phẩm: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_best_selling_product_image(self, args: Dict[str, Any]) -> str:
        """Lấy hình ảnh sản phẩm bán chạy nhất"""
        try:
            limit = args.get("limit", 1)
            if not isinstance(limit, int) or limit < 1:
                limit = 1
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                query = f"""
                    SELECT TOP {limit}
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
                rows = cursor.fetchall()
                cursor.close()
            
            if not rows:
                return json.dumps({
                    "error": "Không tìm thấy sản phẩm bán chạy nhất trong hệ thống."
                }, ensure_ascii=False)
            
            # Lấy base URL từ environment variable hoặc sử dụng giá trị mặc định
            base_url = os.getenv("APP_BASE_URL", "https://localhost:7240")
            
            products = []
            # Download ảnh và trả về base64 để frontend hiển thị trực tiếp
            import base64
            import urllib.parse
            import httpx

            async with httpx.AsyncClient(verify=False, timeout=10.0) as client:
                for row in rows:
                    ma_san_pham, ten_san_pham, anh, gia_ban, so_luong_ton, tong_ban = row
                    
                    image_url = None
                    image_data = None
                    image_mime_type = None
                    if anh:
                        encoded = urllib.parse.quote(str(anh), safe='')
                        image_url = f"{base_url}/images/products/{encoded}"
                        try:
                            resp = await client.get(image_url)
                            if resp.status_code == 200:
                                image_data = base64.b64encode(resp.content).decode("utf-8")
                                image_mime_type = resp.headers.get("content-type", "image/jpeg")
                        except Exception:
                            image_data = None
                            image_mime_type = None
                    
                    products.append({
                        "maSanPham": ma_san_pham,
                        "tenSanPham": ten_san_pham,
                        "anh": anh,
                        "anhUrl": image_url,
                        "imageData": image_data,
                        "imageMimeType": image_mime_type,
                        "giaBan": float(gia_ban) if gia_ban else 0,
                        "soLuongTon": so_luong_ton if so_luong_ton else 0,
                        "tongBan": tong_ban if tong_ban else 0,
                    })
            
            result = {
                "products": products if limit > 1 else products[0] if products else None,
                "message": f"Sản phẩm bán chạy nhất là {products[0]['tenSanPham']} với tổng số lượng đã bán là {products[0]['tongBan']}." if products else "Không có dữ liệu"
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_best_selling_product_image: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy hình ảnh sản phẩm bán chạy nhất: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_product_info(self, args: Dict[str, Any]) -> str:
        """Lấy thông tin chi tiết của sản phẩm"""
        try:
            product_id = args.get("productId")
            product_name = args.get("productName")
            
            if not product_id and not product_name:
                return json.dumps({
                    "error": "Cần cung cấp productId hoặc productName"
                }, ensure_ascii=False)
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                if product_id:
                    query = """
                        SELECT s.MaSanPham, s.TenSanPham, s.MoTa, s.GiaBan, s.SoLuongTon, 
                               s.DonViTinh, s.Anh, s.NgaySanXuat, s.NgayHetHan,
                               dm.TenDanhMuc
                        FROM SanPham s
                        LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                        WHERE s.MaSanPham = ? AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                    """
                    cursor.execute(query, product_id)
                    rows = cursor.fetchall()
                else:
                    # Tìm kiếm theo tên sản phẩm - hỗ trợ tìm kiếm linh hoạt hơn
                    # Tìm kiếm không phân biệt hoa thường và hỗ trợ tìm kiếm một phần
                    query = """
                        SELECT TOP 5 s.MaSanPham, s.TenSanPham, s.MoTa, s.GiaBan, s.SoLuongTon, 
                               s.DonViTinh, s.Anh, s.NgaySanXuat, s.NgayHetHan,
                               dm.TenDanhMuc
                        FROM SanPham s
                        LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                        WHERE (s.TenSanPham LIKE ? OR s.TenSanPham LIKE ? OR s.TenSanPham LIKE ?)
                          AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                        ORDER BY 
                            CASE 
                                WHEN s.TenSanPham LIKE ? THEN 1  -- Khớp chính xác
                                WHEN s.TenSanPham LIKE ? THEN 2  -- Bắt đầu bằng
                                ELSE 3  -- Chứa
                            END,
                            s.TenSanPham
                    """
                    # Tìm kiếm với nhiều pattern: chính xác, bắt đầu bằng, chứa
                    search_pattern = product_name.strip()
                    cursor.execute(query, (
                        search_pattern,  # Khớp chính xác
                        f"{search_pattern}%",  # Bắt đầu bằng
                        f"%{search_pattern}%",  # Chứa
                        search_pattern,  # Cho ORDER BY
                        f"{search_pattern}%"  # Cho ORDER BY
                    ))
                
                    rows = cursor.fetchall()
                
                cursor.close()
            
            if not rows or len(rows) == 0:
                return json.dumps({
                    "error": f"Không tìm thấy sản phẩm '{product_name or product_id}' trong hệ thống. Vui lòng kiểm tra lại tên sản phẩm hoặc cung cấp mã sản phẩm chính xác.",
                    "suggestion": "Bạn có thể thử tìm kiếm với tên sản phẩm khác hoặc xem danh sách sản phẩm trong ứng dụng."
                }, ensure_ascii=False)
            
            # Nếu có nhiều kết quả, trả về sản phẩm đầu tiên (khớp nhất)
            # Hoặc có thể trả về danh sách nếu cần
            row = rows[0]  # Lấy sản phẩm khớp nhất
            
            ma_san_pham, ten_san_pham, mo_ta, gia_ban, so_luong_ton, don_vi_tinh, anh, ngay_san_xuat, ngay_het_han, ten_danh_muc = row
            
            base_url = os.getenv("APP_BASE_URL", "https://localhost:7240")
            image_url = f"{base_url}/images/products/{anh}" if anh else None
            
            result = {
                "maSanPham": ma_san_pham,
                "tenSanPham": ten_san_pham,
                "moTa": mo_ta,
                "giaBan": float(gia_ban) if gia_ban else 0,
                "soLuongTon": so_luong_ton if so_luong_ton else 0,
                "donViTinh": don_vi_tinh,
                "anh": anh,
                "anhUrl": image_url,
                "ngaySanXuat": ngay_san_xuat.strftime("%d/%m/%Y") if ngay_san_xuat else None,
                "ngayHetHan": ngay_het_han.strftime("%d/%m/%Y") if ngay_het_han else None,
                "danhMuc": ten_danh_muc,
                "trangThai": "Còn hàng" if so_luong_ton and so_luong_ton > 0 else "Hết hàng"
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_product_info: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy thông tin sản phẩm: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_order_status(self, args: Dict[str, Any]) -> str:
        """Lấy trạng thái đơn hàng"""
        try:
            order_id = args.get("orderId")
            if not order_id:
                return json.dumps({
                    "error": "Cần cung cấp orderId"
                }, ensure_ascii=False)
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                query = """
                    SELECT dh.MaDonHang, dh.NgayDat, dh.TrangThai, dh.TongTien,
                           nd.HoTen, nd.Sdt, nd.DiaChi
                    FROM DonHang dh
                    LEFT JOIN NguoiDung nd ON dh.MaTaiKhoan = nd.MaTaiKhoan
                    WHERE dh.MaDonHang = ?
                """
                
                cursor.execute(query, order_id)
                row = cursor.fetchone()
                cursor.close()
            
            if not row:
                return json.dumps({
                    "error": f"Không tìm thấy đơn hàng với mã {order_id}"
                }, ensure_ascii=False)
            
            ma_don_hang, ngay_dat, trang_thai, tong_tien, ho_ten, sdt, dia_chi = row
            
            result = {
                "maDonHang": ma_don_hang,
                "ngayDat": ngay_dat.strftime("%d/%m/%Y %H:%M") if ngay_dat else None,
                "trangThai": trang_thai,
                "tongTien": float(tong_tien) if tong_tien else 0,
                "khachHang": {
                    "hoTen": ho_ten,
                    "sdt": sdt,
                    "diaChi": dia_chi
                }
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_order_status: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy trạng thái đơn hàng: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_customer_orders(self, args: Dict[str, Any]) -> str:
        """Lấy danh sách đơn hàng của khách hàng"""
        try:
            customer_id = args.get("customerId")
            customer_email = args.get("customerEmail")
            limit = args.get("limit", 10)
            
            if not customer_id and not customer_email:
                return json.dumps({
                    "error": "Cần cung cấp customerId hoặc customerEmail"
                }, ensure_ascii=False)
            
            if not isinstance(limit, int) or limit < 1:
                limit = 10
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                if customer_id:
                    # Nếu limit >= 100, lấy tất cả đơn hàng (không dùng TOP)
                    if limit >= 100:
                        query = """
                            SELECT dh.MaDonHang, dh.NgayDat, dh.TrangThai, dh.TongTien
                            FROM DonHang dh
                            WHERE dh.MaTaiKhoan = ?
                            ORDER BY dh.NgayDat DESC
                        """
                    else:
                        query = f"""
                            SELECT TOP {limit}
                                dh.MaDonHang, dh.NgayDat, dh.TrangThai, dh.TongTien
                            FROM DonHang dh
                            WHERE dh.MaTaiKhoan = ?
                            ORDER BY dh.NgayDat DESC
                        """
                    cursor.execute(query, customer_id)
                else:
                    query = f"""
                        SELECT TOP {limit}
                            dh.MaDonHang, dh.NgayDat, dh.TrangThai, dh.TongTien
                        FROM DonHang dh
                        INNER JOIN NguoiDung nd ON dh.MaTaiKhoan = nd.MaTaiKhoan
                        WHERE nd.Email = ?
                        ORDER BY dh.NgayDat DESC
                    """
                    cursor.execute(query, customer_email)
                
                rows = cursor.fetchall()
                cursor.close()
            
            orders = []
            for row in rows:
                ma_don_hang, ngay_dat, trang_thai, tong_tien = row
                orders.append({
                    "maDonHang": ma_don_hang,
                    "ngayDat": ngay_dat.strftime("%d/%m/%Y %H:%M") if ngay_dat else None,
                    "trangThai": trang_thai,
                    "tongTien": float(tong_tien) if tong_tien else 0
                })
            
            result = {
                "totalOrders": len(orders),
                "orders": orders
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_customer_orders: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy danh sách đơn hàng: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_top_products(self, args: Dict[str, Any]) -> str:
        """Lấy danh sách sản phẩm bán chạy nhất"""
        try:
            limit = args.get("limit", 10)
            if not isinstance(limit, int) or limit < 1:
                limit = 10
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                query = f"""
                    SELECT TOP {limit}
                        s.MaSanPham, s.TenSanPham, s.GiaBan, s.SoLuongTon,
                        ISNULL(SUM(ct.SoLuong), 0) as TongBan
                    FROM SanPham s
                    LEFT JOIN ChiTietDonHang ct ON s.MaSanPham = ct.MaSanPham
                    WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                    GROUP BY s.MaSanPham, s.TenSanPham, s.GiaBan, s.SoLuongTon
                    ORDER BY TongBan DESC
                """
                
                cursor.execute(query)
                rows = cursor.fetchall()
                cursor.close()
            
            products = []
            for row in rows:
                ma_san_pham, ten_san_pham, gia_ban, so_luong_ton, tong_ban = row
                products.append({
                    "maSanPham": ma_san_pham,
                    "tenSanPham": ten_san_pham,
                    "giaBan": float(gia_ban) if gia_ban else 0,
                    "soLuongTon": so_luong_ton if so_luong_ton else 0,
                    "tongBan": tong_ban if tong_ban else 0
                })
            
            result = {
                "totalProducts": len(products),
                "products": products
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_top_products: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy danh sách sản phẩm bán chạy: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_inventory_status(self, args: Dict[str, Any]) -> str:
        """Lấy trạng thái tồn kho"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                query = """
                    SELECT 
                        COUNT(*) as TongSanPham,
                        SUM(CASE WHEN SoLuongTon > 0 THEN 1 ELSE 0 END) as ConHang,
                        SUM(CASE WHEN SoLuongTon = 0 OR SoLuongTon IS NULL THEN 1 ELSE 0 END) as HetHang,
                        SUM(SoLuongTon) as TongSoLuong
                    FROM SanPham
                    WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
                """
                
                cursor.execute(query)
                row = cursor.fetchone()
                cursor.close()
            
            if not row:
                return json.dumps({
                    "error": "Không thể lấy thông tin tồn kho"
                }, ensure_ascii=False)
            
            tong_san_pham, con_hang, het_hang, tong_so_luong = row
            
            result = {
                "tongSanPham": tong_san_pham if tong_san_pham else 0,
                "conHang": con_hang if con_hang else 0,
                "hetHang": het_hang if het_hang else 0,
                "tongSoLuong": float(tong_so_luong) if tong_so_luong else 0
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_inventory_status: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy trạng thái tồn kho: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_category_products(self, args: Dict[str, Any]) -> str:
        """Lấy danh sách sản phẩm theo danh mục"""
        try:
            category_id = args.get("categoryId")
            category_name = args.get("categoryName")
            limit = args.get("limit", 20)
            
            if not category_id and not category_name:
                return json.dumps({
                    "error": "Cần cung cấp categoryId hoặc categoryName"
                }, ensure_ascii=False)
            
            if not isinstance(limit, int) or limit < 1:
                limit = 20
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                if category_id:
                    query = f"""
                        SELECT TOP {limit}
                            s.MaSanPham, s.TenSanPham, s.GiaBan, s.SoLuongTon, s.Anh
                        FROM SanPham s
                        WHERE s.MaDanhMuc = ? AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                        ORDER BY s.TenSanPham
                    """
                    cursor.execute(query, category_id)
                else:
                    query = f"""
                        SELECT TOP {limit}
                            s.MaSanPham, s.TenSanPham, s.GiaBan, s.SoLuongTon, s.Anh
                        FROM SanPham s
                        INNER JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                        WHERE dm.TenDanhMuc LIKE ? AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                        ORDER BY s.TenSanPham
                    """
                    cursor.execute(query, f"%{category_name}%")
                
                rows = cursor.fetchall()
                cursor.close()
            
            products = []
            base_url = os.getenv("APP_BASE_URL", "https://localhost:7240")
            
            for row in rows:
                ma_san_pham, ten_san_pham, gia_ban, so_luong_ton, anh = row
                image_url = f"{base_url}/images/products/{anh}" if anh else None
                
                products.append({
                    "maSanPham": ma_san_pham,
                    "tenSanPham": ten_san_pham,
                    "giaBan": float(gia_ban) if gia_ban else 0,
                    "soLuongTon": so_luong_ton if so_luong_ton else 0,
                    "anh": anh,
                    "anhUrl": image_url
                })
            
            result = {
                "totalProducts": len(products),
                "products": products
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_category_products: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy danh sách sản phẩm theo danh mục: {str(ex)}"
            }, ensure_ascii=False)
    
    async def _get_active_promotions(self, args: Dict[str, Any]) -> str:
        """
        Lấy danh sách khuyến mãi đang hoạt động
        Bao gồm: khuyến mãi cho sản phẩm cụ thể và khuyến mãi cho tất cả sản phẩm
        """
        try:
            product_id = args.get("productId")  # Optional: lọc theo sản phẩm cụ thể
            limit = args.get("limit", 20)
            
            if not isinstance(limit, int) or limit < 1:
                limit = 20
            
            with self._get_connection() as conn:
                cursor = conn.cursor()
                
                # Query lấy khuyến mãi đang hoạt động
                if product_id:
                    # Lấy khuyến mãi cho sản phẩm cụ thể hoặc khuyến mãi cho tất cả (MaSanPham = 'ALL')
                    query = """
                        SELECT TOP (?)
                            km.Id_sale,
                            km.GiaTriKhuyenMai,
                            ISNULL(km.LoaiGiaTri, 'Amount') as LoaiGiaTri,
                            km.MoTaChuongTrinh,
                            km.NgayBatDau,
                            km.NgayKetThuc,
                            km.TrangThai,
                            km.MaSanPham,
                            sp.TenSanPham
                        FROM KhuyenMai km
                        LEFT JOIN SanPham sp ON km.MaSanPham = sp.MaSanPham
                        WHERE km.TrangThai = 'Active'
                            AND km.NgayBatDau <= GETDATE()
                            AND km.NgayKetThuc >= GETDATE()
                            AND (km.MaSanPham = ? OR km.MaSanPham = 'ALL')
                        ORDER BY km.NgayBatDau DESC
                    """
                    cursor.execute(query, limit, product_id)
                else:
                    # Lấy tất cả khuyến mãi đang hoạt động
                    query = f"""
                        SELECT TOP {limit}
                            km.Id_sale,
                            km.GiaTriKhuyenMai,
                            ISNULL(km.LoaiGiaTri, 'Amount') as LoaiGiaTri,
                            km.MoTaChuongTrinh,
                            km.NgayBatDau,
                            km.NgayKetThuc,
                            km.TrangThai,
                            km.MaSanPham,
                            sp.TenSanPham
                        FROM KhuyenMai km
                        LEFT JOIN SanPham sp ON km.MaSanPham = sp.MaSanPham
                        WHERE km.TrangThai = 'Active'
                            AND km.NgayBatDau <= GETDATE()
                            AND km.NgayKetThuc >= GETDATE()
                        ORDER BY km.NgayBatDau DESC
                    """
                    cursor.execute(query)
                
                rows = cursor.fetchall()
                cursor.close()
            
            promotions = []
            base_url = os.getenv("APP_BASE_URL", "https://localhost:7240")
            
            for row in rows:
                id_sale, gia_tri, loai_gia_tri, mo_ta, ngay_bat_dau, ngay_ket_thuc, trang_thai, ma_san_pham, ten_san_pham = row
                
                # Tính số ngày còn lại
                now = datetime.now()
                days_remaining = (ngay_ket_thuc.date() - now.date()).days if ngay_ket_thuc else None
                
                promotions.append({
                    "idSale": id_sale,
                    "giaTriKhuyenMai": float(gia_tri) if gia_tri else 0,
                    "loaiGiaTri": loai_gia_tri if loai_gia_tri else "Amount",  # "Amount" hoặc "Percent"
                    "moTaChuongTrinh": mo_ta if mo_ta else "",
                    "ngayBatDau": ngay_bat_dau.strftime("%d/%m/%Y %H:%M") if ngay_bat_dau else None,
                    "ngayKetThuc": ngay_ket_thuc.strftime("%d/%m/%Y %H:%M") if ngay_ket_thuc else None,
                    "trangThai": trang_thai if trang_thai else "Active",
                    "maSanPham": ma_san_pham if ma_san_pham else "ALL",
                    "tenSanPham": ten_san_pham if ten_san_pham else ("Tất cả sản phẩm" if ma_san_pham == "ALL" else None),
                    "daysRemaining": days_remaining,
                    "isActive": True  # Đã filter trong query
                })
            
            result = {
                "totalPromotions": len(promotions),
                "promotions": promotions
            }
            
            return json.dumps(result, ensure_ascii=False)
            
        except Exception as ex:
            logger.error(f"Error in _get_active_promotions: {str(ex)}", exc_info=True)
            return json.dumps({
                "error": f"Lỗi khi lấy danh sách khuyến mãi: {str(ex)}"
            }, ensure_ascii=False)

