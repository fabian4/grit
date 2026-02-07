import SwiftUI
import AppKit

struct TopBar: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal")
                Image(systemName: "folder")
                Text("untitled-project")
                    .font(.system(size: 13, weight: .semibold))

                HeaderIcon(symbol: "tray.and.arrow.up")
                HeaderIcon(symbol: "arrow.triangle.branch")
            }
            .foregroundStyle(AppTheme.chromeText)
            .frame(width: 330, alignment: .leading)
            .padding(.leading, 10)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.chromeMuted)
                Text("Search everywhere")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted)
                Spacer(minLength: 0)
                Text("Double Shift")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
            }
            .padding(.horizontal, 10)
            .frame(width: 360, height: 24)
            .background(AppTheme.fieldFill)
            .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                    Text("master")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.chromeMuted)

                HeaderIcon(symbol: "play.fill", tint: AppTheme.accent)
                HeaderIcon(symbol: "ladybug.fill")
                HeaderIcon(symbol: "gearshape")

                Button("Open") {
                    Task { await viewModel.openRepo() }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.accent)
            }
            .padding(.trailing, 10)
        }
        .frame(height: 34)
        .background(AppTheme.chromeDark)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
    }
}

private struct HeaderIcon: View {
    let symbol: String
    var tint: Color = AppTheme.chromeText

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
    }
}

struct ToolWindowRail: View {
    var body: some View {
        VStack(spacing: 10) {
            RailIcon(symbol: "tray", active: true)
            RailIcon(symbol: "folder", active: false)
            RailIcon(symbol: "terminal", active: false)
            RailIcon(symbol: "sparkles", active: false)
            Spacer(minLength: 0)
            RailIcon(symbol: "gearshape", active: false)
        }
        .padding(.top, 8)
        .frame(width: 36)
        .background(AppTheme.chromeDark)
        .overlay(alignment: .trailing) { Rectangle().fill(AppTheme.chromeDivider).frame(width: 1) }
    }
}

private struct RailIcon: View {
    let symbol: String
    let active: Bool

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(active ? AppTheme.chromeText : AppTheme.chromeMuted)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}

struct LeftPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            ToolWindowRail()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Project")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeText)
                    Spacer(minLength: 0)
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted)
                }
                .padding(.horizontal, 10)
                .frame(height: 34)

                Text(viewModel.repoPath)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)

                HStack(spacing: 6) {
                    StatusPill(title: "Changes", value: viewModel.statusItems.count)
                    StatusPill(title: "Files", value: viewModel.fileTree.count)
                }
                .padding(.horizontal, 10)

                HStack(spacing: 8) {
                    Text("Mode")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeText)

                    SegmentButton(title: "Changes", isSelected: viewModel.leftMode == .changes) {
                        viewModel.leftMode = .changes
                    }

                    SegmentButton(title: "Files", isSelected: viewModel.leftMode == .files) {
                        viewModel.leftMode = .files
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 10)

                Divider().overlay(AppTheme.chromeDivider)

                HStack {
                    Text("Group by Folder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeText)
                    Spacer(minLength: 0)
                    Toggle("", isOn: $viewModel.groupDiffByFolder)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)

                Divider().overlay(AppTheme.chromeDivider)

                ScrollView {
                    VStack(alignment: .leading, spacing: 3) {
                        if viewModel.statusItems.isEmpty {
                            Text("No changes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.chromeMuted)
                                .padding(.horizontal, 10)
                                .padding(.top, 10)
                        } else {
                            ForEach(viewModel.sortedStatusItems) { item in
                                FileRow(path: item.path, isSelected: item.path == viewModel.selectedPath)
                                    .onTapGesture {
                                        viewModel.leftMode = .changes
                                        viewModel.selectedPath = item.path
                                        Task { await viewModel.loadDiffForSelection() }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                }
            }
            .background(AppTheme.chromeDark)
            .overlay(alignment: .trailing) { Rectangle().fill(AppTheme.chromeDivider).frame(width: 1) }
        }
    }
}

private struct FileRow: View {
    let path: String
    let isSelected: Bool

    var body: some View {
        Text(path)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isSelected ? AppTheme.chromeText : AppTheme.chromeMuted)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.chromeDarkElevated : Color.clear)
    }
}

struct MainPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(spacing: 0) {
            EditorTabs()
            EditorHeader(path: viewModel.selectedPath ?? "Main.kt")
            DiffControls(mode: viewModel.diffMode, isEditable: viewModel.isDetailEditable)

