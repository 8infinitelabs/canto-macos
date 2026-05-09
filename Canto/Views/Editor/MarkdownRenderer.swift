import SwiftUI

/// Block-level markdown renderer using native SwiftUI.
/// Parses markdown into blocks and renders them with proper typography.
/// Parsing is cached — only recomputes when content changes.
struct MarkdownRenderer: View {
    let content: String
    @State private var blocks: [MarkdownBlock] = []

    init(content: String) {
        self.content = content
        _blocks = State(initialValue: parseBlocks(content))
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .drawingGroup()
        .onChange(of: content) { _, newContent in
            blocks = parseBlocks(newContent)
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

        case .table(let headers, let rows):
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                        Text(inlineMarkdown(header))
                            .font(CantoTypography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(CantoColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .textSelection(.enabled)
                        if index < headers.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(CantoColors.surface)

                Divider()

                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                            Text(inlineMarkdown(cell))
                                .font(CantoTypography.bodySmall)
                                .foregroundStyle(CantoColors.textPrimary.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .textSelection(.enabled)
                            if colIndex < row.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(rowIndex % 2 == 1 ? CantoColors.surface.opacity(0.5) : Color.clear)
                    if rowIndex < rows.count - 1 {
                        Divider()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CantoColors.textSecondary.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))

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
    case table(headers: [String], rows: [[String]])
    case divider
    case empty
}

// MARK: - Parser

func parseBlocks(_ markdown: String) -> [MarkdownBlock] {
    let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
    var blocks: [MarkdownBlock] = []
    blocks.reserveCapacity(lines.count / 2)
    var i = 0

    while i < lines.count {
        let rawLine = lines[i]
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        i += 1

        if trimmed.isEmpty { continue }

        // Use first character dispatch for fast classification
        switch trimmed.first {
        case "#" where trimmed.hasPrefix("#"):
            let hashes = trimmed.prefix(while: { $0 == "#" })
            let count = hashes.count
            if count <= 6 {
                let start = trimmed.index(trimmed.startIndex, offsetBy: count)
                let rest = trimmed[start...].trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty {
                    blocks.append(.heading(level: count, text: String(rest)))
                    continue
                }
            }

        case "-" where trimmed == "---":
            blocks.append(.divider)
            continue

        case ">":
            var quoteLines: [String] = []
            var j = i - 1
            while j < lines.count {
                let l = lines[j].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("> ") {
                    quoteLines.append(String(l.dropFirst(2)))
                    j += 1
                } else { break }
            }
            blocks.append(.quote(quoteLines.joined(separator: " ")))
            i = j
            continue

        case "-", "*":
            let rest = trimmed.dropFirst()
            if rest.hasPrefix(" ") {
                var items: [String] = []
                var j = i - 1
                while j < lines.count {
                    let l = lines[j].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("- ") || l.hasPrefix("* ") {
                        items.append(String(l.dropFirst(2)))
                        j += 1
                    } else { break }
                }
                blocks.append(.bulletList(items))
                i = j
                continue
            }

        case "`" where trimmed.hasPrefix("```"):
            let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            while i < lines.count {
                if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    i += 1
                    break
                }
                codeLines.append(String(lines[i]))
                i += 1
            }
            blocks.append(.codeBlock(code: codeLines.joined(separator: "\n"), language: language.isEmpty ? nil : language))
            continue

        case "|":
            var tableLines: [String] = []
            var j = i - 1
            while j < lines.count {
                let l = lines[j].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("|") {
                    tableLines.append(l)
                    j += 1
                } else { break }
            }
            i = j
            if tableLines.count >= 2 {
                let headers = parseTableRow(tableLines[0])
                let dataRows = tableLines.dropFirst(2).map { parseTableRow($0) }
                blocks.append(.table(headers: headers, rows: Array(dataRows)))
            } else if !tableLines.isEmpty {
                blocks.append(.paragraph(tableLines.joined(separator: " ")))
            }
            continue

        default:
            if let first = trimmed.first, first.isNumber, isNumberedLine(trimmed) {
                var items: [String] = []
                var j = i - 1
                while j < lines.count {
                    let l = lines[j].trimmingCharacters(in: .whitespaces)
                    if isNumberedLine(l) {
                        let dotIdx = l.firstIndex(of: ".")!
                        items.append(String(l[l.index(after: dotIdx)...]).trimmingCharacters(in: .whitespaces))
                        j += 1
                    } else { break }
                }
                blocks.append(.numberedList(items))
                i = j
                continue
            }
            break
        }

        // Paragraph fallthrough — collect consecutive non-empty lines
        var paraLines: [String] = []
        var j = i - 1
        while j < lines.count {
            let l = lines[j].trimmingCharacters(in: .whitespaces)
            if l.isEmpty { break }
            if isBlockStarter(l) { break }
            paraLines.append(String(lines[j]))
            j += 1
        }
        i = j
        if !paraLines.isEmpty {
            blocks.append(.paragraph(paraLines.joined(separator: " ")))
        }
    }

    return blocks
}

private func isNumberedLine(_ s: String) -> Bool {
    guard let first = s.first, first.isNumber else { return false }
    // Find the dot-space pattern: "1. " or "12. "
    var digits = 0
    for ch in s {
        if ch.isNumber { digits += 1; continue }
        if ch == "." && digits > 0 {
            let after = s[s.index(s.startIndex, offsetBy: digits + 1)...]
            return after.hasPrefix(" ")
        }
        return false
    }
    return false
}

private func isBlockStarter(_ s: String) -> Bool {
    guard let first = s.first else { return false }
    switch first {
    case "#": return s.hasPrefix("#")
    case "-": return s.hasPrefix("- ") || s == "---"
    case "*": return s.hasPrefix("* ") || s == "***"
    case ">": return s.hasPrefix("> ")
    case "`": return s.hasPrefix("```")
    case "|": return true
    case "0"..."9": return isNumberedLine(s)
    default: return false
    }
}

private func parseTableRow(_ line: String) -> [String] {
    var s = line.trimmingCharacters(in: .whitespaces)
    if s.hasPrefix("|") { s = String(s.dropFirst()) }
    if s.hasSuffix("|") { s = String(s.dropLast()) }
    return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
}
