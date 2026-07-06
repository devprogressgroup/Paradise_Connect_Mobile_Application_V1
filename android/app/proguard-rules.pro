# Firebase Cloud Messaging / Firebase core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Play Core (referenced by Flutter engine's deferred-components code path even when unused)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# webview_flutter JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# socket_io_client / okhttp / okio
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class io.socket.** { *; }

# Keep native method signatures
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable CREATOR fields (geolocator, camera, etc. pass Parcelables across plugin channels)
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
