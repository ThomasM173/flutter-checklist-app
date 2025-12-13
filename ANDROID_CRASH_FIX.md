# Android Startup Crash - Root Cause Analysis & Fix

## Issue Summary
**Status**: RESOLVED  
**Date**: December 13, 2025  
**Severity**: P0 - Complete app failure on Android

## Reproduction Steps
1. Build release or debug APK/AAB
2. Install on Android device or emulator  
3. Launch app
4. **Result**: App crashes immediately with blank screen - never reaches UI

## Root Cause

### Primary Issue: ClassNotFoundException
**Evidence from logcat:**
```
E AndroidRuntime: FATAL EXCEPTION: main
E AndroidRuntime: java.lang.RuntimeException: Unable to instantiate activity 
  ComponentInfo{com.clearedtogo.app/com.clearedtogo.app.MainActivity}:
  java.lang.ClassNotFoundException: Didn't find class "com.clearedtogo.app.MainActivity"
```

**Problem**: The MainActivity.kt file was in the wrong package directory.

**Expected path**: `android/app/src/main/kotlin/com/clearedtogo/app/MainActivity.kt`  
**Actual path**: `android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt`

**Package mismatch**:
- AndroidManifest.xml declares: `package="com.clearedtogo.app"`
- build.gradle.kts declares: `namespace = "com.clearedtogo.app"` and `applicationId = "com.clearedtogo.app"`
- MainActivity.kt was in: `package com.example.flutter_application_1`

This is a legacy issue from when the project was created with the default Flutter template name, then renamed but the Kotlin file was never moved/updated.

## Fix Implemented

### 1. Created Correct Directory Structure
```bash
android/app/src/main/kotlin/com/clearedtogo/app/
```

### 2. Created MainActivity.kt with Correct Package
**File**: `android/app/src/main/kotlin/com/clearedtogo/app/MainActivity.kt`
```kotlin
package com.clearedtogo.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

### 3. Added Global Error Handlers (Prevention)
**File**: `lib/main.dart`

Added comprehensive error handling to catch and log any future issues:
```dart
// Flutter framework errors
FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  safePrint('Flutter Error: ${details.exception}');
  safePrint('Stack: ${details.stack}');
};

// Platform errors (uncaught async exceptions)
PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
  safePrint('Platform Error: $error');
  safePrint('Stack: $stack');
  return true;
};
```

## Files Modified

1. **Created**: `android/app/src/main/kotlin/com/clearedtogo/app/MainActivity.kt`
   - New file with correct package declaration

2. **Modified**: `lib/main.dart`
   - Added `dart:async` import
   - Added `dart:foundation` import  
   - Added FlutterError.onError handler
   - Added PlatformDispatcher.instance.onError handler

## Why This Wasn't Caught Earlier

1. **Build succeeds**: Gradle doesn't validate that the MainActivity exists in the declared package until runtime
2. **APK/AAB builds successfully**: The build system doesn't check class path consistency
3. **Only fails at runtime**: Android only discovers the missing class when trying to launch the Activity

## Testing Performed

### Before Fix
- ✅ APK builds successfully
- ❌ App crashes immediately on launch
- ❌ ClassNotFoundException in logcat
- ❌ Never reaches Flutter UI

### After Fix  
- ✅ APK builds successfully
- ✅ MainActivity found and instantiated
- ✅ App launches to UI
- ✅ No ClassNotFoundException

## Prevention Measures

1. **Error Logging**: Global error handlers will now catch and log all unhandled exceptions
2. **Build Validation**: Future package/namespace changes should verify MainActivity path
3. **Testing Checklist**: Always test on actual device/emulator before release builds

## Related Issues Fixed Previously

These timeout fixes were already in place and remain valuable:
- Amplify configuration: 5-second timeout
- Auth session checks: 3-second timeouts
- Sign in/up operations: 10-second timeouts
- These prevent network-related hanging (secondary issue)

## Clean Build Required

After this fix, always run:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

This ensures old build artifacts from the wrong package path are cleared.

## Verification Checklist

- [x] MainActivity.kt exists in correct package path
- [x] Package declaration matches namespace/applicationId
- [x] Global error handlers installed
- [x] App launches on emulator
- [ ] App launches on physical device
- [ ] Release build works  
- [ ] Internal testing build works

## Next Steps

1. Test app launch on physical device
2. Upload new release build (version 1.0.1+5) to Google Play
3. Verify internal testing build works
4. Test admin login (Tom/David) works offline
5. Test Cognito login works with network

## Conclusion

The Android startup crash was **not** related to Amplify, async operations, or network issues. It was a simple but critical build configuration error: the MainActivity was in the wrong package directory, causing Android to fail to instantiate the Activity at launch.

The fix was straightforward: create the correct directory structure and MainActivity.kt with the proper package declaration.
