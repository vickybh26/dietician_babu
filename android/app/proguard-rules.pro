# ─── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ─── Firebase ─────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ─── Razorpay ─────────────────────────────────────────────────────────────────
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
# Razorpay uses Proguard — required to prevent crashes
-keepattributes *Annotation*
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ─── Google Sign-In ───────────────────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ─── Kotlin / Coroutines ──────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# ─── Gson / JSON ─────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes EnclosingMethod
-keep class sun.misc.Unsafe { *; }

# ─── OkHttp / Dio ─────────────────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ─── App-specific model classes ───────────────────────────────────────────────
# Prevent stripping of any data classes passed to/from Firestore
-keep class com.example.dietician_babu.** { *; }
-keep class com.dietician_babu.app.** { *; }

# ─── Suppress leftover Stripe warnings (package not in use) ───────────────────
-dontwarn com.stripe.**
