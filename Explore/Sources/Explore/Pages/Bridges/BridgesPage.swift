import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Traversal

/// Each place in the village and where it sits, in SVG units of the 640 × 430 view box.
let villageSpots: [(name: String, x: Double, y: Double)] = [
    ("Farm", 60, 360), ("Mill", 140, 230), ("Church", 170, 80), ("Square", 330, 120), ("School", 310, 290),
    ("Station", 455, 185), ("Market", 590, 95), ("Harbour", 580, 300), ("Lighthouse", 450, 385),
]

/// The index in `villageSpots` of each place's name.
let villageIndex: [String: Int] = Dictionary(uniqueKeysWithValues: villageSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of road `road`, as offsets in `villageSpots`.
func villageEnds(_ road: Int) -> (Int, Int) {
    let edge = village.edges[road]
    return (villageIndex[edge.u]!, villageIndex[edge.v]!)
}

/// `Mill–Church`.
func roadName(_ road: Int) -> String { "\(village.edges[road])" }

/// One marble on the search's timeline, read off Grafluent's edge depth-first search: a place
/// reached for the first time (`discover`), a road to a new place (`treeEdge`), a road back to a
/// place still on the current path (`backEdge`), or a place left once every road out of it has
/// been tried (`finish`). Places are offsets in `villageSpots`, roads positions in `village`.
enum LowLinkStep {
    case arrive(place: Int)
    case tree(road: Int, from: Int, to: Int)
    case back(road: Int, from: Int, to: Int)
    case leave(place: Int)
}

/// What the village shows after some steps: each place's discovery time and low-link, the
/// current path, each road's kind, and the weak spots found so far.
struct LowLinkSnapshot {
    var time: [Int?]
    var low: [Int?]
    var finished: [Bool]
    var parent: [Int?]
    /// The tree road into each place.
    var via: [Int?]
    /// The places entered and not yet left, the start first.
    var path: [Int] = []
    var tree: Set<Int> = []
    var back: Set<Int> = []
    var bridges: [Int] = []
    var cutVertices: [Int] = []
    var clock = 0

    init(count n: Int) {
        time = [Int?](repeating: nil, count: n)
        low = [Int?](repeating: nil, count: n)
        finished = [Bool](repeating: false, count: n)
        parent = [Int?](repeating: nil, count: n)
        via = [Int?](repeating: nil, count: n)
    }

    /// The places whose tree road comes from `place`.
    func children(of place: Int) -> [Int] {
        parent.indices.filter { parent[$0] == place }
    }

    /// The snapshot after `step`, which follows this one.
    func after(_ step: LowLinkStep) -> LowLinkSnapshot {
        var next = self
        switch step {
        case .arrive(let v):
            next.clock += 1
            next.time[v] = next.clock
            next.low[v] = next.clock
            next.path.append(v)
        case .tree(let road, let from, let to):
            next.tree.insert(road)
            next.parent[to] = from
            next.via[to] = road
        case .back(let road, let from, let to):
            next.back.insert(road)
            next.low[from] = min(next.low[from]!, next.time[to]!)
        case .leave(let v):
            next.finished[v] = true
            next.path.removeLast()
            if let p = parent[v] {
                next.low[p] = min(next.low[p]!, next.low[v]!)
                if low[v]! > time[p]! { next.bridges.append(via[v]!) }
                if parent[p] != nil, low[v]! >= time[p]!, !next.cutVertices.contains(p) { next.cutVertices.append(p) }
            } else if children(of: v).count > 1 {
                next.cutVertices.append(v)
            }
        }
        return next
    }
}

/// The bridges page's state: the start of the search, its steps and the snapshot after each, the
/// playhead, and the road or place closed in the village above it.
@Reactive
final class BridgesModel {
    var start = villageIndex["Mill"]!
    var events: [VillageSearchEvent] = []
    var steps: [LowLinkStep] = []
    /// `snapshots[k]` is the village after the first `k` steps.
    var snapshots: [LowLinkSnapshot] = []
    var closedRoad: Int?
    var closedPlace: Int?
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 800, scrubID: "scrub-lowlink")

    init() {
        run(from: start)
    }

    /// Runs Grafluent's edge depth-first search from `place` and rewinds to the start.
    func run(from place: Int) {
        start = place
        events = villageSearch(from: villageSpots[place].name)
        steps = BridgesModel.timeline(events)
        var state = LowLinkSnapshot(count: villageSpots.count)
        snapshots = [state]
        for step in steps {
            state = state.after(step)
            snapshots.append(state)
        }
        playback.reset(count: steps.count)
        setProperty(id: "lowlink-start", "value", to: "\(place)")
    }

    /// The marbles of `events`. A back edge is reported from the end that reaches it first, the
    /// place being explored; its other end is on the current path.
    static func timeline(_ events: [VillageSearchEvent]) -> [LowLinkStep] {
        var steps: [LowLinkStep] = []
        var path: [Int] = []
        for event in events {
            switch event {
            case .discover(let v):
                path.append(villageIndex[v]!)
                steps.append(.arrive(place: villageIndex[v]!))
            case .treeEdge(let road):
                let (a, b) = villageEnds(road)
                let from = a == path.last! ? a : b
                steps.append(.tree(road: road, from: from, to: from == a ? b : a))
            case .backEdge(let road), .forwardEdge(let road), .crossEdge(let road):
                let (a, b) = villageEnds(road)
                let from = a == path.last! ? a : b
                steps.append(.back(road: road, from: from, to: from == a ? b : a))
            case .finish(let v):
                path.removeLast()
                steps.append(.leave(place: villageIndex[v]!))
            }
        }
        return steps
    }

    func toggle(road: Int) {
        closedPlace = nil
        closedRoad = closedRoad == road ? nil : road
    }

    func toggle(place: Int) {
        closedRoad = nil
        closedPlace = closedPlace == place ? nil : place
    }

    /// The pieces of the village with the closed road or place gone, from Grafluent.
    var pieces: [[String]] {
        if let road = closedRoad { return villagePieces(closingRoad: village.edges[road]) }
        if let place = closedPlace { return villagePieces(closingPlace: villageSpots[place].name) }
        return villagePieces()
    }
}

