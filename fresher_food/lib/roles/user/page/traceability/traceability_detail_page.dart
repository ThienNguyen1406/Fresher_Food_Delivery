import 'package:flutter/material.dart';
import 'package:fresher_food/models/ProductTraceability.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:intl/intl.dart';

class TraceabilityDetailPage extends StatelessWidget {
  final ProductTraceabilityResponse traceabilityResponse;

  const TraceabilityDetailPage({
    Key? key,
    required this.traceabilityResponse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final traceability = traceabilityResponse.traceabilityInfo;
    final product = traceabilityResponse.productInfo;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.traceabilityInfo),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với badge verified
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade700
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.tenSanPham ?? traceability.tenSanPham,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (traceabilityResponse.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  localizations.verifiedOnBlockchain,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Product Information
            _buildSection(
              context,
              '📦 ${localizations.productInfo}',
              [
                _buildInfoRow(localizations.productCode,
                    product?.maSanPham ?? traceability.maSanPham),
                _buildInfoRow(
                    localizations.traceabilityCode, traceability.maTruyXuat),
                if (product != null)
                  _buildInfoRow(localizations.price,
                      '${product.giaBan.toStringAsFixed(0)} VND'),
              ],
            ),

            const SizedBox(height: 15),

            // Origin Information
            _buildSection(
              context,
              '🌍 ${localizations.originInfo}',
              [
                _buildInfoRow(localizations.origin, traceability.nguonGoc),
                _buildInfoRow(
                    localizations.manufacturer, traceability.nhaSanXuat),
                _buildInfoRow(localizations.manufacturingAddress,
                    traceability.diaChiSanXuat),
                _buildInfoRow(localizations.manufacturingDate,
                    dateFormat.format(traceability.ngaySanXuat)),
                if (traceability.ngayHetHan != null)
                  _buildInfoRow(localizations.expiryDate,
                      dateFormat.format(traceability.ngayHetHan!)),
              ],
            ),

            // Transport Information
            if (traceability.nhaCungCap != null) ...[
              const SizedBox(height: 15),
              _buildSection(
                context,
                '🚚 ${localizations.transportInfo}',
                [
                  _buildInfoRow(
                      localizations.supplier, traceability.nhaCungCap!),
                  if (traceability.phuongTienVanChuyen != null)
                    _buildInfoRow(localizations.transportMethod,
                        traceability.phuongTienVanChuyen!),
                  if (traceability.ngayNhapKho != null)
                    _buildInfoRow(localizations.warehouseDate,
                        dateFormat.format(traceability.ngayNhapKho!)),
                ],
              ),
            ],

            // Quality Certification
            if (traceability.chungNhanChatLuong != null) ...[
              const SizedBox(height: 15),
              _buildSection(
                context,
                '📜 ${localizations.certification}',
                [
                  _buildInfoRow(localizations.certificate,
                      traceability.chungNhanChatLuong!),
                  if (traceability.soChungNhan != null)
                    _buildInfoRow(localizations.certificateNumber,
                        traceability.soChungNhan!),
                  if (traceability.coQuanChungNhan != null)
                    _buildInfoRow(localizations.certifyingAuthority,
                        traceability.coQuanChungNhan!),
                ],
              ),
            ],

            // Blockchain Information
            if (traceability.blockchainHash != null) ...[
              const SizedBox(height: 15),
              _buildSection(
                context,
                '⛓️ ${localizations.blockchainInfo}',
                [
                  if (traceability.blockchainTransactionId != null)
                    _buildInfoRow(
                      localizations.transactionId,
                      traceability.blockchainTransactionId!,
                      isLongText: true,
                    ),
                  _buildInfoRow(
                      localizations.hash, traceability.blockchainHash!,
                      isLongText: true),
                  if (traceability.ngayLuuBlockchain != null)
                    _buildInfoRow(
                      localizations.savedDate,
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(traceability.ngayLuuBlockchain!),
                    ),
                ],
                Colors.green.shade50,
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children, [
    Color? backgroundColor,
  ]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              maxLines: isLongText ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
