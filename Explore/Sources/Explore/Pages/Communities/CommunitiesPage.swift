import AdjacencyListModule
import CommunityDetection
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each student and where they sit, in SVG units of the 680 × 420 view box.
let studentSpots: [(name: String, x: Double, y: Double)] = [
    ("Ada", 70, 90), ("Bo", 200, 50), ("Cal", 210, 190), ("Dot", 80, 230),
    ("Eve", 170, 340), ("Finn", 300, 390), ("Gia", 330, 290), ("Hugo", 430, 360),
    ("Ivy", 500, 250), ("Jay", 620, 300), ("Kim", 450, 130), ("Leo", 600, 150),
]

let studentIndex: [String: Int] = Dictionary(uniqueKeysWithValues: studentSpots.enumerated().map { ($0.element.name, $0.offset) })

/// One marble on the Louvain timeline.
enum LouvainStep {
    /// Level vertex `vertex` (the students in `members`) moved from community `from` to `to`.
    case move(level: Int, vertex: Int, members: [String], from: Int, to: Int, gain: Double)
    case levelFinished(level: Int, groups: [[String]], modularity: Double)
    case aggregate(level: Int, vertexCount: Int)
}

/// The school after some steps: each student's community at the current level, by the level
/// vertex number naming it, and the modularity so far.
struct LouvainSnapshot {
    var level = 1
    var community: [String: Int]
    var modularity: Double
    var finished: [[String]]? = nil
}

@Reactive
final class CommunitiesModel {
    var events: [SchoolLouvainEvent] = []
    var clubs: [[String]] = []
    var score = 0.0
    var steps: [LouvainStep] = []
    var snapshots: [LouvainSnapshot] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-communities")

    init() {
        (events, clubs, score) = schoolCommunities()
        let names = Array(school.vertices)
        // Each level vertex's students: at the first level, one student each; after an
        // aggregation, the communities of the level just finished, in its order.
        var members = names.map { [$0] }
        var level = 1
        var lastGroups: [[String]] = members
        for event in events {
            switch event {
            case .move(let v, let from, let to, let gain):
                steps.append(.move(level: level, vertex: v, members: members[v], from: from, to: to, gain: gain))
            case .levelFinished(let partition, let modularity):
                lastGroups = partition.map(Array.init)
                steps.append(.levelFinished(level: level, groups: lastGroups, modularity: modularity))
            case .aggregate(let count):
                steps.append(.aggregate(level: level, vertexCount: count))
                members = lastGroups
                level += 1
            }
        }
        // The modularity before any move: the first finished level's, less the gains before it.
        var start = 0.0
        for step in steps {
            if case .move(_, _, _, _, _, let gain) = step { start -= gain }
            if case .levelFinished(_, _, let q) = step { start += q; break }
        }
        var state = LouvainSnapshot(community: Dictionary(uniqueKeysWithValues: names.enumerated().map { ($0.element, $0.offset) }), modularity: start)
        snapshots = [state]
        for step in steps {
            switch step {
            case .move(_, _, let group, _, let to, let gain):
                for s in group { state.community[s] = to }
                state.modularity += gain
            case .levelFinished(_, let groups, let q):
                state.modularity = q
                state.finished = groups
            case .aggregate(_, _):
                state.level += 1
                // Each next-level vertex is a community of the level just finished, numbered in
                // its order, and starts in a community of its own.
                for (j, group) in (state.finished ?? []).enumerated() {
                    for s in group { state.community[s] = j }
                }
                state.finished = nil
            }
            snapshots.append(state)
        }
        playback.reset(count: steps.count)
    }
}

let communitiesModel = CommunitiesModel()

/// `0.375` or `−0.083`.
func signedThree(_ x: Double) -> String {
    x < 0 ? "−" + threePlaces(-x) : threePlaces(x)
}

