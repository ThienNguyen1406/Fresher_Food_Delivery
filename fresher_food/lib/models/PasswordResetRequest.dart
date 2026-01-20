class PasswordResetRequest {
  final String maYeuCau;
  final String email;
  final String? maNguoiDung;
  final String? tenNguoiDung;
  final String trangThai; // "Pending", "Approved", "Rejected"
  final DateTime ngayTao;
  final DateTime? ngayXuLy;
  final String? maAdminXuLy;

  PasswordResetRequest({
    required this.maYeuCau,
    required this.email,
    this.maNguoiDung,
    this.tenNguoiDung,
    required this.trangThai,
    required this.ngayTao,
    this.ngayXuLy,
    this.maAdminXuLy,
  });

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequest(
      maYeuCau: json['maYeuCau']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      maNguoiDung: json['maNguoiDung']?.toString(),
      tenNguoiDung: json['tenNguoiDung']?.toString(),
      trangThai: json['trangThai']?.toString() ?? 'Pending',
      ngayTao: json['ngayTao'] != null
          ? DateTime.parse(json['ngayTao'].toString())
          : DateTime.now(),
      ngayXuLy: json['ngayXuLy'] != null
          ? DateTime.parse(json['ngayXuLy'].toString())
          : null,
      maAdminXuLy: json['maAdminXuLy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maYeuCau': maYeuCau,
      'email': email,
      'maNguoiDung': maNguoiDung,
      'tenNguoiDung': tenNguoiDung,
      'trangThai': trangThai,
      'ngayTao': ngayTao.toIso8601String(),
      'ngayXuLy': ngayXuLy?.toIso8601String(),
      'maAdminXuLy': maAdminXuLy,
    };
  }

  bool get isPending => trangThai == 'Pending';
  bool get isApproved => trangThai == 'Approved';
  bool get isRejected => trangThai == 'Rejected';
}

