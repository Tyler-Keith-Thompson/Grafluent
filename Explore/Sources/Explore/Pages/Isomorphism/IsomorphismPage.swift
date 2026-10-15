import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import IsomorphismModule
import Reactivity

/// Two drawings to compare: each vertex and where it is drawn in the 880 × 400 view box (the
/// first drawing in x < 440, the second beyond), and the edges of each.
struct DrawingPair {
    var title: String
    var first: [(name: String, x: Double, y: Double)]
    var second: [(name: String, x: Double, y: Double)]
    var firstEdges: [UndirectedEdge<String>]
    var secondEdges: [UndirectedEdge<String>]
}

func edgeList(_ pairs: [(String, String)]) -> [UndirectedEdge<String>] { pairs.map { UndirectedEdge($0.0, $0.1) } }

let drawingPairs: [DrawingPair] = [
    DrawingPair(
        title: "Two cubes",
        first: [("A", 60, 50), ("B", 380, 50), ("C", 380, 350), ("D", 60, 350), ("E", 150, 140), ("F", 290, 140), ("G", 290, 260), ("H", 150, 260)],
        second: [("1", 660, 40), ("2", 773, 87), ("3", 820, 200), ("4", 773, 313), ("5", 660, 360), ("6", 547, 313), ("7", 500, 200), ("8", 547, 87)],
        firstEdges: edgeList([("A", "B"), ("B", "C"), ("C", "D"), ("D", "A"), ("E", "F"), ("F", "G"), ("G", "H"), ("H", "E"), ("A", "E"), ("B", "F"), ("C", "G"), ("D", "H")]),
        secondEdges: edgeList([("1", "2"), ("2", "3"), ("3", "4"), ("4", "5"), ("5", "6"), ("6", "7"), ("7", "8"), ("8", "1"), ("1", "4"), ("2", "7"), ("3", "6"), ("5", "8")])),
    DrawingPair(
        title: "Look-alikes",
        first: [("A", 100, 70), ("B", 100, 200), ("C", 100, 330), ("D", 340, 70), ("E", 340, 200), ("F", 340, 330)],
        second: [("1", 660, 40), ("2", 820, 340), ("3", 500, 340), ("4", 660, 170), ("5", 725, 270), ("6", 595, 270)],
        firstEdges: edgeList(["A", "B", "C"].flatMap { u in ["D", "E", "F"].map { (u, $0) } }),
        secondEdges: edgeList([("1", "2"), ("2", "3"), ("3", "1"), ("4", "5"), ("5", "6"), ("6", "4"), ("1", "4"), ("2", "5"), ("3", "6")])),
    DrawingPair(
        title: "Two trees",
        first: [("A", 60, 150), ("B", 120, 150), ("C", 180, 150), ("D", 240, 150), ("E", 300, 150), ("F", 360, 150), ("G", 120, 280)],
        second: [("1", 520, 150), ("2", 580, 150), ("3", 640, 150), ("4", 700, 150), ("5", 760, 150), ("6", 820, 150), ("7", 640, 280)],
        firstEdges: edgeList([("A", "B"), ("B", "C"), ("C", "D"), ("D", "E"), ("E", "F"), ("B", "G")]),
        secondEdges: edgeList([("1", "2"), ("2", "3"), ("3", "4"), ("4", "5"), ("5", "6"), ("3", "7")])),
]

