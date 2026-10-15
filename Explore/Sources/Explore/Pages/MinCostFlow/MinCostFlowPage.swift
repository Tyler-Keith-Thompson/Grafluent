import AdjacencyListModule
import ElementaryUI
import Flows
import GraphProtocols
import Reactivity

/// Each place and where it sits, in SVG units of the 660 × 430 view box.
let deliverySpots: [(name: String, x: Double, y: Double)] = [
    ("Stock", 50, 215), ("North", 200, 95), ("South", 200, 335), ("Hub", 360, 215),
    ("Ashby", 570, 55), ("Barton", 600, 170), ("Colby", 600, 275), ("Denton", 570, 385),
]

let deliveryIndex: [String: Int] = Dictionary(uniqueKeysWithValues: deliverySpots.enumerated().map { ($0.element.name, $0.offset) })

/// The shops in the order they open.
let shopOrder = ["Ashby", "Barton", "Colby", "Denton"]

/// The cheapest plan with some shops open.
struct DeliveryState {
    var open: [String]
    var flows: [Int]
    var total: Int
    var shipped: Int
}

@Reactive
final class MinCostFlowModel {
    /// `states[k]` is the plan with the first `k` shops open.
    var states: [DeliveryState] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1500, scrubID: "scrub-mincostflow")

    init() {
        states = (0 ... shopOrder.count).map { k in
            let open = Array(shopOrder.prefix(k))
            let plan = deliveryPlan(open: open)!
            return DeliveryState(open: open, flows: plan.flows, total: plan.total, shipped: plan.shipped)
        }
        playback.reset(count: shopOrder.count)
    }
}

let minCostFlowModel = MinCostFlowModel()

/// `North → Hub`.
func deliveryRoadName(_ r: Int) -> String { "\(roads[r].road.source) → \(roads[r].road.target)" }

func describeOpening(_ k: Int, _ model: MinCostFlowModel) -> String {
    let shop = shopOrder[k - 1]
    let before = model.states[k - 1], after = model.states[k]
    let less = roads.indices.filter { after.flows[$0] < before.flows[$0] && roads[$0].road.source != "Stock" }
    let head = "\(shop) opens and wants \(demand[shop]!) crates. The cheapest plan now costs £\(after.total), which is £\(after.total - before.total) more."
    if less.isEmpty { return head + " Every earlier delivery stays as it was." }
    return head + " To make room, fewer crates go along " + less.map(deliveryRoadName).joined(separator: " and ") + "."
}

@View
struct MinCostFlowLab {
    var body: some View {
        let model = minCostFlowModel
        let playback = model.playback
        let k = playback.k
        let finished = k == shopOrder.count
        let state = model.states[k]
        let before = model.states[max(k - 1, 0)]
        let open = Set(state.open)
        let nodes = deliverySpots.map { spot in
            let wanted = demand[spot.name]
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: wanted.map { "\($0)" } ?? "",
                              note: spot.name == "Stock" ? "made up" : "", radius: 17,
                              classes: wanted == nil ? (spot.name == "Stock" ? "dim" : "visited") : open.contains(spot.name) ? "frontier" : "",
                              nameAbove: spot.y < 100)
        }
        let edges = roads.indices.map { r in
            let flow = state.flows[r], road = roads[r]
            let changed = k > 0 && flow != before.flows[r]
            return CanvasEdge(from: deliveryIndex[road.road.source]!, to: deliveryIndex[road.road.target]!, directed: true,
                              label: road.road.source == "Stock" ? "\(flow)/\(road.crates)" : "\(flow)/\(road.crates) £\(road.cost)",
                              classes: (flow > 0 ? "tree" : "") + (changed ? " active" : "") + (road.road.source == "Stock" ? " faint" : ""),
                              bend: road.road == DirectedEdge(from: "North", to: "Barton") ? -16 : road.road == DirectedEdge(from: "South", to: "Colby") ? 16 : 0)
        }
        let used = roads.indices.filter { state.flows[$0] > 0 && roads[$0].road.source != "Stock" }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Deliveries")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Two warehouses, a hub and four shops joined by one-way roads, each labelled crates sent over crates allowed and cost per crate", width: 660, height: 430, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line tree")) {}; "crates on the road" }
                        span { i(.class("line active")) {}; "changed this step" }
                        span { i(.class("dot frontier")) {}; "an open shop, with its demand" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Every shop open" : k == 0 ? "\(shopOrder.count) shops to open" : "\(k) of \(shopOrder.count) shops open" }
                        p(.class("narration")) {
                            if k == 0 {
                                "No shop is open yet. Press Step to open the first one. Each time a shop opens, Grafluent works out the cheapest plan for every shop open so far."
                            } else if finished {
                                describeOpening(k, model)
                                " All 11 crates go out. No plan that stocks every shop costs less than £\(state.total)."
                            } else {
                                describeOpening(k, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The plan" }
                        div(.class("stat")) {
                            div(.class("good")) {
                                span(.class("num")) { "£\(state.total)" }
                                "total cost"
                            }
                            div {
                                span(.class("num")) { "\(state.shipped)" }
                                "crates shipped"
                            }
                        }
                        div(.class("queue")) {
                            if used.isEmpty { p(.class("empty")) { "Nothing to send yet" } }
                            for r in used {
                                div(.class(k > 0 && state.flows[r] != before.flows[r] ? "qrow top" : "qrow")) {
                                    span { deliveryRoadName(r) }
                                    span(.class("num")) { "\(state.flows[r]) × £\(roads[r].cost)" }
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
                    marbles: (1 ... shopOrder.count).map { j in
                        let rerouted = roads.indices.contains { model.states[j].flows[$0] < model.states[j - 1].flows[$0] && roads[$0].road.source != "Stock" }
                        return Marble(kind: rerouted ? "m-violet" : "m-blue", radius: 11, letter: String(shopOrder[j - 1].prefix(1)), title: describeOpening(j, model))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a shop opens, the old deliveries kept"),
                        (Marble(kind: "m-violet", radius: 6), "a shop opens, and old deliveries move"),
                    ])
                p(.class("note")) { "Each step is a fresh minimumCostFlow call with one more shop open: the network simplex itself runs to the optimum in one go. Labels are crates sent / crates allowed, then the cost per crate." }
            }
        }
    }
}

@View
struct MinCostFlowCodePanel {
    var body: some View {
        let model = minCostFlowModel
        let k = model.playback.k
        let state = model.states[k]
        CodePanel(
            snippets: [
                .mincostflowImports, .mincostflowRoads,
                Snippet(lines: ["let open = [" + state.open.map { "\"\($0)\"" }.joined(separator: ", ") + "]"]),
                .mincostflowPlan,
            ],
            results: ["\(state.total)", "\(state.shipped)"])
    }
}

enum MinCostFlowPage {
    static func mount() {
        mountView(MinCostFlowLab(), in: "app")
        mountView(MinCostFlowCodePanel(), in: "code")
    }
}
