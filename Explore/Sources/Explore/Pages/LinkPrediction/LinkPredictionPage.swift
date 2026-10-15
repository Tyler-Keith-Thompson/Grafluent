import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import Similarity

/// Each friend and where they stand, in SVG units of the 640 × 420 view box.
let palSpots: [(name: String, x: Double, y: Double)] = [
    ("Ana", 110, 220), ("Ben", 300, 110), ("Cy", 290, 260), ("Dee", 200, 370), ("Eli", 450, 200),
    ("Fay", 420, 50), ("Gus", 560, 90), ("Hal", 580, 210), ("Ivy", 400, 360),
]

let palIndex: [String: Int] = Dictionary(uniqueKeysWithValues: palSpots.enumerated().map { ($0.element.name, $0.offset) })

typealias FriendScore = (candidate: String, shared: [String], jaccard: Double, adamicAdar: Double)

@Reactive
final class LinkPredictionModel {
    var person = "Ana"
    /// Whether the ranking is by Adamic–Adar rather than Jaccard.
    var byAdamicAdar = true
    var scores: [FriendScore] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1200, scrubID: "scrub-linkprediction")

    init() {
        choose(person)
    }

    func choose(_ name: String) {
        person = name
        scores = friendSuggestions(for: name)
        playback.reset(count: scores.count)
    }

    /// The candidates scored so far, best first by the chosen measure, ties in seat order.
    func ranked(_ k: Int) -> [FriendScore] {
        let key: (FriendScore) -> Double = byAdamicAdar ? { $0.adamicAdar } : { $0.jaccard }
        return scores.prefix(k).sorted { (-key($0), palIndex[$0.candidate]!) < (-key($1), palIndex[$1.candidate]!) }
    }
}

let linkPredictionModel = LinkPredictionModel()

/// 1 / ln d, what a shared friend with d friends adds to the Adamic–Adar index, for the friend
/// counts this network has.
func inverseLogarithm(_ d: Int) -> Double {
    [2: 1.442695, 3: 0.910239, 4: 0.721348, 5: 0.621335, 6: 0.558111, 7: 0.513898, 8: 0.480898][d] ?? 0
}

func describeCandidate(_ s: FriendScore, person: String, byAdamicAdar: Bool) -> String {
    guard !s.shared.isEmpty else { return "\(s.candidate) shares no friends with \(person), so the score is 0." }
    let count = s.shared.count == 1 ? "one friend" : "\(s.shared.count) friends"
    let head = "\(person) and \(s.candidate) share \(count), \(guestList(s.shared))."
    if byAdamicAdar {
        let parts = s.shared.map { "\($0) knows \(pals.degree(of: $0)) people and adds \(signedTwoPlaces(inverseLogarithm(pals.degree(of: $0))))." }.joined(separator: " ")
        return head + " " + parts + " Adamic–Adar gives \(signedTwoPlaces(s.adamicAdar))."
    }
    let union = pals.degree(of: person) + pals.degree(of: s.candidate) - s.shared.count
    return head + " Between them they know \(union) people. Jaccard gives \(s.shared.count) ÷ \(union) = \(signedTwoPlaces(s.jaccard))."
}

