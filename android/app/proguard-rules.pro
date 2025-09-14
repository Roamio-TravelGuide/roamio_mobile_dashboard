-keepattributes Signature
-keepattributes *Annotation*

-keep interface retrofit2.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

-keep class lk.payhere.** { *; }
-keep interface lk.payhere.androidsdk.PayhereSDK { *; }
-keep class lk.payhere.androidsdk.models.** { *; }
