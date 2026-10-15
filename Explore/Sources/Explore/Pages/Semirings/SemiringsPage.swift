import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Semirings
import Traversal

/// Each place on the network and where it sits, in SVG units of the 680 × 400 view box.
let networkSpots: [(name: String, x: Double, y: Double)] = [
    ("Server", 60, 200), ("North", 210, 80), ("South", 210, 320), ("Mill", 330, 200),
    ("Bank", 450, 320), ("Dock", 470, 80), ("Farm", 620, 200),
]

let networkIndex: [String: Int] = Dictionary(uniqueKeysWithValues: networkSpots.enumerated().map { ($0.element.name, $0.offset) })

/// One question the page asks: what extending and choosing mean for it, and how its values read.
struct SemiringQuestion {
    var title: String
    var question: String
    var extend: String
    var choose: String
    var noRoute: String
    var alreadyThere: String
}

let semiringQuestions = [
    SemiringQuestion(title: "Quickest", question: "How fast can data get there?", extend: "+", choose: "min", noRoute: "∞", alreadyThere: "0"),
    SemiringQuestion(title: "Widest", question: "How much bandwidth does the best route carry?", extend: "min", choose: "max", noRoute: "0", alreadyThere: "∞"),
    SemiringQuestion(title: "Most reliable", question: "What is the best chance every link on a route is up?", extend: "×", choose: "max", noRoute: "0", alreadyThere: "1"),
    SemiringQuestion(title: "Reachable", question: "Can data get there at all?", extend: "and", choose: "or", noRoute: "false", alreadyThere: "true"),
    SemiringQuestion(title: "How many routes", question: "How many different routes are there?", extend: "×", choose: "+", noRoute: "0", alreadyThere: "1"),
]

/// One way into a place: the link, the value at its start, the link's own value, and their
/// extension.
struct SemiringCandidate {
    var edge: DirectedEdge<String>
    var from: String
    var start: String
    var weight: String
    var extended: String
}

/// One place's answer, in the order the page shows them: the ways in from places already
/// answered, each extended, and the choice between them.
struct SemiringStep {
    var place: String
    var value: String
    var candidates: [SemiringCandidate]
    /// The places with a link in that are not answered yet.
    var waiting: [String]
    /// The link the best route arrives by, for the questions that pick one route.
    var via: DirectedEdge<String>?
    /// Whether choosing between the candidates gives Grafluent's value.
    var agrees: Bool
}

/// The steps for one question: each place in `order`, its ways in from earlier places extended
/// with `times(_:)` and chosen between with `plus(_:)`, checked against Grafluent's answer.
func semiringSteps<S: Semiring>(_ answer: SemiringAnswer<S>, order: [String], weight: (DirectedEdge<String>) -> S, show: (S) -> String, showWeight: (S) -> String) -> [SemiringStep] {
    var steps: [SemiringStep] = []
    var done: [String] = []
    for place in order {
        let value = answer.value[place] ?? S.zero
        var candidates: [SemiringCandidate] = []
        var chosen = place == "Server" ? S.one : S.zero
        for connection in connections where connection.edge.target == place && done.contains(connection.edge.source) {
            let start = answer.value[connection.edge.source] ?? S.zero
            let extended = start.times(weight(connection.edge))
            candidates.append(SemiringCandidate(edge: connection.edge, from: connection.edge.source, start: show(start), weight: showWeight(weight(connection.edge)), extended: show(extended)))
            chosen = chosen.plus(extended)
        }
        let waiting = connections.filter { $0.edge.target == place && !done.contains($0.edge.source) }.map(\.edge.source)
        steps.append(SemiringStep(place: place, value: show(value), candidates: candidates, waiting: waiting, via: answer.via[place], agrees: chosen == value))
        done.append(place)
    }
    return steps
}

/// `place` sorted best first by the semiring's order, ties in the network's order: the order in
/// which Dijkstra's algorithm settles them.
func bestFirst<S: SelectiveSemiring>(_ answer: SemiringAnswer<S>) -> [String] {
    network.vertices.filter { answer.value[$0] != nil && answer.value[$0] != S.zero }
        .sorted { (answer.value[$0]!, networkIndex[$0]!) < (answer.value[$1]!, networkIndex[$1]!) }
}

