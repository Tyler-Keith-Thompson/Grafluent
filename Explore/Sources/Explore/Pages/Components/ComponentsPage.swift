import CompressedSparseRowModule
import ElementaryUI
import Reactivity
import Traversal

let islandSpots: [(name: String, x: Double, y: Double)] = [
    ("Gull", 70, 90), ("Pine", 210, 50), ("Fern", 150, 210), ("Harbor", 310, 170), ("Mill", 430, 70),
    ("Reef", 570, 120), ("Rock", 470, 290), ("Cove", 600, 300),
]
let islandNames = islandSpots.map(\.name)
let allBridges: [(String, String)] = [
    ("Gull", "Pine"), ("Pine", "Fern"), ("Gull", "Fern"), ("Fern", "Harbor"), ("Harbor", "Mill"), ("Mill", "Reef"),
    ("Rock", "Cove"), ("Reef", "Rock"), ("Harbor", "Rock"),
]
let startingBroken: Set<Int> = [7, 8]

let cornerSpots: [(name: String, x: Double, y: Double)] = [
    ("Park", 70, 80), ("School", 210, 45), ("Market", 160, 185), ("Mill", 310, 195), ("Dock", 440, 105),
    ("Bakery", 575, 205), ("Hill", 370, 340), ("Square", 535, 365), ("Church", 470, 270),
]
let cornerNames = cornerSpots.map(\.name)
let startingOneWay: [(String, String)] = [
    ("Park", "School"), ("School", "Market"), ("Market", "Park"), ("Market", "Mill"), ("Mill", "Dock"), ("Dock", "Mill"),
    ("Dock", "Bakery"), ("Hill", "Square"), ("Square", "Church"), ("Church", "Hill"), ("Church", "Mill"),
]

/// One step of the islands' timeline: an island reached by the search numbered `search`, the
/// first of each search being where it started.
struct IslandStep {
    var island: String
    var search: Int
    var starts: Bool
}

@Reactive
final class ComponentsModel {
    var broken = startingBroken
    var oneWay = startingOneWay
    var islands: (groups: [[String]], steps: [IslandStep]) = ([], [])
    var streets: (groups: [[String]], links: CompressedSparseRow, events: [DepthFirstSearchEvent<String>]) = ([], CompressedSparseRow(), [])
    @ReactiveIgnored let islandPlayback = Playback(millisecondsPerStep: 500, scrubID: "scrub-islands")
    @ReactiveIgnored let streetPlayback = Playback(millisecondsPerStep: 450, scrubID: "scrub-streets")

    init() {
        rerunIslands()
        rerunStreets()
    }

    func rerunIslands() {
        let found = islandGroups(islands: islandNames, bridges: standingBridges(broken))
        var steps: [IslandStep] = []
        for (n, search) in found.searches.enumerated() {
            for case .discover(let island) in search { steps.append(IslandStep(island: island, search: n, starts: steps.last?.search != n)) }
        }
        islands = (found.groups, steps)
        islandPlayback.reset(count: steps.count)
        islandPlayback.show(steps.count)
    }

    func rerunStreets() {
        streets = neighbourhoods(corners: cornerNames, oneWay: oneWay)
        streetPlayback.reset(count: streets.events.count)
        streetPlayback.show(streets.events.count)
    }

    func toggleBridge(_ i: Int) {
        if broken.contains(i) { broken.remove(i) } else { broken.insert(i) }
        rerunIslands()
    }

    /// Turns street `i` around; if the reverse is already a street, removes this one.
    func flip(_ i: Int) {
        let (a, b) = oneWay[i]
        if oneWay.contains(where: { $0 == (b, a) }) { oneWay.remove(at: i) } else { oneWay[i] = (b, a) }
        rerunStreets()
    }
}

/// The street corners after `k` events of the depth-first search: entered, finished, and the
/// neighbourhoods completed so far (Tarjan's algorithm completes one when its first-entered
/// corner finishes).
struct StreetSnapshot {
    var entered = Set<String>()
    var finished = Set<String>()
    var complete = Set<Int>()
    var last: DepthFirstSearchEvent<String>?

