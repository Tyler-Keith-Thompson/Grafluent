import AdjacencyListModule
import ElementaryUI
import GraphDrawing
import GraphProtocols
import Planarity
import Reactivity

/// One graph on the planarity page: its places, where it is first drawn in the 640 × 420 view
/// box, and its links in the order they are added.
struct PlanarityScenario {
    var title: String
    var link: String
    var spots: [(name: String, x: Double, y: Double)]
    var links: [UndirectedEdge<String>]

    func index(_ name: String) -> Int { spots.firstIndex { $0.name == name }! }
}

let planarityScenarios: [PlanarityScenario] = [
    PlanarityScenario(
        title: "Three utilities", link: "pipe",
        spots: [("House A", 130, 80), ("House B", 320, 80), ("House C", 510, 80), ("Water", 130, 340), ("Gas", 320, 340), ("Power", 510, 340)],
        links: ["House A", "House B", "House C"].flatMap { house in ["Water", "Gas", "Power"].map { UndirectedEdge(house, $0) } }),
    PlanarityScenario(
        title: "Five towns", link: "road",
        spots: [("Ash", 320, 50), ("Birch", 540, 190), ("Cedar", 455, 370), ("Dale", 185, 370), ("Elm", 100, 190)],
        links: [("Ash", "Birch"), ("Birch", "Cedar"), ("Cedar", "Dale"), ("Dale", "Elm"), ("Elm", "Ash"),
                ("Ash", "Cedar"), ("Ash", "Dale"), ("Birch", "Dale"), ("Birch", "Elm"), ("Cedar", "Elm")].map { UndirectedEdge($0.0, $0.1) }),
    PlanarityScenario(
        title: "A cube", link: "edge",
        spots: [("A", 150, 160), ("B", 380, 160), ("C", 380, 390), ("D", 150, 390), ("E", 270, 50), ("F", 500, 50), ("G", 500, 280), ("H", 270, 280)],
        links: [("A", "B"), ("B", "C"), ("C", "D"), ("D", "A"), ("E", "F"), ("F", "G"), ("G", "H"), ("H", "E"),
                ("A", "E"), ("B", "F"), ("C", "G"), ("D", "H")].map { UndirectedEdge($0.0, $0.1) }),
]

/// Grafluent's answers after some links.
struct PlanarityState {
    var planar: Bool
    var witness: KuratowskiSubgraph<UndirectedAdjacencyList<String>>?
    /// Where each place goes in the crossing-free drawing, in view-box units.
    var layout: [(x: Double, y: Double)]?
    var faces: Int?
    var witnessEdges: Set<UndirectedEdge<String>> = []
}

@Reactive
final class PlanarityModel {
    var scenario = 0
    /// Links taken out by a click, by offset in the scenario's links.
    var removed: Set<Int> = []
    var asDrawn = false
    var links: [UndirectedEdge<String>] = []
    /// `states[k]` is the answer after the first `k` links.
    var states: [PlanarityState] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-planarity")

    init() {
        choose(0)
    }

    var current: PlanarityScenario { planarityScenarios[scenario] }

    func choose(_ n: Int) {
        scenario = n
        removed = []
        run()
    }

    func toggle(link: UndirectedEdge<String>) {
        let i = current.links.firstIndex(of: link)!
        if removed.contains(i) { removed.remove(i) } else { removed.insert(i) }
        run()
        playback.show(links.count)
    }

    func restore() {
        removed = []
        run()
        playback.show(links.count)
    }

    /// Asks Grafluent about every prefix of the links, and rewinds.
    func run() {
        let s = current
        links = s.links.indices.filter { !removed.contains($0) }.map { s.links[$0] }
        let names = s.spots.map(\.name)
        states = (0 ... links.count).map { k in
            let answer = planarity(places: names, links: links, added: k)
            var state = PlanarityState(planar: answer.planar, witness: answer.witness, layout: nil, faces: answer.faces)
            if let drawing = answer.drawing {
                let n = Double(names.count)
                let width = max(2 * n - 4, 1), height = max(n - 2, 1)
                state.layout = names.map { name in
                    let p = drawing.position(of: name)
                    return (60 + p.x / width * 520, 380 - p.y / height * 320)
                }
            }
            if let witness = answer.witness {
                state.witnessEdges = Set(witness.edges.map { answer.graph.edges[$0] })
            }
            return state
        }
        playback.reset(count: links.count)
    }

