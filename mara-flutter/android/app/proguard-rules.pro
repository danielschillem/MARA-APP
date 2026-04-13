# Flutter ProGuard rules
# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive
-keep class com.hivedb.** { *; }
-keepclassmembers class * {
    @com.hivedb.hive.annotations.HiveType <fields>;
}

# Keep model classes used with Hive adapters
-keep class bf.mara.mara_flutter.** { *; }

# Suppress warnings for missing classes in release builds
-dontwarn io.flutter.embedding.**
