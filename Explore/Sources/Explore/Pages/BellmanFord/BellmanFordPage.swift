import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import ShortestPaths

/// Each currency and where it sits, in SVG units of the 640 × 430 view box: pounds in the middle
/// of the triangle the other three make, so no two trades cross.
let currencySpots: [(name: String, x: Double, y: Double)] = [
    ("USD", 90, 350), ("EUR", 320, 70), ("GBP", 320, 250), ("CHF", 550, 350),
]

let currencyIndex: [String: Int] = Dictionary(uniqueKeysWithValues: currencySpots.enumerated().map { ($0.element.name, $0.offset) })

/// The quotes: what one unit buys, and its cost, −1000 × ln(rate) rounded, so that multiplying
/// rates is adding costs and the best rate is the cheapest path.
let marketQuotes: [(trade: DirectedEdge<String>, rate: Double, cost: Int)] = [
    (DirectedEdge(from: "USD", to: "EUR"), 0.9, 105), (DirectedEdge(from: "USD", to: "GBP"), 0.78, 248),
    (DirectedEdge(from: "EUR", to: "GBP"), 0.86, 151), (DirectedEdge(from: "GBP", to: "EUR"), 1.15, -140),
    (DirectedEdge(from: "EUR", to: "CHF"), 0.96, 41), (DirectedEdge(from: "GBP", to: "CHF"), 1.12, -113),
    (DirectedEdge(from: "CHF", to: "USD"), 1.13, -122),
]

/// The franc-to-dollar quote made a little too generous, so that trading round
/// USD → GBP → CHF → USD pays.
let generousFrancQuote = (trade: DirectedEdge(from: "CHF", to: "USD"), rate: 1.16, cost: -148)

/// `1.0043`, `147.8` or `0.006633`: about four significant figures, the same on every platform.
func rateText(_ x: Double) -> String {
    var places = 4
    if x >= 100 { places = 1 } else if x < 0.01 { places = 6 } else if x < 0.1 { places = 5 }
    var scale = 1.0
    for _ in 0 ..< places { scale *= 10 }
    let n = Int((x * scale).rounded())
    let whole = n / Int(scale), fraction = String(n % Int(scale))
    let digits = String(repeating: "0", count: places - fraction.count) + fraction
    let trimmed = digits.reversed().drop { $0 == "0" }.reversed()
    return trimmed.isEmpty ? "\(whole)" : "\(whole).\(String(trimmed))"
}

/// The search after some events: each currency's cost from dollars, what one dollar buys along
/// the trades found so far, the trade it was last reached by, and the round.
struct MarketState {
    var cost: [String: Int] = ["USD": 0]
    var amount: [String: Double] = ["USD": 1]
    var parent: [String: Int] = [:]
    var round = 0
    var cycle: [String]?
}

@Reactive
final class BellmanFordModel {
    var generous = false
    var market = AdjacencyList<String>()
    var events: [MarketEvent] = []
    var cycle: [String]?
    var states: [MarketState] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 600, scrubID: "scrub-bellmanford")

    init() {
        run()
    }

    var quotes: [(trade: DirectedEdge<String>, rate: Double, cost: Int)] {
        generous ? marketQuotes.map { $0.trade == generousFrancQuote.trade ? generousFrancQuote : $0 } : marketQuotes
    }

    func rate(_ trade: DirectedEdge<String>) -> Double { quotes.first { $0.trade == trade }!.rate }

    func run() {
        (market, events, cycle) = marketSearch(quotes)
        var state = MarketState()
        states = [state]
        for event in events {
            switch event {
            case .round(let k): state.round = k
            case .examine: break
            case .edgeRelaxed(let e, let d):
                let trade = market.edges[e]
                let target = trade.target
                state.amount[target] = state.amount[trade.source]! * rate(trade)
                state.cost[target] = d
                state.parent[target] = e
            case .edgeNotRelaxed: break
            case .negativeCycle(let loop): state.cycle = loop.vertices
            }
            states.append(state)
        }
        playback.reset(count: events.count)
    }

    func choose(generous: Bool) {
        self.generous = generous
        run()
    }

    /// What one dollar buys of `currency` by the trades found by `state`, if any reach it.
    func amount(of currency: String, in state: MarketState) -> Double? {
        state.amount[currency]
    }
}

