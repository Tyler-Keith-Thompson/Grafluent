import AdjacencyListModule
import ElementaryUI
import GraphDrawing
import GraphProtocols
import Reactivity

/// Everyone in the two circles, in `vertices` order.
let circlePeople = circles(open: crossLinks).vertices.map { $0 }

/// The index in `circlePeople` of each name.
let circleIndex: [String: Int] = Dictionary(uniqueKeysWithValues: circlePeople.enumerated().map { ($0.element, $0.offset) })

/// `x` to two decimal places, with a true minus sign.
func twoPlacesSigned(_ x: Double) -> String {
    let n = Int((x * 100).rounded())
    let r = abs(n) % 100
    return (n < 0 ? "−" : "") + "\(abs(n) / 100)." + (r < 10 ? "0" : "") + "\(r)"
}

/// `x` to three decimal places.
func threePlacesPlain(_ x: Double) -> String {
    let n = Int((x * 1000).rounded())
    let r = n % 1000
    return "\(n / 1000)." + String(repeating: "0", count: 3 - String(r).count) + "\(r)"
}

/// One threshold of the sweep: the first `k` people of the Fiedler order on one side, the rest
/// on the other, the links cut and the ratio cut.
struct SweepCut {
    var k: Int
    var cut: Int
    var ratio: Double
}

/// The spectral page's state: which links between the circles are open, and what Grafluent
/// makes of the result; the sweep's playhead.
@Reactive
final class SpectralModel {
    var open = [true, true, false]
    var drawing: Drawing<String>
    var split: (connectivity: Double, values: [Double], negative: [String])?
    var order: [String] = []
    var sweep: [SweepCut] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-sweep")

    init() {
        drawing = try! spectralDrawing(circles(open: crossLinks))
        run()
    }

    var openLinks: [UndirectedEdge<String>] { crossLinks.indices.filter { open[$0] }.map { crossLinks[$0] } }

    var graph: UndirectedAdjacencyList<String> { circles(open: openLinks) }

    /// Asks Grafluent again after a link changes, and rewinds the sweep.
    func run() {
        let g = graph
        drawing = try! spectralDrawing(g)
        split = try! fiedlerSplit(g)
        order = split == nil ? [] : try! fiedlerOrder(g)
        let n = order.count
        sweep = n < 2 ? [] : (1 ..< n).map { k in
            let left = Set(order.prefix(k))
            let cut = g.edges.filter { left.contains($0.u) != left.contains($0.v) }.count
            return SweepCut(k: k, cut: cut, ratio: Double(cut) * (1 / Double(k) + 1 / Double(n - k)))
        }
        playback.reset(count: sweep.count)
    }

    func toggle(link: Int) {
        open[link].toggle()
        run()
    }

    /// Where each person is drawn in a `width` × `height` view box: the drawing scaled to fit,
    /// each axis on its own, rounded to a tenth.
    func spots(width: Double, height: Double) -> [(x: Double, y: Double)] {
        let at = circlePeople.map { drawing.positions[drawing.vertices.firstIndex(of: $0)!] }
        let xs = at.map(\.x), ys = at.map(\.y)
        func scale(_ v: Double, _ low: Double, _ high: Double, _ size: Double) -> Double {
            let t = high - low < 1e-9 ? 0.5 : (v - low) / (high - low)
            return ((50 + t * (size - 100)) * 10).rounded() / 10
        }
        return at.map { (scale($0.x, xs.min()!, xs.max()!, width), scale($0.y, ys.min()!, ys.max()!, height)) }
    }
}

let spectralModel = SpectralModel()

/// The canvas edges of the circles: every tie, then each link between them, faint when closed.
func circleEdges(open: [Bool], cutSide: [Int: Bool]? = nil) -> [CanvasEdge] {
    insideTies.map { tie in
        let crossing = cutSide.map { $0[circleIndex[tie.u]!] != $0[circleIndex[tie.v]!] } ?? false
        return CanvasEdge(from: circleIndex[tie.u]!, to: circleIndex[tie.v]!, classes: crossing ? "route" : "")
    } + crossLinks.enumerated().map { j, link in
        let crossing = cutSide.map { $0[circleIndex[link.u]!] != $0[circleIndex[link.v]!] } ?? false
        return CanvasEdge(from: circleIndex[link.u]!, to: circleIndex[link.v]!, classes: open[j] ? (crossing ? "route" : "tree") : "faint")
    }
}

