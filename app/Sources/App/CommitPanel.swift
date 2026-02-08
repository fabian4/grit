import SwiftUI

struct CommitPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            commitEditor
            Rectangle().fill(AppTheme.chromeDivider).frame(width: 1)
            stagedSummary
        }
        .frame(height: 140)
        .background(AppTheme.panelDark)
    }

    private var commitEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WRITE A COMMIT MESSAGE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.commitMessage)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(AppTheme.chromeText.opacity(0.95))
                    .padding(8)
                    .background(AppTheme.mainDark)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider.opacity(0.9), lineWidth: 1))
                    .disabled(!viewModel.isRepoOpen || viewModel.isBusy)

                if viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Write a commit message…")
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stagedSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STAGED CHANGES")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if viewModel.stagedItems.isEmpty {
                        Text("Stage files to commit")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
                            .padding(.top, 4)
                    } else {
                        ForEach(viewModel.stagedItems.prefix(12)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.95))
                                    .frame(width: 5, height: 5)
                                Text(URL(fileURLWithPath: item.path).lastPathComponent)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(AppTheme.chromeText.opacity(0.92))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Button("Commit Changes") {
                Task { await viewModel.commitFromMessage() }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(viewModel.canCommit ? 1.0 : 0.45)
            .disabled(!viewModel.canCommit)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 260, alignment: .leading)
    }
}
