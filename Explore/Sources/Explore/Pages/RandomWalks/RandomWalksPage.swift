import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Walks

/// Each place in the park and where it sits, in SVG units of the 640 × 400 view box.
let parkSpots: [(name: String, x: Double, y: Double)] = [
    ("Ash", 50, 120), ("Birch", 130, 50), ("Cedar", 120, 200), ("Elm", 210, 120), ("Fir", 190, 280), ("Oak", 270, 210),
    ("Ford", 340, 250), ("Mill", 400, 200), ("Weir", 450, 250),
    ("Bay", 500, 180), ("Cove", 560, 100), ("Dune", 520, 300), ("Reef", 600, 210), ("Sand", 580, 360), ("Tide", 620, 300),
]

/// The index in `parkSpots` of each name.
let parkIndex: [String: Int] = Dictionary(uniqueKeysWithValues: parkSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each path, as offsets in `parkSpots`, by position in `park`.
let parkEnds: [(Int, Int)] = park.edges.map { (parkIndex[$0.u]!, parkIndex[$0.v]!) }

/// The places on the beach, the far side of the park from Ash.
let beach: Set<String> = ["Bay", "Cove", "Dune", "Reef", "Sand", "Tide"]

/// The values each slider steps through.
let walkParameters: [Double] = [0.25, 0.5, 1, 2, 4]

/// `0.25`, `1`, `4`.
func parameterText(_ x: Double) -> String {
    x == x.rounded() ? "\(Int(x))" : x == 0.25 ? "0.25" : "0.5"
}

/// How one step of a walk relates to the place before the last: straight back, to another
/// place next to it, or further away.
enum WalkStepKind {
    case first, back, near, out
}

/// The random walks page's state: p, q and the seed, the walk, and its playhead.
@Reactive
final class RandomWalksModel {
    /// Offsets in `walkParameters`.
    var p = 2
    var q = 2
    var seed: UInt64 = 1
    var walk: Walk<String, Int>
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 450, scrubID: "scrub-walk")
    static let length = 30

    init() {
        walk = parkWalk(p: 1, q: 1, length: RandomWalksModel.length, seed: 1)
        playback.reset(count: walk.length)
    }

    func run() {
        walk = parkWalk(p: walkParameters[p], q: walkParameters[q], length: RandomWalksModel.length, seed: seed)
        playback.reset(count: walk.length)
        setProperty(id: "walk-p", "value", to: "\(p)")
        setProperty(id: "walk-q", "value", to: "\(q)")
    }

    var places: [Int] { walk.vertices.map { parkIndex[$0]! } }

    /// The kind of step `j` (from 0) of the walk.
    func kind(_ j: Int) -> WalkStepKind {
        guard j > 0 else { return .first }
        let places = places
        let before = places[j - 1], to = places[j + 1]
        if to == before { return .back }
        return parkEnds.contains { ($0.0 == before && $0.1 == to) || ($0.1 == before && $0.0 == to) } ? .near : .out
    }

    /// Over twenty seeds from this one, the mean number of places a walk visits and how many
    /// walks reach the beach.
    var sample: (distinct: Double, beach: Int) {
        let walks = (0 ..< 20).map { parkWalk(p: walkParameters[p], q: walkParameters[q], length: RandomWalksModel.length, seed: seed + UInt64($0)) }
        let distinct = walks.map { Double(Set($0.vertices).count) }.reduce(0, +) / 20
        return (distinct, walks.filter { $0.vertices.contains { beach.contains($0) } }.count)
    }
}

let randomWalksModel = RandomWalksModel()

/// The sentence for step `j` (from 0) of the walk.
func describeWalkStep(_ model: RandomWalksModel, _ j: Int) -> String {
    let places = model.places
    let from = parkSpots[places[j]].name, to = parkSpots[places[j + 1]].name
    switch model.kind(j) {
    case .first: return "Set off from \(from) to \(to). On the first step, every path out is equally likely."
    case .back: return "Go back from \(from) to \(to), where the walker just was. This step has weight 1/p."
    case .near: return "Go from \(from) to \(to). \(to) is next to \(parkSpots[places[j - 1]].name), where the walker just was, so this step has weight 1."
    case .out: return "Go on from \(from) to \(to), further from \(parkSpots[places[j - 1]].name). This step has weight 1/q."
    }
}

