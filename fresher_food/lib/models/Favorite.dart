import 'package:fresher_food/models/Product.dart';
class Favorite {
  final String id;
  final String maTaiKhoan;
  final String maSanPham;
  final Product sanPham;

  Favorite({
    required this.id,
    required this.maTaiKhoan,
    required this.maSanPham,
    required this.sanPham,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id']?.toString() ?? '',
      maTaiKhoan: json['maTaiKhoan']?.toString() ?? '',
      maSanPham: json['maSanPham']?.toString() ?? '',
      sanPham: Product.fromJson(json['sanPham'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maTaiKhoan': maTaiKhoan,
      'maSanPham': maSanPham,
      'sanPham': sanPham.toJson(),
    };
  }
}