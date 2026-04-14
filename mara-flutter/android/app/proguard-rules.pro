# Flutter ProGuard rules
# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }

# Keep Hive
-keep class com.hivedb.** { *; }
-keepclassmembers class * {
    @com.hivedb.hive.annotations.HiveType <fields>;
}

# Keep model classes used with Hive adapters
-keep class bf.mara.mara_flutter.** { *; }

# OkHttp (used by Dio)
-dontwarn okhttp3.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# WebSocket / WebView related
-keep class com.google.** { *; }

# Suppress warnings for missing classes in release builds
-dontwarn io.flutter.embedding.**
-dontwarn okio.**
