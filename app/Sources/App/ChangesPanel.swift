import SwiftUI
import AppKit

struct ChangesPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var query: String = ""
    @State private var scope: DiffScope = .unstaged
    @State private var pendingDiscardItem: StatusItem? = nil
    @State private var keyMonitor: Any? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(AppTheme.chromeDivider)
            searchRow
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            controlsRow
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            Divider().overlay(AppTheme.chromeDivider)
            listBody
        }
        .background(AppTheme.sidebarDark)
        .overlay(alignment: .trailing) { Rectangle().fill(AppTheme.chromeDivider).frame(width: 1) }
        .onAppear {
            viewModel.leftMode = .changes
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .alert(item: $pendingDiscardItem) { item in
            Alert(
                title: Text(item.isUntracked ? "Delete untracked file?" : "Discard changes?"),
                message: Text(item.path),
                primaryButton: .destructive(Text(item.isUntracked ? "Delete" : "Discard")) {
                    Task { await viewModel.discard(item: item) }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            scopeTabs
            Spacer(minLength: 0)
            Text("Changes: \(viewModel.statusItems.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
    }

    private var scopeTabs: some View {
        HStack(spacing: 0) {
            scopeTab(title: "Unstaged", count: viewModel.unstagedItems.count, value: .unstaged)
            scopeTab(title: "Staged", count: viewModel.stagedItems.count, value: .staged)
        }
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }

    private func scopeTab(title: String, count: Int, value: DiffScope) -> some View {
        Button {
            scope = value
            if viewModel.selectedPath != nil {
                viewModel.selectedDiffScope = value
                Task { await viewModel.loadDiffForSelection() }
            }
        } label: {
            Text("\(title) \(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(scope == value ? AppTheme.chromeText : AppTheme.chromeMuted)
                .padding(.horizontal, 10)
                .frame(height: 20)
                .background(scope == value ? AppTheme.chromeDarkElevated : AppTheme.sidebarDark)
        }
        .buttonStyle(.plain)
    }

    private var searchRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            TextField("Filter files", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.chromeText)
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(AppTheme.fieldFill)
        .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
    }

    private var controlsRow: some View {
        HStack(spacing: 8) {
            Button("Stage All") { Task { await viewModel.stageAll() } }
                .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.45)
                .disabled(!viewModel.isRepoOpen || viewModel.isBusy)
            Button("Unstage All") { Task { await viewModel.unstageAll() } }
                .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.45)
                .disabled(!viewModel.isRepoOpen || viewModel.isBusy)
            Spacer(minLength: 0)
            Text("Staged: \(viewModel.stagedCount)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppTheme.chromeText)
    }

    private var listBody: some View {
        ScrollView {
            if !viewModel.isRepoOpen {
                EmptyLeftState(title: "No repo open", subtitle: "Use Open in the top bar")
                    .padding(.top, 18)
            } else if viewModel.statusItems.isEmpty {
                EmptyLeftState(title: "Working tree clean", subtitle: nil)
                    .padding(.top, 18)
            } else if filteredItems.isEmpty {
                EmptyLeftState(
                    title: scope == .staged ? "No staged changes" : "No unstaged changes",
                    subtitle: query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "No matching files"
                )
                .padding(.top, 18)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredItems) { item in
                        ChangeRow(
                            item: item,
                            isSelected: item.path == viewModel.selectedPath && viewModel.selectedDiffScope == scope,
                            scope: scope,
                            onSelect: { select(item) },
                            onToggleStage: { Task { await viewModel.toggleStage(item: item) } },
                            onDiscard: { pendingDiscardItem = item }
                        )
                        .contextMenu { statusItemContextMenu(item) }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func select(_ item: StatusItem) {
        viewModel.selectedDiffScope = scope
        viewModel.selectedPath = item.path
        viewModel.activateTab(item.path)
        Task { await viewModel.loadDiffForSelection() }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView || responder is NSTextField {
                return event
            }
            guard let chars = event.charactersIgnoringModifiers, chars.count == 1 else { return event }
            if chars == String(UnicodeScalar(NSDownArrowFunctionKey)!) {
                moveSelection(step: 1)
                return nil
            }
            if chars == String(UnicodeScalar(NSUpArrowFunctionKey)!) {
                moveSelection(step: -1)
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func moveSelection(step: Int) {
        let items = filteredItems
        guard !items.isEmpty else { return }
        let isCurrentInScope = (viewModel.selectedDiffScope == scope)
        let currentIndex: Int = {
            guard isCurrentInScope, let sel = viewModel.selectedPath, let idx = items.firstIndex(where: { $0.path == sel }) else {
                return 0
            }
            return idx
        }()
        let nextIndex = max(0, min(items.count - 1, currentIndex + step))
        select(items[nextIndex])
    }

    private var filteredItems: [StatusItem] {
        let base: [StatusItem] = (scope == .staged) ? viewModel.stagedItems : viewModel.unstagedItems
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return base.sorted { $0.path.lowercased() < $1.path.lowercased() } }
        return base.filter { $0.path.lowercased().contains(q) }.sorted { $0.path.lowercased() < $1.path.lowercased() }
    }

    @ViewBuilder
    private func statusItemContextMenu(_ item: StatusItem) -> some View {
        Button(item.isStaged ? "Unstage" : "Stage") {
            Task { await viewModel.toggleStage(item: item) }
        }
        Button(item.isUntracked ? "Delete Untracked" : "Discard", role: .destructive) {
            pendingDiscardItem = item
        }
        Divider()
        Button("Copy Path") { copyPath(item.path) }
        Button("Open in Finder") { openInFinder(relativePath: item.path) }
    }

    private func copyPath(_ path: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
    }

    private func openInFinder(relativePath: String) {
        let url = URL(fileURLWithPath: viewModel.repoPath).appendingPathComponent(relativePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private struct ChangeRow: View {
    let item: StatusItem
    let isSelected: Bool
    let scope: DiffScope
    let onSelect: () -> Void
    let onToggleStage: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggleStage) {
                Image(systemName: item.isStaged ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(item.isStaged ? AppTheme.accent : AppTheme.chromeMuted)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)

            Text(statusLetter)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(statusColor)
                .frame(width: 12, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.chromeText)
                    .lineLimit(1)
                if !dirPath.isEmpty {
                    Text(dirPath)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 0)

            if item.additions > 0 || item.deletions > 0 {
                HStack(spacing: 6) {
                    if item.additions > 0 {
                        Text("+\(item.additions)")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.green.opacity(0.9))
                    }
                    if item.deletions > 0 {
                        Text("-\(item.deletions)")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.red.opacity(0.9))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 21)
        .contentShape(Rectangle())
        .background(isSelected ? Color.white.opacity(0.07) : .clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isSelected ? AppTheme.accent.opacity(0.8) : .clear)
                .frame(width: 2)
        }
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button(item.isStaged ? "Unstage" : "Stage") { onToggleStage() }
            Button(item.isUntracked ? "Delete Untracked" : "Discard", role: .destructive) { onDiscard() }
        }
    }

    private var statusLetter: String {
        if item.status == "??" { return "U" }
        if scope == .staged {
            let c = item.stagedCode
            if c == " " { return "·" }
            return String(c)
        }
        let c = item.unstagedCode
        if c == " " { return "·" }
        return String(c)
    }

    private var statusColor: Color {
        switch statusLetter {
        case "A": return Color.green.opacity(0.9)
        case "D": return Color.red.opacity(0.9)
        case "U", "?": return Color.orange.opacity(0.9)
        default: return AppTheme.accent.opacity(0.9)
        }
    }

    private var fileName: String {
        URL(fileURLWithPath: item.path).lastPathComponent
    }

    private var dirPath: String {
        let dir = URL(fileURLWithPath: item.path).deletingLastPathComponent().path
        return dir == "/" ? "" : dir
    }
}

private struct EmptyLeftState: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.chromeText.opacity(0.9))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}
