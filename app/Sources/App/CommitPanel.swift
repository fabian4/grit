import SwiftUI

struct CommitPanel: View {
    @ObservedObject var viewModel: RepoViewModel

    var body: some View {
        HStack(spacing: 0) {
            commitEditor
            Rectangle().fill(AppTheme.chromeDividerStrong).frame(width: 1)
            stagedSummary
        }
        .frame(height: 124)
        .background(AppTheme.commitBarBackground)
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.035)).frame(height: 1) }
    }

    private var commitEditor: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.isRepoOpen {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppTheme.commitFieldFill.opacity(0.82))
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(AppTheme.commitFieldStroke, lineWidth: 1)

                TextField(
                    "",
                    text: $viewModel.commitMessage,
                    prompt: Text("Write a commit message...")
                        .foregroundColor(AppTheme.chromeMuted.opacity(0.73))
                )
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.chromeText.opacity(0.92))
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .disabled(viewModel.isBusy)
            } else {
                Text("Write a commit message...")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.chromeMuted.opacity(0.72))
                    .padding(.horizontal, 9)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var stagedSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STAGED CHANGES")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.chromeMuted.opacity(0.96))
                .padding(.leading, 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    if viewModel.stagedItems.isEmpty {
                        Text("Stage files to commit")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.chromeMuted.opacity(0.93))
                            .padding(.top, 4)
                    } else {
                        ForEach(viewModel.stagedItems.prefix(12)) { item in
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.95))
                                    .frame(width: 4, height: 4)
                                Text(URL(fileURLWithPath: item.path).lastPathComponent)
                                    .font(.system(size: 10.5, weight: .medium))
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
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .background(AppTheme.commitButtonBlue)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(viewModel.canCommit ? 1.0 : 0.45)
            .disabled(!viewModel.canCommit)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(width: 242, alignment: .leading)
    }
}
