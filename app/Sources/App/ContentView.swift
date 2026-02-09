import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = RepoViewModel.shared
    @FocusState private var isPathFocused: Bool
    @State private var splitRatio: CGFloat = CGFloat(AppConfig.shared.splitRatio)

    var body: some View {
        ZStack {
            AppTheme.windowBackdrop.ignoresSafeArea()

            WorkspaceShell(viewModel: viewModel, splitRatio: $splitRatio)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppTheme.chromeDivider, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 4)
                .padding(12)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    isPathFocused = true
                }
                .background(AppTheme.mainDark)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(AppTheme.windowBackdrop)
        .preferredColorScheme(.dark)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            isPathFocused = true
        }
    }
}
