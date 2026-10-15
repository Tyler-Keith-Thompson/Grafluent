import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import ShortestPaths

/// Each place and where it sits on the map, in SVG units of the 640 × 470 view box.
let crosstownSpots: [(name: String, x: Double, y: Double)] = [
    ("Home", 60, 235), ("Mill", 185, 85), ("Bridge", 185, 385), ("Square", 320, 235), ("Museum", 345, 70),
    ("Market", 345, 400), ("Harbor", 480, 135), ("Park", 480, 330), ("Stadium", 590, 235),
]

let crosstownIndex: [String: Int] = Dictionary(uniqueKeysWithValues: crosstownSpots.enumerated().map { ($0.element.name, $0.offset) })

/// One route from the sequence, and how it relates to the routes before it: the earlier route it
/// shares the longest opening with, and how many stops that opening has.
struct KRoute {
    var stops: [String]
    var roads: [Int]
    var minutes: Int
    /// The offset of the earlier route it leaves, or nil for the first.
    var parent: Int?
    /// The stops it shares with `parent` before turning off; the last is where it turns.
    var shared: Int
}

@Reactive
final class KPathsModel {
    var start = "Home"
    var goal = "Stadium"
    var count = 8
    var routes: [KRoute] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-kpaths")

    init() {
        run()
    }

    /// Asks for the first `count` routes and rewinds.
    func run() {
        var found: [KRoute] = []
        for route in alternativeRoutes(from: start, to: goal, count: count) {
            var parent: Int?
            var shared = 0
            for (j, earlier) in found.enumerated() {
                let common = zip(earlier.stops, route.stops).prefix { $0 == $1 }.count
                if common > shared { shared = common; parent = j }
            }
            found.append(KRoute(stops: route.stops, roads: route.roads, minutes: route.minutes, parent: parent, shared: shared))
        }
        routes = found
        playback.reset(count: routes.count)
        setProperty(id: "kpaths-start", "value", to: start)
        setProperty(id: "kpaths-goal", "value", to: goal)
    }

    func choose(start: String? = nil, goal: String? = nil) {
        if let start { self.start = start }
        if let goal { self.goal = goal }
        if self.start == self.goal {
            self.goal = crosstownSpots.map(\.name).last { $0 != self.start }!
        }
        run()
    }
}

let kpathsModel = KPathsModel()

/// `Home → Mill → Square`.
func stopList(_ stops: [String]) -> String { stops.joined(separator: " → ") }

func describeRoute(_ n: Int, _ routes: [KRoute]) -> String {
    let route = routes[n]
    let head = "Route \(n + 1), \(route.minutes) min: \(stopList(route.stops))."
    guard let parent = route.parent else {
        return head + " The quickest of all, found by one shortest-path search."
    }
    let turn = route.stops[route.shared - 1]
    let extra = route.minutes - routes[0].minutes
    let slower = extra == 0 ? "It ties the quickest." : "It is \(extra) min slower than the quickest."
    let detour = route.shared == 1
        ? " It leaves \(turn) a different way, by \(route.stops[1]). "
        : " It follows route \(parent + 1) as far as \(turn), then turns off to \(route.stops[route.shared]). "
    return head + detour + slower
}

