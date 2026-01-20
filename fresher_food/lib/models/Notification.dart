class Notification {
  final String maThongBao;
  final String loaiThongBao;
  final String? maDonHang;
  final String maNguoiNhan;
  final String tieuDe;
  final String? noiDung;
  final bool daDoc;
  final DateTime ngayTao;
  final DateTime? ngayDoc;

  Notification({
    required this.maThongBao,
    required this.loaiThongBao,
    this.maDonHang,
    required this.maNguoiNhan,
    required this.tieuDe,
    this.noiDung,
    required this.daDoc,
    required this.ngayTao,
    this.ngayDoc,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      maThongBao: json['maThongBao']?.toString() ?? '',
      loaiThongBao: json['loaiThongBao']?.toString() ?? '',
      maDonHang: json['maDonHang']?.toString(),
      maNguoiNhan: json['maNguoiNhan']?.toString() ?? '',
      tieuDe: json['tieuDe']?.toString() ?? '',
      noiDung: json['noiDung']?.toString(),
      daDoc: json['daDoc'] == true || json['daDoc'] == 1,
      ngayTao: json['ngayTao'] != null
          ? DateTime.parse(json['ngayTao'].toString())
          : DateTime.now(),
      ngayDoc: json['ngayDoc'] != null
          ? DateTime.parse(json['ngayDoc'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maThongBao': maThongBao,
      'loaiThongBao': loaiThongBao,
      'maDonHang': maDonHang,
      'maNguoiNhan': maNguoiNhan,
      'tieuDe': tieuDe,
      'noiDung': noiDung,
      'daDoc': daDoc,
      'ngayTao': ngayTao.toIso8601String(),
      'ngayDoc': ngayDoc?.toIso8601String(),
    };
  }
}

