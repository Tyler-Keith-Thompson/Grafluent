import AdjacencyListModule
import ElementaryUI
import GraphDrawing
import GraphProtocols
import Reactivity

let richPeople = 30, richLinks = 2

/// Each vertex's place in the 680 × 400 view box, from `drawing` scaled to fit, rounded.
func richSpots(_ drawing: Drawing<Int>) -> [(x: Double, y: Double)] {
    guard let box = drawing.boundingBox else { return [] }
    let span = SIMD2(max(box.max.x - box.min.x, 1e-9), max(box.max.y - box.min.y, 1e-9))
    var spots = [(x: Double, y: Double)](repeating: (0, 0), count: richPeople)
    for (v, p) in zip(drawing.vertices, drawing.positions) {
        spots[v] = ((40 + (p.x - box.min.x) / span.x * 600).rounded(), (36 + (p.y - box.min.y) / span.y * 328).rounded())
    }
    return spots
}

@Reactive
final class RichModel {
    var seed: UInt64 = 7
    var network = UndirectedAdjacencyList<Int>()
    var spots: [(x: Double, y: Double)] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 500, scrubID: "scrub-rich")

    init() {
        run()
    }

    func run() {
        let made = richGetRicher(people: richPeople, links: richLinks, seed: seed)
        network = made.network
        spots = richSpots(made.drawing)
        playback.reset(count: richPeople - richLinks - 1)
        playback.show(playback.count)
    }

    /// The vertices present after `k` newcomers: the starting star and the first `k` after it.
    func present(_ k: Int) -> Int { richLinks + 1 + k }

    /// Each present vertex's degree counting only links among present vertices.
    func degrees(_ k: Int) -> [Int] {
        let n = present(k)
        var d = [Int](repeating: 0, count: n)
        for e in network.edges where e.u < n && e.v < n { d[e.u] += 1; d[e.v] += 1 }
        return d
    }
}

let richModel = RichModel()

func describeNewcomer(_ k: Int, _ model: RichModel) -> String {
    let v = model.present(k) - 1
    let before = model.degrees(k - 1)
    let targets = model.network.edges.filter { ($0.u == v && $0.v < v) || ($0.v == v && $0.u < v) }.map { $0.u == v ? $0.v : $0.u }.sorted()
    let total = before.reduce(0, +)
    let odds = targets.map { "\($0) (\(before[$0]) of \(total) link ends)" }.joined(separator: " and ")
    return "Newcomer \(v) links to \(odds). Each pick is in proportion to how many links a vertex already has."
}

