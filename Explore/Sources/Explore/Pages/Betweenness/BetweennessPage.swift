import AdjacencyListModule
import Centrality
import ElementaryUI
import GraphProtocols
import Reactivity
import ShortestPaths

/// Each person and where they sit, in SVG units of the 660 × 420 view box.
let officeSeats: [(name: String, x: Double, y: Double)] = [
    ("Ana", 60, 210), ("Ben", 160, 90), ("Cara", 160, 330), ("Dev", 270, 210), ("Eve", 370, 300),
    ("Fay", 470, 110), ("Gus", 480, 300), ("Hana", 590, 170), ("Ivo", 600, 360),
]

let officeSeat: [String: Int] = Dictionary(uniqueKeysWithValues: officeSeats.enumerated().map { ($0.element.name, $0.offset) })

/// One pair of people and every shortest path between them.
struct OfficePair {
    var a: Int
    var b: Int
    var paths: [(people: [String], links: [Int])]
    /// The people strictly inside a shortest path, each with the share of the pair's paths that
    /// go through them, in seat order.
    var brokers: [(person: Int, share: Double)]
}

/// The running totals after some pairs.
struct BrokerTotals {
    var people: [Double]
    var links: [Double]
}

@Reactive
final class BetweennessModel {
    var pairs: [OfficePair] = []
    /// `totals[k]` is after the first `k` pairs.
    var totals: [BrokerTotals] = []
    var grafluentPeople: [Double] = []
    var grafluentLinks: [Double] = []
    var busiest = UndirectedEdge("Eve", "Eve")
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 700, scrubID: "scrub-betweenness")

    init() {
        let n = officeSeats.count
        var running = BrokerTotals(people: [Double](repeating: 0, count: n), links: [Double](repeating: 0, count: workplace.edgeCount))
        totals = [running]
        for a in 0 ..< n {
            for b in a + 1 ..< n {
                let paths = shortestPaths(between: officeSeats[a].name, and: officeSeats[b].name)
                let share = 1 / Double(paths.count)
                var credit = [Double](repeating: 0, count: n)
                for path in paths {
                    for person in path.people.dropFirst().dropLast() { credit[officeSeat[person]!] += share }
                    for link in path.links { running.links[link] += share }
                }
                for v in 0 ..< n { running.people[v] += credit[v] }
                pairs.append(OfficePair(a: a, b: b, paths: paths, brokers: (0 ..< n).filter { credit[$0] > 0 }.map { ($0, credit[$0]) }))
                totals.append(running)
            }
        }
        let answer = workplaceBetweenness()
        grafluentPeople = officeSeats.map { answer.people.score(of: $0.name) }
        grafluentLinks = workplace.edges.indices.map { answer.links.score(ofEdgeAt: $0) }
        busiest = answer.busiest
        playback.reset(count: pairs.count)
    }
}

let betweennessModel = BetweennessModel()

func describePair(_ pair: OfficePair) -> String {
    let a = officeSeats[pair.a].name, b = officeSeats[pair.b].name
    let hops = pair.paths[0].links.count
    if hops == 1 { return "\(a) and \(b) talk directly. Nobody is in between." }
    let routes = pair.paths.map { $0.people.joined(separator: " → ") }
    let credits = guestList(pair.brokers.map { "\(officeSeats[$0.person].name) \(shareText($0.share))" })
    if pair.paths.count == 1 {
        let middle = pair.brokers.map { officeSeats[$0.person].name }
        return "The shortest way from \(a) to \(b) is \(routes[0]). " + (middle.count == 1 ? "\(middle[0]) is in the middle and gets 1." : "\(guestList(middle)) are in the middle, and each gets 1.")
    }
    return "\(a) and \(b) have \(pair.paths.count) shortest ways, \(guestList(routes)). Each way counts 1/\(pair.paths.count). That gives \(credits)."
}

