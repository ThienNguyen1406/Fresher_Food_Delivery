import 'package:fresher_food/models/User.dart';

class Chat {
  final String maChat;
  final String maNguoiDung;
  final String? maAdmin;
  final String? tieuDe;
  final String trangThai; // Open, Closed, Pending
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;
  final String? tinNhanCuoi;
  final DateTime? ngayTinNhanCuoi;
  final int? soTinNhanChuaDoc;
  final User? nguoiDung;

  Chat({
    required this.maChat,
    required this.maNguoiDung,
    this.maAdmin,
    this.tieuDe,
    required this.trangThai,
    required this.ngayTao,
    this.ngayCapNhat,
    this.tinNhanCuoi,
    this.ngayTinNhanCuoi,
    this.soTinNhanChuaDoc,
    this.nguoiDung,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      maChat: json['maChat']?.toString() ?? '',
      maNguoiDung: json['maNguoiDung']?.toString() ?? '',
      maAdmin: json['maAdmin']?.toString(),
      tieuDe: json['tieuDe']?.toString(),
      trangThai: json['trangThai']?.toString() ?? 'Open',
      ngayTao: json['ngayTao'] != null
          ? DateTime.parse(json['ngayTao'].toString())
          : DateTime.now(),
      ngayCapNhat: json['ngayCapNhat'] != null
          ? DateTime.parse(json['ngayCapNhat'].toString())
          : null,
      tinNhanCuoi: json['tinNhanCuoi']?.toString(),
      ngayTinNhanCuoi: json['ngayTinNhanCuoi'] != null
          ? DateTime.parse(json['ngayTinNhanCuoi'].toString())
          : null,
      soTinNhanChuaDoc: json['soTinNhanChuaDoc'] != null
          ? int.tryParse(json['soTinNhanChuaDoc'].toString())
          : null,
      nguoiDung: json['nguoiDung'] != null
          ? User.fromJson(json['nguoiDung'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maChat': maChat,
      'maNguoiDung': maNguoiDung,
      'maAdmin': maAdmin,
      'tieuDe': tieuDe,
      'trangThai': trangThai,
      'ngayTao': ngayTao.toIso8601String(),
      'ngayCapNhat': ngayCapNhat?.toIso8601String(),
      'tinNhanCuoi': tinNhanCuoi,
      'ngayTinNhanCuoi': ngayTinNhanCuoi?.toIso8601String(),
    };
  }
}

class Message {
  final String maTinNhan;
  final String maChat;
  final String maNguoiGui;
  final String loaiNguoiGui; // "User" or "Admin"
  final String noiDung;
  final bool daDoc;
  final DateTime ngayGui;
  final DateTime? ngayDoc;
  final User? nguoiGui;

  Message({
    required this.maTinNhan,
    required this.maChat,
    required this.maNguoiGui,
    required this.loaiNguoiGui,
    required this.noiDung,
    required this.daDoc,
    required this.ngayGui,
    this.ngayDoc,
    this.nguoiGui,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      maTinNhan: json['maTinNhan']?.toString() ?? '',
      maChat: json['maChat']?.toString() ?? '',
      maNguoiGui: json['maNguoiGui']?.toString() ?? '',
      loaiNguoiGui: json['loaiNguoiGui']?.toString() ?? 'User',
      noiDung: json['noiDung']?.toString() ?? '',
      daDoc: json['daDoc'] == true || json['daDoc'] == 1,
      ngayGui: json['ngayGui'] != null
          ? DateTime.parse(json['ngayGui'].toString())
          : DateTime.now(),
      ngayDoc: json['ngayDoc'] != null
          ? DateTime.parse(json['ngayDoc'].toString())
          : null,
      nguoiGui: json['nguoiGui'] != null
          ? User.fromJson(json['nguoiGui'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTinNhan': maTinNhan,
      'maChat': maChat,
      'maNguoiGui': maNguoiGui,
      'loaiNguoiGui': loaiNguoiGui,
      'noiDung': noiDung,
      'daDoc': daDoc,
      'ngayGui': ngayGui.toIso8601String(),
      'ngayDoc': ngayDoc?.toIso8601String(),
    };
  }

  bool get isFromUser => loaiNguoiGui == 'User';
  bool get isFromAdmin => loaiNguoiGui == 'Admin';
}

