class Product {
  final String maSanPham;
  final String tenSanPham;
  final String moTa;
  final double giaBan;
  final String anh;
  final int soLuongTon;
  final String donViTinh;
  final String xuatXu;
  final String maDanhMuc;
  final DateTime? ngaySanXuat; // Ngày sản xuất
  final DateTime? ngayHetHan; // Ngày hết hạn

  Product({
    required this.maSanPham,
    required this.tenSanPham,
    required this.moTa,
    required this.giaBan,
    required this.anh,
    required this.soLuongTon,
    required this.donViTinh,
    required this.xuatXu,
    required this.maDanhMuc,
    this.ngaySanXuat,
    this.ngayHetHan,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      maSanPham: json['maSanPham']?.toString() ?? '',
      tenSanPham: json['tenSanPham']?.toString() ?? '',
      moTa: json['moTa']?.toString() ?? '',
      giaBan: (json['giaBan'] is num) ? (json['giaBan'] as num).toDouble() : 0.0,
      anh: json['anh']?.toString() ?? '',
      soLuongTon: (json['soLuongTon'] is num) ? (json['soLuongTon'] as num).toInt() : 0,
      donViTinh: json['donViTinh']?.toString() ?? '',
      xuatXu: json['xuatXu']?.toString() ?? '',
      maDanhMuc: json['maDanhMuc']?.toString() ?? '',
      ngaySanXuat: Product._safeParseDateTime(json['ngaySanXuat']),
      ngayHetHan: Product._safeParseDateTime(json['ngayHetHan']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maSanPham': maSanPham,
      'tenSanPham': tenSanPham,
      'moTa': moTa,
      'giaBan': giaBan,
      'anh': anh,
      'soLuongTon': soLuongTon,
      'donViTinh': donViTinh,
      'xuatXu': xuatXu,
      'maDanhMuc': maDanhMuc,
      'ngaySanXuat': ngaySanXuat?.toIso8601String(),
      'ngayHetHan': ngayHetHan?.toIso8601String(),
    };
  }

  Product copyWith({int? soLuongTon}) {
    return Product(
      maSanPham: maSanPham,
      tenSanPham: tenSanPham,
      moTa: moTa,
      giaBan: giaBan,
      anh: anh,
      soLuongTon: soLuongTon ?? this.soLuongTon,
      donViTinh: donViTinh,
      xuatXu: xuatXu,
      maDanhMuc: maDanhMuc,
      ngaySanXuat: ngaySanXuat,
      ngayHetHan: ngayHetHan,
    );
  }

  // Helper method để parse DateTime an toàn
  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is String) {
        // Thử parse ISO8601 format
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      }
    } catch (e) {
      print('Lỗi parse DateTime: $value - $e');
    }
    
    return null;
  }
}