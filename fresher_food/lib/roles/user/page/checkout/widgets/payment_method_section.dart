import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/payment_option_widget.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/add_card_dialog.dart';
import 'package:fresher_food/models/SavedCard.dart';

class PaymentMethodSection extends StatelessWidget {
  final CheckoutProvider provider;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final List<SavedCard> savedCards;
  final SavedCard? selectedCard;
  final Function(SavedCard?)? onCardSelected;
  final Function()? onAddNewCard;
  final Function()? onCardSaved;

  const PaymentMethodSection({
    super.key,
    required this.provider,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    this.savedCards = const [],
    this.selectedCard,
    this.onCardSelected,
    this.onAddNewCard,
    this.onCardSaved,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: provider.paymentMethods.map((pay) {
          final isSelected = provider.selectedPaymentId == pay.Id_Pay;
          final payName = pay.Pay_name.toLowerCase();
          final isCOD = payName.contains('cod');
          final isMoMo = payName.contains('momo');
          // Kiểm tra Stripe - mở rộng điều kiện để bắt nhiều trường hợp hơn
          final isStripe = payName.contains('stripe') || 
                          payName.contains('thẻ') || 
                          payName.contains('card') || 
                          payName.contains('credit') ||
                          payName.contains('debit') ||
                          payName.contains('tín dụng') ||
                          payName.contains('ghi nợ');
          final isBanking = payName.contains('banking') || payName.contains('bank') || payName.contains('chuyển khoản') || payName.contains('transfer');
          
          // Debug log chi tiết
          print('🔍 Payment: ${pay.Pay_name}, payName=$payName, isStripe=$isStripe, isSelected=$isSelected, selectedPaymentId=${provider.selectedPaymentId}, pay.Id_Pay=${pay.Id_Pay}, paymentMethod=${provider.paymentMethod}');

          IconData icon;
          Color color;
          String subtitle;

          if (isCOD) {
            icon = Icons.money_outlined;
            color = primaryColor;
            subtitle = 'Thanh toán bằng tiền mặt khi nhận hàng';
          } else if (isMoMo) {
            icon = Icons.phone_iphone_outlined;
            color = Colors.pink;
            subtitle = 'Thanh toán qua ứng dụng MoMo';
          } else if (isStripe) {
            icon = Icons.credit_card;
            color = Colors.blue;
            subtitle = 'Thanh toán bằng thẻ tín dụng/ghi nợ';
          } else if (isBanking) {
            icon = Icons.account_balance;
            color = Colors.purple;
            subtitle = 'Chuyển khoản qua ngân hàng';
          } else {
            icon = Icons.account_balance_outlined;
            color = accentColor;
            subtitle = pay.Pay_name.isNotEmpty
                ? 'Thanh toán qua ${pay.Pay_name}'
                : 'Thanh toán trực tuyến';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentOptionWidget(
                provider: provider,
                value: pay.Id_Pay,
                title: pay.Pay_name.isNotEmpty ? pay.Pay_name : 'Thanh toán trực tuyến',
                subtitle: subtitle,
                icon: icon,
                color: color,
                isSelected: isSelected,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                backgroundColor: backgroundColor,
              ),
              // ✅ Hiển thị dropdown chọn thẻ khi Stripe được chọn
              if (isStripe && isSelected)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _buildCardDropdown(),
                  ],
                )
              else
                const SizedBox.shrink(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chọn thẻ thanh toán',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (dropdownContext) {
              // Đảm bảo selectedCard khớp với một item trong danh sách
              // Nếu không, set thành null để tránh lỗi DropdownButton
              SavedCard? validSelectedCard;
              if (selectedCard != null && savedCards.isNotEmpty) {
                // Tìm card trong danh sách có cùng id
                try {
                  validSelectedCard = savedCards.firstWhere(
                    (card) => card.id == selectedCard!.id,
                  );
                } catch (e) {
                  // Không tìm thấy trong danh sách, set thành null
                  validSelectedCard = null;
                }
              }
              
              return DropdownButtonFormField<SavedCard?>(
                value: validSelectedCard,
                isExpanded: true,
                decoration: InputDecoration(
              filled: true,
              fillColor: surfaceColor,
              hintText: savedCards.isEmpty ? 'Chưa có thẻ, chọn "Thêm thẻ mới"' : 'Chọn thẻ thanh toán',
              hintStyle: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            selectedItemBuilder: (BuildContext context) {
              // Custom builder để hiển thị giá trị đã chọn - chỉ 1 dòng để tránh overflow
              return [
                // Option "Thêm thẻ mới"
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Thêm thẻ mới',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                // Danh sách thẻ đã lưu - chỉ hiển thị tên thẻ (1 dòng)
                ...savedCards.map((card) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.credit_card, size: 16, color: textPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${card.displayName}${card.isDefault ? ' • Mặc định' : ''}',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  );
                }),
              ];
            },
            items: [
              // Option "Thêm thẻ mới"
              DropdownMenuItem<SavedCard?>(
                value: null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Thêm thẻ mới',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Danh sách thẻ đã lưu
              ...savedCards.map((card) {
                return DropdownMenuItem<SavedCard?>(
                  value: card,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.credit_card, size: 18, color: textPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card.displayName,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hết hạn: ${card.expiryDate}${card.isDefault ? ' • Mặc định' : ''}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
                onChanged: (card) async {
                  if (card == null) {
                    // Chọn "Thêm thẻ mới" - Mở dialog
                    final savedCard = await AddCardDialog.show(
                      context: dropdownContext,
                      savedCards: savedCards,
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                    
                    // Nếu thẻ được lưu thành công, reload danh sách thẻ và chọn thẻ đó
                    if (savedCard != null) {
                      // Gọi callback để reload danh sách thẻ
                      onCardSaved?.call();
                      // Chọn thẻ vừa lưu
                      onCardSelected?.call(savedCard);
                    }
                  } else {
                    // Chọn thẻ đã lưu
                    onCardSelected?.call(card);
                  }
                },
                dropdownColor: surfaceColor,
                style: TextStyle(color: textPrimary, fontSize: 14),
                icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                itemHeight: 70, // Tăng từ 60 lên 70 để tránh overflow
              );
            },
          ),
        ],
      ),
    );
  }
}