            if viewModel.leftMode == .changes {
                IDEUnifiedDiff(lines: mapLines(viewModel.diffLines), split: viewModel.diffMode == .sideBySide)
            } else {
                DiffTextView(text: $viewModel.fileContent, lines: viewModel.diffLines, mode: .unified, isEditable: false)
            }
        }
        .background(AppTheme.editorBackground)
    }

    private func mapLines(_ lines: [DiffLine]) -> [IDEDiffRow] {
        if lines.isEmpty {
            return demoRows
        }

        let mapped = lines.map { line in
            switch line.kind {
            case .added:
                return IDEDiffRow(
                    oldNum: nil,
                    oldText: "",
                    newNum: line.newLine,
                    newText: String(line.text.dropFirst()),
                    kind: .added
                )
            case .removed:
                return IDEDiffRow(
                    oldNum: line.oldLine,
                    oldText: String(line.text.dropFirst()),
                    newNum: nil,
                    newText: "",
                    kind: .removed
                )
            default:
                let text = line.text.first.map { ($0 == "+" || $0 == "-" || $0 == " ") ? String(line.text.dropFirst()) : line.text } ?? line.text
                return IDEDiffRow(
                    oldNum: line.oldLine,
                    oldText: text,
                    newNum: line.newLine,
                    newText: text,
                    kind: .normal
                )
            }
        }

        let visibleCount = mapped.filter {
            !($0.oldText.trimmingCharacters(in: .whitespaces).isEmpty &&
              $0.newText.trimmingCharacters(in: .whitespaces).isEmpty)
        }.count
        return visibleCount < 4 ? demoRows : mapped
    }

    private var demoRows: [IDEDiffRow] {
        [
                IDEDiffRow(oldNum: 1, oldText: "package com.example.app", newNum: 1, newText: "package com.example.app", kind: .normal),
                IDEDiffRow(oldNum: 2, oldText: "", newNum: 2, newText: "", kind: .normal),
                IDEDiffRow(oldNum: 3, oldText: "import java.util.Scanner", newNum: 3, newText: "import java.util.Scanner", kind: .normal),
                IDEDiffRow(oldNum: nil, oldText: "", newNum: 4, newText: "val greeting = \"Welcome back\"", kind: .added),
                IDEDiffRow(oldNum: 4, oldText: "val greeting = \"Hello, User\"", newNum: nil, newText: "", kind: .removed),
                IDEDiffRow(oldNum: 5, oldText: "", newNum: 5, newText: "fun main() {", kind: .normal),
                IDEDiffRow(oldNum: 6, oldText: "println(greeting)", newNum: 6, newText: "println(greeting)", kind: .normal)
        ]
    }
}

private struct EditorTabs: View {
    var body: some View {
        HStack(spacing: 0) {
            tab(title: "Main.kt", selected: true)
            tab(title: "Utils.java", selected: false)
            Spacer(minLength: 0)
        }
        .frame(height: 28)
        .background(AppTheme.chromeDark)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
    }

    @ViewBuilder
    private func tab(title: String, selected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: selected ? "k.circle.fill" : "circle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(selected ? AppTheme.accent : AppTheme.chromeMuted)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? AppTheme.chromeText : AppTheme.chromeMuted)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(selected ? AppTheme.chromeDarkElevated : AppTheme.chromeDark)
        .overlay(alignment: .bottom) {
            Rectangle().fill(selected ? AppTheme.accent : .clear).frame(height: 1.5)
        }
    }
}

private struct EditorHeader: View {
    let path: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(path)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.chromeText)
            Text("Diff preview")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.chromeMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.editorHeader)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
    }
}

private struct DiffControls: View {
    let mode: DiffViewMode
    let isEditable: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("Diff View")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)

            SegmentedPill(labels: ["Unified", "Side-by-side"], selectedIndex: mode == .unified ? 0 : 1)
            Text("Editable")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText)
            Toggle("", isOn: .constant(isEditable))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(AppTheme.editorHeader)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
    }
}

private struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.chromeMuted)
                .frame(minWidth: 64)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(isSelected ? AppTheme.accent : AppTheme.chromeDarkElevated)
                .overlay(
                    Rectangle()
                        .stroke(AppTheme.chromeDivider, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SegmentedPill: View {
    let labels: [String]
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(index == selectedIndex ? .white : AppTheme.chromeMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(index == selectedIndex ? AppTheme.accent : AppTheme.chromeDarkElevated)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
            }
        }
    }
}

private enum DiffKind {
    case normal
    case added
    case removed
}

private struct IDEDiffRow: Identifiable {
    let id = UUID()
    let oldNum: Int?
    let oldText: String
    let newNum: Int?
    let newText: String
    let kind: DiffKind
}

private struct IDEUnifiedDiff: View {
    let lines: [IDEDiffRow]
    let split: Bool

    var body: some View {
        if split {
            HStack(spacing: 0) {
                DiffColumn(lines: lines, side: .old)
                Rectangle().fill(AppTheme.chromeDivider).frame(width: 1)
                DiffColumn(lines: lines, side: .new)
            }
        } else {
            DiffColumn(lines: lines, side: .new)
        }
    }

    private enum Side { case old, new }

    private struct DiffColumn: View {
        let lines: [IDEDiffRow]
        let side: Side

        var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { row in
                        let lineNum = side == .old ? row.oldNum : row.newNum
                        let text = side == .old ? row.oldText : row.newText

                        HStack(spacing: 8) {
                            Text(lineNum.map(String.init) ?? "")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(AppTheme.chromeMuted)
                                .frame(width: 30, alignment: .trailing)

                            Text(text)
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundStyle(AppTheme.chromeText)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(backgroundColor(for: row, side: side))
                    }
                }
            }
            .background(AppTheme.editorBackground)
        }

        private func backgroundColor(for row: IDEDiffRow, side: Side) -> Color {
            switch row.kind {
            case .normal:
                return Color.clear
            case .added:
                return side == .new ? Color.green.opacity(0.15) : Color.clear
            case .removed:
                return side == .old ? Color.red.opacity(0.15) : Color.clear
            }
        }
    }
}

struct BottomPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text("Terminal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.chromeText)

                Spacer(minLength: 0)

                Text("New Tab")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent)
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(AppTheme.chromeDark)
            .overlay(alignment: .top) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.chromeDivider).frame(height: 1) }

            Text("Terminal tab 1 not wired yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.chromeMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
                .background(AppTheme.chromeDarkElevated)
        }
    }
}
