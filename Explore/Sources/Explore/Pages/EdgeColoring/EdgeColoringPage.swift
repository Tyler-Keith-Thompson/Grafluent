import AdjacencyListModule
import ColoringModule
import ElementaryUI
import GraphProtocols
import Reactivity

/// Where the teams sit, evenly round a circle, for each number of teams, in SVG units of the
/// 640 × 440 view box.
let leagueSeats: [Int: [(x: Double, y: Double)]] = [
    3: [(320, 50), (463, 298), (177, 298)],
    4: [(320, 50), (485, 215), (320, 380), (155, 215)],
    5: [(320, 50), (477, 164), (417, 348), (223, 348), (163, 164)],
    6: [(320, 50), (463, 132), (463, 298), (320, 380), (177, 298), (177, 132)],
    7: [(320, 50), (449, 112), (481, 252), (392, 364), (248, 364), (159, 252), (191, 112)],
    8: [(320, 50), (437, 98), (485, 215), (437, 332), (320, 380), (203, 332), (155, 215), (203, 98)],
]

@Reactive
final class EdgeColoringModel {
    var teamCount = 6
    /// Whether the schedule shown is the circle method's rather than edgeColoring()'s.
    var circle = false
    var league = UndirectedAdjacencyList<String>()
    var colouring: [Int] = []
    var circleRounds: [Int] = []
    var circleIsProper = false
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1100, scrubID: "scrub-edgecoloring")

    init() {
        run()
    }

    func run() {
        (league, colouring, circleRounds, circleIsProper) = roundRobin(count: teamCount)
        playback.reset(count: roundCount)
        setProperty(id: "edgecoloring-teams", "value", to: "\(teamCount)")
    }

    func choose(teams n: Int) {
        teamCount = n
        run()
    }

    func choose(circle: Bool) {
        self.circle = circle
        playback.reset(count: roundCount)
    }

    /// The round of each match, by edge position, in the schedule shown.
    var rounds: [Int] { circle ? circleRounds : colouring }
    var roundCount: Int { (rounds.max() ?? -1) + 1 }
    /// The fewest rounds any schedule can have: n − 1 for an even count, n for an odd one.
    var fewest: Int { teamCount.isMultiple(of: 2) ? teamCount - 1 : teamCount }

    /// The matches of round `r`, by edge position.
    func matches(in r: Int) -> [Int] { league.edges.indices.filter { rounds[$0] == r } }

    /// The teams resting in round `r`.
    func resting(in r: Int) -> [String] {
        let playing = Set(matches(in: r).flatMap { [league.edges[$0].u, league.edges[$0].v] })
        return leagueTeams.prefix(teamCount).filter { !playing.contains($0) }
    }
}

let edgeColoringModel = EdgeColoringModel()

func describeRound(_ r: Int, _ model: EdgeColoringModel) -> String {
    let games = model.matches(in: r).map { "\(model.league.edges[$0].u)–\(model.league.edges[$0].v)" }
    let rest = model.resting(in: r)
    let resting = rest.isEmpty ? " Every team plays." : " \(guestList(rest)) \(rest.count == 1 ? "rests" : "rest")."
    return "Round \(r + 1) plays \(guestList(games)). No team is in two of them, so they can all be played at once." + resting
}