    /// The first `k` at which the graph is not planar, if any.
    var breaking: Int? { states.firstIndex { !$0.planar } }
}

let planarityModel = PlanarityModel()

/// `K₃,₃` or `K₅`.
func kuratowskiName(_ kind: KuratowskiGraph) -> String { kind == .k5 ? "K₅" : "K₃,₃" }

func describePlanarity(_ k: Int, _ model: PlanarityModel) -> String {
    let s = model.current
    let link = model.links[k - 1]
    let state = model.states[k]
    let head = "\(s.link.prefix(1).uppercased() + s.link.dropFirst()) \(k) joins \(link.u) and \(link.v)."
    if state.planar {
        return head + " The graph is still planar, so planarLayout() redraws it with no crossings."
    }
    guard let witness = state.witness else { return head + " The graph is not planar." }
    if k == model.breaking {
        return head + " Now no drawing can avoid a crossing. The red lines are the proof, a \(kuratowskiName(witness.kind)) from findKuratowskiSubgraph()."
    }
    return head + " The graph is still not planar. Adding a link never makes it planar again."
}

@View
struct PlanarityLab {
    var body: some View {
        let model = planarityModel
        let s = model.current
        let playback = model.playback
        let k = playback.k
        let state = model.states[k]
        let finished = k == model.links.count
        let useLayout = state.planar && !model.asDrawn && state.layout != nil
        let branch = Set(state.witness?.branchVertices ?? [])
        let nodes = s.spots.enumerated().map { v, spot in
            let at = useLayout ? state.layout![v] : (x: spot.x, y: spot.y)
            return CanvasNode(x: at.x, y: at.y, name: spot.name, radius: 16,
                              classes: branch.contains(spot.name) ? "cut" : state.witness != nil ? "dim" : "", nameAbove: at.y < 110)
        }
        let edges = model.links.prefix(k).enumerated().map { i, link in
            CanvasEdge(from: s.index(link.u), to: s.index(link.v),
                       classes: (state.witnessEdges.contains(link) ? "route" : state.witness != nil ? "faint" : "tree") + (i == k - 1 ? " active" : ""))
        }
        let vertexCount = s.spots.count

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Can it be drawn without crossings?")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "\(s.title): \(k) \(s.link)s added, " + (state.planar ? "planar" : "not planar"), width: 640, height: 430,
                                nodes: nodes, edges: edges, onEdge: { i in planarityModel.toggle(link: planarityModel.links[i]) })
                    div(.class("legend")) {
                        span { i(.class("line tree")) {}; (s.link == "edge" ? "an " : "a ") + s.link }
                        span { i(.class("line active")) {}; "the newest" }
                        span { i(.class("line route")) {}; "the Kuratowski subgraph" }
                        span { i(.class("dot cut")) {}; "its branch vertices" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "All \(model.links.count) \(s.link)s added" : "\(k) of \(model.links.count) \(s.link)s" }
                        p(.class("narration")) {
                            if k == 0 {
                                "\(vertexCount) places, and nothing joins them yet. Add the \(s.link)s one at a time. After each one, Grafluent checks whether some drawing still avoids every crossing."
                            } else if finished && state.planar {
                                "Every \(s.link) is in, and the graph is planar. "
                                if let faces = state.faces {
                                    "Its drawing has \(faces) faces, counting the outside. And \(vertexCount) − \(k) + \(faces) = \(vertexCount - k + faces), as Euler’s formula says."
                                }
                            } else {
                                describePlanarity(k, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { state.planar ? "Planar" : "Not planar" }
                        div(.class("stat")) {
                            div {
                                span(.class("num")) { "\(vertexCount)" }
                                "vertices"
                            }
                            div {
                                span(.class("num")) { "\(k)" }
                                "edges, of at most \(3 * vertexCount - 6)"
                            }
                            div(.class(state.planar ? "good" : "bad")) {
                                span(.class("num")) { state.faces.map { "\($0)" } ?? "–" }
                                "faces"
                            }
                        }
                    }
                    if let witness = state.witness {
                        div(.class("panel")) {
                            span(.class("label")) { "The proof: a \(kuratowskiName(witness.kind))" }
                            div(.class("chips")) {
                                for v in witness.branchVertices { span(.class("chip bad")) { v } }
                            }
                            p(.class("note")) {
                                witness.kind == .k5
                                    ? "Each of these five is joined to every other by a red path."
                                    : "Each of the first three is joined to each of the last three by a red path."
                            }
                        }
                    }
                    if !model.removed.isEmpty {
                        div(.class("panel")) {
                            span(.class("label")) { "Taken out" }
                            div(.class("chips")) {
                                for i in model.removed.sorted() { span(.class("chip hollow")) { "\(s.links[i])" } }
                            }
                            div(.class("buttons")) {
                                button(.type(.button)) { "Put them back" }
                                    .onClick { planarityModel.restore() }
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Graph")) {
                        button(.type(.button), .class(model.scenario == 0 ? "on" : "")) { planarityScenarios[0].title }
                            .onClick { planarityModel.choose(0) }
                        button(.type(.button), .class(model.scenario == 1 ? "on" : "")) { planarityScenarios[1].title }
                            .onClick { planarityModel.choose(1) }
                        button(.type(.button), .class(model.scenario == 2 ? "on" : "")) { planarityScenarios[2].title }
                            .onClick { planarityModel.choose(2) }
                    }
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Drawing")) {
                        button(.type(.button), .class(model.asDrawn ? "" : "on")) { "Planar layout" }
                            .onClick { planarityModel.asDrawn = false }
                        button(.type(.button), .class(model.asDrawn ? "on" : "")) { "As first drawn" }
                            .onClick { planarityModel.asDrawn = true }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ... max(model.links.count, 1)).prefix(model.links.count).map { k in
                        let title = describePlanarity(k, model)
                        if model.states[k].planar { return Marble(kind: "m-blue", radius: 8, title: title) }
                        return k == model.breaking ? Marble(kind: "m-red", radius: 11, letter: "!", title: title) : Marble(kind: "m-grey", radius: 6, title: title)
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "still planar"),
                        (Marble(kind: "m-red", radius: 6), "the \(s.link) that makes it non-planar"),
                        (Marble(kind: "m-grey", radius: 4), "still not planar"),
                    ])
                p(.class("note")) { "Click any \(s.link) to take it out, and click again to put it back. While the graph is planar, planarLayout() draws it. Otherwise it is shown as first drawn." }
            }
        }
    }
}

@View
struct PlanarityCodePanel {
    var body: some View {
        let model = planarityModel
        let s = model.current
        let k = model.playback.k
        let state = model.states[k]
        let witness = state.witness.map { "\(kuratowskiName($0.kind)) on [" + $0.branchVertices.map { "\"\($0)\"" }.joined(separator: ", ") + "]" } ?? "nil"
        let drawing = state.layout == nil ? "nil" : "\(s.spots.count) points on a grid, no crossings"
        CodePanel(
            snippets: [
                .planarityImports,
                Snippet(lines: ["let places = [" + s.spots.map { "\"\($0.name)\"" }.joined(separator: ", ") + "]", "let links = ["]
                    + model.links.map { "    UndirectedEdge(\"\($0.u)\", \"\($0.v)\")," } + ["]", "let added = \(k)"]),
                .planarityTest,
            ],
            results: ["\(state.planar)", witness, drawing, state.faces.map { "\($0)" } ?? "nil"])
    }
}

enum PlanarityPage {
    static func mount() {
        mountView(PlanarityLab(), in: "app")
        mountView(PlanarityCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.kuratowski, Names.wagner, Names.euler, Names.deFraysseix]), in: "names")
    }
}
