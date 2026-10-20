import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each village and where it sits, in SVG units of the 640 × 470 view box.
let countySpots: [(name: String, x: Double, y: Double)] = [
    ("Ash", 50, 120), ("Birch", 170, 150), ("Cedar", 250, 60), ("Dale", 400, 100), ("Elm", 540, 170),
    ("Glen", 300, 230), ("Holt", 440, 300), ("Ivy", 540, 410), ("Fir", 620, 300),
]

/// The index in `countySpots` of each village.
let countyIndex: [String: Int] = Dictionary(uniqueKeysWithValues: countySpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each road, as offsets in `countySpots`, by position in `county`.
let countyRoadEnds: [(Int, Int)] = county.edges.map { (countyIndex[$0.u]!, countyIndex[$0.v]!) }

/// The distances page's state: hops or drivingMinutes, and the playback over the villages.
@Reactive
final class DistancesModel {
    var byMinutes = false
    @ReactiveIgnored let hops = countyHops()
    @ReactiveIgnored let times = countyMinutes()
    @ReactiveIgnored let longest = countyDiameterPath()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1100, scrubID: "scrub-distances")
    /// The countyFarthest village from each, in `vertices` order, by hops and by drivingMinutes.
    @ReactiveIgnored let farthestByHops = county.vertices.map { countyFarthest(from: $0, byMinutes: false) }
    @ReactiveIgnored let farthestByMinutes = county.vertices.map { countyFarthest(from: $0, byMinutes: true) }

    init() {
        playback.reset(count: county.vertexCount)
    }

    func choose(byMinutes: Bool) {
        self.byMinutes = byMinutes
        setProperty(id: "distances-unit", "value", to: byMinutes ? "1" : "0")
    }
}

let distancesModel = DistancesModel()

/// The positions of the roads along a route, by consecutive stops.
func countyPathEdges(_ stops: [String]) -> Set<Int> {
    var edges = Set<Int>()
    for (a, b) in zip(stops, stops.dropFirst()) {
        for (p, ends) in countyRoadEnds.enumerated() where Set([ends.0, ends.1]) == Set([countyIndex[a]!, countyIndex[b]!]) { edges.insert(p) }
    }
    return edges
}

/// `["Birch", "Glen"]`.
func countyQuoted(_ names: [String]) -> String { "[" + names.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }

/// The sentence for one village's eccentricity.
func describeEccentricity(_ v: Int, _ model: DistancesModel) -> String {
    let unit = model.byMinutes ? "minutes" : "hops"
    let far = model.byMinutes ? model.farthestByMinutes[v] : model.farthestByHops[v]
    let name = countySpots[v].name
    return "\(name): the farthest village is \(far.village), \(far.distance) \(unit) away by \(nameList(Array(far.stops.dropFirst()))). So \(name)’s eccentricity is \(far.distance)."
}