@View
struct EdgeColoringLab {
    var body: some View {
        let model = edgeColoringModel
        let playback = model.playback
        let k = playback.k
        let n = model.teamCount
        let finished = k == model.roundCount
        let rounds = model.rounds
        let current = k > 0 && !finished ? k - 1 : -1
        let playing = Set(current >= 0 ? model.matches(in: current).flatMap { [model.league.edges[$0].u, model.league.edges[$0].v] } : [])
        let teams = Array(leagueTeams.prefix(n))
        let nodes = teams.enumerated().map { i, team in
            let (x, y) = leagueSeats[n]![i]
            return CanvasNode(x: x, y: y, name: team, badge: String(team.prefix(1)), radius: 18,
                              classes: current < 0 ? "" : playing.contains(team) ? "visited" : "dim", nameAbove: y < 215)
        }
        let index = Dictionary(uniqueKeysWithValues: teams.enumerated().map { ($0.element, $0.offset) })
        let edges = model.league.edges.indices.map { e in
            let edge = model.league.edges[e]
            let r = rounds[e]
            return CanvasEdge(from: index[edge.u]!, to: index[edge.v]!,
                              classes: r >= k ? "" : "pal\(r % 8)" + (current >= 0 && r != current ? " past" : ""))
        }
        let extra = model.roundCount - model.fewest

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A round-robin schedule")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "\(n) teams, a line for every match, coloured by round", width: 640, height: 440, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line")) {}; "a match not scheduled yet" }
                        span { i(.class("dot visited")) {}; "playing this round" }
                        span { "one colour per round" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "The whole schedule" : k == 0 ? "\(model.roundCount) rounds to show" : "Round \(k) of \(model.roundCount)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "\(n) teams each play every other team once. That makes \(model.league.edgeCount) matches. Each round gets a colour. Press Step to see the first round."
                            } else if finished {
                                "Every match has a round, and there are \(model.roundCount) rounds. "
                                extra == 0
                                    ? (n.isMultiple(of: 2) ? "That is the fewest possible. Each team plays \(n - 1) matches, at most one a round." : "That is the fewest possible. With an odd number of teams, someone rests every round.")
                                    : "The fewest possible is \(model.fewest), so this schedule has \(extra) round more than it needs. Vizing’s theorem promises \(n - 1) or \(n) rounds. Misra and Gries’s method keeps that promise, but it doesn’t always find the smaller."
                            } else {
                                describeRound(k - 1, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Schedule" }
                        div(.class("stat")) {
                            div(.class(extra == 0 ? "good" : "bad")) {
                                span(.class("num")) { "\(model.roundCount)" }
                                "rounds"
                            }
                            div {
                                span(.class("num")) { "\(model.fewest)" }
                                "the fewest possible"
                            }
                        }
                        div(.class("queue")) {
                            for r in 0 ..< k {
                                div(.class(r == current ? "qrow top" : "qrow")) {
                                    span { "Round \(r + 1)" }
                                    span { model.matches(in: r).map { "\(model.league.edges[$0].u.prefix(1))–\(model.league.edges[$0].v.prefix(1))" }.joined(separator: " ") }
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
                    label(.class("field"), .for("edgecoloring-teams")) {
                        "Teams "
                        select(.id("edgecoloring-teams")) {
                            for count in 3 ... leagueTeams.count {
                                option(.value("\(count)")) { "\(count)" }.attributes(.selected, when: count == n)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let count = Int(value) { edgeColoringModel.choose(teams: count) }
                        }
                    }
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Schedule")) {
                        button(.type(.button), .class(model.circle ? "" : "on")) { "edgeColoring()" }
                            .onClick { edgeColoringModel.choose(circle: false) }
                        button(.type(.button), .class(model.circle ? "on" : "")) { "Circle method" }
                            .onClick { edgeColoringModel.choose(circle: true) }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: (0 ..< model.roundCount).map { r in
                        Marble(kind: "m-pal\(r % 8)", radius: 11, letter: "\(model.matches(in: r).count)", title: describeRound(r, model))
                    },
                    legend: [
                        (Marble(kind: "m-pal0", radius: 6), "a round, in its colour, with its number of matches"),
                    ])
                p(.class("note")) { "Each step shows one round of the finished schedule, the matches of one colour; the colouring itself is computed all at once." }
            }
        }
    }
}

@View
struct EdgeColoringCodePanel {
    var body: some View {
        let model = edgeColoringModel
        let edges = model.league.edges
        let first = model.colouring.indices.filter { model.colouring[$0] == 0 }.map { "UndirectedEdge(\"\(edges[$0].u)\", \"\(edges[$0].v)\")" }
        CodePanel(
            snippets: [
                .edgecoloringImports,
                Snippet(lines: ["let leagueTeams = [" + leagueTeams.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let n = \(model.teamCount)"]),
                .edgecoloringLeague, .edgecoloringVizing, .edgecoloringCircle,
            ],
            results: [
                "\((model.colouring.max() ?? -1) + 1)",
                "[" + first.joined(separator: ", ") + "]",
                "\(model.circleIsProper)",
            ])
    }
}

enum EdgeColoringPage {
    static func mount() {
        mountView(EdgeColoringLab(), in: "app")
        mountView(EdgeColoringCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.vizing, Names.konig]), in: "names")
    }
}
