// models/cart.dart

class CartItem {
  final String maGioHang;
  final String maSanPham;
  final int soLuong;
  final String tenSanPham;
  final double giaBan;
  final String anh;
  final int soLuongTon;
  final String tenDanhMuc;
  final String maTaiKhoan;
  final double thanhTien;
  bool isSelected;

  CartItem({
    required this.maGioHang,
    required this.maSanPham,
    required this.soLuong,
    required this.tenSanPham,
    required this.giaBan,
    required this.anh,
    required this.soLuongTon,
    required this.tenDanhMuc,
    required this.maTaiKhoan,
    required this.thanhTien,
    this.isSelected = false, // Mặc định là false
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      maGioHang: json['maGioHang']?.toString() ?? '',
      maSanPham: json['maSanPham']?.toString() ?? '',
      soLuong: json['soLuong'] ?? 0,
      tenSanPham: json['tenSanPham']?.toString() ?? '',
      giaBan: (json['giaBan'] ?? 0).toDouble(),
      anh: json['anh']?.toString() ?? '',
      soLuongTon: json['soLuongTon'] ?? 0,
      tenDanhMuc: json['tenDanhMuc']?.toString() ?? '',
      maTaiKhoan: json['maTaiKhoan']?.toString() ?? '',
      thanhTien: (json['thanhTien'] ?? 0).toDouble(),
      isSelected: json['isSelected'] ?? false, // Thêm từ JSON nếu có
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maGioHang': maGioHang,
      'maSanPham': maSanPham,
      'soLuong': soLuong,
      'tenSanPham': tenSanPham,
      'giaBan': giaBan,
      'anh': anh,
      'soLuongTon': soLuongTon,
      'tenDanhMuc': tenDanhMuc,
      'maTaiKhoan': maTaiKhoan,
      'thanhTien': thanhTien,
      'isSelected': isSelected, // Thêm vào JSON
    };
  }

  // Tạo bản sao với các thuộc tính có thể thay đổi
  CartItem copyWith({
    String? maGioHang,
    String? maSanPham,
    int? soLuong,
    String? tenSanPham,
    double? giaBan,
    String? anh,
    int? soLuongTon,
    String? tenDanhMuc,
    String? maTaiKhoan,
    double? thanhTien,
    bool? isSelected,
  }) {
    return CartItem(
      maGioHang: maGioHang ?? this.maGioHang,
      maSanPham: maSanPham ?? this.maSanPham,
      soLuong: soLuong ?? this.soLuong,
      tenSanPham: tenSanPham ?? this.tenSanPham,
      giaBan: giaBan ?? this.giaBan,
      anh: anh ?? this.anh,
      soLuongTon: soLuongTon ?? this.soLuongTon,
      tenDanhMuc: tenDanhMuc ?? this.tenDanhMuc,
      maTaiKhoan: maTaiKhoan ?? this.maTaiKhoan,
      thanhTien: thanhTien ?? this.thanhTien,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class CartResponse {
  final String maTaiKhoan;
  final double tongTien;
  final int tongSoLuong;
  final List<CartItem> sanPham;

  CartResponse({
    required this.maTaiKhoan,
    required this.tongTien,
    required this.tongSoLuong,
    required this.sanPham,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> sanPhamData = json['sanPham'] ?? [];
    return CartResponse(
      maTaiKhoan: json['maTaiKhoan']?.toString() ?? '',
      tongTien: (json['tongTien'] ?? 0).toDouble(),
      tongSoLuong: json['tongSoLuong'] ?? 0,
      sanPham: sanPhamData.map((item) => CartItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTaiKhoan': maTaiKhoan,
      'tongTien': tongTien,
      'tongSoLuong': tongSoLuong,
      'sanPham': sanPham.map((item) => item.toJson()).toList(),
    };
  }
}