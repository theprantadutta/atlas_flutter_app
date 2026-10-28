package com.example.atlas_flutter_app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Draw behind the system bars on every version, the way Android 15+
        // already insists on. The app pads for the insets itself and never
        // colours the bars, which keeps it off the deprecated bar-colour APIs.
        WindowCompat.enableEdgeToEdge(window)
        super.onCreate(savedInstanceState)
        // Flutter's splash draws the same spark in the same spot, so drop the
        // system splash at once instead of letting the OEM exit animation slide
        // its icon away over ours (One UI does).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }
}
