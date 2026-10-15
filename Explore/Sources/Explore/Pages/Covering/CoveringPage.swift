import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each corner of the town and where it sits, in SVG units of the 640 × 440 view box.
let cornerPlaces: [(name: String, x: Double, y: Double)] = [
    ("Church", 80, 70), ("Mill", 240, 60), ("Park", 400, 70), ("Dock", 560, 80),
    ("School", 100, 215), ("Square", 260, 205), ("Market", 420, 225), ("Pier", 570, 235),
    ("Farm", 70, 370), ("Bakery", 230, 360), ("Library", 400, 375), ("Station", 560, 370),
]

/// The index in `cornerPlaces` of each corner's name.
let cornerIndex: [String: Int] = Dictionary(uniqueKeysWithValues: cornerPlaces.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each street, as offsets in `cornerPlaces`, by position in `crossroads`.
let streetCorners: [(Int, Int)] = crossroads.edges.map { (cornerIndex[$0.u]!, cornerIndex[$0.v]!) }

/// The corners next to each corner.
let cornerNeighbours: [[Int]] = cornerPlaces.map { place in crossroads.neighbors(of: place.name).map { cornerIndex[$0]! } }

/// One choice of the greedy plan: the corner given a station and the corners it newly reaches.
struct StationPick {
    var corner: Int
    var reached: [Int]
}

/// The covering page's state: cameras or stations, the corners chosen, and the greedy plan's
/// steps with their playhead.
@Reactive
final class CoveringModel {
    /// 0 for cameras (a vertex cover), 1 for fire stations (a dominating set).
    var mode = 0
    var cameras: [Int] = [cornerIndex["Square"]!, cornerIndex["Market"]!]
    var stations: [Int] = [cornerIndex["Square"]!]
    @ReactiveIgnored let picks: [StationPick]
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-stations")

    init() {
        picks = CoveringModel.greedy()
        playback.reset(count: picks.count)
    }

    /// Chvátal's greedy plan, as approximateMinimumDominatingSet() describes it: repeatedly the
    /// corner that reaches the most corners not yet reached (itself and its neighbours), the
    /// first listed on ties.
    static func greedy() -> [StationPick] {
        var reached = Set<Int>()
        var picks: [StationPick] = []
        while reached.count < cornerPlaces.count {
            var best = -1, bestNew: [Int] = []
            for v in cornerPlaces.indices {
                let new = ([v] + cornerNeighbours[v]).filter { !reached.contains($0) }
                if new.count > bestNew.count { best = v; bestNew = new }
            }
            picks.append(StationPick(corner: best, reached: bestNew.sorted()))
            reached.formUnion(bestNew)
        }
        return picks
    }

    var chosen: [Int] { mode == 0 ? cameras : stations }

    func toggle(_ v: Int) {
        if mode == 0 {
            if let i = cameras.firstIndex(of: v) { cameras.remove(at: i) } else { cameras.append(v) }
        } else {
            if let i = stations.firstIndex(of: v) { stations.remove(at: i) } else { stations.append(v) }
        }
    }

    func choose(mode: Int) {
        self.mode = mode
        setProperty(id: "covering-mode", "value", to: "\(mode)")
    }

    /// Replaces the chosen corners by `names`.
    func use(_ names: [String]) {
        let picked = names.map { cornerIndex[$0]! }
        if mode == 0 { cameras = picked } else { stations = picked }
    }
}

let coveringModel = CoveringModel()

/// The chosen corners' names, in the order of `cornerPlaces`.
func chosenNames(_ chosen: [Int]) -> [String] {
    cornerPlaces.indices.filter { chosen.contains($0) }.map { cornerPlaces[$0].name }
}

/// The town with cameras or stations to place.
@View
struct CoveringLab {
    var body: some View {
        let model = coveringModel
        let chosen = Set(model.chosen)
        let names = chosenNames(model.chosen)
        let cameras = model.mode == 0
        let seen = streetCorners.map { chosen.contains($0.0) || chosen.contains($0.1) }
        let reached = cornerPlaces.indices.map { v in chosen.contains(v) || cornerNeighbours[v].contains { chosen.contains($0) } }
        let camera = cameraAnswers(chosen: names)
        let station = stationAnswers(chosen: names)
        let unseen = seen.filter { !$0 }.count, unreached = reached.filter { !$0 }.count
        let nodes = cornerPlaces.enumerated().map { v, place in
            CanvasNode(x: place.x, y: place.y, name: place.name, badge: chosen.contains(v) ? (cameras ? "C" : "F") : "", radius: 16,
                       classes: chosen.contains(v) ? "visited" : (!cameras && !reached[v]) ? "cut" : "")
        }
        let edges = streetCorners.enumerated().map { p, ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: cameras ? (seen[p] ? "tree" : "route") : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Cameras and fire stations")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twelve street corners and the streets between them; click a corner to put a \(cameras ? "camera" : "fire station") there or take it away",
                                width: 640, height: 440, nodes: nodes, edges: edges, onNode: { coveringModel.toggle($0) }, nodeAction: cameras ? "Toggle a camera at" : "Toggle a fire station at")
                    div(.class("legend")) {
                        if cameras {
                            span { i(.class("dot visited")) {}; "a camera" }
                            span { i(.class("line tree")) {}; "a street a camera sees" }
                            span { i(.class("line route")) {}; "a street no camera sees" }
                        } else {
                            span { i(.class("dot visited")) {}; "a fire station" }
                            span { i(.class("dot cut")) {}; "a corner with no station on it or next to it" }
                        }
                    }
                    p(.class("note")) { cameras ? "A camera on a corner sees every street that meets there." : "A station serves its own corner and every corner one street away." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { cameras ? "\(names.count) camera\(names.count == 1 ? "" : "s")" : "\(names.count) station\(names.count == 1 ? "" : "s")" }
                        p(.class("narration")) {
                            if cameras {
                                unseen == 0
                                    ? "Every street is watched, so this is a vertex cover. The fewest cameras that can do it is \(camera.fewest)" + (names.count == camera.fewest ? ", and you have that many." : ".")
                                    : "\(unseen) of \(crossroads.edgeCount) streets have no camera at either end. Every street needs a camera on at least one of its corners."
                            } else {
                                unreached == 0
                                    ? "Every corner has a station on it or next to it, so this is a dominating set. The fewest stations that can do it is \(station.fewest)" + (names.count == station.fewest ? ", and you have that many." : ".")
                                    : "\(unreached) corner\(unreached == 1 ? " has" : "s have") no station on or next to it."
                            }
                        }
                        label(.class("field"), .for("covering-mode")) {
                            "Place "
                            select(.id("covering-mode")) {
                                option(.value("0")) { "cameras" }.attributes(.selected, when: model.mode == 0)
                                option(.value("1")) { "fire stations" }.attributes(.selected, when: model.mode == 1)
                            }
                            .onInput { event in
                                if let value = event.targetValue, let n = Int(value) { coveringModel.choose(mode: n) }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Plans from Grafluent" }
                        div(.class("queue")) {
                            div(.class("qrow plain")) {
                                span { "Fewest, first in the list: " + (cameras ? camera.first : station.first).joined(separator: ", ") }
                                span(.class("num")) { "\((cameras ? camera.first : station.first).count)" }
                            }
                            div(.class("qrow plain")) {
                                span { "Quick estimate: " + (cameras ? camera.quick : station.quick).joined(separator: ", ") }
                                span(.class("num")) { "\((cameras ? camera.quick : station.quick).count)" }
                            }
                        }
                        div(.class("buttons")) {
                            button(.type(.button)) { "Use the fewest" }
                                .onClick { coveringModel.use(coveringModel.mode == 0 ? cameraAnswers(chosen: []).first : stationAnswers(chosen: []).first) }
                            button(.type(.button)) { "Clear" }
                                .onClick { coveringModel.use([]) }
                        }
                    }
                }
            }
        }
    }
}

