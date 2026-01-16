class Sale {
  final String idSale;
  final double giaTriKhuyenMai;
  final String loaiGiaTri; // "Amount" hoặc "Percent"
  final String? moTaChuongTrinh;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final String? trangThai;
  final String maSanPham;
  final String? tenSanPham; // Tên sản phẩm (optional, for display)

  Sale({
    required this.idSale,
    required this.giaTriKhuyenMai,
    this.loaiGiaTri = 'Amount', // Default là Amount
    this.moTaChuongTrinh,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.trangThai,
    required this.maSanPham,
    this.tenSanPham,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      idSale: json['id_sale']?.toString() ?? 
              json['idSale']?.toString() ?? 
              json['Id_sale']?.toString() ?? '',
      giaTriKhuyenMai: (json['giaTriKhuyenMai'] is num)
          ? (json['giaTriKhuyenMai'] as num).toDouble()
          : (json['GiaTriKhuyenMai'] is num)
              ? (json['GiaTriKhuyenMai'] as num).toDouble()
              : 0.0,
      moTaChuongTrinh: json['moTaChuongTrinh']?.toString() ?? 
                       json['MoTaChuongTrinh']?.toString(),
      ngayBatDau: json['ngayBatDau'] != null
          ? DateTime.parse(json['ngayBatDau'])
          : json['NgayBatDau'] != null
              ? DateTime.parse(json['NgayBatDau'])
              : DateTime.now(),
      ngayKetThuc: json['ngayKetThuc'] != null
          ? DateTime.parse(json['ngayKetThuc'])
          : json['NgayKetThuc'] != null
              ? DateTime.parse(json['NgayKetThuc'])
              : DateTime.now(),
      trangThai: json['trangThai']?.toString() ?? 
                 json['TrangThai']?.toString(),
      maSanPham: json['maSanPham']?.toString() ?? 
                 json['MaSanPham']?.toString() ?? '',
      tenSanPham: json['tenSanPham']?.toString() ?? 
                  json['TenSanPham']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_sale': idSale,
      'giaTriKhuyenMai': giaTriKhuyenMai,
      'loaiGiaTri': loaiGiaTri,
      'moTaChuongTrinh': moTaChuongTrinh,
      'ngayBatDau': ngayBatDau.toIso8601String(),
      'ngayKetThuc': ngayKetThuc.toIso8601String(),
      'trangThai': trangThai ?? 'Active',
      'maSanPham': maSanPham,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return trangThai == 'Active' &&
        now.isAfter(ngayBatDau) &&
        now.isBefore(ngayKetThuc);
  }

  bool get isExpired {
    return DateTime.now().isAfter(ngayKetThuc);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(ngayBatDau);
  }
}