@View
struct BetweennessLab {
    var body: some View {
        let model = betweennessModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.pairs.count
        let pair = k > 0 && !finished ? model.pairs[k - 1] : nil
        let state = model.totals[k]
        let onPath = Set(pair?.paths.flatMap(\.links) ?? [])
        let brokers = Set(pair?.brokers.map(\.person) ?? [])
        let top = state.people.max() ?? 0
        let busiestLink = workplace.edges.indices.firstIndex { workplace.edges[$0] == model.busiest } ?? -1
        let nodes = officeSeats.enumerated().map { v, seat in
            CanvasNode(x: seat.x, y: seat.y, name: seat.name, badge: state.people[v] > 0 ? shareText(state.people[v]) : "",
                       radius: 15 + 13 * (top > 0 ? (state.people[v] / top).squareRoot() : 0),
                       classes: v == pair?.a || v == pair?.b ? "frontier" : brokers.contains(v) ? "visited current" : state.people[v] > 0 ? "visited" : "",
                       nameAbove: seat.y < 150)
        }
        let edges = workplace.edges.indices.map { link in
            let edge = workplace.edges[link]
            return CanvasEdge(from: officeSeat[edge.u]!, to: officeSeat[edge.v]!, label: state.links[link] > 0 ? shareText(state.links[link]) : "",
                              classes: onPath.contains(link) ? "active" : finished && link == busiestLink ? "route" : "")
        }
        let ranked = officeSeats.indices.sorted { (-state.people[$0], $0) < (-state.people[$1], $1) }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The office")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Nine people in an office, a line between each pair who talk", width: 660, height: 420, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "the pair" }
                        span { i(.class("line active")) {}; "their shortest paths" }
                        span { i(.class("dot visited")) {}; "a broker, sized by score" }
                        span { i(.class("line route")) {}; "the busiest link" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "All \(model.pairs.count) pairs counted" : k == 0 ? "\(model.pairs.count) pairs to count" : "Pair \(k) of \(model.pairs.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "For each pair of people, find the shortest chains of conversations between them. Everyone in the middle of a chain gets a share of a point. A person’s total is their betweenness. Press Step for the first pair."
                            } else if finished {
                                "Every pair is counted. \(officeSeats[ranked[0]].name) scores highest, with \(shareText(state.people[ranked[0]])). Most news in the office passes through \(officeSeats[ranked[0]].name). The busiest link is \(model.busiest.u)–\(model.busiest.v), with \(shareText(model.grafluentLinks[busiestLink])). "
                                "These totals are exactly what "
                                code { "betweennessCentrality" }
                                " and "
                                code { "edgeBetweennessCentrality" }
                                " return."
                            } else {
                                describePair(model.pairs[k - 1])
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Betweenness so far" }
                        div(.class("bars")) {
                            for v in ranked {
                                div(.class(state.people[v] == top && top > 0 ? "bar top" : "bar")) {
                                    span { officeSeats[v].name }
                                    span(.class("track")) {
                                        span(.class("fill"), .style("width: \(top > 0 ? Int((state.people[v] / max(top, model.grafluentPeople.max() ?? 1) * 100).rounded()) : 0)%; display: block;")) {}
                                    }
                                    span(.class("num")) { shareText(state.people[v]) }
                                }
                            }
                        }
                        if finished {
                            p(.class("note")) {
                                model.grafluentPeople.indices.allSatisfy { abs(model.grafluentPeople[$0] - state.people[$0]) < 1e-9 }
                                    ? "Grafluent’s betweennessCentrality(normalized: false) gives the same numbers."
                                    : "Grafluent’s betweennessCentrality(normalized: false) disagrees."
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
                    marbles: model.pairs.map { pair in
                        let title = describePair(pair)
                        if pair.brokers.isEmpty { return Marble(kind: "m-grey", radius: 4, title: title) }
                        return pair.paths.count == 1
                            ? Marble(kind: "m-blue", radius: 9, letter: "\(pair.brokers.count)", title: title)
                            : Marble(kind: "m-violet", radius: 9, letter: "\(pair.paths.count)", title: title)
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "one shortest path, with how many in the middle"),
                        (Marble(kind: "m-violet", radius: 6), "several, with how many share the credit"),
                        (Marble(kind: "m-grey", radius: 3.5), "the pair talk directly"),
                    ])
                p(.class("note")) { "Each step is one pair, with its shortest paths from shortestSimplePaths. The numbers on the links are edge betweenness so far." }
            }
        }
    }
}

@View
struct BetweennessCodePanel {
    var body: some View {
        let model = betweennessModel
        let k = model.playback.k
        let pair = model.pairs[max(k, 1) - 1]
        let busiest = model.busiest
        CodePanel(
            snippets: [
                .betweennessImports, .betweennessWorkplace,
                Snippet(lines: ["let a = \"\(officeSeats[pair.a].name)\"", "let b = \"\(officeSeats[pair.b].name)\""]),
                .betweennessPair, .betweennessScores,
            ],
            results: [
                shareText(model.grafluentPeople[officeSeat["Eve"]!]),
                shareText(model.grafluentPeople[officeSeat["Dev"]!]),
                "UndirectedEdge(\"\(busiest.u)\", \"\(busiest.v)\")",
            ])
    }
}

enum BetweennessPage {
    static func mount() {
        mountView(BetweennessLab(), in: "app")
        mountView(BetweennessCodePanel(), in: "code")
    }
}
