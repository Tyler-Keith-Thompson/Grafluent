import ElementaryUI
import MatchingModule
import Reactivity

/// Students and tutors in two columns of the 640 × 440 view box: node `i` is student `i`, node
/// `4 + j` is tutor `j`.
let matchSpots: [(x: Double, y: Double)] = [(130, 60), (130, 170), (130, 280), (130, 390), (510, 60), (510, 170), (510, 280), (510, 390)]

/// The held pairs after some events, by reviewer.
struct MatchState {
    var held: [Int?] = [nil, nil, nil, nil]
}

@Reactive
final class StableMatchingModel {
    var studentsPropose = true
    var events: [GaleShapleyEvent] = []
    var states: [MatchState] = []
    /// Each student's tutor when students propose, and when tutors do.
    var studentsFirst: [Int?] = []
    var tutorsFirst: [Int?] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1000, scrubID: "scrub-stablematching")

    init() {
        studentsFirst = matchingRun(studentsPropose: true).mates
        let tutorMates = matchingRun(studentsPropose: false).mates
        tutorsFirst = students.indices.map { s in tutorMates.firstIndex { $0 == s } }
        run()
    }

    func run() {
        events = matchingRun(studentsPropose: studentsPropose).events
        var state = MatchState()
        states = [state]
        for event in events {
            switch event {
            case .accept(let p, let r): state.held[r] = p
            case .tradeUp(let r, _, let to): state.held[r] = to
            default: break
            }
            states.append(state)
        }
        playback.reset(count: events.count)
    }

    func choose(studentsPropose: Bool) {
        self.studentsPropose = studentsPropose
        run()
    }

    var proposerNames: [String] { studentsPropose ? students : tutors }
    var reviewerNames: [String] { studentsPropose ? tutors : students }
    var proposerLikes: [[String]] { studentsPropose ? studentLikes : tutorLikes }
    var reviewerLikes: [[String]] { studentsPropose ? tutorLikes : studentLikes }

    /// The canvas node of proposer `p` and of reviewer `r`.
    func node(proposer p: Int) -> Int { studentsPropose ? p : 4 + p }
    func node(reviewer r: Int) -> Int { studentsPropose ? 4 + r : r }
}

let stableMatchingModel = StableMatchingModel()

/// `1st`, `2nd`, `3rd`, `4th`.
func ordinal(_ n: Int) -> String { n == 1 ? "1st" : n == 2 ? "2nd" : n == 3 ? "3rd" : "\(n)th" }

func describeMatchEvent(_ event: GaleShapleyEvent, _ model: StableMatchingModel) -> String {
    let p = model.proposerNames, r = model.reviewerNames
    func rank(_ who: String, in likes: [String]) -> String { ordinal(likes.firstIndex(of: who)! + 1) }
    switch event {
    case .propose(let a, let b):
        return "\(p[a]) asks \(r[b]), \(p[a])’s \(rank(r[b], in: model.proposerLikes[a])) choice."
    case .accept(let a, let b):
        return "\(r[b]) is free, so holds on to \(p[a]) for now."
    case .reject(let a, let b):
        let held = model.reviewerLikes[b]
        return "\(r[b]) says no: \(p[a]) is \(r[b])’s \(rank(p[a], in: held)) choice, worse than the one \(r[b]) holds."
    case .tradeUp(let b, let from, let to):
        return "\(r[b]) prefers \(p[to]) (\(rank(p[to], in: model.reviewerLikes[b]))) to \(p[from]) (\(rank(p[from], in: model.reviewerLikes[b]))): trades up, and \(p[from]) is free again."
    case .exhausted(let a):
        return "\(p[a]) has asked everyone and stays unmatched."
    }
}

