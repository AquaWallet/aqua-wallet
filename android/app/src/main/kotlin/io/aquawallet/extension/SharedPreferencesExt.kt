package io.aquawallet.extension

import android.content.SharedPreferences
import io.reactivex.Single

fun SharedPreferences.getStringSingle(key: String): Single<String> = Single
        .create { emitter ->
            try {
                val value = getString(key, null) ?: throw SharedPreferencesNonExistingValueException
                emitter.onSuccess(value)
            } catch (e: Exception) {
                emitter.tryOnError(e)
            }
        }

object SharedPreferencesNonExistingValueException : Exception()
object SharedPreferencesUnableToCommitException : Exception()