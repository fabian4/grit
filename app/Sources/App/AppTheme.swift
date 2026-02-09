import SwiftUI
import AppKit

enum AppTheme {
    static let accent = Color(red: 0.21, green: 0.46, blue: 0.80)
    static let accentSecondary = Color(red: 0.35, green: 0.58, blue: 0.86)
    static let chromeDark = adaptive(
        light: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.98, alpha: 1),
        dark: NSColor(calibratedRed: 0.114, green: 0.114, blue: 0.116, alpha: 1)
    )
    static let chromeBarTop = adaptive(
        light: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1),
        dark: NSColor(calibratedRed: 0.123, green: 0.123, blue: 0.126, alpha: 1)
    )
    static let chromeBarBottom = adaptive(
        light: NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.97, alpha: 1),
        dark: NSColor(calibratedRed: 0.111, green: 0.111, blue: 0.114, alpha: 1)
    )
    static let sidebarDark = adaptive(
        light: NSColor(calibratedRed: 0.93, green: 0.94, blue: 0.96, alpha: 1),
        dark: NSColor(calibratedRed: 0.114, green: 0.114, blue: 0.117, alpha: 1)
    )
    static let mainDark = adaptive(
        light: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1),
        dark: NSColor(calibratedRed: 0.145, green: 0.145, blue: 0.149, alpha: 1)
    )
    static let panelDark = adaptive(
        light: NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.96, alpha: 1),
        dark: NSColor(calibratedRed: 0.162, green: 0.162, blue: 0.168, alpha: 1)
    )
    static let backgroundTop = mainDark
    static let backgroundBottom = mainDark
    static let panelStroke = adaptive(light: NSColor.black.withAlphaComponent(0.10), dark: NSColor.white.withAlphaComponent(0.08))
    static let mutedText = adaptive(light: NSColor.black.withAlphaComponent(0.45), dark: NSColor.white.withAlphaComponent(0.45))
    static let fieldFill = adaptive(light: NSColor.black.withAlphaComponent(0.05), dark: NSColor.white.withAlphaComponent(0.10))
    static let chromeDarkElevated = adaptive(light: NSColor.black.withAlphaComponent(0.055), dark: NSColor.white.withAlphaComponent(0.062))
    static let chromeDivider = adaptive(light: NSColor.black.withAlphaComponent(0.11), dark: NSColor.white.withAlphaComponent(0.070))
    static let chromeDividerStrong = adaptive(light: NSColor.black.withAlphaComponent(0.15), dark: NSColor.white.withAlphaComponent(0.120))
    static let chromeText = adaptive(light: NSColor.black.withAlphaComponent(0.78), dark: NSColor.white.withAlphaComponent(0.89))
    static let chromeMuted = adaptive(light: NSColor.black.withAlphaComponent(0.50), dark: NSColor.white.withAlphaComponent(0.50))
    static let editorBackground = mainDark
    static let editorHeader = mainDark
    static let editorDivider = adaptive(light: NSColor.black.withAlphaComponent(0.10), dark: NSColor.white.withAlphaComponent(0.08))
    static let windowBackdrop = adaptive(
        light: NSColor(calibratedRed: 0.89, green: 0.90, blue: 0.92, alpha: 1),
        dark: NSColor(calibratedRed: 0.154, green: 0.154, blue: 0.154, alpha: 1)
    )
    static let windowBackdropDot = adaptive(
        light: NSColor.black.withAlphaComponent(0.10),
        dark: NSColor.white.withAlphaComponent(0.10)
    )
    static let commitFieldFill = adaptive(
        light: NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.97, alpha: 1),
        dark: NSColor(calibratedRed: 0.194, green: 0.194, blue: 0.199, alpha: 1)
    )
    static let commitFieldStroke = adaptive(
        light: NSColor.black.withAlphaComponent(0.12),
        dark: NSColor.white.withAlphaComponent(0.075)
    )
    static let commitBarBackground = adaptive(
        light: NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.95, alpha: 1),
        dark: NSColor(calibratedRed: 0.204, green: 0.204, blue: 0.209, alpha: 1)
    )
    static let commitButtonBlue = adaptive(
        light: NSColor(calibratedRed: 0.12, green: 0.47, blue: 0.95, alpha: 1),
        dark: NSColor(calibratedRed: 0.14, green: 0.45, blue: 0.90, alpha: 1)
    )

    static let diffAddedFill = Color(red: 0.11, green: 0.32, blue: 0.18).opacity(0.50)
    static let diffRemovedFill = Color(red: 0.36, green: 0.12, blue: 0.12).opacity(0.50)
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
    static let chromeBarGradient = LinearGradient(
        colors: [chromeBarTop, chromeBarBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let sidebarTop = adaptive(
        light: NSColor(calibratedRed: 0.93, green: 0.94, blue: 0.96, alpha: 1),
        dark: NSColor(calibratedRed: 0.116, green: 0.116, blue: 0.120, alpha: 1)
    )
    static let sidebarBottom = adaptive(
        light: NSColor(calibratedRed: 0.92, green: 0.93, blue: 0.95, alpha: 1),
        dark: NSColor(calibratedRed: 0.110, green: 0.110, blue: 0.114, alpha: 1)
    )
    static let mainPanelTop = adaptive(
        light: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1),
        dark: NSColor(calibratedRed: 0.160, green: 0.160, blue: 0.166, alpha: 1)
    )
    static let mainPanelBottom = adaptive(
        light: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.97, alpha: 1),
        dark: NSColor(calibratedRed: 0.152, green: 0.152, blue: 0.158, alpha: 1)
    )
    static let commitBarTop = adaptive(
        light: NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.95, alpha: 1),
        dark: NSColor(calibratedRed: 0.208, green: 0.208, blue: 0.212, alpha: 1)
    )
    static let commitBarBottom = adaptive(
        light: NSColor(calibratedRed: 0.89, green: 0.91, blue: 0.94, alpha: 1),
        dark: NSColor(calibratedRed: 0.198, green: 0.198, blue: 0.204, alpha: 1)
    )
    static let sidebarGradient = LinearGradient(
        colors: [sidebarTop, sidebarBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let mainPanelGradient = LinearGradient(
        colors: [mainPanelTop, mainPanelBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let commitBarGradient = LinearGradient(
        colors: [commitBarTop, commitBarBottom],
        startPoint: .top,
        endPoint: .bottom
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