let bridgesModel = BridgesModel()

/// `Farm, Mill and Church`.
func placeList(_ names: [String]) -> String {
    names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// The sentence for one step, given the snapshots before and after it.
func describeLowLink(_ step: LowLinkStep, before: LowLinkSnapshot, after: LowLinkSnapshot) -> String {
    func name(_ v: Int) -> String { villageSpots[v].name }
    switch step {
    case .arrive(let v):
        let t = after.time[v]!
        return t == 1
            ? "Start at \(name(v)), at time 1. Its low-link is its own time for now."
            : "Arrive at \(name(v)) at time \(t). Its low-link starts at \(t), its own time."
    case .tree(let road, _, let to):
        return "\(roadName(road)) leads somewhere new. Walk on to \(name(to))."
    case .back(let road, let from, let to):
        let was = before.low[from]!, now = after.low[from]!
        return now < was
            ? "\(roadName(road)) leads back to \(name(to)), which is on the path at time \(before.time[to]!). So \(name(from))’s low-link drops from \(was) to \(now)."
            : "\(roadName(road)) leads back to \(name(to)), time \(before.time[to]!). \(name(from)) already reaches back to \(was), so nothing changes."
    case .leave(let v):
        let low = after.low[v]!
        guard let p = before.parent[v] else {
            let branches = before.children(of: v)
            return branches.count > 1
                ? "Back at \(name(v)), where the search began. It had to set out \(branches.count) separate times, to \(placeList(branches.map(name))). So \(name(v)) is an articulation point."
                : "Back at \(name(v)), where the search began. It set out only once, so \(name(v)) is not an articulation point."
        }
        let pt = before.time[p]!
        let road = roadName(before.via[v]!)
        if low > pt {
            return "Leave \(name(v)) with low-link \(low), later than \(name(p))’s time \(pt). So \(road) is the only way back, and it is a bridge."
                + (before.parent[p] != nil ? " \(name(p)) is an articulation point." : "")
        } else if low == pt {
            return "Leave \(name(v)) with low-link \(low), the same as \(name(p))’s time. It can get back to \(name(p)) another way, so \(road) is not a bridge."
                + (before.parent[p] != nil ? " But it gets no further, so \(name(p)) is an articulation point." : "")
        }
        return "Leave \(name(v)) with low-link \(low), earlier than \(name(p))’s time \(pt). There is a way round \(name(p)), so \(name(p))’s low-link becomes \(after.low[p]!)."
    }
}

/// The marble for one step of the search.
func lowLinkMarble(_ step: LowLinkStep, before: LowLinkSnapshot, after: LowLinkSnapshot) -> Marble {
    let title = describeLowLink(step, before: before, after: after)
    switch step {
    case .arrive(let v): return Marble(kind: "m-blue", radius: 11, letter: "\(after.time[v]!)", title: title)
    case .tree: return Marble(kind: "m-blue", radius: 4, title: title)
    case .back: return Marble(kind: "m-violet", radius: 7, title: title)
    case .leave:
        if after.bridges.count > before.bridges.count { return Marble(kind: "m-red", radius: 10, letter: "B", title: title) }
        if after.cutVertices.count > before.cutVertices.count { return Marble(kind: "m-red", radius: 8, title: title) }
        return Marble(kind: "m-hollow", radius: 8, title: title)
    }
}

/// The search: the village with times and low-links, the panels beside it, and the playback
/// controls with the timeline.
@View
struct LowLinkLab {
    var body: some View {
        let model = bridgesModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let state = model.snapshots[k]
        let before = model.snapshots[max(0, k - 1)]
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let answer = villageWeakSpots()
        let activeRoad: Int = {
            switch last {
            case .tree(let road, _, _)?, .back(let road, _, _)?: return road
            default: return -1
            }
        }()
        let current: Int = {
            switch last {
            case .arrive(let v)?, .leave(let v)?: return v
            case .tree(_, _, let to)?: return to
            case .back(_, let from, _)?: return from
            case nil: return -1
            }
        }()
        let nodes = villageSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, badge: state.time[v].map { "\($0)" } ?? "",
                note: state.low[v].map { "low \($0)" } ?? "", radius: 17,
                classes: (state.cutVertices.contains(v) ? "cut" : state.finished[v] ? "done" : state.time[v] != nil ? "frontier" : "")
                    + (v == model.start ? " source" : "") + (v == current ? " current" : ""))
        }
        let edges = village.edges.indices.map { road in
            let (a, b) = villageEnds(road)
            return CanvasEdge(
                from: a, to: b,
                classes: (state.bridges.contains(road) ? "bridge" : state.back.contains(road) ? "nontree" : state.tree.contains(road) ? "tree" : "")
                    + (road == activeRoad ? " active" : ""))
        }
        let matches = Set(state.bridges.map { village.edges[$0] }) == Set(answer.bridges)
            && Set(state.cutVertices.map { villageSpots[$0].name }) == Set(answer.cutVertices)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Depth-first search of the village")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The village searched depth-first: each place numbered by when it was reached, with its low-link", width: 640, height: 430,
                                nodes: nodes, edges: edges, onNode: { bridgesModel.run(from: $0) }, nodeAction: "Start the search at")
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "on the current path" }
                        span { i(.class("dot done")) {}; "left" }
                        span { i(.class("dot cut")) {}; "articulation point" }
                        span { i(.class("line tree")) {}; "tree road" }
                        span { i(.class("line nontree")) {}; "back road: a second way round" }
                        span { i(.class("line bridge")) {}; "bridge" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) events" : "Event \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "A depth-first search gives each place a "
                                em { "time" }
                                ", the order it first arrives there. Each place also keeps a "
                                em { "low-link" }
                                ", the earliest time it can get back to. Press Step to begin."
                            } else if finished {
                                describeLowLink(last!, before: before, after: state) + " Every place is left."
                                matches
                                    ? " The same answer as village.bridges() and village.articulationPoints()."
                                    : " This disagrees with village.bridges() and village.articulationPoints()."
                            } else {
                                describeLowLink(last!, before: before, after: state)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Current path, from the start" }
                        div(.class("queue")) {
                            if state.path.isEmpty { p(.class("empty")) { finished ? "Empty: every place is left." : "Empty" } }
                            for (j, v) in state.path.enumerated() {
                                div(.class(j == state.path.count - 1 ? "qrow top" : "qrow")) {
                                    span { villageSpots[v].name }
                                    span(.class("num")) { "time \(state.time[v]!) · low \(state.low[v]!)" }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Found so far" }
                        div(.class("chips")) {
                            if state.bridges.isEmpty && state.cutVertices.isEmpty { p(.class("empty")) { "Nothing yet" } }
                            for road in state.bridges { span(.class("chip bad")) { "bridge " + roadName(road) } }
                            for v in state.cutVertices { span(.class("chip hollow")) { villageSpots[v].name } }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    label(.class("field"), .for("lowlink-start")) {
                        "Start at "
                        select(.id("lowlink-start")) {
                            for (v, spot) in villageSpots.enumerated() {
                                option(.value("\(v)")) { spot.name }.attributes(.selected, when: v == model.start)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let v = Int(value) { bridgesModel.run(from: v) }
                        }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.enumerated().map { j, step in lowLinkMarble(step, before: model.snapshots[j], after: model.snapshots[j + 1]) },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "arrive, with the time"),
                        (Marble(kind: "m-blue", radius: 3.5), "tree road"),
                        (Marble(kind: "m-violet", radius: 5), "back road"),
                        (Marble(kind: "m-hollow", radius: 5), "leave"),
                        (Marble(kind: "m-red", radius: 6), "leave, and a weak spot is found"),
                    ])
                p(.class("note")) { "In each circle: the time the search arrived. Under it: the low-link. Click a place to start the search there; the times change, the weak spots don’t." }
            }
        }
    }
}

