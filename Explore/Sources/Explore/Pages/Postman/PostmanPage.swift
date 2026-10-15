import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Tours

/// Each junction of the estate and where it sits, in SVG units of the 640 × 440 view box.
let junctionSpots: [(name: String, x: Double, y: Double)] = [
    ("Depot", 70, 220), ("Church", 220, 100), ("School", 220, 340), ("Park", 390, 100),
    ("Market", 390, 340), ("Bridge", 570, 130), ("Mill", 570, 330),
]

/// The index in `junctionSpots` of each junction's name.
let junctionIndex: [String: Int] = Dictionary(uniqueKeysWithValues: junctionSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each street, as offsets in `junctionSpots`, by position in `estate`.
let streetEnds: [(Int, Int)] = estate.edges.map { (junctionIndex[$0.u]!, junctionIndex[$0.v]!) }

/// `Church–School`.
func streetName(_ street: Int) -> String { "\(estate.edges[street].u)–\(estate.edges[street].v)" }

/// One street driven: which, from where to where, and whether it was already cleared.
struct PloughStep {
    var street: Int
    var from: Int
    var to: Int
    var again: Bool
    /// Minutes driven so far, this street included.
    var clock: Int
}

/// The postman page's state: the minutes of each street, the tour, and the playhead along it.
@Reactive
final class PostmanModel {
    var minutes = [3, 4, 2, 5, 6, 2, 4, 3, 2]
    var tour: EstateTour
    var steps: [PloughStep] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 700, scrubID: "scrub-plough")

    init() {
        tour = ploughTour(minutes: [3, 4, 2, 5, 6, 2, 4, 3, 2])
        run()
    }

    /// Asks Grafluent for the tour with the current minutes and rewinds.
    func run() {
        tour = ploughTour(minutes: minutes)
        var seen = Set<Int>()
        var clock = 0
        steps = tour.walk.edges.enumerated().map { j, street in
            clock += minutes[street]
            let step = PloughStep(street: street, from: junctionIndex[tour.walk.vertices[j]]!, to: junctionIndex[tour.walk.vertices[j + 1]]!,
                                  again: seen.contains(street), clock: clock)
            seen.insert(street)
            return step
        }
        playback.reset(count: steps.count)
    }

    /// One more minute on `street`, back to 1 after 9.
    func lengthen(_ street: Int) {
        guard street < minutes.count else { return }
        minutes[street] = minutes[street] % 9 + 1
        run()
    }

    /// The three ways to pair the four odd junctions, each with its two pairs and its minutes,
    /// cheapest first, ties in the order listed.
    var pairings: [(pairs: [(String, String)], minutes: Int)] {
        let (odd, distance) = oddJunctions(minutes: minutes)
        guard odd.count == 4 else { return [] }
        let ways: [[(Int, Int)]] = [[(0, 1), (2, 3)], [(0, 2), (1, 3)], [(0, 3), (1, 2)]]
        var result: [(pairs: [(String, String)], minutes: Int)] = []
        for way in ways {
            let pairs: [(String, String)] = way.map { (odd[$0.0], odd[$0.1]) }
            let cost: Int = way.map { distance[$0.0][$0.1] }.reduce(0, +)
            result.append((pairs, cost))
        }
        // A stable sort: ties keep the order listed.
        let order = result.indices.sorted { (result[$0].minutes, $0) < (result[$1].minutes, $1) }
        return order.map { result[$0] }
    }
}

let postmanModel = PostmanModel()

/// The estate's streets, then a bent copy of each duplicated street: `classes` gives each
/// street's classes, `copyClasses` each copy's.
func estateEdges(minutes: [Int], duplicated: [Int], classes: (Int) -> String, copyClasses: (Int) -> String) -> [CanvasEdge] {
    streetEnds.enumerated().map { p, ends in
        CanvasEdge(from: ends.0, to: ends.1, label: "\(minutes[p])", classes: classes(p))
    } + duplicated.map { p in
        CanvasEdge(from: streetEnds[p].0, to: streetEnds[p].1, classes: copyClasses(p), bend: -14)
    }
}

