import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = RepoViewModel()
    @FocusState private var isPathFocused: Bool
    @State private var splitRatio: CGFloat = CGFloat(AppConfig.shared.splitRatio)

    var body: some View {
        VStack(spacing: 0) {
            panelArea
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            isPathFocused = true
            Task { await viewModel.openRepo() }
        }
    }
}

private extension ContentView {
    @ViewBuilder
    var panelArea: some View {
        VStack(spacing: 0) {
            ResizableSplitView(ratio: $splitRatio, minLeft: 180, minRight: 400) {
                LeftPanel(viewModel: viewModel)
            } right: {
                MainPanel(viewModel: viewModel)
            }
            Divider()
            BottomPanel()
                .frame(minHeight: 180, maxHeight: 260)
        }
    }
}
