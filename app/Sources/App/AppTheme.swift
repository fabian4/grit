import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.21, green: 0.49, blue: 0.86)
    static let accentSecondary = Color(red: 0.31, green: 0.59, blue: 0.95)
    static let chromeDark = Color(red: 0.094, green: 0.102, blue: 0.122)      // #181A1F
    static let sidebarDark = Color(red: 0.082, green: 0.090, blue: 0.110)     // #15171C
    static let mainDark = Color(red: 0.106, green: 0.118, blue: 0.141)        // #1B1E24
    static let backgroundTop = mainDark
    static let backgroundBottom = mainDark
    static let panelStroke = Color.white.opacity(0.08)
    static let mutedText = Color.white.opacity(0.45)
    static let fieldFill = Color.white.opacity(0.10)
    static let chromeDarkElevated = Color.white.opacity(0.07)
    static let chromeDivider = Color.white.opacity(0.08)
    static let chromeText = Color.white.opacity(0.85)
    static let chromeMuted = Color.white.opacity(0.45)
    static let editorBackground = mainDark
    static let editorHeader = mainDark
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
