## Flutter specific ProGuard rules
# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep plugin registrant
-keep class io.flutter.app.FlutterApplication { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep Gson / JSON serialization (if used by any plugin)
-keep class com.google.gson.** { *; }
-keepattributes Signature

# Suppress warnings for common Flutter plugin patterns
-dontwarn io.flutter.**
-dontwarn android.**
