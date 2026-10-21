import AdjacencyListModule
import ElementaryUI
import GraphDrawing
import GraphFormats
import GraphProtocols
import Reactivity

/// An example in each format, the same small weighted network where the format allows it.
let pasteExamples: [PasteFormat: String] = [
    .dot: """
        graph town {
          Home -- Bakery [weight=4];
          Home -- Park [weight=6];
          Bakery -- Park [weight=3];
          Bakery -- School [weight=7];
          Park -- Library [weight=5];
          School -- Library [weight=4];
          School -- Cafe [weight=6];
          Library -- Cafe [weight=3];
          Cafe -- Station [weight=5];
          Pier -- Beach;
        }
        """,
    .graphML: """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml xmlns="http://graphml.graphdrawing.org/xmlns">
          <key id="w" for="edge" attr.name="weight" attr.type="int"/>
          <graph edgedefault="undirected">
            <node id="Home"/><node id="Bakery"/><node id="Park"/><node id="School"/>
            <edge source="Home" target="Bakery"><data key="w">4</data></edge>
            <edge source="Home" target="Park"><data key="w">6</data></edge>
            <edge source="Bakery" target="Park"><data key="w">3</data></edge>
            <edge source="Bakery" target="School"><data key="w">7</data></edge>
            <edge source="Park" target="School"><data key="w">5</data></edge>
          </graph>
        </graphml>
        """,
    .graph6: "IheA@GUAo",
    .edgeList: """
        # u v, then an optional dict of attributes
        Home Bakery {'weight': 4}
        Home Park {'weight': 6}
        Bakery Park {'weight': 3}
        Bakery School {'weight': 7}
        Park Library {'weight': 5}
        School Library
        Library Cafe {'weight': 3}
        """,
]

/// The most vertices the page draws.
let pasteVertexLimit = 200

/// What to run on the pasted graph.
enum PasteAlgorithm: Int, CaseIterable {
    case bfs, dijkstra, components

    var name: String {
        switch self {
        case .bfs: "Breadth-first search"
        case .dijkstra: "Dijkstra"
        case .components: "Connected components"
        }
    }
}

/// One marble of the run: a vertex reached, or an edge taken into the search tree.
enum PasteStep {
    case reach(vertex: String, distance: Int?, piece: Int)
    case take(edge: Int, piece: Int)
}

/// The paste page's state: the text, its format, what Grafluent read from it, the drawing, the
/// search and its playhead.
@Reactive
final class PasteModel {
    var format = PasteFormat.dot
    var text = pasteExamples[.dot]!
    var algorithm = PasteAlgorithm.bfs
    var start = ""
    var outcome: Result<(graph: PastedGraph, weights: [Int: Int]), ParseError> = .failure(ParseError(kind: .syntax, line: 1, column: 1, byteOffset: 0))
    var drawing: Drawing<String>?
    var steps: [PasteStep] = []
    var eventCount = 0
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 500, scrubID: "scrub-paste")

    init() { read() }

    var graph: PastedGraph? { if case .success(let g) = outcome { g.graph } else { nil } }

    /// Reads the text again, draws it and reruns the search.
    func read() {
        outcome = readPasted(text, as: format)
        drawing = nil
        if let g = graph, g.vertexCount > 0, g.vertexCount <= pasteVertexLimit {
            drawing = pastedDrawing(g.vertices, (0 ..< g.edgeCount).map { g.ends($0) })
            if !g.contains(start) { start = g.vertices.first! }
        }
        run()
    }

    /// Runs the chosen algorithm from the start and rewinds.
    func run() {
        steps = []
        eventCount = 0
        if let g = graph, drawing != nil, case .success(let read) = outcome {
            switch algorithm {
            case .bfs:
                let events = pastedBreadthFirst(g, from: start)
                eventCount = events.count
                for event in events {
                    switch event {
                    case .discover(let v): steps.append(.reach(vertex: v, distance: nil, piece: 0))
                    case .treeEdge(let e): steps.append(.take(edge: e, piece: 0))
                    default: break
                    }
                }
            case .dijkstra:
                let (count, kept) = pastedDijkstra(g, weights: read.weights, from: start)
                eventCount = count
                for event in kept {
                    switch event {
                    case .examine(let v, let d): steps.append(.reach(vertex: v, distance: d, piece: 0))
                    case .relaxed(let e): steps.append(.take(edge: e, piece: 0))
                    }
                }
            case .components:
                let (pieces, events) = pastedComponents(g)
                eventCount = events.count
                let pieceOf: [String: Int] = Dictionary(uniqueKeysWithValues: pieces.enumerated().flatMap { n, names in names.map { ($0, n) } })
                for event in events {
                    switch event {
                    case .discover(let v): steps.append(.reach(vertex: v, distance: nil, piece: pieceOf[v]!))
                    case .treeEdge(let e): steps.append(.take(edge: e, piece: pieceOf[g.ends(e).0]!))
                    default: break
                    }
                }
            }
        }
        playback.reset(count: steps.count)
    }

    func choose(format: Int) {
        self.format = PasteFormat(rawValue: format)!
        text = pasteExamples[self.format]!
        setProperty(id: "paste-text", "value", to: text)
        setProperty(id: "paste-format", "value", to: "\(format)")
        read()
    }

    func choose(algorithm: Int) {
        self.algorithm = PasteAlgorithm(rawValue: algorithm)!
        setProperty(id: "paste-algorithm", "value", to: "\(algorithm)")
        run()
    }
}

