import SwiftUI

/// Block-level markdown renderer using native SwiftUI.
/// Parses markdown into blocks and renders them as proper typography.
struct MarkdownRenderer: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseBlocks(content).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inlineMarkdown(text))
                .font(headingFont(level: level))
                .foregroundStyle(CantoColors.textPrimary)
                .textSelection(.enabled)
                .padding(.top, level == 1 ? 4 : 2)

        case .paragraph(let text):
            Text(inlineMarkdown(text))
                .font(CantoTypography.body)
                .foregroundStyle(CantoColors.textPrimary.opacity(0.9))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .foregroundStyle(CantoColors.accent)
                        Text(inlineMarkdown(item))
                            .font(CantoTypography.body)
                            .foregroundStyle(CantoColors.textPrimary.opacity(0.9))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .foregroundStyle(CantoColors.accent)
                            .font(CantoTypography.body)
                        Text(inlineMarkdown(item))
                            .font(CantoTypography.body)
                            .foregroundStyle(CantoColors.textPrimary.opacity(0.9))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .codeBlock(let code, _):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(CantoTypography.code)
                    .foregroundStyle(CantoColors.textPrimary)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(CantoColors.surface)
            .cornerRadius(6)

        case .quote(let text):
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(CantoColors.accent)
                    .frame(width: 3)
                Text(inlineMarkdown(text))
                    .font(CantoTypography.body)
                    .foregroundStyle(CantoColors.textPrimary.opacity(0.7))
                    .italic()
                    .textSelection(.enabled)
            }

        case .divider:
            Divider()
                .padding(.vertical, 4)

        case .empty:
            EmptyView()
        }
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: return .system(size: 28, weight: .bold)
        case 2: return .system(size: 22, weight: .bold)
        case 3: return .system(size: 18, weight: .semibold)
        case 4: return .system(size: 16, weight: .semibold)
        default: return .system(size: 15, weight: .semibold)
        }
    }

    /// Parse inline markdown (bold, italic, code, links) using AttributedString.
    private func inlineMarkdown(_ text: String) -> AttributedString {
        if let attr = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attr
        }
        return AttributedString(text)
    }
}

// MARK: - Block types

enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletList([String])
    case numberedList([String])
    case codeBlock(code: String, language: String?)
    case quote(String)
    case divider
    case empty
}

// MARK: - Parser

func parseBlocks(_ markdown: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    var lines = markdown.components(separatedBy: .newlines)
    var i = 0

    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Empty line — skip (block separator)
        if trimmed.isEmpty {
            i += 1
            continue
        }

        // Heading
        if let match = trimmed.range(of: #"^(#{1,6})\s+(.+)$"#, options: .regularExpression) {
            let hashes = trimmed.prefix(while: { $0 == "#" })
            let level = hashes.count
            let text = String(trimmed[match].dropFirst(level).trimmingCharacters(in: .whitespaces))
            blocks.append(.heading(level: level, text: text))
            i += 1
            continue
        }

        // Divider
        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            blocks.append(.divider)
            i += 1
            continue
        }

        // Code block (fenced)
        if trimmed.hasPrefix("```") {
            let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            i += 1
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("```") {
                    i += 1
                    break
                }
                codeLines.append(lines[i])
                i += 1
            }
            blocks.append(.codeBlock(code: codeLines.joined(separator: "\n"), language: language.isEmpty ? nil : language))
            continue
        }

        // Quote
        if trimmed.hasPrefix("> ") {
            var quoteLines: [String] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("> ") {
                    quoteLines.append(String(l.dropFirst(2)))
                    i += 1
                } else {
                    break
                }
            }
            blocks.append(.quote(quoteLines.joined(separator: " ")))
            continue
        }

        // Bullet list
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            var items: [String] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("- ") || l.hasPrefix("* ") {
                    items.append(String(l.dropFirst(2)))
                    i += 1
                } else {
                    break
                }
            }
            blocks.append(.bulletList(items))
            continue
        }

        // Numbered list
        if trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
            var items: [String] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if let match = l.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                    items.append(String(l[match.upperBound...]))
                    i += 1
                } else {
                    break
                }
            }
            blocks.append(.numberedList(items))
            continue
        }

        // Paragraph — collect consecutive non-empty lines
        var paragraphLines: [String] = []
        while i < lines.count {
            let l = lines[i].trimmingCharacters(in: .whitespaces)
            if l.isEmpty { break }
            // Stop if we hit a block starter
            if l.hasPrefix("#") || l.hasPrefix("- ") || l.hasPrefix("* ") ||
               l.hasPrefix("> ") || l.hasPrefix("```") || l == "---" ||
               l.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                break
            }
            paragraphLines.append(lines[i])
            i += 1
        }
        if !paragraphLines.isEmpty {
            blocks.append(.paragraph(paragraphLines.joined(separator: " ")))
        }
    }

    return blocks
}
