import SwiftUI

private struct MockCommit: Identifiable, Hashable {
    let id: String
    let title: String
    let tag: String?
    let author: String
    let initials: String
    let time: String
    let additions: Int
    let deletions: Int
}

private let mockCommits: [MockCommit] = [
    MockCommit(id: "a1b2c3d", title: "Refactor theme provider context", tag: "main", author: "Jane Doe", initials: "JD", time: "10:42 AM", additions: 12, deletions: 4),
    MockCommit(id: "b3c4d5e", title: "Update dependencies to latest versions", tag: nil, author: "Mike Smith", initials: "MS", time: "Yesterday", additions: 7, deletions: 1),
    MockCommit(id: "c5d6e7f", title: "Fix overflow issue in sidebar", tag: nil, author: "Jane Doe", initials: "JD", time: "Oct 24", additions: 4, deletions: 9),
    MockCommit(id: "d7e8f9a", title: "Merge branch 'feature/dark-mode'", tag: "feature", author: "Alex Lee", initials: "AL", time: "Oct 22", additions: 21, deletions: 18),
    MockCommit(id: "e9f0a1b", title: "Initial commit structure", tag: nil, author: "Jane Doe", initials: "JD", time: "Oct 20", additions: 10, deletions: 0)
]

struct HistorySidebarPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                section(title: "LOCAL BRANCHES") {
                    branchRow("main", badge: "2h", active: true)
                    branchRow("feature/vertical-layout", badge: "1d", active: false)
                    branchRow("fix/api-headers", badge: "3d", active: false)
                }
                section(title: "REMOTES") {
                    branchRow("origin/main", badge: nil, active: false)
                    branchRow("origin/staging", badge: nil, active: false)
                }
                section(title: "TAGS") {
                    branchRow("v2.4.0", badge: nil, active: false)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted)
            content()
        }
    }

    private func branchRow(_ name: String, badge: String?, active: Bool) -> some View {
        HistoryBranchRow(name: name, badge: badge, active: active)
    }
}

private struct HistoryBranchRow: View {
    let name: String
    let badge: String?
    let active: Bool
    @State private var isHovering: Bool = false
    @GestureState private var isPressing: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.chromeMuted)
            Text(name)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(active ? AppTheme.chromeText : AppTheme.chromeMuted)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 21)
        .background(backgroundFill)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(active ? AppTheme.accent.opacity(0.8) : .clear)
                .frame(width: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke((isHovering && !active) ? AppTheme.chromeDivider.opacity(0.52) : .clear, lineWidth: 1)
        }
        .onHover { inside in
            isHovering = inside
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressing) { _, state, _ in
                    state = true
                }
        )
    }

    private var backgroundFill: Color {
        if active {
            return AppTheme.chromeDarkElevated.opacity(0.95)
        }
        if isPressing {
            return AppTheme.chromeDarkElevated.opacity(0.58)
        }
        if isHovering {
            return AppTheme.chromeDarkElevated.opacity(0.36)
        }
        return .clear
    }
}

struct HistoryMainPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var selectedCommitID: String = mockCommits.first?.id ?? ""
    @State private var isDiffSectionExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            commitTable
            Divider().overlay(AppTheme.chromeDivider)
            detailCard
            Divider().overlay(AppTheme.chromeDivider)
            diffSection
        }
        .background(AppTheme.editorBackground)
    }

    private var selectedCommit: MockCommit {
        mockCommits.first(where: { $0.id == selectedCommitID }) ?? mockCommits[0]
    }

    private var commitTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("COMMIT MESSAGE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("AUTHOR")
                    .frame(width: 186, alignment: .leading)
                Text("DATE")
                    .frame(width: 96, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AppTheme.chromeMuted)
            .padding(.horizontal, 11)
            .frame(height: 27)
            .background(AppTheme.panelDark)

            ForEach(Array(mockCommits.enumerated()), id: \.element.id) { index, commit in
                HistoryCommitRow(
                    commit: commit,
                    index: index,
                    isSelected: commit.id == selectedCommitID
                ) {
                    selectedCommitID = commit.id
                }
                Divider().overlay(AppTheme.chromeDivider.opacity(0.75))
            }
        }
    }

    private var detailCard: some View {
        HStack(spacing: 11) {
            Circle()
                .fill(AppTheme.accent.opacity(0.6))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(selectedCommit.initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.chromeText)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCommit.title)
                    .font(.system(size: 33, weight: .bold))
                    .foregroundStyle(AppTheme.chromeText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 8) {
                    Text("\(selectedCommit.author) committed 2 hours ago")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.chromeMuted)
                    Text("•")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.8))
                    Text(selectedCommit.id)
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.accent.opacity(0.9))
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        .background(AppTheme.accent.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                statPill(text: "+\(selectedCommit.additions)", tint: Color.green.opacity(0.9))
                statPill(text: "-\(selectedCommit.deletions)", tint: Color.red.opacity(0.9))
                Button {
                    // Reserved for commit actions menu.
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .hoverPressControl(cornerRadius: 4, hoverFillOpacity: 0.30, pressFillOpacity: 0.58)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(height: 84)
        .background(AppTheme.panelDark)
    }

    private var diffSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.14)) {
                        isDiffSectionExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isDiffSectionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.8))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .hoverPressControl(cornerRadius: 4, hoverFillOpacity: 0.30, pressFillOpacity: 0.58)
                Image(systemName: "doc.text")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted)
                Text("src/hooks/useTheme.ts")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.95))
                Spacer(minLength: 0)
                Button {
                    // Reserved for preview action.
                } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.8))
                        .frame(width: 18, height: 16)
                }
                .buttonStyle(.plain)
                .hoverPressControl(cornerRadius: 4, hoverFillOpacity: 0.30, pressFillOpacity: 0.58)
            }
            .padding(.horizontal, 10)
            .frame(height: 27)
            .background(AppTheme.panelDark)

            if isDiffSectionExpanded {
                Divider().overlay(AppTheme.chromeDivider.opacity(0.9))

                HStack {
                    Text(currentHunkHeader)
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .frame(height: 23)
                .background(AppTheme.panelDark.opacity(0.85))

                Divider().overlay(AppTheme.chromeDivider.opacity(0.9))

                DiffView(lines: viewModel.diffLines.isEmpty ? fallbackDiff : viewModel.diffLines, mode: .unified)
                    .background(AppTheme.editorBackground)
            }
        }
    }

    private func statPill(text: String, tint: Color) -> some View {
        Button {
            // Reserved for stats filter action.
        } label: {
            Text(text)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(tint)
                .padding(.horizontal, 7)
                .frame(height: 19)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .hoverPressControl(cornerRadius: 4, hoverFillOpacity: 0.14, pressFillOpacity: 0.26)
    }

    private var fallbackDiff: [DiffLine] {
        [
            DiffLine(id: "h0", kind: .hunk, oldLine: nil, newLine: nil, text: "@@ -12,10 +12,20 @@"),
            DiffLine(id: "h1", kind: .context, oldLine: 12, newLine: 12, text: " import { useState, useEffect } from 'react';"),
            DiffLine(id: "h2", kind: .removed, oldLine: 14, newLine: nil, text: "-import { Layout } from './components/Layout';"),
            DiffLine(id: "h3", kind: .added, oldLine: nil, newLine: 14, text: "+import { NativeLayout } from './components/NativeLayout';"),
            DiffLine(id: "h4", kind: .added, oldLine: nil, newLine: 15, text: "+import { useTheme } from './hooks/useTheme';")
        ]
    }

    private var currentHunkHeader: String {
        (viewModel.diffLines.first(where: { $0.kind == .hunk }) ?? fallbackDiff.first(where: { $0.kind == .hunk }))?.text ?? "@@ -1,1 +1,1 @@"
    }
}