let pasteModel = PasteModel()

/// The `ParseError` kind in words.
func parseErrorText(_ kind: ParseError.Kind) -> String {
    switch kind {
    case .syntax: "Something here isn’t allowed by the format."
    case .unexpectedEndOfInput: "The text ends in the middle of something."
    case .kindMismatch: "The text says one kind of graph and its edges say another."
    case .invalidUTF8: "The text isn’t valid UTF-8."
    case .undeclaredVertex: "An edge names a node that was never declared."
    case .duplicateVertex: "A node is declared twice."
    case .invalidValue: "A value the format doesn’t allow."
    default: "\(kind)"
    }
}

/// The format chooser and the text box. Its body reads no state, so typing never redraws it.
@View
struct PasteInput {
    var body: some View {
        section(.class("panel controls"), .custom(name: "aria-label", value: "Your graph")) {
            div(.class("buttons")) {
                label(.class("field"), .for("paste-format")) {
                    "Format "
                    select(.id("paste-format")) {
                        for format in PasteFormat.allCases {
                            option(.value("\(format.rawValue)")) { format.name }.attributes(.selected, when: format == .dot)
                        }
                    }
                    .onInput { event in
                        if let value = event.targetValue, let n = Int(value) { pasteModel.choose(format: n) }
                    }
                }
            }
            textarea(.id("paste-text"), .class("paste-text"), .custom(name: "rows", value: "12"), .custom(name: "spellcheck", value: "false"),
                     .custom(name: "aria-label", value: "The graph, as text")) { pasteExamples[.dot]! }
                .onInput { event in
                    if let value = event.targetValue {
                        pasteModel.text = value
                        pasteModel.read()
                    }
                }
        }
    }
}

