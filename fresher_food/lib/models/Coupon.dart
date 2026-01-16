class PhieuGiamGia {
  final String idPhieuGiamGia;
  final String code;
  final double giaTri;
  final String moTa;
  final String loaiGiaTri; // "Amount" hoặc "Percent"
  final int? soLuongToiDa; // Số lượng tối đa có thể sử dụng (null = không giới hạn)
  final int soLuongDaSuDung; // Số lượng đã sử dụng

  const PhieuGiamGia({
    required this.idPhieuGiamGia,
    required this.code,
    required this.giaTri,
    required this.moTa,
    this.loaiGiaTri = 'Amount', // Mặc định là số tiền cố định
    this.soLuongToiDa,
    this.soLuongDaSuDung = 0,
  });

  factory PhieuGiamGia.fromJson(Map<String, dynamic> json) {
    return PhieuGiamGia(
      idPhieuGiamGia: json['id_phieugiamgia']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      giaTri: (json['giaTri'] is num) ? (json['giaTri'] as num).toDouble() : 0.0,
      moTa: json['moTa']?.toString() ?? '',
      loaiGiaTri: json['loaiGiaTri']?.toString() ?? 'Amount',
      soLuongToiDa: json['soLuongToiDa'] != null ? int.tryParse(json['soLuongToiDa'].toString()) : null,
      soLuongDaSuDung: json['soLuongDaSuDung'] != null ? int.tryParse(json['soLuongDaSuDung'].toString()) ?? 0 : 0,
    );
  }

  // Kiểm tra xem voucher còn có thể sử dụng không
  bool get conSuDungDuoc {
    if (soLuongToiDa == null) return true; // Không giới hạn
    return soLuongDaSuDung < soLuongToiDa!;
  }
}