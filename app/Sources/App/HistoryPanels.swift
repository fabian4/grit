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
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted)
            content()
        }
    }

    private func branchRow(_ name: String, badge: String?, active: Bool) -> some View {
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
        .frame(height: 22)
        .background(active ? AppTheme.chromeDarkElevated : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct HistoryMainPanel: View {
    @ObservedObject var viewModel: RepoViewModel
    @State private var selectedCommitID: String = mockCommits.first?.id ?? ""

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
                    .frame(width: 170, alignment: .leading)
                Text("DATE")
                    .frame(width: 84, alignment: .trailing)
            }
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(AppTheme.chromeMuted)
            .padding(.horizontal, 11)
            .frame(height: 26)
            .background(AppTheme.panelDark)

            ForEach(mockCommits) { commit in
                Button {
                    selectedCommitID = commit.id
                } label: {
                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(commit.id == selectedCommitID ? AppTheme.accent : AppTheme.chromeMuted.opacity(0.65))
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(commit.title)
                                        .font(.system(size: 13, weight: .semibold))
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
                                if commit.id == selectedCommitID {
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
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.chromeMuted)
                                .lineLimit(1)
                        }
                        .frame(width: 170, alignment: .leading)

                        Text(commit.time)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(AppTheme.chromeMuted)
                            .frame(width: 84, alignment: .trailing)
                    }
                    .padding(.horizontal, 11)
                    .frame(height: commit.id == selectedCommitID ? 50 : 41)
                    .background(commit.id == selectedCommitID ? AppTheme.chromeDarkElevated.opacity(0.7) : .clear)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(commit.id == selectedCommitID ? AppTheme.accent.opacity(0.9) : .clear)
                            .frame(width: 2)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(commit.id == selectedCommitID ? AppTheme.chromeDivider.opacity(0.85) : .clear, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                Divider().overlay(AppTheme.chromeDivider.opacity(0.75))
            }
        }
    }

    private var detailCard: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(AppTheme.accent.opacity(0.6))
                .frame(width: 34, height: 34)
                .overlay {
                    Text(selectedCommit.initials)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(AppTheme.chromeText)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedCommit.title)
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(AppTheme.chromeText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(selectedCommit.author) committed 2 hours ago  •  \(selectedCommit.id)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.chromeMuted)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                statPill(text: "+\(selectedCommit.additions)", tint: Color.green.opacity(0.9))
                statPill(text: "-\(selectedCommit.deletions)", tint: Color.red.opacity(0.9))
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: 66)
        .background(AppTheme.panelDark)
    }

    private var diffSection: some View {
        DiffView(lines: viewModel.diffLines.isEmpty ? fallbackDiff : viewModel.diffLines, mode: .unified)
            .background(AppTheme.editorBackground)
    }

    private func statPill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .frame(height: 19)
            .background(tint.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 4))
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
}
