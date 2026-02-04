import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = RepoViewModel()
    @FocusState private var isPathFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Repo path", text: $viewModel.repoPath, prompt: Text("/path/to/repo"))
                    .textFieldStyle(.roundedBorder)
                    .focused($isPathFocused)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        NSApp.activate(ignoringOtherApps: true)
                        isPathFocused = true
                    }
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

            ScrollView {
                Text(viewModel.output)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
                    .padding(6)
            }
            .border(Color.gray.opacity(0.3))
        }
        .padding()
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            isPathFocused = true
        }
    }
}
