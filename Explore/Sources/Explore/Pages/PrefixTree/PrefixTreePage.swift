import ElementaryUI
import GraphProtocols
import Reactivity
import Trees

/// Where each vertex of the whole word list's prefix tree is drawn, in SVG units of the
/// 680 × 410 view box: leaves evenly spaced in preorder, each parent over the middle of its
/// children, a row per depth. The tree of fewer words numbers its vertices the same way, so it
/// is drawn in the same places.
let prefixSpots: [(x: Double, y: Double)] = {
    let full = prefixTree(of: wordList)
    let tree = full.arborescence
    let leaves = tree.preorder.filter { tree.children(of: $0).isEmpty }
    let gap = 600.0 / Double(max(leaves.count - 1, 1))
    var x = [Double](repeating: 0, count: tree.vertexCount)
    for (i, leaf) in leaves.enumerated() { x[leaf] = 40 + Double(i) * gap }
    for v in tree.preorder.reversed() where !tree.children(of: v).isEmpty {
        let children = tree.children(of: v)
        x[v] = children.map { x[$0] }.reduce(0, +) / Double(children.count)
    }
    return (0 ..< tree.vertexCount).map { (x[$0], 40 + Double(tree.depth(of: $0)) * 82) }
}()

@Reactive
final class PrefixTreeModel {
    var typed = "ca"
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-prefixtree")

    init() {
        playback.reset(count: wordList.count)
        playback.show(wordList.count)
    }

    func set(typed text: String) {
        typed = String(text.lowercased().prefix(8))
    }
}

let prefixTreeModel = PrefixTreeModel()

/// The prefix spelled by the path from the root to `v`.
func prefixText(_ tree: PrefixTree<Character>, _ v: Int) -> String {
    var letters: [Character] = []
    var at = v
    while let parent = tree.arborescence.parent(of: at) {
        letters.append(tree.symbol(ofEdgeAt: at - 1))
        at = parent
    }
    return String(letters.reversed())
}

func describeInsert(_ k: Int) -> String {
    let before = prefixTree(of: wordList.prefix(k - 1)), after = prefixTree(of: wordList.prefix(k))
    let word = wordList[k - 1]
    let added = after.arborescence.vertexCount - before.arborescence.vertexCount
    let shared = word.count - added
    let reuse = shared == 0 ? "None of it is in the tree yet" : "“\(word.prefix(shared))” is already in the tree"
    return "Add “\(word)”. \(reuse), so it takes \(added) new \(added == 1 ? "vertex" : "vertices"), and its last one is marked as a word."
}

@View
struct PrefixTreeLab {
    var body: some View {
        let model = prefixTreeModel
        let playback = model.playback
        let k = playback.k
        let answer = autocomplete(added: k, typed: model.typed)
        let tree = answer.tree
        let n = tree.arborescence.vertexCount
        let typedPath: Set<Int> = {
            var path = Set<Int>()
            guard var at = answer.node else { return path }
            path.insert(at)
            while let parent = tree.arborescence.parent(of: at) { path.insert(parent); at = parent }
            return path
        }()
        let below = Set(answer.node.map { at in tree.arborescence.preorder.filter { tree.arborescence.isAncestor(at, of: $0) } } ?? [])
        let newest = k > 0 ? Set((prefixTree(of: wordList.prefix(k - 1)).arborescence.vertexCount ..< n)) : []
        let nodes = (0 ..< n).map { v in
            CanvasNode(x: prefixSpots[v].x, y: prefixSpots[v].y, name: tree.isSequenceEnd(v) && v != 0 ? prefixText(tree, v) : "",
                       badge: v == 0 ? "·" : String(tree.symbol(ofEdgeAt: v - 1)), radius: 16,
                       classes: (typedPath.contains(v) && !model.typed.isEmpty ? "frontier" : below.contains(v) && !model.typed.isEmpty ? "pal2" : tree.isSequenceEnd(v) ? "visited" : "")
                           + (newest.contains(v) ? " current" : ""))
        }
        let edges = (1 ..< max(n, 1)).map { v in
            CanvasEdge(from: tree.arborescence.parent(of: v)!, to: v, directed: true,
                       classes: typedPath.contains(v) && !model.typed.isEmpty ? "active" : below.contains(v) && !model.typed.isEmpty ? "pal2" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The prefix tree")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The prefix tree of \(k) words: each vertex adds one letter to the prefix above it", width: 680, height: 410, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "a whole word ends here" }
                        span { i(.class("dot frontier")) {}; "the letters typed" }
                        span { i(.class("dot pal2")) {}; "everything that can follow" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel")) {
                        label(.class("field"), .for("prefixtree-typed")) {
                            span(.class("label")) { "Type the start of a word" }
                            input(.id("prefixtree-typed"), .type(.text), .value(model.typed), .custom(name: "maxlength", value: "8"),
                                  .custom(name: "spellcheck", value: "false"), .custom(name: "autocomplete", value: "off"))
                                .onInput { event in prefixTreeModel.set(typed: event.targetValue ?? "") }
                        }
                        span(.class("label")) { "Suggestions" }
                        div(.class("chips")) {
                            if answer.suggestions.isEmpty {
                                p(.class("empty")) { answer.node == nil ? "No word starts with “\(model.typed)”" : "None yet" }
                            }
                            for word in answer.suggestions { span(.class("chip")) { word } }
                        }
                    }
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == wordList.count ? "All \(wordList.count) words" : "\(k) of \(wordList.count) words" }
                        p(.class("narration")) {
                            if k == 0 {
                                "An empty tree: just the root, the empty prefix. Press Step to add the words one at a time."
                            } else {
                                describeInsert(k)
                                " The tree has \(n) vertices for \(wordList.prefix(k).reduce(0) { $0 + $1.count }) letters."
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
                    marbles: (1 ... wordList.count).map { j in
                        Marble(kind: "m-blue", radius: 11, letter: String(wordList[j - 1].prefix(1)), title: describeInsert(j))
                    },
                    legend: [(Marble(kind: "m-blue", radius: 6), "a word added")])
                p(.class("note")) { "Each step is prefixTree(of:) on one more word. Suggestions come from the tree as it stands, so type while stepping to see them appear." }
            }
        }
    }
}

@View
struct PrefixTreeCodePanel {
    var body: some View {
        let model = prefixTreeModel
        let k = model.playback.k
        let answer = autocomplete(added: k, typed: model.typed)
        CodePanel(
            snippets: [
                .prefixtreeImports,
                Snippet(lines: ["let words = [" + wordList.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let added = \(k)", "let typed = \"\(model.typed)\""]),
                .prefixtreeBuild, .prefixtreeComplete,
            ],
            results: ["[" + answer.suggestions.map { "\"\($0)\"" }.joined(separator: ", ") + "]"])
    }
}

enum PrefixTreePage {
    static func mount() {
        mountView(PrefixTreeLab(), in: "app")
        mountView(PrefixTreeCodePanel(), in: "code")
    }
}
