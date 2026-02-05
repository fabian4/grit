import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.26, green: 0.58, blue: 0.98)
    static let accentSecondary = Color(red: 0.35, green: 0.78, blue: 0.98)
    static let backgroundTop = Color(red: 0.11, green: 0.12, blue: 0.15)
    static let backgroundBottom = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let panelStroke = Color.white.opacity(0.08)
    static let mutedText = Color(red: 0.61, green: 0.64, blue: 0.70)
    static let fieldFill = Color(red: 0.18, green: 0.19, blue: 0.23)
    static let chromeDark = Color(red: 0.15, green: 0.16, blue: 0.20)
    static let chromeDarkElevated = Color(red: 0.19, green: 0.20, blue: 0.25)
    static let chromeDivider = Color.white.opacity(0.09)
    static let chromeText = Color(red: 0.90, green: 0.92, blue: 0.96)
    static let chromeMuted = Color(red: 0.70, green: 0.73, blue: 0.80)
    static let editorBackground = Color(red: 0.16, green: 0.17, blue: 0.21)
    static let editorHeader = Color(red: 0.19, green: 0.20, blue: 0.24)
    static let editorDivider = Color.white.opacity(0.06)

    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let jetbrainsGlow = RadialGradient(
        colors: [
            Color.white.opacity(0.06),
            Color.clear
        ],
        center: .topLeading,
        startRadius: 40,
        endRadius: 460
    )
}

struct PanelCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                Rectangle()
                    .fill(AppTheme.editorBackground)
            )
            .overlay(
                Rectangle()
                    .stroke(AppTheme.editorDivider, lineWidth: 1)
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
                Rectangle()
                    .fill(AppTheme.chromeDark)
            )
            .overlay(
                Rectangle()
                    .stroke(AppTheme.chromeDivider, lineWidth: 1)
            )
    }
}

struct StatusPill: View {
    let title: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.chromeMuted)
            Text("\(value)")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.chromeText)
        }
        .background(
            Rectangle().fill(AppTheme.chromeDarkElevated)
        )
        .overlay(
            Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1)
        )
    }
}
