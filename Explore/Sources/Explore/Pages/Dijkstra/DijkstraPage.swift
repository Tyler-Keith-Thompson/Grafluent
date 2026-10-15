import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import ShortestPaths

/// Each place and where it sits on the map, in SVG units of the 640 × 520 view box.
let places: [(name: String, x: Double, y: Double)] = [
    ("Home", 80, 290), ("Bakery", 210, 160), ("Park", 230, 370), ("School", 380, 90),
    ("Library", 390, 280), ("Café", 540, 180), ("Market", 370, 450), ("Station", 560, 390),
]

/// The index in `places` of each place's name.
let placeIndex: [String: Int] = Dictionary(uniqueKeysWithValues: places.enumerated().map { ($0.element.name, $0.offset) })

/// One marble on the timeline, read off Grafluent's Dijkstra events: a place settled (an
/// `examine` event), or a street checked into a place not yet settled (an `examineEdge` event
/// followed by `edgeRelaxed` or `edgeNotRelaxed`). Places are indices into `places`, streets are
/// edge positions in `town`.
enum DijkstraStep {
    case settle(place: Int, distance: Int)
    case check(from: Int, to: Int, street: Int, offer: Int, previous: Int?, better: Bool)

    /// The place the step is about: the one settled, or the one across the street.
    var place: Int {
        switch self {
        case .settle(let place, _): place
        case .check(_, let to, _, _, _, _): to
        }
    }
}

/// What the map shows after the first `k` steps.
struct DijkstraSnapshot {
    var distance: [Int?]
    var settled: [Bool]
    /// The street each place was last reached by.
    var parent: [Int?]
}

/// The Dijkstra page's state: the start, the destination, the timeline from the start, and the
/// playhead.
@Reactive
final class DijkstraModel {
    var source = placeIndex["Home"]!
    /// The place whose walk is drawn when the search is done; -1 for none.
    var target = placeIndex["Station"]!
    var steps: [DijkstraStep] = []
    /// Every event of the search, for the code panel.
    var events: [TownSearchEvent] = []
    @ReactiveIgnored let playback = Playback()

    init() {
        start(source)
    }

    /// Runs Grafluent's Dijkstra search from `place` and rewinds to the start.
    func start(_ place: Int) {
        source = place
        events = townSearch(from: places[place].name)
        steps = DijkstraModel.timeline(events)
        playback.reset(count: steps.count)
        setProperty(id: "source", "value", to: "\(place)")
    }

    /// The marbles of `events`: each settled place, and each street checked into a place not yet
    /// settled with the guess it offered and the guess it met.
    static func timeline(_ events: [TownSearchEvent]) -> [DijkstraStep] {
        var steps: [DijkstraStep] = []
        var guess = [Int?](repeating: nil, count: places.count)
        var offer = 0
        for event in events {
            switch event {
            case .discover(let v, let d):
                guess[placeIndex[v]!] = guess[placeIndex[v]!] ?? d
            case .examine(let v, let d):
                steps.append(.settle(place: placeIndex[v]!, distance: d))
            case .examineEdge(_, let d):
                offer = d
            case .edgeRelaxed(let arc, let d), .edgeNotRelaxed(let arc, let d):
                let from = placeIndex[town.directedView.source(ofEdgeAt: arc)]!
                let to = placeIndex[town.directedView.target(ofEdgeAt: arc)]!
                let better: Bool
                if case .edgeRelaxed = event { better = true } else { better = false }
                steps.append(.check(from: from, to: to, street: arc.position, offer: offer, previous: guess[to], better: better))
                if better { guess[to] = d }
            case .finish:
                break
            }
        }
        return steps
    }

