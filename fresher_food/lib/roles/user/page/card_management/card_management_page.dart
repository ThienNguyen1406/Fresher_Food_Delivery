import 'package:flutter/material.dart';
import 'package:fresher_food/models/SavedCard.dart';
import 'package:fresher_food/services/api/stripe_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/user/page/card_management/add_card_page.dart';

class CardManagementPage extends StatefulWidget {
  const CardManagementPage({super.key});

  @override
  State<CardManagementPage> createState() => _CardManagementPageState();
}

class _CardManagementPageState extends State<CardManagementPage> {
  final StripeApi _stripeApi = StripeApi();
  List<SavedCard> _savedCards = [];
  bool _isLoading = true;
  String? _error;

  final Color _primaryColor = const Color(0xFF10B981);
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userInfo = await UserApi().getUserInfo();
      final userId = userInfo['maTaiKhoan'] ?? '';
      
      if (userId.isEmpty) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final cards = await _stripeApi.getSavedCards(userId);
      setState(() {
        _savedCards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCard(SavedCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thẻ'),
        content: Text('Bạn có chắc chắn muốn xóa thẻ ${card.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _stripeApi.deleteSavedCard(card.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thẻ thành công')),
          );
          _loadSavedCards();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa thẻ: $e')),
          );
        }
      }
    }
  }

  Future<void> _setDefaultCard(SavedCard card) async {
    try {
      final userInfo = await UserApi().getUserInfo();
      final userId = userInfo['maTaiKhoan'] ?? '';
      
      await _stripeApi.setDefaultCard(card.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đặt thẻ làm mặc định')),
        );
        _loadSavedCards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đặt thẻ mặc định: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Quản lý thẻ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: _textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: $_error',
                        style: TextStyle(color: _textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSavedCards,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _savedCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_off, size: 64, color: _textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có thẻ nào được lưu',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút + để thêm thẻ mới',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSavedCards,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _savedCards.length,
                        itemBuilder: (context, index) {
                          final card = _savedCards[index];
                          return _buildCardItem(card);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCard,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm thẻ mới'),
      ),
    );
  }

  Future<void> _addNewCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardPage(
          onCardAdded: () {
            _loadSavedCards();
          },
        ),
      ),
    );
    
    if (result == true) {
      _loadSavedCards();
    }
  }

  Widget _buildCardItem(SavedCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.credit_card,
            color: _primaryColor,
          ),
        ),
        title: Text(
          card.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Hết hạn: ${card.expiryDate}',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
            if (card.cardholderName != null) ...[
              const SizedBox(height: 2),
              Text(
                card.cardholderName!,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (card.isDefault) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mặc định',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: _textSecondary),
          itemBuilder: (context) => [
            if (!card.isDefault)
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Đặt làm mặc định'),
                  ],
                ),
                onTap: () => _setDefaultCard(card),
              ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa thẻ', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _deleteCard(card),
            ),
          ],
        ),
      ),
    );
  }
}

