# flutter_inapp_purchase (OpenIAP) and the Play Billing Library it wraps.
# R8 would otherwise strip classes reached only reflectively from the native
# side, which fails at runtime in release builds and nowhere else.
-keep class dev.hyo.** { *; }
-keep class io.github.hyochan.** { *; }
-keep class com.android.vending.billing.**
-keep class com.android.billingclient.** { *; }
-dontwarn dev.hyo.**
-dontwarn io.github.hyochan.**
