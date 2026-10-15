import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Traversal

/// One search page's graph: where each vertex sits, its edges, and which search runs on it.
struct TraversalScenario {
    var spots: [(name: String, x: Double, y: Double)]
    var edges: [DirectedEdge<String>]
    var depthFirst: Bool
    /// The edge to draw bent, so it clears the vertices between its ends.
    var bent: DirectedEdge<String>?
    /// What a vertex and an edge are called on the page.
    var vertexWord: String
    var edgeWord: String

    func index(_ name: String) -> Int { spots.firstIndex { $0.name == name }! }
}

let officeScenario = TraversalScenario(
    spots: [("Reception", 70, 220), ("Kitchen", 230, 105), ("Archive", 400, 55), ("Server room", 565, 150),
            ("Meeting room", 230, 335), ("Lounge", 400, 335), ("Print room", 565, 315)],
    edges: doors, depthFirst: true, bent: DirectedEdge(from: "Archive", to: "Reception"), vertexWord: "room", edgeWord: "door")

let newsScenario = TraversalScenario(
    spots: [("Ana", 60, 210), ("Ben", 200, 75), ("Cy", 200, 210), ("Dee", 200, 345), ("Eli", 350, 120),
            ("Fay", 350, 300), ("Gus", 500, 140), ("Hal", 500, 300), ("Ivy", 620, 220)],
    edges: tells, depthFirst: false, bent: DirectedEdge(from: "Ivy", to: "Ana"), vertexWord: "friend", edgeWord: "message")

/// What one event of either search says, by vertex and edge offsets.
enum TraversalStep {
    case discover(Int)
    case finish(Int)
    /// An edge looked along: its offset in the scenario's edges and its kind, `tree`, `back`,
    /// `forward`, `cross` (depth-first) or `nontree` (breadth-first).
    case edge(Int, kind: String)
}

/// A search page's state: its graph, the start, the events of the search from there, and the
/// playhead.
@Reactive
final class TraversalModel {
    @ReactiveIgnored let scenario: TraversalScenario
    var start = 0
    var steps: [TraversalStep] = []
    var eventCount = 0
    var firstEvents = ""
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 650)

    init(_ scenario: TraversalScenario) {
        self.scenario = scenario
        run()
    }

    func run() {
        let name = scenario.spots[start].name
        let s = scenario
        func edge(_ e: DirectedEdge<String>) -> Int { s.edges.firstIndex(of: e)! }
        if scenario.depthFirst {
            let events = officeDepthFirst(from: name)
            eventCount = events.count
            firstEvents = events.prefix(2).map { "\($0)" }.joined(separator: ", ")
            steps = events.map { event in
                switch event {
                case .discover(let v): .discover(s.index(v))
                case .finish(let v): .finish(s.index(v))
                case .treeEdge(let e): .edge(edge(e), kind: "tree")
                case .backEdge(let e): .edge(edge(e), kind: "back")
                case .forwardEdge(let e): .edge(edge(e), kind: "forward")
                case .crossEdge(let e): .edge(edge(e), kind: "cross")
                }
            }
        } else {
            let events = newsBreadthFirst(from: name)
            eventCount = events.count
            firstEvents = events.prefix(2).map { "\($0)" }.joined(separator: ", ")
            steps = events.map { event in
                switch event {
                case .discover(let v): .discover(s.index(v))
                case .finish(let v): .finish(s.index(v))
                case .treeEdge(let e): .edge(edge(e), kind: "tree")
                case .nonTreeEdge(let e): .edge(edge(e), kind: "nontree")
                }
            }
        }
        playback.reset(count: steps.count)
        setProperty(id: "start", "value", to: "\(start)")
    }

    func choose(start: Int) {
        self.start = start
        run()
    }

    func describe(_ step: TraversalStep) -> String {
        let s = scenario
        switch step {
        case .discover(let v):
            return s.depthFirst ? "Enter \(s.spots[v].name) for the first time." : "\(s.spots[v].name) hears the news and joins the back of the queue."
        case .finish(let v):
            return s.depthFirst
                ? "Finish \(s.spots[v].name): every door out of it has been tried, so back up."
                : "\(s.spots[v].name) has passed the news to everyone they message, and leaves the queue."
        case .edge(let d, let kind):
            let e = s.edges[d]
            let via = "\(e.source) → \(e.target)"
            switch kind {
            case "tree": return s.depthFirst ? "Tree edge \(via): \(e.target) is new, so walk through." : "Tree edge \(via): \(e.target) hadn’t heard yet."
            case "back": return "Back edge \(via): \(e.target) is still being explored, an ancestor on the current path. That closes a cycle."
            case "forward": return "Forward edge \(via): \(e.target) was already reached, and finished, further down this corridor."
            case "cross": return "Cross edge \(via): \(e.target) is finished, on a branch already explored."
            default: return "Non-tree edge \(via): \(e.target) already heard, so nothing changes."
            }
        }
    }
}

