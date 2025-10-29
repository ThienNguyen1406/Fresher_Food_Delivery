class User {
  final String maTaiKhoan;
  final String tenNguoiDung;
  final String matKhau;
  final String email;
  final String hoTen;
  final String sdt;
  final String diaChi;
  final String vaiTro;

  User({
    required this.maTaiKhoan,
    required this.tenNguoiDung,
    required this.matKhau,
    required this.email,
    required this.hoTen,
    required this.sdt,
    required this.diaChi,
    required this.vaiTro,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maTaiKhoan: json['maTaiKhoan']?.toString() ?? '',
      tenNguoiDung: json['tenNguoiDung']?.toString() ?? '',
      matKhau: json['matKhau']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      hoTen: json['hoTen']?.toString() ?? '',
      sdt: json['sdt']?.toString() ?? '',
      diaChi: json['diaChi']?.toString() ?? '',
      vaiTro: json['vaiTro']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTaiKhoan': maTaiKhoan,
      'tenNguoiDung': tenNguoiDung,
      'matKhau': matKhau,
      'email': email,
      'hoTen': hoTen,
      'sdt': sdt,
      'diaChi': diaChi,
      'vaiTro': vaiTro,
    };
  }
}
