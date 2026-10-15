import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each child on the playground and where they stand, in SVG units of the 640 × 450 view box.
let playSpots: [(name: String, x: Double, y: Double)] = [
    ("Ada", 90, 80), ("Ben", 50, 190), ("Cleo", 200, 100), ("Dan", 180, 215), ("Eve", 90, 300),
    ("Fox", 340, 50), ("Gil", 330, 170), ("Hana", 450, 80), ("Iris", 470, 200), ("Jude", 580, 140),
    ("Kit", 190, 390), ("Lou", 430, 300), ("Max", 370, 390), ("Nell", 520, 390), ("Oz", 280, 310), ("Pip", 270, 420),
]

/// The index in `playSpots` of each name.
let playIndex: [String: Int] = Dictionary(uniqueKeysWithValues: playSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each friendship, as offsets in `playSpots`, by position in `playground`.
let playEnds: [(Int, Int)] = playground.edges.map { (playIndex[$0.u]!, playIndex[$0.v]!) }

/// One visit in a sweep: the child, the rumour they held and the one they hold after, and how many
/// friends told them the most common rumour.
struct RumourStep {
    var sweep: Int
    var child: Int
    var before: Int
    var after: Int
    /// The rumours most friends hold, with that count.
    var leaders: [Int]
    var votes: Int
}

/// The label propagation page's state: the form shown in the first lab, its seed, and the
/// sweeps of the second, with their playhead.
@Reactive
final class LabelPropagationModel {
    var variant = 0
    var seed: UInt64 = 1
    @ReactiveIgnored let steps: [RumourStep]
    /// `labels[k]` is every child's rumour after the first `k` steps.
    @ReactiveIgnored let labels: [[Int]]
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 500, scrubID: "scrub-rumour")

    init() {
        (steps, labels) = LabelPropagationModel.sweeps()
        playback.reset(count: steps.count)
    }

    /// Asynchronous label propagation as asynchronousLabelPropagationCommunities() describes it:
    /// everyone starts with their own rumour, numbered by `vertices` order; sweeps in that order,
    /// each child not holding a most-told rumour taking the greatest-numbered of them, until a
    /// sweep changes nothing.
    static func sweeps() -> ([RumourStep], [[Int]]) {
        let n = playSpots.count
        let friends = (0 ..< n).map { v in playground.neighbors(of: playSpots[v].name).map { playIndex[$0]! } }
        var label = Array(0 ..< n)
        var steps: [RumourStep] = []
        var labels = [label]
        var sweep = 0
        var changed = true
        while changed {
            changed = false
            sweep += 1
            for v in 0 ..< n {
                var counts = [Int](repeating: 0, count: n)
                for w in friends[v] { counts[label[w]] += 1 }
                let most = counts.max() ?? 0
                let leaders = (0 ..< n).filter { counts[$0] == most && most > 0 }
                let before = label[v]
                if !leaders.isEmpty && !leaders.contains(before) {
                    label[v] = leaders.max()!
                    changed = true
                }
                steps.append(RumourStep(sweep: sweep, child: v, before: before, after: label[v], leaders: leaders, votes: most))
                labels.append(label)
            }
        }
        return (steps, labels)
    }

    func choose(variant: Int) {
        self.variant = variant
        setProperty(id: "lp-variant", "value", to: "\(variant)")
    }
}

let labelPropagationModel = LabelPropagationModel()

/// The groups `groups` as a palette index per child, by group order.
func groupColours(_ groups: [[String]]) -> [Int] {
    var colour = [Int](repeating: 0, count: playSpots.count)
    for (g, names) in groups.enumerated() { for name in names { colour[playIndex[name]!] = g } }
    return colour
}

