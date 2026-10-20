import ElementaryUI
import Hypergraphs
import Reactivity

/// The committees' names, in `committees` order.
let committeeNames = ["Budget", "Hiring", "Audit", "Social", "Safety", "Archive"]

/// Each person and where they sit, in SVG units of the 640 × 470 view box, in `council.vertices`
/// order; the committees sit above them.
let councilSpots: [(name: String, x: Double, y: Double)] = [
    ("Ann", 60, 330), ("Bert", 170, 400), ("Cleo", 230, 300), ("Dev", 330, 400), ("Ezra", 390, 300),
    ("Fay", 300, 210), ("Gus", 470, 400), ("Hana", 560, 330), ("Ivo", 590, 420), ("Jude", 600, 120),
]

/// Where each committee sits.
let committeeSpots: [(x: Double, y: Double)] = [(90, 150), (270, 90), (170, 230), (520, 180), (390, 150), (600, 40)]

/// The index of each person in `councilSpots`.
let councilIndex: [String: Int] = Dictionary(uniqueKeysWithValues: councilSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The hypergraphs page's state: whether to show the committees or the pairs, and the playback
/// over the committees.
@Reactive
final class HypergraphsModel {
    /// 0 shows committees as their own circles, 1 shows the clique expansion.
    var mode = 0
    @ReactiveIgnored let facts = councilFacts()
    @ReactiveIgnored let pairs = councilPairs()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1000, scrubID: "scrub-hypergraphs")

    init() {
        playback.reset(count: committees.count)
    }

    func choose(mode: Int) {
        self.mode = mode
        setProperty(id: "hypergraphs-mode", "value", to: "\(mode)")
    }
}

let hypergraphsModel = HypergraphsModel()

/// The people, and the committees as circles above them joined to their members, or the pairs
/// of the clique expansion.
func councilDrawing(expansion: Bool, shown k: Int, current: Int?, inShown: Set<String>, pairs: [(String, String)]) -> ([CanvasNode], [CanvasEdge]) {
    let people = councilSpots.count
    var nodes: [CanvasNode] = []
    for spot in councilSpots {
        let classes: String
        if expansion { classes = "visited" } else if let current, committees[current].contains(spot.name) { classes = "current" } else if inShown.contains(spot.name) { classes = "visited" } else { classes = "" }
        nodes.append(CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: "\(council.degree(of: spot.name))", radius: 14, classes: classes))
    }
    var edges: [CanvasEdge] = []
    if expansion {
        edges = pairs.map { CanvasEdge(from: councilIndex[$0.0]!, to: councilIndex[$0.1]!, classes: "tree") }
        return (nodes, edges)
    }
    for c in 0 ..< committees.count {
        let spot = committeeSpots[c]
        let isShown = c < k
        nodes.append(CanvasNode(x: spot.x, y: spot.y, name: committeeNames[c], badge: "\(committees[c].count)", radius: 17,
                                classes: "pal\(c % 8)" + (isShown ? (c == current ? " current" : "") : " dim")))
        if isShown {
            for member in committees[c] {
                edges.append(CanvasEdge(from: people + c, to: councilIndex[member]!, classes: c == current ? "current" : "tree"))
            }
        }
    }
    return (nodes, edges)
}

/// The sentence for one committee.
func describeCommittee(_ c: Int) -> String {
    let members = committees[c]
    let size = members.count
    return "\(committeeNames[c]): \(nameList(members)). One hyperedge with \(size) member\(size == 1 ? "" : "s")\(size == 1 ? ", which no ordinary edge could be" : (size == 2 ? ", like an ordinary edge" : ", which an ordinary graph would need \(size * (size - 1) / 2) edges to hint at"))."
}

/// The council drawn as its incidence graph, committee by committee, or as its clique expansion.
@View
struct HypergraphsLab {
    var body: some View {
        let model = hypergraphsModel
        let playback = model.playback
        let k = playback.k
        let expansion = model.mode == 1
        let people = councilSpots.count
        let shownCommittees = Array(0 ..< k)
        let inShown = Set(shownCommittees.flatMap { committees[$0] })
        let current = k > 0 ? k - 1 : nil
        let (nodes, edges) = councilDrawing(expansion: expansion, shown: k, current: current, inShown: inShown, pairs: model.pairs)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The council's committees as a hypergraph")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: expansion ? "Ten people joined whenever they sit on a committee together" : "Ten people and six committees, each committee a circle joined to its members", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        if expansion {
                            span { i(.class("line tree")) {}; "sit together on some committee" }
                        } else {
                            span { i(.class("dot pal0")) {}; "a committee, with how many members" }
                            span { i(.class("line current")) {}; "membership in the committee just added" }
                        }
                        span { "number on a person: committees they sit on" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { expansion ? "The clique expansion" : (k == 0 ? "The council" : "Committee \(k) of \(committees.count)") }
                        p(.class("narration")) {
                            if expansion {
                                "Join two people whenever some committee holds both. \(model.pairs.count) pairs. The committees themselves are gone: Ann, Bert and Cleo look like three pairs, and nothing says they meet as one group. Jude, alone on the archive committee, has no pair at all."
                            } else if k == 0 {
                                "A hyperedge joins any number of people at once. Each committee is one. Press Step to add them one by one."
                            } else {
                                describeCommittee(current!)
                                if k == committees.count {
                                    " \(model.facts.components.count) connected groups in all, and the largest committee has \(model.facts.rank) members."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("hypergraphs-mode")) {
                                "Show "
                                select(.id("hypergraphs-mode")) {
                                    option(.value("0")) { "committees" }.attributes(.selected, when: model.mode == 0)
                                    option(.value("1")) { "pairs who sit together" }.attributes(.selected, when: model.mode == 1)
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { hypergraphsModel.choose(mode: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Committees so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for c in shownCommittees {
                                div(.class(c == current ? "qrow top" : "qrow plain")) {
                                    span { "\(committeeNames[c]): \(nameList(committees[c]))" }
                                    span(.class("num")) { "\(committees[c].count)" }
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
                    marbles: committees.indices.map { c in
                        Marble(kind: "m-pal\(c % 8)", radius: 5 + Double(committees[c].count) * 1.5, letter: "\(committees[c].count)", title: describeCommittee(c))
                    },
                    legend: [(Marble(kind: "m-pal1", radius: 8), "one committee, bigger for more members")])
                p(.class("note")) { "The hypergraph is built at once. Each step shows one more hyperedge." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct HypergraphsCodePanel {
    var body: some View {
        let model = hypergraphsModel
        let facts = model.facts
        let quoted = { (names: [String]) -> String in "[" + names.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        if model.mode == 1 {
            CodePanel(snippets: [.hypergraphsImports, .hypergraphsCommittees, .hypergraphsExpansion], results: ["\(model.pairs.count)"])
        } else {
            CodePanel(snippets: [.hypergraphsImports, .hypergraphsCommittees, .hypergraphsFacts],
                      results: ["\(facts.sizes)", "\(facts.degrees)", quoted(facts.neighborsOfCleo), "[" + facts.components.map(quoted).joined(separator: ", ") + "]", "\(facts.rank)"])
        }
    }
}

enum HypergraphsPage {
    static func mount() {
        mountView(HypergraphsLab(), in: "app")
        mountView(HypergraphsCodePanel(), in: "code")
    }
}
