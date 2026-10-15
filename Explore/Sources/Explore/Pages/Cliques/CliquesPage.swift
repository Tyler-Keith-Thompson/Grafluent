import AdjacencyListModule
import Cliques
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each guest and where they stand, in SVG units of the 680 × 400 view box.
let guestSpots: [(name: String, x: Double, y: Double)] = [
    ("Ana", 80, 140), ("Ben", 240, 60), ("Cy", 140, 300), ("Dee", 290, 220), ("Eli", 400, 330),
    ("Fay", 570, 300), ("Gus", 450, 170), ("Hal", 610, 110),
]

let guestIndex: [String: Int] = Dictionary(uniqueKeysWithValues: guestSpots.enumerated().map { ($0.element.name, $0.offset) })

/// One call of the search as it stands: R, P, X, and its pivot once chosen.
struct CliqueFrame {
    var adding: String
    var clique: [String]
    var candidates: [String]
    var excluded: [String]
    var pivot: String?
}

/// What the party shows after some events: the calls in progress, innermost last, and the
/// maximal cliques found.
struct CliqueSnapshot {
    var frames: [CliqueFrame] = []
    var found: [[String]] = []
    /// The guest the last backtrack moved from P to X, in the call it returned to.
    var movedToExcluded: String?

    /// The state after `event`. A call pushes a frame; a backtrack pops it and, in the call it
    /// returns to, moves the vertex it added from P to X, as the search does.
    func after(_ event: BronKerboschEvent<String>) -> CliqueSnapshot {
        var next = self
        next.movedToExcluded = nil
        switch event {
        case .call(let adding, let clique, let candidates, let excluded):
            next.frames.append(CliqueFrame(adding: adding, clique: clique, candidates: candidates, excluded: excluded))
        case .pivot(let u):
            next.frames[next.frames.count - 1].pivot = u
        case .maximalClique(let clique):
            next.found.append(clique)
        case .backtrack:
            let done = next.frames.removeLast()
            if !next.frames.isEmpty {
                let top = next.frames.count - 1
                next.frames[top].candidates.removeAll { $0 == done.adding }
                next.frames[top].excluded = guestSpots.map(\.name).filter { next.frames[top].excluded.contains($0) || $0 == done.adding }
                next.movedToExcluded = done.adding
            }
        }
        return next
    }
}

@Reactive
final class CliquesModel {
    var events: [BronKerboschEvent<String>] = []
    var cliques: [[String]] = []
    var largest: [String] = []
    /// `snapshots[k]` is the party after the first `k` events.
    var snapshots: [CliqueSnapshot] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 900, scrubID: "scrub-cliques")

    init() {
        (events, cliques, largest) = partyCliques()
        var state = CliqueSnapshot()
        snapshots = [state]
        for event in events {
            state = state.after(event)
            snapshots.append(state)
        }
        playback.reset(count: events.count)
    }
}

let cliquesModel = CliquesModel()

