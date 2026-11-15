package com.moneycash.money_app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Flutter draws the same mark right away, so skip the system exit animation.
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }
}
