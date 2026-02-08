import SwiftUI

struct CommitPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Commit")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.9))
                Spacer(minLength: 0)
                Text("branch \(viewModel.currentBranch)")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
                Text("staged \(viewModel.stagedCount)")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.chromeDarkElevated)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.commitMessage)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.chromeText)
                    .padding(6)
                    .frame(height: 72)
                    .background(AppTheme.editorBackground)
                    .overlay(Rectangle().stroke(AppTheme.chromeDivider, lineWidth: 1))
                    .disabled(!viewModel.isRepoOpen || viewModel.isBusy)

                if viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(viewModel.stagedCount == 0 ? "Stage files to commit" : "Write a commit message")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                Button("Commit") { Task { await viewModel.commitFromMessage() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 86, height: 22)
                    .background(AppTheme.accent)
                    .opacity(viewModel.canCommit ? 1.0 : 0.45)
                    .disabled(!viewModel.canCommit)
                    .keyboardShortcut(.return, modifiers: .command)

                Spacer(minLength: 0)
                if viewModel.isBusy {
                    Text("Running…")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.chromeMuted.opacity(0.85))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(AppTheme.chromeDark)
    }
}

