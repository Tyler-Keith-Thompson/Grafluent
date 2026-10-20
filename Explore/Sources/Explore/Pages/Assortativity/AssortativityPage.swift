import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Where each person of the newsroom sits, in SVG units of the 640 × 470 view box, in `vertices` order.
let newsroomSpots: [(name: String, x: Double, y: Double)] = [
    ("Ed", 220, 170), ("Flo", 420, 170), ("Gil", 320, 330), ("Ana", 100, 100), ("Ben", 40, 210), ("Cat", 540, 100),
    ("Dan", 600, 210), ("Eve", 250, 440), ("Hal", 420, 440),
]

/// Where each airport sits, in `vertices` order.
let airlineSpots: [(name: String, x: Double, y: Double)] = [
    ("Hub", 320, 235), ("Ames", 130, 90), ("Bend", 60, 235), ("Cody", 130, 390), ("Dale", 320, 430),
    ("Elko", 510, 390), ("Fargo", 580, 235), ("Gary", 510, 90), ("Hilo", 320, 50),
]

/// The assortativity page's state: the network, and the playback over its vertices.
@Reactive
final class AssortativityModel {
    var network = 0
    @ReactiveIgnored let newsroomMixing = mixing(newsroom)
    @ReactiveIgnored let airlineMixing = mixing(airline)
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-assortativity")

    init() {
        playback.reset(count: newsroom.vertexCount)
    }

    var graph: UndirectedAdjacencyList<String> { network == 0 ? newsroom : airline }
    var spots: [(name: String, x: Double, y: Double)] { network == 0 ? newsroomSpots : airlineSpots }
    var measures: (degree: [Int], neighborDegree: [Double], coefficient: Double?, byDegree: [Int: Double]) { network == 0 ? newsroomMixing : airlineMixing }

    func choose(network: Int) {
        self.network = network
        playback.reset(count: graph.vertexCount)
        setProperty(id: "assortativity-network", "value", to: "\(network)")
    }
}

let assortativityModel = AssortativityModel()

/// The vertices drawn with their degree and their neighbours' average once shown.
func mixingNodes(_ spots: [(name: String, x: Double, y: Double)], _ measures: (degree: [Int], neighborDegree: [Double], coefficient: Double?, byDegree: [Int: Double]), shown k: Int, current: Int?, neighbours: Set<String>) -> [CanvasNode] {
    var nodes: [CanvasNode] = []
    for (v, spot) in spots.enumerated() {
        let classes: String
        if current == v { classes = "current" } else if neighbours.contains(spot.name) { classes = "frontier" } else if v < k { classes = "done" } else { classes = "" }
        nodes.append(CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: v < k ? "\(measures.degree[v])" : "",
                                note: v < k ? "near \(oneDecimal(measures.neighborDegree[v]))" : "", radius: 15, classes: classes))
    }
    return nodes
}

/// The links, the current vertex's picked out.
func mixingEdges(_ graph: UndirectedAdjacencyList<String>, _ index: [String: Int], current: String?, muted: Bool) -> [CanvasEdge] {
    graph.edges.map { edge in
        let mine = current != nil && (edge.u == current || edge.v == current)
        return CanvasEdge(from: index[edge.u]!, to: index[edge.v]!, classes: mine ? "tree" : (muted ? "faint" : ""))
    }
}

/// One vertex's marble: busier, quieter or about the same as its neighbours.
func mixingMarble(_ v: Int, _ model: AssortativityModel) -> Marble {
    let d = model.measures.degree[v], around = model.measures.neighborDegree[v]
    let kind = around > Double(d) + 0.05 ? "m-frontier" : (around < Double(d) - 0.05 ? "m-current" : "m-done")
    return Marble(kind: kind, radius: 4 + Double(d), letter: "\(d)", title: describeMixing(v, model))
}

/// The sentence for one vertex.
func describeMixing(_ v: Int, _ model: AssortativityModel) -> String {
    let name = model.spots[v].name
    let degree = model.measures.degree[v]
    let around = model.measures.neighborDegree[v]
    let compare = around > Double(degree) + 0.05 ? "busier than" : (around < Double(degree) - 0.05 ? "quieter than" : "as busy as")
    return "\(name) has \(degree) link\(degree == 1 ? "" : "s"); \(name)’s neighbours have \(oneDecimal(around)) on average. They are \(compare) \(name)."
}

