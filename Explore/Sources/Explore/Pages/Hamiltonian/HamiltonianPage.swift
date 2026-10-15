import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Walks

/// Every place on the board, outer ring first, and where it sits, in SVG units of the 640 × 500
/// view box: the outer and inner rings are pentagons, the middle ring a decagon between them,
/// all centred on (320, 255).
let boardSpots: [(name: String, x: Double, y: Double)] = [
    ("B", 320, 30), ("C", 534, 185), ("D", 452, 437), ("F", 188, 437), ("G", 106, 185),
    ("H", 320, 110), ("J", 405, 138), ("K", 458, 210), ("L", 458, 300), ("M", 405, 372),
    ("N", 320, 400), ("P", 235, 372), ("Q", 182, 300), ("R", 182, 210), ("S", 235, 138),
    ("T", 362, 197), ("V", 388, 277), ("W", 320, 327), ("X", 252, 277), ("Z", 278, 197),
]

/// The index in `boardSpots` of each place's name.
let boardIndex: [String: Int] = Dictionary(uniqueKeysWithValues: boardSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each road, as offsets in `boardSpots`, by position in `icosian`.
let boardEnds: [(Int, Int)] = icosian.edges.map { (boardIndex[$0.u]!, boardIndex[$0.v]!) }

/// Whether places `a` and `b` are joined.
func boardAdjacent(_ a: Int, _ b: Int) -> Bool {
    boardEnds.contains { ($0.0 == a && $0.1 == b) || ($0.0 == b && $0.1 == a) }
}

/// The roads along `route`, as canvas edges with `classes`, closed back to its start when `closed`.
func routeEdges(_ route: [Int], closed: Bool, classes: String) -> [CanvasEdge] {
    let count = closed ? route.count : route.count - 1
    return (0 ..< max(0, count)).map { CanvasEdge(from: route[$0], to: route[($0 + 1) % route.count], classes: classes) }
}

/// One step of the backtracking search: a place added to the route, a place taken off it, or the
/// road home that closes the cycle.
enum IcosianStep {
    case extend(Int)
    case retreat(Int)
    case close
}

/// The Hamiltonian page's state: the route someone is drawing, the search's steps, and the
/// playhead.
@Reactive
final class HamiltonianModel {
    /// The route so far, as offsets in `boardSpots`: Hamilton's game starts with five places chosen.
    var route = ["B", "C", "D", "F", "G"].map { boardIndex[$0]! }
    var showFinish = false
    var message = ""
    @ReactiveIgnored let steps: [IcosianStep]
    @ReactiveIgnored let cycle = icosianCycle()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 250, scrubID: "scrub-icosian")

    init() {
        steps = HamiltonianModel.search()
        playback.reset(count: steps.count)
    }

    /// Plain backtracking from B, trying each place's neighbours in `neighbors(of:)` order, until
    /// a route through every place ends next to B.
    static func search() -> [IcosianStep] {
        let n = boardSpots.count
        let neighbours = boardSpots.map { spot in icosian.neighbors(of: spot.name).map { boardIndex[$0]! } }
        var steps: [IcosianStep] = [.extend(0)]
        var route = [0]
        var onRoute = [Bool](repeating: false, count: n)
        onRoute[0] = true
        // For each place on the route, the next neighbour to try.
        var cursor = [0]
        while let last = route.last {
            if route.count == n && neighbours[last].contains(0) {
                steps.append(.close)
                return steps
            }
            let row = neighbours[last]
            var next = -1
            while cursor[cursor.count - 1] < row.count {
                let w = row[cursor[cursor.count - 1]]
                cursor[cursor.count - 1] += 1
                if !onRoute[w] { next = w; break }
            }
            if next >= 0 && route.count < n {
                route.append(next)
                onRoute[next] = true
                cursor.append(0)
                steps.append(.extend(next))
            } else {
                route.removeLast()
                cursor.removeLast()
                onRoute[last] = false
                steps.append(.retreat(last))
                if route.isEmpty { return steps }
            }
        }
        return steps
    }

    /// The route after the first `k` steps.
    func route(after k: Int) -> (route: [Int], closed: Bool) {
        var route: [Int] = []
        var closed = false
        for step in steps.prefix(k) {
            switch step {
            case .extend(let v): route.append(v)
            case .retreat: route.removeLast()
            case .close: closed = true
            }
        }
        return (route, closed)
    }

    /// Someone clicked place `v`: start there, step to it, or take the last place back.
    func click(_ v: Int) {
        showFinish = false
        if route.isEmpty { route = [v]; message = ""; return }
        if v == route.last { route.removeLast(); message = ""; return }
        if route.contains(v) {
            message = "\(boardSpots[v].name) is already on the route: each place is visited once."
        } else if !boardAdjacent(route.last!, v) {
            message = "\(boardSpots[v].name) isn’t next to \(boardSpots[route.last!].name)."
        } else {
            route.append(v)
            message = ""
        }
    }

    func clear() {
        route = []
        showFinish = false
        message = ""
    }

    /// A way to finish the route, from Grafluent, as offsets in `boardSpots`; nil when there is
    /// none. A route of one place asks for a whole cycle.
    var finish: [Int]? {
        guard let first = route.first, let last = route.last else { return nil }
        if route.count == 1 {
            return cycle.map { c in
                let names = c.vertices.map { boardIndex[$0]! }
                let at = names.firstIndex(of: first)!
                return Array(names[at...] + names[..<at]) + [first]
            }
        }
        let inside = Set(route.dropFirst().dropLast().map { boardSpots[$0].name })
        return icosianFinish(first: boardSpots[first].name, current: boardSpots[last].name, inside: inside)?.vertices.map { boardIndex[$0]! }
    }
}