@Reactive
final class SemiringsModel {
    var question = 0
    var steps: [SemiringStep] = []
    var farm = ""
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1100, scrubID: "scrub-semirings")

    init() {
        ask(0)
    }

    func ask(_ n: Int) {
        question = n
        switch n {
        case 0:
            let answer = quickestRoutes()
            steps = semiringSteps(answer, order: bestFirst(answer), weight: { TropicalSemiring(link[$0]!.minutes) },
                                  show: { "\($0.value) min" }, showWeight: { "\($0.value) min" })
            farm = answer.farm.map { "\($0.value) min" } ?? "nil"
        case 1:
            let answer = widestRoutes()
            steps = semiringSteps(answer, order: bestFirst(answer), weight: { BottleneckSemiring(link[$0]!.megabits) },
                                  show: { $0 == .one ? "∞" : "\($0.value) Mbit/s" }, showWeight: { "\($0.value) Mbit/s" })
            farm = answer.farm.map { "\($0.value) Mbit/s" } ?? "nil"
        case 2:
            let answer = mostReliableRoutes()
            steps = semiringSteps(answer, order: bestFirst(answer), weight: { ViterbiSemiring(link[$0]!.up) },
                                  show: { threePlaces($0.value) }, showWeight: { twoPlaces($0.value) })
            farm = answer.farm.map { threePlaces($0.value) } ?? "nil"
        case 3:
            let answer = reachableRoutes()
            steps = semiringSteps(answer, order: bestFirst(answer), weight: { _ in BooleanSemiring(true) },
                                  show: { "\($0.value)" }, showWeight: { "\($0.value)" })
            farm = answer.farm.map { "\($0.value)" } ?? "nil"
        default:
            let answer = routeCounts()
            let order = network.topologicalSort() ?? []
            steps = semiringSteps(answer, order: order, weight: { _ in CountingSemiring(1) },
                                  show: { "\($0.value)" }, showWeight: { "\($0.value)" })
            farm = answer.farm.map { "\($0.value)" } ?? "nil"
        }
        playback.reset(count: steps.count)
    }
}

let semirings = SemiringsModel()

/// A link's own value for question `n`, as its label shows it.
func linkLabel(_ edge: DirectedEdge<String>, _ n: Int) -> String {
    let l = link[edge]!
    switch n {
    case 0: return "\(l.minutes) min"
    case 1: return "\(l.megabits)"
    case 2: return twoPlaces(l.up)
    default: return ""
    }
}

func describeSemiringStep(_ step: SemiringStep, _ n: Int) -> String {
    let q = semiringQuestions[n]
    if step.place == "Server" {
        return "Start at the Server. Being already there is worth \(q.alreadyThere): the value that extending leaves unchanged."
    }
    let ways = step.candidates.map { c in
        q.extend == "min" ? "from \(c.from), min(\(c.start), \(c.weight)) = \(c.extended)" : "from \(c.from), \(c.start) \(q.extend) \(c.weight) = \(c.extended)"
    }.joined(separator: "; ")
    let choice = step.candidates.count == 1 ? "Only one to choose from" : "Choose with \(q.choose)"
    let later = step.waiting.isEmpty ? "" : " \(step.waiting.joined(separator: " and ")) isn’t answered yet, and anything through it can only be worse."
    return "\(step.place): extend each way in by its link: \(ways). \(choice): \(step.value)." + later + (step.agrees ? "" : " (Grafluent says otherwise.)")
}

