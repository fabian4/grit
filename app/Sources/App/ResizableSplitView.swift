import SwiftUI

struct ResizableSplitView<Left: View, Right: View>: View {
    @Binding var ratio: CGFloat
    let minLeft: CGFloat
    let minRight: CGFloat
    @ViewBuilder let left: Left
    @ViewBuilder let right: Right

    init(
        ratio: Binding<CGFloat>,
        minLeft: CGFloat = 180,
        minRight: CGFloat = 400,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self._ratio = ratio
        self.minLeft = minLeft
        self.minRight = minRight
        self.left = left()
        self.right = right()
    }

    var body: some View {
        GeometryReader { geo in
            let total = geo.size.width
            let leftWidth = clamp(total * ratio, minLeft, total - minRight)
            HStack(spacing: 0) {
                left
                    .frame(width: leftWidth)
                Divider()
                    .frame(width: 1)
                    .background(Color.gray.opacity(0.4))
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                let newLeft = clamp(leftWidth + value.translation.width, minLeft, total - minRight)
                                ratio = newLeft / total
                            }
                    )
                right
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func clamp(_ value: CGFloat, _ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
        min(max(value, minValue), maxValue)
    }
}
