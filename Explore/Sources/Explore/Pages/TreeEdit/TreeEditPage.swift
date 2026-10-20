import ElementaryUI
import GraphProtocols
import Reactivity
import Trees

/// The edits from last year's chart to this year's, each applied to the chart before it.
let chartEdits: [(what: String, chart: [String: [String]])] = [
    ("Cy leaves Eng", ["CEO": ["Eng", "Sales"], "Eng": ["Ana", "Bo"], "Sales": ["Di"]]),
    ("Cy joins Sales", ["CEO": ["Eng", "Sales"], "Eng": ["Ana", "Bo"], "Sales": ["Di", "Cy"]]),
    ("Bo leaves", ["CEO": ["Eng", "Sales"], "Eng": ["Ana"], "Sales": ["Di", "Cy"]]),
    ("Ops is founded", ["CEO": ["Eng", "Sales", "Ops"], "Eng": ["Ana"], "Sales": ["Di", "Cy"]]),
    ("Eve joins Ops", thisYear),
]

/// Where each person of a chart sits: leaves left to right, a parent above the middle of its
/// children, rows by depth, inside a box `width` wide starting at `left`.
func chartSpots(_ chart: [String: [String]], left: Double, width: Double) -> [(name: String, x: Double, y: Double)] {
    var leaves = 0
    var spots: [(String, Double, Double)] = []
    func place(_ v: String, depth: Int) -> Double {
        let children = chart[v] ?? []
        let x: Double
        if children.isEmpty {
            x = Double(leaves)
            leaves += 1
        } else {
            let xs = children.map { place($0, depth: depth + 1) }
            x = (xs.first! + xs.last!) / 2
        }
        spots.append((v, x, Double(depth)))
        return x
    }
    _ = place("CEO", depth: 0)
    let slots = Double(max(leaves, 1))
    return spots.map { ($0.0, left + ($0.1 + 0.5) / slots * width, 70 + $0.2 * 130) }
}

/// The tree edit distance page's state: the playback over the edits.
@Reactive
final class TreeEditModel {
    @ReactiveIgnored let distances = chartDistances()
    @ReactiveIgnored let remaining: [Int] = [distanceToThisYear(lastYear)] + chartEdits.map { distanceToThisYear($0.chart) }
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1300, scrubID: "scrub-treeedit")

    init() {
        playback.reset(count: chartEdits.count)
    }
}

let treeEditModel = TreeEditModel()

/// The people whose place changed in edit `step` (1-based); none before the first.
func chartChanged(step k: Int) -> Set<String> {
    guard k > 0 else { return [] }
    let previous = k == 1 ? lastYear : chartEdits[k - 2].chart
    let now = chartEdits[k - 1].chart
    var moved = Set<String>()
    for (parent, kids) in now { for kid in kids where !(previous[parent] ?? []).contains(kid) { moved.insert(kid) } }
    for (parent, kids) in previous { for kid in kids where !(now[parent] ?? []).contains(kid) { moved.insert(kid) } }
    return moved
}

/// The arrows of both charts, the one being edited drawn plainly and the goal faintly.
func chartEdges(_ current: [String: [String]], _ goal: [String: [String]], _ index: [String: Int]) -> [CanvasEdge] {
    var edges: [CanvasEdge] = []
    for (side, chart) in [("L", current), ("R", goal)] {
        for (parent, kids) in chart.sorted(by: { $0.key < $1.key }) {
            for kid in kids { edges.append(CanvasEdge(from: index["\(side)\(parent)"]!, to: index["\(side)\(kid)"]!, directed: true, classes: side == "L" ? "tree" : "faint")) }
        }
    }
    return edges
}

/// The sentence for one edit.
func describeEdit(_ n: Int, _ model: TreeEditModel) -> String {
    let left = model.remaining[n + 1]
    return "Edit \(n + 1): \(chartEdits[n].what). The distance to this year's chart is now \(left)."
}

/// Last year's chart being edited, beside this year's.
@View
struct TreeEditLab {
    var body: some View {
        let model = treeEditModel
        let playback = model.playback
        let k = playback.k
        let current = k == 0 ? lastYear : chartEdits[k - 1].chart
        let changed = chartChanged(step: k)
        let leftSpots = chartSpots(current, left: 20, width: 290)
        let rightSpots = chartSpots(thisYear, left: 330, width: 290)
        let spots = leftSpots + rightSpots
        let index: [String: Int] = Dictionary(uniqueKeysWithValues: spots.enumerated().map { ("\($0.offset < leftSpots.count ? "L" : "R")\($0.element.name)", $0.offset) })
        let nodes = spots.enumerated().map { i, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 14,
                       classes: i < leftSpots.count ? (changed.contains(spot.name) ? "current" : "visited") : "dim")
        }
        let edges = chartEdges(current, thisYear, index)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Editing last year's chart into this year's")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Last year's org chart being edited step by step, beside this year's", width: 640, height: 470, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "last year's chart, as edited so far" }
                        span { i(.class("dot current")) {}; "changed by this edit" }
                        span { i(.class("dot dim")) {}; "this year's chart" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "Two charts" : "Edit \(k) of \(chartEdits.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Turn last year's chart into this year's by deleting and inserting people, one at a time. With a deletion or an insertion costing 1 and a change of name 2, the tree edit distance is \(model.distances.named): the cheapest way to do it. Press Step to make the edits."
                            } else {
                                describeEdit(k - 1, model)
                                if k == chartEdits.count { " The two charts are the same now, after exactly the \(model.distances.named) edits the distance promised." }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Shape only" }
                        p(.class("note")) { "treeEditDistance(to:) alone charges nothing for a substitution, so it compares shapes and ignores names: \(model.distances.unit) here, because once renaming is free last year's Eng can become this year's Sales, and only one deletion and two insertions remain." }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Edits so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for n in 0 ..< k {
                                div(.class(n == k - 1 ? "qrow top" : "qrow plain")) {
                                    span { chartEdits[n].what }
                                    span(.class("num")) { "\(model.remaining[n + 1]) to go" }
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
                    marbles: chartEdits.indices.map { n in
                        Marble(kind: "m-tree", radius: 5 + Double(model.remaining[n + 1]) * 1.5, letter: "\(model.remaining[n + 1])", title: describeEdit(n, model))
                    },
                    legend: [(Marble(kind: "m-tree", radius: 7), "one edit, with the distance left after it")])
                p(.class("note")) { "treeEditDistance(to:) gives the distance, not the edits. The page makes the edits and asks the distance again after each one." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct TreeEditCodePanel {
    var body: some View {
        let model = treeEditModel
        CodePanel(snippets: [.treeeditImports, .treeeditCharts, .treeeditDistance], results: ["\(model.distances.unit)", "\(model.distances.named)"])
    }
}

enum TreeEditPage {
    static func mount() {
        mountView(TreeEditLab(), in: "app")
        mountView(TreeEditCodePanel(), in: "code")
    }
}
