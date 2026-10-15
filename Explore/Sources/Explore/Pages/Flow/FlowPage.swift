import AdjacencyListModule
import ElementaryUI
import Flows
import GraphProtocols
import Reactivity

/// Each place in the waterworks and where it sits, in SVG units of the 680 × 400 view box.
let waterSpots: [(name: String, x: Double, y: Double)] = [
    ("Reservoir", 60, 200), ("North pump", 220, 80), ("South pump", 220, 320), ("Junction", 400, 210),
    ("Tank", 470, 70), ("Town", 620, 200),
]

let waterIndex: [String: Int] = Dictionary(uniqueKeysWithValues: waterSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The pipes in the order they are laid, with how much each carries at first.
let startingPipes: [(pipe: DirectedEdge<String>, capacity: Int)] = [
    (DirectedEdge(from: "Reservoir", to: "North pump"), 2),
    (DirectedEdge(from: "Reservoir", to: "South pump"), 2),
    (DirectedEdge(from: "North pump", to: "Junction"), 2),
    (DirectedEdge(from: "North pump", to: "Tank"), 2),
    (DirectedEdge(from: "South pump", to: "Junction"), 2),
    (DirectedEdge(from: "Junction", to: "Town"), 2),
    (DirectedEdge(from: "Tank", to: "Town"), 2),
]

/// One marble on the flow timeline, a Grafluent event with its pipes as offsets in the pipes.
enum FlowStep {
    case path([Int], bottleneck: Int)
    case push(Int, amount: Int)
    case cancel(Int, amount: Int)
}

@Reactive
final class FlowModel {
    var capacities = startingPipes.map(\.capacity)
    var steps: [FlowStep] = []
    var eventCount = 0
    var firstEvents = ""
    var most = 0
    var cut: [Int] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-flow")

    init() {
        run()
    }

    var pipes: [(pipe: DirectedEdge<String>, capacity: Int)] {
        startingPipes.indices.map { (startingPipes[$0].pipe, capacities[$0]) }
    }

    func pipeIndex(_ edge: DirectedEdge<String>) -> Int { startingPipes.firstIndex { $0.pipe == edge }! }

    /// Runs Grafluent's Edmonds–Karp on the current capacities and rewinds.
    func run() {
        let result = waterworksFlow(pipes)
        let w = result.waterworks
        eventCount = result.events.count
        firstEvents = result.events.prefix(2).map { "\($0)" }.joined(separator: ", ")
        steps = result.events.map { event in
            switch event {
            case .augmentingPath(let path, let bottleneck): .path(path.map { self.pipeIndex(w.edges[$0]) }, bottleneck: bottleneck)
            case .push(let e, let amount): .push(pipeIndex(w.edges[e]), amount: amount)
            case .cancel(let e, let amount): .cancel(pipeIndex(w.edges[e]), amount: amount)
            }
        }
        most = result.most
        cut = result.cut.map(pipeIndex)
        playback.reset(count: steps.count)
    }

    /// Widens pipe `i` by one, back to 0 after 5.
    func widen(_ i: Int) {
        capacities[i] = (capacities[i] + 1) % 6
        run()
    }

    /// Each pipe's flow after the first `k` steps.
    func flows(_ k: Int) -> [Int] {
        var flow = [Int](repeating: 0, count: startingPipes.count)
        for step in steps.prefix(k) {
            switch step {
            case .push(let i, let amount): flow[i] += amount
            case .cancel(let i, let amount): flow[i] -= amount
            case .path: break
            }
        }
        return flow
    }
}

let flowModel = FlowModel()

func pipeName(_ i: Int) -> String {
    let p = startingPipes[i].pipe
    return "\(p.source) → \(p.target)"
}

/// Each route found in `steps`, with what it carries and whether it runs backwards anywhere.
func flowRoutes(_ steps: ArraySlice<FlowStep>) -> [(length: Int, bottleneck: Int, backwards: Bool)] {
    var paths: [(length: Int, bottleneck: Int, backwards: Bool)] = []
    for step in steps {
        switch step {
        case .path(let path, let b): paths.append((path.count, b, false))
        case .cancel: paths[paths.count - 1].backwards = true
        case .push: break
        }
    }
    return paths
}

func describeFlowStep(_ step: FlowStep, _ model: FlowModel) -> String {
    switch step {
    case .path(let path, let bottleneck):
        var route: [String] = [startingPipes[path[0]].pipe.source]
        var at = route[0]
        for i in path {
            let p = startingPipes[i].pipe
            at = p.source == at ? p.target : p.source
            route.append(at)
        }
        return "The shortest route with room to spare: \(route.joined(separator: " → ")), \(path.count) pipes. Its tightest spot leaves room for \(bottleneck)."
    case .push(let i, let amount):
        return "Send \(amount) more along \(pipeName(i))."
    case .cancel(let i, let amount):
        return "This route runs backwards through \(pipeName(i)): cancel \(amount) of the water already sent there, and reroute it."
    }
}

/// The class of pipe `i` on the map.
func pipeClass(_ i: Int, flow: [Int], last: FlowStep?, finished: Bool, cut: Set<Int>) -> String {
    if finished && cut.contains(i) { return "bridge" }
    switch last {
    case .cancel(let j, _)? where j == i: return "cancel"
    case .push(let j, _)? where j == i: return "active"
    case .path(let path, _)? where path.contains(i): return "active"
    default: return flow[i] > 0 ? "tree" : ""
    }
}

@View
struct FlowLab {
    var body: some View {
        let model = flowModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let flow = model.flows(k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let paths = flowRoutes(steps.prefix(k))
        let arrived = startingPipes.indices.filter { startingPipes[$0].pipe.target == "Town" }.map { flow[$0] }.reduce(0, +)
        let cutSet = Set(model.cut)
        let nodes = waterSpots.map { spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 18,
                       classes: spot.name == "Reservoir" ? "visited source" : spot.name == "Town" ? "frontier" : "")
        }
        let edges = startingPipes.indices.map { i in
            CanvasEdge(from: waterIndex[startingPipes[i].pipe.source]!, to: waterIndex[startingPipes[i].pipe.target]!, directed: true,
                       label: "\(flow[i])/\(model.capacities[i])", classes: pipeClass(i, flow: flow, last: last, finished: finished, cut: cutSet))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The waterworks")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A reservoir and a town joined by pumps and pipes, each labelled flow over capacity", width: 680, height: 400,
                                nodes: nodes, edges: edges, onEdge: { flowModel.widen($0) })
                    div(.class("legend")) {
                        span { i(.class("line tree")) {}; "carrying water" }
                        span { i(.class("line active")) {}; "the route being used" }
                        span { i(.class("line cancel")) {}; "water cancelled, to reroute" }
                        span { i(.class("line bridge")) {}; "the minimum cut" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) events" : "Event \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Nothing flows yet. Each pipe is labelled with its flow over how much it can carry. Find a route from the Reservoir to the Town with room to spare, send what fits, and repeat. Press Step to begin."
                            } else if finished {
                                describeFlowStep(last!, model) + " No route has room left now, so "
                                em { "\(model.most)" }
                                " is the most the network can carry. The red pipes are a minimum cut: they hold exactly \(model.most) between them, and every route to the Town crosses one, so nothing could carry more."
                            } else {
                                describeFlowStep(last!, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Water reaching the Town" }
                        div(.class("stat")) {
                            div(.class("good")) {
                                span(.class("num")) { "\(arrived)" }
                                "arriving now"
                            }
                            div {
                                span(.class("num")) { finished ? "\(model.most)" : "?" }
                                "the most possible"
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Routes found" }
                        div(.class("queue")) {
                            if paths.isEmpty { p(.class("empty")) { "None yet" } }
                            for route in paths {
                                div(.class("qrow plain")) {
                                    span { "\(route.length) pipes" + (route.backwards ? ", one run backwards" : "") }
                                    span(.class("num")) { "+\(route.bottleneck)" }
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
                    marbles: steps.map { step in
                        let title = describeFlowStep(step, model)
                        switch step {
                        case .path(_, let b): return Marble(kind: "m-blue", radius: 11, letter: "+\(b)", title: title)
                        case .push: return Marble(kind: "m-ring", radius: 6, title: title)
                        case .cancel: return Marble(kind: "m-red", radius: 8, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a route with room, and what it carries"),
                        (Marble(kind: "m-ring", radius: 5), "water sent along a pipe"),
                        (Marble(kind: "m-red", radius: 5), "water cancelled, to reroute"),
                    ])
                p(.class("note")) { "Click a pipe to make it carry one more, up to 5, then 0 again." }
            }
        }
    }
}

@View
struct FlowCodePanel {
    var body: some View {
        let model = flowModel
        let pipeLines = ["let pipes = ["] + model.pipes.map { "    (pipe: DirectedEdge(from: \"\($0.pipe.source)\", to: \"\($0.pipe.target)\"), capacity: \($0.capacity))," } + ["]"]
        let cut = "[" + model.cut.map(pipeName).joined(separator: ", ") + "]"
        CodePanel(
            snippets: [.flowImports, Snippet(lines: pipeLines), .flowWaterworks, .flowRun],
            results: ["\(model.eventCount) events: \(model.firstEvents), …", "\(model.most)", cut])
    }
}

enum FlowPage {
    static func mount() {
        mountView(FlowLab(), in: "app")
        mountView(FlowCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.dinic]), in: "names")
    }
}
