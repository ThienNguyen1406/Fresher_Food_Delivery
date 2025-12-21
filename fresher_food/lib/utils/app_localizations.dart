import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Vietnamese translations
  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Settings
      'settings': 'Cài đặt',
      'notifications': 'Thông báo',
      'enable_notifications': 'Bật thông báo',
      'enable_notifications_desc': 'Nhận thông báo từ ứng dụng',
      'email_notifications': 'Thông báo qua email',
      'email_notifications_desc': 'Nhận thông báo qua email',
      'push_notifications': 'Thông báo đẩy',
      'push_notifications_desc': 'Nhận thông báo đẩy trên thiết bị',
      'appearance': 'Giao diện',
      'dark_mode': 'Chế độ tối',
      'dark_mode_desc': 'Bật chế độ tối cho ứng dụng',
      'language': 'Ngôn ngữ',
      'language_desc': 'Chọn ngôn ngữ hiển thị',
      'vietnamese': 'Tiếng Việt',
      'english': 'Tiếng Anh',
      'other': 'Khác',
      'storage': 'Dữ liệu và bộ nhớ',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'create': 'Tạo',
      'retry': 'Thử lại',
      'select_language': 'Chọn ngôn ngữ',
      'light': 'Sáng',
      'dark': 'Tối',
      'system': 'Theo hệ thống',

      // Traceability & QR Code
      'traceability_info': 'Thông tin truy xuất nguồn gốc',
      'verified_on_blockchain': 'Đã xác minh trên Blockchain',
      'product_info': 'Thông tin sản phẩm',
      'product_code': 'Mã sản phẩm',
      'traceability_code': 'Mã truy xuất',
      'price': 'Giá bán',
      'origin_info': 'Nguồn gốc xuất xứ',
      'origin': 'Nguồn gốc',
      'manufacturer': 'Nhà sản xuất',
      'manufacturing_address': 'Địa chỉ sản xuất',
      'manufacturing_date': 'Ngày sản xuất',
      'expiry_date': 'Ngày hết hạn',
      'transport_info': 'Thông tin vận chuyển',
      'supplier': 'Nhà cung cấp',
      'transport_method': 'Phương tiện',
      'warehouse_date': 'Ngày nhập kho',
      'certification': 'Chứng nhận chất lượng',
      'certificate': 'Chứng nhận',
      'certificate_number': 'Số chứng nhận',
      'certifying_authority': 'Cơ quan chứng nhận',
      'blockchain_info': 'Thông tin Blockchain',
      'transaction_id': 'Transaction ID',
      'hash': 'Hash',
      'saved_date': 'Ngày lưu',
      'scan_qr_code': 'Quét QR Code',
      'point_camera_at_qr': 'Đưa camera vào QR code trên sản phẩm',
      'qr_code_traceability': 'QR Code Truy xuất nguồn gốc',
      'scan_qr_to_view_origin':
          'Quét QR code để xem thông tin nguồn gốc xuất xứ của sản phẩm',
      'traceability_not_found':
          'Không tìm thấy thông tin truy xuất cho QR code này',
      'error': 'Lỗi',
      'loading': 'Đang tải...',
      'loading_product': 'Đang tải sản phẩm...',
      'product_not_found': 'Không tìm thấy sản phẩm',
      'no_traceability_info':
          'Sản phẩm này chưa có thông tin truy xuất nguồn gốc',
      'cannot_load_traceability': 'Không thể tải thông tin truy xuất',

      // Authentication
      'login': 'Đăng nhập',
      'welcome_back': 'Chào mừng bạn trở lại!',
      'email': 'Email',
      'password': 'Mật khẩu',
      'please_enter_email': 'Vui lòng nhập email',
      'invalid_email': 'Email không hợp lệ',
      'please_enter_password': 'Vui lòng nhập mật khẩu',
      'password_min_length': 'Mật khẩu phải có ít nhất 6 ký tự',
      'no_account': 'Chưa có tài khoản? ',
      'register_now': 'Đăng ký ngay',
      'login_failed': 'Đăng nhập thất bại',
      'register': 'Đăng ký',
      'username': 'Tên đăng nhập',
      'please_enter_username': 'Vui lòng nhập tên đăng nhập',
      'full_name': 'Họ và tên',
      'please_enter_full_name': 'Vui lòng nhập họ tên',
      'phone': 'Số điện thoại',
      'address': 'Địa chỉ',
      'confirm_password': 'Xác nhận mật khẩu',
      'please_confirm_password': 'Vui lòng xác nhận mật khẩu',
      'password_mismatch': 'Mật khẩu xác nhận không khớp',
      'register_success': 'Đăng ký thành công!',
      'register_failed': 'Đăng ký thất bại',

      // Account
      'account': 'Tài khoản',
      'login_to_view_account':
          'Đăng nhập để xem thông tin tài khoản\nvà trải nghiệm đầy đủ tính năng',
      'personal_info': 'Thông tin cá nhân',
      'product_review': 'Đánh giá sản phẩm',
      'favorite_products': 'Sản phẩm yêu thích',
      'select_product_to_review': 'Chọn sản phẩm đánh giá',
      'cannot_load_products': 'Không thể tải sản phẩm',
      'no_products_to_review': 'Chưa có sản phẩm nào để đánh giá',
      'product': 'Sản phẩm',
      'code': 'Mã',
      'update_info_success': 'Cập nhật thông tin thành công',
      'error_loading_info': 'Lỗi tải thông tin',
      'save_info': 'Lưu thông tin',

      // Cart
      'cart': 'Giỏ hàng',
      'removed_from_cart': 'Đã xóa',
      'from_cart': 'khỏi giỏ hàng',
      'error_removing_product': 'Lỗi khi xóa sản phẩm',
      'error_updating_quantity': 'Lỗi khi cập nhật số lượng',
      'please_select_at_least_one':
          'Vui lòng chọn ít nhất một sản phẩm để thanh toán',
      'quantity_will_be_zero':
          'Số lượng sẽ là 0. Bạn có muốn xóa sản phẩm này khỏi giỏ hàng?',
      'add_to_cart_failed': 'Không thể thêm sản phẩm vào giỏ hàng',
      'only_left': 'Chỉ còn',
      'products_left': 'sản phẩm',

      // Product
      'back': 'Quay lại',
      'description': 'Mô tả',
      'details': 'Chi tiết',
      'reviews': 'Đánh giá',
      'add_to_cart': 'Thêm vào giỏ hàng',
      'buy_now': 'Mua ngay',
      'out_of_stock': 'Hết hàng',
      'in_stock': 'Còn hàng',
      'you_already_reviewed': 'Bạn đã đánh giá sản phẩm này',
      'be_first_to_review': 'Hãy là người đầu tiên đánh giá sản phẩm này',

      // Main Screen
      'shop': 'Shop',
      'vouchers': 'Vouchers',
      'favorite': 'Favorite',

      // Checkout
      'delivery_info': 'Thông tin giao hàng',
      'selected_products': 'Sản phẩm đã chọn',
      'please_fill_delivery_info': 'Vui lòng điền đầy đủ thông tin giao hàng',
      'please_scan_qr_and_confirm':
          'Vui lòng quét QR code và nhấn "Xác nhận đã thanh toán"',
      'please_enter_card_info': 'Vui lòng nhập thông tin thẻ',
      'credit_card_info': 'Thông tin thẻ tín dụng',

      // Orders
      'no_orders':
          'Bạn chưa có đơn hàng nào.\nHãy khám phá và mua sắm các sản phẩm chất lượng!',
      'orders': 'Đơn hàng',
      'order_details': 'Chi tiết đơn hàng',

      // Favorite
      'favorites': 'Sản phẩm yêu thích',
      'no_favorites': 'Chưa có sản phẩm yêu thích',
      'add_favorites_here':
          'Hãy thêm sản phẩm bạn yêu thích vào danh sách\nđể xem ở đây',
      'explore_products': 'Khám phá sản phẩm',
      'login_to_view_favorites':
          'Đăng nhập để xem danh sách sản phẩm\nyêu thích của bạn',
      'loading_favorites': 'Đang tải sản phẩm yêu thích...',

      // Support
      'support_center': 'Trung tâm hỗ trợ',
      'how_to_order': 'Cách đặt hàng',
      'order_steps':
          '1. Chọn sản phẩm bạn muốn mua\n2. Thêm vào giỏ hàng\n3. Xem giỏ hàng và chọn số lượng\n4. Điền thông tin giao hàng\n5. Chọn phương thức thanh toán\n6. Xác nhận đơn hàng',
      'shipping_info': 'Thông tin về phí vận chuyển và thời gian giao hàng',
      'return_policy': 'Quy định về đổi trả sản phẩm',
      'return_conditions':
          '• Sản phẩm phải còn nguyên vẹn, chưa sử dụng\n• Có hóa đơn mua hàng\n• Trong vòng 7 ngày kể từ ngày nhận hàng',

      // Chat
      'support_chat': 'Chat',
      'new_chat': 'Cuộc trò chuyện mới',
      'chat_title': 'Tiêu đề',
      'optional': 'Tùy chọn',
      'first_message': 'Tin nhắn đầu tiên',
      'enter_your_message': 'Nhập tin nhắn của bạn...',
      'no_chats_yet': 'Chưa có cuộc trò chuyện nào',
      'start_new_chat': 'Bắt đầu cuộc trò chuyện mới để được hỗ trợ',
      'no_messages': 'Chưa có tin nhắn',
      'type_message': 'Nhập tin nhắn...',
      'send': 'Gửi',

      // Admin Dashboard
      'admin_home': 'Trang chủ',
      'admin_product_management': 'Quản lý sản phẩm',
      'admin_category_management': 'Quản lý danh mục',
      'admin_order_management': 'Quản lý đơn hàng',
      'admin_user_management': 'Quản lý người dùng',
      'admin_coupon_management': 'Quản lý mã giảm giá',
      'admin_chat_management': 'Quản lý chat',
      'admin_promotion_management': 'Quản lý khuyến mãi',
      'admin_settings': 'Cài đặt',
      'admin_administrator': 'Quản trị viên',
      'feature_under_development': 'Tính năng đang phát triển',

      // Order
      'order_cancelled_successfully': 'Đơn hàng đã được hủy thành công',
      'cannot_cancel_order': 'Không thể hủy đơn hàng. Vui lòng thử lại.',
      'confirm': 'Xác nhận',

      // Contact Support
      'contact_support': 'Liên hệ hỗ trợ',
      'send_success': 'Gửi thành công',
      'support_request_sent': 'Yêu cầu hỗ trợ của bạn đã được gửi. Chúng tôi sẽ phản hồi trong vòng 24 giờ.',
      'call': 'Gọi điện',
      'call_confirmation': 'Bạn có muốn gọi đến số {phone}?',
      'calling': 'Gọi đến {phone}',
      'make_call': 'Gọi',
      'send_email': 'Gửi email',
      'email_confirmation': 'Bạn có muốn gửi email đến {email}?',
      'sending_email': 'Gửi email đến {email}',
      'send_email_action': 'Gửi',
      'order_category': 'Đơn hàng',
      'product_category': 'Sản phẩm',
      'payment_category': 'Thanh toán',
      'shipping_category': 'Vận chuyển',
      'return_category': 'Đổi trả',
      'other_category': 'Khác',

      // Delivery Address
      'set_as_default_address': 'Đặt làm địa chỉ mặc định',
      'please_fill_all_fields': 'Vui lòng điền đầy đủ thông tin',
      'confirm_delete': 'Xác nhận xóa',
      'confirm_delete_address': 'Bạn có chắc chắn muốn xóa địa chỉ này?',
      'delete': 'Xóa',
    },
    'en': {
      // Settings
      'settings': 'Settings',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable Notifications',
      'enable_notifications_desc': 'Receive notifications from the app',
      'email_notifications': 'Email Notifications',
      'email_notifications_desc': 'Receive notifications via email',
      'push_notifications': 'Push Notifications',
      'push_notifications_desc': 'Receive push notifications on device',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'dark_mode_desc': 'Enable dark mode for the app',
      'language': 'Language',
      'language_desc': 'Select display language',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'other': 'Other',
      'storage': 'Data and Storage',
      'save': 'Save',
      'cancel': 'Cancel',
      'create': 'Create',
      'retry': 'Retry',
      'select_language': 'Select Language',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',

      // Traceability & QR Code
      'traceability_info': 'Product Traceability Information',
      'verified_on_blockchain': 'Verified on Blockchain',
      'product_info': 'Product Information',
      'product_code': 'Product Code',
      'traceability_code': 'Traceability Code',
      'price': 'Price',
      'origin_info': 'Origin Information',
      'origin': 'Origin',
      'manufacturer': 'Manufacturer',
      'manufacturing_address': 'Manufacturing Address',
      'manufacturing_date': 'Manufacturing Date',
      'expiry_date': 'Expiry Date',
      'transport_info': 'Transport Information',
      'supplier': 'Supplier',
      'transport_method': 'Transport Method',
      'warehouse_date': 'Warehouse Date',
      'certification': 'Quality Certification',
      'certificate': 'Certificate',
      'certificate_number': 'Certificate Number',
      'certifying_authority': 'Certifying Authority',
      'blockchain_info': 'Blockchain Information',
      'transaction_id': 'Transaction ID',
      'hash': 'Hash',
      'saved_date': 'Saved Date',
      'scan_qr_code': 'Scan QR Code',
      'point_camera_at_qr': 'Point camera at QR code on product',
      'qr_code_traceability': 'QR Code Product Traceability',
      'scan_qr_to_view_origin':
          'Scan QR code to view product origin information',
      'traceability_not_found':
          'Traceability information not found for this QR code',
      'error': 'Error',
      'loading': 'Loading...',
      'loading_product': 'Loading product...',
      'product_not_found': 'Product not found',
      'no_traceability_info':
          'This product does not have traceability information yet',
      'cannot_load_traceability': 'Cannot load traceability information',

      // Authentication
      'login': 'Login',
      'welcome_back': 'Welcome back!',
      'email': 'Email',
      'password': 'Password',
      'please_enter_email': 'Please enter email',
      'invalid_email': 'Invalid email',
      'please_enter_password': 'Please enter password',
      'password_min_length': 'Password must be at least 6 characters',
      'no_account': 'Don\'t have an account? ',
      'register_now': 'Register now',
      'login_failed': 'Login failed',
      'register': 'Register',
      'username': 'Username',
      'please_enter_username': 'Please enter username',
      'full_name': 'Full Name',
      'please_enter_full_name': 'Please enter full name',
      'phone': 'Phone Number',
      'address': 'Address',
      'confirm_password': 'Confirm Password',
      'please_confirm_password': 'Please confirm password',
      'password_mismatch': 'Password confirmation does not match',
      'register_success': 'Registration successful!',
      'register_failed': 'Registration failed',

      // Account
      'account': 'Account',
      'login_to_view_account':
          'Login to view account information\nand experience full features',
      'personal_info': 'Personal Information',
      'product_review': 'Product Review',
      'favorite_products': 'Favorite Products',
      'select_product_to_review': 'Select Product to Review',
      'cannot_load_products': 'Cannot load products',
      'no_products_to_review': 'No products to review yet',
      'product': 'Product',
      'code': 'Code',
      'update_info_success': 'Information updated successfully',
      'error_loading_info': 'Error loading information',
      'save_info': 'Save Information',

      // Cart
      'cart': 'Cart',
      'removed_from_cart': 'Removed',
      'from_cart': 'from cart',
      'error_removing_product': 'Error removing product',
      'error_updating_quantity': 'Error updating quantity',
      'please_select_at_least_one':
          'Please select at least one product to checkout',
      'quantity_will_be_zero':
          'Quantity will be 0. Do you want to remove this product from cart?',
      'add_to_cart_failed': 'Cannot add product to cart',
      'only_left': 'Only',
      'products_left': 'left',

      // Product
      'back': 'Back',
      'description': 'Description',
      'details': 'Details',
      'reviews': 'Reviews',
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'out_of_stock': 'Out of Stock',
      'in_stock': 'In Stock',
      'you_already_reviewed': 'You have already reviewed this product',
      'be_first_to_review': 'Be the first to review this product',

      // Main Screen
      'shop': 'Shop',
      'vouchers': 'Vouchers',
      'favorite': 'Favorite',

      // Checkout
      'delivery_info': 'Delivery Information',
      'selected_products': 'Selected Products',
      'please_fill_delivery_info': 'Please fill in all delivery information',
      'please_scan_qr_and_confirm':
          'Please scan QR code and press "Confirm Payment"',
      'please_enter_card_info': 'Please enter card information',
      'credit_card_info': 'Credit Card Information',

      // Orders
      'no_orders':
          'You don\'t have any orders yet.\nExplore and shop quality products!',
      'orders': 'Orders',
      'order_details': 'Order Details',

      // Favorite
      'favorites': 'Favorite Products',
      'no_favorites': 'No favorite products yet',
      'add_favorites_here':
          'Add products you like to your list\nto see them here',
      'explore_products': 'Explore Products',
      'login_to_view_favorites': 'Login to view your\nfavorite products list',
      'loading_favorites': 'Loading favorite products...',

      // Support
      'support_center': 'Support Center',
      'how_to_order': 'How to Order',
      'order_steps':
          '1. Select products you want to buy\n2. Add to cart\n3. View cart and select quantity\n4. Fill delivery information\n5. Choose payment method\n6. Confirm order',
      'shipping_info': 'Information about shipping fees and delivery time',
      'return_policy': 'Product Return Policy',
      'return_conditions':
          '• Product must be intact, unused\n• Must have purchase receipt\n• Within 7 days from delivery date',

      // Chat
      'support_chat': 'Chat',
      'new_chat': 'New Chat',
      'chat_title': 'Chat Title',
      'optional': 'Optional',
      'first_message': 'First Message',
      'enter_your_message': 'Enter your message...',
      'no_chats_yet': 'No chats yet',
      'start_new_chat': 'Start a new chat to get support',
      'no_messages': 'No messages',
      'type_message': 'Type a message...',
      'send': 'Send',

      // Admin Dashboard
      'admin_home': 'Home',
      'admin_product_management': 'Product Management',
      'admin_category_management': 'Category Management',
      'admin_order_management': 'Order Management',
      'admin_user_management': 'User Management',
      'admin_coupon_management': 'Coupon Management',
      'admin_chat_management': 'Chat Management',
      'admin_promotion_management': 'Promotion Management',
      'admin_settings': 'Settings',
      'admin_administrator': 'Administrator',
      'feature_under_development': 'Feature Under Development',

      // Order
      'order_cancelled_successfully': 'Order cancelled successfully',
      'cannot_cancel_order': 'Cannot cancel order. Please try again.',
      'confirm': 'Confirm',

      // Contact Support
      'contact_support': 'Contact Support',
      'send_success': 'Sent Successfully',
      'support_request_sent': 'Your support request has been sent. We will respond within 24 hours.',
      'call': 'Call',
      'call_confirmation': 'Do you want to call {phone}?',
      'calling': 'Calling {phone}',
      'make_call': 'Call',
      'send_email': 'Send Email',
      'email_confirmation': 'Do you want to send email to {email}?',
      'sending_email': 'Sending email to {email}',
      'send_email_action': 'Send',
      'order_category': 'Order',
      'product_category': 'Product',
      'payment_category': 'Payment',
      'shipping_category': 'Shipping',
      'return_category': 'Return',
      'other_category': 'Other',

      // Delivery Address
      'set_as_default_address': 'Set as Default Address',
      'please_fill_all_fields': 'Please fill in all fields',
      'confirm_delete': 'Confirm Delete',
      'confirm_delete_address': 'Are you sure you want to delete this address?',
      'delete': 'Delete',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common translations
  String get settings => translate('settings');
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enable_notifications');
  String get enableNotificationsDesc => translate('enable_notifications_desc');
  String get emailNotifications => translate('email_notifications');
  String get emailNotificationsDesc => translate('email_notifications_desc');
  String get pushNotifications => translate('push_notifications');
  String get pushNotificationsDesc => translate('push_notifications_desc');
  String get appearance => translate('appearance');
  String get darkMode => translate('dark_mode');
  String get darkModeDesc => translate('dark_mode_desc');
  String get language => translate('language');
  String get languageDesc => translate('language_desc');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get other => translate('other');
  String get storage => translate('storage');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get create => translate('create');
  String get retry => translate('retry');
  String get selectLanguage => translate('select_language');
  String get light => translate('light');
  String get dark => translate('dark');
  String get system => translate('system');

  // Traceability & QR Code
  String get traceabilityInfo => translate('traceability_info');
  String get verifiedOnBlockchain => translate('verified_on_blockchain');
  String get productInfo => translate('product_info');
  String get productCode => translate('product_code');
  String get traceabilityCode => translate('traceability_code');
  String get price => translate('price');
  String get originInfo => translate('origin_info');
  String get origin => translate('origin');
  String get manufacturer => translate('manufacturer');
  String get manufacturingAddress => translate('manufacturing_address');
  String get manufacturingDate => translate('manufacturing_date');
  String get expiryDate => translate('expiry_date');
  String get transportInfo => translate('transport_info');
  String get supplier => translate('supplier');
  String get transportMethod => translate('transport_method');
  String get warehouseDate => translate('warehouse_date');
  String get certification => translate('certification');
  String get certificate => translate('certificate');
  String get certificateNumber => translate('certificate_number');
  String get certifyingAuthority => translate('certifying_authority');
  String get blockchainInfo => translate('blockchain_info');
  String get transactionId => translate('transaction_id');
  String get hash => translate('hash');
  String get savedDate => translate('saved_date');
  String get scanQRCode => translate('scan_qr_code');
  String get pointCameraAtQR => translate('point_camera_at_qr');
  String get qrCodeTraceability => translate('qr_code_traceability');
  String get scanQRToViewOrigin => translate('scan_qr_to_view_origin');
  String get traceabilityNotFound => translate('traceability_not_found');
  String get error => translate('error');
  String get loading => translate('loading');
  String get loadingProduct => translate('loading_product');
  String get productNotFound => translate('product_not_found');
  String get noTraceabilityInfo => translate('no_traceability_info');
  String get cannotLoadTraceability => translate('cannot_load_traceability');

  // Authentication
  String get login => translate('login');
  String get welcomeBack => translate('welcome_back');
  String get email => translate('email');
  String get password => translate('password');
  String get pleaseEnterEmail => translate('please_enter_email');
  String get invalidEmail => translate('invalid_email');
  String get pleaseEnterPassword => translate('please_enter_password');
  String get passwordMinLength => translate('password_min_length');
  String get noAccount => translate('no_account');
  String get registerNow => translate('register_now');
  String get loginFailed => translate('login_failed');
  String get register => translate('register');
  String get username => translate('username');
  String get pleaseEnterUsername => translate('please_enter_username');
  String get fullName => translate('full_name');
  String get pleaseEnterFullName => translate('please_enter_full_name');
  String get phone => translate('phone');
  String get address => translate('address');
  String get confirmPassword => translate('confirm_password');
  String get pleaseConfirmPassword => translate('please_confirm_password');
  String get passwordMismatch => translate('password_mismatch');
  String get registerSuccess => translate('register_success');
  String get registerFailed => translate('register_failed');

  // Account
  String get account => translate('account');
  String get loginToViewAccount => translate('login_to_view_account');
  String get personalInfo => translate('personal_info');
  String get productReview => translate('product_review');
  String get favoriteProducts => translate('favorite_products');
  String get selectProductToReview => translate('select_product_to_review');
  String get cannotLoadProducts => translate('cannot_load_products');
  String get noProductsToReview => translate('no_products_to_review');
  String get product => translate('product');
  String get code => translate('code');
  String get updateInfoSuccess => translate('update_info_success');
  String get errorLoadingInfo => translate('error_loading_info');
  String get saveInfo => translate('save_info');

  // Cart
  String get cart => translate('cart');
  String get removedFromCart => translate('removed_from_cart');
  String get fromCart => translate('from_cart');
  String get errorRemovingProduct => translate('error_removing_product');
  String get errorUpdatingQuantity => translate('error_updating_quantity');
  String get pleaseSelectAtLeastOne => translate('please_select_at_least_one');
  String get quantityWillBeZero => translate('quantity_will_be_zero');
  String get addToCartFailed => translate('add_to_cart_failed');
  String get onlyLeft => translate('only_left');
  String get productsLeft => translate('products_left');

  // Product
  String get back => translate('back');
  String get description => translate('description');
  String get details => translate('details');
  String get reviews => translate('reviews');
  String get addToCart => translate('add_to_cart');
  String get buyNow => translate('buy_now');
  String get outOfStock => translate('out_of_stock');
  String get inStock => translate('in_stock');
  String get youAlreadyReviewed => translate('you_already_reviewed');
  String get beFirstToReview => translate('be_first_to_review');

  // Main Screen
  String get shop => translate('shop');
  String get vouchers => translate('vouchers');
  String get favorite => translate('favorite');

  // Checkout
  String get deliveryInfo => translate('delivery_info');
  String get selectedProducts => translate('selected_products');
  String get pleaseFillDeliveryInfo => translate('please_fill_delivery_info');
  String get pleaseScanQrAndConfirm => translate('please_scan_qr_and_confirm');
  String get pleaseEnterCardInfo => translate('please_enter_card_info');
  String get creditCardInfo => translate('credit_card_info');

  // Orders
  String get noOrders => translate('no_orders');
  String get orders => translate('orders');
  String get orderDetails => translate('order_details');

  // Favorite
  String get favorites => translate('favorites');
  String get noFavorites => translate('no_favorites');
  String get addFavoritesHere => translate('add_favorites_here');
  String get exploreProducts => translate('explore_products');
  String get loginToViewFavorites => translate('login_to_view_favorites');
  String get loadingFavorites => translate('loading_favorites');

  // Support
  String get supportCenter => translate('support_center');
  String get howToOrder => translate('how_to_order');
  String get orderSteps => translate('order_steps');
  String get shippingInfo => translate('shipping_info');
  String get returnPolicy => translate('return_policy');
  String get returnConditions => translate('return_conditions');

  // Chat
  String get supportChat => translate('support_chat');
  String get newChat => translate('new_chat');
  String get chatTitle => translate('chat_title');
  String get optional => translate('optional');
  String get firstMessage => translate('first_message');
  String get enterYourMessage => translate('enter_your_message');
  String get noChatsYet => translate('no_chats_yet');
  String get startNewChat => translate('start_new_chat');
  String get noMessages => translate('no_messages');
  String get typeMessage => translate('type_message');
  String get send => translate('send');

  // Admin Dashboard
  String get adminHome => translate('admin_home');
  String get adminProductManagement => translate('admin_product_management');
  String get adminCategoryManagement => translate('admin_category_management');
  String get adminOrderManagement => translate('admin_order_management');
  String get adminUserManagement => translate('admin_user_management');
  String get adminCouponManagement => translate('admin_coupon_management');
  String get adminChatManagement => translate('admin_chat_management');
  String get adminPromotionManagement => translate('admin_promotion_management');
  String get adminSettings => translate('admin_settings');
  String get adminAdministrator => translate('admin_administrator');
  String get featureUnderDevelopment => translate('feature_under_development');

  // Order
  String get orderCancelledSuccessfully => translate('order_cancelled_successfully');
  String get cannotCancelOrder => translate('cannot_cancel_order');
  String get confirm => translate('confirm');

  // Contact Support
  String get contactSupport => translate('contact_support');
  String get sendSuccess => translate('send_success');
  String get supportRequestSent => translate('support_request_sent');
  String get call => translate('call');
  String callConfirmation(String phone) => translate('call_confirmation').replaceAll('{phone}', phone);
  String calling(String phone) => translate('calling').replaceAll('{phone}', phone);
  String get makeCall => translate('make_call');
  String get sendEmail => translate('send_email');
  String emailConfirmation(String email) => translate('email_confirmation').replaceAll('{email}', email);
  String sendingEmail(String email) => translate('sending_email').replaceAll('{email}', email);
  String get sendEmailAction => translate('send_email_action');
  String get orderCategory => translate('order_category');
  String get productCategory => translate('product_category');
  String get paymentCategory => translate('payment_category');
  String get shippingCategory => translate('shipping_category');
  String get returnCategory => translate('return_category');
  String get otherCategory => translate('other_category');

  // Delivery Address
  String get setAsDefaultAddress => translate('set_as_default_address');
  String get pleaseFillAllFields => translate('please_fill_all_fields');
  String get confirmDelete => translate('confirm_delete');
  String get confirmDeleteAddress => translate('confirm_delete_address');
  String get delete => translate('delete');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}
