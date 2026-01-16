class Category {
  final String maDanhMuc;
  final String tenDanhMuc;
  final String icon;

  Category({
    required this.maDanhMuc,
    required this.tenDanhMuc,
    required this.icon,
  });

factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      maDanhMuc: json['maDanhMuc']?.toString() ?? '',
      tenDanhMuc: json['tenDanhMuc']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDanhMuc': maDanhMuc,
      'tenDanhMuc': tenDanhMuc,
      'icon': icon,
    };
  }
}