@View
struct RichLab {
    var body: some View {
        let model = richModel
        let playback = model.playback
        let k = playback.k
        let n = model.present(k)
        let degrees = model.degrees(k)
        let top = degrees.max() ?? 1
        let newest = k > 0 ? n - 1 : -1
        let nodes = model.spots.indices.map { v in
            CanvasNode(x: model.spots[v].x, y: model.spots[v].y, name: "", badge: v < n && degrees[v] >= 6 ? "\(degrees[v])" : "",
                       radius: v < n ? 5 + 2.2 * Double(degrees[v]) : 5,
                       classes: v >= n ? "hidden" : v == newest ? "frontier" : degrees[v] == top ? "visited current" : "visited")
        }
        let edges = model.network.edges.compactMap { e -> CanvasEdge? in
            guard e.u < n && e.v < n else { return nil }
            return CanvasEdge(from: e.u, to: e.v, classes: e.u == newest || e.v == newest ? "active" : "")
        }
        let histogram = (0 ... top).map { d in degrees.filter { $0 == d }.count }
        let rows = (richLinks ... max(top, richLinks)).filter { histogram.indices.contains($0) && histogram[$0] > 0 }
        let most = histogram.max() ?? 1

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A growing network")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A Barabási–Albert network of \(n) vertices, each drawn bigger the more links it has", width: 680, height: 400, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "the newcomer" }
                        span { i(.class("line active")) {}; "its links" }
                        span { "size: number of links" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "\(n) of \(richPeople) vertices" }
                        p(.class("narration")) {
                            if k == 0 {
                                "A star of \(richLinks + 1) to start. Each newcomer makes \(richLinks) links, choosing whom to link to in proportion to how many links they already have. Press Step."
                            } else {
                                describeNewcomer(k, model)
                                if k == playback.count {
                                    " The early vertices have become hubs: the most linked has \(top) links, while most have only \(richLinks) or \(richLinks + 1)."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "How many vertices have each degree" }
                        div(.class("bars")) {
                            for d in rows {
                                div(.class(d == top ? "bar top" : "bar")) {
                                    span { "\(d) links" }
                                    span(.class("track")) {
                                        span(.class("fill"), .style("width: \(histogram[d] * 100 / most)%; display: block;")) {}
                                    }
                                    span(.class("num")) { "\(histogram[d])" }
                                }
                            }
                        }
                        p(.class("note")) { "Many with few links, a few with many: a long tail, unlike a network whose links are placed at random." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    button(.type(.button)) { "New draw" }
                        .onClick {
                            richModel.seed += 1
                            richModel.run()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ... playback.count).map { j in Marble(kind: "m-blue", radius: 7, title: describeNewcomer(j, model)) },
                    legend: [(Marble(kind: "m-blue", radius: 6), "a newcomer joins")])
                p(.class("note")) { "The network is drawn once, whole, by fruchtermanReingoldLayout; each step shows one more of its vertices, in the order barabasiAlbert added them." }
            }
        }
    }
}

@View
struct RichCodePanel {
    var body: some View {
        let model = richModel
        CodePanel(
            snippets: [
                .networkmodelsImports,
                Snippet(lines: ["let people = \(richPeople)", "let links = \(richLinks)", "let seed: UInt64 = \(model.seed)"]),
                .networkmodelsBarabasi,
            ],
            results: ["\(model.network.vertices.map { model.network.degree(of: $0) }.max() ?? 0)"])
    }
}

let smallPeople = 60, smallNeighbors = 4
let smallProbabilities: [Double] = [0, 0.02, 0.05, 0.1, 0.2, 0.5, 1]

/// Sixty places evenly round a circle in the 640 × 430 view box.
let smallSpots: [(x: Double, y: Double)] = [
    (320, 30), (339, 31), (358, 34), (377, 39), (395, 46), (412, 55), (429, 65), (444, 78), (457, 91), (470, 106),
    (480, 122), (489, 140), (496, 158), (501, 177), (504, 196), (505, 215), (504, 234), (501, 253), (496, 272), (489, 290),
    (480, 308), (470, 324), (457, 339), (444, 352), (429, 365), (412, 375), (395, 384), (377, 391), (358, 396), (339, 399),
    (320, 400), (301, 399), (282, 396), (263, 391), (245, 384), (228, 375), (211, 365), (196, 352), (183, 339), (170, 324),
    (160, 308), (151, 290), (144, 272), (139, 253), (136, 234), (135, 215), (136, 196), (139, 177), (144, 158), (151, 140),
    (160, 122), (170, 106), (183, 91), (196, 78), (211, 65), (228, 55), (245, 46), (263, 39), (282, 34), (301, 31),
]

@Reactive
final class SmallWorldModel {
    var seed: UInt64 = 3
    var worlds: [(network: UndirectedAdjacencyList<Int>, clustering: Double, separation: Double)] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1300, scrubID: "scrub-smallworld")

    init() {
        run()
    }

    func run() {
        worlds = smallProbabilities.map { smallWorld(people: smallPeople, neighbors: smallNeighbors, p: $0, seed: seed) }
        playback.reset(count: smallProbabilities.count - 1)
    }
}

let smallWorldModel = SmallWorldModel()

/// `0.05` as `5%`.
func percent(_ p: Double) -> String { "\(Int((p * 100).rounded()))%" }

