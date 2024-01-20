package io.aquawallet.extension

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.reactivex.BackpressureStrategy
import io.reactivex.Flowable
import io.reactivex.android.MainThreadDisposable

fun MethodChannel.callHandlerFlowable(): Flowable<Pair<MethodCall, MethodChannel.Result>> = Flowable
        .create({ emitter ->
            val callHandler = MethodChannel.MethodCallHandler { call, result ->
                emitter.onNext(Pair(call, result))
            }
            emitter.setDisposable(object : MainThreadDisposable() {
                override fun onDispose() {
                    setMethodCallHandler(null)
                }
            })
            setMethodCallHandler(callHandler)
        }, BackpressureStrategy.LATEST)