    init(_ events: [DepthFirstSearchEvent<String>], _ groups: [[String]], _ k: Int) {
        let group = colours(of: groups)
        var root: [Int: String] = [:]
        for event in events {
            if case .discover(let v) = event, root[group[v]!] == nil { root[group[v]!] = v }
        }
        for event in events.prefix(k) {
            switch event {
            case .discover(let v): entered.insert(v)
            case .finish(let v):
                finished.insert(v)
                if root[group[v]!] == v { complete.insert(group[v]!) }
            default: break
            }
        }
        last = k > 0 ? events[k - 1] : nil
    }

    /// Whether `event` finishes the first-entered corner of its neighbourhood.
    static func completes(_ event: DepthFirstSearchEvent<String>, _ events: [DepthFirstSearchEvent<String>], _ group: [String: Int]) -> Bool {
        guard case .finish(let v) = event else { return false }
        for e in events { if case .discover(let w) = e, group[w] == group[v] { return w == v } }
        return false
    }
}

let componentsModel = ComponentsModel()

/// Comma-separated names in braces.
func groupText(_ group: [String]) -> String { "{" + group.joined(separator: ", ") + "}" }

/// Each name's group, by offset.
func colours(of groups: [[String]]) -> [String: Int] {
    var colour: [String: Int] = [:]
    for (c, group) in groups.enumerated() { for name in group { colour[name] = c } }
    return colour
}

/// The bridges still standing.
func standingBridges(_ broken: Set<Int>) -> [(String, String)] {
    allBridges.indices.filter { !broken.contains($0) }.map { allBridges[$0] }
}

@View
struct IslandsLab {
    var body: some View {
        let model = componentsModel
        let groups = model.islands.groups
        let steps = model.islands.steps
        let playback = model.islandPlayback
        let k = playback.k
        let reached = Dictionary(uniqueKeysWithValues: steps.prefix(k).map { ($0.island, $0.search) })
        let last = k > 0 ? steps[k - 1] : nil
        let nodes = islandSpots.map { spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)), radius: 17,
                       classes: (reached[spot.name].map { "pal\($0 % 8)" } ?? "") + (last?.island == spot.name ? " current" : ""))
        }
        let edges = allBridges.enumerated().map { i, bridge in
            CanvasEdge(from: islandNames.firstIndex(of: bridge.0)!, to: islandNames.firstIndex(of: bridge.1)!,
                       classes: model.broken.contains(i) ? "faint" : reached[bridge.0].map { "pal\($0 % 8)" } ?? "")
        }
        div {
        section(.class("lab"), .custom(name: "aria-label", value: "Islands and bridges")) {
            div(.class("panel stage")) {
                GraphCanvas(label: "Eight islands joined by two-way bridges", width: 660, height: 350, nodes: nodes, edges: edges,
                            onEdge: { componentsModel.toggleBridge($0) })
                p(.class("note")) { "Click a bridge to close it, or a dashed one to open it. Islands of the same colour are in the same component." }
            }
            div(.class("side")) {
                div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                    span(.class("label")) { k == steps.count ? "\(groups.count) connected component\(groups.count == 1 ? "" : "s")" : "Step \(k) of \(steps.count)" }
                    p(.class("narration")) {
                        if let last {
                            if k == steps.count {
                                groups.count == 1
                                    ? "You can walk from any island to any other."
                                    : "You can walk between any two islands of the same colour, and never between colours."
                            } else if last.starts {
                                "\(last.island) hasn’t been reached yet. Start a new breadth-first search there, for component \(last.search + 1)."
                            } else {
                                "The search from component \(last.search + 1)’s start crosses a bridge to \(last.island)."
                            }
                        } else {
                            "Take the first island and walk everywhere its bridges lead. Everything you reach is one component. Then start again from an island not yet reached."
                        }
                    }
                    div(.class("chips")) {
                        for (c, group) in groups.enumerated() where k == steps.count { span(.class("chip pal\(c % 8)")) { groupText(group) } }
                    }
                }
            }
        }
        section(.class("panel controls"), .custom(name: "aria-label", value: "Islands playback")) {
            div(.class("buttons")) { PlaybackButtons(playback: playback) }
            Timeline(
                playback: playback,
                marbles: steps.map { step in
                    step.starts
                        ? Marble(kind: "m-pal\(step.search % 8)", radius: 11, letter: String(step.island.prefix(1)), title: "Start search \(step.search + 1) at \(step.island)")
                        : Marble(kind: "m-pal\(step.search % 8)", radius: 6, title: "Search \(step.search + 1) reaches \(step.island)")
                },
                legend: [(Marble(kind: "m-pal0", radius: 6), "a new search starts"), (Marble(kind: "m-pal0", radius: 4), "it reaches another island")])
        }
        }
    }
}

