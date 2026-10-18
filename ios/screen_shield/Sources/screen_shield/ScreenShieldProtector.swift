import Flutter
import ObjectiveC
import UIKit

/// Blocks screenshots and screen recordings for the whole app on iOS.
///
/// A full-screen `UITextField` with `isSecureTextEntry = true` carries a
/// protected `IOSurface` on one of its internal layers. The Flutter view's layer
/// is re-parented inside that protected layer, so the entire UI renders black in
/// screenshots and screen recordings.
///
/// Design notes (mirroring the proven `flutter_screenshot_blocker` approach):
/// - `window.layer` is never moved — only `flutterView.layer`, one level lower.
///   Moving the window's own layer violates a UIKit invariant and crashes.
/// - The anchor is `field.layer.sublayers.last` on iOS 17+ (`first` on older
///   iOS); the first sublayer on iOS 17+ is a decoration layer without the
///   protection flag.
/// - `flutterView.layer.position`/`bounds` are reset after the move so the
///   coordinate space stays correct (otherwise the app renders blank).
/// - The `UITextField` must stay in the view hierarchy for the protection to
///   remain effective.
///
/// **Modals:** presenting a native modal (document/photo picker, share sheet,
/// alerts…) while the Flutter layer is re-parented leaves UIKit's layer tree
/// inconsistent — the window then stops receiving touches after the modal is
/// dismissed (the app appears frozen). To avoid that, protection is *suspended*
/// (the Flutter layer is moved back to its normal place) for the duration of any
/// presented modal and re-applied once it is dismissed.
///
/// This is a no-op on the Simulator (the protected surface only exists on real
/// hardware, and blocking cannot be verified there anyway).
enum ScreenShieldProtector {

    private static weak var targetWindow: UIWindow?
    private static weak var protectedView: UIView?
    private static weak var originalSuperlayer: CALayer?
    private static var secureField: UITextField?
    private static var hasSwizzled = false

    /// Whether protection is currently desired. The plugin sets this on
    /// enable/disable so that backgrounding or a dismissed modal cannot silently
    /// re-apply protection after `disable()`.
    static var isEnabled = true

    private static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()

    /// Installs the modal observers exactly once, at launch, so protection can
    /// be suspended before any native modal is presented.
    static func start() {
        guard !isSimulator, !hasSwizzled else { return }
        hasSwizzled = true
        swizzle(
            UIViewController.self,
            original: #selector(UIViewController.present(_:animated:completion:)),
            replacement: #selector(UIViewController.ss_present(_:animated:completion:))
        )
        swizzle(
            UIViewController.self,
            original: #selector(UIViewController.dismiss(animated:completion:)),
            replacement: #selector(UIViewController.ss_dismiss(animated:completion:))
        )
    }

    /// Installs protection on the current key window. Safe to call repeatedly:
    /// it re-attaches when the scene (and its window) is re-created.
    static func installOnActiveWindow() {
        // The protected IOSurface only exists on real hardware, so this is a
        // no-op on the Simulator.
        if isSimulator { return }
        if !isEnabled { return }

        guard let window = activeWindow() else { return }
        // Never touch the layer tree while a modal is presented; leave it
        // suspended until the modal is dismissed.
        if window.rootViewController?.presentedViewController != nil { return }
        guard let flutterView = window.rootViewController?.view else { return }
        install(on: window, flutterView: flutterView)
    }

    /// Moves the Flutter layer back to its normal place so native modals present
    /// and dismiss with an intact layer tree. Re-applied by [resume].
    static func suspend() {
        guard let window = targetWindow, let flutterView = protectedView,
            secureField != nil
        else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let parent = originalSuperlayer ?? window.layer
        parent.addSublayer(flutterView.layer)
        flutterView.layer.position = CGPoint(
            x: flutterView.bounds.midX,
            y: flutterView.bounds.midY
        )
        flutterView.layer.bounds = flutterView.bounds
        CATransaction.commit()

        secureField?.removeFromSuperview()
        secureField = nil
    }

    /// Re-applies protection after a modal is dismissed. Deferred a runloop so
    /// UIKit has finished tearing the modal down.
    static func resume() {
        guard isEnabled else { return }
        DispatchQueue.main.async { installOnActiveWindow() }
    }

    private static func activeWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }

        // Only ever protect the app's own Flutter window. Transient system
        // windows (document/photo pickers, alerts, the app switcher) must be
        // left untouched: re-parenting their view hierarchy breaks their
        // rendering and — because this runs again on every `didBecomeKey` /
        // `applicationDidBecomeActive` — leaves the app unable to receive
        // touches once the transient window closes (e.g. after cancelling the
        // audio picker).
        if let flutterKeyWindow = windows.first(where: {
            $0.isKeyWindow && $0.rootViewController is FlutterViewController
        }) {
            return flutterKeyWindow
        }
        return windows.first(where: {
            $0.rootViewController is FlutterViewController
        })
    }

    private static func install(on window: UIWindow, flutterView: UIView) {
        if targetWindow === window, protectedView === flutterView,
            secureField?.superview === window {
            return
        }

        // Remember where the Flutter layer belongs so [suspend] can restore it.
        originalSuperlayer = flutterView.layer.superlayer ?? window.layer

        secureField?.removeFromSuperview()
        secureField = nil

        // Full-screen secure field. Constrained to fill the window so its layer's
        // coordinate space matches the window's.
        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        field.backgroundColor = .clear
        field.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(field)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: window.topAnchor),
            field.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            field.bottomAnchor.constraint(equalTo: window.bottomAnchor),
        ])
        // Force UITextField to build its internal sublayer tree synchronously.
        window.setNeedsLayout()
        window.layoutIfNeeded()

        // iOS ≤ 16: the protected IOSurface is at sublayers[0] (first).
        // iOS 17+: a decoration/glass layer occupies first; the protected layer
        // is last.
        let sublayers = field.layer.sublayers ?? []
        let secureAnchor: CALayer
        if #available(iOS 17.0, *) {
            secureAnchor = sublayers.last ?? field.layer
        } else {
            secureAnchor = sublayers.first ?? field.layer
        }

        // window.layer → [field.layer → secureAnchor(protected) → flutterView.layer]
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        secureAnchor.addSublayer(flutterView.layer)
        flutterView.layer.position = CGPoint(
            x: flutterView.bounds.midX,
            y: flutterView.bounds.midY
        )
        flutterView.layer.bounds = flutterView.bounds
        CATransaction.commit()

        targetWindow = window
        protectedView = flutterView
        secureField = field
    }

    private static func swizzle(
        _ cls: AnyClass,
        original: Selector,
        replacement: Selector
    ) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
            let replacementMethod = class_getInstanceMethod(cls, replacement)
        else { return }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }
}

extension UIViewController {
    /// Suspends screenshot protection before a native modal is presented so the
    /// modal's presentation does not corrupt UIKit's layer tree.
    @objc fileprivate func ss_present(
        _ viewControllerToPresent: UIViewController,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        ScreenShieldProtector.suspend()
        ss_present(
            viewControllerToPresent,
            animated: animated,
            completion: completion
        )
    }

    /// Re-applies screenshot protection once a native modal is dismissed.
    @objc fileprivate func ss_dismiss(
        animated: Bool,
        completion: (() -> Void)?
    ) {
        ss_dismiss(animated: animated) {
            completion?()
            ScreenShieldProtector.resume()
        }
    }
}
