import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Where each package sits in the 640 × 470 view box, in `packages` order.
let packageSpots: [(name: String, x: Double, y: Double)] = [
    ("App", 320, 60), ("Test", 120, 60), ("UI", 200, 170), ("Auth", 460, 170), ("Net", 120, 300), ("Core", 300, 300),
    ("Log", 200, 420), ("DB", 580, 300), ("Cache", 460, 420),
]

let packageIndex: [String: Int] = Dictionary(uniqueKeysWithValues: packageSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The feedback page's state: the plan, and the playback over the cuts.
@Reactive
final class FeedbackModel {
    @ReactiveIgnored let plan = cutPlan()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-feedback")
    @ReactiveIgnored let stages: [(loops: Int, order: [String]?)]

    init() {
        let plan = cutPlan()
        stages = (0 ... plan.cuts.count).map { afterCuts(plan.cuts, count: $0) }
        playback.reset(count: plan.cuts.count)
    }
}

let feedbackModel = FeedbackModel()

/// The packages, the culprits marked once every cut is made.
func cutNodes(_ model: FeedbackModel, after k: Int) -> [CanvasNode] {
    let order = model.stages[k].order
    var rank: [String: Int] = [:]
    if let order { for (i, name) in order.enumerated() { rank[name] = i + 1 } }
    return packageSpots.map { spot in
        let classes = order != nil ? "done" : (model.plan.culprits.contains(spot.name) ? "frontier" : "")
        return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: rank[spot.name].map { "\($0)" } ?? "", radius: 17, classes: classes)
    }
}

/// The arrows: those cut so far faint, the one cut in this step picked out.
func cutEdges(_ model: FeedbackModel, after k: Int) -> [CanvasEdge] {
    let cuts = model.plan.cuts
    return dependencies.edges.indices.map { position in
        let edge = dependencies.edges[position]
        let when = cuts.firstIndex(of: position)
        let classes = when.map { $0 + 1 == k ? "tree" : ($0 < k ? "faint" : "") } ?? ""
        return CanvasEdge(from: packageIndex[edge.source]!, to: packageIndex[edge.target]!, directed: true, classes: classes)
    }
}

/// One cut's marble: how many loops it breaks.
func cutMarble(_ k: Int, _ model: FeedbackModel) -> Marble {
    let broken = model.stages[k - 1].loops - model.stages[k].loops
    return Marble(kind: model.stages[k].loops == 0 ? "m-done" : "m-current", radius: 5 + Double(broken) * 2, letter: "\(broken)", title: describeFeedbackCut(k, model))
}

/// The sentence for one cut.
func describeFeedbackCut(_ k: Int, _ model: FeedbackModel) -> String {
    let edge = dependencies.edges[model.plan.cuts[k - 1]]
    let broken = model.stages[k - 1].loops - model.stages[k].loops
    let left = model.stages[k].loops
    return "Cut \(edge.source) → \(edge.target): \(broken) loop\(broken == 1 ? "" : "s") broken, \(left) left."
}

/// The packages, one cut a step, until a build order exists.
@View
struct FeedbackLab {
    var body: some View {
        let model = feedbackModel
        let playback = model.playback
        let k = playback.k
        let plan = model.plan
        let stage = model.stages[k]
        let nodes = cutNodes(model, after: k)
        let edges = cutEdges(model, after: k)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Cutting dependency loops")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Nine packages and their imports, the cut arrows fading one a step, and the build order once no loop is left", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot frontier")) {}; "a package in every loop’s way: the fewest to rewrite" }
                        span { i(.class("dot done")) {}; "number: its place in the build order" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "Before any cut" : (stage.order != nil ? "No loops left" : "Cut \(k) of \(plan.cuts.count)") }
                        p(.class("narration")) {
                            if k == 0 {
                                "The imports form \(plan.loops) loops, so there is no order to build the packages in. The fewest arrows whose removal breaks every loop number \(plan.cuts.count). Press Step to cut them one at a time."
                            } else {
                                describeFeedbackCut(k, model)
                                if let order = stage.order {
                                    " The packages now build in the order \(nameList(order)). Rewriting the packages "
                                    em { nameList(plan.culprits) }
                                    " would do as well: no loop avoids all three."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Three answers" }
                        div(.class("queue")) {
                            div(.class("qrow top")) { span { "fewest arrows, exact" }; span(.class("num")) { "\(plan.cuts.count)" } }
                            div(.class("qrow plain")) { span { "Eades–Lin–Smyth’s heuristic" }; span(.class("num")) { "\(plan.cheap.count)" } }
                            div(.class("qrow plain")) { span { "fewest packages" }; span(.class("num")) { "\(plan.culprits.count)" } }
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
                    marbles: (1 ... max(plan.cuts.count, 1)).map { cutMarble($0, model) },
                    legend: [(Marble(kind: "m-current", radius: 7), "a cut; the number is the loops it breaks"), (Marble(kind: "m-done", radius: 7), "the cut that breaks the last loop")])
                p(.class("note")) { "minimumFeedbackArcSet() names all \(plan.cuts.count) arrows at once; each step cuts one and counts the loops left with simpleCycles()." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct FeedbackCodePanel {
    var body: some View {
        let model = feedbackModel
        let plan = model.plan
        let k = model.playback.k
        let stage = model.stages[k]
        CodePanel(
            snippets: [.feedbackImports, .feedbackPackages, .feedbackPlan, Snippet(lines: ["let count = \(k)"]), .feedbackAfter],
            results: ["\(plan.loops)", "\(plan.cuts)", "\(plan.cheap)", "\(plan.culprits)", "\(stage.loops)", stage.order.map { "\($0)" } ?? "nil"])
    }
}

enum FeedbackPage {
    static func mount() {
        mountView(FeedbackLab(), in: "app")
        mountView(FeedbackCodePanel(), in: "code")
    }
}
