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
        .border(Color.gray.opacity(0.3))
    }
}

private struct DiffRowUnified: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.oldLine.map(String.init) ?? "")
                .frame(width: 42, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(line.newLine.map(String.init) ?? "")
                .frame(width: 42, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(line.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(.body, design: .monospaced))
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .added:
            return Color.green.opacity(0.15)
        case .removed:
            return Color.red.opacity(0.15)
        case .hunk:
            return Color.gray.opacity(0.2)
        case .meta:
            return Color.gray.opacity(0.1)
        case .context:
            return Color.clear
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
                .frame(width: 42, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(.body, design: .monospaced))
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
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
            return Color.red.opacity(0.15)
        case .hunk:
            return Color.gray.opacity(0.2)
        case .meta:
            return Color.gray.opacity(0.1)
        default:
            return Color.clear
        }
    }

    private var rightBackground: Color {
        switch line.kind {
        case .added:
            return Color.green.opacity(0.15)
        case .hunk:
            return Color.gray.opacity(0.2)
        case .meta:
            return Color.gray.opacity(0.1)
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