func studentList(_ names: [String]) -> String {
    names.count == 1 ? names[0] : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// The students in community `c` after `snapshot`.
func communityMembers(_ c: Int, _ snapshot: LouvainSnapshot) -> [String] {
    studentSpots.map(\.name).filter { snapshot.community[$0] == c }
}

func describeLouvain(_ step: LouvainStep, before: LouvainSnapshot, after: LouvainSnapshot) -> String {
    switch step {
    case .move(let level, _, let members, let from, let to, let gain):
        let who = level == 1 ? members[0] : "The group " + studentList(members)
        let joined = communityMembers(to, before)
        let target = joined.isEmpty ? "a group of their own" : "the group with " + studentList(joined)
        _ = from
        return "\(who) moves to \(target). That raises modularity by \(signedThree(gain)), to \(signedThree(after.modularity))."
    case .levelFinished(let level, let groups, let q):
        return "A full pass moves nobody. Level \(level) ends with \(groups.count) groups and modularity \(signedThree(q))."
    case .aggregate(_, let count):
        return "Each group becomes a single dot, and the friendships between groups become weighted links. That leaves \(count) dots. Now whole groups can move."
    }
}

/// The modularity after each step, as a small line chart.
@View
struct ModularityChart {
    var values: [Double]
    var k: Int

    static func point(_ i: Int, _ q: Double, count: Int, low: Double, high: Double) -> (x: Double, y: Double) {
        (48 + 242 * Double(i) / Double(max(count - 1, 1)), 120 - 105 * (q - low) / max(high - low, 1e-9))
    }

    static func line(_ values: ArraySlice<Double>, count: Int, low: Double, high: Double) -> String {
        values.indices.map { i in
            let p = point(i, values[i], count: count, low: low, high: high)
            return "\(i == 0 ? "M" : "L")\(Int(p.x)),\(Int(p.y))"
        }.joined(separator: " ")
    }

    var body: some View {
        let low = min(values.min() ?? 0, 0), high = max(values.max() ?? 1, 0.01)
        let all = ModularityChart.line(values[...], count: values.count, low: low, high: high)
        let shown = ModularityChart.line(values.prefix(k + 1), count: values.count, low: low, high: high)
        let dot = ModularityChart.point(k, values[k], count: values.count, low: low, high: high)
        let zero = ModularityChart.point(0, 0, count: values.count, low: low, high: high).y
        SVG.svg(.class("chart"), .viewBox(0, 0, 300, 140), .custom(name: "role", value: "img"), .custom(name: "aria-label", value: "Modularity after each step")) {
            SVG.line(.x1(48), .y1(.init(zero)), .x2(290), .y2(.init(zero)), .class("axis")) {}
            SVG.text(.x(44), .y(.init(zero + 4)), .textAnchor("end"), .class("tick")) { "0" }
            SVG.text(.x(44), .y(19), .textAnchor("end"), .class("tick")) { signedThree(high) }
            SVG.path(.d(all), .class("ghost-line")) {}
            SVG.path(.d(shown), .class("value-line")) {}
            SVG.circle(.cx(.init(dot.x)), .cy(.init(dot.y)), .r(4), .class("value-dot")) {}
        }
    }
}

@View
struct CommunitiesLab {
    var body: some View {
        let model = communitiesModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let state = model.snapshots[k]
        let before = model.snapshots[max(0, k - 1)]
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let moved: Set<String> = { if case .move(_, _, let members, _, _, _)? = last { return Set(members) }; return [] }()
        // Colours follow the groups: each community gets the colour of its first student, so a
        // group keeps its colour as others join it.
        let labels = studentSpots.map { state.community[$0.name]! }
        let colour: [Int: Int] = Dictionary(labels.enumerated().map { ($1, $0) }, uniquingKeysWith: { a, _ in a })
        let sizes = Dictionary(grouping: labels, by: { $0 }).mapValues(\.count)
        let palette = Array(Set(colour.values)).sorted()
        let nodes = studentSpots.map { spot in
            let c = state.community[spot.name]!
            let shade = sizes[c]! > 1 ? "pal\(palette.firstIndex(of: colour[c]!)! % 8)" : ""
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 17, classes: shade + (moved.contains(spot.name) ? " current" : ""))
        }
        let edges = friendships.map { pair in
            let inside = state.community[pair.u] == state.community[pair.v]
            return CanvasEdge(from: studentIndex[pair.u]!, to: studentIndex[pair.v]!, classes: inside ? "" : "faint")
        }
        let groups = Array(Set(labels)).sorted().map { communityMembers($0, state) }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A school's friendships")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twelve students and their friendships, coloured by group", width: 680, height: 420, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal1")) {}; "a colour per group" }
                        span { i(.class("line")) {}; "a friendship inside a group" }
                        span { i(.class("line faint")) {}; "a friendship between groups" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count), level \(state.level)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Everyone starts in a group of their own. Each student in turn moves to the friend’s group that raises modularity most. If no move helps, they stay put. Press Step to begin."
                            } else if finished {
                                "No dot gains by moving, so Louvain stops. It found "
                                em { "\(model.clubs.count) groups" }
                                ", with modularity \(signedThree(model.score))."
                            } else {
                                describeLouvain(last!, before: before, after: state)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Modularity" }
                        div(.class("stat")) {
                            div(.class("good")) {
                                span(.class("num")) { signedThree(state.modularity) }
                                "now"
                            }
                            div {
                                span(.class("num")) { "\(groups.count)" }
                                "groups"
                            }
                        }
                        ModularityChart(values: model.snapshots.map(\.modularity), k: k)
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Groups of two or more" }
                        div(.class("chips")) {
                            for group in groups where group.count > 1 {
                                let c = state.community[group[0]]!
                                span(.class("chip pal\(palette.firstIndex(of: colour[c]!)! % 8)")) { group.joined(separator: " ") }
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
                    marbles: steps.indices.map { j in
                        let title = describeLouvain(steps[j], before: model.snapshots[j], after: model.snapshots[j + 1])
                        switch steps[j] {
                        case .move(let level, _, let members, _, _, _): return Marble(kind: level == 1 ? "m-blue" : "m-violet", radius: 9, letter: level == 1 ? String(members[0].prefix(1)) : "", title: title)
                        case .levelFinished: return Marble(kind: "m-green", radius: 10, letter: "✓", title: title)
                        case .aggregate: return Marble(kind: "m-hollow", radius: 9, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a student moves"),
                        (Marble(kind: "m-violet", radius: 6), "a whole group moves"),
                        (Marble(kind: "m-green", radius: 6), "a level is finished"),
                        (Marble(kind: "m-hollow", radius: 6), "groups merged into dots"),
                    ])
                p(.class("note")) { "Grey dashed lines are friendships between groups. A good split has few of them." }
            }
        }
    }
}

@View
struct CommunitiesCodePanel {
    var body: some View {
        let model = communitiesModel
        CodePanel(
            snippets: [.communitiesImports, .communitiesSchool, .communitiesLouvain],
            results: [
                "\(model.events.count) events",
                model.clubs.map { "[" + $0.joined(separator: ", ") + "]" }.joined(separator: ", "),
                signedThree(model.score),
            ])
    }
}

enum CommunitiesPage {
    static func mount() {
        mountView(CommunitiesLab(), in: "app")
        mountView(CommunitiesCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.louvain, Names.leiden]), in: "names")
    }
}
