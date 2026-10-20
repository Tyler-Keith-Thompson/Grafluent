import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each place on the utility and where it sits, in SVG units of the 640 × 470 view box.
let gridSpots: [(name: String, x: Double, y: Double)] = [
    ("Plant", 60, 110), ("Mill", 190, 60), ("Ford", 200, 220), ("Quarry", 330, 70), ("Cross", 350, 240),
    ("Hill", 480, 110), ("Marsh", 420, 390), ("Bay", 580, 300),
]

/// The index in `gridSpots` of each place.
let gridIndex: [String: Int] = Dictionary(uniqueKeysWithValues: gridSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each cable, as offsets in `gridSpots`, by position in `utility`.
let gridEnds: [(Int, Int)] = utility.edges.map { (gridIndex[$0.u]!, gridIndex[$0.v]!) }

/// The sets of places a customer might ask to connect.
let gridRequests: [(label: String, places: [String])] = [
    ("Plant, Hill and Bay", ["Plant", "Hill", "Bay"]),
    ("Plant and Bay", ["Plant", "Bay"]),
    ("Mill, Quarry and Marsh", ["Mill", "Quarry", "Marsh"]),
    ("Plant, Quarry, Marsh and Bay", ["Plant", "Quarry", "Marsh", "Bay"]),
    ("everywhere", gridSpots.map(\.name)),
]

/// The Steiner tree page's state: the request, and the playback over the tree's mains.
@Reactive
final class SteinerModel {
    var request = 0
    @ReactiveIgnored let spanning = gridSpanningTree()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1000, scrubID: "scrub-steiner")

    init() {
        playback.reset(count: gridSteinerTree(gridRequests[0].places).edges.count)
    }

    var places: [String] { gridRequests[request].places }

    func choose(request: Int) {
        self.request = request
        playback.reset(count: gridSteinerTree(gridRequests[request].places).edges.count)
        setProperty(id: "steiner-request", "value", to: "\(request)")
    }
}

let steinerModel = SteinerModel()

/// The mains of the tree sorted by length, so the playback lays the short ones first.
func gridLaidInOrder(_ edges: [Int]) -> [Int] {
    edges.sorted { (cableKilometres[utility.edges[$0]]!, $0) < (cableKilometres[utility.edges[$1]]!, $1) }
}

/// The sentence for one cable laid.
func describeCable(_ p: Int, number: Int, of total: Int) -> String {
    let cable = utility.edges[p]
    return "Cable \(number) of \(total): \(cable.u) to \(cable.v), \(cableKilometres[cable]!) km."
}

/// The utility with the Steiner tree laid cable by cable.
@View
struct SteinerLab {
    var body: some View {
        let model = steinerModel
        let playback = model.playback
        let k = playback.k
        let places = model.places
        let tree = gridSteinerTree(places)
        let laid = gridLaidInOrder(tree.edges)
        let shown = Set(laid.prefix(k))
        let current = k > 0 ? laid[k - 1] : nil
        let terminals = Set(places.map { gridIndex[$0]! })
        let touched = Set(shown.flatMap { [gridEnds[$0].0, gridEnds[$0].1] })
        let finished = k == laid.count
        let nodes = gridSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 15,
                       classes: terminals.contains(v) ? "frontier" : (touched.contains(v) ? "visited" : "dim"))
        }
        let edges = gridEnds.enumerated().map { p, ends in
            CanvasEdge(from: ends.0, to: ends.1, label: "\(cableKilometres[utility.edges[p]]!)", classes: current == p ? "current" : (shown.contains(p) ? "tree" : "faint"))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A Steiner tree on the grid")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eight places that could be joined by twelve cables, with the cables laid so far", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "a place that must be connected" }
                        span { i(.class("dot visited")) {}; "a place used on the way" }
                        span { i(.class("line tree")) {}; "a cable laid" }
                        span { "numbers: kilometres" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Connected" : (k == 0 ? "The request" : "Cable \(k) of \(laid.count)") }
                        p(.class("narration")) {
                            if k == 0 {
                                "Connect \(nameList(places)) with the least cable. Other places may be used on the way. Press Step to lay the cables, shortest first."
                            } else {
                                describeCable(current!, number: k, of: laid.count)
                                if finished {
                                    " \(tree.kilometres) km in all. Connecting every place would take \(model.spanning.kilometres) km."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("steiner-request")) {
                                "Connect "
                                select(.id("steiner-request")) {
                                    for (n, request) in gridRequests.enumerated() {
                                        option(.value("\(n)")) { request.label }.attributes(.selected, when: model.request == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { steinerModel.choose(request: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Cables so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for (n, p) in laid.prefix(k).enumerated() {
                                div(.class(n == k - 1 ? "qrow top" : "qrow plain")) {
                                    span { "\(utility.edges[p].u) – \(utility.edges[p].v)" }
                                    span(.class("num")) { "\(cableKilometres[utility.edges[p]]!) km" }
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
                    marbles: laid.enumerated().map { n, p in
                        Marble(kind: "m-tree", radius: 4 + Double(cableKilometres[utility.edges[p]]!), letter: "\(cableKilometres[utility.edges[p]]!)",
                               title: describeCable(p, number: n + 1, of: laid.count))
                    },
                    legend: [(Marble(kind: "m-tree", radius: 7), "one cable of the tree, bigger for longer")])
                p(.class("note")) { "steinerTree(terminals:weight:) returns the whole tree at once. The page lays its cables shortest first." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct SteinerCodePanel {
    var body: some View {
        let model = steinerModel
        let tree = gridSteinerTree(model.places)
        CodePanel(
            snippets: [.steinerImports, .steinerNetwork, Snippet(lines: ["let places = [" + model.places.map { "\"\($0)\"" }.joined(separator: ", ") + "]"]), .steinerTree, .steinerSpanning],
            results: ["[" + tree.edges.map { "\($0)" }.joined(separator: ", ") + "]", "\(tree.kilometres)", "\(model.spanning.kilometres)"])
    }
}

enum SteinerPage {
    static func mount() {
        mountView(SteinerLab(), in: "app")
        mountView(SteinerCodePanel(), in: "code")
    }
}