/// `Ana, Ben and Cy`, or `nobody`.
func guestList(_ names: [String]) -> String {
    names.isEmpty ? "nobody" : names.count == 1 ? names[0] : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

func describeClique(_ event: BronKerboschEvent<String>, before: CliqueSnapshot, after: CliqueSnapshot) -> String {
    switch event {
    case .call(let adding, let clique, let candidates, let excluded):
        let start = clique.count == 1
            ? "Start a group with \(adding)."
            : "Add \(adding): the group is now \(guestList(clique))."
        return start + " Could still join, knowing everyone in it: \(guestList(candidates)). Already tried: \(guestList(excluded))."
    case .pivot(let u):
        let frame = after.frames.last!
        let skipped = frame.candidates.filter { $0 != u && party.contains(edge: UndirectedEdge($0, u)) }
        return skipped.isEmpty
            ? "Pivot on \(u). Every candidate needs trying from here."
            : "Pivot on \(u), who knows \(guestList(skipped)). Any group built from \(u)’s friends alone could take \(u) too, so it will turn up through \(u): only the others need trying here."
    case .maximalClique(let clique):
        return "Nobody can join, and nobody already tried could either: \(guestList(clique)) is a maximal clique."
    case .backtrack:
        guard let moved = after.movedToExcluded else { return "Done with \(before.frames.last!.adding)’s start." }
        return "Back out of \(moved). From here on \(moved) counts as already tried, so no group is found twice."
    }
}

func cliqueMarble(_ event: BronKerboschEvent<String>, title: String) -> Marble {
    switch event {
    case .call(let adding, let clique, _, _): Marble(kind: clique.count == 1 ? "m-blue" : "m-hollow", radius: 9, letter: String(adding.prefix(1)), title: title)
    case .pivot: Marble(kind: "m-violet", radius: 6, title: title)
    case .maximalClique(let clique): Marble(kind: "m-green", radius: 11, letter: "\(clique.count)", title: title)
    case .backtrack: Marble(kind: "m-grey", radius: 4, title: title)
    }
}

@View
struct CliquesLab {
    var body: some View {
        let model = cliquesModel
        let playback = model.playback
        let k = playback.k
        let state = model.snapshots[k]
        let before = model.snapshots[max(0, k - 1)]
        let last = k > 0 ? model.events[k - 1] : nil
        let finished = k == model.events.count
        let frame = state.frames.last
        let inR = Set(frame?.clique ?? []), inP = Set(frame?.candidates ?? []), inX = Set(frame?.excluded ?? [])
        let justFound: [String] = { if case .maximalClique(let c)? = last { return c }; return [] }()
        let foundIndex: [String: Int] = Dictionary(state.found.enumerated().flatMap { n, c in c.map { ($0, n) } }, uniquingKeysWith: { a, _ in a })
        let nodes = guestSpots.map { spot in
            let name = spot.name
            let base = finished ? "pal\((foundIndex[name] ?? 0) % 8)"
                : justFound.contains(name) ? "visited" : inR.contains(name) ? "visited" : inP.contains(name) ? "frontier" : inX.contains(name) ? "excluded" : ""
            return CanvasNode(x: spot.x, y: spot.y, name: name, badge: String(name.prefix(1)), radius: 18,
                              classes: base + (frame?.pivot == name && !finished ? " selected" : ""))
        }
        let edges = haveMet.map { pair in
            let inside = inR.contains(pair.u) && inR.contains(pair.v)
            return CanvasEdge(from: guestIndex[pair.u]!, to: guestIndex[pair.v]!, classes: inside && !finished ? "tree" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The party")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eight guests at a party, a line between each pair who have met", width: 680, height: 400, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "R: the group being grown" }
                        span { i(.class("dot frontier")) {}; "P: could still join" }
                        span { i(.class("dot excluded")) {}; "X: already tried" }
                        span { i(.class("dot selected")) {}; "the pivot" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(model.events.count) events" : "Event \(k) of \(model.events.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Grow a group one guest at a time, keeping track of who could still join (everyone in the group knows them) and who has already been tried. When nobody can join, the group is a maximal clique. Press Step to begin."
                            } else if finished {
                                "Every start is tried: \(state.found.count) maximal cliques, each in its own colour. The largest, "
                                em { guestList(model.largest) }
                                ", is a maximum clique: \(model.largest.count) guests who have all met."
                            } else {
                                describeClique(last!, before: before, after: state)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The current call" }
                        div(.class("queue")) {
                            div(.class("qrow plain")) {
                                span { "R, the group" }
                                span { guestList(frame?.clique ?? []) }
                            }
                            div(.class("qrow")) {
                                span { "P, could join" }
                                span { guestList(frame?.candidates ?? []) }
                            }
                            div(.class("qrow cable later")) {
                                span { "X, already tried" }
                                span { guestList(frame?.excluded ?? []) }
                            }
                        }
                        p(.class("note")) { "Calls in progress: \(state.frames.count), one per guest in the group." }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Maximal cliques found" }
                        div(.class("chips")) {
                            if state.found.isEmpty { p(.class("empty")) { "None yet" } }
                            for (n, clique) in state.found.enumerated() {
                                span(.class("chip pal\(n % 8)")) { clique.joined(separator: " ") }
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
                    marbles: model.events.indices.map { j in
                        cliqueMarble(model.events[j], title: describeClique(model.events[j], before: model.snapshots[j], after: model.snapshots[j + 1]))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "start a group"),
                        (Marble(kind: "m-hollow", radius: 6), "add a guest"),
                        (Marble(kind: "m-violet", radius: 5), "choose a pivot"),
                        (Marble(kind: "m-green", radius: 6), "a maximal clique, with its size"),
                        (Marble(kind: "m-grey", radius: 3.5), "back out"),
                    ])
                p(.class("note")) { "A line joins each pair who have met. The outer calls start from each guest in turn, in degeneracy order: those with the fewest connections to the rest go first." }
            }
        }
    }
}

@View
struct CliquesCodePanel {
    var body: some View {
        let model = cliquesModel
        CodePanel(
            snippets: [.cliquesImports, .cliquesParty, .cliquesSearch],
            results: [
                "\(model.events.count) events",
                "[" + model.cliques.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]",
                "[" + model.largest.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

enum CliquesPage {
    static func mount() {
        mountView(CliquesLab(), in: "app")
        mountView(CliquesCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.bronKerbosch, Names.tomita]), in: "names")
    }
}
