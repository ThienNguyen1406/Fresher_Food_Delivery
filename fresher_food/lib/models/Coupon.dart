class PhieuGiamGia {
  final String idPhieuGiamGia;
  final String code;
  final double giaTri;
  final String moTa;

  const PhieuGiamGia({
    required this.idPhieuGiamGia,
    required this.code,
    required this.giaTri,
    required this.moTa,
  });

  factory PhieuGiamGia.fromJson(Map<String, dynamic> json) {
    return PhieuGiamGia(
      idPhieuGiamGia: json['id_phieugiamgia']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      giaTri: (json['giaTri'] is num) ? (json['giaTri'] as num).toDouble() : 0.0,
      moTa: json['moTa']?.toString() ?? '',
    );
  }
}