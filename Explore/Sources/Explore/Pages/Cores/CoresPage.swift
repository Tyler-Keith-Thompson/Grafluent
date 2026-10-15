import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each person in the club and where they sit, in SVG units of the 640 × 470 view box.
let clubSpots: [(name: String, x: Double, y: Double)] = [
    ("Ana", 330, 165), ("Ben", 259, 225), ("Cy", 401, 225), ("Dee", 374, 310), ("Eli", 286, 310),
    ("Fay", 200, 150), ("Gus", 95, 95), ("Hal", 290, 50), ("Ivy", 450, 400), ("Jo", 250, 410),
    ("Kai", 525, 215), ("Lea", 500, 95), ("Max", 580, 430), ("Ned", 600, 300), ("Ola", 610, 40), ("Pat", 35, 200),
]

/// The index in `clubSpots` of each person's name.
let clubIndex: [String: Int] = Dictionary(uniqueKeysWithValues: clubSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each friendship, as offsets in `clubSpots`, by position in `club`.
let clubEnds: [(Int, Int)] = club.edges.map { (clubIndex[$0.u]!, clubIndex[$0.v]!) }

/// One round of peeling: the onion layer removed, and how many friends each person had among
/// those still there just before it, as offsets in `clubSpots`.
struct PeelRound {
    var layer: [Int]
    var degreeBefore: [Int?]
    /// The core number of the people in this layer.
    var core: Int
}

/// The cores page's state: the core or truss shown, its k, and the peeling's rounds and
/// playhead.
@Reactive
final class CoresModel {
    /// 0 for the k-core, 1 for the k-truss.
    var mode = 0
    var k = 3
    @ReactiveIgnored let coreNumber = clubCoreNumbers()
    @ReactiveIgnored let layers = clubLayers()
    @ReactiveIgnored let rounds: [PeelRound]
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-onion")

    init() {
        let coreNumber = clubCoreNumbers()
        var gone = Set<Int>()
        var rounds: [PeelRound] = []
        for names in clubLayers() {
            let layer = names.map { clubIndex[$0]! }
            let degree: [Int?] = clubSpots.indices.map { v in
                gone.contains(v) ? nil : clubEnds.filter { ($0.0 == v && !gone.contains($0.1)) || ($0.1 == v && !gone.contains($0.0)) }.count
            }
            rounds.append(PeelRound(layer: layer, degreeBefore: degree, core: coreNumber[layer[0]]))
            gone.formUnion(layer)
        }
        self.rounds = rounds
        playback.reset(count: rounds.count)
    }

    func choose(mode: Int) {
        self.mode = mode
        setProperty(id: "cores-mode", "value", to: "\(mode)")
    }

    func choose(k: Int) {
        self.k = k
        setProperty(id: "cores-k", "value", to: "\(k)")
    }
}

let coresModel = CoresModel()

/// `Ana, Ben and Cy`.
func nameList(_ names: [String]) -> String {
    names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// The club with the k-core or the k-truss picked out.
@View
struct CoresLab {
    var body: some View {
        let model = coresModel
        let k = model.k
        let truss = model.mode == 1
        let (core, degeneracy) = clubCore(k)
        let strong = clubTruss(k)
        let inCore = Set(core.map { clubIndex[$0]! })
        let strongSet = Set(strong)
        let inTruss = Set(strong.flatMap { [clubEnds[$0].0, clubEnds[$0].1] })
        let nodes = clubSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, badge: truss ? "" : "\(model.coreNumber[v])", radius: 16,
                classes: (truss ? inTruss.contains(v) : inCore.contains(v)) ? "visited" : "dim")
        }
        let edges = clubEnds.enumerated().map { p, ends in
            let kept = truss ? strongSet.contains(p) : inCore.contains(ends.0) && inCore.contains(ends.1)
            return CanvasEdge(from: ends.0, to: ends.1, classes: kept ? "tree" : "faint")
        }
        let people = truss ? clubSpots.indices.filter { inTruss.contains($0) }.map { clubSpots[$0].name } : core

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Cores and trusses of the club")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A club of sixteen people and their friendships, with the \(k)-\(truss ? "truss" : "core") picked out", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; truss ? "in a friendship of the \(k)-truss" : "in the \(k)-core" }
                        span { i(.class("line tree")) {}; truss ? "a friendship in at least \(max(0, k - 2)) triangle\(k == 3 ? "" : "s") of the \(k)-truss" : "a friendship inside the \(k)-core" }
                    }
                    if !truss { p(.class("note")) { "In each circle: the person’s core number, the largest k whose k-core they are in." } }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { truss ? "The \(k)-truss" : "The \(k)-core" }
                        p(.class("narration")) {
                            if truss {
                                if k <= 2 {
                                    "Every friendship is in the 2-truss: it asks for k − 2 = 0 shared friends."
                                } else if strong.isEmpty {
                                    "Nobody. No group is so tight that every friendship in it has \(k - 2) friends in common."
                                } else {
                                    "Keep only the friendships whose two people share at least \(k - 2) friend\(k == 3 ? "" : "s") inside what is kept. \(strong.count) of the \(club.edgeCount) friendships survive, among "
                                    em { nameList(people) }
                                    "."
                                }
                            } else if core.isEmpty {
                                "Nobody: no group has everyone with \(k) friends inside it. The largest k with a core is \(degeneracy), the club’s degeneracy."
                            } else {
                                "The largest group in which everyone has at least \(k) friend\(k == 1 ? "" : "s") inside the group: "
                                em { nameList(core) }
                                "."
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("cores-mode")) {
                                "Show the "
                                select(.id("cores-mode")) {
                                    option(.value("0")) { "k-core" }.attributes(.selected, when: model.mode == 0)
                                    option(.value("1")) { "k-truss" }.attributes(.selected, when: model.mode == 1)
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { coresModel.choose(mode: n) }
                                }
                            }
                            label(.class("field"), .for("cores-k")) {
                                "k = "
                                select(.id("cores-k")) {
                                    for n in 1 ... 5 {
                                        option(.value("\(n)")) { "\(n)" }.attributes(.selected, when: model.k == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { coresModel.choose(k: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Core or truss?" }
                        p(.class("note")) {
                            "A core counts friends; a truss counts shared friends. Cy–Hal and Hal–Lea are in the 3-core but not the 3-truss: Hal has three friends, but shares none of them with Cy or Lea."
                        }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct CoresCodePanel {
    var body: some View {
        let model = coresModel
        let k = model.k
        if model.mode == 1 {
            let strong = clubTruss(k)
            CodePanel(
                snippets: [.coresImports, .coresFriends, Snippet(lines: ["let k = \(k)"]), .coresTruss],
                results: ["\(strong.count) friendships: " + strong.prefix(4).map { "\(club.edges[$0])" }.joined(separator: ", ") + (strong.count > 4 ? ", …" : "")])
        } else {
            let (core, degeneracy) = clubCore(k)
            CodePanel(
                snippets: [.coresImports, .coresFriends, Snippet(lines: ["let k = \(k)"]), .coresCore],
                results: ["[" + core.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "\(degeneracy)"])
        }
    }
}

/// The sentence for one round of peeling.
func describePeel(_ round: PeelRound, number: Int, previous: PeelRound?) -> String {
    let names = round.layer.map { clubSpots[$0].name }
    let left = round.degreeBefore.compactMap { $0 }
    let fewest = left.min() ?? 0
    let lead = "Layer \(number). \(left.count) people are left, and the fewest friends anyone still has is \(fewest). "
    if fewest > round.core || previous == nil || previous!.core < round.core {
        return lead + "Raise k to \(round.core) and peel off everyone with at most \(round.core): \(nameList(names)). They are the \(round.core)-shell, or the start of it: core number \(round.core)."
    }
    return lead + "k stays \(round.core). Peeling the last layer left \(nameList(names)) with only \(round.core), so they go now: still core number \(round.core), one layer deeper."
}

/// Peeling the club layer by layer, as the onion decomposition does.
@View
struct OnionLab {
    var body: some View {
        let model = coresModel
        let playback = model.playback
        let k = playback.k
        let rounds = model.rounds
        let finished = k == rounds.count
        let last = k > 0 ? rounds[k - 1] : nil
        let layerOf: [Int?] = clubSpots.indices.map { v in rounds.prefix(k).firstIndex { $0.layer.contains(v) }.map { $0 + 1 } }
        let nextDegrees = k < rounds.count ? rounds[k].degreeBefore : [Int?](repeating: nil, count: clubSpots.count)
        let nodes = clubSpots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, badge: layerOf[v] == nil ? (nextDegrees[v].map { "\($0)" } ?? "") : "",
                note: layerOf[v].map { "layer \($0)" } ?? "", radius: 16,
                classes: layerOf[v] == nil ? "" : "pal\((model.coreNumber[v] - 1) % 8)" + (last?.layer.contains(v) == true ? " current" : " dim"))
        }
        let edges = clubEnds.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: layerOf[ends.0] != nil || layerOf[ends.1] != nil ? "faint" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Peeling the club layer by layer")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The club peeled from the outside in: each person peeled shows their layer, each person left their friends among those left", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "core 1" }
                        span { i(.class("dot pal1")) {}; "core 2" }
                        span { i(.class("dot pal2")) {}; "core 3" }
                        span { i(.class("dot pal3")) {}; "core 4" }
                        span { i(.class("line faint")) {}; "a friendship with someone peeled" }
                    }
                    p(.class("note")) { "In each circle still there: how many friends the person has among those still there." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(rounds.count) layers" : "Layer \(k) of \(rounds.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Peel the club like an onion. Start with k = 1: take away, all at once, everyone with at most k friends left. If nobody has that few, raise k to the fewest anyone has. Each round is a layer. Press Step to begin."
                            } else {
                                describePeel(last!, number: k, previous: k > 1 ? rounds[k - 2] : nil)
                                if finished { " Nobody is left. The core numbers are the k each person was peeled at; the layers split the shells finer, by how deep inside each one a person sits." }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Layers so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for (n, round) in rounds.prefix(k).enumerated() {
                                div(.class(n == k - 1 ? "qrow top" : "qrow plain")) {
                                    span { nameList(round.layer.map { clubSpots[$0].name }) }
                                    span(.class("num")) { "layer \(n + 1) · core \(round.core)" }
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
                    marbles: rounds.enumerated().map { n, round in
                        Marble(kind: "m-pal\((round.core - 1) % 8)", radius: 6 + Double(round.layer.count), letter: "\(round.core)",
                               title: describePeel(round, number: n + 1, previous: n > 0 ? rounds[n - 1] : nil))
                    },
                    legend: [(Marble(kind: "m-pal2", radius: 7), "one layer, with its core number; bigger for more people")])
                p(.class("note")) { "Each step is one layer of onionLayers(), which computes them all at once; the friend counts are worked out by the page from the friendships still there." }
            }
        }
    }
}

/// The peeling's code panel.
@View
struct OnionCodePanel {
    var body: some View {
        let model = coresModel
        CodePanel(
            snippets: [.coresImports, .coresFriends, .coresOnion],
            results: ["[" + model.layers.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"])
    }
}

enum CoresPage {
    static func mount() {
        mountView(CoresLab(), in: "app")
        mountView(CoresCodePanel(), in: "code")
        mountView(OnionLab(), in: "onion")
        mountView(OnionCodePanel(), in: "code-onion")
        mountView(NamesStrip(names: [Names.batageljZaversnik]), in: "names")
    }
}
