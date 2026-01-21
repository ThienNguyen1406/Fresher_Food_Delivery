"""
Function Handler Service - Xử lý function calling từ AI
Kết nối với SQL Server để lấy dữ liệu real-time
Phiên bản cải tiến với error handling tốt hơn và nhiều function hơn
"""
import json
import logging
import os
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from contextlib import contextmanager
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
        if not connection_string:
            raise ValueError("Connection string không được để trống")
        self.connection_string = connection_string
        logger.info("FunctionHandler initialized successfully")
    
    @contextmanager
    def _get_connection(self):
        """Context manager để quản lý database connection"""
        conn = None
        try:
            conn = pyodbc.connect(self.connection_string)
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
        
        Args:
            function_name: Tên function cần thực thi
            arguments: Arguments của function (dictionary)
            
        Returns:
            JSON string chứa kết quả
        """
        try:
            logger.info(f"Executing function: {function_name} with arguments: {arguments}")
            
            # Mapping các function names
            function_map = {
                "getProductExpiry": self._get_product_expiry,
                "getProductsExpiringSoon": self._get_products_expiring_soon,
                "getMonthlyRevenue": self._get_monthly_revenue,
                "getRevenueStatistics": self._get_revenue_statistics,
                "getBestSellingProductImage": self._get_best_selling_product_image,
                "getProductInfo": self._get_product_info,
                "getOrderStatus": self._get_order_status,
                "getCustomerOrders": self._get_customer_orders,
                "getTopProducts": self._get_top_products,
                "getInventoryStatus": self._get_inventory_status,
                "getCategoryProducts": self._get_category_products,
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
            for row in rows:
                ma_san_pham, ten_san_pham, anh, gia_ban, so_luong_ton, tong_ban = row
                
                image_url = None
                if anh:
                    image_url = f"{base_url}/images/products/{anh}"
                
                products.append({
                    "maSanPham": ma_san_pham,
                    "tenSanPham": ten_san_pham,
                    "anh": anh,
                    "anhUrl": image_url,
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
                else:
                    query = """
                        SELECT s.MaSanPham, s.TenSanPham, s.MoTa, s.GiaBan, s.SoLuongTon, 
                               s.DonViTinh, s.Anh, s.NgaySanXuat, s.NgayHetHan,
                               dm.TenDanhMuc
                        FROM SanPham s
                        LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                        WHERE s.TenSanPham LIKE ? AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                        ORDER BY s.TenSanPham
                    """
                    cursor.execute(query, f"%{product_name}%")
                
                row = cursor.fetchone()
                cursor.close()
            
            if not row:
                return json.dumps({
                    "error": f"Không tìm thấy sản phẩm '{product_name or product_id}'"
                }, ensure_ascii=False)
            
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

