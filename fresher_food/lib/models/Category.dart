class Category {
  final String maDanhMuc;
  final String tenDanhMuc;
  final String icon;
  final int soLuongSanPham;

  Category({
    required this.maDanhMuc,
    required this.tenDanhMuc,
    required this.icon,
    this.soLuongSanPham = 0,
  });

factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      maDanhMuc: json['maDanhMuc']?.toString() ?? '',
      tenDanhMuc: json['tenDanhMuc']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      soLuongSanPham: json['soLuongSanPham'] != null 
          ? (json['soLuongSanPham'] is int 
              ? json['soLuongSanPham'] 
              : int.tryParse(json['soLuongSanPham'].toString()) ?? 0)
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDanhMuc': maDanhMuc,
      'tenDanhMuc': tenDanhMuc,
      'icon': icon,
      'soLuongSanPham': soLuongSanPham,
    };
  }
}