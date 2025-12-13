# ClearedToGo

Aviation checklist and flight planning app for pilots.

## Features

- Pre-flight checklists for multiple aircraft (Cessna 152, Cessna 172, Piper PA-28)
- Emergency procedures reference
- PAVE risk assessment
- Weight & Balance calculations
- Weather briefings
- Technical log
- PDF export functionality
- User authentication with AWS Cognito

---

## Android Release Build (Internal Testing)

This section explains how to build a signed release APK/AAB for uploading to Google Play Console (internal testing track).

### Prerequisites

1. **Flutter SDK** installed and in your PATH
2. **Android SDK** with API 34 (Android 14) installed
3. **Java 17** (required for Gradle)
4. A **release keystore** (see below for generation)

### Step 1: Generate a Release Keystore

If you don't already have a release keystore, create one:

```powershell
keytool -genkey -v -keystore c:\dev\flutter-checklist-app\android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:** You'll be prompted to create passwords. **Save these securely** - you'll need them for every release!

Recommended values:
- **Keystore password:** (create a strong password)
- **Key password:** (create a strong password, can be same as keystore password)
- **First and last name:** ClearedToGo
- **Organizational unit:** Aviation
- **Organization:** ClearedToGo
- **City/Locality:** (your city)
- **State/Province:** (your state)
- **Country code:** GB (or your country)

### Step 2: Create key.properties File

Create a file named `key.properties` in the `android/` directory (NOT in `android/app/`):

**File location:** `c:\dev\flutter-checklist-app\android\key.properties`

**Contents:**
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

Replace `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with the passwords you created in Step 1.

**⚠️ SECURITY WARNING:** The `key.properties` file and keystore are already in `.gitignore` and will NOT be committed to version control. Keep them secure and backed up!

### Step 3: Build the Release App Bundle

From the project root directory:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output location:**
```
c:\dev\flutter-checklist-app\build\app\outputs\bundle\release\app-release.aab
```

### Step 4: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (or create a new app)
3. Navigate to: **Testing → Internal testing**
4. Click **Create new release**
5. Upload the `.aab` file from the output location above
6. Fill in release notes
7. Click **Review release** → **Start rollout to internal testing**

---

## Alternative: Build a Release APK

If you need an APK instead of an AAB (for direct installation testing):

```powershell
flutter build apk --release
```

**Output location:**
```
c:\dev\flutter-checklist-app\build\app\outputs\flutter-apk\app-release.apk
```

---

## App Configuration

### Application ID
- **Package Name:** `com.clearedtogo.app`
- **App Name:** ClearedToGo

### Version Information
- **Current Version:** 1.0.0 (versionName)
- **Build Number:** 1 (versionCode)

To update the version for a new release:
1. Edit `pubspec.yaml`: Update the `version:` field (e.g., `1.0.1+2`)
2. Rebuild the app bundle

### SDK Versions
- **Minimum SDK:** 24 (Android 7.0)
- **Target SDK:** 34 (Android 14)
- **Compile SDK:** 34

---

## Troubleshooting

### "Execution failed for task ':app:signReleaseBundle'"

**Solution:** Check that `key.properties` exists and contains the correct passwords.

### "JAVA_HOME is not set"

**Solution:** Install Java 17 and set the `JAVA_HOME` environment variable:
```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
```

### "Flutter SDK not found"

**Solution:** Ensure Flutter is in your PATH:
```powershell
flutter doctor -v
```

### "Unsigned APK/AAB"

**Solution:** Ensure `key.properties` file exists in the correct location (`android/key.properties`, not `android/app/key.properties`).

---

## Development

For local development and testing:

```powershell
flutter run
```

For debug builds:

```powershell
flutter build apk --debug
```

---

## Admin Access (Development Only)

For testing purposes, the app includes an admin login:
- **Username:** Tom
- **Password:** David

**Note:** This is for development/testing only and bypasses normal authentication.

---

## Getting Started with Flutter

If this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