@View
struct StreetsLab {
    var body: some View {
        let model = componentsModel
        let oneWay = model.oneWay
        let found = model.streets
        let colour = colours(of: found.groups)
        let playback = model.streetPlayback
        let k = playback.k
        let snapshot = StreetSnapshot(found.events, found.groups, k)
        let current: String = {
            switch snapshot.last {
            case .discover(let v)?, .finish(let v)?: return v
            default: return ""
            }
        }()
        let nodes = cornerSpots.map { spot in
            let c = colour[spot.name]!
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)), radius: 17,
                              classes: (snapshot.complete.contains(c) ? "pal\(c % 8)" : snapshot.finished.contains(spot.name) ? "done" : snapshot.entered.contains(spot.name) ? "frontier" : "")
                                  + (spot.name == current ? " current" : ""))
        }
        let edges = oneWay.map { a, b in
            CanvasEdge(from: cornerNames.firstIndex(of: a)!, to: cornerNames.firstIndex(of: b)!, directed: true,
                       classes: colour[a] == colour[b] && snapshot.complete.contains(colour[a]!) ? "pal\(colour[a]! % 8)" : "faint", bend: oneWay.contains { $0 == (b, a) } ? 14 : 0)
        }
        // The condensation: one dot per neighbourhood, at its corners' centre.
        let centres = found.groups.map { group -> (x: Double, y: Double) in
            let spots = group.map { cornerSpots[cornerNames.firstIndex(of: $0)!] }
            return (spots.map(\.x).reduce(0, +) / Double(spots.count), spots.map(\.y).reduce(0, +) / Double(spots.count))
        }
        let dots = found.groups.enumerated().map { c, group in
            CanvasNode(x: 30 + centres[c].x * 0.85, y: 20 + centres[c].y * 0.85, name: group.count == 1 ? group[0] : "", badge: "\(group.count)",
                       radius: 12 + 3 * Double(group.count), classes: "pal\(c % 8)")
        }
        let links = found.links.edges.map { CanvasEdge(from: $0.source, to: $0.target, directed: true, classes: "tree") }
        div {
        section(.class("lab"), .custom(name: "aria-label", value: "One-way streets")) {
            div(.class("panel stage")) {
                GraphCanvas(label: "Nine street corners joined by one-way streets", width: 640, height: 410,
                            nodes: nodes, edges: edges, onEdge: { componentsModel.flip($0) })
                p(.class("note")) { "Click a street to turn it around. Corners of the same colour are in the same neighbourhood. Grey dashed streets run between neighbourhoods." }
            }
            div(.class("side")) {
                div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                    span(.class("label")) { k == found.events.count ? "\(found.groups.count) strongly connected components" : "Event \(k) of \(found.events.count)" }
                    p(.class("narration")) {
                        if k == found.events.count {
                            "Inside a colour you can drive from any corner to any other and back. Between colours, traffic only flows one way."
                        } else if let last = snapshot.last {
                            streetText(last, completes: StreetSnapshot.completes(last, found.events, colour))
                        } else {
                            "A depth-first search drives down one-way streets. A neighbourhood is complete when the search backs out of the first corner it entered there."
                        }
                    }
                    div(.class("chips")) {
                        for (c, group) in found.groups.enumerated() where snapshot.complete.contains(c) { span(.class("chip pal\(c % 8)")) { groupText(group) } }
                    }
                }
                div(.class("panel")) {
                    span(.class("label")) { "The condensation, each neighbourhood squeezed to a dot" }
                    GraphCanvas(label: "The condensation: one vertex per strongly connected component", width: 600, height: 380, nodes: dots, edges: links)
                    p(.class("note")) { "It never has a cycle. A cycle between neighbourhoods would make them one neighbourhood." }
                }
            }
        }
        section(.class("panel controls"), .custom(name: "aria-label", value: "Streets playback")) {
            div(.class("buttons")) {
                PlaybackButtons(playback: playback)
                span(.class("spacer")) {}
                button(.type(.button)) { "Reset both maps" }
                    .onClick {
                        componentsModel.oneWay = startingOneWay
                        componentsModel.broken = startingBroken
                        componentsModel.rerunIslands()
                        componentsModel.rerunStreets()
                    }
            }
            Timeline(
                playback: playback,
                marbles: found.events.map { event in
                    let completes = StreetSnapshot.completes(event, found.events, colour)
                    switch event {
                    case .discover(let v): return Marble(kind: "m-blue", radius: 9, letter: String(v.prefix(1)), title: streetText(event, completes: false))
                    case .finish(let v): return completes
                        ? Marble(kind: "m-pal\(colour[v]! % 8)", radius: 11, letter: "✓", title: streetText(event, completes: true))
                        : Marble(kind: "m-hollow", radius: 7, title: streetText(event, completes: false))
                    default: return Marble(kind: "m-grey", radius: 4, title: streetText(event, completes: false))
                    }
                },
                legend: [(Marble(kind: "m-blue", radius: 6), "enter a corner"), (Marble(kind: "m-hollow", radius: 5), "back out of it"),
                         (Marble(kind: "m-pal0", radius: 6), "a neighbourhood is complete"), (Marble(kind: "m-grey", radius: 3.5), "drive down a street")])
        }
        }
    }
}

