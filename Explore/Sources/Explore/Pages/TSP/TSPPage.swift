import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Walks

/// The index in `towns` of each town's name.
let townIndex: [String: Int] = Dictionary(uniqueKeysWithValues: towns.enumerated().map { ($0.element.name, $0.offset) })

/// The km between each pair of towns, by offsets in `towns`.
let townKm: [[Int]] = {
    var d = [[Int]](repeating: [Int](repeating: 0, count: towns.count), count: towns.count)
    for (p, road) in tourMap.edges.enumerated() {
        let a = townIndex[road.u]!, b = townIndex[road.v]!
        d[a][b] = km[p]
        d[b][a] = km[p]
    }
    return d
}()

/// Where town `v` is drawn, in SVG units of the 640 × 440 view box: 5 units a km.
func townSpot(_ v: Int) -> (x: Double, y: Double) { (25 + towns[v].x * 5, 25 + towns[v].y * 5) }

/// The length of the closed tour through `order`.
func orderLength(_ order: [Int]) -> Int {
    order.indices.map { townKm[order[$0]][order[($0 + 1) % order.count]] }.reduce(0, +)
}

/// One step of building and improving a tour: a town added by nearest neighbour, the road home
/// that closes the tour, or one 2-opt exchange of two roads for two shorter ones.
enum TourStep {
    case visit(town: Int, km: Int)
    case close(km: Int)
    case exchange(removed: [(Int, Int)], added: [(Int, Int)], saved: Int, order: [Int])
}

/// The tour page's state: the start town, the tour shown, the steps of nearest neighbour then
/// 2-opt, and the playhead.
@Reactive
final class TSPModel {
    var start = 0
    var method = 1
    var menu: [(name: String, tour: TownTour)] = []
    var steps: [TourStep] = []
    /// The nearest-neighbour order, then the order after each 2-opt exchange.
    var greedyOrder: [Int] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-tour")

    init() { run(from: 0) }

    /// Asks Grafluent for every tour from `town`, and works out the steps.
    func run(from town: Int) {
        start = town
        menu = tourMenu(from: towns[town].name)
        greedyOrder = menu[0].tour.vertices.map { townIndex[$0]! }
        var steps: [TourStep] = []
        for j in 1 ..< greedyOrder.count {
            steps.append(.visit(town: greedyOrder[j], km: townKm[greedyOrder[j - 1]][greedyOrder[j]]))
        }
        steps.append(.close(km: townKm[greedyOrder.last!][greedyOrder[0]]))
        steps += TSPModel.twoOpt(greedyOrder)
        self.steps = steps
        playback.reset(count: steps.count)
        setProperty(id: "tsp-start", "value", to: "\(town)")
    }

    func choose(method: Int) {
        self.method = method
        setProperty(id: "tsp-method", "value", to: "\(method)")
    }

    /// 2-opt as twoOptTour(improving:weight:) describes it: each round, the exchange that saves
    /// the most, the first in row-major order on ties, the first town fixed, until none saves
    /// anything.
    static func twoOpt(_ start: [Int]) -> [TourStep] {
        var t = start
        let n = t.count
        var steps: [TourStep] = []
        while true {
            var best = 0, bi = -1, bj = -1
            for i in 0 ..< n - 2 {
                for j in i + 2 ..< n where !(i == 0 && j == n - 1) {
                    let a = t[i], b = t[i + 1], c = t[j], e = t[(j + 1) % n]
                    let gain = (townKm[a][b] + townKm[c][e]) - (townKm[a][c] + townKm[b][e])
                    if gain > best { best = gain; bi = i; bj = j }
                }
            }
            guard bi >= 0 else { return steps }
            let a = t[bi], b = t[bi + 1], c = t[bj], e = t[(bj + 1) % n]
            t[(bi + 1) ... bj].reverse()
            steps.append(.exchange(removed: [(a, b), (c, e)], added: [(a, c), (b, e)], saved: best, order: t))
        }
    }

    /// The tour after the first `k` steps: the towns in order, and whether it is closed yet.
    func state(after k: Int) -> (order: [Int], closed: Bool) {
        let n = greedyOrder.count
        if k < n { return (Array(greedyOrder.prefix(k + 1)), false) }
        if k == n { return (greedyOrder, true) }
        if case .exchange(_, _, _, let order) = steps[k - 1] { return (order, true) }
        return (greedyOrder, true)
    }
}

let tspModel = TSPModel()

