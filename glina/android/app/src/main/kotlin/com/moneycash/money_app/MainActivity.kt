package com.moneycash.money_app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 12+: системная заставка (фон + иконка G1) снимается сразу,
        // без своей анимации ухода. Под ней тот же цвет фона, а дальше играет
        // Flutter-заставка: иначе между ними заметен скачок.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }
}