/// The village with a road or place closed: the pieces it falls into, in colours.
@View
struct ClosureLab {
    var body: some View {
        let model = bridgesModel
        let pieces = model.pieces
        let piece: [String: Int] = Dictionary(uniqueKeysWithValues: pieces.enumerated().flatMap { n, names in names.map { ($0, n) } })
        let split = pieces.count > 1
        let nodes = villageSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, radius: 17,
                classes: v == model.closedPlace ? "closed" : split ? "pal\(piece[spot.name]! % 8)" : "")
        }
        let edges = village.edges.indices.map { road in
            let (a, b) = villageEnds(road)
            let gone = road == model.closedRoad || a == model.closedPlace || b == model.closedPlace
            return CanvasEdge(from: a, to: b, classes: gone ? "faint" : split ? "pal\(piece[villageSpots[a].name]! % 8)" : "")
        }
        let closed = model.closedRoad.map { "the road " + roadName($0) } ?? model.closedPlace.map { villageSpots[$0].name } ?? ""

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Close a road or a place")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A village of nine places joined by ten roads; click a road or a place to close it", width: 640, height: 430,
                                nodes: nodes, edges: edges, onNode: { bridgesModel.toggle(place: $0) }, onEdge: { bridgesModel.toggle(road: $0) },
                                nodeAction: "Close")
                    div(.class("legend")) {
                        span { i(.class("line faint")) {}; "closed" }
                        span { i(.class("dot pal1")) {}; "a colour per piece the village falls into" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { closed.isEmpty ? "Everything open" : "Closed: " + closed }
                        p(.class("narration")) {
                            if closed.isEmpty {
                                "Click any road to close it, or any place to close it and every road into it. Which single closure splits the village?"
                            } else if split {
                                "With \(closed) closed, the village falls into "
                                em { "\(pieces.count) pieces" }
                                ". "
                                model.closedRoad != nil ? "That road is a bridge." : "That place is an articulation point."
                            } else {
                                "With \(closed) closed, everyone left can still reach everyone else. There is another way round."
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Pieces" }
                        div(.class("queue")) {
                            for (n, names) in pieces.enumerated() {
                                div(.class("qrow plain")) {
                                    span(.class(split ? "chip pal\(n % 8)" : "chip")) { "\(names.count)" }
                                    span { names.sorted { villageIndex[$0]! < villageIndex[$1]! }.joined(separator: ", ") }
                                }
                            }
                        }
                    }
                    if !closed.isEmpty {
                        div(.class("panel")) {
                            div(.class("buttons")) {
                                button(.type(.button)) { "Reopen" }
                                    .onClick {
                                        bridgesModel.closedRoad = nil
                                        bridgesModel.closedPlace = nil
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The closure's code panel: the village, the closure, and its pieces.
@View
struct ClosureCodePanel {
    var body: some View {
        let model = bridgesModel
        let pieces = model.pieces
        let result = "\(pieces.count) piece\(pieces.count == 1 ? "" : "s"): " + pieces.map { "[" + $0.joined(separator: ", ") + "]" }.joined(separator: ", ")
        if let road = model.closedRoad {
            let edge = village.edges[road]
            CodePanel(snippets: [.bridgesImports, .bridgesVillage, Snippet(lines: ["let road = UndirectedEdge(\"\(edge.u)\", \"\(edge.v)\")"]), .bridgesCloseRoad], results: [result])
        } else if let place = model.closedPlace {
            CodePanel(snippets: [.bridgesImports, .bridgesVillage, Snippet(lines: ["let place = \"\(villageSpots[place].name)\""]), .bridgesClosePlace], results: [result])
        } else {
            CodePanel(snippets: [.bridgesImports, .bridgesVillage, .bridgesWhole], results: [result])
        }
    }
}

/// The search's code panel: the village, the search the timeline shows, and Grafluent's answer.
@View
struct LowLinkCodePanel {
    var body: some View {
        let model = bridgesModel
        let answer = villageWeakSpots()
        CodePanel(
            snippets: [
                .bridgesImports, .bridgesVillage,
                Snippet(lines: ["let start = \"\(villageSpots[model.start].name)\""]),
                .bridgesSearch, .bridgesAnswer,
            ],
            results: [
                "\(model.events.count) events: " + model.events.prefix(3).map { "\($0)" }.joined(separator: ", ") + ", …",
                "[" + answer.bridges.map { "\($0)" }.joined(separator: ", ") + "]",
                "[" + answer.cutVertices.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

enum BridgesPage {
    static func mount() {
        mountView(ClosureLab(), in: "app")
        mountView(ClosureCodePanel(), in: "code")
        mountView(LowLinkLab(), in: "search")
        mountView(LowLinkCodePanel(), in: "code-search")
        mountView(NamesStrip(names: [Names.tremaux]), in: "names")
    }
}