/// The roads of the closed tour through `order`, or of the path through it, as canvas edges.
func tourEdges(_ order: [Int], closed: Bool, classes: String = "tree", highlight: [(Int, Int)] = [], highlightClass: String = "active") -> [CanvasEdge] {
    let count = closed ? order.count : order.count - 1
    return (0 ..< max(0, count)).map { j in
        let a = order[j], b = order[(j + 1) % order.count]
        let lit = highlight.contains { ($0.0 == a && $0.1 == b) || ($0.0 == b && $0.1 == a) }
        return CanvasEdge(from: a, to: b, classes: lit ? highlightClass : classes)
    }
}

/// `+12%`.
func percentOver(_ length: Int, _ shortest: Int) -> String {
    length == shortest ? "shortest" : "+\(Int((Double(length - shortest) * 100 / Double(shortest)).rounded()))%"
}

/// The towns with the chosen tour drawn, and every tour's length.
@View
struct TSPLab {
    var body: some View {
        let model = tspModel
        let menu = model.menu
        let chosen = menu[model.method]
        let order = chosen.tour.vertices.map { townIndex[$0]! }
        let shortest = tourLength(menu[4].tour)
        let nodes = towns.indices.map { v in
            CanvasNode(x: townSpot(v).x, y: townSpot(v).y, name: towns[v].name, radius: 12, classes: v == model.start ? "visited source" : "visited")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Tours of eleven towns")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eleven towns with the \(chosen.name.lowercased()) tour drawn; click a town to start from it", width: 640, height: 440,
                                nodes: nodes, edges: tourEdges(order, closed: true), onNode: { tspModel.run(from: $0) }, nodeAction: "Start from")
                    div(.class("legend")) {
                        span { i(.class("dot source")) {}; "where the tour starts" }
                        span { i(.class("line tree")) {}; "the tour" }
                    }
                    p(.class("note")) { "Every pair of towns has a straight road. Click a town to start the nearest-neighbour tour, and the tours improved from it, there." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "\(chosen.name): \(tourLength(chosen.tour)) km" }
                        p(.class("narration")) {
                            switch model.method {
                            case 0: "Always drive to the nearest town not yet visited, then home. Quick, and usually decent, but the last few legs have to take whatever is left."
                            case 1: "Start from the nearest-neighbour tour and keep swapping two roads for two shorter ones, by turning a stretch of the tour around, until no swap helps."
                            case 2: "Random changes to the nearest-neighbour tour, sometimes accepting a worse one so the search can climb out of a dip; a seeded generator makes it the same every time."
                            case 3: "A minimum spanning tree, with its odd towns matched up, walked as an Euler circuit with repeats skipped. Never more than 1.5 times the shortest on straight roads."
                            default: "The shortest of all \(Int((1 ... towns.count - 1).reduce(1, *) / 2)) tours, by Held and Karp’s dynamic programming over subsets of towns."
                            }
                        }
                        label(.class("field"), .for("tsp-method")) {
                            "Show "
                            select(.id("tsp-method")) {
                                for (n, entry) in menu.enumerated() {
                                    option(.value("\(n)")) { entry.name }.attributes(.selected, when: model.method == n)
                                }
                            }
                            .onInput { event in
                                if let value = event.targetValue, let n = Int(value) { tspModel.choose(method: n) }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Every tour from \(towns[model.start].name)" }
                        div(.class("queue")) {
                            for (n, entry) in menu.enumerated() {
                                div(.class(n == model.method ? "qrow top" : "qrow plain")) {
                                    span { entry.name }
                                    span(.class("num")) { "\(tourLength(entry.tour)) km · " + percentOver(tourLength(entry.tour), shortest) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct TSPCodePanel {
    var body: some View {
        let model = tspModel
        CodePanel(
            snippets: [
                .tspImports, .tspTowns, Snippet(lines: ["let start = \"\(towns[model.start].name)\""]), .tspNearest, .tspTwoOpt, .tspMenu,
                Snippet(lines: ["let tour = " + ["greedy", "improved", "annealed", "christofides", "shortest"][model.method]]), .tspLength,
            ],
            results: ["\(tourLength(model.menu[model.method].tour))"])
    }
}

/// The sentence for one step.
func describeTourStep(_ step: TourStep, before: [Int]) -> String {
    switch step {
    case .visit(let town, let km):
        return "From \(towns[before.last!].name), the nearest town not yet visited is \(towns[town].name), \(km) km."
    case .close(let km):
        return "Every town is visited. Drive home to \(towns[before[0]].name), \(km) km: the nearest-neighbour tour is \(orderLength(before)) km."
    case .exchange(let removed, let added, let saved, let order):
        func road(_ r: (Int, Int)) -> String { "\(towns[r.0].name)–\(towns[r.1].name)" }
        return "Swap \(road(removed[0])) and \(road(removed[1])) for \(road(added[0])) and \(road(added[1])), turning the stretch between them around. That saves \(saved) km: \(orderLength(order)) km."
    }
}

/// Nearest neighbour building a tour, then 2-opt improving it, one step at a time.
@View
struct TourStepLab {
    var body: some View {
        let model = tspModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let (order, closed) = model.state(after: k)
        let before = model.state(after: max(0, k - 1)).order
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let library = tourLength(model.menu[1].tour)
        let highlight: [(Int, Int)] = {
            switch last {
            case .visit(let town, _)?: return [(order[order.count - 2], town)]
            case .close?: return [(order.last!, order[0])]
            case .exchange(_, let added, _, _)?: return added
            case nil: return []
            }
        }()
        let removed: [(Int, Int)] = { if case .exchange(let r, _, _, _)? = last { return r } else { return [] } }()
        let visited = Set(order)
        let nodes = towns.indices.map { v in
            CanvasNode(x: townSpot(v).x, y: townSpot(v).y, name: towns[v].name, radius: 12,
                       classes: (visited.contains(v) ? "visited" : "") + (v == model.start ? " source" : "") + (v == order.last && !closed ? " current" : ""))
        }
        let edges = tourEdges(order, closed: closed, highlight: highlight)
            + removed.map { CanvasEdge(from: $0.0, to: $0.1, classes: "faint") }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Building and improving a tour")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The towns, with the tour built so far", width: 640, height: 440, nodes: nodes, edges: edges,
                                onNode: { tspModel.run(from: $0) }, nodeAction: "Start from")
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "visited" }
                        span { i(.class("line active")) {}; "the road just added" }
                        span { i(.class("line faint")) {}; "the roads just swapped out" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Start at \(towns[model.start].name). First build a tour greedily, one nearest town at a time; then improve it with 2-opt, one swap of two roads at a time. Press Step to begin."
                            } else {
                                describeTourStep(last!, before: before)
                                if finished {
                                    orderLength(order) == library
                                        ? " No swap saves anything now: the tour is 2-optimal, \(orderLength(order)) km, as twoOptTour(improving:) found."
                                        : " No swap saves anything now. twoOptTour(improving:) found \(library) km."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { closed ? "Tour length" : "Driven so far" }
                        p(.class("narration")) { b(.class("num")) { "\(closed ? orderLength(order) : zip(order, order.dropFirst()).map { townKm[$0][$1] }.reduce(0, +)) km" } }
                        p(.class("note")) { "The shortest tour is \(tourLength(model.menu[4].tour)) km." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    label(.class("field"), .for("tsp-start")) {
                        "Start at "
                        select(.id("tsp-start")) {
                            for (v, town) in towns.enumerated() {
                                option(.value("\(v)")) { town.name }.attributes(.selected, when: v == model.start)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let v = Int(value) { tspModel.run(from: v) }
                        }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.enumerated().map { j, step in
                        let title = describeTourStep(step, before: model.state(after: j).order)
                        switch step {
                        case .visit(_, let km): return Marble(kind: "m-blue", radius: 3 + Double(km) / 6, title: title)
                        case .close(let km): return Marble(kind: "m-hollow", radius: 3 + Double(km) / 6, title: title)
                        case .exchange(_, _, let saved, _): return Marble(kind: "m-violet", radius: 8, letter: "\(saved)", title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 5), "nearest town added; bigger for farther"),
                        (Marble(kind: "m-hollow", radius: 5), "the road home"),
                        (Marble(kind: "m-violet", radius: 6), "a 2-opt swap, with the km it saves"),
                    ])
                p(.class("note")) { "The first steps replay nearestNeighborTour(from:)’s tour. The swaps are made by the page, the way twoOptTour(improving:) describes its rounds, since the library reports only the finished tour; the last step is checked against it." }
            }
        }
    }
}

/// The steps' code panel.
@View
struct TourStepCodePanel {
    var body: some View {
        let model = tspModel
        let greedy = model.menu[0].tour
        let improved = model.menu[1].tour
        CodePanel(
            snippets: [
                .tspImports, .tspTowns, Snippet(lines: ["let start = \"\(towns[model.start].name)\""]), .tspNearest,
                .tspTwoOpt, Snippet(lines: ["let tour = improved"]), .tspLength,
            ],
            results: ["\(tourLength(improved))  (from \(tourLength(greedy)))"])
    }
}

enum TSPPage {
    static func mount() {
        mountView(TSPLab(), in: "app")
        mountView(TSPCodePanel(), in: "code")
        mountView(TourStepLab(), in: "steps")
        mountView(TourStepCodePanel(), in: "code-steps")
        mountView(NamesStrip(names: [Names.christofides]), in: "names")
    }
}
