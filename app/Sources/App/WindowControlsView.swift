import SwiftUI
import AppKit

struct WindowControlsView: View {
    var body: some View {
        HStack(spacing: 6) {
            WindowControlDot(color: Color(red: 0.95, green: 0.32, blue: 0.30)) {
                activeWindow()?.performClose(nil)
            }
            WindowControlDot(color: Color(red: 0.98, green: 0.78, blue: 0.25)) {
                activeWindow()?.miniaturize(nil)
            }
            WindowControlDot(color: Color(red: 0.17, green: 0.78, blue: 0.35)) {
                activeWindow()?.toggleFullScreen(nil)
            }
        }
        .frame(height: 12)
    }

    private func activeWindow() -> NSWindow? {
        NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
    }
}

private struct WindowControlDot: View {
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.25), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
