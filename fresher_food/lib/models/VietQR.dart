class VietQRRequest {
  final String maDonHang;
  final double soTien;
  final String? noiDung;

  VietQRRequest({
    required this.maDonHang,
    required this.soTien,
    this.noiDung,
  });

  Map<String, dynamic> toJson() {
    return {
      'maDonHang': maDonHang,
      'soTien': soTien,
      'noiDung': noiDung,
    };
  }
}

class VietQRResponse {
  final String qrData;
  final String soTaiKhoan;
  final String tenChuTaiKhoan;
  final String tenNganHang;
  final String maNganHang;
  final double soTien;
  final String noiDung;

  VietQRResponse({
    required this.qrData,
    required this.soTaiKhoan,
    required this.tenChuTaiKhoan,
    required this.tenNganHang,
    required this.maNganHang,
    required this.soTien,
    required this.noiDung,
  });

  factory VietQRResponse.fromJson(Map<String, dynamic> json) {
    return VietQRResponse(
      qrData: json['qrData'] ?? '',
      soTaiKhoan: json['soTaiKhoan'] ?? '',
      tenChuTaiKhoan: json['tenChuTaiKhoan'] ?? '',
      tenNganHang: json['tenNganHang'] ?? '',
      maNganHang: json['maNganHang'] ?? '',
      soTien: (json['soTien'] ?? 0).toDouble(),
      noiDung: json['noiDung'] ?? '',
    );
  }
}
