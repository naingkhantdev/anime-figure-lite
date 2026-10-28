# Extra R8 rules for release builds. Flutter and the Firebase plugins ship
# their own keep rules; add here only what a release build proves is missing.

# Keep line numbers so Crashlytics stack traces point at the right line.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
