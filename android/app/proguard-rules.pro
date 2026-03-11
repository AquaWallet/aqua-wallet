# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep custom application class
-keep class io.aquawallet.** { *; }

# Keep RxJava
-dontwarn java.util.concurrent.Flow*
-dontwarn io.reactivex.**
-keep class io.reactivex.** { *; }

# Keep Biometric
-keep class androidx.biometric.** { *; }

# Fix for XmlPullParser conflict
-dontwarn org.xmlpull.v1.**
-dontwarn org.kxml2.io.**
-dontwarn android.content.res.**

# Keep XmlPull API and Android's XML classes
-keep class org.xmlpull.** { *; }
-keep class android.content.res.XmlResourceParser { *; }
-keep interface org.xmlpull.v1.XmlPullParser { *; }

# Critical fix for the specific conflict mentioned in the error
-keepnames class android.content.res.XmlResourceParser
-keepnames interface org.xmlpull.v1.XmlPullParser

# Keep implementations and extensions
-keep class * implements org.xmlpull.v1.XmlPullParser { *; }
-keep class * extends org.xmlpull.v1.XmlPullParser { *; }

# Prevent R8 from removing the implementation relationship
-if interface org.xmlpull.v1.XmlPullParser
-keep class android.content.res.XmlResourceParser

# Keep all methods in these classes
-keepclassmembers class android.content.res.XmlResourceParser {
    public *;
    protected *;
}
-keepclassmembers class * implements org.xmlpull.v1.XmlPullParser {
    <methods>;
}