    /// The map after the first `k` steps.
    func snapshot(_ k: Int) -> DijkstraSnapshot {
        var state = DijkstraSnapshot(distance: [Int?](repeating: nil, count: places.count), settled: [Bool](repeating: false, count: places.count), parent: [Int?](repeating: nil, count: places.count))
        state.distance[source] = 0
        for step in steps.prefix(k) {
            switch step {
            case .settle(let place, _):
                state.settled[place] = true
            case .check(_, let to, let street, let offer, _, let better):
                if better {
                    state.distance[to] = offer
                    state.parent[to] = street
                }
            }
        }
        return state
    }

    /// The streets of the walk from the source to `target`, by parent streets.
    func walk(to target: Int, in state: DijkstraSnapshot) -> Set<Int> {
        var streets = Set<Int>()
        var v = target
        while v != source, let street = state.parent[v] {
            streets.insert(street)
            let edge = town.edges[street]
            v = placeIndex[edge.u == places[v].name ? edge.v : edge.u]!
        }
        return streets
    }
}

let dijkstra = DijkstraModel()

/// `∞` or `n min`.
func minutesText(_ d: Int?) -> String {
    d.map { "\($0) min" } ?? "∞"
}

/// The sentence for one step, as the narration and a marble's tooltip give it.
func describe(_ step: DijkstraStep) -> String {
    switch step {
    case .settle(let place, let d):
        return d == 0
            ? "Start at \(places[place].name). It takes 0 minutes to be where you already are, so it is settled first."
            : "\(places[place].name) has the smallest guess on the frontier, \(d) min. Nothing quicker can still arrive, so it is settled."
    case .check(let from, let to, let street, let offer, let previous, let better):
        let w = minutes[town.edges[street]]!
        let via = "\(places[from].name) → \(places[to].name)"
        return better
            ? "Check \(via): \(offer - w) + \(w) = \(offer) min, which beats \(minutesText(previous)). \(places[to].name)’s guess drops to \(offer) min."
            : "Check \(via): \(offer - w) + \(w) = \(offer) min, which doesn’t beat \(minutesText(previous)). Nothing changes."
    }
}

