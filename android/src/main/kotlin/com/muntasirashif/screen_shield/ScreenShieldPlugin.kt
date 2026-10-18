package com.muntasirashif.screen_shield

import android.app.Activity
import android.os.Build
import android.view.WindowManager
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.function.Consumer

/**
 * Blocks screenshots and screen recording via FLAG_SECURE and reports capture
 * state (recording on API 35+, single screenshots on API 34+ while unblocked).
 *
 * All native work is idempotent and exception-safe, and is (un)registered with
 * the Activity lifecycle so returning from native flows (pickers, share sheets,
 * camera) cannot crash or wedge the host app.
 */
class ScreenShieldPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var lifecycle: Lifecycle? = null

    private var enabled = true
    private var suspended = false
    private var isRecording = false

    private var recordingCallbackRegistered = false
    private var screenCaptureCallback: Activity.ScreenCaptureCallback? = null
    private var screenCaptureCallbackRegistered = false

    private var eventSink: EventChannel.EventSink? = null

    private val recordingCallback = Consumer<Int> { state ->
        isRecording = state == WindowManager.SCREEN_RECORDING_STATE_VISIBLE
        eventSink?.success(if (isRecording) "recording" else "none")
    }

    // ── FlutterPlugin ────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ── ActivityAware ────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        activity = binding.activity
        // Flutter exposes the binding's Lifecycle as Object to avoid a hard
        // dependency in the embedding API; cast to the real type here.
        val lc = binding.lifecycle as? Lifecycle
        lifecycle = lc
        lc?.addObserver(lifecycleObserver)
        syncProtection()
        registerRecording()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        lifecycle?.removeObserver(lifecycleObserver)
        lifecycle = null
        unregisterRecording()
        unregisterScreenCapture()
        binding = null
        activity = null
    }

    private val lifecycleObserver = object : DefaultLifecycleObserver {
        override fun onStart(owner: LifecycleOwner) {
            syncProtection()
            registerRecording()
        }

        override fun onStop(owner: LifecycleOwner) {
            unregisterRecording()
            unregisterScreenCapture()
        }
    }

    // ── MethodChannel ────────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enable" -> {
                enabled = true
                suspended = false
                syncProtection()
                registerRecording()
                result.success(null)
            }
            "disable" -> {
                enabled = false
                unregisterRecording()
                syncProtection()
                result.success(null)
            }
            "suspend" -> {
                suspended = true
                syncProtection()
                result.success(null)
            }
            "resume" -> {
                suspended = false
                syncProtection()
                result.success(null)
            }
            "isEnabled" -> result.success(isProtected)
            "isCaptured" -> result.success(isRecording)
            else -> result.notImplemented()
        }
    }

    // ── EventChannel ─────────────────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        // Re-emit the current state so a capture already in progress is not missed.
        events.success(if (isRecording) "recording" else "none")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ── Internals ────────────────────────────────────────────────────────────

    private val isProtected: Boolean
        get() = enabled && !suspended

    /**
     * Applies the desired protection state. When protected, FLAG_SECURE is set
     * and the (mutually-exclusive) screenshot callback is unregistered; when
     * unprotected, the flag is cleared and screenshot detection is enabled.
     */
    private fun syncProtection() {
        val window = activity?.window ?: return
        if (isProtected) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
            unregisterScreenCapture()
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            registerScreenCapture()
        }
    }

    private fun registerRecording() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) return
        if (recordingCallbackRegistered) return
        val a = activity ?: return
        try {
            val initial = a.windowManager.addScreenRecordingCallback(
                a.mainExecutor,
                recordingCallback,
            )
            recordingCallbackRegistered = true
            recordingCallback.accept(initial)
        } catch (_: Exception) {
            recordingCallbackRegistered = false
        }
    }

    private fun unregisterRecording() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) return
        if (!recordingCallbackRegistered) return
        val a = activity ?: return
        try {
            a.windowManager.removeScreenRecordingCallback(recordingCallback)
        } catch (_: Exception) {
            // Ignore: the callback is gone either way.
        } finally {
            recordingCallbackRegistered = false
        }
    }

    private fun registerScreenCapture() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        if (screenCaptureCallbackRegistered) return
        val a = activity ?: return
        try {
            val callback = Activity.ScreenCaptureCallback { eventSink?.success("screenshot") }
            a.registerScreenCaptureCallback(a.mainExecutor, callback)
            screenCaptureCallback = callback
            screenCaptureCallbackRegistered = true
        } catch (_: Exception) {
            screenCaptureCallback = null
            screenCaptureCallbackRegistered = false
        }
    }

    private fun unregisterScreenCapture() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        if (!screenCaptureCallbackRegistered) return
        val a = activity ?: return
        val callback = screenCaptureCallback ?: return
        try {
            a.unregisterScreenCaptureCallback(callback)
        } catch (_: Exception) {
            // Ignore: the callback is gone either way.
        } finally {
            screenCaptureCallback = null
            screenCaptureCallbackRegistered = false
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "screen_shield/method"
        private const val EVENT_CHANNEL = "screen_shield/event"
    }
}
