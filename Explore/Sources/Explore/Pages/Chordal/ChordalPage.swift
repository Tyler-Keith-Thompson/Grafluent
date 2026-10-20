import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each friend and where they sit, in SVG units of the 640 × 450 view box.
let chordalSpots: [(name: String, x: Double, y: Double)] = [
    ("Ana", 320, 60), ("Ben", 460, 140), ("Cy", 460, 290), ("Dee", 320, 370), ("Eli", 180, 290), ("Fay", 180, 140),
    ("Gus", 470, 410), ("Hal", 60, 215),
]

/// The index in `chordalSpots` of each name.
let chordalIndex: [String: Int] = Dictionary(uniqueKeysWithValues: chordalSpots.enumerated().map { ($0.element.name, $0.offset) })

/// One step of the second lab: a friend visited by maximum cardinality search, or a friend
/// eliminated, with whether their remaining friends all know each other.
enum ChordalStep {
    case visit(Int, count: Int)
    case eliminate(Int, later: [Int], missing: (Int, Int)?)
}

/// The chordal page's state: the friendships taken away, and the steps on what is left, with
/// their playhead.
@Reactive
final class ChordalModel {
    /// Offsets in `acquaintances` of the friendships taken away.
    var removed: [Int] = []
    var steps: [ChordalStep] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-chordal")

    init() { run() }

    var removedPairs: [UndirectedEdge<String>] { removed.map { acquaintances[$0] } }

    var friends: UndirectedAdjacencyList<String> { circleOfFriends(removing: removedPairs) }

    func adjacent(_ a: Int, _ b: Int) -> Bool {
        acquaintances.indices.contains { p in
            !removed.contains(p) && Set([chordalIndex[acquaintances[p].u]!, chordalIndex[acquaintances[p].v]!]) == Set([a, b])
        }
    }

    /// The steps on the friendships left: the visits in maximum cardinality search's order, then
    /// the eliminations in its reverse until one fails.
    func run() {
        let order = chordalOrders(friends).mcs.map { chordalIndex[$0]! }
        var steps: [ChordalStep] = []
        var visited: [Int] = []
        for v in order {
            steps.append(.visit(v, count: visited.filter { adjacent($0, v) }.count))
            visited.append(v)
        }
        let elimination = Array(order.reversed())
        for (i, v) in elimination.enumerated() {
            let later = elimination[(i + 1)...].filter { adjacent($0, v) }
            var missing: (Int, Int)?
            search: for a in later.indices { for b in later.indices where b > a && !adjacent(later[a], later[b]) { missing = (later[a], later[b]); break search } }
            steps.append(.eliminate(v, later: later, missing: missing))
            if missing != nil { break }
        }
        self.steps = steps
        playback.reset(count: steps.count)
    }

    /// Takes friendship `p` away, or gives it back; never leaves anyone without a friend.
    func toggle(_ p: Int) {
        if let i = removed.firstIndex(of: p) {
            removed.remove(at: i)
        } else {
            let ends = [acquaintances[p].u, acquaintances[p].v]
            let lonely = ends.contains { name in
                !acquaintances.indices.contains { q in q != p && !removed.contains(q) && (acquaintances[q].u == name || acquaintances[q].v == name) }
            }
            if lonely { return }
            removed.append(p)
        }
        run()
    }
}

let chordalModel = ChordalModel()

/// The canvas edges: every friendship, faint when taken away, with `classes` for the rest.
func chordalEdges(_ model: ChordalModel, classes: (Int, Int) -> String) -> [CanvasEdge] {
    acquaintances.enumerated().map { p, pair in
        let a = chordalIndex[pair.u]!, b = chordalIndex[pair.v]!
        return CanvasEdge(from: a, to: b, classes: model.removed.contains(p) ? "faint" : classes(a, b))
    }
}

