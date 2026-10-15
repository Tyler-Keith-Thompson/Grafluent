import ElementaryUI
import GraphDrawing
import GraphProtocols
import Reactivity

/// The giant component page's school: how many people, and how many friendships it adds.
let giantPeople = 50
let giantFriendships = 75

/// Each person's place in the 680 × 360 view box, from `drawing` scaled to fit, rounded to whole
/// units.
func giantSpots(_ drawing: Drawing<Int>) -> [(x: Double, y: Double)] {
    guard let box = drawing.boundingBox else { return [] }
    let span = SIMD2(max(box.max.x - box.min.x, 1e-9), max(box.max.y - box.min.y, 1e-9))
    var spots = [(x: Double, y: Double)](repeating: (0, 0), count: giantPeople)
    for (v, p) in zip(drawing.vertices, drawing.positions) where v < giantPeople {
        spots[v] = ((24 + (p.x - box.min.x) / span.x * 632).rounded(), (24 + (p.y - box.min.y) / span.y * 312).rounded())
    }
    return spots
}

/// After some friendships: the groups, largest first, and each person's group.
struct GiantState {
    var groups: [[Int]]
    var group: [Int]

    init(_ groups: [[Int]]) {
        self.groups = groups
        group = [Int](repeating: 0, count: giantPeople)
        for (n, members) in groups.enumerated() {
            for v in members { group[v] = n }
        }
    }

    var largest: Int { groups[0].count }
}

@Reactive
final class GiantModel {
    var seed: UInt64 = 1
    var order: [UndirectedEdge<Int>] = []
    /// `states[k]` is the school after the first `k` friendships.
    var states: [GiantState] = []
    var spots: [(x: Double, y: Double)] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 450, scrubID: "scrub-giant")

    init() {
        draw(seed: 1)
    }

    /// Draws the friendships from `seed` with Grafluent and rewinds.
    func draw(seed: UInt64) {
        self.seed = seed
        order = friendshipOrder(people: giantPeople, edgeCount: giantFriendships, seed: seed)
        spots = giantSpots(friendshipDrawing(people: giantPeople, order: order, seed: seed))
        states = (0 ... order.count).map { GiantState(friendshipGroups(people: giantPeople, order: order, added: $0)) }
        playback.reset(count: order.count)
    }
}

let giant = GiantModel()

/// `0.0204`: p for `m` edges among the people, m over the number of pairs.
func giantP(_ m: Int) -> String {
    let pairs = giantPeople * (giantPeople - 1) / 2
    let tenThousandths = (m * 10000 + pairs / 2) / pairs
    let text = "000" + String(tenThousandths)
    return "0." + String(text.suffix(4))
}

/// `1.5`: the average number of friends after `m` friendships, 2m/n, to one decimal.
func giantDegree(_ m: Int) -> String {
    let tenths = (2 * m * 10 + giantPeople / 2) / giantPeople
    return "\(tenths / 10).\(tenths % 10)"
}

/// The sentence for friendship `m` (from 1), with the school before and after it.
func describeFriendship(_ m: Int, _ model: GiantModel) -> String {
    let edge = model.order[m - 1]
    let before = model.states[m - 1], after = model.states[m]
    let a = before.groups[before.group[edge.u]].count, b = before.groups[before.group[edge.v]].count
    var text = before.group[edge.u] == before.group[edge.v]
        ? "Friendship \(m) is between two people already in one group of \(a): it closes a loop, and no group grows."
        : "Friendship \(m) links a group of \(a) and a group of \(b) into one of \(a + b)."
    text += " The largest group has \(after.largest) of \(giantPeople)."
    if m == giantPeople / 2 {
        text += " Each person now has one friend on average: p has reached 1/n."
    }
    return text
}

/// The size of the largest group against the friendships added, the threshold marked.
@View
struct GiantChart {
    var states: [GiantState]
    var k: Int

    /// The chart's x for `i` friendships and y for a group of `size`.
    static func point(_ i: Int, _ size: Int, of m: Int) -> (x: Double, y: Double) {
        (30 + 260 * Double(i) / Double(m), 128 - 118 * Double(size) / Double(giantPeople))
    }

    static func line(_ states: ArraySlice<GiantState>, of m: Int) -> String {
        states.indices.map { i in
            let p = point(i, states[i].largest, of: m)
            return "\(i == 0 ? "M" : "L")\(Int(p.x)),\(Int(p.y))"
        }.joined(separator: " ")
    }