let hamiltonianModel = HamiltonianModel()

/// The board with the route being drawn.
@View
struct IcosianLab {
    var body: some View {
        let model = hamiltonianModel
        let route = model.route
        let finish = model.finish
        let complete = route.count == boardSpots.count && boardAdjacent(route.last!, route[0])
        let nodes = boardSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: "", badge: spot.name, radius: 15,
                classes: (route.contains(v) ? "visited" : "") + (v == route.first ? " source" : "") + (v == route.last && !complete ? " current" : ""))
        }
        let edges = boardEnds.map { CanvasEdge(from: $0.0, to: $0.1) }
            + routeEdges(route, closed: complete, classes: "tree")
            + (model.showFinish && !complete ? routeEdges(finish ?? [], closed: false, classes: "route") : [])

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Hamilton’s icosian game")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The dodecahedron flattened: twenty places, each joined to three others", width: 640, height: 500,
                                nodes: nodes, edges: edges, onNode: { hamiltonianModel.click($0) }, nodeAction: "Go to")
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "on the route" }
                        span { i(.class("line tree")) {}; "the route" }
                        span { i(.class("line route")) {}; "a way to finish, from Grafluent" }
                    }
                    p(.class("note")) { "Click a place next to the end of the route to go there; click the end to take it back." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { complete ? "Solved" : "\(route.count) of \(boardSpots.count) places" }
                        p(.class("narration")) {
                            if complete {
                                "Every place once, and back to \(boardSpots[route[0]].name): a Hamiltonian cycle."
                            } else if route.isEmpty {
                                "Click any place to start a route."
                            } else if !model.message.isEmpty {
                                model.message
                            } else if finish == nil {
                                "Stuck: there is no way to visit every place left and get back to \(boardSpots[route[0]].name) from here. Take some places back."
                            } else if route.count == 5 && route.map({ boardSpots[$0].name }) == ["B", "C", "D", "F", "G"] {
                                "Hamilton’s game: one player chooses the first five places, B C D F G here, and the other must finish the round, visiting every place once and returning to B. It can be done from here."
                            } else {
                                "The route can still be finished: there is a way through every place left and back to \(boardSpots[route[0]].name)."
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            button(.type(.button)) { model.showFinish ? "Hide the finish" : "Show a finish" }
                                .onClick { hamiltonianModel.showFinish.toggle() }
                                .attributes(.disabled, when: finish == nil || complete)
                            button(.type(.button)) { "Clear" }
                                .onClick { hamiltonianModel.clear() }
                        }
                        p(.class("note")) {
                            "The route so far: " + (route.isEmpty ? "none" : route.map { boardSpots[$0].name }.joined(separator: " "))
                        }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct IcosianCodePanel {
    var body: some View {
        let model = hamiltonianModel
        let route = model.route
        if route.count >= 2 {
            let finish = model.finish
            CodePanel(
                snippets: [
                    .hamiltonianImports, .hamiltonianBoard,
                    Snippet(lines: [
                        "let first = \"\(boardSpots[route[0]].name)\", current = \"\(boardSpots[route.last!].name)\"",
                        "let inside: Set = [" + route.dropFirst().dropLast().map { "\"\(boardSpots[$0].name)\"" }.joined(separator: ", ") + "]",
                    ]),
                    .hamiltonianFinish,
                ],
                results: [finish.map { $0.map { boardSpots[$0].name }.joined(separator: " → ") } ?? "nil"])
        } else {
            CodePanel(
                snippets: [.hamiltonianImports, .hamiltonianBoard, .hamiltonianCycle],
                results: [model.cycle.map { $0.vertices.joined(separator: " → ") } ?? "nil"])
        }
    }
}

/// The sentence for one step of the search.
func describeIcosianStep(_ step: IcosianStep, after route: [Int]) -> String {
    switch step {
    case .extend(let v):
        return route.count == 1
            ? "Start at \(boardSpots[v].name)."
            : "Go on to \(boardSpots[v].name), the first neighbour not yet on the route: \(route.count) places."
    case .retreat(let v):
        return "\(boardSpots[v].name) leads nowhere new that works. Take it off the route and try the next neighbour of \(route.last.map { boardSpots[$0].name } ?? "the start")."
    case .close:
        return "Every place is on the route, and the last, \(boardSpots[route.last!].name), is next to \(boardSpots[route[0]].name). Close the cycle."
    }
}

/// The backtracking search, one step at a time.
@View
struct IcosianSearchLab {
    var body: some View {
        let model = hamiltonianModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let (route, closed) = model.route(after: k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let retreats = steps.prefix(k).filter { if case .retreat = $0 { return true } else { return false } }.count
        let retreated: Int = { if case .retreat(let v)? = last { return v } else { return -1 } }()
        let matches = model.cycle.map { Cycle(route.map { boardSpots[$0].name }, in: icosian) == $0 } ?? false
        let nodes = boardSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: "", badge: spot.name, radius: 15,
                classes: (v == retreated ? "cut" : route.contains(v) ? "visited" : "") + (v == route.last && !closed ? " current" : ""))
        }
        let edges = boardEnds.map { CanvasEdge(from: $0.0, to: $0.1) } + routeEdges(route, closed: closed, classes: "tree")

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A backtracking search for a Hamiltonian cycle")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The board with the search’s current route", width: 640, height: 500, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "on the route" }
                        span { i(.class("dot cut")) {}; "just taken back" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "A computer has no better idea than to try: go to the first neighbour not yet visited, and when that leads nowhere, take it back and try the next. Press Play to watch."
                            } else {
                                describeIcosianStep(last!, after: route)
                                if finished {
                                    matches ? " The same cycle as icosian.hamiltonianCycle()." : " A different cycle from icosian.hamiltonianCycle()."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "So far" }
                        p(.class("narration")) { "\(route.count) places on the route; \(retreats) taken back." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                }
                Timeline(
                    playback: playback,
                    marbles: steps.enumerated().map { j, step in
                        let title = describeIcosianStep(step, after: model.route(after: j + 1).route)
                        switch step {
                        case .extend: return Marble(kind: "m-blue", radius: 5, title: title)
                        case .retreat: return Marble(kind: "m-red", radius: 5, title: title)
                        case .close: return Marble(kind: "m-green", radius: 10, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 5), "a place added"),
                        (Marble(kind: "m-red", radius: 5), "a place taken back"),
                        (Marble(kind: "m-green", radius: 6), "the cycle closed"),
                    ])
                p(.class("note")) { "The steps are the page’s own plain backtracking, in the order hamiltonianCycle() searches. Grafluent’s search also skips routes that leave a place cut off, so it takes fewer steps to the same cycle, and reports none." }
            }
        }
    }
}

/// The search's code panel.
@View
struct IcosianSearchCodePanel {
    var body: some View {
        CodePanel(snippets: [.hamiltonianImports, .hamiltonianBoard, .hamiltonianCycle],
                  results: [hamiltonianModel.cycle.map { $0.vertices.joined(separator: " → ") } ?? "nil"])
    }
}

enum HamiltonianPage {
    static func mount() {
        mountView(IcosianLab(), in: "app")
        mountView(IcosianCodePanel(), in: "code")
        mountView(IcosianSearchLab(), in: "search")
        mountView(IcosianSearchCodePanel(), in: "code-search")
    }
}