/// The sentence for one event of the streets' depth-first search.
func streetText(_ event: DepthFirstSearchEvent<String>, completes: Bool) -> String {
    switch event {
    case .discover(let v): return "Drive into \(v) for the first time."
    case .finish(let v):
        return completes
            ? "Back out of \(v), the first corner entered in its neighbourhood. That neighbourhood is now complete."
            : "Every street out of \(v) has been driven. Back out of \(v)."
    case .treeEdge(let e): return "Drive \(e.source) → \(e.target), to a corner not yet visited."
    case .backEdge(let e), .forwardEdge(let e), .crossEdge(let e): return "The street \(e.source) → \(e.target) leads somewhere already visited."
    }
}

@View
struct IslandsCodePanel {
    var body: some View {
        let model = componentsModel
        let groups = model.islands.groups
        CodePanel(
            snippets: [
                .componentsImports,
                Snippet(lines: ["let names = [" + islandNames.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let bridges = ["]
                    + standingBridges(model.broken).map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                .componentsIslands,
            ],
            results: ["\(groups.count): " + groups.map(groupText).joined(separator: " ")])
    }
}

@View
struct StreetsCodePanel {
    var body: some View {
        let model = componentsModel
        let found = model.streets
        CodePanel(
            snippets: [
                .componentsImports,
                Snippet(lines: ["let corners = [" + cornerNames.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let oneWay = ["]
                    + model.oneWay.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                .componentsStreets,
            ],
            results: [
                "\(found.groups.count): " + found.groups.map(groupText).joined(separator: " "),
                "\(found.links.edgeCount)",
                "\(found.events.count) events",
            ])
    }
}

enum ComponentsPage {
    static func mount() {
        mountView(IslandsLab(), in: "islands")
        mountView(StreetsLab(), in: "app")
        mountView(IslandsCodePanel(), in: "code-islands")
        mountView(StreetsCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.kosaraju]), in: "names")
    }
}