/// The estate with its duplicated streets, and the pairing that chose them.
@View
struct PostmanLab {
    var body: some View {
        let model = postmanModel
        let tour = model.tour
        let (odd, _) = oddJunctions(minutes: model.minutes)
        let pairings = model.pairings
        let total = model.minutes.reduce(0, +)
        let nodes = junctionSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 17,
                       classes: (odd.contains(spot.name) ? "frontier" : "") + (v == 0 ? " source" : ""))
        }
        let edges = estateEdges(minutes: model.minutes, duplicated: tour.duplicatedEdges,
                                classes: { tour.duplicatedEdges.contains($0) ? "tree" : "" }, copyClasses: { _ in "route" })

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The snowplough’s round")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "An estate of seven junctions and nine streets, minutes on each; the streets driven twice have a second, curved copy", width: 640, height: 440,
                                nodes: nodes, edges: edges, onEdge: { postmanModel.lengthen($0) })
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "an odd number of streets" }
                        span { i(.class("line route")) {}; "driven a second time" }
                    }
                    p(.class("note")) { "Click a street to add a minute to it, up to 9 and then back to 1. The numbers are minutes to clear each street." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "\(tour.weight) minutes" }
                        p(.class("narration")) {
                            "Clearing every street once takes \(total) minutes. But \(blockList(odd)) each have an odd number of streets. So some streets must be driven twice. The cheapest choice is "
                            em { blockList(tour.duplicatedEdges.map(streetName)) }
                            ", for \(tour.weight - total) minutes more."
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Pairing the odd junctions" }
                        div(.class("queue")) {
                            for (n, pairing) in pairings.enumerated() {
                                div(.class(n == 0 ? "qrow top" : "qrow plain")) {
                                    span { pairing.pairs.map { "\($0.0)–\($0.1)" }.joined(separator: " and ") }
                                    span(.class("num")) { "+\(pairing.minutes) min" }
                                }
                            }
                        }
                        p(.class("note")) { "Each pair is joined by its quickest route, driven twice. The cheapest pairing wins." }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct PostmanCodePanel {
    var body: some View {
        let model = postmanModel
        let tour = model.tour
        let (odd, distance) = oddJunctions(minutes: model.minutes)
        CodePanel(
            snippets: [
                .postmanImports, .postmanEstate,
                Snippet(lines: ["let minutes = [" + model.minutes.map(String.init).joined(separator: ", ") + "]"]),
                .postmanOdd, .postmanTour,
            ],
            results: [
                "[" + odd.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
                "[" + distance.map { "[" + $0.map(String.init).joined(separator: ", ") + "]" }.joined(separator: ", ") + "]",
                "\(tour.weight)",
                "[" + tour.duplicatedEdges.map { "\(estate.edges[$0])" }.joined(separator: ", ") + "]",
                "[" + tour.walk.vertices.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

/// The sentence for one street driven.
func describePlough(_ step: PloughStep, minutes: [Int]) -> String {
    let from = junctionSpots[step.from].name, to = junctionSpots[step.to].name
    let drive = "Drive from \(from) to \(to), \(minutes[step.street]) minute\(minutes[step.street] == 1 ? "" : "s")"
    return step.again
        ? drive + ", along a street already cleared. This is one of the streets driven twice. \(step.clock) minutes so far."
        : drive + ", clearing it. \(step.clock) minutes so far."
}

/// The plough driving the tour, one street at a time.
@View
struct PloughLab {
    var body: some View {
        let model = postmanModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let tour = model.tour
        let shown = steps.prefix(k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let cleared = Set(shown.map(\.street))
        let twice = Set(shown.filter(\.again).map(\.street))
        let at = last?.to ?? 0
        let nodes = junctionSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 17,
                       classes: (v == at ? "visited current" : "") + (v == 0 ? " source" : ""))
        }
        let edges = estateEdges(
            minutes: model.minutes, duplicated: tour.duplicatedEdges,
            classes: { p in (cleared.contains(p) ? "tree" : "") + (last?.street == p && last?.again == false ? " active" : "") },
            copyClasses: { p in twice.contains(p) ? "route" + (last?.street == p && last?.again == true ? " active" : "") : "faint" })

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The plough’s round, street by street")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The plough driving its round: cleared streets marked, the plough at its junction", width: 640, height: 440,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "the plough" }
                        span { i(.class("line tree")) {}; "cleared" }
                        span { i(.class("line route")) {}; "driven again" }
                        span { i(.class("line faint")) {}; "still to drive again" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Back at the depot after \(tour.weight) minutes" : "Street \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "The plough leaves the depot and must drive every street at least once, then come home. Press Step to follow it."
                            } else if finished {
                                describePlough(last!, minutes: model.minutes) + " Every street is cleared, \(twice.count) of them twice, and the plough is home."
                            } else {
                                describePlough(last!, minutes: model.minutes)
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
                    marbles: steps.map { step in
                        Marble(kind: step.again ? "m-red" : "m-blue", radius: 4 + Double(model.minutes[step.street]), title: describePlough(step, minutes: model.minutes))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a street cleared; bigger for longer"),
                        (Marble(kind: "m-red", radius: 6), "a street driven again"),
                    ])
                p(.class("note")) { "The steps replay tour.walk, the finished round chinesePostmanTour returns; the algorithm itself reports no steps. Change a street’s minutes in the first lab and the round changes here too." }
            }
        }
    }
}

/// The round's code panel.
@View
struct PloughCodePanel {
    var body: some View {
        let model = postmanModel
        let tour = model.tour
        CodePanel(
            snippets: [.postmanImports, .postmanEstate, Snippet(lines: ["let minutes = [" + model.minutes.map(String.init).joined(separator: ", ") + "]"]), .postmanTour],
            results: [
                "\(tour.weight)",
                "[" + tour.duplicatedEdges.map { "\(estate.edges[$0])" }.joined(separator: ", ") + "]",
                "[" + tour.walk.vertices.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

enum PostmanPage {
    static func mount() {
        mountView(PostmanLab(), in: "app")
        mountView(PostmanCodePanel(), in: "code")
        mountView(PloughLab(), in: "plough")
        mountView(PloughCodePanel(), in: "code-plough")
        mountView(NamesStrip(names: [Names.guan]), in: "names")
    }
}
