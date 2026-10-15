import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import ShortestPaths

/// The grid's size, and where each block is drawn: `cityCell` view-box units square, after a
/// margin for the column letters and row numbers.
let cityColumns = 13, cityRows = 9
let cityCell = 48.0, cityMargin = 24.0
let cityHome = Block(column: 3, row: 4)
let cityCafé = Block(column: 10, row: 4)
/// A short wall between home and the café, its ends bent back toward home.
let cityWalls: Set<Block> = [
    Block(column: 6, row: 3), Block(column: 7, row: 3), Block(column: 7, row: 4), Block(column: 7, row: 5), Block(column: 6, row: 5),
]

/// `B4` for column 1, row 3: a map's grid reference.
func blockName(_ b: Block) -> String {
    b == cityHome ? "Home" : b == cityCafé ? "the café" : String(UnicodeScalar(UInt8(65 + b.column))) + "\(b.row + 1)"
}

/// `x.y`, one decimal.
func oneDecimal(_ x: Double) -> String {
    let tenths = Int((x * 10).rounded())
    return "\(tenths / 10).\(tenths % 10)"
}

/// A guess as a block shows it: one decimal below 10, whole numbers from there, so it fits.
func cellGuess(_ x: Double) -> String {
    x < 9.95 ? oneDecimal(x) : "\(Int(x.rounded()))"
}

/// `x.yz`, two decimals.
func twoDecimals(_ x: Double) -> String {
    let hundredths = Int((x * 100).rounded())
    let rest = hundredths % 100
    return "\(hundredths / 100)." + (rest < 10 ? "0" : "") + "\(rest)"
}

/// One marble on the timeline, read off the search's events: a block settled (`examine`), a
/// block reached for the first time with its guess (`edgeRelaxed` and `discover`), a shorter
/// way to an open block (`edgeRelaxed`), or a settled block opened again (`edgeRelaxed` and
/// `reopen`). Checks that change nothing are left off.
enum CityStep {
    case settle(block: Block, walked: Double, guess: Double)
    case estimate(block: Block, from: Block, walked: Double, guess: Double)
    case relax(block: Block, from: Block, walked: Double, previous: Double)
    case reopen(block: Block, from: Block, walked: Double, previous: Double)

    var block: Block {
        switch self {
        case .settle(let b, _, _), .estimate(let b, _, _, _), .relax(let b, _, _, _), .reopen(let b, _, _, _): b
        }
    }
}

/// What the grid shows after the first `k` steps.
struct CitySnapshot {
    var walked: [Block: Double] = [:]
    var guess: [Block: Double] = [:]
    var open: Set<Block> = []
    var closed: Set<Block> = []
    var parent: [Block: Block] = [:]
}

