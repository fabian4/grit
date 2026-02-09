import SwiftUI
import AppKit

enum AppTheme {
    static let accent = Color(red: 0.20, green: 0.53, blue: 0.98)
    static let accentSecondary = Color(red: 0.31, green: 0.59, blue: 0.95)
    static let chromeDark = adaptive(
        light: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.98, alpha: 1),
        dark: NSColor(calibratedRed: 0.094, green: 0.102, blue: 0.122, alpha: 1)
    )
    static let sidebarDark = adaptive(
        light: NSColor(calibratedRed: 0.93, green: 0.94, blue: 0.96, alpha: 1),
        dark: NSColor(calibratedRed: 0.082, green: 0.090, blue: 0.110, alpha: 1)
    )
    static let mainDark = adaptive(
        light: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1),
        dark: NSColor(calibratedRed: 0.106, green: 0.118, blue: 0.141, alpha: 1)
    )
    static let panelDark = adaptive(
        light: NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.96, alpha: 1),
        dark: NSColor(calibratedRed: 0.125, green: 0.140, blue: 0.173, alpha: 1)
    )
    static let backgroundTop = mainDark
    static let backgroundBottom = mainDark
    static let panelStroke = adaptive(light: NSColor.black.withAlphaComponent(0.10), dark: NSColor.white.withAlphaComponent(0.08))
    static let mutedText = adaptive(light: NSColor.black.withAlphaComponent(0.45), dark: NSColor.white.withAlphaComponent(0.45))
    static let fieldFill = adaptive(light: NSColor.black.withAlphaComponent(0.05), dark: NSColor.white.withAlphaComponent(0.10))
    static let chromeDarkElevated = adaptive(light: NSColor.black.withAlphaComponent(0.06), dark: NSColor.white.withAlphaComponent(0.07))
    static let chromeDivider = adaptive(light: NSColor.black.withAlphaComponent(0.10), dark: NSColor.white.withAlphaComponent(0.08))
    static let chromeText = adaptive(light: NSColor.black.withAlphaComponent(0.78), dark: NSColor.white.withAlphaComponent(0.86))
    static let chromeMuted = adaptive(light: NSColor.black.withAlphaComponent(0.50), dark: NSColor.white.withAlphaComponent(0.45))
    static let editorBackground = mainDark
    static let editorHeader = mainDark
    static let editorDivider = adaptive(light: NSColor.black.withAlphaComponent(0.10), dark: NSColor.white.withAlphaComponent(0.08))
    static let windowBackdrop = adaptive(
        light: NSColor(calibratedRed: 0.89, green: 0.90, blue: 0.92, alpha: 1),
        dark: NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.17, alpha: 1)
    )

    static let diffAddedFill = Color(red: 0.11, green: 0.32, blue: 0.18).opacity(0.55)
    static let diffRemovedFill = Color(red: 0.36, green: 0.12, blue: 0.12).opacity(0.55)
    static let diffAddedStripe = Color(red: 0.20, green: 0.74, blue: 0.35).opacity(0.95)
    static let diffRemovedStripe = Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.95)
    static let diffHunkFill = adaptive(
        light: NSColor(calibratedRed: 0.88, green: 0.90, blue: 0.94, alpha: 1),
        dark: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.21, alpha: 1)
    )
    static let diffHunkSelectedFill = adaptive(
        light: NSColor(calibratedRed: 0.82, green: 0.86, blue: 0.95, alpha: 1),
        dark: NSColor(calibratedRed: 0.18, green: 0.24, blue: 0.34, alpha: 1)
    )

    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let jetbrainsGlow = RadialGradient(
        colors: [Color.clear, Color.clear],
        center: .topLeading,
        startRadius: 1,
        endRadius: 1
    )

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let best = appearance.bestMatch(from: [.darkAqua, .aqua])
            return best == .darkAqua ? dark : light
        })
    }
}

struct PanelCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                Rectangle().fill(AppTheme.editorBackground)
            )
            .overlay(
                Rectangle().stroke(AppTheme.editorDivider, lineWidth: 1)
            )
    }
}

struct ChromeCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                Rectangle().fill(AppTheme.chromeDark)
            )
            .overlay(
                Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1)
            )
    }
}

struct StatusPill: View {
    let title: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.chromeMuted)
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.chromeText)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Rectangle().fill(AppTheme.chromeDarkElevated))
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }
}
