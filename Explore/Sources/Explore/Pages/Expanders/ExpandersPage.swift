import AdjacencyListModule
import ElementaryUI
import Foundation
import GraphProtocols
import Reactivity

/// Where each machine sits: a circle in the 640 × 470 view box, machine 0 at the top.
let ringSpots: [(x: Double, y: Double)] = (0 ..< machines).map { v in
    let angle = 2 * Double.pi * Double(v) / Double(machines) - Double.pi / 2
    return (320 + 205 * cos(angle), 235 + 205 * sin(angle))
}

/// The wirings in the page's order, with their names.
let wiringLabel = ["the ring", "the ring with a skip", "the chordal cycle"]
let wirings = [plainRing, skipRing, chordRing]

/// The expanders page's state: the wiring, and the playback over the message's hops.
@Reactive
final class ExpandersModel {
    var wiring = 2
    @ReactiveIgnored let numbers: [(hops: [[Int]], cables: Int, farthest: Int, gap: Double)] = wirings.map { try! wiringNumbers($0) }
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-expanders")

    init() {
        playback.reset(count: numbers[wiring].hops.count - 1)
    }

    var graph: UndirectedAdjacencyList<Int> { wirings[wiring] }
    var current: (hops: [[Int]], cables: Int, farthest: Int, gap: Double) { numbers[wiring] }

    func choose(wiring: Int) {
        self.wiring = wiring
        playback.reset(count: numbers[wiring].hops.count - 1)
        setProperty(id: "expanders-wiring", "value", to: "\(wiring)")
    }
}

let expandersModel = ExpandersModel()

/// The machines, those that have the message filled in, the newest ring of them picked out.
func hopNodes(_ hops: [[Int]], after k: Int) -> [CanvasNode] {
    var hop = [Int](repeating: -1, count: machines)
    for (h, layer) in hops.enumerated() where h <= k { for v in layer { hop[v] = h } }
    return (0 ..< machines).map { v in
        let classes = hop[v] < 0 ? "" : (hop[v] == k && k > 0 ? "frontier" : (v == 0 ? "current" : "done"))
        return CanvasNode(x: ringSpots[v].x, y: ringSpots[v].y, name: "\(v)", badge: hop[v] > 0 ? "\(hop[v])" : "", radius: 12, classes: classes)
    }
}

/// The cables, those that carried the message in this hop picked out.
func hopEdges(_ graph: UndirectedAdjacencyList<Int>, _ hops: [[Int]], after k: Int) -> [CanvasEdge] {
    var hop = [Int](repeating: -1, count: machines)
    for (h, layer) in hops.enumerated() where h <= k { for v in layer { hop[v] = h } }
    return graph.edges.map { edge in
        let carried = k > 0 && ((hop[edge.u] == k - 1 && hop[edge.v] == k) || (hop[edge.v] == k - 1 && hop[edge.u] == k))
        return CanvasEdge(from: edge.u, to: edge.v, classes: carried ? "tree" : (k > 0 ? "faint" : ""))
    }
}

/// One hop's marble: how many machines hear the message in it.
func hopMarble(_ h: Int, _ hops: [[Int]]) -> Marble {
    Marble(kind: h + 1 == hops.count ? "m-done" : "m-frontier", radius: 4 + Double(hops[h].count) / 2, letter: "\(hops[h].count)", title: describeHops(h, hops))
}

/// The sentence for one hop.
func describeHops(_ h: Int, _ hops: [[Int]]) -> String {
    let reached = hops[0 ... h].reduce(0) { $0 + $1.count }
    let new = hops[h].count
    return "Hop \(h): \(new) more machine\(new == 1 ? "" : "s") hear\(new == 1 ? "s" : "") it, \(reached) of \(machines) in all."
}

/// A message from machine 0 spreading over one wiring, one hop a step.
@View
struct ExpandersLab {
    var body: some View {
        let model = expandersModel
        let playback = model.playback
        let k = playback.k
        let graph = model.graph
        let numbers = model.current
        let hops = numbers.hops
        let finished = k == hops.count - 1
        let nodes = hopNodes(hops, after: k)
        let edges = hopEdges(graph, hops, after: k)
        let reached = hops[0 ... k].reduce(0) { $0 + $1.count }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A message spreading over a wiring")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twenty-nine machines in a ring, their cables, and which have the message after each hop", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot current")) {}; "machine 0, where the message starts" }
                        span { i(.class("dot frontier")) {}; "heard it this hop" }
                        span { i(.class("dot done")) {}; "heard it earlier; number: the hop" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "Before the first hop" : (finished ? "Everyone has it" : "Hop \(k) of \(hops.count - 1)") }
                        p(.class("narration")) {
                            if k == 0 {
                                "Machine 0 has a message for all \(machines). Each hop, every machine that has it passes it along every cable it has. Press Step to send it over \(wiringLabel[model.wiring])."
                            } else {
                                describeHops(k, hops)
                                if finished {
                                    " \(wiringLabel[model.wiring].prefix(1).uppercased() + wiringLabel[model.wiring].dropFirst()) uses \(numbers.cables) cables and its farthest pair is \(numbers.farthest) hops apart. Its spectral gap is \(twoDecimals(numbers.gap)), and bigger is better."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("expanders-wiring")) {
                                "Wiring: "
                                select(.id("expanders-wiring")) {
                                    for (i, name) in wiringLabel.enumerated() {
                                        option(.value("\(i)")) { name }.attributes(.selected, when: model.wiring == i)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { expandersModel.choose(wiring: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The three wirings" }
                        div(.class("queue")) {
                            for (i, name) in wiringLabel.enumerated() {
                                div(.class(i == model.wiring ? "qrow top" : "qrow plain")) {
                                    span { "\(name): \(model.numbers[i].cables) cables" }
                                    span(.class("num")) { "\(model.numbers[i].hops.count - 1) hops to all; gap \(twoDecimals(model.numbers[i].gap))" }
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
                    marbles: (1 ..< hops.count).map { hopMarble($0, hops) },
                    legend: [(Marble(kind: "m-frontier", radius: 7), "a hop; the number is how many hear it then"), (Marble(kind: "m-done", radius: 7), "the last hop")])
                p(.class("note")) { "breadthFirstLayers(from:) gives every hop at once; \(reached) of \(machines) machines have the message after \(k) hop\(k == 1 ? "" : "s")." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct ExpandersCodePanel {
    var body: some View {
        let model = expandersModel
        let numbers = model.current
        let graphName = ["plainRing", "skipRing", "chordRing"][model.wiring]
        CodePanel(
            snippets: [.expandersImports, .expandersWirings, Snippet(lines: ["let graph = \(graphName)"]), .expandersNumbers],
            results: ["[" + numbers.hops.map { "[\($0.map(String.init).joined(separator: ", "))]" }.joined(separator: ", ") + "]",
                      "\(numbers.cables)", "\(numbers.farthest)", twoDecimals(numbers.gap)])
    }
}

enum ExpandersPage {
    static func mount() {
        mountView(ExpandersLab(), in: "app")
        mountView(ExpandersCodePanel(), in: "code")
    }
}