/// The playground coloured by the groups one form of label propagation finds.
@View
struct RumourLab {
    var body: some View {
        let model = labelPropagationModel
        let (groups, score) = rumourGroups(variant: model.variant, seed: model.seed)
        let colour = groupColours(groups)
        let nodes = playSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 15, classes: "pal\(colour[v] % 8)")
        }
        let edges = playEnds.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: colour[ends.0] == colour[ends.1] ? "pal\(colour[ends.0] % 8)" : "faint")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Groups on the playground")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Sixteen children and who plays with whom, coloured by the groups label propagation finds", width: 640, height: 450,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "a colour per group" }
                        span { i(.class("line faint")) {}; "a friendship between groups" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "\(groups.count) group\(groups.count == 1 ? "" : "s") · modularity \(twoPlacesSigned(score))" }
                        p(.class("narration")) {
                            switch model.variant {
                            case 0: "Everyone starts with a rumour of their own. Going round in a fixed order, each child switches to the rumour most of their friends tell, until nobody wants to switch. Each rumour left standing is a group."
                            case 1: "The same rule, but children who aren’t friends with each other switch at the same moment, in rounds. Nobody hears a rumour that changed under them in the same round, which keeps two friends from swapping back and forth."
                            default: "Each sweep goes round in a new random order, and ties are broken at random, from seed \(model.seed). Different seeds can give different groups: label propagation has no single answer."
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("lp-variant")) {
                                "Spread "
                                select(.id("lp-variant")) {
                                    option(.value("0")) { "in order" }.attributes(.selected, when: model.variant == 0)
                                    option(.value("1")) { "in rounds" }.attributes(.selected, when: model.variant == 1)
                                    option(.value("2")) { "in random order" }.attributes(.selected, when: model.variant == 2)
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { labelPropagationModel.choose(variant: n) }
                                }
                            }
                            if model.variant == 2 {
                                button(.type(.button)) { "Draw again" }
                                    .onClick { labelPropagationModel.seed += 1 }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Groups" }
                        div(.class("queue")) {
                            for (g, names) in groups.enumerated() {
                                div(.class("qrow plain")) {
                                    span(.class("chip pal\(g % 8)")) { "\(names.count)" }
                                    span { names.joined(separator: ", ") }
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
struct RumourCodePanel {
    var body: some View {
        let model = labelPropagationModel
        let (groups, score) = rumourGroups(variant: model.variant, seed: model.seed)
        let shown = "[" + groups.map { "[" + $0.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
        CodePanel(
            snippets: [.labelpropagationImports, .labelpropagationPlayground]
                + (model.variant == 2 ? [Snippet(lines: ["let seed: UInt64 = \(model.seed)"])] : [])
                + [[Snippet.labelpropagationAsync, .labelpropagationSemi, .labelpropagationShuffled][model.variant]],
            results: [shown, twoPlacesSigned(score)])
    }
}

/// The sentence for one visit.
func describeRumour(_ step: RumourStep) -> String {
    let child = playSpots[step.child].name
    func rumour(_ l: Int) -> String { "\(playSpots[l].name)’s" }
    let told = step.leaders.count == 1
        ? "\(step.votes) friend\(step.votes == 1 ? "" : "s") tell \(rumour(step.leaders[0])) rumour, more than any other"
        : "\(step.leaders.count) rumours tie at \(step.votes) friend\(step.votes == 1 ? "" : "s") each (\(step.leaders.map { playSpots[$0].name }.joined(separator: ", ")))"
    if step.before != step.after {
        return "\(child): \(told). Switch from \(rumour(step.before)) rumour to \(rumour(step.after))" + (step.leaders.count > 1 ? ", the last of them in the list." : ".")
    }
    return "\(child): \(told). Already holding " + (step.leaders.count > 1 ? "one of them" : "it") + ", so keep \(rumour(step.before))."
}

/// The sweeps, one child at a time.
@View
struct RumourStepLab {
    var body: some View {
        let model = labelPropagationModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let label = model.labels[k]
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let finalLabels = model.labels[steps.count]
        let survivors = Array(Set(finalLabels)).sorted()
        let library = rumourGroups(variant: 0, seed: 1).groups
        let mine = survivors.map { l in playSpots.indices.filter { finalLabels[$0] == l }.map { playSpots[$0].name } }
        let agrees = Set(mine.map(Set.init)) == Set(library.map(Set.init))
        let nodes = playSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, badge: String(playSpots[label[v]].name.prefix(1)), radius: 15,
                classes: (survivors.firstIndex(of: label[v]).map { "pal\($0 % 8)" } ?? "") + (v == last?.child ? " current" : ""))
        }
        let edges = playEnds.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: last.map { ends.0 == $0.child || ends.1 == $0.child } == true ? "active" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Rumours spreading, one child at a time")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The playground with each child’s current rumour, by the initial of the child it started with", width: 640, height: 450,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "holding a rumour that survives to the end" }
                        span { i(.class("line active")) {}; "the friends just heard from" }
                    }
                    p(.class("note")) { "In each circle: whose rumour the child holds, by initial." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(last?.sweep ?? 0) sweeps" : last.map { "Sweep \($0.sweep), visit \(k) of \(steps.count)" } ?? "Visit 0 of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Every child starts with a rumour of their own. Going round in order, each listens to their friends and switches to the rumour most of them tell; on a tie, they keep theirs if it is among the most told, else take the last in the list. Press Step to begin."
                            } else {
                                describeRumour(last!)
                                if finished {
                                    " A whole sweep changed nothing: \(survivors.count) rumours are left, one per group."
                                    agrees ? " The same groups as asynchronousLabelPropagationCommunities()." : " Not the groups asynchronousLabelPropagationCommunities() found."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Rumours still told" }
                        div(.class("chips")) {
                            for l in Array(Set(label)).sorted() {
                                span(.class(survivors.firstIndex(of: l).map { "chip pal\($0 % 8)" } ?? "chip hollow")) {
                                    "\(playSpots[l].name)’s ×\(label.filter { $0 == l }.count)"
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
                        step.before != step.after
                            ? Marble(kind: "m-blue", radius: 9, letter: String(playSpots[step.after].name.prefix(1)), title: describeRumour(step))
                            : Marble(kind: "m-hollow", radius: 5, title: describeRumour(step))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a child switches rumour, to the one shown"),
                        (Marble(kind: "m-hollow", radius: 5), "a child keeps theirs"),
                    ])
                p(.class("note")) { "The visits are the page’s own, following the rule asynchronousLabelPropagationCommunities() documents, which returns only the groups; the last step is checked against it." }
            }
        }
    }
}

/// The sweeps' code panel.
@View
struct RumourStepCodePanel {
    var body: some View {
        let (groups, score) = rumourGroups(variant: 0, seed: 1)
        CodePanel(
            snippets: [.labelpropagationImports, .labelpropagationPlayground, .labelpropagationAsync],
            results: ["[" + groups.map { "[" + $0.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]", twoPlacesSigned(score)])
    }
}

enum LabelPropagationPage {
    static func mount() {
        mountView(RumourLab(), in: "app")
        mountView(RumourCodePanel(), in: "code")
        mountView(RumourStepLab(), in: "sweeps")
        mountView(RumourStepCodePanel(), in: "code-sweeps")
    }
}
