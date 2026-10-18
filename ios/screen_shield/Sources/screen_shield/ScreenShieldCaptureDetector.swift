import Flutter
import UIKit

/// Reports whether the device screen is currently being captured — screen
/// recording, AirPlay/QuickTime mirroring, etc. — and, after the fact, single
/// screenshots.
///
/// Detection is device-wide on iOS: `UIScreen.isCaptured` is `true` whenever
/// the screen is captured at all, regardless of which app is on screen, and the
/// notification also fires while the app is backgrounded (e.g. with music
/// playing).
///
/// Events are strings (`"none"` | `"recording"` | `"screenshot"`) so the wire
/// format can grow without breaking Dart clients.
final class ScreenShieldCaptureDetector: NSObject, FlutterStreamHandler {

    static let channelName = "screen_shield/event"

    /// Retained so the channel's message handler is not dropped: the binary
    /// messenger holds the handler through a weak reference to the channel.
    private var channel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    /// Current device-wide capture state (one-shot read).
    var isCapturedNow: Bool { UIScreen.main.isCaptured }

    /// Registers the event channel on `messenger` and returns the detector.
    /// The caller must keep a strong reference for as long as events are wanted.
    static func register(messenger: FlutterBinaryMessenger) -> ScreenShieldCaptureDetector {
        let detector = ScreenShieldCaptureDetector()
        let channel = FlutterEventChannel(name: channelName, binaryMessenger: messenger)
        channel.setStreamHandler(detector)
        detector.channel = channel
        return detector
    }

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(capturedDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        // Emit the current state so a capture already in progress is not missed.
        events(UIScreen.main.isCaptured ? "recording" : "none")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    @objc private func capturedDidChange() {
        eventSink?(UIScreen.main.isCaptured ? "recording" : "none")
    }

    @objc private func userDidTakeScreenshot() {
        eventSink?("screenshot")
    }
}
