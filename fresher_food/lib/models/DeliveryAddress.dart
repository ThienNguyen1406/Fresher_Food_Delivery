class DeliveryAddress {
  final String maDiaChi;
  final String maTaiKhoan;
  final String hoTen;
  final String soDienThoai;
  final String diaChi;
  final bool laDiaChiMacDinh;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;

  DeliveryAddress({
    required this.maDiaChi,
    required this.maTaiKhoan,
    required this.hoTen,
    required this.soDienThoai,
    required this.diaChi,
    required this.laDiaChiMacDinh,
    required this.ngayTao,
    this.ngayCapNhat,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      maDiaChi: json['maDiaChi'] ?? '',
      maTaiKhoan: json['maTaiKhoan'] ?? '',
      hoTen: json['hoTen'] ?? '',
      soDienThoai: json['soDienThoai'] ?? '',
      diaChi: json['diaChi'] ?? '',
      laDiaChiMacDinh: json['laDiaChiMacDinh'] ?? false,
      ngayTao: json['ngayTao'] != null
          ? DateTime.parse(json['ngayTao'])
          : DateTime.now(),
      ngayCapNhat: json['ngayCapNhat'] != null
          ? DateTime.parse(json['ngayCapNhat'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDiaChi': maDiaChi,
      'maTaiKhoan': maTaiKhoan,
      'hoTen': hoTen,
      'soDienThoai': soDienThoai,
      'diaChi': diaChi,
      'laDiaChiMacDinh': laDiaChiMacDinh,
      'ngayTao': ngayTao.toIso8601String(),
      'ngayCapNhat': ngayCapNhat?.toIso8601String(),
    };
  }

  DeliveryAddress copyWith({
    String? maDiaChi,
    String? maTaiKhoan,
    String? hoTen,
    String? soDienThoai,
    String? diaChi,
    bool? laDiaChiMacDinh,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
  }) {
    return DeliveryAddress(
      maDiaChi: maDiaChi ?? this.maDiaChi,
      maTaiKhoan: maTaiKhoan ?? this.maTaiKhoan,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      diaChi: diaChi ?? this.diaChi,
      laDiaChiMacDinh: laDiaChiMacDinh ?? this.laDiaChiMacDinh,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
    );
  }
}