@Reactive
final class IsomorphismModel {
    var pair = 0
    var sameHash = false
    var firstColours: [String: [Int]] = [:]
    var secondColours: [String: [Int]] = [:]
    var mapping: [String: String]?
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1300, scrubID: "scrub-isomorphism")

    init() {
        choose(0)
    }

    var current: DrawingPair { drawingPairs[pair] }

    func choose(_ n: Int) {
        pair = n
        (sameHash, firstColours, secondColours, mapping) = compareDrawings(current.firstEdges, current.secondEdges)
        playback.reset(count: 4)
    }

    /// Each vertex's colour class after `round` rounds, numbered by first appearance across the
    /// first drawing then the second; every vertex is class 0 before the first round.
    func classes(after round: Int) -> (first: [String: Int], second: [String: Int]) {
        var number: [Int: Int] = [:]
        func colour(_ hashes: [Int]) -> Int {
            guard round > 0 else { return 0 }
            let h = hashes[round - 1]
            if let n = number[h] { return n }
            number[h] = number.count
            return number.count - 1
        }
        var a: [String: Int] = [:], b: [String: Int] = [:]
        for v in current.first { a[v.name] = colour(firstColours[v.name]!) }
        for v in current.second { b[v.name] = colour(secondColours[v.name]!) }
        return (a, b)
    }

    /// The number of vertices of each colour, in colour order.
    func counts(_ classes: [String: Int], _ spots: [(name: String, x: Double, y: Double)]) -> [Int] {
        let top = (classes.values.max() ?? 0) + 1
        var counts = [Int](repeating: 0, count: top)
        for v in spots { counts[classes[v.name]!] += 1 }
        return counts
    }

    /// Whether the two drawings have the same number of vertices of each colour after `round`.
    func colourCountsAgree(after round: Int) -> Bool {
        let (a, b) = classes(after: round)
        let top = max((a.values.max() ?? 0), (b.values.max() ?? 0)) + 1
        var ca = [Int](repeating: 0, count: top), cb = ca
        for v in current.first { ca[a[v.name]!] += 1 }
        for v in current.second { cb[b[v.name]!] += 1 }
        return ca == cb
    }
}

let isomorphismModel = IsomorphismModel()

func describeIsoStep(_ k: Int, _ model: IsomorphismModel) -> String {
    if k == 4 {
        guard let mapping = model.mapping else {
            return model.sameHash
                ? "The search tries every way to match the vertices and finds none that keeps every edge. The colours couldn’t tell them apart, but these are different graphs."
                : "No mapping exists, as the colours already showed."
        }
        let some = model.current.first.prefix(3).map { "\($0.name) → \(mapping[$0.name]!)" }.joined(separator: ", ")
        return "The search finds a mapping that keeps every edge: \(some), and so on. Matching colours mark each vertex and its image. Same graph, two drawings."
    }
    let agree = model.colourCountsAgree(after: k)
    let what = k == 1 ? "Round 1: colour every vertex by how many neighbours it has." : "Round \(k): colour every vertex by its colour and the colours of its neighbours."
    return what + (agree
        ? " Both drawings have the same number of vertices of each colour, so they might be the same graph."
        : " The counts differ between the drawings, so they are certainly different graphs.")
}

