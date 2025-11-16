import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fresher_food/services/api/traceability_api.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:fresher_food/utils/config.dart';
import 'package:fresher_food/utils/app_localizations.dart';

class QRCodeDialog extends StatefulWidget {
  final String productId;
  final String productName;

  const QRCodeDialog({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  String? _traceabilityId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTraceabilityInfo();
  }

  Future<void> _loadTraceabilityInfo() async {
    try {
      final traceabilityApi = TraceabilityApi();

      // Gọi API để lấy MaTruyXuat từ product ID
      final result =
          await traceabilityApi.getTraceabilityByProductId(widget.productId);

      if (result != null && result['maTruyXuat'] != null) {
        setState(() {
          _isLoading = false;
          _traceabilityId = result['maTruyXuat'].toString();
        });
      } else {
        // Nếu chưa có traceability info, vẫn hiển thị QR code với product ID
        // Người dùng có thể quét để xem thông báo
        setState(() {
          _isLoading = false;
          _traceabilityId = widget.productId; // Fallback
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Vẫn hiển thị QR code với product ID làm fallback
        _traceabilityId = widget.productId;
      });
    }
  }

  String _getQRCodeUrl() {
    // Sử dụng publicBaseUrl để QR code có thể quét từ mọi thiết bị
    final publicUrl = AppConfig.publicBaseUrl;

    if (_traceabilityId != null) {
      // URL công khai để quét QR code và xem thông tin truy xuất
      return '$publicUrl/api/Traceability/qr/$_traceabilityId';
    }
    // Fallback: sử dụng product ID
    return '$publicUrl/api/Traceability/qr/${widget.productId}';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.qrCodeTraceability,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? localizations.cannotLoadTraceability,
                      style: TextStyle(color: Colors.red.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Product name
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: _getQRCodeUrl(),
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instruction text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localizations.scanQRToViewOrigin,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
