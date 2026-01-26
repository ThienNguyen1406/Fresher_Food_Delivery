import 'package:flutter/material.dart';
import 'package:fresher_food/models/SavedCard.dart';

class SavedCardSelector extends StatelessWidget {
  final List<SavedCard> savedCards;
  final SavedCard? selectedCard;
  final Function(SavedCard?) onCardSelected;
  final Function() onAddNewCard;
  final bool showNewCardForm; // Trạng thái đang hiển thị form thẻ mới
  final Function()? onBackToSavedCards; // Callback để quay lại chọn thẻ đã lưu
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;

  const SavedCardSelector({
    super.key,
    required this.savedCards,
    this.selectedCard,
    required this.onCardSelected,
    required this.onAddNewCard,
    this.showNewCardForm = false,
    this.onBackToSavedCards,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn thẻ thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (showNewCardForm)
            // Hiển thị thông báo và nút quay lại khi đang show form thẻ mới
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang nhập thông tin thẻ mới',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onBackToSavedCards,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại chọn thẻ đã lưu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                  ),
                ),
              ],
            )
          else ...[
            // Hiển thị danh sách thẻ đã lưu
            if (savedCards.isEmpty)
              Text(
                'Chưa có thẻ nào được lưu',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              )
            else
              ...savedCards.map((card) => _buildCardOption(card)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddNewCard,
              icon: const Icon(Icons.add),
              label: const Text('Thêm thẻ mới'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardOption(SavedCard card) {
    final isSelected = selectedCard?.id == card.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<SavedCard>(
        value: card,
        groupValue: selectedCard,
        onChanged: (value) => onCardSelected(value),
        title: Text(
          card.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          'Hết hạn: ${card.expiryDate}${card.isDefault ? ' • Mặc định' : ''}',
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
          ),
        ),
        activeColor: primaryColor,
        dense: true,
      ),
    );
  }
}

