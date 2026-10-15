import ElementaryUI
import Reactivity
import Trees

/// A letter as the page shows it: a space as `␣`.
func shown(_ letter: Character) -> String { letter == " " ? "␣" : String(letter) }

/// One marble on the Huffman timeline: a join of the two lightest trees (vertex `n + j`, the
/// `j`-th that `huffman(weights:)` made), or the code word of one letter read off the finished
/// tree.
enum HuffmanStep {
    case join(vertex: Int)
    case read(leaf: Int)
}

@Reactive
final class HuffmanModel {
    var text = "she sells sea shells"
    var letters: [Character] = []
    var counts: [Character: Int] = [:]
    var tree = BinaryTree<Int>.huffman(weights: [1])
    var codes: [Character: String] = [:]
    var bits = 0
    var plain = 0
    /// The weight of every vertex of the tree: a leaf's count, or the sum of its children's.
    var weight: [Int] = []
    var steps: [HuffmanStep] = []
    /// Where each vertex is drawn, and the drawing's height.
    var spots: [(x: Double, y: Double)] = []
    var height = 200
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-huffman")

    init() {
        set(text: text)
    }

    var leafCount: Int { letters.count }

    /// Counts the letters of `newText`, builds Grafluent's Huffman tree and rewinds.
    func set(text newText: String) {
        text = String(newText.prefix(60))
        guard !text.isEmpty else {
            letters = []
            steps = []
            spots = []
            playback.reset(count: 0)
            return
        }
        (letters, counts) = huffmanLetters(text)
        tree = huffmanTree(letters, counts)
        (codes, bits, plain) = huffmanCodes(text, letters, tree)
        let n = letters.count
        weight = letters.map { counts[$0]! } + [Int](repeating: 0, count: max(n - 1, 0))
        for v in n ..< 2 * n - 1 { weight[v] = weight[tree.left(of: v)!] + weight[tree.right(of: v)!] }
        steps = (n ..< 2 * n - 1).map { .join(vertex: $0) } + (0 ..< n).map { .read(leaf: $0) }
        layOut()
        playback.reset(count: steps.count)
    }

    /// Leaves side by side in the tree's symmetric order, each joined vertex over the middle of
    /// its children, one row per depth.
    func layOut() {
        let n = letters.count
        let gap = min(64.0, 640.0 / Double(max(n, 1)))
        var x = [Double](repeating: 0, count: 2 * n - 1)
        var column = 0
        for v in tree.inorder where v < n {
            x[v] = 340 - gap * Double(n - 1) / 2 + gap * Double(column)
            column += 1
        }
        for v in n ..< 2 * n - 1 { x[v] = (x[tree.left(of: v)!] + x[tree.right(of: v)!]) / 2 }
        spots = (0 ..< 2 * n - 1).map { v in (x[v], 36 + 62 * Double(tree.depth(of: v))) }
        height = 36 + 62 * tree.height + 64
    }

    /// The vertices made after the first `k` steps: every leaf, and the first joins.
    func made(_ k: Int) -> Int { letters.count + min(k, letters.count - 1) }

    /// The trees waiting to be joined after `k` steps, lightest first, a leaf before a joined
    /// tree and earlier before later on a tie, as `huffman(weights:)` takes them.
    func queue(_ k: Int) -> [Int] {
        let m = made(k)
        return (0 ..< m).filter { v in tree.parent(of: v).map { $0 >= m } ?? true }
            .sorted { (weight[$0], $0 >= letters.count ? 1 : 0, $0) < (weight[$1], $1 >= letters.count ? 1 : 0, $1) }
    }

    /// The path of code bits from the root to `leaf`, as the vertices passed.
    func path(to leaf: Int) -> [Int] {
        var path = [leaf], v = leaf
        while let parent = tree.parent(of: v) {
            path.insert(parent, at: 0)
            v = parent
        }
        return path
    }
}

let huffman = HuffmanModel()

/// The name of a tree in the queue: a letter, or the letters under a joined vertex.
func huffmanName(_ v: Int, _ model: HuffmanModel) -> String {
    if v < model.leafCount { return "“\(shown(model.letters[v]))”" }
    return "“" + model.tree.inorder.filter { $0 < model.leafCount && model.path(to: $0).contains(v) }.map { shown(model.letters[$0]) }.joined() + "”"
}

func describeHuffman(_ step: HuffmanStep, _ model: HuffmanModel) -> String {
    switch step {
    case .join(let v):
        let l = model.tree.left(of: v)!, r = model.tree.right(of: v)!
        return "Take the two lightest, \(huffmanName(l, model)) (\(model.weight[l])) and \(huffmanName(r, model)) (\(model.weight[r])). Join them under a new node weighing \(model.weight[v]), with the lighter on the 0 side."
    case .read(let leaf):
        let letter = model.letters[leaf]
        let word = model.codes[letter]!
        let count = model.counts[letter]!
        return "Read the path to “\(shown(letter))” from the top. Its code is \(word). It appears \(count) time\(count == 1 ? "" : "s"), so it costs \(count * word.count) bits."
    }
}

