import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MomoWebView extends StatefulWidget {
  final double amount;
  final String orderId;
  final Function(bool) onPaymentCompleted;

  const MomoWebView({
    super.key,
    required this.amount,
    required this.orderId,
    required this.onPaymentCompleted,
  });

  @override
  State<MomoWebView> createState() => _MomoWebViewState();
}

class _MomoWebViewState extends State<MomoWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final paymentUrl = _buildMoMoPaymentUrl(widget.amount, widget.orderId);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onUrlChange: (UrlChange change) {
            _handleUrlChange(change.url ?? '');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            _handlePaymentError();
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  String _buildMoMoPaymentUrl(double amount, String orderId) {
    return 'https://your-payment-gateway.com/momo/payment?'
        'amount=${amount.toInt()}&'
        'orderId=$orderId&'
        // 'customerName=${Uri.encodeComponent(_nameController.text)}&'
        // 'customerPhone=${_phoneController.text}&'
        'returnUrl=https://your-domain.com/success&'
        'cancelUrl=https://your-domain.com/cancel';
  }

  void _handleUrlChange(String url) {
    print('URL changed: $url');

    if (url.contains('success') ||
        url.contains('thanh-cong') ||
        url.contains('completed')) {
      widget.onPaymentCompleted(true);
      Navigator.of(context).pop();
    } else if (url.contains('cancel') ||
        url.contains('error') ||
        url.contains('that-bai')) {
      widget.onPaymentCompleted(false);
      Navigator.of(context).pop();
    }
  }

  void _handlePaymentError() {
    widget.onPaymentCompleted(false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán MoMo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onPaymentCompleted(false);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}