@View
struct KPathsLab {
    var body: some View {
        let model = kpathsModel
        let playback = model.playback
        let k = playback.k
        let routes = model.routes
        let finished = k == routes.count
        let current = k > 0 ? routes[k - 1] : nil
        let onRoute = Set(current?.roads ?? [])
        let spur = Set(current.map { Array($0.roads.dropFirst($0.parent == nil ? $0.roads.count : $0.shared - 1)) } ?? [])
        let parentRoads = Set(current?.parent.map { routes[$0].roads } ?? [])
        let turn = current.flatMap { route in route.parent == nil ? nil : route.stops[route.shared - 1] }
        let stops = Set(current?.stops ?? [])
        let nodes = crosstownSpots.map { spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 15,
                       classes: (stops.contains(spot.name) || spot.name == model.start || spot.name == model.goal ? "visited" : "")
                           + (spot.name == model.start ? " source" : "") + (spot.name == turn ? " selected" : ""),
                       nameAbove: spot.y < 100)
        }
        let edges = crosstown.edges.indices.map { road in
            let edge = crosstown.edges[road]
            return CanvasEdge(
                from: crosstownIndex[edge.u]!, to: crosstownIndex[edge.v]!, label: "\(driveMinutes[edge]!)",
                classes: spur.contains(road) ? "active" : onRoute.contains(road) ? "route" : parentRoads.contains(road) ? "tree" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Alternative routes")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Map of a town: places joined by roads labelled with driving minutes", width: 640, height: 470,
                                nodes: nodes, edges: edges, onNode: { kpathsModel.choose(goal: crosstownSpots[$0].name) }, nodeAction: "Drive to")
                    div(.class("legend")) {
                        span { i(.class("line route")) {}; "this route" }
                        span { i(.class("line active")) {}; "where it turns off" }
                        span { i(.class("line tree")) {}; "the earlier route it leaves" }
                        span { i(.class("dot selected")) {}; "the turning point" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "All \(routes.count) routes" : k == 0 ? "\(routes.count) routes to come" : "Route \(k) of \(routes.count)" }
                        p(.class("narration")) {
                            if routes.isEmpty {
                                "There is no way from \(model.start) to \(model.goal)."
                            } else if k == 0 {
                                "The first \(routes.count) routes from \(model.start) to \(model.goal), none visiting a place twice, quickest first. Press Step to take the next one from the sequence."
                            } else {
                                describeRoute(k - 1, routes)
                                if finished {
                                    " The sequence would go on, each route a little slower or tied, until every loop-free route is listed."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Routes so far, quickest first" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for (j, route) in routes.prefix(k).enumerated() {
                                div(.class(j == k - 1 ? "qrow top" : "qrow")) {
                                    span { "\(j + 1). " + route.stops.dropFirst().dropLast().joined(separator: ", ") }
                                    span(.class("num")) { "\(route.minutes) min" }
                                }
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    label(.class("field"), .for("kpaths-start")) {
                        "From "
                        select(.id("kpaths-start")) {
                            for spot in crosstownSpots {
                                option(.value(spot.name)) { spot.name }.attributes(.selected, when: spot.name == model.start)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue { kpathsModel.choose(start: value) }
                        }
                    }
                    label(.class("field"), .for("kpaths-goal")) {
                        "to "
                        select(.id("kpaths-goal")) {
                            for spot in crosstownSpots {
                                option(.value(spot.name)) { spot.name }.attributes(.selected, when: spot.name == model.goal)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue { kpathsModel.choose(goal: value) }
                        }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: routes.indices.map { j in
                        Marble(kind: j == 0 ? "m-blue" : routes[j].minutes == routes[0].minutes ? "m-hollow" : "m-ring", radius: 11,
                               letter: "\(j + 1)", title: describeRoute(j, routes))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "the quickest route"),
                        (Marble(kind: "m-hollow", radius: 6), "a route tied with it"),
                        (Marble(kind: "m-ring", radius: 6), "a slower route"),
                    ])
                p(.class("note")) { "The page takes the first \(model.count) routes from the lazy sequence, and each step shows the next of them. Click any place to drive there instead." }
            }
        }
    }
}

@View
struct KPathsCodePanel {
    var body: some View {
        let model = kpathsModel
        let routes = model.routes
        CodePanel(
            snippets: [
                .kpathsImports, .kpathsTown,
                Snippet(lines: ["let start = \"\(model.start)\"", "let goal = \"\(model.goal)\"", "let count = \(model.count)"]),
                .kpathsRoutes,
            ],
            results: [
                "\(routes.count) routes",
                "[" + routes.map { "\($0.minutes)" }.joined(separator: ", ") + "]",
                "[" + (routes.first?.stops ?? []).map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

enum KPathsPage {
    static func mount() {
        mountView(KPathsLab(), in: "app")
        mountView(KPathsCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.yen, Names.dijkstra]), in: "names")
    }
}