@View
struct StableMatchingLab {
    var body: some View {
        let model = stableMatchingModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.events.count
        let state = model.states[k]
        let last = k > 0 ? model.events[k - 1] : nil
        let asking: (Int, Int)? = { if case .propose(let a, let b)? = last { return (a, b) }; return nil }()
        let refused: (Int, Int)? = {
            switch last {
            case .reject(let a, let b)?: return (a, b)
            case .tradeUp(let b, let from, _)?: return (from, b)
            default: return nil
            }
        }()
        let names = students + tutors
        let nodes = matchSpots.indices.map { v in
            let proposerSide = model.studentsPropose ? v < 4 : v >= 4
            return CanvasNode(x: matchSpots[v].x, y: matchSpots[v].y, name: names[v], badge: String(names[v].prefix(1)), radius: 20,
                              classes: proposerSide ? "visited" : "pal1")
        }
        let heldEdges = (0 ..< 4).compactMap { r in state.held[r].map { p in CanvasEdge(from: model.node(proposer: p), to: model.node(reviewer: r), directed: true, classes: "tree") } }
        let askEdge = asking.map { [CanvasEdge(from: model.node(proposer: $0.0), to: model.node(reviewer: $0.1), directed: true, classes: "active")] } ?? []
        let refuseEdge = refused.map { [CanvasEdge(from: model.node(proposer: $0.0), to: model.node(reviewer: $0.1), directed: true, classes: "cancel")] } ?? []
        let edges = heldEdges + askEdge + refuseEdge

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Students and tutors")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Four students and four tutors; an arrow from each proposer to the one holding them", width: 640, height: 440, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; model.studentsPropose ? "students, asking" : "tutors, asking" }
                        span { i(.class("dot pal1")) {}; model.studentsPropose ? "tutors, answering" : "students, answering" }
                        span { i(.class("line active")) {}; "asking" }
                        span { i(.class("line tree")) {}; "held for now" }
                        span { i(.class("line cancel")) {}; "turned down" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Stable" : k == 0 ? "\(model.events.count) events to come" : "Event \(k) of \(model.events.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Every \(model.studentsPropose ? "student" : "tutor") asks their favourite first. Whoever is asked holds on to the best offer so far and turns the rest down, trading up when a better one comes. Press Step."
                            } else if finished {
                                "Nobody is left asking. No student and tutor would both rather have each other than the partners they have: the matching is stable. "
                                model.studentsPropose
                                    ? "With students asking, every student gets the best partner any stable matching could give them."
                                    : "With tutors asking, every tutor gets their best stable partner, and every student their worst."
                            } else {
                                describeMatchEvent(last!, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Who each student ends up with" }
                        div(.class("queue")) {
                            for s in students.indices {
                                let a = model.studentsFirst[s], b = model.tutorsFirst[s]
                                let rankA = a.map { studentLikes[s].firstIndex(of: tutors[$0])! + 1 }, rankB = b.map { studentLikes[s].firstIndex(of: tutors[$0])! + 1 }
                                div(.class(finished && rankA != rankB ? "qrow top" : "qrow")) {
                                    span { students[s] }
                                    span(.class("num")) { (a.map { "\(tutors[$0]) \(ordinal(rankA!))" } ?? "–") + " · " + (b.map { "\(tutors[$0]) \(ordinal(rankB!))" } ?? "–") }
                                }
                            }
                        }
                        p(.class("note")) { "Each row: the tutor a student gets when students ask, then when tutors ask, with the student’s own rank of them; 1st is their favourite." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Who asks")) {
                        button(.type(.button), .class(model.studentsPropose ? "on" : "")) { "Students ask" }
                            .onClick { stableMatchingModel.choose(studentsPropose: true) }
                        button(.type(.button), .class(model.studentsPropose ? "" : "on")) { "Tutors ask" }
                            .onClick { stableMatchingModel.choose(studentsPropose: false) }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: model.events.map { event in
                        let title = describeMatchEvent(event, model)
                        switch event {
                        case .propose(let a, _): return Marble(kind: "m-blue", radius: 8, letter: String(model.proposerNames[a].prefix(1)), title: title)
                        case .accept: return Marble(kind: "m-green", radius: 6, title: title)
                        case .reject: return Marble(kind: "m-red", radius: 6, title: title)
                        case .tradeUp: return Marble(kind: "m-ring", radius: 6, title: title)
                        case .exhausted: return Marble(kind: "m-grey", radius: 6, title: title)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "an offer"),
                        (Marble(kind: "m-green", radius: 5), "held"),
                        (Marble(kind: "m-ring", radius: 5), "traded up"),
                        (Marble(kind: "m-red", radius: 5), "turned down"),
                    ])
                p(.class("note")) { "The events are those of galeShapley; the final pairs are stableMatching’s." }
            }
        }
    }
}

@View
struct StableMatchingCodePanel {
    var body: some View {
        let model = stableMatchingModel
        let mates = matchingRun(studentsPropose: model.studentsPropose).mates
        CodePanel(
            snippets: [
                .stablematchingImports, .stablematchingPreferences,
                Snippet(lines: ["let studentsPropose = \(model.studentsPropose)"]),
                .stablematchingRun,
            ],
            results: ["\(model.events.count) events", "[" + mates.map { $0.map(String.init) ?? "nil" }.joined(separator: ", ") + "]"])
    }
}

enum StableMatchingPage {
    static func mount() {
        mountView(StableMatchingLab(), in: "app")
        mountView(StableMatchingCodePanel(), in: "code")
    }
}