/// The A* page's state: the walls, which search is shown, whether the guess overestimates, the
/// timeline and the playhead.
@Reactive
final class AStarModel {
    var walls = cityWalls
    var showsDijkstra = false
    var overestimates = false
    var run = CityRun(city: UndirectedAdjacencyList<Block>(), aStar: [], dijkstra: [], route: nil)
    var steps: [CityStep] = []
    /// The blocks each search settles, and the shortest walk Dijkstra finds.
    var aStarSettled = 0
    var dijkstraSettled = 0
    var shortest: Double?
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 380)

    init() {
        start()
    }

    var overestimate: Double { overestimates ? 3 : 1 }

    /// Runs both searches on the current walls and rewinds to the start.
    func start() {
        run = cityRun(from: cityHome, to: cityCafé, walls: walls, overestimate: overestimate)
        let aStar = AStarModel.timeline(run.aStar, in: run.city)
        let dijkstra = AStarModel.timeline(run.dijkstra, in: run.city)
        aStarSettled = aStar.filter { if case .settle = $0 { true } else { false } }.count
        dijkstraSettled = dijkstra.filter { if case .settle = $0 { true } else { false } }.count
        shortest = run.dijkstra.lazy.compactMap { event -> Double? in
            if case .examine(cityCafé, let d) = event { return d }
            return nil
        }.first
        steps = showsDijkstra ? dijkstra : aStar
        playback.reset(count: steps.count)
    }

    func toggle(_ b: Block) {
        guard b != cityHome, b != cityCafé else { return }
        if walls.contains(b) { walls.remove(b) } else { walls.insert(b) }
        start()
    }

    /// The marbles of A*'s events.
    static func timeline(_ events: [CitySearchEvent], in city: UndirectedAdjacencyList<Block>) -> [CityStep] {
        var steps: [CityStep] = []
        var current = cityHome
        var walked: [Block: Double] = [:]
        var closed: Set<Block> = []
        var reached: (block: Block, previous: Double)?
        for event in events {
            switch event {
            case .discover(let b, let d, let h):
                walked[b] = d
                if b != cityHome || !steps.isEmpty { steps.append(.estimate(block: b, from: current, walked: d, guess: h)) }
            case .examine(let b, let d, let h):
                steps.append(.settle(block: b, walked: d, guess: h))
                closed.insert(b)
                current = b
            case .edgeRelaxed(let arc, let d):
                let b = city.directedView.target(ofEdgeAt: arc)
                if let previous = walked[b] {
                    if closed.contains(b) {
                        reached = (b, previous)
                    } else {
                        steps.append(.relax(block: b, from: current, walked: d, previous: previous))
                    }
                }
                walked[b] = d
            case .reopen(let b, let d, _):
                steps.append(.reopen(block: b, from: current, walked: d, previous: reached?.previous ?? d))
                closed.remove(b)
            case .examineEdge, .edgeNotRelaxed, .finish:
                break
            }
        }
        return steps
    }

    /// The marbles of Dijkstra's events: every guess is zero.
    static func timeline(_ events: [CityDijkstraEvent], in city: UndirectedAdjacencyList<Block>) -> [CityStep] {
        var steps: [CityStep] = []
        var current = cityHome
        var walked: [Block: Double] = [:]
        for event in events {
            switch event {
            case .discover(let b, let d):
                walked[b] = d
                if b != cityHome { steps.append(.estimate(block: b, from: current, walked: d, guess: 0)) }
            case .examine(let b, let d):
                steps.append(.settle(block: b, walked: d, guess: 0))
                current = b
            case .edgeRelaxed(let arc, let d):
                let b = city.directedView.target(ofEdgeAt: arc)
                if let previous = walked[b] { steps.append(.relax(block: b, from: current, walked: d, previous: previous)) }
                walked[b] = d
            case .examineEdge, .edgeNotRelaxed, .finish:
                break
            }
        }
        return steps
    }

    /// The grid after the first `k` steps.
    func snapshot(_ k: Int) -> CitySnapshot {
        var state = CitySnapshot()
        state.walked[cityHome] = 0
        state.guess[cityHome] = showsDijkstra ? 0 : overestimate * cityHome.distance(to: cityCafé)
        state.open.insert(cityHome)
        for step in steps.prefix(k) {
            switch step {
            case .settle(let b, _, _):
                state.open.remove(b)
                state.closed.insert(b)
            case .estimate(let b, let from, let walked, let guess):
                state.walked[b] = walked
                state.guess[b] = guess
                state.parent[b] = from
                state.open.insert(b)
            case .relax(let b, let from, let walked, _):
                state.walked[b] = walked
                state.parent[b] = from
            case .reopen(let b, let from, let walked, _):
                state.walked[b] = walked
                state.parent[b] = from
                state.closed.remove(b)
                state.open.insert(b)
            }
        }
        return state
    }

    /// The blocks of the route from home to the café, by parents, once the café is settled.
    func route(in state: CitySnapshot) -> [Block] {
        guard state.closed.contains(cityCafé) else { return [] }
        var blocks = [cityCafé]
        while let p = state.parent[blocks.last!], blocks.count <= cityColumns * cityRows { blocks.append(p) }
        return blocks.reversed()
    }
}

