import 'package:flutter/material.dart';
import 'package:fresher_food/models/DeliveryAddress.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:fresher_food/services/api/delivery_address_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryAddressDialog extends StatefulWidget {
  final CheckoutProvider provider;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;

  const DeliveryAddressDialog({
    super.key,
    required this.provider,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<DeliveryAddressDialog> createState() => _DeliveryAddressDialogState();
}

class _DeliveryAddressDialogState extends State<DeliveryAddressDialog> {
  final DeliveryAddressApi _api = DeliveryAddressApi();
  List<DeliveryAddress> _addresses = [];
  DeliveryAddress? _selectedAddress;
  bool _isLoading = true;
  String? _maTaiKhoan;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      setState(() => _isLoading = true);
      
      // Lấy maTaiKhoan từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _maTaiKhoan = prefs.getString('maTaiKhoan');
      
      if (_maTaiKhoan == null || _maTaiKhoan!.isEmpty) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final addresses = await _api.getDeliveryAddresses(_maTaiKhoan!);
      
      // Tìm địa chỉ hiện tại đang dùng
      final currentName = widget.provider.state.name;
      final currentPhone = widget.provider.state.phone;
      final currentAddress = widget.provider.state.address;
      
      DeliveryAddress? currentMatch;
      for (var addr in addresses) {
        if (addr.hoTen == currentName && 
            addr.soDienThoai == currentPhone && 
            addr.diaChi == currentAddress) {
          currentMatch = addr;
          break;
        }
      }
      
      setState(() {
        _addresses = addresses;
        _selectedAddress = currentMatch ?? (addresses.isNotEmpty ? addresses.first : null);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.error}: $e')),
        );
      }
    }
  }

  void _selectAddress(DeliveryAddress address) {
    setState(() {
      _selectedAddress = address;
    });
    
    // Cập nhật thông tin vào provider
    widget.provider.updateName(address.hoTen);
    widget.provider.updatePhone(address.soDienThoai);
    widget.provider.updateAddress(address.diaChi);
    
    Navigator.pop(context);
  }

  void _showAddEditDialog({DeliveryAddress? address}) {
    final nameController = TextEditingController(text: address?.hoTen ?? '');
    final phoneController = TextEditingController(text: address?.soDienThoai ?? '');
    final addressController = TextEditingController(text: address?.diaChi ?? '');
    bool isDefault = address?.laDiaChiMacDinh ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(address == null ? 'Thêm địa chỉ mới' : 'Sửa địa chỉ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    border: OutlineInputBorder(),
                  ),
                  enableInteractiveSelection: true,
                  enableSuggestions: true,
                  autocorrect: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  enableInteractiveSelection: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enableInteractiveSelection: true,
                  enableSuggestions: true,
                  autocorrect: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() => isDefault = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                  );
                  return;
                }

                try {
                  if (address == null) {
                    // Tạo mới
                    await _api.createDeliveryAddress(
                      maTaiKhoan: _maTaiKhoan!,
                      hoTen: nameController.text.trim(),
                      soDienThoai: phoneController.text.trim(),
                      diaChi: addressController.text.trim(),
                      laDiaChiMacDinh: isDefault,
                    );
                  } else {
                    // Cập nhật
                    await _api.updateDeliveryAddress(
                      maDiaChi: address.maDiaChi,
                      hoTen: nameController.text.trim(),
                      soDienThoai: phoneController.text.trim(),
                      diaChi: addressController.text.trim(),
                      laDiaChiMacDinh: isDefault,
                    );
                  }

                  Navigator.pop(context);
                  await _loadAddresses();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(address == null 
                            ? 'Đã thêm địa chỉ thành công' 
                            : 'Đã cập nhật địa chỉ thành công'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    final localizations = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${localizations.error}: $e')),
                    );
                  }
                }
              },
              child: Text(address == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAddress(DeliveryAddress address) async {
    final localizations = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmDelete),
        content: Text(localizations.confirmDeleteAddress),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteDeliveryAddress(address.maDiaChi);
        await _loadAddresses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa địa chỉ thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn địa chỉ giao hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _addresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: widget.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có địa chỉ nào',
                                style: TextStyle(color: widget.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            final isSelected = _selectedAddress?.maDiaChi == address.maDiaChi;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected 
                                      ? const Color(0xFF10B981) 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _selectAddress(address),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              address.hoTen,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: widget.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (address.laDiaChiMacDinh)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Mặc định',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 14,
                                            color: widget.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            address.soDienThoai,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: widget.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: widget.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              address.diaChi,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: widget.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _showAddEditDialog(address: address),
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Sửa'),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _deleteAddress(address),
                                            icon: const Icon(Icons.delete, size: 16),
                                            label: const Text('Xóa'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: widget.textSecondary.withOpacity(0.2)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm địa chỉ mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
