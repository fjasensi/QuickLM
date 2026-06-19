import AppKit
import SwiftUI

struct MarkdownResponseView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 14)
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let selectedRange = textView.selectedRange()
        textView.textStorage?.setAttributedString(MarkdownResponseFormatter.render(text))

        if selectedRange.location != NSNotFound, selectedRange.upperBound <= textView.string.utf16.count {
            textView.setSelectedRange(selectedRange)
        }
    }
}

private enum MarkdownResponseFormatter {
    private enum BlockKind {
        case paragraph
        case heading
        case quote
        case bullet
        case ordered(String)
    }

    static func render(_ text: String) -> NSAttributedString {
        let normalizedText = text.replacingOccurrences(of: "\\n", with: "\n")
        let output = NSMutableAttributedString()
        let lines = normalizedText.components(separatedBy: "\n")

        for (index, rawLine) in lines.enumerated() {
            let parsed = parseBlock(rawLine)

            if parsed.content.isEmpty {
                output.append(NSAttributedString(string: "\n", attributes: attributes(for: .paragraph)))
                continue
            }

            let line = NSMutableAttributedString()
            if let prefix = parsed.prefix {
                line.append(NSAttributedString(string: prefix, attributes: attributes(for: parsed.kind, isBold: true)))
            }

            line.append(renderInline(parsed.content, kind: parsed.kind))
            output.append(line)

            if index < lines.count - 1 {
                output.append(NSAttributedString(string: "\n", attributes: attributes(for: parsed.kind)))
            }
        }

        return output
    }

    private static func parseBlock(_ rawLine: String) -> (kind: BlockKind, prefix: String?, content: String) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)

        guard !line.isEmpty else {
            return (.paragraph, nil, "")
        }

        if let heading = headingContent(from: line) {
            return (.heading, nil, heading)
        }

        if line.hasPrefix(">") {
            let content = line.dropFirst().trimmingCharacters(in: .whitespaces)
            return (.quote, nil, String(content))
        }

        if line.hasPrefix("* ") || line.hasPrefix("- ") {
            return (.bullet, "• ", String(line.dropFirst(2)))
        }

        if let ordered = orderedListContent(from: line) {
            return (.ordered(ordered.prefix), ordered.prefix, ordered.content)
        }

        return (.paragraph, nil, line)
    }

    private static func headingContent(from line: String) -> String? {
        let hashes = line.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }

        let contentStart = line.index(line.startIndex, offsetBy: hashes.count)
        guard contentStart < line.endIndex, line[contentStart] == " " else { return nil }

        return String(line[contentStart...]).trimmingCharacters(in: .whitespaces)
    }

    private static func orderedListContent(from line: String) -> (prefix: String, content: String)? {
        var index = line.startIndex

        while index < line.endIndex, line[index].isNumber {
            index = line.index(after: index)
        }

        guard index > line.startIndex, index < line.endIndex else { return nil }
        guard line[index] == "." || line[index] == ")" else { return nil }

        let separatorIndex = index
        index = line.index(after: index)
        guard index < line.endIndex, line[index] == " " else { return nil }

        let prefix = String(line[line.startIndex...separatorIndex]) + " "
        let content = String(line[line.index(after: index)...])
        return (prefix, content)
    }

    private static func renderInline(_ text: String, kind: BlockKind) -> NSAttributedString {
        let output = NSMutableAttributedString()
        var cursor = text.startIndex

        while cursor < text.endIndex {
            if text[cursor...].hasPrefix("**") {
                let boldStart = text.index(cursor, offsetBy: 2)
                guard let closing = text[boldStart...].range(of: "**") else {
                    append(text[cursor...], to: output, kind: kind)
                    return output
                }

                append(text[boldStart..<closing.lowerBound], to: output, kind: kind, isBold: true)
                cursor = closing.upperBound
            } else if text[cursor] == "`", let closing = text[text.index(after: cursor)...].firstIndex(of: "`") {
                let codeStart = text.index(after: cursor)
                append(text[codeStart..<closing], to: output, kind: kind, isCode: true)
                cursor = text.index(after: closing)
            } else if text[cursor] == "`" {
                append(text[cursor...], to: output, kind: kind)
                return output
            } else {
                let nextBold = text[cursor...].range(of: "**")?.lowerBound
                let nextCode = text[cursor...].firstIndex(of: "`")
                let next = [nextBold, nextCode].compactMap { $0 }.min() ?? text.endIndex
                append(text[cursor..<next], to: output, kind: kind)
                cursor = next
            }
        }

        return output
    }

    private static func append(_ substring: Substring, to output: NSMutableAttributedString, kind: BlockKind, isBold: Bool = false, isCode: Bool = false) {
        guard !substring.isEmpty else { return }

        output.append(NSAttributedString(
            string: String(substring),
            attributes: attributes(for: kind, isBold: isBold, isCode: isCode)
        ))
    }

    private static func attributes(for kind: BlockKind, isBold: Bool = false, isCode: Bool = false) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacing = 8

        switch kind {
        case .bullet, .ordered:
            paragraphStyle.headIndent = 22
            paragraphStyle.firstLineHeadIndent = 0
        case .quote:
            paragraphStyle.headIndent = 14
            paragraphStyle.firstLineHeadIndent = 14
        default:
            break
        }

        let font: NSFont
        if isCode {
            font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        } else if case .heading = kind {
            font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        } else {
            font = NSFont.systemFont(ofSize: 15, weight: isBold ? .semibold : .regular)
        }

        let color: NSColor = {
            switch kind {
            case .quote:
                return .secondaryLabelColor
            default:
                return .labelColor
            }
        }()

        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
    }
}