let aStar = AStarModel()

/// The sentence for one step, as the narration and a marble's tooltip give it.
func describe(_ step: CityStep, dijkstra: Bool) -> String {
    switch step {
    case .settle(let b, let walked, let guess):
        if b == cityHome {
            return dijkstra
                ? "Start at Home. Dijkstra has no sense of direction. A block’s only number is the distance walked to it."
                : "Start at Home. Nothing walked yet, and the straight line to the café is \(oneDecimal(guess)) blocks."
        }
        if b == cityCafé {
            return "Settle the café, \(oneDecimal(walked)) blocks walked. The search stops here."
        }
        return dijkstra
            ? "Settle \(blockName(b)). Its \(oneDecimal(walked)) walked is the least of any open block."
            : "Settle \(blockName(b)). Walked \(oneDecimal(walked)) plus guess \(oneDecimal(guess)) makes \(oneDecimal(walked + guess)), the least of any open block."
    case .estimate(let b, let from, let walked, let guess):
        return dijkstra
            ? "Reach \(blockName(b)) from \(blockName(from)), with \(oneDecimal(walked)) walked."
            : "Reach \(blockName(b)) from \(blockName(from)). Walked \(oneDecimal(walked)) plus guess \(oneDecimal(guess)) makes \(oneDecimal(walked + guess))."
    case .relax(let b, let from, let walked, let previous):
        return "Through \(blockName(from)), \(blockName(b)) is closer. It takes \(oneDecimal(walked)) walked instead of \(oneDecimal(previous))."
    case .reopen(let b, let from, let walked, let previous):
        return "Through \(blockName(from)), \(blockName(b)) is closer, \(oneDecimal(walked)) instead of \(oneDecimal(previous)). But it was already settled. The inflated guess settled it too soon, so it is opened again."
    }
}

/// The grid of blocks: walls, settled and open blocks, the straight-line guess in each, and the
/// route once the café is reached. A click on a block puts up or takes down a wall.
@View
struct CityGrid {
    var walls: Set<Block>
    var state: CitySnapshot
    var current: Block?
    var route: [Block]
    var showsGuess: Bool
    var overestimate: Double

    var body: some View {
        let width = cityMargin + Double(cityColumns) * cityCell + 4
        let height = cityMargin + Double(cityRows) * cityCell + 4
        let line = route.map { b in
            "\(cityMargin + (Double(b.column) + 0.5) * cityCell),\(cityMargin + (Double(b.row) + 0.5) * cityCell)"
        }.joined(separator: " ")
        SVG.svg(.class("grid"), .viewBox(0, 0, .init(width), .init(height)), .custom(name: "role", value: "img"),
                .custom(name: "aria-label", value: "A grid of city blocks, \(cityColumns) across and \(cityRows) down, with walls; Home is at D5 and the café at K5")) {
            for column in 0 ..< cityColumns {
                SVG.text(.x(.init(cityMargin + (Double(column) + 0.5) * cityCell)), .y(17), .textAnchor("middle"), .class("axis-label")) {
                    String(UnicodeScalar(UInt8(65 + column)))
                }
            }
            for row in 0 ..< cityRows {
                SVG.text(.x(11), .y(.init(cityMargin + (Double(row) + 0.5) * cityCell + 5)), .textAnchor("middle"), .class("axis-label")) { "\(row + 1)" }
            }
            for row in 0 ..< cityRows {
                for column in 0 ..< cityColumns {
                    let b = Block(column: column, row: row)
                    let fixed = b == cityHome || b == cityCafé
                    let kind = walls.contains(b) ? "wall" : state.closed.contains(b) ? "closed" : state.open.contains(b) ? "open" : ""
                    let x = cityMargin + Double(column) * cityCell, y = cityMargin + Double(row) * cityCell
                    SVG.g(.class("cell \(kind)" + (fixed ? " fixed" : "") + (b == current ? " current" : "")), .data("cell", value: "\(row * cityColumns + column)")) {
                        SVG.rect(.x(.init(x + 2)), .y(.init(y + 2)), .width(.init(cityCell - 4)), .height(.init(cityCell - 4)), .rx(5)) {}
                        if showsGuess && !walls.contains(b) {
                            SVG.text(.x(.init(x + 6)), .y(.init(y + 16)), .class("h")) { cellGuess(b == cityCafé ? 0 : overestimate * b.distance(to: cityCafé)) }
                        }
                        if fixed {
                            SVG.text(.x(.init(x + cityCell / 2)), .y(.init(y + cityCell - 8)), .textAnchor("middle"), .class("place")) { b == cityHome ? "Home" : "Café" }
                        }
                    }
                }
            }
            if route.count > 1 {
                SVG.polyline(.points(line), .class("route-line")) {}
            }
        }
        ._onEvent(ClickEvent.self) { event in
            guard let i = event.integer("data-cell") else { return }
            aStar.toggle(Block(column: i % cityColumns, row: i / cityColumns))
        }
    }
}

