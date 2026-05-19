import Foundation

extension String {
    func floatingCaptionTail(maxLines: Int) -> String {
        let maxLines = max(1, maxLines)
        let trimmedText = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return "" }

        let maxCharactersPerLine = trimmedText.floatingCaptionCharactersPerLine()
        let maxCharacters = maxLines * maxCharactersPerLine
        let cueText = trimmedText.floatingCaptionCue(maxCharacters: maxCharacters)
        let wrappedCue = cueText
            .balancedWrappedForFloatingCaptions(
                maxLines: maxLines,
                maxCharactersPerLine: maxCharactersPerLine
            )

        guard wrappedCue.count > maxCharacters else { return wrappedCue }

        let boundedText = String(wrappedCue.suffix(maxCharacters))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return boundedText.balancedWrappedForFloatingCaptions(
            maxLines: maxLines,
            maxCharactersPerLine: maxCharactersPerLine
        )
    }

    private func boundedSuffix(maxCharacters: Int) -> Substring {
        guard maxCharacters > 0,
              let start = index(endIndex, offsetBy: -maxCharacters, limitedBy: startIndex)
        else {
            return self[startIndex..<endIndex]
        }

        return self[start..<endIndex]
    }

    private func floatingCaptionCue(maxCharacters: Int) -> String {
        let scanText = String(boundedSuffix(maxCharacters: maxCharacters * 5))
            .normalizedFloatingCaptionWhitespace()
        let phrases = scanText.floatingCaptionPhrases(maxCharactersPerPhrase: max(34, maxCharacters))
        guard !phrases.isEmpty else { return scanText }

        var selected: [String] = []
        var selectedLength = 0
        for phrase in phrases.reversed() {
            let phraseLength = phrase.count
            if selected.isEmpty {
                selected.insert(phrase, at: 0)
                selectedLength += phraseLength
                continue
            }

            let projectedLength = selectedLength + phraseLength + 1
            guard projectedLength <= maxCharacters else { break }

            if selectedLength < maxCharacters / 3 || phrase.isSoftContinuation {
                selected.insert(phrase, at: 0)
                selectedLength = projectedLength
            } else {
                break
            }
        }

        return selected.joined(separator: " ")
    }

    private func balancedWrappedForFloatingCaptions(
        maxLines: Int,
        maxCharactersPerLine: Int
    ) -> String {
        let lines = normalizedFloatingCaptionWhitespace()
            .components(separatedBy: .newlines)
            .flatMap { line in
                line.wrapCaptionLine(maxLines: maxLines, maxCharacters: maxCharactersPerLine)
            }
        if lines.count <= maxLines {
            return lines.joined(separator: "\n")
        }
        return lines.suffix(maxLines).joined(separator: "\n")
    }

    private func wrapCaptionLine(maxLines: Int, maxCharacters: Int) -> [String] {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        guard text.count > maxCharacters else { return [text] }

        let words = split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard words.count > 1 else {
            return chunked(maxCharacters: maxCharacters)
        }

        if maxLines == 2, let balanced = balancedTwoLineWrap(words: words, maxCharacters: maxCharacters) {
            return balanced
        }

        var lines: [String] = []
        var current = ""
        for word in words {
            let candidate = current.isEmpty ? word : "\(current) \(word)"
            if candidate.count <= maxCharacters {
                current = candidate
            } else {
                if !current.isEmpty { lines.append(current) }
                current = word
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines.flatMap { $0.chunked(maxCharacters: maxCharacters) }
    }

    private func balancedTwoLineWrap(words: [String], maxCharacters: Int) -> [String]? {
        guard words.count > 2 else { return nil }

        let totalLength = words.joined(separator: " ").count
        var best: (index: Int, score: Int)?
        for index in 1..<words.count {
            let first = words[..<index].joined(separator: " ")
            let second = words[index...].joined(separator: " ")
            guard first.count <= maxCharacters, second.count <= maxCharacters else { continue }

            let balanceScore = abs(first.count - second.count)
            let punctuationBonus = words[index - 1].hasFloatingCaptionPause ? -8 : 0
            let midpointScore = abs(first.count - totalLength / 2)
            let score = balanceScore + midpointScore / 3 + punctuationBonus
            if best == nil || score < best!.score {
                best = (index, score)
            }
        }

        guard let best else { return nil }
        return [
            words[..<best.index].joined(separator: " "),
            words[best.index...].joined(separator: " ")
        ]
    }

    private func chunked(maxCharacters: Int) -> [String] {
        guard count > maxCharacters else { return [self] }

        var chunks: [String] = []
        var start = startIndex
        while start < endIndex {
            let end = index(start, offsetBy: maxCharacters, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[start..<end]))
            start = end
        }
        return chunks
    }

    private func floatingCaptionPhrases(maxCharactersPerPhrase: Int) -> [String] {
        var phrases: [String] = []
        var current = ""

        for scalar in unicodeScalars {
            current.unicodeScalars.append(scalar)

            let character = Character(scalar)
            if character.isStrongCaptionBoundary
                || (current.count >= maxCharactersPerPhrase && character.isSoftCaptionBoundary) {
                let phrase = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !phrase.isEmpty { phrases.append(phrase) }
                current = ""
            }
        }

        let tail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { phrases.append(tail) }

        return phrases
            .flatMap { phrase in
                phrase.splitLongCaptionPhrase(maxCharacters: maxCharactersPerPhrase)
            }
            .filter { !$0.isEmpty }
    }

    private func splitLongCaptionPhrase(maxCharacters: Int) -> [String] {
        guard count > maxCharacters else { return [self] }

        let splitPattern = #"(?i)\s+(?=(which|that|who|when|where|while|because|although|but|and|or|so)\b)"#
        let splitText = replacingOccurrences(of: splitPattern, with: "\n", options: .regularExpression)
        let parts = splitText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard parts.count > 1 else { return chunked(maxCharacters: maxCharacters) }
        return parts.flatMap { $0.count > maxCharacters ? $0.chunked(maxCharacters: maxCharacters) : [$0] }
    }

    private func normalizedFloatingCaptionWhitespace() -> String {
        replacingOccurrences(of: #"[ \t\r\f]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func floatingCaptionCharactersPerLine() -> Int {
        if containsCJK {
            return 22
        }
        if containsArabicScript {
            return 32
        }
        return 64
    }

    private var containsCJK: Bool {
        unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
                || (0x3040...0x30FF).contains(Int(scalar.value))
                || (0xAC00...0xD7AF).contains(Int(scalar.value))
        }
    }

    private var containsArabicScript: Bool {
        unicodeScalars.contains { scalar in
            (0x0600...0x06FF).contains(Int(scalar.value))
                || (0x0750...0x077F).contains(Int(scalar.value))
                || (0x08A0...0x08FF).contains(Int(scalar.value))
        }
    }

    private var isSoftContinuation: Bool {
        range(
            of: #"(?i)^(which|that|who|when|where|while|because|although|but|and|or|so)\b"#,
            options: .regularExpression
        ) != nil
    }

    private var hasFloatingCaptionPause: Bool {
        hasSuffix(",") || hasSuffix("，") || hasSuffix(";") || hasSuffix("；") || hasSuffix(":") || hasSuffix("：")
    }
}

private extension Character {
    var isStrongCaptionBoundary: Bool {
        ".!?。！？؟".contains(self) || self == "\n"
    }

    var isSoftCaptionBoundary: Bool {
        ",，;；:：،".contains(self)
    }
}
