import ElementaryUI
import GraphProtocols
import Multigraphs
import Reactivity
import Tours
import Walks

/// One city on the Euler page: where each place sits in the 640 × 440 view box, and its bridges
/// (or roads) in the order they are built.
struct EulerScenario {
    var title: String
    var road: String
    var spots: [(name: String, x: Double, y: Double)]
    var bridges: [UndirectedEdge<String>]

    func index(_ name: String) -> Int { spots.firstIndex { $0.name == name }! }
}

let konigsbergSpots: [(name: String, x: Double, y: Double)] = [
    ("North bank", 330, 60), ("Kneiphof", 180, 225), ("South bank", 330, 385), ("Lomse", 500, 225),
]
let konigsbergBridges = [
    UndirectedEdge("North bank", "Kneiphof"), UndirectedEdge("North bank", "Kneiphof"),
    UndirectedEdge("South bank", "Kneiphof"), UndirectedEdge("South bank", "Kneiphof"),
    UndirectedEdge("Kneiphof", "Lomse"), UndirectedEdge("North bank", "Lomse"), UndirectedEdge("South bank", "Lomse"),
]

let eulerScenarios = [
    EulerScenario(title: "Königsberg", road: "bridge", spots: konigsbergSpots, bridges: konigsbergBridges),
    EulerScenario(title: "An eighth bridge", road: "bridge", spots: konigsbergSpots,
                  bridges: konigsbergBridges + [UndirectedEdge("North bank", "South bank")]),
    EulerScenario(
        title: "A town with a tour", road: "road",
        spots: [("Pier", 160, 70), ("Inn", 320, 150), ("Mill", 110, 260), ("Gate", 480, 70), ("Well", 530, 260), ("Hall", 320, 385)],
        bridges: [
            UndirectedEdge("Pier", "Inn"), UndirectedEdge("Inn", "Mill"), UndirectedEdge("Mill", "Pier"),
            UndirectedEdge("Inn", "Gate"), UndirectedEdge("Gate", "Well"), UndirectedEdge("Well", "Inn"),
            UndirectedEdge("Mill", "Hall"), UndirectedEdge("Hall", "Well"), UndirectedEdge("Well", "Mill"),
        ]),
]

/// One marble on the Euler timeline. First each place's count of bridges (`degree(of:)`); then,
/// when a tour exists, Hierholzer's walk in the stack form `eulerianCircuit()` documents: from
/// the place on top, take its first unused bridge in `incidentEdges` order, or, with none left,
/// back up, the bridge just backed over taking the last free place in the tour.
enum EulerStep {
    case count(place: Int, degree: Int)
    case walk(road: Int, from: Int, to: Int, detour: Bool)
    /// Stuck at `place`: it leaves the walk, and the bridge that reached it, if any, becomes
    /// number `slot` of the tour.
    case stuck(place: Int, road: Int?, slot: Int)
}

/// What the city shows after some steps.
struct EulerSnapshot {
    var degree: [Int?]
    /// The places of the walk in progress, the start first, and the bridges between them.
    var walk: [Int] = []
    var walkRoads: [Int] = []
    /// Each bridge's number in the finished tour, once it has one.
    var slot: [Int: Int] = [:]
}

@Reactive
final class EulerModel {
    var scenario = 0
    var city = eulerCity(eulerScenarios[0].bridges)
    var steps: [EulerStep] = []
    var odd: [String] = []
    var circuit: Circuit<String, Int>?
    var trail: Trail<String, Int>?
    /// The tour the replay stitched together, by bridge positions, and whether it is Grafluent's.
    var stitched: [Int] = []
    var agrees = true
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 800, scrubID: "scrub-euler")

    init() {
        choose(0)
    }

    var current: EulerScenario { eulerScenarios[scenario] }

    func choose(_ n: Int) {
        scenario = n
        let s = eulerScenarios[n]
        city = eulerCity(s.bridges)
        (odd, circuit, trail) = eulerAnswers(city)
        steps = s.spots.map { .count(place: s.index($0.name), degree: city.degree(of: $0.name)) }
        stitched = []
        if let trail {
            let replay = EulerModel.hierholzer(city, from: trail.source, s)
            steps += replay.steps
            stitched = replay.tour
            agrees = stitched == (circuit?.edges ?? trail.edges)
        }
        playback.reset(count: steps.count)
    }

    /// The stack form of Hierholzer's walk on `city` from `start`, as steps, and the tour it
    /// ends with.
    static func hierholzer(_ city: Multigraph<String>, from start: String, _ s: EulerScenario) -> (steps: [EulerStep], tour: [Int]) {
        var steps: [EulerStep] = []
        var used = Set<Int>()
        var stack = [start]
        var roads: [Int] = []
        var tour = [Int](repeating: -1, count: city.edgeCount)
        var free = city.edgeCount
        var backedUp = false
        while let v = stack.last {
            if let e = city.incidentEdges(of: v).first(where: { !used.contains($0) }) {
                used.insert(e)
                let w = city.edges[e].oppositeVertex(to: v)
                steps.append(.walk(road: e, from: s.index(v), to: s.index(w), detour: backedUp))
                stack.append(w)
                roads.append(e)
                backedUp = false
            } else {
                stack.removeLast()
                if let e = roads.popLast() {
                    tour[free - 1] = e
                    steps.append(.stuck(place: s.index(v), road: e, slot: free))
                    free -= 1
                } else {
                    steps.append(.stuck(place: s.index(v), road: nil, slot: 0))
                }
                backedUp = true
            }
        }
        return (steps, tour)
    }

    func snapshot(_ k: Int) -> EulerSnapshot {
        let s = current
        var state = EulerSnapshot(degree: [Int?](repeating: nil, count: s.spots.count))
        for step in steps.prefix(k) {
            switch step {
            case .count(let place, let degree):
                state.degree[place] = degree
            case .walk(let road, let from, let to, _):
                if state.walk.isEmpty { state.walk = [from] }
                state.walk.append(to)
                state.walkRoads.append(road)
            case .stuck(_, let road, let slot):
                state.walk.removeLast()
                if let road {
                    state.walkRoads.removeLast()
                    state.slot[road] = slot
                }
            }
        }
        return state
    }
}