func describeWorld(_ k: Int, _ model: SmallWorldModel) -> String {
    let w = model.worlds[k], ring = model.worlds[0]
    if k == 0 {
        return "A ring: everyone knows the \(smallNeighbors) nearest. Friends of friends are mostly friends (clustering \(signedTwoPlaces(w.clustering))), but crossing the ring takes \(signedTwoPlaces(w.separation)) steps on average."
    }
    let c = Int((w.clustering / ring.clustering * 100).rounded()), l = Int((w.separation / ring.separation * 100).rounded())
    return "Rewire each link with probability \(percent(smallProbabilities[k])). Clustering keeps \(c)% of the ring’s; the average distance drops to \(l)% of it."
}

@View
struct SmallWorldLab {
    var body: some View {
        let model = smallWorldModel
        let playback = model.playback
        let k = playback.k
        let world = model.worlds[k]
        let ring = model.worlds[0].network
        let nodes = smallSpots.indices.map { v in CanvasNode(x: smallSpots[v].x, y: smallSpots[v].y, name: "", radius: 6, classes: "visited") }
        let edges = world.network.edges.map { e in
            CanvasEdge(from: e.u, to: e.v, classes: ring.contains(edge: e) ? "" : "route")
        }
        let base = model.worlds[0]

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A small world")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A Watts–Strogatz ring of \(smallPeople), rewired with probability \(percent(smallProbabilities[k]))", width: 640, height: 430, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line")) {}; "a link of the ring" }
                        span { i(.class("line route")) {}; "a rewired shortcut" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "Rewiring \(percent(smallProbabilities[k]))" }
                        p(.class("narration")) { describeWorld(k, model) }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Against the ring" }
                        div(.class("queue")) {
                            div(.class("qrow plain")) {
                                span { "rewired" }
                                span(.class("num")) { "clustering · distance" }
                            }
                            for j in 0 ... k {
                                div(.class(j == k ? "qrow top" : "qrow")) {
                                    span { percent(smallProbabilities[j]) }
                                    span(.class("num")) { "\(Int((model.worlds[j].clustering / base.clustering * 100).rounded()))% · \(Int((model.worlds[j].separation / base.separation * 100).rounded()))%" }
                                }
                            }
                        }
                        p(.class("note")) { "A few rewired links make distances short long before the clustering goes: a small world, close-knit and yet only a few steps across." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    button(.type(.button)) { "New draw" }
                        .onClick {
                            smallWorldModel.seed += 1
                            smallWorldModel.run()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ..< smallProbabilities.count).map { j in
                        Marble(kind: "m-violet", radius: 10, title: describeWorld(j, model))
                    },
                    legend: [(Marble(kind: "m-violet", radius: 6), "more rewiring, from the same seed")])
                p(.class("note")) { "Each step is a fresh wattsStrogatz call with a larger rewiring probability and the same seed." }
            }
        }
    }
}

@View
struct SmallWorldCodePanel {
    var body: some View {
        let model = smallWorldModel
        let k = model.playback.k
        let w = model.worlds[k]
        CodePanel(
            snippets: [
                .networkmodelsImports,
                Snippet(lines: ["let people = \(smallPeople)", "let neighbors = \(smallNeighbors)", "let p = \(smallProbabilities[k])", "let seed: UInt64 = \(model.seed)"]),
                .networkmodelsWatts,
            ],
            results: [signedTwoPlaces(w.clustering), signedTwoPlaces(w.separation)])
    }
}

enum NetworkModelsPage {
    static func mount() {
        mountView(RichLab(), in: "app")
        mountView(RichCodePanel(), in: "code")
        mountView(SmallWorldLab(), in: "smallworld")
        mountView(SmallWorldCodePanel(), in: "code-smallworld")
        mountView(NamesStrip(names: [Names.barabasiAlbert, Names.wattsStrogatz]), in: "names")
    }
}
