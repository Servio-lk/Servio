import 'package:supabase_flutter/supabase_flutter.dart';

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
      print('Error signing in with Google: $e');
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
      print('Error signing in with Facebook: $e');
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
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
