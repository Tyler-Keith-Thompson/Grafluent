import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import ShortestPaths

/// Each currency and where it sits, in SVG units of the 640 × 430 view box.
let currencySpots: [(name: String, x: Double, y: Double)] = [
    ("USD", 320, 55), ("EUR", 560, 200), ("GBP", 440, 385), ("JPY", 80, 200), ("CHF", 200, 385),
]

let currencyIndex: [String: Int] = Dictionary(uniqueKeysWithValues: currencySpots.enumerated().map { ($0.element.name, $0.offset) })

/// The quotes: what one unit buys, and its cost, −1000 × ln(rate) rounded, so that multiplying
/// rates is adding costs and the best rate is the cheapest path.
let marketQuotes: [(trade: DirectedEdge<String>, rate: Double, cost: Int)] = [
    (DirectedEdge(from: "USD", to: "EUR"), 0.9, 105), (DirectedEdge(from: "EUR", to: "USD"), 1.089, -85),
    (DirectedEdge(from: "USD", to: "GBP"), 0.7734, 257), (DirectedEdge(from: "GBP", to: "USD"), 1.29, -255),
    (DirectedEdge(from: "EUR", to: "GBP"), 0.865, 145), (DirectedEdge(from: "GBP", to: "EUR"), 1.152, -141),
    (DirectedEdge(from: "USD", to: "JPY"), 147.8, -4996), (DirectedEdge(from: "JPY", to: "USD"), 0.006633, 5016),
    (DirectedEdge(from: "EUR", to: "CHF"), 0.9723, 28), (DirectedEdge(from: "CHF", to: "EUR"), 1.008, -8),
    (DirectedEdge(from: "CHF", to: "JPY"), 165.5, -5109), (DirectedEdge(from: "JPY", to: "CHF"), 0.005922, 5129),
]

/// The pound-to-dollar quote once the mistake is fixed.
let fixedPoundQuote = (trade: DirectedEdge(from: "GBP", to: "USD"), rate: 1.267, cost: -237)

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

/// The search after some events: each currency's cost from dollars, the trade it was last
/// reached by, and the round.
struct MarketState {
    var cost: [String: Int] = ["USD": 0]
    var parent: [String: Int] = [:]
    var round = 0
    var cycle: [String]?
}

@Reactive
final class BellmanFordModel {
    var fixed = false
    var market = AdjacencyList<String>()
    var events: [MarketEvent] = []
    var cycle: [String]?
    var states: [MarketState] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 600, scrubID: "scrub-bellmanford")

    init() {
        run()
    }

    var quotes: [(trade: DirectedEdge<String>, rate: Double, cost: Int)] {
        fixed ? marketQuotes.map { $0.trade == fixedPoundQuote.trade ? fixedPoundQuote : $0 } : marketQuotes
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
                let target = market.edges[e].target
                state.cost[target] = d
                state.parent[target] = e
            case .edgeNotRelaxed: break
            case .negativeCycle(let loop): state.cycle = loop.vertices
            }
            states.append(state)
        }
        playback.reset(count: events.count)
    }

    func choose(fixed: Bool) {
        self.fixed = fixed
        run()
    }

    /// What one dollar becomes along `state`'s parent trades into `currency`, or nil when the
    /// trail loops back before reaching dollars.
    func amount(of currency: String, in state: MarketState) -> Double? {
        var product = 1.0, at = currency, steps = 0
        while at != "USD" {
            guard let e = state.parent[at], steps < currencySpots.count else { return nil }
            let trade = market.edges[e]
            product *= rate(trade)
            at = trade.source
            steps += 1
        }
        return product
    }
}

let bellmanFordModel = BellmanFordModel()

func describeMarketEvent(_ event: MarketEvent, _ model: BellmanFordModel, after: MarketState) -> String {
    switch event {
    case .round(let k):
        return k == 1 ? "Round 1: start from dollars." : "Round \(k): look again from every currency whose best rate improved last round."
    case .examine(let v, _):
        if v == "USD" { return "Trade onward from USD, where the money starts." }
        let amount = model.amount(of: v, in: after).map { "1 USD buys \(rateText($0)) \(v) so far" } ?? "its best way in now runs round a loop"
        return "Trade onward from \(v): " + amount + "."
    case .edgeRelaxed(let e, _):
        let trade = model.market.edges[e]
        let amount = model.amount(of: trade.target, in: after).map { rateText($0) } ?? "more"
        return "\(trade.source) → \(trade.target) at \(rateText(model.rate(trade))) gives a better rate: 1 USD now buys \(amount) \(trade.target)."
    case .edgeNotRelaxed(let e, _):
        let trade = model.market.edges[e]
        return "\(trade.source) → \(trade.target) at \(rateText(model.rate(trade))) is no better than the best way to \(trade.target) so far."
    case .negativeCycle(let loop):
        let names = loop.vertices + [loop.vertices[0]]
        var product = 1.0
        for (a, b) in zip(names, names.dropFirst()) { product *= model.rate(DirectedEdge(from: a, to: b)) }
        return "Still improving after \(currencySpots.count) rounds, so there is a loop that pays: \(names.joined(separator: " → ")) turns 1 \(names[0]) into \(rateText(product)). Trade round it forever and you get rich, so no best rate exists."
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
                              note: state.cost[spot.name] == nil ? "" : amount.map { rateText($0) } ?? "↻", radius: 20,
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
                    GraphCanvas(label: "Five currencies, an arrow for each quote labelled with what one unit buys", width: 640, height: 430, nodes: nodes, edges: edges)
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
                                "Start with dollars. What is the most of each other currency one dollar can buy, trading through as many currencies as you like? Press Step."
                            } else if finished && model.cycle == nil {
                                "Nothing improved in round \(state.round), so every rate is the best there is. The blue arrows are the best way to each currency. With the mistaken quote fixed, no loop pays."
                            } else {
                                describeMarketEvent(last!, model, after: state)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "What 1 USD buys" }
                        div(.class("queue")) {
                            for spot in currencySpots where spot.name != "USD" {
                                div(.class(loop.contains(spot.name) ? "qrow top" : "qrow")) {
                                    span { spot.name }
                                    span(.class("num")) { state.cost[spot.name] == nil ? "–" : model.amount(of: spot.name, in: state).map(rateText) ?? "round a loop" }
                                }
                            }
                        }
                        p(.class("note")) { "The search adds each trade’s cost, −1000 × ln(rate): adding logarithms multiplies rates, and a loop of negative total cost multiplies to more than 1." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Pound quote")) {
                        button(.type(.button), .class(model.fixed ? "" : "on")) { "GBP → USD at 1.29" }
                            .onClick { bellmanFordModel.choose(fixed: false) }
                        button(.type(.button), .class(model.fixed ? "on" : "")) { "Fixed: 1.267" }
                            .onClick { bellmanFordModel.choose(fixed: true) }
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
