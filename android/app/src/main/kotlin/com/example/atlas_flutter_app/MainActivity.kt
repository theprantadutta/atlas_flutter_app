package com.example.atlas_flutter_app

import android.content.res.Resources
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

// A FlutterFragmentActivity (a ComponentActivity) so the window can use
// androidx.activity's enableEdgeToEdge, the call Play expects. The older
// WindowCompat.enableEdgeToEdge from androidx.core set the bar colours through
// Android 15's deprecated setStatusBarColor/setNavigationBarColor, which Play
// flagged.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Draw behind the system bars on every version, the way Android 15+
        // already insists on. The app pads for the insets itself and never
        // colours the bars. enableEdgeToEdge reloads the window background,
        // which fails on an install missing its density split (a sideloaded
        // base APK); losing edge-to-edge there beats crashing before Flutter
        // starts.
        try {
            enableEdgeToEdge()
        } catch (e: Resources.NotFoundException) {
            Log.w("Atlas", "Edge-to-edge skipped: ${e.message}")
        }
        super.onCreate(savedInstanceState)
        // Flutter's splash draws the same spark in the same spot, so drop the
        // system splash at once instead of letting the OEM exit animation slide
        // its icon away over ours (One UI does).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }
}