let breadthFirstModel = TraversalModel(newsScenario)
let depthFirstModel = TraversalModel(officeScenario)

/// The vertices and edges after the first `k` steps: when each vertex was discovered and
/// finished on one clock, each edge's kind, each vertex's depth in the search tree, and the
/// discovery order.
struct TraversalSnapshot {
    var discovered: [Int?]
    var finished: [Int?]
    var kinds: [String]
    var depth: [Int]
    var order: [Int] = []

    init(_ scenario: TraversalScenario, _ steps: [TraversalStep], _ k: Int) {
        let n = scenario.spots.count
        discovered = [Int?](repeating: nil, count: n)
        finished = [Int?](repeating: nil, count: n)
        kinds = [String](repeating: "", count: scenario.edges.count)
        depth = [Int](repeating: 0, count: n)
        var clock = 0
        for step in steps.prefix(k) {
            switch step {
            case .discover(let v):
                clock += 1
                discovered[v] = clock
                order.append(v)
            case .finish(let v):
                clock += 1
                finished[v] = clock
            case .edge(let d, let kind):
                kinds[d] = kind
                let e = scenario.edges[d]
                if kind == "tree" { depth[scenario.index(e.target)] = depth[scenario.index(e.source)] + 1 }
            }
        }
    }
}

@View
struct TraversalLab {
    var model: TraversalModel