    var body: some View {
        let w = 300.0, h = 150.0, left = 30.0, bottom = 128.0, top = 10.0, right = 290.0
        let m = states.count - 1
        let line = GiantChart.line(states[...], of: m)
        let shown = GiantChart.line(states.prefix(k + 1), of: m)
        let threshold = GiantChart.point(giantPeople / 2, 0, of: m).x
        let dot = GiantChart.point(k, states[k].largest, of: m)
        SVG.svg(.class("chart"), .viewBox(0, 0, .init(w), .init(h)), .custom(name: "role", value: "img"),
                .custom(name: "aria-label", value: "Size of the largest group against friendships added")) {
            SVG.line(.x1(.init(left)), .y1(.init(bottom)), .x2(.init(right)), .y2(.init(bottom)), .class("axis")) {}
            SVG.line(.x1(.init(left)), .y1(.init(top)), .x2(.init(left)), .y2(.init(bottom)), .class("axis")) {}
            SVG.line(.x1(.init(threshold)), .y1(.init(top)), .x2(.init(threshold)), .y2(.init(bottom)), .class("threshold")) {}
            SVG.text(.x(.init(threshold + 4)), .y(.init(top + 10)), .class("tick")) { "p = 1/n" }
            SVG.text(.x(.init(left - 4)), .y(.init(top + 8)), .textAnchor("end"), .class("tick")) { "\(giantPeople)" }
            SVG.text(.x(.init(left - 4)), .y(.init(bottom)), .textAnchor("end"), .class("tick")) { "0" }
            SVG.text(.x(.init(right)), .y(.init(h - 2)), .textAnchor("end"), .class("tick")) { "\(m) friendships" }
            SVG.path(.d(line), .class("ghost-line")) {}
            SVG.path(.d(shown), .class("value-line")) {}
            SVG.circle(.cx(.init(dot.x)), .cy(.init(dot.y)), .r(4), .class("value-dot")) {}
        }
    }
}

@View
struct GiantLab {
    var body: some View {
        let model = giant
        let playback = model.playback
        let k = playback.k
        let state = model.states[k]
        let finished = k == model.order.count
        let newest = k > 0 ? k - 1 : -1
        let nodes = model.spots.enumerated().map { v, spot in
            let size = state.groups[state.group[v]].count
            return CanvasNode(
                x: spot.x, y: spot.y, name: "", radius: 9,
                classes: state.group[v] == 0 && size > 1 ? "visited" : size > 1 ? "small" : "")
        }
        let edges = model.order.prefix(k).enumerated().map { i, edge in
            CanvasEdge(from: edge.u, to: edge.v, classes: (state.group[edge.u] == 0 ? "tree" : "") + (i == newest ? " active" : ""))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A random friendship network")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Fifty people, with \(k) random friendships; the largest group in blue", width: 680, height: 360, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "the largest group" }
                        span { i(.class("dot small")) {}; "a smaller group" }
                        span { i(.class("dot")) {}; "no friends yet" }
                        span { i(.class("line active")) {}; "the newest friendship" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "All \(model.order.count) friendships added" : "Friendship \(k) of \(model.order.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Fifty people, no friendships yet. Each step adds one, between two people picked at random. Watch the largest group."
                            } else if finished {
                                "With three friends each on average, one group holds "
                                em { "\(state.largest) of \(giantPeople)" }
                                ": the giant component. Everyone else is in groups of a few, or alone."
                            } else {
                                describeFriendship(k, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The school now" }
                        div(.class("stat")) {
                            div(.class("good")) {
                                span(.class("num")) { "\(state.largest)" }
                                "in the largest group"
                            }
                            div {
                                span(.class("num")) { giantDegree(k) }
                                "friends each, on average"
                            }
                            div {
                                span(.class("num")) { giantP(k) }
                                "p, with 1/n = 0.0200"
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Largest group as friendships are added" }
                        GiantChart(states: model.states, k: k)
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    span(.class("field")) { "Seed \(model.seed)" }
                    button(.type(.button)) { "Draw again" }
                        .onClick { giant.draw(seed: giant.seed + 1) }
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ... model.order.count).map { m in
                        let edge = model.order[m - 1]
                        let before = model.states[m - 1]
                        let joinsGiant = model.states[m].group[edge.u] == 0
                        let title = describeFriendship(m, model)
                        if before.group[edge.u] == before.group[edge.v] { return Marble(kind: "m-hollow", radius: 5, title: title) }
                        return joinsGiant ? Marble(kind: "m-blue", radius: 8, title: title) : Marble(kind: "m-grey", radius: 6, title: title)
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "two groups join, into the largest"),
                        (Marble(kind: "m-grey", radius: 5), "two smaller groups join"),
                        (Marble(kind: "m-hollow", radius: 4), "a friendship inside a group"),
                    ])
                p(.class("note")) { "The same seed always draws the same friendships. Draw again for another school." }
            }
        }
    }
}

@View
struct GiantCodePanel {
    var body: some View {
        let model = giant
        let k = model.playback.k
        CodePanel(
            snippets: [
                .giantImports,
                Snippet(lines: ["let people = \(giantPeople)", "let edgeCount = \(giantFriendships)", "let seed: UInt64 = \(model.seed)"]),
                .giantDraw,
                Snippet(lines: ["let added = \(k)"]),
                .giantGroups,
                .giantLayout,
            ],
            results: ["\(model.states[k].largest)"])
    }
}

enum GiantPage {
    static func mount() {
        mountView(GiantLab(), in: "app")
        mountView(GiantCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.erdosRenyi, Names.barabasi]), in: "names")
    }
}
