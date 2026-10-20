import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each clearing and where it sits, in SVG units of the 640 × 470 view box, in `trails.vertices` order.
let trailSpots: [(name: String, x: Double, y: Double)] = [
    ("A1", 70, 90), ("A2", 170, 60), ("A3", 190, 170), ("A4", 90, 190),
    ("B1", 330, 290), ("B2", 290, 400), ("B3", 400, 380), ("B4", 350, 460), ("B5", 450, 440),
    ("C1", 560, 330), ("C2", 600, 200), ("C3", 500, 160), ("C4", 420, 100),
]

/// The index in `trailSpots` of each clearing.
let trailIndex: [String: Int] = Dictionary(uniqueKeysWithValues: trailSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each footway, as offsets in `trailSpots`, by position in `trails`.
let trailEnds: [(Int, Int)] = trails.edges.map { (trailIndex[$0.u]!, trailIndex[$0.v]!) }

/// The Infomap page's state: the trials, and the playback over them.
@Reactive
final class InfomapModel {
    @ReactiveIgnored let trials = trailTrials(8)
    @ReactiveIgnored let best = trailModules(trials: 8)
    @ReactiveIgnored let louvain = trailLouvain()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-infomap")

    init() {
        playback.reset(count: trials.count)
    }
}

let infomapModel = InfomapModel()

/// The module of each clearing, by `trailSpots` offset.
func trailModuleOf(_ modules: [[String]]) -> [Int: Int] {
    var map = [Int: Int]()
    for (n, module) in modules.enumerated() { for name in module { map[trailIndex[name]!] = n } }
    return map
}

/// The sentence for one trial.
func describeTrial(_ n: Int, _ model: InfomapModel) -> String {
    let trial = model.trials[n]
    let bestSoFar = model.trials.prefix(n + 1).map(\.codeLength).min()!
    let better = n == 0 || trial.codeLength < model.trials.prefix(n).map(\.codeLength).min()! - 1e-9
    return "Trial \(n + 1): \(trial.modules.count) modules, \(signedTwoPlaces(trial.codeLength)) bits per step. " + (better ? "The shortest so far." : "No shorter than the best so far, \(signedTwoPlaces(bestSoFar)) bits.")
}

/// The trails coloured by the modules of one trial.
@View
struct InfomapLab {
    var body: some View {
        let model = infomapModel
        let playback = model.playback
        let k = playback.k
        let trial = k > 0 ? model.trials[k - 1] : nil
        let moduleOf = trailModuleOf(trial?.modules ?? [])
        let nodes = trailSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 14, classes: moduleOf[v].map { "pal\($0 % 8)" } ?? "")
        }
        let edges = trailEnds.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: trial != nil && moduleOf[ends.0] != moduleOf[ends.1] ? "faint" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Infomap's modules of the trails")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Thirteen clearings joined by footpaths, coloured by the modules a trial of Infomap finds", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "one module" }
                        span { i(.class("line faint")) {}; "a path between modules" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "Before we start" : "Trial \(k) of \(model.trials.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "A walker wanders the paths at random. Describe the walk with a code: one name per module, and one per clearing inside its module. Modules the walker stays in for a while make the description short. Infomap searches for the modules that make it shortest. Press Step to run its trials."
                            } else {
                                describeTrial(k - 1, model)
                                if k == model.trials.count {
                                    " Describing the walk with no modules at all costs \(signedTwoPlaces(model.best.oneModule)) bits per step, and with every clearing its own module \(signedTwoPlaces(model.best.singletons))."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Compared with modularity" }
                        p(.class("note")) {
                            "Louvain finds \(model.louvain.modules.count) communities on these trails, at modularity \(signedTwoPlaces(model.louvain.modularity)); their code length is \(signedTwoPlaces(model.louvain.codeLength)) bits. Infomap’s best is \(signedTwoPlaces(model.best.codeLength))."
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Trials so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for n in 0 ..< k {
                                div(.class(n == k - 1 ? "qrow top" : "qrow plain")) {
                                    span { "trial \(n + 1): \(model.trials[n].modules.count) modules" }
                                    span(.class("num")) { "\(signedTwoPlaces(model.trials[n].codeLength)) bits" }
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
                    marbles: model.trials.enumerated().map { n, trial in
                        Marble(kind: "m-pal\(trial.modules.count % 8)", radius: 5 + trial.codeLength * 2, letter: "\(trial.modules.count)", title: describeTrial(n, model))
                    },
                    legend: [(Marble(kind: "m-pal3", radius: 8), "one trial, with its module count; bigger for a longer code")])
                p(.class("note")) { "infomapCommunities(trials:using:) runs its trials at once and keeps the shortest code. The page runs one per step, each from its own seed." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct InfomapCodePanel {
    var body: some View {
        let model = infomapModel
        CodePanel(snippets: [.infomapImports, .infomapTrails, Snippet(lines: ["let trials = \(model.trials.count)"]), .infomapRun, .infomapLouvain],
                  results: [signedTwoPlaces(model.best.codeLength), signedTwoPlaces(model.best.oneModule), signedTwoPlaces(model.best.singletons), signedTwoPlaces(model.louvain.codeLength), signedTwoPlaces(model.louvain.modularity)])
    }
}

enum InfomapPage {
    static func mount() {
        mountView(InfomapLab(), in: "app")
        mountView(InfomapCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.louvain]), in: "names")
    }
}
