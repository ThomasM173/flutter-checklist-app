# Keep Error Prone annotations (used by Google Crypto Tink)
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Keep javax annotations
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }

# Keep all classes used by Amplify
-keep class com.amplifyframework.** { *; }
-keep class com.amazonaws.** { *; }
-keepattributes *Annotation*

# Keep Google Crypto Tink
-keep class com.google.crypto.tink.** { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
