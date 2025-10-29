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
    );
  }
}