import AdjacencyListModule
import Cycles
import ElementaryUI
import GraphProtocols
import Reactivity
import Walks

/// Each place in the commons and where it sits, in SVG units of the 640 × 470 view box.
let loopSpots: [(name: String, x: Double, y: Double)] = [
    ("Gate", 70, 240), ("Pond", 200, 110), ("Oak", 200, 370), ("Kiosk", 330, 370),
    ("Bridge", 330, 110), ("Lawn", 460, 370), ("Fountain", 460, 110), ("Shed", 590, 240),
]

/// The index in `loopSpots` of each place.
let loopIndex: [String: Int] = Dictionary(uniqueKeysWithValues: loopSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each path, as offsets in `loopSpots`, by position in `commons`.
let loopEnds: [(Int, Int)] = commons.edges.map { (loopIndex[$0.u]!, loopIndex[$0.v]!) }

/// Each path's length in metres, by position: the path from the Kiosk to the Bridge is long.
let loopMetres = [30, 25, 35, 20, 90, 30, 25, 30, 20, 25, 30]

/// The cycle basis page's state: which basis, and the playback over its cycles.
@Reactive
final class CycleBasisModel {
    /// 0 for the fundamental basis, 1 for the minimum basis, 2 for the lightest basis by metres.
    var mode = 1
    @ReactiveIgnored let fundamental = parkFundamentalBasis()
    @ReactiveIgnored let minimum = parkMinimumBasis()
    @ReactiveIgnored let weighted = parkWeightedBasis(loopMetres)
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-basis")

    init() {
        playback.reset(count: minimum.count)
    }

    var basis: [Cycle<String, Int>] {
        switch mode {
        case 0: fundamental
        case 1: minimum
        default: weighted
        }
    }

    func choose(mode: Int) {
        self.mode = mode
        playback.reset(count: basis.count)
        setProperty(id: "basis-mode", "value", to: "\(mode)")
    }
}

let cycleBasisModel = CycleBasisModel()

/// The colour of each path by the first of the shown cycles that uses it.
func loopEdgeColors(_ shown: [Cycle<String, Int>]) -> [Int: Int] {
    var colors = [Int: Int]()
    for (i, cycle) in shown.enumerated() { for e in cycle.edges { colors[e] = i } }
    return colors
}

/// `[[Gate, Pond, Oak], …]`.
func loopList(_ cycles: [Cycle<String, Int>]) -> String {
    "[" + cycles.map { "[" + $0.vertices.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
}

/// The sentence for one cycle of the basis.
func describeCycle(_ cycle: Cycle<String, Int>, number: Int, weighted: Bool) -> String {
    let places = cycle.vertices
    let metres = cycle.edges.reduce(0) { $0 + loopMetres[$1] }
    let size = weighted ? "\(metres) m" : "\(cycle.edges.count) path\(cycle.edges.count == 1 ? "" : "s")"
    return "Cycle \(number): \(nameList(places)), back to \(places[0]). \(size)."
}

/// The commons with the basis cycles shown one by one.
@View
struct CycleBasisLab {
    var body: some View {
        let model = cycleBasisModel
        let playback = model.playback
        let k = playback.k
        let basis = model.basis
        let weighted = model.mode == 2
        let shown = Array(basis.prefix(k))
        let current = k > 0 ? basis[k - 1] : nil
        let edgeColor = loopEdgeColors(shown)
        let currentEdges = Set(current?.edges ?? [])
        let currentPlaces = Set((current?.vertices ?? []).map { loopIndex[$0]! })
        let length = basis.reduce(0) { $0 + $1.edges.count }
        let metres = basis.reduce(0) { total, cycle in total + cycle.edges.reduce(0) { $0 + loopMetres[$1] } }
        let nodes = loopSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 15, classes: currentPlaces.contains(v) ? "current" : (k == 0 ? "" : "dim"))
        }
        let edges = loopEnds.enumerated().map { p, ends in
            let classes = currentEdges.contains(p) ? "tree" : (edgeColor[p].map { "pal\($0 % 8)" } ?? (k == 0 ? "" : "faint"))
            return CanvasEdge(from: ends.0, to: ends.1, label: weighted ? "\(loopMetres[p])" : "", classes: classes)
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A cycle basis of the park")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eight places in a park joined by eleven paths, with the basis cycles shown one at a time", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line tree")) {}; "the cycle just added" }
                        span { i(.class("line pal0")) {}; "an earlier cycle of the basis" }
                        if weighted { span { "numbers: metres" } }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == basis.count ? "The whole basis" : "Cycle \(k) of \(basis.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "The park has \(commons.vertexCount) places and \(commons.edgeCount) paths, so every basis has \(commons.edgeCount - commons.vertexCount + 1) loops. Every closed loop is a combination of \(basis.count) basis cycles. Press Step to see them."
                            } else {
                                describeCycle(current!, number: k, weighted: weighted)
                                if k == basis.count {
                                    weighted ? " Together they use \(metres) m of path, the least any basis can." : (model.mode == 1 ? " Together they use \(length) footpaths, the fewest any basis can." : " Together they use \(length) footpaths. The minimum basis needs \(model.minimum.reduce(0) { $0 + $1.edges.count }).")
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("basis-mode")) {
                                "Basis: "
                                select(.id("basis-mode")) {
                                    option(.value("0")) { "fundamental" }.attributes(.selected, when: model.mode == 0)
                                    option(.value("1")) { "minimum" }.attributes(.selected, when: model.mode == 1)
                                    option(.value("2")) { "lightest by metres" }.attributes(.selected, when: model.mode == 2)
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { cycleBasisModel.choose(mode: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Cycles so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for (n, cycle) in shown.enumerated() {
                                div(.class(n == k - 1 ? "qrow top" : "qrow plain")) {
                                    span { cycle.vertices.joined(separator: " – ") }
                                    span(.class("num")) { weighted ? "\(cycle.edges.reduce(0) { $0 + loopMetres[$1] }) m" : "\(cycle.edges.count) footpaths" }
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
                    marbles: basis.enumerated().map { n, cycle in
                        Marble(kind: "m-pal\(n % 8)", radius: 5 + Double(cycle.edges.count), letter: "\(cycle.edges.count)",
                               title: describeCycle(cycle, number: n + 1, weighted: weighted))
                    },
                    legend: [(Marble(kind: "m-pal1", radius: 8), "one cycle of the basis, with how many paths it has")])
                p(.class("note")) { "Each step shows one more cycle. The library returns the whole basis at once." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct CycleBasisCodePanel {
    var body: some View {
        let model = cycleBasisModel
        let list = loopList
        switch model.mode {
        case 0:
            CodePanel(snippets: [.cyclebasisImports, .cyclebasisPark, .cyclebasisFundamental],
                      results: [list(model.fundamental), "\(model.fundamental.reduce(0) { $0 + $1.edges.count })"])
        case 1:
            CodePanel(snippets: [.cyclebasisImports, .cyclebasisPark, .cyclebasisMinimum],
                      results: [list(model.minimum), "\(model.minimum.reduce(0) { $0 + $1.edges.count })"])
        default:
            CodePanel(snippets: [.cyclebasisImports, .cyclebasisPark, Snippet(lines: ["let metres = \(loopMetres)"]), .cyclebasisWeighted],
                      results: [list(model.weighted)])
        }
    }
}

enum CycleBasisPage {
    static func mount() {
        mountView(CycleBasisLab(), in: "app")
        mountView(CycleBasisCodePanel(), in: "code")
    }
}