let euler = EulerModel()

/// `North bank–Kneiphof`.
func bridgeName(_ road: Int, in city: Multigraph<String>) -> String { "\(city.edges[road])" }

func describeEuler(_ step: EulerStep, _ model: EulerModel) -> String {
    let s = model.current
    func name(_ v: Int) -> String { s.spots[v].name }
    switch step {
    case .count(let place, let degree):
        return degree % 2 == 1
            ? "\(name(place)) has \(degree) \(s.road)s, an odd number. Each visit uses one \(s.road) in and one out, so one is left over. Only the start or the end of a walk can be odd."
            : "\(name(place)) has \(degree) \(s.road)s, an even number. Every \(s.road) in can be paired with one out."
    case .walk(let road, let from, let to, let detour):
        return detour
            ? "\(name(from)) still has an unused \(s.road). Set off on a detour along \(bridgeName(road, in: model.city)) to \(name(to)). The loop it makes is stitched into the tour here."
            : "From \(name(from)), take the first unused \(s.road), \(bridgeName(road, in: model.city)), to \(name(to))."
    case .stuck(let place, let road, let slot):
        guard let road else { return "Back at \(name(place)) with nothing left to walk. The tour is complete." }
        return "Stuck at \(name(place)), because every \(s.road) here is used. Back up over \(bridgeName(road, in: model.city)). It becomes \(s.road) \(slot) of \(model.city.edgeCount) in the tour."
    }
}

func eulerMarble(_ step: EulerStep, _ model: EulerModel) -> Marble {
    let title = describeEuler(step, model)
    switch step {
    case .count(_, let degree): return Marble(kind: degree % 2 == 1 ? "m-red" : "m-green", radius: 10, letter: "\(degree)", title: title)
    case .walk(_, _, _, let detour): return detour ? Marble(kind: "m-violet", radius: 8, title: title) : Marble(kind: "m-ring", radius: 6, title: title)
    case .stuck(_, let road, let slot): return road == nil ? Marble(kind: "m-hollow", radius: 8, title: title) : Marble(kind: "m-blue", radius: 10, letter: "\(slot)", title: title)
    }
}

/// `Pier → Inn → Mill`.
func tourText(_ vertices: [String]) -> String { vertices.joined(separator: " → ") }

