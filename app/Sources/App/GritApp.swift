import SwiftUI
import AppKit

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

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(self)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow(_ window: NSWindow) {
        window.styleMask.insert([.titled, .resizable, .miniaturizable, .closable])
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = false
        window.tabbingMode = .disallowed
        window.toolbar = nil
        window.backgroundColor = NSColor.windowBackgroundColor
        window.titlebarSeparatorStyle = .automatic
        window.styleMask.remove(.fullSizeContentView)
        window.collectionBehavior.remove(.fullScreenAuxiliary)
        window.collectionBehavior.insert(.fullScreenPrimary)
    }

    func window(
        _ window: NSWindow,
        willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions
    ) -> NSApplication.PresentationOptions {
        var options = proposedOptions
        options.remove(.autoHideToolbar)
        return options
    }
}
