class SavedCard {
  final String id;
  final String userId;
  final String paymentMethodId; // Stripe Payment Method ID
  final String last4; // 4 số cuối của thẻ
  final String brand; // Visa, Mastercard, etc.
  final int expMonth;
  final int expYear;
  final String? cardholderName;
  final DateTime createdAt;
  final bool isDefault;

  SavedCard({
    required this.id,
    required this.userId,
    required this.paymentMethodId,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
    this.cardholderName,
    required this.createdAt,
    this.isDefault = false,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as String? ?? json['Id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['MaTaiKhoan'] as String? ?? '',
      paymentMethodId: json['paymentMethodId'] as String? ?? json['PaymentMethodId'] as String? ?? '',
      last4: json['last4'] as String? ?? json['Last4'] as String? ?? '',
      brand: json['brand'] as String? ?? json['Brand'] as String? ?? 'card',
      expMonth: json['expMonth'] as int? ?? json['ExpMonth'] as int? ?? 0,
      expYear: json['expYear'] as int? ?? json['ExpYear'] as int? ?? 0,
      cardholderName: json['cardholderName'] as String? ?? json['CardholderName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['NgayTao'] != null
              ? DateTime.parse(json['NgayTao'] as String)
              : DateTime.now(),
      isDefault: json['isDefault'] as bool? ?? json['IsDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'paymentMethodId': paymentMethodId,
      'last4': last4,
      'brand': brand,
      'expMonth': expMonth,
      'expYear': expYear,
      'cardholderName': cardholderName,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  String get displayName {
    return '${brand.toUpperCase()} •••• $last4';
  }

  String get expiryDate {
    return '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

