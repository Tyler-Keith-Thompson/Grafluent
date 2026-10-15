import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import SpanningTrees

/// Each house and where it sits on the map, in SVG units of the 640 × 430 view box.
let housePlaces: [(name: String, x: Double, y: Double)] = [
    ("Ada", 90, 110), ("Ben", 320, 60), ("Cleo", 560, 100), ("Dev", 100, 350), ("Eli", 330, 250), ("Fay", 550, 360),
]

/// The index in `housePlaces` of each house's name.
let houseIndex: [String: Int] = Dictionary(uniqueKeysWithValues: housePlaces.enumerated().map { ($0.element.name, $0.offset) })

/// Every cable, cheapest first, ties by position: the order Kruskal reads them in.
let sortedCables: [Int] = houses.edges.indices.sorted { (cableCost[houses.edges[$0]]!, $0) < (cableCost[houses.edges[$1]]!, $1) }

/// `Ada–Ben`.
func cableName(_ cable: Int) -> String {
    let edge = houses.edges[cable]
    let (a, b) = houseIndex[edge.u]! < houseIndex[edge.v]! ? (edge.u, edge.v) : (edge.v, edge.u)
    return "\(a)–\(b)"
}

func cost(_ cable: Int) -> Int { cableCost[houses.edges[cable]]! }

/// One marble on Kruskal's timeline: a cable considered (`examineEdge`), then laid (`treeEdge`)
/// or skipped because its houses are already connected (`nonTreeEdge`).
enum KruskalStep {
    case consider(cable: Int)
    case lay(cable: Int, merging: String, into: String)
    case skip(cable: Int, root: String)

    var cable: Int {
        switch self {
        case .consider(let c), .lay(let c, _, _), .skip(let c, _): c
        }
    }
}

/// One marble on Prim's timeline: a house joins the network (`examine`), or a cable from it to a
/// house not yet connected is read (`examineEdge`, then `edgeRelaxed` or `edgeNotRelaxed`).
enum PrimStep {
    case join(house: Int, cable: Int?)
    case offer(from: Int, to: Int, cable: Int, previous: Int?, better: Bool)
}

/// What Kruskal's map shows after the first `k` steps: each house's group, by the group's root,
/// and each cable's fate.
struct KruskalSnapshot {
    var root: [Int]
    var laid: Set<Int> = []
    var skipped: Set<Int> = []
    var considered: Set<Int> = []

    /// The houses of `house`'s group, in map order.
    func group(of house: Int) -> [Int] {
        root.indices.filter { root[$0] == root[house] }
    }
}

/// What Prim's map shows after the first `k` steps.
struct PrimSnapshot {
    var joined: [Bool]
    var key: [Int?]
    /// The cable each waiting or joined house is reached by.
    var via: [Int?]
    var order: [Int] = []
}

/// The page's state: which algorithm is shown, Prim's start, both timelines and the playhead.
@Reactive
final class MSTModel {
    var showsPrim = false
    var start = houseIndex["Ada"]!
    var kruskalEvents: [HouseKruskalEvent] = []
    var primEvents: [HousePrimEvent] = []
    var kruskalSteps: [KruskalStep] = []
    var primSteps: [PrimStep] = []
    @ReactiveIgnored let playback = Playback()

    init() {
        kruskalEvents = kruskalCabling()
        kruskalSteps = MSTModel.timeline(kruskalEvents)
        startPrim(at: start)
        show(prim: false)
    }

    var count: Int { showsPrim ? primSteps.count : kruskalSteps.count }

    func show(prim: Bool) {
        showsPrim = prim
        playback.reset(count: count)
    }

    /// Runs Grafluent's Prim from `house`.
    func startPrim(at house: Int) {
        start = house
        primEvents = primCabling(from: housePlaces[house].name)
        primSteps = MSTModel.timeline(primEvents)
        if showsPrim { playback.reset(count: primSteps.count) }
    }

    static func timeline(_ events: [HouseKruskalEvent]) -> [KruskalStep] {
        events.map { event in
            switch event {
            case .examineEdge(let cable, _): .consider(cable: cable)
            case .treeEdge(let cable, let merging, let into): .lay(cable: cable, merging: merging, into: into)
            case .nonTreeEdge(let cable, let root): .skip(cable: cable, root: root)
            }
        }
    }

