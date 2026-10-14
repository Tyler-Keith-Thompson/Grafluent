import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import JavaScriptKit
import Reactivity
import ShortestPaths

/// One marble on the timeline, read off Grafluent's Dijkstra events: a place settled (an
/// `examine` event), or a street checked into a place not yet settled (an `examineEdge` event
/// followed by `edgeRelaxed` or `edgeNotRelaxed`). Places are indices into `places`, streets are
/// edge positions in `town`.
enum Step {
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
struct Snapshot {
    var distance: [Int?]
    var settled: [Bool]
    /// The street each place was last reached by.
    var parent: [Int?]
}

/// The explorer's state: the source, the destination, the timeline from the source, and the
/// playhead. Both mounted views read it, so a change redraws whichever depends on it.
@Reactive
final class Explorer {
    var source = placeIndex["Home"]!
    /// The place whose walk is drawn when the search is done; -1 for none.
    var target = placeIndex["Station"]!
    var steps: [Step] = []
    /// Every event of the search, for the code panel.
    var events: [DijkstraSearchEvent<String, DirectedView<UndirectedAdjacencyList<String>>.Edges.Index, Int>] = []
    var k = 0
    var playing = false
    @ReactiveIgnored var timer: JSTimer?

    init() {
        start(source)
    }

    /// Runs Grafluent's Dijkstra search from `place` and rewinds to the start.
    func start(_ place: Int) {
        pause()
        source = place
        events = Array(town.dijkstraSearch(from: places[place].name) { minutes[town.edges[$0]]! })
        steps = Explorer.timeline(events)
        show(0)
        setProperty(id: "source", "value", to: "\(place)")
    }

    /// The marbles of `events`: each settled place, and each street checked into a place not yet
    /// settled with the guess it offered and the guess it met.
    static func timeline(_ events: [DijkstraSearchEvent<String, DirectedView<UndirectedAdjacencyList<String>>.Edges.Index, Int>]) -> [Step] {
        var steps: [Step] = []
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
    func snapshot(_ k: Int) -> Snapshot {
        var state = Snapshot(distance: [Int?](repeating: nil, count: places.count), settled: [Bool](repeating: false, count: places.count), parent: [Int?](repeating: nil, count: places.count))
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

    /// The streets and stops of the walk from the source to `target`, by parent streets.
    func walk(to target: Int, in state: Snapshot) -> (streets: Set<Int>, stops: [String]) {
        var streets = Set<Int>()
        var stops = [places[target].name]
        var v = target
        while v != source, let street = state.parent[v] {
            streets.insert(street)
            let edge = town.edges[street]
            v = placeIndex[edge.u == places[v].name ? edge.v : edge.u]!
            stops.append(places[v].name)
        }
        return (streets, stops.reversed())
    }

    func show(_ n: Int) {
        k = max(0, min(steps.count, n))
        setProperty(id: "scrub", "value", to: "\(k)")
    }

    func play() {
        if k >= steps.count { show(0) }
        playing = true
        timer = JSTimer(millisecondsDelay: 750, isRepeating: true) { [weak self] in
            guard let self else { return }
            if self.k >= self.steps.count { self.pause() } else { self.show(self.k + 1) }
        }
    }

    func pause() {
        timer = nil
        playing = false
    }

    func togglePlay() {
        if playing { pause() } else { play() }
    }

    func step(by offset: Int) {
        pause()
        show(k + offset)
    }

    func setTarget(_ place: Int) {
        target = place
    }
}

/// Sets a DOM property, for the controls whose shown value is the property rather than the
/// attribute once someone has used them: a select's value and a range input's value.
func setProperty(id: String, _ name: String, to value: String) {
    guard let document = JSObject.global.document.object,
          let element = document.getElementById!(id).object else { return }
    element[name] = .string(value)
}
