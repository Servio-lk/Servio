import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_client.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Safe accessor to check if Supabase is initialized
  bool get isInitialized {
    try {
      // Accessing Supabase.instance throws if not initialized
      final _ = Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Safe client accessor that returns null instead of throwing in uninitialized environments (like widget tests)
  SupabaseClient? get safeClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient get client {
    final c = safeClient;
    if (c == null) {
      throw StateError('Supabase has not been initialized. Call Supabase.initialize(...) first.');
    }
    return c;
  }

  // Get current user
  User? get currentUser => safeClient?.auth.currentUser;

  // Get current session
  Session? get currentSession => safeClient?.auth.currentSession;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get access token
  String? get accessToken => currentSession?.accessToken;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await syncWithBackend();
    return res;
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
    await syncWithBackend();
    return res;
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
    final res = await client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: otp,
    );
    await syncWithBackend();
    return res;
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
    try {
      await safeClient?.auth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPasswordForEmail(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges =>
      safeClient?.auth.onAuthStateChange ?? const Stream.empty();

  // Update user profile
  Future<UserResponse> updateUserProfile({Map<String, dynamic>? data}) async {
    return await client.auth.updateUser(UserAttributes(data: data));
  }

  /// Syncs the authenticated Supabase session with Spring Boot backend via /api/auth/supabase-login
  Future<Map<String, dynamic>?> syncWithBackend() async {
    final session = currentSession;
    final user = currentUser;
    if (session == null || user == null) return null;

    try {
      final token = session.accessToken;
      final email = user.email ?? '';
      final fullName = user.userMetadata?['full_name'] as String? ?? '';
      final role = user.userMetadata?['role'] as String? ?? 'CUSTOMER';

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/supabase-login',
        body: {
          'accessToken': token,
          'email': email,
          'fullName': fullName,
          'role': role,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Backend sync during login: $e');
      return null;
    }
  }

  /// Queries mechanic pre-registration from Spring Boot REST API
  Future<Map<String, dynamic>?> getActiveMechanicByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/auth/mechanic-registration',
        queryParameters: {'email': normalizedEmail},
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        return {
          'id': data['id'],
          'full_name': data['fullName'] ?? data['full_name'],
          'email': data['email'],
          'phone': data['phone'],
          'specialization': data['specialization'],
          'experience_years': data['experienceYears'] ?? data['experience_years'],
          'status': data['status'],
          'is_active': data['isActive'] ?? data['is_active'] ?? true,
        };
      }
    } catch (e) {
      debugPrint('Error fetching mechanic registration from backend: $e');
    }
    return null;
  }

  /// Reports mechanic registration error to Spring Boot REST API
  Future<bool> reportMechanicErrorToBackend(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/mechanic-registration/report-error',
        body: {'email': email},
      );
      return response.success;
    } catch (e) {
      debugPrint('Report error to backend failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentMechanic() async {
    final email = currentUser?.email;
    if (email == null) return null;
    return getActiveMechanicByEmail(email);
  }

  /// Updates user metadata and syncs with Spring Boot
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

    await updateUserProfile(
      data: {
        'role': 'MECHANIC',
        if (name != null) 'full_name': name,
        if (phone != null) 'phone': phone,
      },
    );

    await syncWithBackend();
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

  // Fetch full user profile from Spring Boot backend /api/auth/profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/auth/profile',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.data;
    } catch (e) {
      debugPrint('Error fetching user profile from backend: $e');
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
