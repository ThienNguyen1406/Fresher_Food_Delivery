import 'package:fresher_food/models/Product.dart';

class ProductTraceability {
  final String maTruyXuat;
  final String maSanPham;
  final String tenSanPham;
  final String nguonGoc;
  final String nhaSanXuat;
  final String diaChiSanXuat;
  final DateTime ngaySanXuat;
  final DateTime? ngayHetHan;
  final String? nhaCungCap;
  final String? phuongTienVanChuyen;
  final DateTime? ngayNhapKho;
  final String? chungNhanChatLuong;
  final String? soChungNhan;
  final String? coQuanChungNhan;
  final String? blockchainHash;
  final String? blockchainTransactionId;
  final DateTime? ngayLuuBlockchain;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;

  ProductTraceability({
    required this.maTruyXuat,
    required this.maSanPham,
    required this.tenSanPham,
    required this.nguonGoc,
    required this.nhaSanXuat,
    required this.diaChiSanXuat,
    required this.ngaySanXuat,
    this.ngayHetHan,
    this.nhaCungCap,
    this.phuongTienVanChuyen,
    this.ngayNhapKho,
    this.chungNhanChatLuong,
    this.soChungNhan,
    this.coQuanChungNhan,
    this.blockchainHash,
    this.blockchainTransactionId,
    this.ngayLuuBlockchain,
    required this.ngayTao,
    this.ngayCapNhat,
  });

  factory ProductTraceability.fromJson(Map<String, dynamic> json) {
    return ProductTraceability(
      maTruyXuat: json['maTruyXuat']?.toString() ?? '',
      maSanPham: json['maSanPham']?.toString() ?? '',
      tenSanPham: json['tenSanPham']?.toString() ?? '',
      nguonGoc: json['nguonGoc']?.toString() ?? '',
      nhaSanXuat: json['nhaSanXuat']?.toString() ?? '',
      diaChiSanXuat: json['diaChiSanXuat']?.toString() ?? '',
      ngaySanXuat: json['ngaySanXuat'] != null
          ? DateTime.parse(json['ngaySanXuat'])
          : DateTime.now(),
      ngayHetHan: json['ngayHetHan'] != null
          ? DateTime.parse(json['ngayHetHan'])
          : null,
      nhaCungCap: json['nhaCungCap']?.toString(),
      phuongTienVanChuyen: json['phuongTienVanChuyen']?.toString(),
      ngayNhapKho: json['ngayNhapKho'] != null
          ? DateTime.parse(json['ngayNhapKho'])
          : null,
      chungNhanChatLuong: json['chungNhanChatLuong']?.toString(),
      soChungNhan: json['soChungNhan']?.toString(),
      coQuanChungNhan: json['coQuanChungNhan']?.toString(),
      blockchainHash: json['blockchainHash']?.toString(),
      blockchainTransactionId: json['blockchainTransactionId']?.toString(),
      ngayLuuBlockchain: json['ngayLuuBlockchain'] != null
          ? DateTime.parse(json['ngayLuuBlockchain'])
          : null,
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
      'maTruyXuat': maTruyXuat,
      'maSanPham': maSanPham,
      'tenSanPham': tenSanPham,
      'nguonGoc': nguonGoc,
      'nhaSanXuat': nhaSanXuat,
      'diaChiSanXuat': diaChiSanXuat,
      'ngaySanXuat': ngaySanXuat.toIso8601String(),
      'ngayHetHan': ngayHetHan?.toIso8601String(),
      'nhaCungCap': nhaCungCap,
      'phuongTienVanChuyen': phuongTienVanChuyen,
      'ngayNhapKho': ngayNhapKho?.toIso8601String(),
      'chungNhanChatLuong': chungNhanChatLuong,
      'soChungNhan': soChungNhan,
      'coQuanChungNhan': coQuanChungNhan,
      'blockchainHash': blockchainHash,
      'blockchainTransactionId': blockchainTransactionId,
      'ngayLuuBlockchain': ngayLuuBlockchain?.toIso8601String(),
      'ngayTao': ngayTao.toIso8601String(),
      'ngayCapNhat': ngayCapNhat?.toIso8601String(),
    };
  }
}

class ProductTraceabilityResponse {
  final String maTruyXuat;
  final Product? productInfo;
  final ProductTraceability traceabilityInfo;
  final bool isVerified;
  final String? blockchainVerificationUrl;

  ProductTraceabilityResponse({
    required this.maTruyXuat,
    this.productInfo,
    required this.traceabilityInfo,
    required this.isVerified,
    this.blockchainVerificationUrl,
  });

  factory ProductTraceabilityResponse.fromJson(Map<String, dynamic> json) {
    return ProductTraceabilityResponse(
      maTruyXuat: json['maTruyXuat']?.toString() ?? '',
      productInfo: json['productInfo'] != null
          ? Product.fromJson(json['productInfo'])
          : null,
      traceabilityInfo: ProductTraceability.fromJson(json['traceabilityInfo']),
      isVerified: json['isVerified'] ?? false,
      blockchainVerificationUrl: json['blockchainVerificationUrl']?.toString(),
    );
  }
}
