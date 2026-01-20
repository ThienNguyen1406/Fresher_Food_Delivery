import 'package:flutter/material.dart';

/// ScreenSize Utility - Quản lý kích thước màn hình và responsive design
/// Truyền qua các component để tránh overflow khi chuyển device
class ScreenSize {
  final double width;
  final double height;
  final double devicePixelRatio;
  final Orientation orientation;

  ScreenSize({
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.orientation,
  });

  /// Tạo ScreenSize từ BuildContext
  factory ScreenSize.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ScreenSize(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      orientation: mediaQuery.orientation,
    );
  }

  /// Tạo ScreenSize từ MediaQuery
  factory ScreenSize.fromMediaQuery(MediaQueryData mediaQuery) {
    return ScreenSize(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      orientation: mediaQuery.orientation,
    );
  }

  /// Kiểm tra xem có phải tablet không (width >= 600)
  bool get isTablet => width >= 600;

  /// Kiểm tra xem có phải phone không
  bool get isPhone => width < 600;

  /// Kiểm tra xem có phải landscape không
  bool get isLandscape => orientation == Orientation.landscape;

  /// Kiểm tra xem có phải portrait không
  bool get isPortrait => orientation == Orientation.portrait;

  /// Lấy số cột phù hợp cho grid
  int getGridColumnCount({int phoneColumns = 2, int tabletColumns = 3}) {
    if (isTablet) {
      return isLandscape ? tabletColumns + 1 : tabletColumns;
    }
    return phoneColumns;
  }

  /// Tính toán aspect ratio cho product card dựa trên screen size
  double getProductCardAspectRatio() {
    // Base aspect ratio - tăng lên để có nhiều không gian hơn cho content
    double baseRatio = 0.68;
    
    // Điều chỉnh theo width
    if (width < 360) {
      // Màn hình nhỏ (như iPhone SE)
      return 0.65;
    } else if (width < 400) {
      // Màn hình trung bình
      return 0.67;
    } else if (width >= 600) {
      // Tablet
      return isLandscape ? 0.75 : 0.70;
    }
    
    return baseRatio;
  }

  /// Tính toán height cho product image dựa trên screen size
  double getProductImageHeight() {
    if (isTablet) {
      return isLandscape ? 130 : 140;
    }
    
    // Phone - giảm height để có nhiều không gian cho content
    if (width < 360) {
      return 95; // Màn hình nhỏ
    } else if (width < 400) {
      return 105;
    }
    
    return 115; // Mặc định - giảm từ 120 xuống 115
  }

  /// Tính toán padding dựa trên screen size
  EdgeInsets getProductCardPadding() {
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    }
    
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
    
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 8); // Giảm vertical padding
  }

  /// Tính toán font size dựa trên screen size
  double getProductNameFontSize() {
    if (isTablet) {
      return 14;
    }
    
    if (width < 360) {
      return 12;
    }
    
    return 13;
  }

  /// Tính toán spacing dựa trên screen size
  double getSpacing({double base = 8.0}) {
    if (isTablet) {
      return base * 1.2;
    }
    
    if (width < 360) {
      return base * 0.8;
    }
    
    return base;
  }

  /// Copy với các giá trị mới
  ScreenSize copyWith({
    double? width,
    double? height,
    double? devicePixelRatio,
    Orientation? orientation,
  }) {
    return ScreenSize(
      width: width ?? this.width,
      height: height ?? this.height,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      orientation: orientation ?? this.orientation,
    );
  }

  @override
  String toString() {
    return 'ScreenSize(width: $width, height: $height, orientation: $orientation, isTablet: $isTablet)';
  }
}

/// Extension để dễ dàng lấy ScreenSize từ BuildContext
extension ScreenSizeExtension on BuildContext {
  ScreenSize get screenSize => ScreenSize.fromContext(this);
  
  /// Lấy width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Lấy height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Kiểm tra tablet
  bool get isTablet => screenWidth >= 600;
  
  /// Kiểm tra phone
  bool get isPhone => screenWidth < 600;
}

