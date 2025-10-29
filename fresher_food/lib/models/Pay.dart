class Pay
 {
     final String Id_Pay;
     final String Pay_name;

      Pay({
          required this.Id_Pay,
          required this.Pay_name,
      });

      factory Pay.fromJson(Map<String, dynamic> json) {
          return Pay(
              Id_Pay: json['id_Pay']?.toString() ?? '',
              Pay_name: json['pay_name']?.toString() ?? '',
          );
      }
 }