    var body: some View {
        let model = model
        let s = model.scenario
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let dfs = s.depthFirst
        let snapshot = TraversalSnapshot(s, steps, k)
        let last = k > 0 ? steps[k - 1] : nil
        let open = snapshot.order.filter { snapshot.finished[$0] == nil }
        let pending = dfs ? Array(open.reversed()) : open
        let activeEdge: Int = { if case .edge(let d, _)? = last { return d }; return -1 }()
        let current: Int = {
            switch last {
            case .discover(let v)?, .finish(let v)?: return v
            case .edge(let d, _)?: return s.index(s.edges[d].target)
            case nil: return -1
            }
        }()
        let nodes = s.spots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)),
                note: snapshot.discovered[v].map { d in dfs ? "\(d)/\(snapshot.finished[v].map { "\($0)" } ?? "…")" : "ring \(snapshot.depth[v])" } ?? "",
                radius: 17,
                classes: (snapshot.finished[v] != nil ? "done" : snapshot.discovered[v] != nil ? "frontier" : "")
                    + (v == model.start ? " source" : "") + (v == current ? " current" : ""))
        }
        let edges = s.edges.enumerated().map { d, e in
            CanvasEdge(from: s.index(e.source), to: s.index(e.target), directed: true,
                       classes: snapshot.kinds[d] + (d == activeEdge ? " active" : ""), bend: e == s.bent ? -26 : 0)
        }
        div {
            section(.class("lab"), .custom(name: "aria-label", value: dfs ? "The office building" : "The friends")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: dfs ? "An office building: rooms joined by one-way doors" : "Nine friends; an arrow from each to the friends they message",
                                width: dfs ? 640 : 680, height: dfs ? 400 : 420, nodes: nodes, edges: edges,
                                onNode: { model.choose(start: $0) }, nodeAction: "Start at")
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; dfs ? "on the current path" : "in the queue" }
                        span { i(.class("dot done")) {}; "finished" }
                        span { i(.class("line tree")) {}; "tree edge" }
                        if dfs {
                            span { i(.class("line back")) {}; "back edge" }
                            span { i(.class("line forward")) {}; "forward edge" }
                            span { i(.class("line cross")) {}; "cross edge" }
                        } else {
                            span { i(.class("line nontree")) {}; "non-tree edge" }
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == steps.count ? "Done after \(steps.count) events" : "Event \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if let last {
                                model.describe(last)
                            } else {
                                dfs
                                    ? "Go through the first new door you find, and only back up when a room has no new doors left."
                                    : "\(s.spots[model.start].name) has news. Everyone who hears it passes it on to the people they message, in the order they heard it."
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { dfs ? "Stack: the current path, newest first" : "Queue: next to pass it on first" }
                        div(.class("queue")) {
                            if pending.isEmpty { p(.class("empty")) { "Empty" } }
                            for (j, v) in pending.enumerated() {
                                div(.class(j == 0 ? "qrow top" : "qrow")) {
                                    span { s.spots[v].name }
                                    span(.class("num")) { dfs ? "#\(snapshot.discovered[v]!)" : "ring \(snapshot.depth[v])" }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Discovery order" }
                        div(.class("chips")) {
                            if snapshot.order.isEmpty { p(.class("empty")) { "None yet" } }
                            for v in snapshot.order { span(.class("chip")) { s.spots[v].name } }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    label(.class("field"), .for("start")) {
                        "Start at "
                        select(.id("start")) {
                            for (v, spot) in s.spots.enumerated() {
                                option(.value("\(v)")) { spot.name }.attributes(.selected, when: v == model.start)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let v = Int(value) { model.choose(start: v) }
                        }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { step in traversalMarble(step, s, model.describe(step)) },
                    legend: dfs
                        ? [(Marble(kind: "m-blue", radius: 6), "discover"), (Marble(kind: "m-hollow", radius: 5), "finish"), (Marble(kind: "m-blue", radius: 3.5), "tree edge"),
                           (Marble(kind: "m-red", radius: 5), "back edge"), (Marble(kind: "m-green", radius: 5), "forward edge"), (Marble(kind: "m-violet", radius: 5), "cross edge")]
                        : [(Marble(kind: "m-blue", radius: 6), "discover"), (Marble(kind: "m-hollow", radius: 5), "finish"), (Marble(kind: "m-blue", radius: 3.5), "tree edge"),
                           (Marble(kind: "m-violet", radius: 5), "non-tree edge")])
                p(.class("note")) {
                    dfs
                        ? "Under each room: when it was entered / when it was finished, on one clock. Click a room to start there."
                        : "Under each friend: which ring they are in, how many messages from the start. Click a friend to start there."
                }
            }
        }
    }
}

/// The marble for one search event.
func traversalMarble(_ step: TraversalStep, _ s: TraversalScenario, _ title: String) -> Marble {
    switch step {
    case .discover(let v): return Marble(kind: "m-blue", radius: 11, letter: String(s.spots[v].name.prefix(1)), title: title)
    case .finish: return Marble(kind: "m-hollow", radius: 9, title: title)
    case .edge(_, let kind):
        switch kind {
        case "tree": return Marble(kind: "m-blue", radius: 5, title: title)
        case "back": return Marble(kind: "m-red", radius: 7, title: title)
        case "forward": return Marble(kind: "m-green", radius: 7, title: title)
        default: return Marble(kind: "m-violet", radius: 7, title: title)
        }
    }
}

@View
struct TraversalCodePanel {
    var model: TraversalModel

    var body: some View {
        let model = model
        let dfs = model.scenario.depthFirst
        CodePanel(
            snippets: [.traversalImports, dfs ? .traversalOffice : .traversalNews,
                       Snippet(lines: ["let start = \"\(model.scenario.spots[model.start].name)\""]), dfs ? .traversalDfs : .traversalBfs],
            results: ["\(model.eventCount) events: \(model.firstEvents), …"])
    }
}

enum BreadthFirstPage {
    static func mount() {
        mountView(TraversalLab(model: breadthFirstModel), in: "app")
        mountView(TraversalCodePanel(model: breadthFirstModel), in: "code")
        mountView(NamesStrip(names: [Names.dijkstra]), in: "names")
    }
}

enum DepthFirstPage {
    static func mount() {
        mountView(TraversalLab(model: depthFirstModel), in: "app")
        mountView(TraversalCodePanel(model: depthFirstModel), in: "code")
        mountView(NamesStrip(names: [Names.tremaux]), in: "names")
    }
}