/// The map, the panels beside it, and the playback controls with the timeline.
@View
struct DijkstraLab {
    var body: some View {
        let model = dijkstra
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let state = model.snapshot(k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let tree = Set(state.parent.compactMap { $0 })
        let route = finished && model.target >= 0 ? model.walk(to: model.target, in: state) : []
        let activeStreet = last.flatMap { step -> Int? in
            if case .check(_, _, let street, _, _, _) = step { return street }
            return nil
        } ?? -1
        let frontier = (0 ..< places.count)
            .filter { !state.settled[$0] && state.distance[$0] != nil }
            .sorted { (state.distance[$0]!, $0) < (state.distance[$1]!, $1) }
        let settledOrder = steps.prefix(k).compactMap { step -> (place: Int, distance: Int)? in
            if case .settle(let place, let d) = step { return (place, d) }
            return nil
        }
        let nodes = places.enumerated().map { i, place in
            CanvasNode(
                x: place.x, y: place.y, name: place.name, note: state.distance[i].map { "\($0) min" } ?? "",
                classes: (state.settled[i] ? "visited" : state.distance[i] != nil ? "frontier" : "")
                    + (i == model.source ? " source" : "") + (last?.place == i ? " current" : ""))
        }
        let edges = town.edges.indices.map { street in
            let edge = town.edges[street]
            return CanvasEdge(
                from: placeIndex[edge.u]!, to: placeIndex[edge.v]!, label: "\(minutes[edge]!)",
                classes: (route.contains(street) ? "route" : tree.contains(street) ? "tree" : "") + (street == activeStreet ? " active" : ""))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Interactive map")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Map of a small town: places joined by streets labelled with walking minutes", width: 640, height: 520,
                                nodes: nodes, edges: edges, onNode: { dijkstra.start($0) }, nodeAction: "Start at")
                    div(.class("legend")) {
                        span { i(.class("dot")) {}; "not reached yet" }
                        span { i(.class("dot frontier")) {}; "frontier: a best guess so far" }
                        span { i(.class("dot visited")) {}; "settled: the quickest is known" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Every place starts unknown except \(places[model.source].name), which takes no time to reach. Press Step to begin."
                            } else if finished {
                                "Every place is settled. The blue streets form the "
                                em { "shortest-path tree" }
                                ": each place reached the quickest way from \(places[model.source].name)."
                                if model.target >= 0 && model.target != model.source {
                                    " The red line is the quickest walk to \(places[model.target].name): \(state.distance[model.target].map { "\($0)" } ?? "∞") min."
                                }
                            } else {
                                describe(last!)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Frontier, quickest first" }
                        div(.class("queue")) {
                            if frontier.isEmpty {
                                p(.class("empty")) { finished ? "Empty: nothing left to settle." : "Empty" }
                            }
                            for (j, place) in frontier.enumerated() {
                                div(.class(j == 0 ? "qrow top" : "qrow")) {
                                    span { places[place].name + (j == 0 ? " · next" : "") }
                                    span(.class("num")) { "\(state.distance[place]!) min" }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Settled" }
                        div(.class("chips")) {
                            if settledOrder.isEmpty {
                                p(.class("empty")) { "None yet" }
                            }
                            for entry in settledOrder {
                                span(.class("chip")) {
                                    "\(places[entry.place].name) "
                                    span(.class("num")) { "\(entry.distance)" }
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
                    label(.class("field"), .for("source")) {
                        "Start at "
                        select(.id("source")) {
                            for (i, place) in places.enumerated() {
                                option(.value("\(i)")) { place.name }.attributes(.selected, when: i == model.source)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let place = Int(value) { dijkstra.start(place) }
                        }
                    }
                    label(.class("field"), .for("target")) {
                        "Show the walk to "
                        select(.id("target")) {
                            option(.value("-1")) { "none" }.attributes(.selected, when: model.target == -1)
                            for (i, place) in places.enumerated() {
                                option(.value("\(i)")) { place.name }.attributes(.selected, when: i == model.target)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let place = Int(value) { dijkstra.target = place }
                        }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { step in
                        switch step {
                        case .settle(let place, _): Marble(kind: "m-blue", radius: 11, letter: String(places[place].name.prefix(1)), title: describe(step))
                        case .check(_, _, _, _, _, let better): better ? Marble(kind: "m-ring", radius: 7, title: describe(step)) : Marble(kind: "m-grey", radius: 4, title: describe(step))
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a place is settled"),
                        (Marble(kind: "m-ring", radius: 5), "a street gives a quicker guess"),
                        (Marble(kind: "m-grey", radius: 3.5), "a street is checked, not quicker"),
                    ])
                p(.class("note")) { "Click any place to start from it. Numbers on the streets are walking minutes." }
            }
        }
    }
}

/// The code panel: the town, the search and the walk, as the page runs them.
@View
struct DijkstraCodePanel {
    var body: some View {
        let model = dijkstra
        let start = places[model.source].name
        let goal = model.target >= 0 && model.target != model.source
            ? places[model.target].name
            : (start == "Station" ? "Home" : "Station")
        let walk = quickestWalk(from: start, to: goal)
        CodePanel(
            snippets: [
                .dijkstraImports, .dijkstraTown,
                Snippet(lines: ["let start = \"\(start)\"", "let goal = \"\(goal)\""]),
                .dijkstraSearch, .dijkstraWalk,
            ],
            results: [
                "\(model.events.count) events",
                walk.minutes.map { "\($0)" } ?? "nil",
                "[" + walk.stops.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

enum DijkstraPage {
    static func mount() {
        mountView(DijkstraLab(), in: "app")
        mountView(DijkstraCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.dijkstra, Names.kruskal, Names.boruvka, Names.erdosRenyi, Names.konig, Names.hierholzer, Names.tarjan]), in: "names")
    }
}