/// The county with each village's countyFarthest village, then the centre and the periphery.
@View
struct DistancesLab {
    var body: some View {
        let model = distancesModel
        let playback = model.playback
        let k = playback.k
        let n = county.vertexCount
        let measures = model.byMinutes ? model.times : model.hops
        let unit = model.byMinutes ? "minutes" : "hops"
        let finished = k == n
        let current = k > 0 ? k - 1 : nil
        let far = current.map { model.byMinutes ? model.farthestByMinutes[$0] : model.farthestByHops[$0] }
        let onPath = Set(far?.stops.map { countyIndex[$0]! } ?? [])
        let pathEdges = countyPathEdges(far?.stops ?? [])
        let center = Set(measures.center.map { countyIndex[$0]! })
        let periphery = Set(measures.periphery.map { countyIndex[$0]! })
        let nodes = countySpots.enumerated().map { v, spot in
            let badge = v < k ? (measures.eccentricity[v].map { "\($0)" } ?? "∞") : ""
            let classes: String = finished ? (center.contains(v) ? "current" : (periphery.contains(v) ? "frontier" : "dim"))
                : (current == v ? "current" : (far?.village == spot.name ? "frontier" : (onPath.contains(v) ? "visited" : (v < k ? "done" : ""))))
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: badge, radius: 16, classes: classes)
        }
        let edges = countyRoadEnds.enumerated().map { p, ends in
            CanvasEdge(from: ends.0, to: ends.1, label: model.byMinutes ? "\(drivingMinutes[county.edges[p]]!)" : "", classes: pathEdges.contains(p) ? "tree" : (finished ? "faint" : ""))
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Eccentricity, centre and diameter of the county")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Nine villages joined by twelve roads, each village marked with how far its farthest village is", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        if finished {
                            span { i(.class("dot current")) {}; "the centre" }
                            span { i(.class("dot frontier")) {}; "the periphery" }
                        } else {
                            span { i(.class("dot current")) {}; "this village" }
                            span { i(.class("dot frontier")) {}; "its farthest village" }
                            span { i(.class("line tree")) {}; "the shortest way there" }
                        }
                        if model.byMinutes { span { "numbers on roads: minutes" } }
                    }
                    p(.class("note")) { "Each circle shows the village’s eccentricity once it has been measured." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Every village measured" : (k == 0 ? "Before we start" : "Village \(k) of \(n)") }
                        p(.class("narration")) {
                            if k == 0 {
                                "A village’s eccentricity is how far its farthest village is. Measure every village, and the smallest eccentricity is the radius, the largest the diameter. Press Step to measure them one by one."
                            } else {
                                describeEccentricity(current!, model)
                                if finished {
                                    " The radius is \(measures.radius.map { "\($0)" } ?? "∞") \(unit), at "
                                    em { nameList(measures.center) }
                                    ": the centre. The diameter is \(measures.diameter.map { "\($0)" } ?? "∞") \(unit), at "
                                    em { nameList(measures.periphery) }
                                    ": the periphery."
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("distances-unit")) {
                                "Measure in "
                                select(.id("distances-unit")) {
                                    option(.value("0")) { "hops" }.attributes(.selected, when: !model.byMinutes)
                                    option(.value("1")) { "minutes" }.attributes(.selected, when: model.byMinutes)
                                }
                                .onInput { event in
                                    if let value = event.targetValue { distancesModel.choose(byMinutes: value == "1") }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Eccentricities so far" }
                        div(.class("queue")) {
                            if k == 0 { p(.class("empty")) { "None yet" } }
                            for v in 0 ..< k {
                                div(.class(v == k - 1 ? "qrow top" : "qrow plain")) {
                                    span { countySpots[v].name }
                                    span(.class("num")) { "\(measures.eccentricity[v].map { "\($0)" } ?? "∞") \(unit)" }
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
                    marbles: (0 ..< n).map { v in
                        let e = measures.eccentricity[v] ?? 0
                        return Marble(kind: center.contains(v) ? "m-current" : (periphery.contains(v) ? "m-frontier" : "m-done"), radius: 5 + Double(e) / (model.byMinutes ? 6 : 1), letter: "\(e)",
                                      title: describeEccentricity(v, model))
                    },
                    legend: [(Marble(kind: "m-current", radius: 7), "a village of the centre"), (Marble(kind: "m-frontier", radius: 7), "a village of the periphery"), (Marble(kind: "m-done", radius: 7), "another village, bigger for a larger eccentricity")])
                p(.class("note")) { "eccentricities() measures every village at once with a shortest-path search from each. The page shows one search per step." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct DistancesCodePanel {
    var body: some View {
        let model = distancesModel
        let measures = model.byMinutes ? model.times : model.hops
        let list = countyQuoted
        let results = [measures.radius.map { "\($0)" } ?? "nil", measures.diameter.map { "\($0)" } ?? "nil", list(measures.center), list(measures.periphery)]
        if model.byMinutes {
            CodePanel(snippets: [.distancesImports, .distancesVillages, .distancesMinutes, .distancesPath],
                      results: results + [list(model.longest)])
        } else {
            CodePanel(snippets: [.distancesImports, .distancesVillages, .distancesHops], results: results)
        }
    }
}

enum DistancesPage {
    static func mount() {
        mountView(DistancesLab(), in: "app")
        mountView(DistancesCodePanel(), in: "code")
    }
}
