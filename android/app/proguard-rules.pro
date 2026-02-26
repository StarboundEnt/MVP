# Starbound ProGuard Rules for Release Build

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve generic signatures
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Dart/Flutter native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Generative AI
-keep class com.google.** { *; }
-dontwarn com.google.**

# Gson (used by many plugins)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes (adjust package names as needed)
-keep class com.starbound.app.models.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# Local Notifications
-keep class com.dexterous.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Mobile Scanner
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }

# Encryption libraries
-keep class javax.crypto.** { *; }
-dontwarn javax.crypto.**

# OkHttp and HTTP clients
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# General Android rules
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep crashlytics (if added later)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
