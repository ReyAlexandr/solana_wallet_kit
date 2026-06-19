package dev.solanawalletkit

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class SolanaWalletKitPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {

    private var channel: MethodChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingExport: PendingExport? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        finishWithError("unavailable", "Wallet export became unavailable.")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity()
        finishWithError("unavailable", "Wallet export requires an Android activity.")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            EXPORT_METHOD -> beginExport(call, result)
            else -> result.notImplemented()
        }
    }

    private fun beginExport(call: MethodCall, result: MethodChannel.Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("unavailable", "Wallet export requires an Android activity.", null)
            return
        }

        if (pendingExport != null) {
            result.error("busy", "Another wallet export is already in progress.", null)
            return
        }

        val fileName = call.argument<String>("fileName")?.trim().orEmpty()
        val contents = call.argument<String>("contents")
        val mimeType = call.argument<String>("mimeType")?.trim().orEmpty()

        if (fileName.isEmpty() || contents == null) {
            result.error("invalid_arguments", "Wallet export data is incomplete.", null)
            return
        }

        pendingExport = PendingExport(contents, result)

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType.ifEmpty { DEFAULT_MIME_TYPE }
            putExtra(Intent.EXTRA_TITLE, fileName)
        }

        try {
            activity.startActivityForResult(intent, EXPORT_REQUEST_CODE)
        } catch (error: Exception) {
            finishWithError(
                "document_picker_unavailable",
                "No Android document provider is available.",
                error.message,
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != EXPORT_REQUEST_CODE) return false

        val pending = pendingExport ?: return true
        pendingExport = null

        if (resultCode != Activity.RESULT_OK) {
            pending.result.success(false)
            return true
        }

        val activity = activityBinding?.activity
        val uri = data?.data
        if (activity == null || uri == null) {
            pending.result.error("write_failed", "Android did not return a file destination.", null)
            return true
        }

        try {
            val output = activity.contentResolver.openOutputStream(uri, "w")
            if (output == null) {
                pending.result.error("write_failed", "Could not open the selected file.", null)
                return true
            }

            output.use { stream ->
                stream.write(pending.contents.toByteArray(Charsets.UTF_8))
                stream.flush()
            }
            pending.result.success(true)
        } catch (error: Exception) {
            pending.result.error(
                "write_failed",
                "Could not write the wallet backup.",
                error.message,
            )
        }

        return true
    }

    private fun detachFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    private fun finishWithError(code: String, message: String, details: String? = null) {
        val pending = pendingExport ?: return
        pendingExport = null
        pending.result.error(code, message, details)
    }

    private data class PendingExport(
        val contents: String,
        val result: MethodChannel.Result,
    )

    private companion object {
        const val CHANNEL_NAME = "solana_wallet_kit/backup"
        const val EXPORT_METHOD = "exportBackup"
        const val EXPORT_REQUEST_CODE = 7412
        const val DEFAULT_MIME_TYPE = "application/json"
    }
}
