# Servio Mobile App - Supabase Setup Guide

## ✅ Completed

1. ✅ Added Supabase and Phosphor Flutter dependencies
2. ✅ Created Supabase configuration file
3. ✅ Created Supabase service with authentication methods
4. ✅ Updated signin screen with Supabase integration
5. ✅ Created home screen with Figma design
6. ✅ Initialized Supabase in main.dart

## 🔧 Required Configuration Steps

### 1. Set up your Supabase Project

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Create a new project or select an existing one
3. Go to **Project Settings** → **API**
4. Copy your **Project URL** and **anon/public key**

### 2. Update Supabase Configuration

Open `/Users/chamindu/Documents/GitHub/Servio/mobile/lib/src/core/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual credentials:

```dart
static const String supabase Url = 'https://xxxxxxxxxxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 3. Configure OAuth Providers (Optional)

If you want to use Google or Facebook login:

#### Google Sign-In:
1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Google provider
3. Follow Supabase's guide to set up Google OAuth credentials
4. Configure the redirect URL

#### Facebook Sign-In:
1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Facebook provider
3. Follow Supabase's guide to set up Facebook App
4. Configure the redirect URL

### 4. Set up Deep Linking (for OAuth)

#### Android (`android/app/src/main/AndroidManifest.xml`):

```xml
<activity>
    <!-- ... other activity config ... -->

    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="io.supabase.servio"
            android:host="login-callback" />
    </intent-filter>
</activity>
```

#### iOS (`ios/Runner/Info.plist`):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.servio</string>
        </array>
    </dict>
</array>
```

## 📁 Project Structure

```
mobile/lib/
├── main.dart (✅ Supabase initialized)
├── src/
    ├── core/
    │   ├── config/
    │   │   └── supabase_config.dart (⚠️ Needs your credentials)
    │   └── services/
    │       └── supabase_service.dart (✅ Authentication methods)
    └── features/
        ├── auth/
        │   └── signin_screen.dart (✅ Integrated with Supabase)
        └── home/
            └── home_screen.dart (✅ Figma design implemented)
```

## 🚀 Features Implemented

### Authentication (signin_screen.dart)
- ✅ Email/Password authentication
- ✅ Google OAuth integration
- ✅ Facebook OAuth integration
- ✅ Password reset functionality
- ✅ Loading states
- ✅ Error handling
- ✅ Form validation

### Home Screen (home_screen.dart)
- ✅ Gradient background (#FFF7F5 → #FBFBFB)
- ✅ Greeting section
- ✅ Search container with "Later" button
- ✅ Service center information card
- ✅ Suggestions list with Phosphor icons
- ✅ Offers section with custom star painter
- ✅ Custom tab bar (Home, Services, Activity, Account)
- ✅ Phosphor icons integration
- ✅ Google Fonts (Instrument Sans)

### Supabase Service Methods
- ✅ `signInWithEmail(email, password)`
- ✅ `signUpWithEmail(email, password, data)`
- ✅ `signInWithGoogle()`
- ✅ `signInWithFacebook()`
- ✅ `signOut()`
- ✅ `resetPasswordForEmail(email)`
- ✅ `updateUserProfile(data)`
- ✅ `authStateChanges` stream
- ✅ `currentUser` getter
- ✅ `isLoggedIn` getter

## 🧪 Testing

1. Run the app: `flutter run`
2. Try signing in with test credentials
3. Test form validation
4. Test forgot password
5. Navigate to home screen after successful login

## 🔒 Security Notes

- ⚠️ Never commit your Supabase credentials to Git
- Add `**/supabase_config.dart` to `.gitignore` if needed
- Use environment variables for production builds
- Enable Row Level Security (RLS) on your Supabase tables

## 📱 Mobile View (Web App)

The web app's mobile signin view has also been updated to match the Figma design:
- ✅ Bottom sheet layout
- ✅ Grabber handle
- ✅ Close button
- ✅ Same styling as Flutter app
- ✅ Responsive breakpoints (mobile < 1024px, desktop ≥ 1024px)

## 💡 Next Steps

1. Configure your Supabase credentials
2. Set up authentication providers
3. Create user database schema
4. Implement other tab screens (Services, Activity, Account)
5. Add user profile management
6. Connect service bookings to backend
7. Add search functionality
8. Implement service suggestions from database

## 🆘 Troubleshooting

### Supabase initialization error
- Check your URL and anon key are correct
- Ensure you have internet connection
- Check Supabase Dashboard status

### OAuth not working
- Verify redirect URLs are configured
- Check OAuth provider credentials
- Ensure deep linking is set up correctly

### Dependencies not found
Run: `flutter pub get` or `cd mobile && flutter pub get`

## 📚 Documentation

- [Supabase Flutter Docs](https://supabase.com/docs/reference/dart/introduction)
- [Phosphor Icons](https://phosphoricons.com/)
- [Google Fonts](https://fonts.google.com/specimen/Instrument+Sans)
