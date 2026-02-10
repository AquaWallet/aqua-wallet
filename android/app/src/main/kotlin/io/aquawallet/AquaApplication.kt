package io.aquawallet

import android.os.StrictMode
import io.flutter.app.FlutterApplication
import io.aquawallet.BuildConfig

class AquaApplication : FlutterApplication() {
    override fun onCreate() {
        // Enable strict mode in debug builds to catch issues early
        if (BuildConfig.DEBUG) {
            StrictMode.setThreadPolicy(
                StrictMode.ThreadPolicy.Builder()
                    .detectDiskReads()
                    .detectDiskWrites()
                    .detectNetwork()
                    .penaltyLog()
                    .build()
            )
            StrictMode.setVmPolicy(
                StrictMode.VmPolicy.Builder()
                    .detectLeakedSqlLiteObjects()
                    .detectLeakedClosableObjects()
                    .penaltyLog()
                    .build()
            )
        }

        super.onCreate()
    }
}
