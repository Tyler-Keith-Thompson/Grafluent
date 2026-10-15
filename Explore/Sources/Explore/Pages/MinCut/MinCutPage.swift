import AdjacencyListModule
import ElementaryUI
import Flows
import GraphProtocols
import Reactivity

/// Each office and where it sits, in SVG units of the 640 × 420 view box.
let officeSpots: [(name: String, x: Double, y: Double)] = [
    ("Ashford", 70, 120), ("Bury", 200, 50), ("Cobham", 170, 300), ("Deal", 290, 180),
    ("Epsom", 380, 230), ("Frome", 470, 60), ("Goole", 450, 360), ("Hythe", 580, 210),
]

let officeSpot: [String: Int] = Dictionary(uniqueKeysWithValues: officeSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The cables in each link to start with.
let startingCables: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Ashford", "Bury"): 3, UndirectedEdge("Ashford", "Cobham"): 2, UndirectedEdge("Bury", "Cobham"): 3,
    UndirectedEdge("Bury", "Deal"): 2, UndirectedEdge("Cobham", "Deal"): 4,
    UndirectedEdge("Epsom", "Frome"): 3, UndirectedEdge("Epsom", "Goole"): 4, UndirectedEdge("Frome", "Goole"): 2,
    UndirectedEdge("Frome", "Hythe"): 3, UndirectedEdge("Goole", "Hythe"): 3,
    UndirectedEdge("Deal", "Epsom"): 2, UndirectedEdge("Cobham", "Goole"): 1,
]

typealias OfficeCut = Cut<DirectedView<UndirectedAdjacencyList<String>>, Int>

@Reactive
final class MinCutModel {
    var cables = startingCables
    var offices = UndirectedAdjacencyList<String>()
    var cheapest: OfficeCut?
    var tree: [(pair: UndirectedEdge<String>, cut: OfficeCut)] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1300, scrubID: "scrub-mincut")

    init() {
        run()
    }

    func run() {
        let answer = officeCuts(cables)
        (offices, cheapest, tree) = (answer.offices, answer.cheapest, answer.tree)
        playback.reset(count: tree.count)
    }

    /// One more cable in `link`, from 4 back to 1.
    func addCable(_ link: UndirectedEdge<String>) {
        cables[link] = cables[link]! % 4 + 1
        run()
        playback.show(tree.count)
    }

    func restore() {
        cables = startingCables
        run()
    }

    /// The least value among the tree's cuts.
    var least: Int { tree.map(\.cut.value).min() ?? 0 }
}

let minCutModel = MinCutModel()

/// `Ashford, Bury and Deal`.
func officeList(_ names: [String]) -> String { guestList(names.sorted { officeSpot[$0]! < officeSpot[$1]! }) }

func describeCut(_ k: Int, _ model: MinCutModel) -> String {
    let (pair, cut) = model.tree[k]
    let small = cut.sourceSide.count <= cut.sinkSide.count ? cut.sourceSide : cut.sinkSide
    let plural = cut.value == 1 ? "cable" : "cables"
    return "Separating \(pair.u) from \(pair.v) takes at least \(cut.value) \(plural): cut off \(officeList(small)) from the rest. Gomory and Hu’s tree gets an edge \(pair.u)–\(pair.v) worth \(cut.value)."
}

