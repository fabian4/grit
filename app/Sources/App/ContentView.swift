import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RepoViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("/path/to/repo", text: $viewModel.repoPath)
                    .textFieldStyle(.roundedBorder)
                Button("Open Repo") {
                    Task { await viewModel.openRepo() }
                }
            }

            HStack {
                Button("Run Git Status") {
                    Task { await viewModel.runStatus() }
                }
                .disabled(!viewModel.isRepoOpen)

                Button("Run Git Diff") {
                    Task { await viewModel.runDiff() }
                }
                .disabled(!viewModel.isRepoOpen)
            }

            TextEditor(text: $viewModel.output)
                .font(.system(.body, design: .monospaced))
                .border(Color.gray.opacity(0.3))
        }
        .padding()
        .frame(minWidth: 640, minHeight: 480)
    }
}