/// The friends with any hole drawn.
@View
struct ChordalLab {
    var body: some View {
        let model = chordalModel
        let answer = chordalAnswers(model.friends)
        let hole = (answer.hole ?? []).map { chordalIndex[$0]! }
        let onHole = { (a: Int, b: Int) -> Bool in
            guard let i = hole.firstIndex(of: a) else { return false }
            return hole[(i + 1) % hole.count] == b || hole[(i + hole.count - 1) % hole.count] == b
        }
        let nodes = chordalSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 17, classes: hole.contains(v) ? "cut" : "")
        }
        let edges = chordalEdges(model) { a, b in onHole(a, b) ? "route" : "" }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Is every loop shortcut?")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eight friends; click a friendship to take it away or give it back", width: 640, height: 450,
                                nodes: nodes, edges: edges, onEdge: { chordalModel.toggle($0) })
                    div(.class("legend")) {
                        span { i(.class("line route")) {}; "a hole: a loop of four or more with no shortcut" }
                        span { i(.class("line faint")) {}; "taken away: click to give back" }
                    }
                    p(.class("note")) { "Click a friendship to take it away. Nobody can be left with no friends." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { answer.chordal ? "Chordal" : "Not chordal" }
                        p(.class("narration")) {
                            if answer.chordal {
                                "Every loop of four or more friends has a shortcut. Take away a friendship to break that."
                            } else {
                                "The loop "
                                em { (answer.hole ?? []).joined(separator: " – ") }
                                " has no shortcut. Each of them is friends only with their neighbours on the loop. findHole() returns it as proof."
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Perfect elimination ordering" }
                        p(.class("narration")) {
                            if let ordering = answer.ordering {
                                ordering.joined(separator: ", ")
                            } else {
                                "None. A graph has one exactly when it is chordal."
                            }
                        }
                        p(.class("note")) { "Take the friends away in this order. Whenever someone goes, the friends they still have all know each other." }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct ChordalCodePanel {
    var body: some View {
        let model = chordalModel
        let answer = chordalAnswers(model.friends)
        let list = { (xs: [String]) in "[" + xs.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        CodePanel(
            snippets: [
                .chordalImports, .chordalFriends,
                Snippet(lines: ["let removed = [" + model.removedPairs.map { "UndirectedEdge(\"\($0.u)\", \"\($0.v)\")" }.joined(separator: ", ") + "]"]),
                .chordalGraph, .chordalTest,
            ],
            results: ["\(answer.chordal)", answer.ordering.map(list) ?? "nil", answer.hole.map(list) ?? "nil"])
    }
}

/// The sentence for one step.
func describeChordalStep(_ step: ChordalStep) -> String {
    func name(_ v: Int) -> String { chordalSpots[v].name }
    switch step {
    case .visit(let v, let count):
        return count == 0
            ? "Visit \(name(v)) first."
            : "Visit \(name(v)) next. \(count) of their friends \(count == 1 ? "is" : "are") visited already, and nobody unvisited has more."
    case .eliminate(let v, let later, let missing):
        if later.isEmpty { return "Take away \(name(v)), the last one left." }
        if let (a, b) = missing {
            return "Take away \(name(v)). Their friends still here include \(name(a)) and \(name(b)), who aren’t friends. The order fails, so the graph isn’t chordal."
        }
        return later.count == 1
            ? "Take away \(name(v)). Only one of their friends is still here."
            : "Take away \(name(v)). Their friends still here, \(nameList(later.map(name))), are all friends with each other."
    }
}

/// Maximum cardinality search, then the elimination it gives.
@View
struct ChordalStepLab {
    var body: some View {
        let model = chordalModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let shown = Array(steps.prefix(k))
        let last = shown.last
        let finished = k == steps.count
        let visited: [Int] = shown.compactMap { if case .visit(let v, _) = $0 { return v } else { return nil } }
        let eliminated: [Int] = shown.compactMap { if case .eliminate(let v, _, _) = $0 { return v } else { return nil } }
        let current: Int = { switch last { case .visit(let v, _)?: return v; case .eliminate(let v, _, _)?: return v; case nil: return -1 } }()
        let failed: (Int, Int)? = { if case .eliminate(_, _, let m)? = last { return m } else { return nil } }()
        let later: [Int] = { if case .eliminate(_, let l, _)? = last { return l } else { return [] } }()
        let counts = chordalSpots.indices.map { v in visited.contains(v) ? nil : Optional(visited.filter { model.adjacent($0, v) }.count) }
        let nodes = chordalSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name,
                badge: eliminated.isEmpty ? (counts[v].map { "\($0)" } ?? "\(visited.firstIndex(of: v)! + 1)") : "",
                radius: 17,
                classes: (eliminated.contains(v) && v != current ? "dim" : later.contains(v) ? "frontier" : visited.contains(v) ? "visited" : "")
                    + (v == current ? " current" : ""))
        }
        let edges = chordalEdges(model) { a, b in
            if let (x, y) = failed, Set([a, b]) == Set([x, y]) { return "route" }
            if eliminated.contains(a) && a != current || eliminated.contains(b) && b != current { return "ghost" }
            return (a == current && later.contains(b)) || (b == current && later.contains(a)) ? "active" : ""
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Maximum cardinality search and elimination")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The friends, visited in maximum cardinality search order and then taken away in reverse", width: 640, height: 450, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "visited" }
                        span { i(.class("dot frontier")) {}; "the friends left when someone is taken away" }
                        span { i(.class("line route")) {}; "the missing friendship" }
                    }
                    p(.class("note")) { eliminated.isEmpty ? "An unvisited circle shows how many of its friends are visited. A visited one shows when it was visited." : "Taken away in the reverse of the visiting order." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Visit the friends one at a time. Always pick someone with the most friends already visited. Then take them away in reverse order. Whoever goes must have friends left who all know each other. Press Step to begin."
                            } else {
                                describeChordalStep(last!)
                                if finished && failed == nil { " Everyone is gone without a failure. So the graph is chordal, and the reverse order is a perfect elimination ordering." }
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
                        switch step {
                        case .visit(_, let count): return Marble(kind: "m-blue", radius: 5 + Double(count) * 1.5, letter: "\(count)", title: describeChordalStep(step))
                        case .eliminate(_, _, let missing):
                            return missing == nil ? Marble(kind: "m-green", radius: 7, title: describeChordalStep(step)) : Marble(kind: "m-red", radius: 9, letter: "✕", title: describeChordalStep(step))
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a visit, with the friends already visited"),
                        (Marble(kind: "m-green", radius: 6), "taken away, remaining friends all friends"),
                        (Marble(kind: "m-red", radius: 6), "taken away, and two of them aren’t"),
                    ])
                p(.class("note")) { "The visits follow maximumCardinalitySearch(). The page does the counts and the checks. isChordal runs the same test in one pass." }
            }
        }
    }
}

/// The steps' code panel.
@View
struct ChordalStepCodePanel {
    var body: some View {
        let model = chordalModel
        let orders = chordalOrders(model.friends)
        let list = { (xs: [String]) in "[" + xs.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        CodePanel(
            snippets: [
                .chordalImports, .chordalFriends,
                Snippet(lines: ["let removed = [" + model.removedPairs.map { "UndirectedEdge(\"\($0.u)\", \"\($0.v)\")" }.joined(separator: ", ") + "]"]),
                .chordalGraph, .chordalOrders,
            ],
            results: [list(orders.mcs), list(orders.lexBFS)])
    }
}

enum ChordalPage {
    static func mount() {
        mountView(ChordalLab(), in: "app")
        mountView(ChordalCodePanel(), in: "code")
        mountView(ChordalStepLab(), in: "steps")
        mountView(ChordalStepCodePanel(), in: "code-steps")
    }
}
