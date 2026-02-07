import SwiftUI
import AppKit

struct DiffTextView: NSViewRepresentable {
    @Binding var text: String
    let lines: [DiffLine]
    let mode: DiffViewMode
    let isEditable: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isRichText = true
        textView.usesFindPanel = true
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.textColor = NSColor(calibratedWhite: 0.88, alpha: 1.0)
        textView.insertionPointColor = NSColor(calibratedWhite: 0.88, alpha: 1.0)
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.delegate = context.coordinator
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        textView.isEditable = isEditable

        let displayString = buildAttributedString(in: nsView)
        if textView.textStorage?.string != displayString.string {
            textView.textStorage?.setAttributedString(displayString)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    private func buildAttributedString(in scrollView: NSScrollView) -> NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping

        let contentWidth = scrollView.contentSize.width
        let leftColumn = max(240, contentWidth * 0.5)
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: leftColumn)]

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor(calibratedWhite: 0.88, alpha: 1.0)
        ]

        let result = NSMutableAttributedString()

        let maxOld = maxDigits(lines.map { $0.oldLine })
        let maxNew = maxDigits(lines.map { $0.newLine })

        for line in lines {
            let lineString = formatLine(line, maxOld: maxOld, maxNew: maxNew, mode: mode)
            let start = result.length
            result.append(NSAttributedString(string: lineString + "\n", attributes: attrs))

            let fullRange = NSRange(location: start, length: lineString.count)
            applyBackground(line: line, to: result, range: fullRange, mode: mode)
        }

        return result
    }

    private func formatLine(_ line: DiffLine, maxOld: Int, maxNew: Int, mode: DiffViewMode) -> String {
        let oldStr = formatNumber(line.oldLine, width: maxOld)
        let newStr = formatNumber(line.newLine, width: maxNew)

        switch mode {
        case .unified:
            return "\(oldStr) \(newStr) \(line.text)"
        case .sideBySide:
            let leftText = sideText(line, isLeft: true)
            let rightText = sideText(line, isLeft: false)
            return "\(oldStr) \(leftText)\t\(newStr) \(rightText)"
        }
    }

    private func sideText(_ line: DiffLine, isLeft: Bool) -> String {
        switch line.kind {
        case .added:
            return isLeft ? "" : stripPrefix(line.text)
        case .removed:
            return isLeft ? stripPrefix(line.text) : ""
        case .context:
            return stripPrefix(line.text)
        default:
            return line.text
        }
    }

    private func applyBackground(line: DiffLine, to text: NSMutableAttributedString, range: NSRange, mode: DiffViewMode) {
        let fullColor: NSColor? = {
            switch line.kind {
            case .added: return NSColor.systemGreen.withAlphaComponent(0.15)
            case .removed: return NSColor.systemRed.withAlphaComponent(0.15)
            case .hunk: return NSColor.gray.withAlphaComponent(0.2)
            case .meta: return NSColor.gray.withAlphaComponent(0.1)
            case .context: return nil
            }
        }()

        switch mode {
        case .unified:
            if let color = fullColor {
                text.addAttribute(.backgroundColor, value: color, range: range)
            }
        case .sideBySide:
            if line.kind == .meta || line.kind == .hunk {
                if let color = fullColor {
                    text.addAttribute(.backgroundColor, value: color, range: range)
                }
                return
            }
            guard let tabIndex = (text.string as NSString).range(of: "\t", options: [], range: range).toOptional() else {
                return
            }
            let leftRange = NSRange(location: range.location, length: tabIndex.location - range.location)
            let rightRange = NSRange(location: tabIndex.location + 1, length: range.upperBound - (tabIndex.location + 1))

            if line.kind == .removed {
                text.addAttribute(.backgroundColor, value: NSColor.systemRed.withAlphaComponent(0.15), range: leftRange)
            } else if line.kind == .added {
                text.addAttribute(.backgroundColor, value: NSColor.systemGreen.withAlphaComponent(0.15), range: rightRange)
            }
        }
    }

    private func maxDigits(_ numbers: [Int?]) -> Int {
        let maxValue = numbers.compactMap { $0 }.max() ?? 0
        return max(String(maxValue).count, 1)
    }

    private func formatNumber(_ number: Int?, width: Int) -> String {
        guard let number else { return String(repeating: " ", count: width) }
        let text = String(number)
        if text.count >= width { return text }
        return String(repeating: " ", count: width - text.count) + text
    }

    private func stripPrefix(_ text: String) -> String {
        guard let first = text.first else { return text }
        if first == "+" || first == "-" || first == " " {
            return String(text.dropFirst())
        }
        return text
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

private extension NSRange {
    func toOptional() -> NSRange? {
        self.location == NSNotFound ? nil : self
    }
}