    static func timeline(_ events: [HousePrimEvent]) -> [PrimStep] {
        var steps: [PrimStep] = []
        var key = [Int?](repeating: nil, count: housePlaces.count)
        var current = 0
        var offered: (cable: Int, weight: Int)?
        for event in events {
            switch event {
            case .examine(let house, let cable, _):
                current = houseIndex[house]!
                steps.append(.join(house: current, cable: cable))
            case .examineEdge(let cable, let weight):
                offered = (cable, weight)
            case .edgeRelaxed(let cable, _), .edgeNotRelaxed(let cable, _):
                let to = houseIndex[houses.oppositeVertex(to: housePlaces[current].name, acrossEdgeAt: cable)]!
                let better: Bool
                if case .edgeRelaxed = event { better = true } else { better = false }
                steps.append(.offer(from: current, to: to, cable: cable, previous: key[to], better: better))
                if better { key[to] = offered?.weight }
            case .startVertex, .finish:
                break
            }
        }
        return steps
    }

    func kruskalSnapshot(_ k: Int) -> KruskalSnapshot {
        var state = KruskalSnapshot(root: Array(housePlaces.indices))
        for step in kruskalSteps.prefix(k) {
            switch step {
            case .consider(let cable):
                state.considered.insert(cable)
            case .lay(let cable, let merging, let into):
                state.laid.insert(cable)
                let gone = houseIndex[merging]!, kept = houseIndex[into]!
                for h in state.root.indices where state.root[h] == gone { state.root[h] = kept }
            case .skip(let cable, _):
                state.skipped.insert(cable)
            }
        }
        return state
    }

    func primSnapshot(_ k: Int) -> PrimSnapshot {
        let n = housePlaces.count
        var state = PrimSnapshot(joined: [Bool](repeating: false, count: n), key: [Int?](repeating: nil, count: n), via: [Int?](repeating: nil, count: n))
        state.key[start] = 0
        for step in primSteps.prefix(k) {
            switch step {
            case .join(let house, _):
                state.joined[house] = true
                state.order.append(house)
            case .offer(_, let to, let cable, _, let better):
                if better {
                    state.key[to] = cost(cable)
                    state.via[to] = cable
                }
            }
        }
        return state
    }
}

let mst = MSTModel()

