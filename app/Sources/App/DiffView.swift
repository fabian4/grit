import SwiftUI

struct DiffLine: Identifiable, Hashable {
    enum Kind {
        case meta
        case hunk
        case added
        case removed
        case context
    }

    let id: String
    let kind: Kind
    let oldLine: Int?
    let newLine: Int?
    let text: String
}

enum DiffViewMode: String, CaseIterable, Identifiable, Codable {
    case unified
    case sideBySide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unified: return "Unified"
        case .sideBySide: return "Side-by-side"
        }
    }
}

struct DiffView: View {
    let lines: [DiffLine]
    let mode: DiffViewMode

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                switch mode {
                case .unified:
                    ForEach(lines) { line in
                        DiffRowUnified(line: line)
                    }
                case .sideBySide:
                    ForEach(lines) { line in
                        if line.kind == .meta || line.kind == .hunk {
                            DiffRowUnified(line: line)
                        } else {
                            DiffRowSideBySide(line: line)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppTheme.chromeDivider.opacity(0.7))
                .frame(width: 1)
                .padding(.leading, 80)
        }
        .background(AppTheme.editorBackground)
    }
}

private struct DiffRowUnified: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.oldLine.map(String.init) ?? "")
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.95))
            Text(line.newLine.map(String.init) ?? "")
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.95))
            Text(line.text)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12.5, weight: .regular, design: .monospaced))
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .added:
            return AppTheme.diffAddedFill
        case .removed:
            return AppTheme.diffRemovedFill
        case .hunk:
            return AppTheme.panelDark
        case .meta:
            return AppTheme.panelDark.opacity(0.7)
        case .context:
            return Color.clear
        }
    }

    private var textColor: Color {
        switch line.kind {
        case .hunk:
            return AppTheme.accentSecondary.opacity(0.9)
        case .added, .removed, .meta, .context:
            return AppTheme.chromeText
        }
    }
}

private struct DiffRowSideBySide: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            sideCell(
                lineNumber: line.oldLine,
                text: leftText,
                background: leftBackground
            )
            Divider()
            sideCell(
                lineNumber: line.newLine,
                text: rightText,
                background: rightBackground
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sideCell(lineNumber: Int?, text: String, background: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(lineNumber.map(String.init) ?? "")
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.95))
            Text(text)
                .foregroundStyle(AppTheme.chromeText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12.5, weight: .regular, design: .monospaced))
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
    }

    private var leftText: String {
        switch line.kind {
        case .added:
            return ""
        case .removed:
            return stripPrefix(line.text)
        case .context:
            return stripPrefix(line.text)
        default:
            return line.text
        }
    }

    private var rightText: String {
        switch line.kind {
        case .removed:
            return ""
        case .added:
            return stripPrefix(line.text)
        case .context:
            return stripPrefix(line.text)
        default:
            return line.text
        }
    }

    private var leftBackground: Color {
        switch line.kind {
        case .removed:
            return AppTheme.diffRemovedFill
        case .hunk:
            return AppTheme.panelDark
        case .meta:
            return AppTheme.panelDark.opacity(0.7)
        default:
            return Color.clear
        }
    }

    private var rightBackground: Color {
        switch line.kind {
        case .added:
            return AppTheme.diffAddedFill
        case .hunk:
            return AppTheme.panelDark
        case .meta:
            return AppTheme.panelDark.opacity(0.7)
        default:
            return Color.clear
        }
    }

    private func stripPrefix(_ text: String) -> String {
        guard let first = text.first else { return text }
        if first == "+" || first == "-" || first == " " {
            return String(text.dropFirst())
        }
        return text
    }
}
