import ElementaryUI
import Traversal
import GraphProtocols
import Reactivity

let buildSteps: [(name: String, x: Double, y: Double)] = [
    ("Underwear", 70, 70), ("Socks", 70, 200), ("Shirt", 70, 320), ("Watch", 610, 70), ("Trousers", 250, 110),
    ("Tie", 250, 340), ("Shoes", 430, 160), ("Belt", 430, 270), ("Jacket", 610, 320),
]
let buildIndex: [String: Int] = Dictionary(uniqueKeysWithValues: buildSteps.enumerated().map { ($0.element.name, $0.offset) })
let startingDependencies: [(String, String)] = [
    ("Underwear", "Trousers"), ("Underwear", "Shoes"), ("Trousers", "Shoes"), ("Trousers", "Belt"), ("Socks", "Shoes"),
    ("Shirt", "Belt"), ("Shirt", "Tie"), ("Tie", "Jacket"), ("Belt", "Jacket"),
]

@Reactive
final class TopologicalSortModel {
    var dependencies = startingDependencies
    var selected: Int?
    var plan = BuildPlan(events: [], order: nil, waves: nil, cycle: nil)
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 550)

    init() { replan() }

    /// Runs the search again and shows its end, so an edit shows its answer at once.
    func replan() {
        plan = Explore.plan(clothes: buildSteps.map(\.name), rules: dependencies)
        playback.reset(count: plan.events.count)
        playback.show(plan.events.count)
    }

    /// Adds "`a` before `b`", or removes it if it is there.
    func toggle(_ a: String, _ b: String) {
        if let i = dependencies.firstIndex(where: { $0 == (a, b) }) { dependencies.remove(at: i) } else { dependencies.append((a, b)) }
        replan()
    }

    func tap(_ v: Int) {
        if let u = selected, u != v {
            toggle(buildSteps[u].name, buildSteps[v].name)
            selected = nil
        } else {
            selected = selected == v ? nil : v
        }
    }

    func reset() {
        dependencies = startingDependencies
        selected = nil
        replan()
    }
}

let topological = TopologicalSortModel()

/// What the search has shown after `k` events: who is entered and finished, the order read off
/// the finishes so far (each finished item goes in front), and the back edges met.
struct DressingSnapshot {
    var entered = Set<String>()
    var finished = Set<String>()
    var orderSoFar: [String] = []
    var backEdges: [(String, String)] = []
    var last: DepthFirstSearchEvent<String>?

    init(_ events: [DepthFirstSearchEvent<String>], _ k: Int) {
        for event in events.prefix(k) {
            switch event {
            case .discover(let v): entered.insert(v)
            case .finish(let v):
                finished.insert(v)
                orderSoFar.insert(v, at: 0)
            case .backEdge(let e): backEdges.append((e.source, e.target))
            default: break
            }
        }
        last = k > 0 ? events[k - 1] : nil
    }
}

/// The sentence for one event of the search.
func dressingText(_ event: DepthFirstSearchEvent<String>) -> String {
    switch event {
    case .discover(let v): return "Look at \(v). What has to wait for it?"
    case .finish(let v): return "Everything that waits for \(v) is already placed. So \(v) goes in front of them."
    case .treeEdge(let e): return "\(e.target) waits for \(e.source). Look at \(e.target) next."
    case .backEdge(let e): return "\(e.target) waits for \(e.source), but \(e.target) is still being looked at. The rules go round in a circle."
    case .forwardEdge(let e), .crossEdge(let e): return "\(e.target) waits for \(e.source), and it is already placed. Nothing to do."
    }
}

