import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.23, green: 0.53, blue: 0.91)
    static let accentSecondary = Color(red: 0.38, green: 0.58, blue: 0.92)
    static let backgroundTop = Color(red: 0.10, green: 0.12, blue: 0.17)
    static let backgroundBottom = Color(red: 0.10, green: 0.12, blue: 0.17)
    static let panelStroke = Color.white.opacity(0.06)
    static let mutedText = Color(red: 0.58, green: 0.62, blue: 0.70)
    static let fieldFill = Color(red: 0.18, green: 0.21, blue: 0.29)
    static let chromeDark = Color(red: 0.14, green: 0.16, blue: 0.22)
    static let chromeDarkElevated = Color(red: 0.19, green: 0.22, blue: 0.30)
    static let chromeDivider = Color.white.opacity(0.12)
    static let chromeText = Color(red: 0.87, green: 0.89, blue: 0.93)
    static let chromeMuted = Color(red: 0.67, green: 0.71, blue: 0.78)
    static let editorBackground = Color(red: 0.08, green: 0.11, blue: 0.16)
    static let editorHeader = Color(red: 0.12, green: 0.15, blue: 0.22)
    static let editorDivider = Color.white.opacity(0.08)

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
