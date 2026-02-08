import SwiftUI
import AppKit

struct ChangesPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var pendingDiscardItem: StatusItem? = nil
    @State private var keyMonitor: Any? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar
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

    private var toolbar: some View {
        HStack(spacing: 8) {
            Text("CHANGES")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
            Spacer(minLength: 0)
            Button {
                Task { await viewModel.stageAll() }
            } label: {
                Image(systemName: "checkmark.square")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.35)
            .disabled(!viewModel.isRepoOpen || viewModel.isBusy)

            Button {
                Task { await viewModel.unstageAll() }
            } label: {
                Image(systemName: "square.slash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .opacity(viewModel.isRepoOpen && !viewModel.isBusy ? 1.0 : 0.35)
            .disabled(!viewModel.isRepoOpen || viewModel.isBusy)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
    }

    private var listBody: some View {
        ScrollView {
            if !viewModel.isRepoOpen {
                EmptyLeftState(title: "No repo open", subtitle: "Use Open Repo")
                    .padding(.top, 12)
            } else if viewModel.statusItems.isEmpty {
                EmptyLeftState(title: "Working tree clean", subtitle: nil)
                    .padding(.top, 12)
            } else if viewModel.filteredStatusItems.isEmpty {
                EmptyLeftState(
                    title: "No matching files",
                    subtitle: viewModel.filterQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Clear search to show all changes"
                )
                .padding(.top, 12)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.filteredStatusItems) { item in
                        ChangeRow(
                            item: item,
                            isSelected: item.path == viewModel.selectedPath,
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
        viewModel.selectedDiffScope = .unstaged
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
        let items = viewModel.filteredStatusItems
        guard !items.isEmpty else { return }
        let currentIndex = items.firstIndex { $0.path == viewModel.selectedPath } ?? 0
        let nextIndex = max(0, min(items.count - 1, currentIndex + step))
        select(items[nextIndex])
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

            Image(systemName: fileSymbol)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(fileColor)
                .frame(width: 16, alignment: .leading)

            Text(fileName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.chromeText)
                .lineLimit(1)

            Spacer(minLength: 0)

            ChangeStatsPill(additions: item.additions, deletions: item.deletions)
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

    private var fileName: String {
        URL(fileURLWithPath: item.path).lastPathComponent
    }

    private var fileSymbol: String {
        let lowered = fileName.lowercased()
        if lowered.hasSuffix(".swift") { return "swift" }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return "curlybraces" }
        if lowered.hasSuffix(".md") { return "text.alignleft" }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return "photo" }
        if lowered == "makefile" { return "hammer" }
        return "doc.text"
    }

    private var fileColor: Color {
        let lowered = fileName.lowercased()
        if lowered.hasSuffix(".swift") { return AppTheme.accent }
        if lowered.hasSuffix(".json") || lowered.hasSuffix(".toml") || lowered.hasSuffix(".yaml") || lowered.hasSuffix(".yml") { return Color.purple.opacity(0.85) }
        if lowered.hasSuffix(".md") { return Color.cyan.opacity(0.85) }
        if lowered.hasSuffix(".png") || lowered.hasSuffix(".jpg") || lowered.hasSuffix(".jpeg") || lowered.hasSuffix(".svg") { return Color.orange.opacity(0.9) }
        if lowered == "makefile" { return Color.yellow.opacity(0.9) }
        return AppTheme.chromeMuted
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

private struct ChangeStatsPill: View {
    let additions: Int
    let deletions: Int

    var body: some View {
        let show = additions > 0 || deletions > 0
        Group {
            if show {
                HStack(spacing: 8) {
                    Text("+\(additions)")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(.white)
                    Text("-\(deletions)")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .frame(height: 18)
                .background(AppTheme.accent.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                EmptyView()
            }
        }
    }
}