/// `Ada, Ben and Dev`.
func houseList(_ group: [Int]) -> String {
    let names = group.map { housePlaces[$0].name }
    return names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// The sentence for one Kruskal step, with the groups as they stand before it.
func describe(_ step: KruskalStep, before state: KruskalSnapshot) -> String {
    let edge = houses.edges[step.cable]
    let a = houseIndex[edge.u]!, b = houseIndex[edge.v]!
    switch step {
    case .consider(let cable):
        let left = state.group(of: a), right = state.group(of: b)
        let where_ = left == right
            ? "Both are already in one group: \(houseList(left))."
            : "\(housePlaces[a].name)’s group is \(houseList(left)); \(housePlaces[b].name)’s is \(houseList(right))."
        return "Next cheapest: \(cableName(cable)), cost \(cost(cable)). " + where_
    case .lay(let cable, _, _):
        return "Lay \(cableName(cable)): it joins two groups into one, \(houseList((state.group(of: a) + state.group(of: b)).sorted()))."
    case .skip(let cable, _):
        return "Skip \(cableName(cable)): its houses are already connected, so it would only close a loop."
    }
}

/// The sentence for one Prim step.
func describe(_ step: PrimStep) -> String {
    switch step {
    case .join(let house, let cable):
        guard let cable else { return "Start at \(housePlaces[house].name): a network of one house, costing nothing." }
        return "\(housePlaces[house].name) is the cheapest house to reach: it joins by \(cableName(cable)), cost \(cost(cable))."
    case .offer(let from, let to, let cable, let previous, let better):
        let name = housePlaces[to].name
        if better {
            return previous.map { "\(housePlaces[from].name) can reach \(name) for \(cost(cable)), cheaper than \(name)’s \($0) before." }
                ?? "\(housePlaces[from].name) can reach \(name) for \(cost(cable)). \(name) waits at that price."
        }
        return "\(housePlaces[from].name) could reach \(name) for \(cost(cable)), but \(previous.map { "\($0)" } ?? "?") is already on offer. Nothing changes."
    }
}

/// The houses map, the panels beside it, and the playback controls with the timeline.
@View
struct MSTLab {
    var body: some View {
        let model = mst
        let playback = model.playback
        let k = playback.k
        let prim = model.showsPrim
        let finished = k == model.count
        let kruskal = model.kruskalSnapshot(k)
        let kruskalBefore = model.kruskalSnapshot(max(0, k - 1))
        let grown = model.primSnapshot(k)
        let lastKruskal = !prim && k > 0 ? model.kruskalSteps[k - 1] : nil
        let lastPrim = prim && k > 0 ? model.primSteps[k - 1] : nil
        let primTree = Set(grown.joined.indices.compactMap { grown.joined[$0] ? grown.via[$0] : nil })
        let activeCable = finished ? -1 : lastKruskal?.cable ?? lastPrim.flatMap { step -> Int? in
            switch step {
            case .offer(_, _, let cable, _, _): cable
            case .join(_, let cable): cable
            }
        } ?? -1
        let activeHouses: Set<Int> = activeCable >= 0
            ? [houseIndex[houses.edges[activeCable].u]!, houseIndex[houses.edges[activeCable].v]!]
            : []
        // Groups of two or more get a colour, by their root's place on the map.
        let sizes = Dictionary(grouping: kruskal.root, by: { $0 }).mapValues(\.count)
        let nodes = housePlaces.enumerated().map { i, house in
            if prim {
                let waiting = !grown.joined[i] && grown.key[i] != nil
                return CanvasNode(
                    x: house.x, y: house.y, name: house.name, note: waiting ? "\(grown.key[i]!)" : "", radius: 18,
                    classes: (grown.joined[i] ? "visited" : waiting ? "frontier" : "") + (i == model.start ? " source" : "")
                        + (activeHouses.contains(i) ? " current" : ""))
            }
            return CanvasNode(
                x: house.x, y: house.y, name: house.name, radius: 18,
                classes: (sizes[kruskal.root[i]]! > 1 ? "pal\(kruskal.root[i])" : "") + (activeHouses.contains(i) ? " current" : ""))
        }
        let edges = houses.edges.indices.map { cable in
            let edge = houses.edges[cable]
            let classes: String
            if prim {
                classes = primTree.contains(cable) ? "tree" : ""
            } else if kruskal.laid.contains(cable) {
                classes = "tree"
            } else if kruskal.skipped.contains(cable) {
                classes = cable == activeCable ? "conflict" : "faint"
            } else {
                classes = finished ? "faint" : ""
            }
            return CanvasEdge(
                from: houseIndex[edge.u]!, to: houseIndex[edge.v]!, label: "\(cableCost[edge]!)",
                classes: classes + (cable == activeCable && !kruskal.skipped.contains(cable) ? " active" : ""))
        }
        let laidCost = prim
            ? grown.order.compactMap { grown.via[$0] }.map(cost).reduce(0, +)
            : kruskal.laid.map(cost).reduce(0, +)
        let totals = cablingTotals(from: housePlaces[model.start].name)
        let waiting = housePlaces.indices
            .filter { !grown.joined[$0] && grown.key[$0] != nil }
            .sorted { (grown.key[$0]!, $0) < (grown.key[$1]!, $1) }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Interactive map")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Six houses joined by possible cables, each labelled with its cost", width: 640, height: 430,
                                nodes: nodes, edges: edges, onNode: prim ? { mst.startPrim(at: $0) } : nil, nodeAction: "Start Prim at")
                    div(.class("legend")) {
                        span { i(.class("line")) {}; "a cable that could be laid" }
                        span { i(.class("line tree")) {}; "laid" }
                        if prim {
                            span { i(.class("dot visited")) {}; "connected" }
                            span { i(.class("dot frontier")) {}; "waiting, with the cheapest price so far" }
                        } else {
                            span { i(.class("line faint")) {}; "skipped or not needed" }
                            span { i(.class("dot pal1")) {}; "a colour per group of connected houses" }
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(model.count) steps" : "Step \(k) of \(model.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                prim
                                    ? "Prim grows one network from \(housePlaces[model.start].name), always adding the cheapest cable to a house not yet connected. Press Step to begin."
                                    : "Kruskal reads every cable from cheapest to dearest and lays each one that joins two separate groups. Every house starts in a group of its own. Press Step to begin."
                            } else if finished {
                                "Every house is connected by 5 cables, total cost "
                                em { "\(laidCost)" }
                                prim
                                    ? ". Kruskal, laying cables in a different order, reaches the same total: \(totals.kruskal)."
                                    : ". Prim, growing from one house, reaches the same total: \(totals.prim)."
                            } else if let lastKruskal {
                                describe(lastKruskal, before: kruskalBefore)
                            } else if let lastPrim {
                                describe(lastPrim)
                            }
                        }
                    }
                    if prim {
                        div(.class("panel")) {
                            span(.class("label")) { "Waiting houses, cheapest first" }
                            div(.class("queue")) {
                                if waiting.isEmpty {
                                    p(.class("empty")) { finished ? "Empty: every house is connected." : "Empty" }
                                }
                                for (j, house) in waiting.enumerated() {
                                    div(.class(j == 0 ? "qrow top" : "qrow")) {
                                        span { housePlaces[house].name + (j == 0 ? " · next" : "") }
                                        span(.class("num")) { "\(grown.key[house]!)" }
                                    }
                                }
                            }
                        }
                        div(.class("panel")) {
                            span(.class("label")) { "Connected, in order" }
                            div(.class("chips")) {
                                if grown.order.isEmpty {
                                    p(.class("empty")) { "None yet" }
                                }
                                for house in grown.order {
                                    span(.class("chip")) {
                                        "\(housePlaces[house].name) "
                                        span(.class("num")) { grown.via[house].map { "\(cost($0))" } ?? "start" }
                                    }
                                }
                            }
                        }
                    } else {
                        div(.class("panel")) {
                            span(.class("label")) { "Cables, cheapest first" }
                            div(.class("queue")) {
                                for cable in sortedCables {
                                    let fate = kruskal.laid.contains(cable) ? "laid" : kruskal.skipped.contains(cable) ? "skipped: closes a loop"
                                        : cable == activeCable ? "considering" : finished ? "not needed" : ""
                                    div(.class("qrow cable" + (kruskal.laid.contains(cable) ? " laid" : kruskal.skipped.contains(cable) ? " skipped" : cable == activeCable ? " top" : finished ? " later" : ""))) {
                                        span {
                                            cableName(cable)
                                            if !fate.isEmpty { span(.class("fate")) { fate } }
                                        }
                                        span(.class("num")) { "\(cost(cable))" }
                                    }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Cable laid so far" }
                        div(.class("stat")) {
                            div(.class("good")) {
                                span(.class("num")) { "\(laidCost)" }
                                prim ? "Prim" : "Kruskal"
                            }
                            div {
                                span(.class("num")) { "\(prim ? totals.kruskal : totals.prim)" }
                                prim ? "Kruskal’s total" : "Prim’s total"
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Algorithm")) {
                        button(.type(.button), .class(prim ? "" : "on")) { "Kruskal" }
                            .onClick { mst.show(prim: false) }
                        button(.type(.button), .class(prim ? "on" : "")) { "Prim" }
                            .onClick { mst.show(prim: true) }
                    }
                    if prim {
                        label(.class("field"), .for("prim-start")) {
                            "Start at "
                            select(.id("prim-start")) {
                                for (i, house) in housePlaces.enumerated() {
                                    option(.value("\(i)")) { house.name }.attributes(.selected, when: i == model.start)
                                }
                            }
                            .onInput { event in
                                if let value = event.targetValue, let house = Int(value) { mst.startPrim(at: house) }
                            }
                        }
                    }
                }
                if prim {
                    Timeline(
                        playback: playback,
                        marbles: model.primSteps.map { step in
                            switch step {
                            case .join(let house, _): Marble(kind: "m-blue", radius: 11, letter: String(housePlaces[house].name.prefix(1)), title: describe(step))
                            case .offer(_, _, _, _, let better): better ? Marble(kind: "m-ring", radius: 7, title: describe(step)) : Marble(kind: "m-grey", radius: 4, title: describe(step))
                            }
                        },
                        legend: [
                            (Marble(kind: "m-blue", radius: 6), "a house joins the network"),
                            (Marble(kind: "m-ring", radius: 5), "a cheaper price for a waiting house"),
                            (Marble(kind: "m-grey", radius: 3.5), "a cable is read, not cheaper"),
                        ])
                    p(.class("note")) { "Click any house, or pick one, to grow the network from it. Numbers on the lines are what each cable costs." }
                } else {
                    Timeline(
                        playback: playback,
                        marbles: model.kruskalSteps.enumerated().map { j, step in
                            let title = describe(step, before: model.kruskalSnapshot(j))
                            switch step {
                            case .consider: return Marble(kind: "m-grey", radius: 4, title: title)
                            case .lay: return Marble(kind: "m-blue", radius: 9, title: title)
                            case .skip: return Marble(kind: "m-red", radius: 7, title: title)
                            }
                        },
                        legend: [
                            (Marble(kind: "m-grey", radius: 3.5), "the next cheapest cable is read"),
                            (Marble(kind: "m-blue", radius: 6), "it joins two groups: laid"),
                            (Marble(kind: "m-red", radius: 5), "its houses are already connected: skipped"),
                        ])
                    p(.class("note")) { "Numbers on the lines are what each cable costs. Houses of one colour are already connected to each other." }
                }
            }
        }
    }
}

/// The code panel: the houses, both algorithms and their totals, as the page runs them.
@View
struct MSTCodePanel {
    var body: some View {
        let model = mst
        let totals = cablingTotals(from: housePlaces[model.start].name)
        CodePanel(
            snippets: [
                .mstImports, .mstHouses,
                Snippet(lines: ["let start = \"\(housePlaces[model.start].name)\""]),
                .mstKruskal, .mstPrim, .mstTotals,
            ],
            results: [
                "\(model.kruskalEvents.count) events",
                "\(model.primEvents.count) events",
                "\(totals.kruskal)",
                "\(totals.prim)",
            ])
    }
}

enum MSTPage {
    static func mount() {
        mountView(MSTLab(), in: "app")
        mountView(MSTCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.kruskal, Names.prim, Names.boruvka]), in: "names")
    }
}
