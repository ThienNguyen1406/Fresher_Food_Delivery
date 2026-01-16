// models/order.dart
class Order {
  final String maDonHang;
  final String maTaiKhoan;
  final DateTime ngayDat;
  final String trangThai;
  final String? diaChiGiaoHang;
  final String? soDienThoai;
  final String? ghiChu;
  final String? phuongThucThanhToan;
  final String trangThaiThanhToan;
  final String id_PhieuGiamGia;
  final String id_Pay;

  Order({
    required this.maDonHang,
    required this.maTaiKhoan,
    required this.ngayDat,
    required this.trangThai,
    this.diaChiGiaoHang,
    this.soDienThoai,
    this.ghiChu,
    this.phuongThucThanhToan,
    required this.trangThaiThanhToan,
    required this.id_PhieuGiamGia,
    required this.id_Pay,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      maDonHang: json['maDonHang'] ?? '',
      maTaiKhoan: json['maTaiKhoan'] ?? '',
      ngayDat: DateTime.parse(json['ngayDat']),
      trangThai: json['trangThai'] ?? '',
      diaChiGiaoHang: json['diaChiGiaoHang'],
      soDienThoai: json['soDienThoai'],
      ghiChu: json['ghiChu'],
      phuongThucThanhToan: json['phuongThucThanhToan'],
      trangThaiThanhToan: json['trangThaiThanhToan'] ?? '',
      id_PhieuGiamGia: json['id_phieugiamgia'] ?? '',
      id_Pay: json['id_Pay'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDonHang': maDonHang,
      'maTaiKhoan': maTaiKhoan,
      'ngayDat': ngayDat.toIso8601String(),
      'trangThai': trangThai,
      'diaChiGiaoHang': diaChiGiaoHang,
      'soDienThoai': soDienThoai,
      'ghiChu': ghiChu,
      'phuongThucThanhToan': phuongThucThanhToan,
      'trangThaiThanhToan': trangThaiThanhToan,
      'id_PhieuGiamGia': id_PhieuGiamGia,
      'id_Pay': id_Pay,
    };
  }
}

class OrderDetail {
  final String maDonHang;
  final String maSanPham;
  final String tenSanPham;
  final double giaBan;
  final int soLuong;

  OrderDetail({
    required this.maDonHang,
    required this.maSanPham,
    required this.tenSanPham,
    required this.giaBan,
    required this.soLuong,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      maDonHang: json['maDonHang'] ?? '',
      maSanPham: json['maSanPham'] ?? '',
      tenSanPham: json['tenSanPham'] ?? '',
      giaBan: (json['giaBan'] ?? 0).toDouble(),
      soLuong: json['soLuong'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDonHang': maDonHang,
      'maSanPham': maSanPham,
      'tenSanPham': tenSanPham,
      'giaBan': giaBan,
      'soLuong': soLuong,
    };
  }
}