@View
struct HuffmanLab {
    var body: some View {
        let model = huffman
        let playback = model.playback
        let k = playback.k
        let n = model.leafCount
        let steps = model.steps
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let made = n == 0 ? 0 : model.made(k)
        let readCount = max(0, k - (n - 1))
        let reading: Int = { if case .read(let leaf)? = last { return leaf }; return -1 }()
        let route = reading >= 0 ? model.path(to: reading) : []
        let joined: Int = { if case .join(let v)? = last { return v }; return -1 }()
        let queue = n == 0 ? [] : model.queue(k)
        let nodes = model.spots.enumerated().map { v, spot in
            let leaf = v < n
            let read = leaf && v < readCount
            return CanvasNode(
                x: spot.x, y: spot.y, name: read ? model.codes[model.letters[v]]! : "",
                badge: leaf ? shown(model.letters[v]) : "\(model.weight[v])", note: leaf ? "×\(model.weight[v])" : "", radius: 15,
                classes: (v >= made ? "hidden" : leaf ? (read ? "visited" : "") : "done")
                    + (v == joined || route.contains(v) ? " current" : ""))
        }
        let edges = (n ..< made).flatMap { v in
            [model.tree.left(of: v)!, model.tree.right(of: v)!].enumerated().map { side, child in
                CanvasEdge(from: v, to: child, label: "\(side)",
                           classes: route.contains(v) && route.contains(child) ? "route" : v == joined ? "active" : "tree")
            }
        }

        div {
            section(.class("panel controls huffman-input"), .custom(name: "aria-label", value: "Your sentence")) {
                label(.class("field"), .for("huffman-text")) {
                    "Type a short sentence "
                    input(.id("huffman-text"), .type(.text), .value(model.text), .custom(name: "maxlength", value: "60"),
                          .custom(name: "spellcheck", value: "false"), .custom(name: "autocomplete", value: "off"))
                        .onInput { event in huffman.set(text: event.targetValue ?? "") }
                }
            }
            section(.class("lab"), .custom(name: "aria-label", value: "Building the Huffman tree")) {
                div(.class("panel stage")) {
                    if n == 0 {
                        p(.class("empty")) { "Type something to code." }
                    } else {
                        GraphCanvas(label: "The Huffman tree of the sentence’s letters, \(made - n) joins made so far", width: 680, height: model.height, nodes: nodes, edges: edges)
                    }
                    div(.class("legend")) {
                        span { i(.class("dot")) {}; "a letter, with its count" }
                        span { i(.class("dot done")) {}; "a join, with its weight" }
                        span { i(.class("dot visited")) {}; "code read, shown under it" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if n == 0 {
                                "Nothing to code yet."
                            } else if k == 0 {
                                "Each different letter starts as a tree of its own, weighted by how often it appears. Huffman joins the two lightest again and again, until one tree is left. Press Step to begin."
                            } else if finished {
                                "Every letter has a code, and none is the start of another, so the bits can be read back without gaps. The sentence takes "
                                em { "\(model.bits) bits" }
                                " instead of \(model.plain)."
                            } else {
                                describeHuffman(last!, model)
                            }
                        }
                    }
                    if readCount == 0 {
                        div(.class("panel")) {
                            span(.class("label")) { "Waiting to be joined, lightest first" }
                            div(.class("queue")) {
                                for (j, v) in queue.enumerated() {
                                    div(.class(j < 2 && queue.count > 1 ? "qrow top" : "qrow")) {
                                        span { huffmanName(v, model) }
                                        span(.class("num")) { "\(model.weight[v])" }
                                    }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Codes" }
                        div(.class("queue")) {
                            for (leaf, letter) in model.letters.enumerated() {
                                div(.class(leaf < readCount ? (leaf == reading ? "qrow top" : "qrow plain") : "qrow cable later")) {
                                    span { "\(shown(letter)) ×\(model.counts[letter]!)" }
                                    span(.class("num")) { leaf < readCount ? model.codes[letter]! : "…" }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The whole sentence" }
                        div(.class("stat")) {
                            div(.class("good")) {
                                span(.class("num")) { finished ? "\(model.bits)" : "?" }
                                "bits, Huffman"
                            }
                            div {
                                span(.class("num")) { "\(model.plain)" }
                                "bits at 8 a letter"
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { step in
                        switch step {
                        case .join(let v): Marble(kind: "m-blue", radius: 10, letter: "\(model.weight[v])", title: describeHuffman(step, model))
                        case .read(let leaf): Marble(kind: "m-green", radius: 9, letter: shown(model.letters[leaf]), title: describeHuffman(step, model))
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "join the two lightest, with the new weight"),
                        (Marble(kind: "m-green", radius: 6), "read a letter’s code"),
                    ])
                p(.class("note")) { "0 on each left branch, 1 on each right. Under each letter: how often it appears." }
            }
        }
    }
}

@View
struct HuffmanCodePanel {
    var body: some View {
        let model = huffman
        let escaped = model.text.replacingAll("\\", with: "\\\\").replacingAll("\"", with: "\\\"")
        CodePanel(
            snippets: [.huffmanImports, Snippet(lines: ["let text = \"\(escaped)\""]), .huffmanCount, .huffmanTree, .huffmanCodes],
            results: model.letters.isEmpty ? [] : ["\(model.tree.vertexCount)", "\(model.bits)", "\(model.plain)"])
    }
}

extension String {
    /// The string with every `target` replaced by `replacement`, without Foundation.
    func replacingAll(_ target: Character, with replacement: String) -> String {
        var out = ""
        for c in self { if c == target { out += replacement } else { out.append(c) } }
        return out
    }
}

enum HuffmanPage {
    static func mount() {
        mountView(HuffmanLab(), in: "app")
        mountView(HuffmanCodePanel(), in: "code")
    }
}
