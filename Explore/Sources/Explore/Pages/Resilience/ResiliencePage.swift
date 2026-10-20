import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each rack and where it sits, in SVG units of the 640 × 470 view box, in `machineRoom.vertices` order.
let centreSpots: [(name: String, x: Double, y: Double)] = [
    ("R1", 60, 110), ("R2", 60, 330), ("R3", 190, 330), ("R4", 190, 110),
    ("S1", 450, 110), ("S2", 450, 330), ("S3", 580, 330), ("S4", 580, 110),
    ("P1", 320, 150), ("P2", 320, 290), ("Lab", 600, 420), ("Desk", 480, 440),
]

/// The index in `centreSpots` of each rack.
let centreIndex: [String: Int] = Dictionary(uniqueKeysWithValues: centreSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each patch, as offsets in `centreSpots`, by position in `machineRoom`.
let centreEnds: [(Int, Int)] = machineRoom.edges.map { (centreIndex[$0.u]!, centreIndex[$0.v]!) }

/// The resilience page's state: the playback over k.
@Reactive
final class ResilienceModel {
    @ReactiveIgnored let numbers = centreResilience()
    @ReactiveIgnored let levels = centreLevels()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1500, scrubID: "scrub-resilience")

    init() {
        playback.reset(count: levels.count)
    }
}

let resilienceModel = ResilienceModel()

/// The sentence for one level.
func describeResilienceLevel(_ k: Int, _ groups: [[String]]) -> String {
    let what = k == 1 ? "any single failure" : "any \(k - 1) failures at once"
    let names = groups.map { nameList($0) }.joined(separator: "; ")
    return "k = \(k): \(groups.count) group\(groups.count == 1 ? "" : "s") that stay\(groups.count == 1 ? "s" : "") connected through \(what) among them: \(names)."
}

/// The centre coloured by its k-components, one k at a time.
@View
struct ResilienceLab {
    var body: some View {
        let model = resilienceModel
        let playback = model.playback
        let k = playback.k
        let numbers = model.numbers
        let groups = k > 0 ? model.levels[k - 1] : []
        let cut = Set(numbers.cut.map { centreIndex[$0]! })
        let groupOf = centreGroups(groups)
        let nodes = centreSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, note: k == 0 && cut.contains(v) ? "cut" : "", radius: 15,
                       classes: k == 0 ? (cut.contains(v) ? "current" : "") : (groupOf[v].map { "pal\($0 % 8)" } ?? "dim"))
        }
        let edges = centreEnds.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: k == 0 ? "" : (groupOf[ends.0] != nil && groupOf[ends.0] == groupOf[ends.1] ? "tree" : "faint"))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The data centre's k-components")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twelve racks and their patches, coloured by the groups that survive k − 1 failures", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        if k == 0 {
                            span { i(.class("dot current")) {}; "the smallest set whose failure splits the centre" }
                        } else {
                            span { i(.class("dot pal0")) {}; "one group at this k" }
                            span { i(.class("dot dim")) {}; "in no group at this k" }
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "The whole centre" : "k = \(k) of \(model.levels.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "The centre stays connected through any \(numbers.vertices - 1) rack failure\(numbers.vertices == 2 ? "" : "s"), but not \(numbers.vertices): losing "
                                em { nameList(numbers.cut) }
                                " splits it. Any \(numbers.edges - 1) patch\(numbers.edges == 2 ? "" : "es") can fail too. Press Step to see which groups hold together at each k."
                            } else {
                                describeResilienceLevel(k, groups)
                                if k == model.levels.count { " No group survives \(k) failures, so the hierarchy ends here." }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Groups so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for level in 0 ..< k {
                                for group in model.levels[level] {
                                    div(.class(level == k - 1 ? "qrow top" : "qrow plain")) {
                                        span { nameList(group) }
                                        span(.class("num")) { "k = \(level + 1)" }
                                    }
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
                    marbles: model.levels.enumerated().map { n, groups in
                        Marble(kind: "m-pal\(n % 8)", radius: 6 + Double(groups.count) * 2, letter: "\(n + 1)", title: describeResilienceLevel(n + 1, groups))
                    },
                    legend: [(Marble(kind: "m-pal1", radius: 8), "one k, bigger for more groups")])
                p(.class("note")) { "kComponents() computes every level at once. Each step shows one k." }
            }
        }
    }
}

/// The group each rack is in at one level, by `centreSpots` offset; a rack in no group is absent.
func centreGroups(_ groups: [[String]]) -> [Int: Int] {
    var map = [Int: Int]()
    for (n, group) in groups.enumerated() {
        for name in group where map[centreIndex[name]!] == nil { map[centreIndex[name]!] = n }
    }
    return map
}

/// The lab's code panel.
@View
struct ResilienceCodePanel {
    var body: some View {
        let model = resilienceModel
        let numbers = model.numbers
        let quoted = { (names: [String]) -> String in "[" + names.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        CodePanel(snippets: [.resilienceImports, .resilienceCentre, .resilienceNumbers, .resilienceLevels],
                  results: ["\(numbers.vertices)", "\(numbers.edges)", quoted(numbers.cut), "[" + model.levels.map { "[" + $0.map(quoted).joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"])
    }
}

enum ResiliencePage {
    static func mount() {
        mountView(ResilienceLab(), in: "app")
        mountView(ResilienceCodePanel(), in: "code")
    }
}