/// The lab's code panel.
@View
struct CoveringCodePanel {
    var body: some View {
        let model = coveringModel
        let names = chosenNames(model.chosen)
        let list = { (xs: [String]) in "[" + xs.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        if model.mode == 0 {
            let a = cameraAnswers(chosen: names)
            CodePanel(snippets: [.coveringImports, .coveringTown, Snippet(lines: ["let chosen = " + list(names)]), .coveringCameras],
                      results: ["\(a.fewest)", list(a.first), list(a.quick), "\(a.allSeen)"])
        } else {
            let a = stationAnswers(chosen: names)
            CodePanel(snippets: [.coveringImports, .coveringTown, Snippet(lines: ["let chosen = " + list(names)]), .coveringStations],
                      results: ["\(a.fewest)", list(a.first), list(a.quick), "\(a.allReached)"])
        }
    }
}

/// The sentence for one pick of the greedy plan.
func describePick(_ pick: StationPick, number: Int, left: Int) -> String {
    "Station \(number) goes at \(cornerPlaces[pick.corner].name). It serves \(pick.reached.count) new corner\(pick.reached.count == 1 ? "" : "s"), more than any other spot. \(left == 0 ? "No corner is left." : left == 1 ? "1 corner is left." : "\(left) corners are left.")"
}

/// The greedy plan, one station at a time.
@View
struct GreedyStationLab {
    var body: some View {
        let model = coveringModel
        let playback = model.playback
        let k = playback.k
        let picks = model.picks
        let shown = Array(picks.prefix(k))
        let reached = Set(shown.flatMap(\.reached))
        let last = shown.last
        let finished = k == picks.count
        let quick = stationAnswers(chosen: []).quick
        let fewest = stationAnswers(chosen: []).fewest
        let mine = chosenNames(picks.map(\.corner))
        let nodes = cornerPlaces.enumerated().map { v, place in
            CanvasNode(x: place.x, y: place.y, name: place.name, badge: shown.contains { $0.corner == v } ? "F" : "", radius: 16,
                       classes: (shown.contains { $0.corner == v } ? "visited" : reached.contains(v) ? "done" : "") + (v == last?.corner ? " current" : ""))
        }
        let edges = streetCorners.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: last.map { ($0.corner == ends.0 && $0.reached.contains(ends.1)) || ($0.corner == ends.1 && $0.reached.contains(ends.0)) } == true ? "active" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The greedy plan for fire stations")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The town with the greedy plan’s stations so far and the corners they serve", width: 640, height: 440, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "a station" }
                        span { i(.class("dot done")) {}; "served" }
                        span { i(.class("line active")) {}; "the streets the newest station serves along" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(picks.count) stations" : "Station \(k) of \(picks.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Build stations one at a time. Each goes where it serves the most corners that no station serves yet. Press Step to place the first."
                            } else {
                                describePick(last!, number: k, left: cornerPlaces.count - reached.count)
                                if finished {
                                    (mine == quick ? " This is the plan approximateMinimumDominatingSet() gives." : " This is not the plan approximateMinimumDominatingSet() gives.")
                                        + (picks.count == fewest ? " Here it is also the fewest possible." : " The fewest possible is \(fewest), from minimumDominatingSet().")
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
                    marbles: picks.enumerated().map { n, pick in
                        Marble(kind: "m-blue", radius: 4 + Double(pick.reached.count) * 1.5, letter: "\(pick.reached.count)",
                               title: describePick(pick, number: n + 1, left: cornerPlaces.count - Set(picks.prefix(n + 1).flatMap(\.reached)).count))
                    },
                    legend: [(Marble(kind: "m-blue", radius: 6), "a station, with the corners it newly serves")])
                p(.class("note")) { "The picks are the page’s, following the rule approximateMinimumDominatingSet() documents, which returns only the set; the last step is checked against it." }
            }
        }
    }
}

/// The greedy plan's code panel.
@View
struct GreedyStationCodePanel {
    var body: some View {
        let a = stationAnswers(chosen: chosenNames(coveringModel.picks.map(\.corner)))
        let list = { (xs: [String]) in "[" + xs.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
        CodePanel(snippets: [.coveringImports, .coveringTown, Snippet(lines: ["let chosen = " + list(chosenNames(coveringModel.picks.map(\.corner)))]), .coveringStations],
                  results: ["\(a.fewest)", list(a.first), list(a.quick), "\(a.allReached)"])
    }
}

enum CoveringPage {
    static func mount() {
        mountView(CoveringLab(), in: "app")
        mountView(CoveringCodePanel(), in: "code")
        mountView(GreedyStationLab(), in: "greedy")
        mountView(GreedyStationCodePanel(), in: "code-greedy")
        mountView(NamesStrip(names: [Names.chvatal]), in: "names")
    }
}