@View
struct LinkPredictionLab {
    var body: some View {
        let model = linkPredictionModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.scores.count
        let current = k > 0 && !finished ? model.scores[k - 1] : nil
        let ranked = model.ranked(k)
        let top = finished ? ranked.first : nil
        let shared = Set(current?.shared ?? [])
        let friends = Set(pals.neighbors(of: model.person))
        let nodes = palSpots.map { spot in
            let name = spot.name
            return CanvasNode(x: spot.x, y: spot.y, name: name, badge: String(name.prefix(1)), radius: 18,
                              classes: name == model.person ? "visited source" : name == current?.candidate || name == top?.candidate ? "frontier" : shared.contains(name) ? "pal2" : friends.contains(name) ? "" : "dim",
                              nameAbove: spot.y < 100)
        }
        let friendEdges = palPairs.map { pair -> CanvasEdge in
            let touches = (pair.u == current?.candidate && shared.contains(pair.v)) || (pair.v == current?.candidate && shared.contains(pair.u))
                || ((pair.u == model.person && shared.contains(pair.v)) || (pair.v == model.person && shared.contains(pair.u)))
            return CanvasEdge(from: palIndex[pair.u]!, to: palIndex[pair.v]!, classes: touches ? "pal2" : "")
        }
        let suggested = (current?.candidate ?? top?.candidate).map { [CanvasEdge(from: palIndex[model.person]!, to: palIndex[$0]!, classes: "cancel")] } ?? []
        let edges = friendEdges + suggested
        let measure = model.byAdamicAdar ? "Adamic–Adar" : "Jaccard"

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The friends")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Nine friends, a line between each pair who are friends", width: 640, height: 420, nodes: nodes, edges: edges,
                                onNode: { linkPredictionModel.choose(palSpots[$0].name) }, nodeAction: "Suggest friends for")
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "suggestions for" }
                        span { i(.class("dot frontier")) {}; "the candidate" }
                        span { i(.class("dot pal2")) {}; "friends they share" }
                        span { i(.class("line cancel")) {}; "the link that might form" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Ranked by \(measure)" : k == 0 ? "\(model.scores.count) people to score" : "Candidate \(k) of \(model.scores.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Who should \(model.person) meet? Score everyone \(model.person) doesn’t know yet by the friends they share. Press Step."
                            } else if finished, let top {
                                "Suggest \(top.candidate) first. "
                                model.byAdamicAdar
                                    ? "Adamic–Adar counts a shared friend for more when that friend has few friends. An introduction through someone who knows everybody says little."
                                    : "Jaccard is the share of all their friends that they have in common. Every shared friend counts the same."
                            } else if let current {
                                describeCandidate(current, person: model.person, byAdamicAdar: model.byAdamicAdar)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Scores so far, by \(measure)" }
                        div(.class("queue")) {
                            if ranked.isEmpty { p(.class("empty")) { "None yet" } }
                            for (j, s) in ranked.enumerated() {
                                div(.class(j == 0 && finished ? "qrow top" : "qrow")) {
                                    span { s.candidate }
                                    span(.class("num")) { signedTwoPlaces(model.byAdamicAdar ? s.adamicAdar : s.jaccard) }
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
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Rank by")) {
                        button(.type(.button), .class(model.byAdamicAdar ? "" : "on")) { "Jaccard" }
                            .onClick { linkPredictionModel.byAdamicAdar = false }
                        button(.type(.button), .class(model.byAdamicAdar ? "on" : "")) { "Adamic–Adar" }
                            .onClick { linkPredictionModel.byAdamicAdar = true }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: model.scores.map { s in
                        s.shared.isEmpty
                            ? Marble(kind: "m-grey", radius: 4, title: describeCandidate(s, person: model.person, byAdamicAdar: model.byAdamicAdar))
                            : Marble(kind: "m-pal2", radius: 9, letter: "\(s.shared.count)", title: describeCandidate(s, person: model.person, byAdamicAdar: model.byAdamicAdar))
                    },
                    legend: [
                        (Marble(kind: "m-pal2", radius: 6), "a candidate, with the friends shared"),
                        (Marble(kind: "m-grey", radius: 3.5), "no friends shared"),
                    ])
                p(.class("note")) { "Each step scores one person with jaccardCoefficient(of:and:) and adamicAdarIndex(of:and:). Click anyone to suggest friends for them instead." }
            }
        }
    }
}

@View
struct LinkPredictionCodePanel {
    var body: some View {
        let model = linkPredictionModel
        let best = model.scores.max { $0.adamicAdar < $1.adamicAdar }?.candidate
        CodePanel(
            snippets: [
                .linkpredictionImports, .linkpredictionFriends,
                Snippet(lines: ["let person = \"\(model.person)\""]),
                .linkpredictionScores,
            ],
            results: [best.map { "\"\($0)\"" } ?? "nil"])
    }
}

enum LinkPredictionPage {
    static func mount() {
        mountView(LinkPredictionLab(), in: "app")
        mountView(LinkPredictionCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.adamic, Names.jaccard]), in: "names")
    }
}
