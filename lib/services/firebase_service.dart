import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('FCM background message received: ${message.messageId}');
  }
}

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  User? get currentUser => auth.currentUser;
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Initialize Firebase Core and Firebase Messaging
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Register background handler for FCM
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request FCM permissions (Android 13+ & Web / iOS)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM Authorization status: ${settings.authorizationStatus}');
      }

      // Fetch FCM Device Token
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (kDebugMode) {
          print('FCM Device Token: $token');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting FCM token: $e');
        }
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print(
            'FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}',
          );
        }
      });

      _initialized = true;
      if (kDebugMode) {
        print('Firebase successfully initialized for FarReach');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e\n$stack');
      }
    }
  }

  /// Sign up with Email and Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
    }
    await credential.user?.sendEmailVerification();
    return credential;
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Send another verification email to the current Firebase user.
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user is available.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Retrieve current user ID token
  Future<String?> getIdToken() async {
    return await currentUser?.getIdToken();
  }

  /// Retrieve current FCM token
  Future<String?> getFcmToken() async {
    try {
      return await messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
      return null;
    }
  }

  /// Human-friendly Firebase error message converter
  static String getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email address.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled in Firebase Console.';
        case 'requires-recent-login':
          return 'Please sign in again before completing this action.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }
}