@View
struct EulerLab {
    var body: some View {
        let model = euler
        let s = model.current
        let city = model.city
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let state = model.snapshot(k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let walking = Set(state.walkRoads)
        let activeRoad: Int = { if case .walk(let road, _, _, _)? = last { return road }; if case .stuck(_, let road?, _)? = last { return road }; return -1 }()
        let current: Int = {
            switch last {
            case .count(let v, _)?, .stuck(let v, _, _)?: return v
            case .walk(_, _, let to, _)?: return to
            case nil: return -1
            }
        }()
        let nodes = s.spots.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, badge: state.degree[v].map { "\($0)" } ?? "", radius: 22,
                classes: (state.degree[v].map { $0 % 2 == 1 ? "odd" : "even" } ?? "") + (state.walk.last == v ? " frontier" : "") + (v == current ? " current" : ""))
        }
        // Parallel bridges bend apart, the same way whichever end they are listed from.
        let edges = city.edges.indices.map { road in
            let edge = city.edges[road]
            let (a, b) = s.index(edge.u) < s.index(edge.v) ? (s.index(edge.u), s.index(edge.v)) : (s.index(edge.v), s.index(edge.u))
            let twins = city.edges.indices.filter { Set([city.edges[$0].u, city.edges[$0].v]) == Set([edge.u, edge.v]) }
            let n = twins.firstIndex(of: road)!
            let bend = twins.count == 1 ? 0 : (Double(n) - Double(twins.count - 1) / 2) * 34
            return CanvasEdge(
                from: a, to: b, label: state.slot[road].map { "\($0)" } ?? "",
                classes: (state.slot[road] != nil ? "tree" : walking.contains(road) ? "route" : "") + (road == activeRoad ? " active" : ""), bend: bend)
        }
        let oddCount = state.degree.compactMap { $0 }.filter { $0 % 2 == 1 }.count
        let countingDone: Bool = {
            if state.degree.allSatisfy({ $0 != nil }), case .count? = last { return true }
            return false
        }()

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A city of bridges")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "\(s.title): places joined by \(city.edgeCount) \(s.road)s", width: 640, height: 440, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot odd")) {}; "odd count" }
                        span { i(.class("dot even")) {}; "even count" }
                        span { i(.class("line route")) {}; "the walk in progress" }
                        span { i(.class("line tree")) {}; "in the tour, with its number" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Can you walk across every \(s.road) exactly once? First count the \(s.road)s at each place. Press Step to begin."
                            } else if finished && model.trail == nil {
                                "\(oddCount) places have an odd count. A walk can start at one odd place and end at another, but that covers only two. Each of the rest would strand a \(s.road). So no walk crosses every \(s.road) once, and eulerianTrail() returns nil."
                            } else if finished {
                                if let circuit = model.circuit {
                                    "Every \(s.road) is in the tour, and it ends where it began. "
                                    em { tourText(circuit.vertices + [circuit.vertices[0]]) }
                                    "."
                                } else if let trail = model.trail {
                                    "With two odd places there is no closed tour. But there is a walk from one to the other. "
                                    em { tourText(trail.vertices) }
                                    "."
                                }
                                model.agrees ? " The same as Grafluent’s answer." : " This differs from Grafluent’s answer."
                            } else if countingDone {
                                describeEuler(last!, model)
                                oddCount == 0 ? " No place is odd, so a closed tour exists. Now find it." : oddCount == 2 ? " Two places are odd, so a walk from one to the other exists. Now find it." : ""
                            } else {
                                describeEuler(last!, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { s.road == "bridge" ? "Bridges at each place" : "Roads at each place" }
                        div(.class("chips")) {
                            for (v, spot) in s.spots.enumerated() {
                                span(.class(state.degree[v] == nil ? "chip hollow" : state.degree[v]! % 2 == 1 ? "chip bad" : "chip pal2")) {
                                    spot.name + " "
                                    span(.class("num")) { state.degree[v].map { "\($0)" } ?? "?" }
                                }
                            }
                        }
                    }
                    if model.trail != nil {
                        div(.class("panel")) {
                            span(.class("label")) { "The tour, filled in from its end" }
                            ol(.class("steps")) {
                                for n in 1 ... city.edgeCount {
                                    let road = state.slot.first { $0.value == n }?.key
                                    li(.class(road == nil ? "empty" : "")) { road.map { bridgeName($0, in: city) } ?? "…" }
                                }
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "City")) {
                        button(.type(.button), .class(model.scenario == 0 ? "on" : "")) { eulerScenarios[0].title }
                            .onClick { euler.choose(0) }
                        button(.type(.button), .class(model.scenario == 1 ? "on" : "")) { eulerScenarios[1].title }
                            .onClick { euler.choose(1) }
                        button(.type(.button), .class(model.scenario == 2 ? "on" : "")) { eulerScenarios[2].title }
                            .onClick { euler.choose(2) }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { eulerMarble($0, model) },
                    legend: [
                        (Marble(kind: "m-green", radius: 6), "even count"),
                        (Marble(kind: "m-red", radius: 6), "odd count"),
                        (Marble(kind: "m-ring", radius: 5), "walk on"),
                        (Marble(kind: "m-violet", radius: 5), "start a detour"),
                        (Marble(kind: "m-blue", radius: 6), "stuck, so back up and a \(s.road) joins the tour"),
                    ])
                p(.class("note")) {
                    "Once counted, each circle shows how many \(s.road)s meet there. The walk follows the rule that "
                    code { "eulerianCircuit()" }
                    " documents. It takes the first unused \(s.road) in "
                    code { "incidentEdges" }
                    " order, and backs up when stuck."
                }
            }
        }
    }
}

/// `9 roads: Pier → Inn → …`, or `nil`.
func eulerWalkText(_ vertices: [String]?, closed: Bool, road: String) -> String {
    guard let vertices else { return "nil" }
    return "\(vertices.count - (closed ? 0 : 1)) \(road)s: " + tourText(closed ? vertices + [vertices[0]] : vertices)
}

@View
struct EulerCodePanel {
    var body: some View {
        let model = euler
        let s = model.current
        let bridgeLines = ["let bridges = ["] + s.bridges.map { "    UndirectedEdge(\"\($0.u)\", \"\($0.v)\")," } + ["]"]
        let odd = "[" + model.odd.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        let circuit = eulerWalkText(model.circuit?.vertices, closed: true, road: s.road)
        let trail = eulerWalkText(model.trail?.vertices, closed: false, road: s.road)
        CodePanel(
            snippets: [
                .eulerImports,
                Snippet(lines: bridgeLines),
                .eulerCity, .eulerTour,
            ],
            results: [
                odd, circuit, trail,
            ])
    }
}

enum EulerPage {
    static func mount() {
        mountView(EulerLab(), in: "app")
        mountView(EulerCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.euler, Names.hierholzer, Names.konigsberg, Names.fleury]), in: "names")
    }
}
