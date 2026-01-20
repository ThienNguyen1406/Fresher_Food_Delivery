import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fresher_food/firebase_options.dart';

/// Firebase Service - Quản lý tất cả Firebase services
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  FirebaseAnalytics? _analytics;
  FirebaseMessaging? _messaging;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;

  /// Khởi tạo Firebase với options từ firebase_options.dart
  static Future<void> initialize() async {
    try {
      // Sử dụng Firebase options từ firebase_options.dart để tích hợp keys
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      instance._analytics = FirebaseAnalytics.instance;
      instance._messaging = FirebaseMessaging.instance;
      instance._auth = FirebaseAuth.instance;
      instance._firestore = FirebaseFirestore.instance;
      instance._storage = FirebaseStorage.instance;
      
      // Cấu hình Firebase Messaging
      await _setupFirebaseMessaging();
      
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Cấu hình Firebase Messaging (Push Notifications)
  static Future<void> _setupFirebaseMessaging() async {
    try {
      final messaging = instance._messaging;
      if (messaging == null) return;

      // Request permission (iOS)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined notification permission');
      }

      // Get FCM token
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Lưu token vào backend nếu cần
        // await _saveFCMTokenToBackend(token);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message: ${message.notification?.title}');
        // Hiển thị notification khi app đang mở
      });

      // Handle background messages (khi app đóng)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Background message opened: ${message.notification?.title}');
        // Xử lý khi user click vào notification
      });

      // Handle notification khi app được mở từ terminated state
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.notification?.title}');
      }
    } catch (e) {
      print('Error setting up Firebase Messaging: $e');
    }
  }

  /// Lấy FCM token để gửi push notifications
  Future<String?> getFCMToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Gửi notification đến topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Hủy subscription từ topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Log event với Firebase Analytics
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters != null 
            ? Map<String, Object>.from(parameters) 
            : null,
      );
    } catch (e) {
      print('Error logging event: $e');
    }
  }

  /// Set user property cho Analytics
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Error setting user property: $e');
    }
  }

  /// Set user ID cho Analytics
  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      print('Error setting user ID: $e');
    }
  }

  /// Gửi OTP SMS qua Firebase Phone Authentication
  /// [phoneNumber] phải có format: +84xxxxxxxxxx (với country code)
  Future<String?> sendOTP(String phoneNumber) async {
    try {
      if (_auth == null) {
        throw Exception('Firebase Auth chưa được khởi tạo');
      }

      // Verify phone number và gửi OTP
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto verification (Android only)
          print('Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          throw Exception('Gửi OTP thất bại: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP code sent. Verification ID: $verificationId');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );

      // Lưu verification ID để verify OTP sau
      // Note: verificationId sẽ được trả về trong codeSent callback
      // Cần sử dụng Completer hoặc callback để lấy verificationId
      return null; // Sẽ được xử lý trong callback
    } catch (e) {
      print('Error sending OTP: $e');
      rethrow;
    }
  }

  /// Gửi OTP SMS và trả về verification ID qua callback
  /// [onCodeSent] nhận (verificationId, resendToken) - resendToken có thể null
  Future<void> sendOTPWithCallback(
    String phoneNumber,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(String error) onError,
  ) async {
    try {
      if (_auth == null) {
        onError('Firebase Auth chưa được khởi tạo');
        return;
      }

      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto verification (Android only) - chỉ hoạt động trên device thật
          print('Auto verification completed');
          // Không làm gì ở đây vì user sẽ nhập OTP thủ công
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          onError('Gửi OTP thất bại: ${e.message ?? "Unknown error"}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP code sent. Verification ID: $verificationId');
          print('Resend Token: ${resendToken != null ? "Available" : "Not available"}');
          // Trả về cả verificationId và resendToken
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Đây là hành vi bình thường trên emulator
          // Emulator không thể tự động lấy OTP từ SMS
          // User sẽ cần nhập OTP thủ công
          print('Code auto retrieval timeout (bình thường trên emulator)');
          print('User cần nhập OTP thủ công từ SMS');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error sending OTP: $e');
      onError('Lỗi khi gửi OTP: $e');
    }
  }

  /// Verify OTP code
  /// [verificationId] từ callback codeSent
  /// [smsCode] là mã OTP user nhập
  Future<PhoneAuthCredential?> verifyOTP(
    String verificationId,
    String smsCode,
  ) async {
    try {
      if (_auth == null) {
        throw Exception('Firebase Auth chưa được khởi tạo');
      }

      // Tạo PhoneAuthCredential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Verify credential
      final userCredential = await _auth!.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        print('OTP verified successfully');
        return credential;
      } else {
        throw Exception('Xác thực OTP thất bại');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Resend OTP (nếu có resendToken)
  /// [onCodeSent] nhận (verificationId, resendToken)
  Future<void> resendOTP(
    String phoneNumber,
    int? resendToken,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(String error) onError,
  ) async {
    try {
      if (_auth == null) {
        onError('Firebase Auth chưa được khởi tạo');
        return;
      }

      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          onError('Gửi lại OTP thất bại: ${e.message ?? "Unknown error"}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP code resent. Verification ID: $verificationId');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto retrieval timeout (bình thường trên emulator)');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error resending OTP: $e');
      onError('Lỗi khi gửi lại OTP: $e');
    }
  }

  // Getters
  FirebaseAnalytics? get analytics => _analytics;
  FirebaseMessaging? get messaging => _messaging;
  FirebaseAuth? get auth => _auth;
  FirebaseFirestore? get firestore => _firestore;
  FirebaseStorage? get storage => _storage;
}

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Background message: ${message.notification?.title}');
  // Xử lý background message ở đây
}