@View
struct SemiringsLab {
    var body: some View {
        let model = semirings
        let n = model.question
        let q = semiringQuestions[n]
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let shown = Array(steps.prefix(k))
        let value: [String: String] = Dictionary(uniqueKeysWithValues: shown.map { ($0.place, $0.value) })
        let last = shown.last
        let finished = k == steps.count
        let selective = n < 4
        let chosenEdges = Set(shown.compactMap { $0.via })
        let countedEdges = Set(shown.flatMap { $0.candidates.map(\.edge) })
        let lastEdges = Set(last?.candidates.map(\.edge) ?? [])
        let nodes = networkSpots.map { spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, note: value[spot.name] ?? "", radius: 17,
                       classes: (value[spot.name] != nil ? "visited" : "") + (spot.name == "Server" ? " source" : "") + (last?.place == spot.name ? " current" : ""))
        }
        let edges = connections.map { connection in
            let e = connection.edge
            let used = selective ? chosenEdges.contains(e) : countedEdges.contains(e)
            return CanvasEdge(from: networkIndex[e.source]!, to: networkIndex[e.target]!, directed: true, label: linkLabel(e, n),
                              classes: (lastEdges.contains(e) ? "active" : used ? "tree" : ""), bend: e == DirectedEdge(from: "North", to: "Bank") ? -40 : 0)
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "One network, five questions")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A network of seven places joined by one-way links, labelled for the question: \(q.title)", width: 680, height: 400, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "answered, with its value" }
                        span { i(.class("line active")) {}; "the ways in being compared" }
                        span { i(.class("line tree")) {}; selective ? "the link each best route arrives by" : "links counted so far" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Every place answered" : "Step \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "\(q.question) Every route from the Server is built by two moves: extend a route by one link, and choose between two routes to the same place. Press Step to begin."
                            } else if finished {
                                "Farm: "
                                em { model.farm }
                                ". The same two moves answered every place; only what extend and choose mean changed."
                            } else {
                                describeSemiringStep(last!, n)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "This question’s two moves" }
                        div(.class("stat")) {
                            div {
                                span(.class("num")) { q.extend }
                                "extend by a link"
                            }
                            div {
                                span(.class("num")) { q.choose }
                                "choose between routes"
                            }
                            div {
                                span(.class("num")) { q.noRoute }
                                "no route"
                            }
                            div {
                                span(.class("num")) { q.alreadyThere }
                                "already there"
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { selective ? "Answered, best first" : "Answered, every link pointing forward" }
                        div(.class("chips")) {
                            if shown.isEmpty { p(.class("empty")) { "None yet" } }
                            for step in shown {
                                span(.class("chip")) {
                                    "\(step.place) "
                                    span(.class("num")) { step.value }
                                }
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    div(.class("segmented many"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Question")) {
                        button(.type(.button), .class(n == 0 ? "on" : "")) { semiringQuestions[0].title }.onClick { semirings.ask(0) }
                        button(.type(.button), .class(n == 1 ? "on" : "")) { semiringQuestions[1].title }.onClick { semirings.ask(1) }
                        button(.type(.button), .class(n == 2 ? "on" : "")) { semiringQuestions[2].title }.onClick { semirings.ask(2) }
                        button(.type(.button), .class(n == 3 ? "on" : "")) { semiringQuestions[3].title }.onClick { semirings.ask(3) }
                        button(.type(.button), .class(n == 4 ? "on" : "")) { semiringQuestions[4].title }.onClick { semirings.ask(4) }
                    }
                }
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { step in
                        Marble(kind: step.candidates.count > 1 ? "m-blue" : "m-hollow", radius: 11, letter: String(step.place.prefix(1)), title: describeSemiringStep(step, n))
                    },
                    legend: [
                        (Marble(kind: "m-blue", radius: 6), "a place with several ways in: choose"),
                        (Marble(kind: "m-hollow", radius: 6), "a place with one way in, or the start"),
                    ])
                p(.class("note")) {
                    selective
                        ? "Places are answered best first, the order Dijkstra’s algorithm settles them in. Numbers on the links are the question’s values."
                        : "Places are answered in topological order, every link pointing forward, as dagShortestDistances relaxes them. Every link counts as 1."
                }
            }
        }
    }
}

@View
struct SemiringsCodePanel {
    var body: some View {
        let model = semirings
        let question: Snippet = [Snippet.semiringsQuickest, .semiringsWidest, .semiringsReliable, .semiringsReachable, .semiringsCount][model.question]
        CodePanel(snippets: [.semiringsImports, .semiringsNetwork, question], results: [model.farm])
    }
}

enum SemiringsPage {
    static func mount() {
        mountView(SemiringsLab(), in: "app")
        mountView(SemiringsCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.dijkstra, Names.mohri, Names.viterbi]), in: "names")
    }
}