/// The pasted graph drawn, with the search on it.
@View
struct PasteLab {
    var body: some View {
        let model = pasteModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let shown = Array(steps.prefix(k))
        let last = shown.last
        div {
            switch model.outcome {
            case .failure(let error):
                section(.class("panel paste-error"), .custom(name: "aria-live", value: "polite")) {
                    span(.class("label")) { "Line \(error.line), column \(error.column): \(error.kind)" }
                    p(.class("narration")) { parseErrorText(error.kind) }
                    pre(.class("paste-line")) {
                        let lines = model.text.split(separator: "\n", omittingEmptySubsequences: false)
                        let line = error.line - 1 < lines.count ? String(lines[error.line - 1]) : ""
                        line + "\n" + String(repeating: " ", count: max(0, error.column - 1)) + "^"
                    }
                }
            case .success(let read):
                if read.graph.vertexCount == 0 {
                    section(.class("panel")) { p(.class("narration")) { "The text reads fine, but it has no vertices to draw." } }
                } else if let drawing = model.drawing {
                    let names = read.graph.vertices
                    let arrow = read.graph.isDirected ? "→" : "–"
                    let index: [String: Int] = Dictionary(uniqueKeysWithValues: names.enumerated().map { ($0.element, $0.offset) })
                    let placed = names.map { drawing.positions[drawing.vertices.firstIndex(of: $0)!] }
                    let xs = placed.map(\.x), ys = placed.map(\.y)
                    let (minX, maxX, minY, maxY) = (xs.min()!, xs.max()!, ys.min()!, ys.max()!)
                    let spot = { (v: String) -> (Double, Double) in
                        let p = drawing.positions[drawing.vertices.firstIndex(of: v)!]
                        let x = maxX - minX < 1e-9 ? 320 : 40 + (p.x - minX) / (maxX - minX) * 560
                        let y = maxY - minY < 1e-9 ? 220 : 40 + (p.y - minY) / (maxY - minY) * 360
                        return ((x * 10).rounded() / 10, (y * 10).rounded() / 10)
                    }
                    let reached: [String: (distance: Int?, piece: Int)] = Dictionary(shown.compactMap { if case .reach(let v, let d, let n) = $0 { (v, (d, n)) } else { nil } }, uniquingKeysWith: { a, _ in a })
                    let taken: [Int: Int] = Dictionary(shown.compactMap { if case .take(let e, let n) = $0 { (e, n) } else { nil } }, uniquingKeysWith: { a, _ in a })
                    let components = model.algorithm == .components
                    let small = names.count > 30
                    let nodes = names.map { v in
                        let (x, y) = spot(v)
                        let state = reached[v]
                        let cls = components ? state.map { "pal\($0.piece % 8)" } ?? "" : state == nil ? "" : "visited"
                        let isLast: Bool = { if case .reach(let u, _, _)? = last { return u == v } else { return false } }()
                        return CanvasNode(x: x, y: y, name: small ? "" : v, badge: state?.distance.map { "\($0)" } ?? "", radius: small ? 7 : 14,
                                          classes: cls + (v == model.start && !components ? " source" : "") + (isLast ? " current" : ""))
                    }
                    let edges = (0 ..< read.graph.edgeCount).map { p in
                        let (u, v) = read.graph.ends(p)
                        let isLast: Bool = { if case .take(let f, _)? = last { return f == p } else { return false } }()
                        return CanvasEdge(from: index[u]!, to: index[v]!, directed: read.graph.isDirected, label: read.weights[p].map { "\($0)" } ?? "",
                                          classes: isLast ? "active" : taken[p].map { components ? "pal\($0 % 8)" : "tree" } ?? "")
                    }
                    section(.class("lab"), .custom(name: "aria-label", value: "The pasted graph")) {
                        div(.class("panel stage")) {
                            GraphCanvas(label: "The pasted \(read.graph.isDirected ? "directed " : "")graph, \(names.count) vertices and \(read.graph.edgeCount) edges, drawn by Fruchterman–Reingold",
                                        width: 640, height: 440, nodes: nodes, edges: edges,
                                        onNode: { i in
                                            if let g = pasteModel.graph { pasteModel.start = g.vertices[i]; pasteModel.run() }
                                        }, nodeAction: "Start from")
                            p(.class("note")) { components ? "Same colour, same component." : "Click a vertex to start from it. Numbers on edges are their weight attributes; edges without one weigh 1." }
                        }
                        div(.class("side")) {
                            div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                                span(.class("label")) { "\(names.count) vertices · \(read.graph.edgeCount) \(read.graph.isDirected ? "arcs" : "edges")" }
                                p(.class("narration")) {
                                    switch last {
                                    case nil:
                                        k == 0 && !steps.isEmpty ? "Read as \(model.format.name). Press Step to run \(model.algorithm.name.lowercased())" + (components ? "." : " from \(model.start).") : "Nothing to run."
                                    case .reach(let v, let d, let n)?:
                                        components ? "Reach \(v), in component \(n + 1)." : d.map { "Settle \(v) at distance \($0)." } ?? "Reach \(v)."
                                    case .take(let e, _)?:
                                        "Take \(read.graph.ends(e).0)\(arrow)\(read.graph.ends(e).1) into the search tree."
                                    }
                                }
                                label(.class("field"), .for("paste-algorithm")) {
                                    "Run "
                                    select(.id("paste-algorithm")) {
                                        for algorithm in PasteAlgorithm.allCases {
                                            option(.value("\(algorithm.rawValue)")) { algorithm.name }.attributes(.selected, when: algorithm == model.algorithm)
                                        }
                                    }
                                    .onInput { event in
                                        if let value = event.targetValue, let n = Int(value) { pasteModel.choose(algorithm: n) }
                                    }
                                }
                            }
                        }
                    }
                    section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                        div(.class("buttons")) { PlaybackButtons(playback: playback) }
                        Timeline(
                            playback: playback,
                            marbles: steps.map { step in
                                switch step {
                                case .reach(let v, let d, let n):
                                    return Marble(kind: components ? "m-pal\(n % 8)" : "m-blue", radius: 8, letter: d.map { "\($0)" } ?? "", title: "Reach \(v)")
                                case .take(let e, let n):
                                    return Marble(kind: components ? "m-pal\(n % 8)" : "m-blue", radius: 3.5, title: "Take \(read.graph.ends(e).0)\(read.graph.isDirected ? "→" : "–")\(read.graph.ends(e).1)")
                                }
                            },
                            legend: [(Marble(kind: "m-blue", radius: 6), model.algorithm == .dijkstra ? "a vertex settled, with its distance" : "a vertex reached"), (Marble(kind: "m-blue", radius: 3.5), "an edge into the tree")])
                        p(.class("note")) { "The marbles are the moments each vertex is first reached and each edge joins the search tree, from lazy.edgeBreadthFirstSearch(from:), or each edge is examined and each distance improved, from lazy.dijkstra(from:weight:). The other events are left off." }
                    }
                } else {
                    section(.class("panel")) { p(.class("narration")) { "The text has \(read.graph.vertexCount) vertices and \(read.graph.edgeCount) edges. This page draws at most \(pasteVertexLimit) vertices." } }
                }
            }
        }
    }
}

