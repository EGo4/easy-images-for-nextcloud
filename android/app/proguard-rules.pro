# Keep Error Prone annotations used by Tink
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Keep javax.annotation.concurrent annotations
-dontwarn javax.annotation.concurrent.**
-keep class javax.annotation.concurrent.** { *; }

# Keep Tink crypto classes
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**