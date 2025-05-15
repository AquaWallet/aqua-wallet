package io.aquawallet.uicomponents

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            super.onCreate(savedInstanceState)
            // Your existing code
        } catch (e: Exception) {
            Log.e("AppStartup", "Critical startup error", e)
        }
    }
}