/// The code panel: the reader for the format, the drawing and the algorithm.
@View
struct PasteCodePanel {
    var body: some View {
        let model = pasteModel
        let directed = model.graph?.isDirected == true
        let read: Snippet = switch (model.format, directed) {
        case (.dot, false): .pasteReadDot
        case (.dot, true): .pasteReadDigraph
        case (.graphML, false): .pasteReadGraphml
        case (.graphML, true): .pasteReadGraphmlDirected
        case (.graph6, false): .pasteReadGraph6
        case (.graph6, true): .pasteReadDigraph6
        case (.edgeList, _): .pasteReadEdgelist
        }
        let shown = model.text.count > 60 ? String(model.text.prefix(57)) + "…" : model.text
        let binding = Snippet(lines: ["let text = \"" + shown.replacingNewlines() + "\""] + (model.algorithm == .components ? [] : ["let start = \"\(model.start)\""]))
        let algorithm: Snippet = [.pasteBfs, .pasteDijkstra, directed ? .pasteWeakComponents : .pasteComponents][model.algorithm.rawValue]
        let result: String = {
            switch model.outcome {
            case .failure(let error): return "throws \(error)"
            case .success(let read):
                if model.algorithm == .components, model.drawing != nil { return "\(pastedComponents(read.graph).pieces.count) components" }
                return "\(model.eventCount) events"
            }
        }()
        CodePanel(snippets: [.pasteImports, binding, read, .pasteLayout, algorithm], results: [result])
    }
}

extension String {
    /// The text with each line break written as `\n`, for a one-line string literal.
    func replacingNewlines() -> String {
        var out = ""
        for c in self {
            switch c {
            case "\n": out += "\\n"
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            default: out.append(c)
            }
        }
        return out
    }
}

enum PastePage {
    static func mount() {
        mountView(PasteInput(), in: "input")
        mountView(PasteLab(), in: "app")
        mountView(PasteCodePanel(), in: "code")
    }
}
