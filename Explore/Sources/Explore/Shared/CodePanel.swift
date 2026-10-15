import ElementaryUI

/// A region of a page's source, between `// snippet: name` and `// snippet end`. The Snippets
/// build plugin writes one constant per region (`Snippet.dijkstraTown` and so on), so the code a
/// page shows is the code it compiles. A line ending in `// →` gets a result the page computed.
struct Snippet {
    var lines: [String]
}

/// Swift code with its results: `bindings` (the values the page passes in, as `let` lines), then
/// each snippet, with the `// →` markers filled from `results` in order.
@View
struct CodePanel {
    var bindings: [String] = []
    var snippets: [Snippet]
    var results: [String] = []

    var body: some View {
        let lines = CodePanel.lines(bindings: bindings, snippets: snippets, results: results)
        span {
            for line in lines {
                for token in highlight(line) {
                    if token.kind.isEmpty {
                        token.text
                    } else {
                        span(.class(token.kind)) { token.text }
                    }
                }
                "\n"
            }
        }
    }

    static func lines(bindings: [String], snippets: [Snippet], results: [String]) -> [String] {
        var out = bindings
        if !bindings.isEmpty { out.append("") }
        var slot = 0
        for (n, snippet) in snippets.enumerated() {
            if n > 0 { out.append("") }
            for line in snippet.lines {
                guard line.hasSuffix("// →") else {
                    out.append(line)
                    continue
                }
                // The source aligns its markers; results vary in length, so each follows its code
                // after two spaces.
                let code = String(line.dropLast("// →".count).reversed().drop(while: { $0 == " " }).reversed())
                out.append(slot < results.count ? code + "  // " + results[slot] : code)
                slot += 1
            }
        }
        return out
    }
}

let swiftKeywords: Set<Substring> = [
    "import", "let", "var", "for", "in", "if", "else", "func", "return", "true", "false", "nil", "try",
    "catch", "do", "switch", "case", "guard", "while", "some", "where", "struct", "enum", "throws",
]

/// One line of Swift split into runs: keywords `k`, strings `s`, comments `c`, numbers `n`,
/// type names `t`, and plain text.
func highlight(_ line: String) -> [(text: String, kind: String)] {
    var tokens: [(text: String, kind: String)] = []
    var plain = ""
    func emit(_ text: Substring, _ kind: String) {
        if !plain.isEmpty { tokens.append((plain, "")); plain = "" }
        tokens.append((String(text), kind))
    }
    var i = line.startIndex
    while i < line.endIndex {
        let c = line[i]
        if line[i...].hasPrefix("//") {
            emit(line[i...], "c")
            break
        } else if c == "\"" {
            var j = line.index(after: i)
            while j < line.endIndex, line[j] != "\"" {
                if line[j] == "\\" { j = line.index(after: j) }
                if j < line.endIndex { j = line.index(after: j) }
            }
            if j < line.endIndex { j = line.index(after: j) }
            emit(line[i ..< j], "s")
            i = j
            continue
        } else if c.isNumber, (plain.last.map { !$0.isLetter && $0 != "_" } ?? true) {
            var j = i
            while j < line.endIndex, line[j].isNumber || line[j] == "." || line[j] == "_" { j = line.index(after: j) }
            if line[line.index(before: j)] == "." { j = line.index(before: j) }
            emit(line[i ..< j], "n")
            i = j
            continue
        } else if c.isLetter || c == "_" {
            var j = i
            while j < line.endIndex, line[j].isLetter || line[j].isNumber || line[j] == "_" { j = line.index(after: j) }
            let word = line[i ..< j]
            if swiftKeywords.contains(word) {
                emit(word, "k")
            } else if c.isUppercase {
                emit(word, "t")
            } else {
                plain += word
            }
            i = j
            continue
        }
        plain.append(c)
        i = line.index(after: i)
    }
    if !plain.isEmpty { tokens.append((plain, "")) }
    return tokens
}
