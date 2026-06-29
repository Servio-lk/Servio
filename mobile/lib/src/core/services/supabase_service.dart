import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Get current session
  Session? get currentSession => client.auth.currentSession;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  // Request email OTP via /auth/v1/otp (higher default rate limit).
  Future<void> requestSignupOtp({
    required String email,
    Map<String, dynamic>? data,
  }) async {
    await client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      data: data,
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    return await client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: otp,
    );
  }

  Future<void> resendEmailOtp({required String email}) async {
    await client.auth.resend(type: OtpType.email, email: email);
  }

  Future<UserResponse> setPassword(String password) async {
    return await client.auth.updateUser(UserAttributes(password: password));
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.servio://login-callback/',
      );
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }

  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.servio://login-callback/',
      );
      return true;
    } catch (e) {
      debugPrint('Error signing in with Facebook: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  Future<void> resetPasswordForEmail(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Update user profile
  Future<UserResponse> updateUserProfile({Map<String, dynamic>? data}) async {
    return await client.auth.updateUser(UserAttributes(data: data));
  }

  Future<Map<String, dynamic>?> getActiveMechanicByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final backendMechanic = await _getActiveMechanicFromBackend(
      normalizedEmail,
    );
    if (backendMechanic != null) return backendMechanic;

    try {
      final response = await client
          .from('mechanics')
          .select(
            'id, full_name, email, phone, specialization, experience_years, status, is_active',
          )
          .ilike('email', normalizedEmail)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching mechanic by email: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getActiveMechanicFromBackend(
    String email,
  ) async {
    final checkedUrls = <String>{};
    final baseUrls = [
      ApiConfig.apiBaseUrl,
      ...ApiConfig.fallbackApiBaseUrls,
    ].where((url) => checkedUrls.add(url)).toList();

    for (final baseUrl in baseUrls) {
      try {
        final uri = Uri.parse(
          '$baseUrl/auth/mechanic-registration',
        ).replace(queryParameters: {'email': email});
        final client = HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 1200);

        try {
          final request = await client.getUrl(uri);
          request.headers.set(HttpHeaders.acceptHeader, 'application/json');
          final response = await request.close().timeout(
            const Duration(milliseconds: 1800),
          );
          final body = await response.transform(utf8.decoder).join();

          if (response.statusCode == HttpStatus.notFound) {
            return null;
          }

          if (response.statusCode < 200 || response.statusCode >= 300) {
            continue;
          }

          final decoded = jsonDecode(body) as Map<String, dynamic>;
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            return {
              'id': data['id'],
              'full_name': data['fullName'],
              'email': data['email'],
              'phone': data['phone'],
              'specialization': data['specialization'],
              'experience_years': data['experienceYears'],
              'status': data['status'],
              'is_active': data['isActive'],
            };
          }
        } finally {
          client.close(force: true);
        }
      } catch (e) {
        debugPrint('Mechanic backend lookup failed for $baseUrl: $e');
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> getCurrentMechanic() async {
    final email = currentUser?.email;
    if (email == null) return null;
    return getActiveMechanicByEmail(email);
  }

  Future<void> syncMechanicProfile({
    required User user,
    Map<String, dynamic>? mechanic,
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    final name = _firstNonEmpty([
      mechanic?['full_name'],
      fallbackName,
      user.userMetadata?['full_name'],
      user.userMetadata?['display_name'],
    ]);
    final phone = _firstNonEmpty([
      mechanic?['phone'],
      fallbackPhone,
      user.phone,
      user.userMetadata?['phone'],
    ]);

    await client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      if (name != null) 'full_name': name,
      if (phone != null) 'phone': phone,
      'role': 'MECHANIC',
      'is_admin': false,
    }, onConflict: 'id');

    await updateUserProfile(
      data: {
        'role': 'MECHANIC',
        if (name != null) 'full_name': name,
        if (phone != null) 'phone': phone,
      },
    );
  }

  Future<String> resolveUserRole(
    User user, {
    Map<String, dynamic>? profile,
  }) async {
    final profileRole = profile?['role']?.toString().toUpperCase();
    final metadataRole = user.userMetadata?['role']?.toString().toUpperCase();

    if (profile?['is_admin'] == true ||
        profileRole == 'ADMIN' ||
        metadataRole == 'ADMIN') {
      return 'ADMIN';
    }

    if (profileRole == 'MECHANIC' || metadataRole == 'MECHANIC') {
      return 'MECHANIC';
    }

    final email = user.email ?? profile?['email']?.toString();
    final mechanic = email == null
        ? null
        : await getActiveMechanicByEmail(email);
    if (mechanic != null) {
      try {
        await syncMechanicProfile(user: user, mechanic: mechanic);
      } catch (e) {
        debugPrint('Error syncing mechanic profile: $e');
      }
      return 'MECHANIC';
    }

    return profileRole == 'CUSTOMER' || profileRole == null
        ? 'CUSTOMER'
        : profileRole;
  }

  // Fetch full user profile from profiles table
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