let bellmanFordModel = BellmanFordModel()

func describeMarketEvent(_ event: MarketEvent, _ model: BellmanFordModel, after: MarketState) -> String {
    switch event {
    case .round(let k):
        return k == 1 ? "Round 1. Start from dollars." : "Round \(k). Look again from each currency that just got a better rate."
    case .examine(let v, _):
        if v == "USD" {
            return after.parent["USD"] == nil ? "Try each trade out of USD." : "Try each trade out of USD again, with more than the dollar we started with."
        }
        let amount = model.amount(of: v, in: after).map { "So far 1 USD buys \(rateText($0)) \(v)." } ?? ""
        return "Try each trade out of \(v). " + amount
    case .edgeRelaxed(let e, _):
        let trade = model.market.edges[e]
        let amount = model.amount(of: trade.target, in: after).map { rateText($0) } ?? "more"
        if trade.target == "USD" {
            return "\(trade.source) → USD at \(rateText(model.rate(trade))) brings back \(amount) USD. That is more than the dollar we started with."
        }
        return "\(trade.source) → \(trade.target) at \(rateText(model.rate(trade))) is better. 1 USD now buys \(amount) \(trade.target)."
    case .edgeNotRelaxed(let e, _):
        let trade = model.market.edges[e]
        if trade.target == "USD", after.parent["USD"] == nil, let start = model.amount(of: trade.source, in: after) {
            return "\(trade.source) → USD at \(rateText(model.rate(trade))) brings back \(rateText(start * model.rate(trade))) USD, less than we started with."
        }
        return "\(trade.source) → \(trade.target) at \(rateText(model.rate(trade))) is no better."
    case .negativeCycle(let loop):
        let names = loop.vertices + [loop.vertices[0]]
        var product = 1.0
        for (a, b) in zip(names, names.dropFirst()) { product *= model.rate(DirectedEdge(from: a, to: b)) }
        return "Rates still improve after \(currencySpots.count) rounds, so some loop pays. \(names.joined(separator: " → ")) turns 1 \(names[0]) into \(rateText(product)). Each lap pays again, so no best rate exists."
    }
}

