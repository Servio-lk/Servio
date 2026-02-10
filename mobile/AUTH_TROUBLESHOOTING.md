# Supabase Authentication Troubleshooting Guide

## 🔍 Issue: Can't Login

Your Supabase credentials are configured correctly, but you're unable to login. Follow these steps to resolve the issue:

---

## Step 1: Enable Email/Password Authentication

1. Go to your Supabase Dashboard: https://app.supabase.com/project/szgvnurzdglflmdabjol
2. Navigate to **Authentication** → **Providers**
3. Find **Email** provider
4. Make sure it's **ENABLED**
5. **Disable** "Confirm email" if you want to test without email verification (you can enable it later)
6. Click **Save**

---

## Step 2: Create a Test User

### Option A: Using Supabase Dashboard (Easiest)

1. Go to **Authentication** → **Users**
2. Click **Add User** → **Create new user**
3. Enter:
   - **Email**: `test@example.com`
   - **Password**: `test123456` (minimum 6 characters)
   - **Auto Confirm User**: ✅ **Check this box** (important!)
4. Click **Create User**

### Option B: Using SQL Editor

1. Go to **SQL Editor** in your Supabase Dashboard
2. Run this query:

```sql
-- Create a test user
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'test@example.com',
  crypt('test123456', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);
```

---

## Step 3: Test Login

1. **Run your Flutter app**:
   ```bash
   cd /Users/chamindu/Documents/GitHub/Servio/mobile
   flutter run
   ```

2. **Try logging in with**:
   - Email: `test@example.com`
   - Password: `test123456`

3. **Check the console output** for these debug logs:
   ```
   Attempting to sign in with email: test@example.com
   Sign in response: [user-id]
   Sign in successful!
   ```

---

## Step 4: Check for Errors

If login still fails, check the Flutter console for error messages:

### Common Errors and Solutions:

#### ❌ "Invalid login credentials"
- **Cause**: Wrong email/password OR user doesn't exist
- **Solution**: Double-check the email and password, or create a new user

#### ❌ "Email not confirmed"
- **Cause**: Email confirmation is required but user hasn't verified
- **Solution**:
  1. Go to **Authentication** → **Providers** → **Email**
  2. Disable "Confirm email"
  3. OR go to **Authentication** → **Users** → Select user → **Confirm email**

#### ❌ "Network error" or timeout
- **Cause**: Can't reach Supabase servers
- **Solution**:
  - Check your internet connection
  - Try accessing https://szgvnurzdglflmdabjol.supabase.co in your browser
  - Check if Supabase is down: https://status.supabase.com/

#### ❌ "Invalid API key"
- **Cause**: Wrong `supabaseAnonKey` in config
- **Solution**:
  1. Go to **Project Settings** → **API**
  2. Copy the **anon** key (public key)
  3. Update `/mobile/lib/src/core/config/supabase_config.dart`

---

## Step 5: Test Signup Flow

If you want users to sign up in the app:

1. **Add a Sign Up screen** (or test via API)
2. **Test signup**:

```dart
// In your app, call:
final response = await _supabaseService.signUpWithEmail(
  email: 'newuser@example.com',
  password: 'password123',
  data: {'name': 'Test User'},
);
```

---

## 🔧 Additional Checks

### Verify Supabase Connection

Run this test in your Flutter app:

```dart
// Add this temporarily to your signin screen's initState:
@override
void initState() {
  super.initState();
  _testSupabaseConnection();
}

Future<void> _testSupabaseConnection() async {
  try {
    print('Testing Supabase connection...');
    print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
    print('Supabase client initialized: ${_supabaseService.client != null}');
    print('Current user: ${_supabaseService.currentUser?.email ?? "None"}');
  } catch (e) {
    print('Supabase connection error: $e');
  }
}
```

### Check Authentication Settings

In Supabase Dashboard → **Authentication** → **Settings**:

- ✅ **Site URL**: Should be set (try `http://localhost:3000` for testing)
- ✅ **Redirect URLs**: Add `io.supabase.servio://login-callback/` for OAuth
- ✅ **JWT expiry**: Default is fine (3600 seconds)
- ✅ **Disable Signup**: Should be **OFF** if you want signups

---

## 📱 Testing on Physical Device

If testing on a physical device:

1. **Android**: Make sure your device has internet access
2. **iOS**: Check that you've added the necessary permissions in `Info.plist`
3. **Check Firewall**: Some networks block Supabase domains

---

## 🆘 Still Having Issues?

### View Realtime Logs

1. Go to Supabase Dashboard
2. Click **Logs** → **Auth Logs**
3. Try logging in
4. Check if any requests are reaching Supabase

### Debug Output

Run your app with verbose logging:
```bash
flutter run --verbose
```

Look for:
- Network errors
- Authentication errors
- API key errors

### Contact Information

If none of the above works:
- Check Supabase docs: https://supabase.com/docs/guides/auth
- Supabase Discord: https://discord.supabase.com
- GitHub Issues: https://github.com/supabase/supabase-flutter/issues

---

## ✅ Success Checklist

- [ ] Email/Password provider is enabled in Supabase
- [ ] Email confirmation is disabled (for testing)
- [ ] Test user is created with auto-confirmed email
- [ ] Supabase credentials are correct in `supabase_config.dart`
- [ ] App can reach Supabase servers (check network)
- [ ] Debug logs show "Sign in successful!"
- [ ] User is redirected to home screen

---

## 🎯 Quick Test Commands

Try these in your Firebase Dashboard SQL Editor:

```sql
-- Check if your test user exists
SELECT email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'test@example.com';

-- List all users
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- Delete test user (if needed)
DELETE FROM auth.users WHERE email = 'test@example.com';
```

---

## Next Steps After Login Works

1. ✅ Test password reset flow
2. ✅ Set up user profiles table
3. ✅ Enable email confirmation (production)
4. ✅ Set up Row Level Security (RLS)
5. ✅ Configure OAuth providers (Google, Facebook)
6. ✅ Add user metadata storage
7. ✅ Implement auth state persistence
