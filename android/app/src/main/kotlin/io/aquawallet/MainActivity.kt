package io.aquawallet

import android.content.Context
import android.security.keystore.KeyProperties
import android.view.WindowManager
import androidx.annotation.NonNull
import io.aquawallet.extension.SharedPreferencesUnableToCommitException
import io.aquawallet.extension.callHandlerFlowable
import io.aquawallet.extension.getStringSingle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.reactivex.BackpressureStrategy
import io.reactivex.Flowable
import io.reactivex.Single
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.schedulers.Schedulers
import kotlin.system.exitProcess

class MainActivity : FlutterFragmentActivity() {


    private val UTILS_CHANNEL = "com.example.aqua/utils"

    private val disposable = CompositeDisposable()

    override fun onDestroy() {
        // This will terminate flutter but not the process itself.
        // So when the app is restored old FFI will crash as Flutter port will be closed now.
        // Terminating the process as workaround.
        super.onDestroy()
        exitProcess(0)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UTILS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "addWindowSecureFlags" -> {
                    getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "clearWindowSecureFlags" -> {
                    getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        disposable.clear()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    object ChannelIllegalArgumentsException : Exception()
}