@View
struct BellmanFordLab {
    var body: some View {
        let model = bellmanFordModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.events.count
        let state = model.states[k]
        let last = k > 0 ? model.events[k - 1] : nil
        let active: Int? = { switch last { case .edgeRelaxed(let e, _)?, .edgeNotRelaxed(let e, _)?: e; default: nil } }()
        let relaxed: Bool = { if case .edgeRelaxed? = last { return true }; return false }()
        let examined: String? = { if case .examine(let v, _)? = last { return v }; return nil }()
        let loop = state.cycle ?? []
        let loopTrades = Set(zip(loop, loop.dropFirst() + loop.prefix(1)).map { DirectedEdge(from: $0.0, to: $0.1) })
        let tree = Set(state.parent.values)
        let nodes = currencySpots.map { spot in
            let amount = model.amount(of: spot.name, in: state)
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)),
                              note: amount.map { rateText($0) } ?? "", radius: 20,
                              classes: (loop.contains(spot.name) ? "cut" : state.cost[spot.name] != nil ? "visited" : "") + (spot.name == examined ? " current" : "") + (spot.name == "USD" ? " source" : ""),
                              nameAbove: spot.y < 100)
        }
        let edges = model.market.edges.indices.map { e in
            let trade = model.market.edges[e]
            return CanvasEdge(from: currencyIndex[trade.source]!, to: currencyIndex[trade.target]!, directed: true, label: rateText(model.rate(trade)),
                              classes: loopTrades.contains(trade) ? "route" : e == active ? (relaxed ? "active" : "faint") : tree.contains(e) ? "tree" : "", bend: 9)
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The currency market")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Four currencies, an arrow for each quote labelled with what one unit buys", width: 640, height: 430, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line tree")) {}; "best way in so far" }
                        span { i(.class("line active")) {}; "a better rate found" }
                        span { i(.class("line route")) {}; "a loop that pays" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(model.events.count) events" : k == 0 ? "\(model.events.count) events to come" : "Round \(state.round), event \(k) of \(model.events.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                model.generous
                                    ? "The same market, but francs now buy 1.16 dollars each. Press Step and watch the dollars."
                                    : "You start with 1 dollar. How much of each other currency can it buy? Press Step."
                            } else if finished && model.cycle == nil {
                                "Nothing improved in round \(state.round), so these are the best rates. The blue arrows show the best way to each currency."
                            } else {
                                describeMarketEvent(last!, model, after: state)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "What 1 USD buys" }
                        div(.class("queue")) {
                            for spot in currencySpots {
                                div(.class(loop.contains(spot.name) ? "qrow top" : "qrow")) {
                                    span { spot.name }
                                    span(.class("num")) { model.amount(of: spot.name, in: state).map(rateText) ?? "–" }
                                }
                            }
                        }
                        p(.class("note")) { "Behind the scenes each trade costs −1000 × ln(rate). Adding those costs multiplies the rates, so the cheapest path is the best rate." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Franc quote")) {
                        button(.type(.button), .class(model.generous ? "" : "on")) { "Fair quotes" }
                            .onClick { bellmanFordModel.choose(generous: false) }
                        button(.type(.button), .class(model.generous ? "on" : "")) { "CHF → USD at 1.16" }
                            .onClick { bellmanFordModel.choose(generous: true) }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: model.events.indices.map { j in
                        let title = describeMarketEvent(model.events[j], model, after: model.states[j + 1])
                        switch model.events[j] {
                        case .round(let r): return Marble(kind: "m-violet", radius: 9, letter: "\(r)", title: title)
                        case .examine(let v, _): return Marble(kind: "m-blue", radius: 8, letter: String(v.prefix(1)), title: title)
                        case .edgeRelaxed: return Marble(kind: "m-ring", radius: 6, title: title)
                        case .edgeNotRelaxed: return Marble(kind: "m-grey", radius: 3.5, title: title)
                        case .negativeCycle: return Marble(kind: "m-red", radius: 11, letter: "!", title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-violet", radius: 6), "a round"),
                        (Marble(kind: "m-blue", radius: 6), "trade onward from a currency"),
                        (Marble(kind: "m-ring", radius: 5), "a better rate"),
                        (Marble(kind: "m-grey", radius: 3.5), "no better"),
                        (Marble(kind: "m-red", radius: 6), "a loop that pays"),
                    ])
                p(.class("note")) { "The events are lazy.bellmanFord(from:weight:)’s. Each number under a currency is what one dollar buys by the best trades found so far." }
            }
        }
    }
}

@View
struct BellmanFordCodePanel {
    var body: some View {
        let model = bellmanFordModel
        CodePanel(
            snippets: [
                .bellmanfordImports,
                Snippet(lines: ["// cost is −1000 × ln(rate), rounded: adding costs multiplies rates", "let quotes: [(trade: DirectedEdge<String>, rate: Double, cost: Int)] = ["]
                    + model.quotes.map { "    (DirectedEdge(from: \"\($0.trade.source)\", to: \"\($0.trade.target)\"), \(rateText($0.rate)), \($0.cost))," } + ["]"]),
                .bellmanfordMarket, .bellmanfordRun,
            ],
            results: ["\(model.events.count) events", "[" + (model.cycle ?? []).map { "\"\($0)\"" }.joined(separator: ", ") + "]"])
    }
}

enum BellmanFordPage {
    static func mount() {
        mountView(BellmanFordLab(), in: "app")
        mountView(BellmanFordCodePanel(), in: "code")
    }
}