/// The grid, the panels beside it, and the playback controls with the timeline.
@View
struct AStarLab {
    var body: some View {
        let model = aStar
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let dijkstra = model.showsDijkstra
        let state = model.snapshot(k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let route = model.route(in: state)
        let reached = state.closed.contains(cityCafé)
        let open = state.open.sorted {
            let a = state.walked[$0]! + state.guess[$0]!, b = state.walked[$1]! + state.guess[$1]!
            return a < b || (a == b && ($0.column, $0.row) < ($1.column, $1.row))
        }
        let settled = state.closed.count

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Interactive city grid")) {
                div(.class("panel stage")) {
                    CityGrid(walls: model.walls, state: state, current: last?.block, route: route, showsGuess: !dijkstra, overestimate: model.overestimate)
                    div(.class("legend")) {
                        span { i(.class("dot")) {}; "not reached" }
                        span { i(.class("dot frontier")) {}; "open: reached, not settled" }
                        span { i(.class("dot visited")) {}; "settled" }
                        span { i(.class("dot wall")) {}; "wall" }
                        span { i(.class("line route")) {}; "route" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                dijkstra
                                    ? "Dijkstra on the same grid. It has no guesses, so it spreads out evenly from Home. Press Step to begin."
                                    : "Each block shows its straight-line distance to the café. A* adds that guess to the distance walked. Press Step to begin."
                            } else if finished {
                                if reached {
                                    "The café is reached. The red line is the route, \(twoDecimals(state.walked[cityCafé]!)) blocks. "
                                    if dijkstra {
                                        "Dijkstra settled \(settled) blocks to get there. A* settles \(model.aStarSettled)."
                                    } else if model.overestimates, let shortest = model.shortest, state.walked[cityCafé]! > shortest + 1e-9 {
                                        "But the shortest walk is \(twoDecimals(shortest)). A guess that overestimates lets A* settle for a longer route."
                                    } else {
                                        "A* settled \(settled) blocks. Dijkstra settles \(model.dijkstraSettled) on the same grid."
                                    }
                                } else {
                                    "The walls cut the café off. Every block Home can reach is settled, and none of them is the café."
                                }
                            } else {
                                describe(last!, dijkstra: dijkstra)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { dijkstra ? "Open blocks, least walked first" : "Open blocks, least walked + guess first" }
                        div(.class("queue")) {
                            if open.isEmpty {
                                p(.class("empty")) { reached ? "The search stopped at the café." : "Empty" }
                            }
                            for (j, b) in open.prefix(5).enumerated() {
                                div(.class(j == 0 ? "qrow top" : "qrow")) {
                                    span { (b == cityHome ? "Home" : b == cityCafé ? "Café" : blockName(b)) + (j == 0 ? " · next" : "") }
                                    span(.class("num")) {
                                        dijkstra
                                            ? oneDecimal(state.walked[b]!)
                                            : "\(oneDecimal(state.walked[b]!)) + \(oneDecimal(state.guess[b]!))"
                                    }
                                }
                            }
                            if open.count > 5 {
                                p(.class("note")) { "and \(open.count - 5) more" }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Blocks settled to reach the café" }
                        div(.class("stat")) {
                            div(.class(dijkstra ? "" : "good")) {
                                span(.class("num")) { "\(model.aStarSettled)" }
                                model.overestimates ? "A*, guess ×3" : "A*"
                            }
                            div(.class(dijkstra ? "good" : "")) {
                                span(.class("num")) { "\(model.dijkstraSettled)" }
                                "Dijkstra"
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Search")) {
                        button(.type(.button), .class(dijkstra ? "" : "on")) { "A*" }
                            .onClick {
                                aStar.showsDijkstra = false
                                aStar.start()
                            }
                        button(.type(.button), .class(dijkstra ? "on" : "")) { "Dijkstra" }
                            .onClick {
                                aStar.showsDijkstra = true
                                aStar.start()
                            }
                    }
                    button(.type(.button), .class(model.overestimates ? "on" : ""), .custom(name: "aria-pressed", value: model.overestimates ? "true" : "false")) {
                        model.overestimates ? "Honest guess" : "Overestimate ×3"
                    }
                    .onClick {
                        aStar.overestimates.toggle()
                        aStar.start()
                    }
                    button(.type(.button)) { "Reset walls" }
                        .onClick {
                            aStar.walls = cityWalls
                            aStar.start()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { step in
                        let title = describe(step, dijkstra: dijkstra)
                        switch step {
                        case .settle: return Marble(kind: "m-blue", radius: 9, title: title)
                        case .estimate: return Marble(kind: "m-ring", radius: 6, title: title)
                        case .relax: return Marble(kind: "m-green", radius: 5, title: title)
                        case .reopen: return Marble(kind: "m-red", radius: 7, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a block is settled"),
                        (Marble(kind: "m-ring", radius: 5), dijkstra ? "a block is reached" : "a block is reached and given its guess"),
                        (Marble(kind: "m-green", radius: 4), "a shorter way to an open block"),
                        (Marble(kind: "m-red", radius: 5), "a settled block is opened again"),
                    ])
                p(.class("note")) { "Click a block to put up or take down a wall. The small number in a block is its guess, the straight-line distance to the café. Checks that change nothing are left off the timeline." }
            }
        }
    }
}

/// The code panel: the grid, both searches and the route, as the page runs them.
@View
struct AStarCodePanel {
    var body: some View {
        let model = aStar
        let walls = model.walls.sorted { ($0.column, $0.row) < ($1.column, $1.row) }
        CodePanel(
            snippets: [
                .astarImports, .astarBlock,
                Snippet(lines: [
                    "let home = Block(column: \(cityHome.column), row: \(cityHome.row))",
                    "let café = Block(column: \(cityCafé.column), row: \(cityCafé.row))",
                    walls.isEmpty ? "let walls: Set<Block> = []" : "let walls: Set<Block> = [",
                ] + (walls.isEmpty ? [] : walls.map { "    Block(column: \($0.column), row: \($0.row))," } + ["]"])
                    + ["let overestimate = \(model.overestimates ? "3.0" : "1.0")"]),
                .astarCity, .astarSearch, .astarDijkstra, .astarRoute,
            ],
            results: [
                "\(model.run.aStar.count) events",
                model.run.route.map(twoDecimals) ?? "nil",
            ])
    }
}

enum AStarPage {
    static func mount() {
        mountView(AStarLab(), in: "app")
        mountView(AStarCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.dijkstra]), in: "names")
    }
}