/// The network with each vertex's degree against its neighbours' average, one vertex at a time.
@View
struct AssortativityLab {
    var body: some View {
        let model = assortativityModel
        let playback = model.playback
        let k = playback.k
        let graph = model.graph
        let spots = model.spots
        let measures = model.measures
        let n = graph.vertexCount
        let current = k > 0 ? k - 1 : nil
        let currentName = current.map { spots[$0].name }
        let neighbours = Set(currentName.map { Array(graph.neighbors(of: $0)) } ?? [])
        let index: [String: Int] = Dictionary(uniqueKeysWithValues: spots.enumerated().map { ($0.element.name, $0.offset) })
        let finished = k == n
        let nodes = mixingNodes(spots, measures, shown: k, current: current, neighbours: neighbours)
        let edges = mixingEdges(graph, index, current: currentName, muted: k > 0 && !finished)
        let r = measures.coefficient

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Degree assortativity of a network")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A network with each vertex's number of links, and the average number its neighbours have", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot current")) {}; "this vertex" }
                        span { i(.class("dot frontier")) {}; "its neighbours" }
                        span { "number: links; “near”: the neighbours’ average" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "The whole network" : (k == 0 ? "Before we start" : "Vertex \(k) of \(n)") }
                        p(.class("narration")) {
                            if k == 0 {
                                "Do busy vertices link to busy vertices? Compare each vertex’s number of links with the average of its neighbours. Press Step to go through them."
                            } else {
                                describeMixing(current!, model)
                                if finished {
                                    " The assortativity coefficient is \(r.map(signedTwoPlaces) ?? "undefined"): "
                                    if let r {
                                        r > 0.1 ? "positive, so busy vertices tend to link to busy ones." : (r < -0.1 ? "negative, so busy vertices tend to link to quiet ones." : "near zero, so links do not care about busyness.")
                                    } else {
                                        "every vertex has the same number of links, so there is nothing to compare."
                                    }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("assortativity-network")) {
                                "Network: "
                                select(.id("assortativity-network")) {
                                    option(.value("0")) { "the newsroom" }.attributes(.selected, when: model.network == 0)
                                    option(.value("1")) { "the airline" }.attributes(.selected, when: model.network == 1)
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { assortativityModel.choose(network: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "By number of links" }
                        div(.class("queue")) {
                            for degree in measures.byDegree.keys.sorted() {
                                div(.class("qrow plain")) {
                                    span { "vertices with \(degree) link\(degree == 1 ? "" : "s")" }
                                    span(.class("num")) { "neighbours average \(oneDecimal(measures.byDegree[degree]!))" }
                                }
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
                    marbles: (0 ..< n).map { v in mixingMarble(v, model) },
                    legend: [(Marble(kind: "m-frontier", radius: 7), "neighbours busier than it"), (Marble(kind: "m-current", radius: 7), "neighbours quieter than it"), (Marble(kind: "m-done", radius: 7), "about the same")])
                p(.class("note")) { "averageNeighborDegrees() and degreeAssortativityCoefficient() read the whole network at once. Each step shows one vertex." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct AssortativityCodePanel {
    var body: some View {
        let model = assortativityModel
        let measures = model.measures
        let byDegree = "[" + measures.byDegree.keys.sorted().map { "\($0): \(oneDecimal(measures.byDegree[$0]!))" }.joined(separator: ", ") + "]"
        CodePanel(
            snippets: [.assortativityImports, .assortativityNetworks, Snippet(lines: ["let graph = \(model.network == 0 ? "newsroom" : "airline")"]), .assortativityMeasure],
            results: [measures.coefficient.map(signedTwoPlaces) ?? "nil", "[" + measures.neighborDegree.map(oneDecimal).joined(separator: ", ") + "]", byDegree])
    }
}

enum AssortativityPage {
    static func mount() {
        mountView(AssortativityLab(), in: "app")
        mountView(AssortativityCodePanel(), in: "code")
    }
}