/// The circles drawn by their Laplacian's eigenvectors, coloured by the Fiedler vector's sign.
@View
struct SpectralLab {
    var body: some View {
        let model = spectralModel
        let split = model.split
        let spots = model.spots(width: 640, height: 440)
        let nodes = circlePeople.enumerated().map { v, name in
            CanvasNode(
                x: spots[v].x, y: spots[v].y, name: name, note: split.map { twoPlacesSigned($0.values[v]) } ?? "", radius: 12,
                classes: split.map { $0.values[v] < 0 ? "pal0" : "pal1" } ?? "")
        }
        let lineNodes: [CanvasNode] = split.map { s in
            let low = s.values.min()!, high = s.values.max()!
            let ranked = circlePeople.indices.sorted { (s.values[$0], $0) < (s.values[$1], $1) }
            return circlePeople.indices.map { v in
                let rank = ranked.firstIndex(of: v)!
                return CanvasNode(x: ((20 + (s.values[v] - low) / (high - low) * 380) * 10).rounded() / 10, y: 25 + Double(rank % 3) * 45,
                                  name: circlePeople[v], radius: 8, classes: s.values[v] < 0 ? "pal0" : "pal1")
            }
        } ?? []

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The circles drawn by eigenvectors")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Thirteen friends in two circles, placed by the Laplacian’s second and third eigenvectors; click a link between the circles to open or close it", width: 640, height: 440,
                                nodes: nodes, edges: circleEdges(open: model.open),
                                onEdge: { e in if e >= insideTies.count { spectralModel.toggle(link: e - insideTies.count) } })
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "Fiedler value below 0" }
                        span { i(.class("dot pal1")) {}; "0 or above" }
                        span { i(.class("line tree")) {}; "a link between the circles" }
                        span { i(.class("line faint")) {}; "closed: click to open" }
                    }
                    p(.class("note")) { "Nobody chose these positions. Across is each person’s Fiedler value, and down is their value in the next eigenvector. The number under each name is the Fiedler value." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "Algebraic connectivity " + (split.map { threePlacesPlain($0.connectivity) } ?? "0") }
                        p(.class("narration")) {
                            if let split {
                                (model.openLinks.count == 1 ? "There is 1 link" : "There are \(model.openLinks.count) links") + " between the circles. λ₂, the algebraic connectivity, measures how well the network is joined. More links across give a larger λ₂. Splitting by the sign of the Fiedler vector puts "
                                em { blockList(split.negative) }
                                " on one side."
                            } else {
                                "No link joins the circles, so the network is in two pieces. λ₂ is 0, and there is no Fiedler vector, so fiedlerVector() returns nil. The drawing sets the two pieces apart."
                            }
                        }
                    }
                    if split != nil {
                        div(.class("panel")) {
                            span(.class("label")) { "Everyone on the Fiedler line" }
                            GraphCanvas(label: "Each person placed by their Fiedler value alone, lowest first", width: 420, height: 160, nodes: lineNodes, edges: [])
                        }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct SpectralCodePanel {
    var body: some View {
        let model = spectralModel
        let split = model.split
        CodePanel(
            snippets: [
                .spectralImports, .spectralFriends,
                Snippet(lines: ["let open = [" + model.openLinks.map { "UndirectedEdge(\"\($0.u)\", \"\($0.v)\")" }.joined(separator: ", ") + "]"]),
                .spectralCircles, .spectralLayout, .spectralFiedler,
            ],
            results: split.map { [threePlacesPlain($0.connectivity), "[" + $0.negative.map { "\"\($0)\"" }.joined(separator: ", ") + "]"] } ?? ["(returned nil)", ""])
    }
}

/// The sentence for one threshold of the sweep.
func describeSweep(_ cut: SweepCut, order: [String], best: Int, signSplit: Int) -> String {
    let left = Array(order.prefix(cut.k))
    let first = cut.k == 1 ? "Put \(left[0]), first in the Fiedler order, on one side." : "Put \(blockList(left)), the first \(cut.k) in the Fiedler order, on one side."
    var text = first + " \(cut.cut == 1 ? "1 link crosses" : "\(cut.cut) links cross") between the sides, and the ratio cut is \(threePlacesPlain(cut.ratio))."
    if cut.k == signSplit { text += " This is the sign split, with everyone below 0 on one side." }
    if cut.k == best { text += " It is the best ratio of any threshold." }
    return text
}

/// The sweep along the Fiedler order, one threshold at a time.
@View
struct SweepLab {
    var body: some View {
        let model = spectralModel
        let playback = model.playback
        let k = playback.k
        let sweep = model.sweep
        let order = model.order
        let spots = model.spots(width: 640, height: 440)
        let best = sweep.min { ($0.ratio, $0.k) < ($1.ratio, $1.k) }?.k ?? 0
        let signSplit = model.split?.negative.count ?? 0
        let current = k > 0 ? sweep[k - 1] : nil
        let left = Set(order.prefix(current?.k ?? 0))
        let side: [Int: Bool]? = current.map { _ in Dictionary(uniqueKeysWithValues: circlePeople.indices.map { ($0, left.contains(circlePeople[$0])) }) }
        let nodes = circlePeople.enumerated().map { v, name in
            CanvasNode(x: spots[v].x, y: spots[v].y, name: name, badge: order.firstIndex(of: name).map { "\($0 + 1)" } ?? "", radius: 13,
                       classes: current == nil ? "" : left.contains(name) ? "pal0" : "pal1")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Sweeping a cut along the Fiedler order")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The circles numbered in Fiedler order, with the current threshold’s two sides coloured and the links it cuts marked", width: 640, height: 440,
                                nodes: nodes, edges: circleEdges(open: model.open, cutSide: side))
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "before the threshold" }
                        span { i(.class("dot pal1")) {}; "after it" }
                        span { i(.class("line route")) {}; "a link the threshold cuts" }
                    }
                    p(.class("note")) { "The number in each circle is the person’s place in spectralOrdering(), lowest Fiedler value first." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { sweep.isEmpty ? "No sweep" : k == sweep.count ? "Done after \(sweep.count) thresholds" : "Threshold \(k) of \(sweep.count)" }
                        p(.class("narration")) {
                            if sweep.isEmpty {
                                "With the circles apart there is no Fiedler vector to sweep. Open a link between the circles in the first drawing."
                            } else if let current {
                                describeSweep(current, order: order, best: best, signSplit: signSplit)
                            } else {
                                "The Fiedler vector puts everyone on a line. Each place to cut that line is a candidate split. Try them all. Score each by the links it cuts and by how even the two sides are. Press Step to begin."
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Every threshold so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for cut in sweep.prefix(k) {
                                div(.class(cut.k == best && k == sweep.count ? "qrow top" : "qrow plain")) {
                                    span { "\(cut.k) | \(order.count - cut.k)" + (cut.k == signSplit ? " (sign)" : "") }
                                    span(.class("num")) { "\(cut.cut) cut · \(threePlacesPlain(cut.ratio))" }
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
                    marbles: sweep.map { cut in
                        Marble(kind: cut.k == best ? "m-red" : cut.k == signSplit ? "m-violet" : "m-blue", radius: 4 + Double(cut.cut), letter: "\(cut.cut)",
                               title: describeSweep(cut, order: order, best: best, signSplit: signSplit))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a threshold, with the links it cuts"),
                        (Marble(kind: "m-violet", radius: 6), "the sign split"),
                        (Marble(kind: "m-red", radius: 6), "the best ratio cut"),
                    ])
                p(.class("note")) { "The page runs the sweep itself. It cuts spectralOrdering()’s order at each point in turn and counts the links. The ratio cut is the links cut × (1/|S| + 1/|T|), where |S| and |T| are the sizes of the two sides." }
            }
        }
    }
}

/// The sweep's code panel.
@View
struct SweepCodePanel {
    var body: some View {
        let model = spectralModel
        CodePanel(
            snippets: [
                .spectralImports, .spectralFriends,
                Snippet(lines: ["let open = [" + model.openLinks.map { "UndirectedEdge(\"\($0.u)\", \"\($0.v)\")" }.joined(separator: ", ") + "]"]),
                .spectralCircles, .spectralOrdering,
            ],
            results: ["[" + model.order.map { "\"\($0)\"" }.joined(separator: ", ") + "]"])
    }
}

enum SpectralPage {
    static func mount() {
        mountView(SpectralLab(), in: "app")
        mountView(SpectralCodePanel(), in: "code")
        mountView(SweepLab(), in: "sweep")
        mountView(SweepCodePanel(), in: "code-sweep")
        mountView(NamesStrip(names: [Names.fiedler]), in: "names")
    }
}