@View
struct MinCutLab {
    var body: some View {
        let model = minCutModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.tree.count
        let shown: OfficeCut? = finished ? model.cheapest : k > 0 ? model.tree[k - 1].cut : nil
        let pair = !finished && k > 0 ? model.tree[k - 1].pair : nil
        let sink = Set(shown?.sinkSide ?? [])
        let crossing = Set((shown?.edges ?? []).map(\.position))
        let nodes = officeSpots.map { spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 16,
                       classes: (shown == nil ? "" : sink.contains(spot.name) ? "pal1" : "pal0")
                           + (spot.name == pair?.u || spot.name == pair?.v ? " selected" : ""),
                       nameAbove: spot.y < 100)
        }
        let edges = model.offices.edges.indices.map { e in
            let link = model.offices.edges[e]
            return CanvasEdge(from: officeSpot[link.u]!, to: officeSpot[link.v]!, label: "\(model.cables[link]!)",
                              classes: crossing.contains(e) ? "route" : "")
        }
        let treeNodes = officeSpots.map { spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 16, classes: "visited", nameAbove: spot.y < 100)
        }
        let treeEdges = model.tree.prefix(k).enumerated().map { j, entry in
            CanvasEdge(from: officeSpot[entry.pair.u]!, to: officeSpot[entry.pair.v]!, label: "\(entry.cut.value)",
                       classes: finished && entry.cut.value == model.least ? "route" : j == k - 1 ? "active" : "tree")
        }
        let value = model.cheapest?.value ?? 0

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The office network")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eight offices joined by links, each labelled with its number of cables", width: 640, height: 420,
                                nodes: nodes, edges: edges, onEdge: { e in minCutModel.addCable(minCutModel.offices.edges[e]) })
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "one side" }
                        span { i(.class("dot pal1")) {}; "the other side" }
                        span { i(.class("line route")) {}; "the cables cut" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "The cheapest cut" : k == 0 ? "\(model.tree.count) pairs to separate" : "Cut \(k) of \(model.tree.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "To split the network, cut every cable between two groups of offices. Which split takes the fewest cuts? Press Step to separate one pair of offices at a time, as cheaply as possible."
                            } else if finished {
                                "The cheapest split of all takes \(value) \(value == 1 ? "cable" : "cables"): it cuts off \(officeList(model.cheapest?.sinkSide ?? [])). It is the lightest edge of Gomory and Hu’s tree, and minimumCut(capacity:) finds it directly."
                            } else {
                                describeCut(k - 1, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Gomory–Hu tree so far" }
                        GraphCanvas(label: "The Gomory–Hu tree: an edge per pair separated, labelled with the fewest cables between them", width: 640, height: 420, nodes: treeNodes, edges: treeEdges)
                        p(.class("note")) { "The fewest cables between any two offices is the lightest edge on the tree path between them." }
                    }
                    if model.cables != startingCables {
                        div(.class("panel")) {
                            div(.class("buttons")) {
                                button(.type(.button)) { "Put the cables back" }
                                    .onClick { minCutModel.restore() }
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
                    marbles: model.tree.indices.map { j in
                        Marble(kind: model.tree[j].cut.value == model.least ? "m-red" : "m-blue", radius: 11, letter: "\(model.tree[j].cut.value)", title: describeCut(j, model))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a pair separated, with the cables it takes"),
                        (Marble(kind: "m-red", radius: 6), "the cheapest of them"),
                    ])
                p(.class("note")) { "Each step is one edge of the Gomory–Hu tree, in the order gomoryHuTree(capacity:) adds them, with its cut from minimumCut(between:and:). Click a link to add a cable; four goes back to one." }
            }
        }
    }
}

@View
struct MinCutCodePanel {
    var body: some View {
        let model = minCutModel
        let list = { (names: [String]) in "[" + names.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        CodePanel(
            snippets: [
                .mincutImports,
                Snippet(lines: ["let cables: [UndirectedEdge<String>: Int] = ["]
                    + model.offices.edges.map { "    UndirectedEdge(\"\($0.u)\", \"\($0.v)\"): \(model.cables[$0]!)," } + ["]"]),
                .mincutNetwork, .mincutGlobal, .mincutTree,
            ],
            results: [
                "\(model.cheapest?.value ?? 0)",
                list(model.cheapest?.sinkSide ?? []),
                "[" + model.tree.map { "\($0.pair.u)–\($0.pair.v)" }.joined(separator: ", ") + "]",
                "[" + model.tree.map { "\($0.cut.value)" }.joined(separator: ", ") + "]",
            ])
    }
}

enum MinCutPage {
    static func mount() {
        mountView(MinCutLab(), in: "app")
        mountView(MinCutCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.nagamochiIbaraki]), in: "names")
    }
}
