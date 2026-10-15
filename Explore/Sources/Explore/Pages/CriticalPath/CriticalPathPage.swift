import AdjacencyListModule
import DirectedAcyclicGraphModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Traversal

/// Each task and where it sits, in SVG units of the 700 × 430 view box.
let taskSpots: [(name: String, x: Double, y: Double)] = [
    ("Choose play", 70, 210), ("Cast actors", 210, 110), ("Build set", 300, 285), ("Print posters", 200, 380),
    ("Make costumes", 360, 50), ("Rehearse", 360, 170), ("Sell tickets", 420, 380), ("Dress rehearsal", 530, 170),
    ("Opening night", 630, 280),
]

let taskIndex: [String: Int] = Dictionary(uniqueKeysWithValues: taskSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The schedule after some of Kahn's events: which tasks are ready or scheduled, the earliest
/// each can start given the tasks finished before it so far, and the last edge removed.
struct PlanState {
    var ready: Set<String> = []
    var scheduled: [String] = []
    var earliest: [String: Int] = [:]
    var waiting: [String: Int] = [:]
}

@Reactive
final class CriticalPathModel {
    var events: [PlayKahnEvent] = []
    var critical: [String] = []
    var length = 0
    /// `states[k]` is after the first `k` events.
    var states: [PlanState] = []
    /// The latest each task can start without delaying the opening.
    var latest: [String: Int] = [:]
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-criticalpath")

    init() {
        (events, critical, length) = playSchedule()
        var state = PlanState()
        for spot in taskSpots { state.earliest[spot.name] = 0 }
        states = [state]
        for event in events {
            switch event {
            case .ready(let v): state.ready.insert(v)
            case .emit(let v):
                state.ready.remove(v)
                state.scheduled.append(v)
            case .removeEdge(let e, let left):
                let edge = play.edges[e]
                state.earliest[edge.target] = max(state.earliest[edge.target]!, state.earliest[edge.source]! + days[edge.source]!)
                state.waiting[edge.target] = left
            }
            states.append(state)
        }
        // Backwards, in reverse topological order: a task must finish by the time the earliest of
        // the tasks after it must start.
        let finish = state.earliest["Opening night"]!
        for v in state.scheduled.reversed() {
            let after = comesBefore.filter { $0.source == v }.map { latest[$0.target]! }
            latest[v] = (after.min() ?? finish) - days[v]!
        }
        playback.reset(count: events.count)
    }
}

let criticalPathModel = CriticalPathModel()

func describePlanEvent(_ event: PlayKahnEvent, after: PlanState) -> String {
    switch event {
    case .ready(let v):
        return "\(v) has nothing left to wait for. It is ready."
    case .emit(let v):
        let start = after.earliest[v]!
        return v == "Opening night"
            ? "Opening night is scheduled. Everything before it is done by day \(start)."
            : "Schedule \(v). It starts on day \(start), when the last thing it waits for is done. It takes \(days[v]!) days, until day \(start + days[v]!)."
    case .removeEdge(let e, let left):
        let edge = play.edges[e]
        let finish = after.earliest[edge.source]! + days[edge.source]!
        let wait = left == 0 ? "Nothing else holds it up." : "It still waits for \(left) more."
        return "\(edge.source) ends on day \(finish), so \(edge.target) can’t start before day \(after.earliest[edge.target]!). " + wait
    }
}

@View
struct CriticalPathLab {
    var body: some View {
        let model = criticalPathModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.events.count
        let state = model.states[k]
        let last = k > 0 ? model.events[k - 1] : nil
        let scheduled = Set(state.scheduled)
        let critical = Set(model.critical)
        let criticalSteps = Set(zip(model.critical, model.critical.dropFirst()).map { DirectedEdge(from: $0.0, to: $0.1) })
        let activeEdge: DirectedEdge<String>? = { if case .removeEdge(let e, _)? = last { return play.edges[e] }; return nil }()
        let current: String? = { if case .emit(let v)? = last { return v }; if case .ready(let v)? = last { return v }; return nil }()
        let nodes = taskSpots.map { spot in
            let name = spot.name
            return CanvasNode(x: spot.x, y: spot.y, name: name, badge: days[name]! > 0 ? "\(days[name]!)" : "★",
                              note: scheduled.contains(name) ? (days[name]! > 0 ? "day \(state.earliest[name]!)–\(state.earliest[name]! + days[name]!)" : "day \(state.earliest[name]!)") : "",
                              radius: 17,
                              classes: (finished && critical.contains(name) ? "cut" : scheduled.contains(name) ? "visited" : state.ready.contains(name) ? "frontier" : "")
                                  + (name == current && !finished ? " current" : ""),
                              nameAbove: spot.y < 120)
        }
        let edges = comesBefore.map { step in
            CanvasEdge(from: taskIndex[step.source]!, to: taskIndex[step.target]!, directed: true,
                       classes: step == activeEdge ? "active" : finished && criticalSteps.contains(step) ? "route" : scheduled.contains(step.source) ? "tree" : "")
        }
        let total = max(model.length, 1)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The school play")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The tasks of putting on a school play, an arrow from each task to one that must wait for it, each labelled with its days", width: 700, height: 430, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "ready" }
                        span { i(.class("dot visited")) {}; "scheduled" }
                        span { i(.class("line active")) {}; "a finish passed on" }
                        span { i(.class("line route")) {}; "the critical path" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Scheduled" : k == 0 ? "\(model.events.count) events to come" : "Event \(k) of \(model.events.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Each circle is a task with its length in days. An arrow means the task at its tail must finish first. Press Step to start each task as early as it can."
                            } else if finished {
                                "The play can open on day \(model.length), and no sooner. The tasks "
                                em { model.critical.dropLast().joined(separator: " → ") }
                                " run back to back with no gap. They are the critical path. A day lost on any of them delays the opening."
                            } else {
                                describePlanEvent(last!, after: state)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Schedule, by day" }
                        div(.class("bars")) {
                            for name in state.scheduled where days[name]! > 0 {
                                let start = state.earliest[name]!
                                let slack = model.latest[name]! - start
                                div(.class(finished && critical.contains(name) ? "bar top" : "bar")) {
                                    span { name }
                                    span(.class("track")) {
                                        span(.class("fill"), .style("margin-left: \(start * 100 / total)%; width: \(days[name]! * 100 / total)%; display: block;")) {}
                                    }
                                    span(.class("num")) { finished ? (slack == 0 ? "none" : "+\(slack)") : "\(start)–\(start + days[name]!)" }
                                }
                            }
                        }
                        p(.class("note")) { finished ? "Bars run from day 0 to day \(model.length). The last column is each task’s slack, the days it can slip without moving the opening." : "Bars run from day 0 to day \(model.length)." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                }
                Timeline(
                    playback: playback,
                    marbles: model.events.indices.map { j in
                        let title = describePlanEvent(model.events[j], after: model.states[j + 1])
                        switch model.events[j] {
                        case .ready: return Marble(kind: "m-ring", radius: 6, title: title)
                        case .emit(let v): return Marble(kind: "m-blue", radius: 10, letter: String(v.prefix(1)), title: title)
                        case .removeEdge: return Marble(kind: "m-grey", radius: 4, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-ring", radius: 5), "a task is ready"),
                        (Marble(kind: "m-blue", radius: 6), "a task is scheduled"),
                        (Marble(kind: "m-grey", radius: 3.5), "its finish is passed on"),
                    ])
                p(.class("note")) { "The events come from lazy.kahn(). Each start day is worked out as they come. A finish passed on can only push a later task’s start back." }
            }
        }
    }
}

@View
struct CriticalPathCodePanel {
    var body: some View {
        let model = criticalPathModel
        CodePanel(
            snippets: [.criticalpathImports, .criticalpathProject, .criticalpathKahn, .criticalpathLongest],
            results: [
                "\(model.events.count) events",
                "[" + model.critical.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
                "\(model.length)",
            ])
    }
}

enum CriticalPathPage {
    static func mount() {
        mountView(CriticalPathLab(), in: "app")
        mountView(CriticalPathCodePanel(), in: "code")
    }
}
