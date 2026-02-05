import SwiftUI
import AppKit
import ObjectiveC

@main
enum GritMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var windowController: NSWindowController?
    private static var accessoryKey: UInt8 = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        createMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = windowController?.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            createMainWindow()
        }
        return false
    }

    private func createMainWindow() {
        let hosting = NSHostingController(rootView: ContentView())
        let window = NSWindow(contentViewController: hosting)
        window.setContentSize(NSSize(width: 1100, height: 720))
        configureWindow(window)
        window.delegate = self
        attachAccessoryIfNeeded(to: window)

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(self)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow(_ window: NSWindow) {
        window.styleMask.insert([.titled, .resizable, .miniaturizable, .closable])
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.20, alpha: 1.0)
        window.titlebarSeparatorStyle = .none
        window.styleMask.insert(.fullSizeContentView)
        window.collectionBehavior.remove(.fullScreenAuxiliary)
        window.collectionBehavior.insert(.fullScreenPrimary)
        NSApp.appearance = NSAppearance(named: .darkAqua)
        window.appearance = NSAppearance(named: .darkAqua)
        applyZoomButtonBehavior(window)
    }

    func windowDidBecomeMain(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            configureWindow(window)
            attachAccessoryIfNeeded(to: window)
            applyZoomButtonBehavior(window)
        }
    }

    private func applyZoomButtonBehavior(_ window: NSWindow) {
        if let zoom = window.standardWindowButton(.zoomButton) {
            zoom.target = window
            zoom.action = #selector(NSWindow.toggleFullScreen(_:))
            zoom.isEnabled = true
        }
    }

    private func attachAccessoryIfNeeded(to window: NSWindow) {
        let existing = objc_getAssociatedObject(window, &Self.accessoryKey) as? TitlebarAccessoryController
        if existing == nil {
            let accessory = TitlebarAccessoryController()
            window.addTitlebarAccessoryViewController(accessory)
            objc_setAssociatedObject(window, &Self.accessoryKey, accessory, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

final class TitlebarAccessoryController: NSTitlebarAccessoryViewController {
    private let hostingView = NSHostingView(rootView: TopBar(viewModel: RepoViewModel.shared))
    private let trafficContainer = NSView()
    private var observers: [NSObjectProtocol] = []

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(
            calibratedRed: 0.15,
            green: 0.16,
            blue: 0.20,
            alpha: 1.0
        ).cgColor

        trafficContainer.translatesAutoresizingMaskIntoConstraints = false
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(trafficContainer)
        container.addSubview(hostingView)

        NSLayoutConstraint.activate([
            trafficContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            trafficContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            trafficContainer.heightAnchor.constraint(equalToConstant: 14),

            hostingView.leadingAnchor.constraint(equalTo: trafficContainer.trailingAnchor, constant: 10),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6),
            hostingView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            hostingView.heightAnchor.constraint(equalToConstant: 20),

            container.heightAnchor.constraint(equalToConstant: 24)
        ])

        view = container
        layoutAttribute = .top
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        attachTrafficLights()
        observeFullscreenTransitions()
    }

    private func observeFullscreenTransitions() {
        guard let window = view.window else { return }
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()

        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.attachTrafficLights()
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.attachTrafficLights()
        })
    }

    private func attachTrafficLights() {
        guard let window = view.window ?? NSApp.keyWindow ?? NSApp.mainWindow else { return }
        let buttons: [NSButton] = [
            window.standardWindowButton(.closeButton),
            window.standardWindowButton(.miniaturizeButton),
            window.standardWindowButton(.zoomButton)
        ].compactMap { $0 }

        guard buttons.count == 3 else { return }

        if let zoom = buttons.last {
            zoom.target = window
            zoom.action = #selector(NSWindow.toggleFullScreen(_:))
            zoom.isEnabled = true
        }

        let needsMove = buttons.contains { $0.superview !== trafficContainer }
        guard needsMove else { return }

        for button in buttons {
            button.removeFromSuperview()
            button.translatesAutoresizingMaskIntoConstraints = false
            trafficContainer.addSubview(button)
        }

        let spacing: CGFloat = 6
        let size: CGFloat = 12

        NSLayoutConstraint.activate([
            buttons[0].leadingAnchor.constraint(equalTo: trafficContainer.leadingAnchor),
            buttons[0].centerYAnchor.constraint(equalTo: trafficContainer.centerYAnchor),
            buttons[0].widthAnchor.constraint(equalToConstant: size),
            buttons[0].heightAnchor.constraint(equalToConstant: size),

            buttons[1].leadingAnchor.constraint(equalTo: buttons[0].trailingAnchor, constant: spacing),
            buttons[1].centerYAnchor.constraint(equalTo: trafficContainer.centerYAnchor),
            buttons[1].widthAnchor.constraint(equalToConstant: size),
            buttons[1].heightAnchor.constraint(equalToConstant: size),

            buttons[2].leadingAnchor.constraint(equalTo: buttons[1].trailingAnchor, constant: spacing),
            buttons[2].centerYAnchor.constraint(equalTo: trafficContainer.centerYAnchor),
            buttons[2].widthAnchor.constraint(equalToConstant: size),
            buttons[2].heightAnchor.constraint(equalToConstant: size),

            buttons[2].trailingAnchor.constraint(equalTo: trafficContainer.trailingAnchor)
        ])
    }
}