@View
struct TopologicalSortLab {
    var body: some View {
        let model = topological
        let dependencies = model.dependencies
        let result = model.plan
        let playback = model.playback
        let k = playback.k
        let done = k == result.events.count
        let snapshot = DressingSnapshot(result.events, k)
        let position = Dictionary(uniqueKeysWithValues: (done ? result.order ?? [] : []).enumerated().map { ($0.element, $0.offset + 1) })
        let cycle = done ? result.cycle ?? [] : []
        let cyclePairs = Set(cycle.indices.map { "\(cycle[$0])→\(cycle[($0 + 1) % cycle.count])" })
        let backPairs = Set(snapshot.backEdges.map { "\($0.0)→\($0.1)" })
        let activePair: String = {
            switch snapshot.last {
            case .treeEdge(let e)?, .backEdge(let e)?, .forwardEdge(let e)?, .crossEdge(let e)?: return "\(e.source)→\(e.target)"
            default: return ""
            }
        }()
        let currentItem: String = {
            if done { return "" }
            switch snapshot.last {
            case .discover(let v)?, .finish(let v)?: return v
            default: return ""
            }
        }()
        let hasLoopBack = dependencies.contains { $0 == ("Shoes", "Socks") }
        let nodes = buildSteps.enumerated().map { v, step in
            CanvasNode(x: step.x, y: step.y, name: step.name, badge: position[step.name].map { "\($0)" } ?? "", radius: 17,
                       classes: (cycle.contains(step.name) ? "cycle" : snapshot.finished.contains(step.name) ? "visited" : snapshot.entered.contains(step.name) ? "frontier" : "")
                           + (model.selected == v ? " selected" : "") + (step.name == currentItem ? " current" : ""),
                       nameAbove: step.y < 150)
        }
        let edges = dependencies.map { first, then in
            CanvasEdge(from: buildIndex[first]!, to: buildIndex[then]!, directed: true,
                       classes: (cyclePairs.contains("\(first)→\(then)") || backPairs.contains("\(first)→\(then)") ? "route" : "")
                           + (activePair == "\(first)→\(then)" ? " active" : ""),
                       bend: dependencies.contains { $0 == (then, first) } ? 14 : (first, then) == ("Underwear", "Shoes") ? -22 : 0)
        }
        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Getting dressed")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Clothes, with an arrow from each to the clothes that go on after it", width: 690, height: 400,
                                nodes: nodes, edges: edges, onNode: { topological.tap($0) },
                                onEdge: { i in
                                    let (a, b) = topological.dependencies[i]
                                    topological.toggle(a, b)
                                }, nodeAction: "Pick")
                    p(.class("note")) {
                        if let selected = model.selected {
                            "\(buildSteps[selected].name) is picked. Click what must go on after it, or click \(buildSteps[selected].name) again to let go."
                        } else {
                            "An arrow a → b means a goes on before b. Click one item, then another, to add a rule. Click an arrow to remove it."
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { done ? (result.order == nil ? "No order exists" : "One valid order") : "Event \(k) of \(result.events.count)" }
                        if done, result.order == nil {
                            p(.class("narration")) {
                                "These wait for each other in a circle, "
                                em { (cycle + [cycle.first ?? ""]).joined(separator: " → ") }
                                ". None of them can go first. So "
                                code { "topologicalSort()" }
                                " returns nil, and "
                                code { "findCycle()" }
                                " hands back the circle as proof."
                            }
                        } else {
                            p(.class("narration")) {
                                if let last = snapshot.last {
                                    done ? "Every item is placed. Read the list from the top." : dressingText(last)
                                } else {
                                    "A depth-first search looks at each item in turn. An item goes on the list once everything that waits for it is on the list."
                                }
                            }
                            ol(.class("steps")) {
                                for item in snapshot.orderSoFar { li { item } }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Waves, what could go on together" }
                        if let waves = result.waves {
                            div(.class("gens")) {
                                for (n, wave) in waves.enumerated() {
                                    div(.class("gen")) {
                                        span(.class("label")) { "Wave \(n + 1)" }
                                        for step in wave { span(.class("chip")) { step } }
                                    }
                                }
                            }
                        } else {
                            p(.class("empty")) { "None. The circle never gets started." }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    button(.type(.button), .class(hasLoopBack ? "on" : "")) { hasLoopBack ? "Drop “shoes before socks”" : "Add “shoes before socks”" }
                        .onClick { topological.toggle("Shoes", "Socks") }
                    button(.type(.button)) { "Reset rules" }
                        .onClick { topological.reset() }
                }
                Timeline(
                    playback: playback,
                    marbles: result.events.map { event in
                        let title = dressingText(event)
                        switch event {
                        case .discover(let v): return Marble(kind: "m-blue", radius: 11, letter: String(v.prefix(1)), title: title)
                        case .finish(let v): return Marble(kind: "m-ring", radius: 9, letter: "", title: title + " (\(v))")
                        case .backEdge: return Marble(kind: "m-red", radius: 7, title: title)
                        default: return Marble(kind: "m-grey", radius: 4, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "look at an item"),
                        (Marble(kind: "m-ring", radius: 5), "place it in front"),
                        (Marble(kind: "m-grey", radius: 3.5), "follow a rule"),
                        (Marble(kind: "m-red", radius: 5), "a rule that closes a circle"),
                    ])
                p(.class("note")) { "The timeline is the depth-first search that topologicalSort() runs. An item is placed when it is finished. Press Play to watch it from the start." }
            }
        }
    }
}

/// An optional array of strings, as Swift prints it.
func list(_ items: [String]?) -> String {
    items.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ", ") + "]" } ?? "nil"
}

@View
struct TopologicalSortCodePanel {
    var body: some View {
        let dependencies = topological.dependencies
        let result = topological.plan
        CodePanel(
            snippets: [
                .topoImports,
                Snippet(lines: ["let clothes = [" + buildSteps.map { "\"\($0.name)\"" }.joined(separator: ", ") + "]", "let rules = ["]
                    + dependencies.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                .topoPlan,
            ],
            results: ["\(result.events.count) events", list(result.order), result.waves.map { "\($0.count) waves" } ?? "nil", list(result.cycle)])
    }
}

enum TopologicalSortPage {
    static func mount() {
        mountView(TopologicalSortLab(), in: "app")
        mountView(TopologicalSortCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.tremaux]), in: "names")
    }
}