@View
struct IsomorphismLab {
    var body: some View {
        let model = isomorphismModel
        let pair = model.current
        let playback = model.playback
        let k = playback.k
        let finished = k == 4
        let round = min(k, 3)
        let (a, b) = model.classes(after: round)
        let mapping = finished ? model.mapping : nil
        let order = Dictionary(uniqueKeysWithValues: pair.first.enumerated().map { ($0.element.name, $0.offset) })
        let preimage = Dictionary(uniqueKeysWithValues: (mapping ?? [:]).map { ($0.value, $0.key) })
        let spots = pair.first + pair.second
        let index = Dictionary(uniqueKeysWithValues: spots.enumerated().map { ($0.element.name, $0.offset) })
        let nodes = spots.map { spot -> CanvasNode in
            let colour: Int
            if mapping != nil {
                colour = order[preimage[spot.name] ?? spot.name]!
            } else {
                colour = a[spot.name] ?? b[spot.name]!
            }
            let badge = mapping != nil && preimage[spot.name] != nil ? "\(spot.name)" : spot.name
            return CanvasNode(x: spot.x, y: spot.y, name: mapping != nil && preimage[spot.name] != nil ? "= \(preimage[spot.name]!)" : "", badge: badge, radius: 17,
                              classes: k == 0 ? "" : "pal\(colour % 8)")
        }
        let edges = (pair.firstEdges + pair.secondEdges).map { CanvasEdge(from: index[$0.u]!, to: index[$0.v]!) }
        let agree = model.colourCountsAgree(after: round)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Two drawings")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "\(pair.title): the first drawing with lettered vertices, the second with numbered ones", width: 880, height: 400, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { "Lettered: the first drawing. Numbered: the second." }
                        span { i(.class("dot pal1")) {}; finished && model.mapping != nil ? "a vertex and its image share a colour" : "a colour class" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "The answer" : k == 0 ? "3 rounds, then a search" : "Round \(k) of 3" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Are these two drawings of the same graph: can the numbers be matched to the letters so that every line still joins the same pairs? First a quick test, colour refinement, then a full search. Press Step."
                            } else {
                                describeIsoStep(k, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Weisfeiler–Leman" }
                        div(.class("stat")) {
                            div(.class(round == 0 || agree ? "good" : "bad")) {
                                span(.class("num")) { round == 0 ? "–" : agree ? "same" : "differ" }
                                "colour counts"
                            }
                            div(.class(model.sameHash ? "good" : "bad")) {
                                span(.class("num")) { model.sameHash ? "equal" : "differ" }
                                "graph hashes"
                            }
                        }
                        if finished {
                            div(.class("chips")) {
                                if let mapping = model.mapping {
                                    for v in pair.first {
                                        span(.class("chip pal\(order[v.name]! % 8)")) { "\(v.name) → \(mapping[v.name]!)" }
                                    }
                                } else {
                                    span(.class("chip bad")) { "isomorphism(to:) is nil" }
                                }
                            }
                        }
                        p(.class("note")) { "Equal hashes mean the drawings might be the same graph; different hashes mean they certainly aren’t. Only the search settles it." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Pair")) {
                        button(.type(.button), .class(model.pair == 0 ? "on" : "")) { drawingPairs[0].title }
                            .onClick { isomorphismModel.choose(0) }
                        button(.type(.button), .class(model.pair == 1 ? "on" : "")) { drawingPairs[1].title }
                            .onClick { isomorphismModel.choose(1) }
                        button(.type(.button), .class(model.pair == 2 ? "on" : "")) { drawingPairs[2].title }
                            .onClick { isomorphismModel.choose(2) }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ... 4).map { j in
                        let title = describeIsoStep(j, model)
                        if j == 4 { return Marble(kind: model.mapping == nil ? "m-red" : "m-green", radius: 11, letter: model.mapping == nil ? "≠" : "=", title: title) }
                        return Marble(kind: model.colourCountsAgree(after: j) ? "m-violet" : "m-red", radius: 9, letter: "\(j)", title: title)
                    },
                    legend: [
                        (Marble(kind: "m-violet", radius: 6), "a round of colours, counts alike"),
                        (Marble(kind: "m-red", radius: 6), "counts differ, or no mapping"),
                        (Marble(kind: "m-green", radius: 6), "a mapping found"),
                    ])
                p(.class("note")) { "Each round shows the colours from weisfeilerLehmanSubgraphHashes(iterations: 3); the last step is isomorphism(to:)." }
            }
        }
    }
}

@View
struct IsomorphismCodePanel {
    var body: some View {
        let model = isomorphismModel
        let pair = model.current
        let mapping = model.mapping.map { m in pair.first.map { "\($0.name) ↦ \(m[$0.name]!)" }.joined(separator: ", ") }
        func list(_ name: String, _ edges: [UndirectedEdge<String>]) -> [String] {
            ["let \(name) = ["] + stride(from: 0, to: edges.count, by: 4).map { i in
                "    " + edges[i ..< min(i + 4, edges.count)].map { "UndirectedEdge(\"\($0.u)\", \"\($0.v)\")," }.joined(separator: " ")
            } + ["]"]
        }
        return CodePanel(
            snippets: [
                .isomorphismImports,
                Snippet(lines: list("firstEdges", pair.firstEdges) + list("secondEdges", pair.secondEdges)),
                .isomorphismCompare,
            ],
            results: ["\(model.sameHash)", mapping.map { "Isomorphism(\($0))" } ?? "nil"])
    }
}

enum IsomorphismPage {
    static func mount() {
        mountView(IsomorphismLab(), in: "app")
        mountView(IsomorphismCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.weisfeilerLeman]), in: "names")
    }
}
