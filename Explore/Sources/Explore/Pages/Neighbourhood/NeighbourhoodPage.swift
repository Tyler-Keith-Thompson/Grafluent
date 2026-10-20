import AdjacencyListModule
import ElementaryUI
import GraphOperations
import GraphProtocols
import Reactivity

/// Each entity and where it sits, in SVG units of the 640 × 470 view box.
let factSpots: [(name: String, x: Double, y: Double)] = [
    ("Ada Lovelace", 250, 235), ("Analytical Engine", 370, 160), ("Charles Babbage", 370, 310), ("Difference Engine", 500, 380),
    ("Lord Byron", 120, 235), ("Poetry", 40, 150), ("Greece", 40, 330), ("Punched cards", 300, 60),
    ("Jacquard loom", 170, 40), ("Weaving", 60, 60), ("Programming", 500, 90), ("Alan Turing", 600, 160),
    ("Enigma", 600, 60), ("Bletchley Park", 610, 260), ("Logarithm tables", 390, 440), ("Navigation", 230, 430),
    ("Royal Society", 500, 240), ("Isaac Newton", 590, 400),
]

/// The index in `factSpots` of each entity.
let factIndex: [String: Int] = Dictionary(uniqueKeysWithValues: factSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each mention, as offsets in `factSpots`, by position in `facts`.
let factEnds: [(Int, Int)] = facts.edges.map { (factIndex[$0.u]!, factIndex[$0.v]!) }

/// The questions a reader might ask, and the entities they name.
let factQuestions: [(label: String, seeds: [String])] = [
    ("Ada Lovelace", ["Ada Lovelace"]),
    ("Ada Lovelace and Alan Turing", ["Ada Lovelace", "Alan Turing"]),
    ("the Difference Engine", ["Difference Engine"]),
]

/// The neighbourhood page's state: the question, the hops, the budget, and the playback over
/// the rings.
@Reactive
final class NeighbourhoodModel {
    var question = 0
    var hops = 2
    var budget = 8
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-neighbourhood")

    init() {
        playback.reset(count: hops + 1)
    }

    var seeds: [String] { factQuestions[question].seeds }

    func choose(question: Int) {
        self.question = question
        setProperty(id: "neighbourhood-question", "value", to: "\(question)")
    }

    func choose(hops: Int) {
        self.hops = hops
        playback.reset(count: hops + 1)
        setProperty(id: "neighbourhood-hops", "value", to: "\(hops)")
    }

    func choose(budget: Int) {
        self.budget = budget
        setProperty(id: "neighbourhood-budget", "value", to: "\(budget)")
    }
}

let neighbourhoodModel = NeighbourhoodModel()

/// `Ada Lovelace, Lord Byron and Poetry`.
func factList(_ names: [String]) -> String {
    names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// The ring each kept entity is in: 0 for a seed, then one more per hop, with the budget applied.
func factRings(seeds: [String], hops: Int, budget: Int) -> [String: Int] {
    let kept = Set(factsNearby(seeds, hops: hops, budget: budget))
    var ring = [String: Int]()
    var frontier = seeds.filter { kept.contains($0) }
    for s in frontier { ring[s] = 0 }
    var depth = 0
    while depth < hops, !frontier.isEmpty {
        depth += 1
        var next: [String] = []
        for v in frontier {
            for w in facts.neighbors(of: v) where kept.contains(w) && ring[w] == nil {
                ring[w] = depth
                next.append(w)
            }
        }
        frontier = next
    }
    return ring
}

/// The sentence for one ring.
func describeRing(_ depth: Int, seeds: [String], hops: Int, budget: Int) -> String {
    let withBudget = factRings(seeds: seeds, hops: hops, budget: budget)
    let without = factRings(seeds: seeds, hops: hops, budget: facts.vertexCount)
    let kept = withBudget.filter { $0.value == depth }.map(\.key).sorted()
    let all = without.filter { $0.value == depth }.map(\.key).sorted()
    let keptSoFar = withBudget.filter { $0.value <= depth }.count
    if depth == 0 {
        return "Start from \(factList(seeds)). \(keptSoFar) of the budget of \(budget) used."
    }
    if kept.isEmpty {
        return "Ring \(depth) would add \(factList(all)), but the budget of \(budget) is already used up, so nothing more is kept."
    }
    if kept.count < all.count {
        let dropped = all.filter { !kept.contains($0) }
        return "Ring \(depth) has \(all.count) entities, more than the \(kept.count) places left in the budget. The best connected are kept: \(factList(kept)). Dropped: \(factList(dropped))."
    }
    return "Ring \(depth) adds \(factList(kept)), everything one hop further. \(keptSoFar) of the budget of \(budget) used."
}

/// The knowledge graph with the rings around the seeds, as far as the hops and the budget allow.
@View
struct NeighbourhoodLab {
    var body: some View {
        let model = neighbourhoodModel
        let playback = model.playback
        let k = playback.k
        let seeds = model.seeds
        let rings = factRings(seeds: seeds, hops: model.hops, budget: model.budget)
        let shownRing = k > 0 ? k - 1 : -1
        let seedSet = Set(seeds)
        let nodes = factSpots.map { spot in
            let ring = rings[spot.name]
            let shown = ring != nil && ring! <= shownRing
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 12,
                              classes: shown ? (seedSet.contains(spot.name) ? "current" : (ring == shownRing ? "frontier" : "visited")) : (k == 0 ? "" : "dim"))
        }
        let edges = factEnds.map { ends in
            let a = rings[factSpots[ends.0].name], b = rings[factSpots[ends.1].name]
            let both = a != nil && b != nil && a! <= shownRing && b! <= shownRing
            return CanvasEdge(from: ends.0, to: ends.1, classes: both ? "tree" : (k == 0 ? "" : "faint"))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The neighbourhood of a question in a knowledge graph")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eighteen entities from a knowledge graph with the ones near the question picked out, ring by ring", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot current")) {}; "named in the question" }
                        span { i(.class("dot frontier")) {}; "the ring just added" }
                        span { i(.class("dot visited")) {}; "an earlier ring" }
                        span { i(.class("line tree")) {}; "a fact between kept entities" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "The question" : "Ring \(shownRing) of \(model.hops)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "A question about \(factList(seeds)). Pull in what the graph knows within \(model.hops) hop\(model.hops == 1 ? "" : "s"), at most \(model.budget) entities. Press Step to add one ring at a time."
                            } else {
                                describeRing(shownRing, seeds: seeds, hops: model.hops, budget: model.budget)
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("neighbourhood-question")) {
                                "About "
                                select(.id("neighbourhood-question")) {
                                    for (n, question) in factQuestions.enumerated() {
                                        option(.value("\(n)")) { question.label }.attributes(.selected, when: model.question == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { neighbourhoodModel.choose(question: n) }
                                }
                            }
                            label(.class("field"), .for("neighbourhood-hops")) {
                                "Hops: "
                                select(.id("neighbourhood-hops")) {
                                    for n in 1 ... 4 {
                                        option(.value("\(n)")) { "\(n)" }.attributes(.selected, when: model.hops == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { neighbourhoodModel.choose(hops: n) }
                                }
                            }
                            label(.class("field"), .for("neighbourhood-budget")) {
                                "Budget: "
                                select(.id("neighbourhood-budget")) {
                                    for n in [4, 6, 8, 12, 18] {
                                        option(.value("\(n)")) { "\(n)" }.attributes(.selected, when: model.budget == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { neighbourhoodModel.choose(budget: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Kept so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for depth in 0 ... max(shownRing, 0) where k > 0 {
                                let names = rings.filter { $0.value == depth }.map(\.key).sorted()
                                if !names.isEmpty {
                                    div(.class(depth == shownRing ? "qrow top" : "qrow plain")) {
                                        span { factList(names) }
                                        span(.class("num")) { depth == 0 ? "the question" : "ring \(depth)" }
                                    }
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
                    marbles: (0 ... model.hops).map { depth in
                        let count = rings.filter { $0.value == depth }.count
                        return Marble(kind: depth == 0 ? "m-current" : "m-frontier", radius: 5 + Double(count), letter: "\(count)",
                                      title: describeRing(depth, seeds: seeds, hops: model.hops, budget: model.budget))
                    },
                    legend: [(Marble(kind: "m-current", radius: 7), "the question’s entities"), (Marble(kind: "m-frontier", radius: 7), "one ring, with how many it keeps")])
                p(.class("note")) { "egoGraphView(of:radius:maximumVertexCount:priority:) builds the whole view at once. The page shows it ring by ring." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct NeighbourhoodCodePanel {
    var body: some View {
        let model = neighbourhoodModel
        let all = factsNearby(model.seeds, hops: model.hops)
        let cut = factsNearby(model.seeds, hops: model.hops, budget: model.budget)
        let quoted = { (names: [String]) -> String in "[" + names.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        let links = facts.egoGraphView(of: model.seeds, radius: model.hops).edgeCount
        CodePanel(
            snippets: [.neighbourhoodImports, .neighbourhoodFacts, Snippet(lines: ["let seeds = " + quoted(model.seeds), "let hops = \(model.hops)", "let budget = \(model.budget)"]), .neighbourhoodHops, .neighbourhoodBudget],
            results: [quoted(all), "\(links)", quoted(cut)])
    }
}

enum NeighbourhoodPage {
    static func mount() {
        mountView(NeighbourhoodLab(), in: "app")
        mountView(NeighbourhoodCodePanel(), in: "code")
    }
}