private struct HoverPressControlModifier: ViewModifier {
    let cornerRadius: CGFloat
    let hoverFillOpacity: Double
    let pressFillOpacity: Double

    @State private var isHovering: Bool = false
    @GestureState private var isPressing: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                (isPressing
                    ? AppTheme.chromeDarkElevated.opacity(pressFillOpacity)
                    : (isHovering ? AppTheme.chromeDarkElevated.opacity(hoverFillOpacity) : .clear)
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isHovering ? AppTheme.chromeDivider.opacity(0.55) : .clear, lineWidth: 1)
            )
            .opacity(isPressing ? 0.84 : 1.0)
            .scaleEffect(isPressing ? 0.985 : 1.0)
            .onHover { inside in
                isHovering = inside
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressing) { _, state, _ in
                        state = true
                    }
            )
            .animation(.easeOut(duration: 0.08), value: isPressing)
            .animation(.easeOut(duration: 0.10), value: isHovering)
    }
}

private extension View {
    func hoverPressControl(cornerRadius: CGFloat, hoverFillOpacity: Double, pressFillOpacity: Double) -> some View {
        modifier(
            HoverPressControlModifier(
                cornerRadius: cornerRadius,
                hoverFillOpacity: hoverFillOpacity,
                pressFillOpacity: pressFillOpacity
            )
        )
    }
}

private struct HistoryCommitRow: View {
    let commit: MockCommit
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isSelected ? AppTheme.accent : AppTheme.chromeMuted.opacity(0.65))
                            .frame(width: 6, height: 6)
                        Rectangle()
                            .fill(AppTheme.chromeDivider.opacity(index < mockCommits.count - 1 ? 0.9 : 0))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 10, alignment: .top)
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(commit.title)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(AppTheme.chromeText)
                                .lineLimit(1)
                            if let tag = commit.tag {
                                Text(tag)
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 5)
                                    .frame(height: 15)
                                    .background(AppTheme.accent.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        if isSelected {
                            Text(commit.id)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.accent.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 7) {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.4))
                        .frame(width: 17, height: 17)
                        .overlay {
                            Text(commit.initials)
                                .font(.system(size: 7.5, weight: .bold))
                                .foregroundStyle(AppTheme.chromeText)
                        }
                    Text(commit.author)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppTheme.chromeMuted)
                        .lineLimit(1)
                }
                .frame(width: 186, alignment: .leading)

                Text(commit.time)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted)
                    .frame(width: 96, alignment: .trailing)
            }
            .padding(.horizontal, 11)
            .frame(height: isSelected ? 50 : 40)
            .background(
                isSelected
                    ? AppTheme.chromeDarkElevated.opacity(0.7)
                    : (isHovering ? AppTheme.chromeDarkElevated.opacity(0.35) : .clear)
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(isSelected ? AppTheme.accent.opacity(0.9) : .clear)
                    .frame(width: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isSelected ? AppTheme.chromeDivider.opacity(0.85) : (isHovering ? AppTheme.chromeDivider.opacity(0.5) : .clear), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { inside in
            isHovering = inside
        }
    }
}
