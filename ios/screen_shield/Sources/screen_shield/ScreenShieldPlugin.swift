import Flutter
import UIKit

public class ScreenShieldPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var detector: ScreenShieldCaptureDetector?
  private var enabled = true
  private var windowObserver: NSObjectProtocol?
  private var activeObserver: NSObjectProtocol?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ScreenShieldPlugin()
    let method = FlutterMethodChannel(name: "screen_shield/method",
                                      binaryMessenger: registrar.messenger())
    method.setMethodCallHandler(instance.handle)
    instance.methodChannel = method
    instance.detector = ScreenShieldCaptureDetector.register(messenger: registrar.messenger())

    ScreenShieldProtector.start()
    ScreenShieldProtector.isEnabled = instance.enabled
    instance.windowObserver = NotificationCenter.default.addObserver(
      forName: UIWindow.didBecomeKeyNotification, object: nil, queue: .main
    ) { _ in ScreenShieldProtector.installOnActiveWindow() }
    instance.activeObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in ScreenShieldProtector.installOnActiveWindow() }

    registrar.publish(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    if let observer = windowObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if let observer = activeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    methodChannel?.setMethodCallHandler(nil)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enable":
      enabled = true
      ScreenShieldProtector.isEnabled = true
      ScreenShieldProtector.resume()
      result(nil)
    case "disable":
      enabled = false
      ScreenShieldProtector.isEnabled = false
      ScreenShieldProtector.suspend()
      result(nil)
    case "suspend":
      ScreenShieldProtector.suspend()
      result(nil)
    case "resume":
      if enabled { ScreenShieldProtector.resume() }
      result(nil)
    case "isEnabled":
      result(enabled)
    case "isCaptured":
      result(detector?.isCapturedNow ?? UIScreen.main.isCaptured)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