/// The park with the walk so far.
@View
struct RandomWalkLab {
    var body: some View {
        let model = randomWalksModel
        let playback = model.playback
        let k = playback.k
        let places = model.places
        let walked = Array(places.prefix(k + 1))
        let at = walked.last!
        let visits = parkSpots.indices.map { v in walked.filter { $0 == v }.count }
        let pathsTaken = Set(model.walk.edges.prefix(k))
        let lastPath = k > 0 ? model.walk.edges[k - 1] : -1
        let sample = model.sample
        let pValue = walkParameters[model.p], qValue = walkParameters[model.q]
        let nodes = parkSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: visits[v] > 0 ? "\(visits[v])" : "", radius: 15,
                       classes: (v == at ? "visited current" : visits[v] > 0 ? "done" : "") + (v == 0 ? " source" : ""))
        }
        let edges = parkEnds.enumerated().map { e, ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: e == lastPath ? "active" : pathsTaken.contains(e) ? "tree" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A random walk through the park")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A park of woods, a river path and a beach, with the walk so far", width: 640, height: 400, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "the walker" }
                        span { i(.class("dot done")) {}; "visited, with how often" }
                        span { i(.class("line tree")) {}; "walked" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == model.walk.length ? "Done after \(model.walk.length) steps" : "Step \(k) of \(model.walk.length)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "A walker starts at Ash and takes \(RandomWalksModel.length) random steps. After the first step, each path out gets a weight from the place the walker just left. Straight back is 1/p. To a place next to it is 1. Further away is 1/q. Press Play."
                            } else {
                                describeWalkStep(model, k - 1)
                            }
                        }
                    }
                    div(.class("panel")) {
                        label(.class("field"), .for("walk-p")) {
                            "p = \(parameterText(pValue))"
                            input(.id("walk-p"), .type(.range), .min(0), .max(4), .value("\(model.p)"))
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { randomWalksModel.p = n; randomWalksModel.run() }
                                }
                        }
                        label(.class("field"), .for("walk-q")) {
                            "q = \(parameterText(qValue))"
                            input(.id("walk-q"), .type(.range), .min(0), .max(4), .value("\(model.q)"))
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { randomWalksModel.q = n; randomWalksModel.run() }
                                }
                        }
                        p(.class("note")) {
                            qValue < 1 ? "With q below 1 the walker prefers to move on. It explores outward, like a depth-first search." : qValue > 1 ? "With q above 1 the walker prefers to stay near. It circles its neighbourhood, like a breadth-first search." : "With q = 1 the walker has no preference between near and far."
                            pValue < 1 ? " p below 1 makes it double back often." : pValue > 1 ? " p above 1 makes doubling back rare." : ""
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Twenty walks from seed \(model.seed)" }
                        p(.class("narration")) { "On average a walk visits \(oneDecimal(sample.distinct)) different places. \(sample.beach) of the 20 reach the beach." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    button(.type(.button)) { "Draw again" }
                        .onClick {
                            randomWalksModel.seed += 1
                            randomWalksModel.run()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: (0 ..< model.walk.length).map { j in
                        let title = describeWalkStep(model, j)
                        switch model.kind(j) {
                        case .first: return Marble(kind: "m-hollow", radius: 6, title: title)
                        case .back: return Marble(kind: "m-red", radius: 6, letter: "p", title: title)
                        case .near: return Marble(kind: "m-blue", radius: 6, title: title)
                        case .out: return Marble(kind: "m-violet", radius: 6, letter: "q", title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-red", radius: 6), "straight back, 1/p"),
                        (Marble(kind: "m-blue", radius: 6), "to a place next to the last one, 1"),
                        (Marble(kind: "m-violet", radius: 6), "further on, 1/q"),
                    ])
                p(.class("note")) { "The steps replay the walk that randomWalk(from:length:returnParameter:inOutParameter:using:) returns. The page works out the kind of each step. The same seed always gives the same walk." }
            }
        }
    }
}

/// The walk's code panel.
@View
struct RandomWalkCodePanel {
    var body: some View {
        let model = randomWalksModel
        CodePanel(
            snippets: [
                .randomwalksImports, .randomwalksPark,
                Snippet(lines: ["let (p, q, seed) = (\(parameterText(walkParameters[model.p])), \(parameterText(walkParameters[model.q])), UInt64(\(model.seed)))", "let length = \(RandomWalksModel.length)"]),
                .randomwalksWalk,
            ],
            results: [model.walk.vertices.prefix(6).joined(separator: " → ") + " → …", "\(Set(model.walk.vertices).count)"])
    }
}

enum RandomWalksPage {
    static func mount() {
        mountView(RandomWalkLab(), in: "app")
        mountView(RandomWalkCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.leskovec]), in: "names")
    }
}
