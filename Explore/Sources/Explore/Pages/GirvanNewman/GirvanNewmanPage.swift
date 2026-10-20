import AdjacencyListModule
import CommunityDetection
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each friend and where they stand, in SVG units of the 660 × 470 view box.
let crowdSpots: [(name: String, x: Double, y: Double)] = [
    ("Abe", 60, 110), ("Bea", 170, 50), ("Cam", 160, 200), ("Dan", 270, 110),
    ("Ela", 400, 110), ("Fox", 500, 50), ("Gil", 500, 200), ("Hal", 600, 120),
    ("Ian", 450, 330), ("Jo", 360, 400), ("Kai", 270, 310), ("Lu", 230, 420),
]

let crowdIndex: [String: Int] = Dictionary(uniqueKeysWithValues: crowdSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The crowd after some removals: the links left with their betweenness, the groups, each
/// friend's group colour, and the modularity of the groups.
struct FriendState {
    var scores: [(link: UndirectedEdge<String>, score: Double)]
    var groups: [[String]]
    var colour: [Int]
    var modularity: Double
}

@Reactive
final class GirvanNewmanModel {
    var removed: [UndirectedEdge<String>] = []
    /// `states[k]` is after the first `k` removals.
    var states: [FriendState] = []
    var partitions: [[[String]]] = []
    var best: [[String]] = []
    /// Whether the groups at each split are the partitions girvanNewmanCommunities() lists.
    var agrees = false
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1000, scrubID: "scrub-girvannewman")

    init() {
        removed = friendRemovals()
        (partitions, best) = friendGroups()
        var colours = [Int](repeating: 0, count: crowdSpots.count)
        var next = 1
        states = (0 ... removed.count).map { k in
            let after = friendsAfter(removing: removed.prefix(k))
            // A group keeps the colour of the friend first in seat order; the other half of a
            // split takes a new one.
            var used = Set<Int>()
            for group in after.groups.sorted(by: { crowdIndex[$0[0]]! < crowdIndex[$1[0]]! }) {
                let members = group.map { crowdIndex[$0]! }.sorted()
                let old = colours[members[0]]
                let colour = used.contains(old) ? next : old
                if colour == next { next += 1 }
                used.insert(colour)
                for v in members { colours[v] = colour }
            }
            return FriendState(scores: after.scores, groups: after.groups, colour: colours, modularity: crowd.modularity(of: after.groups))
        }
        var splits: [[[String]]] = []
        for k in 1 ... removed.count where states[k].groups.count > states[k - 1].groups.count {
            splits.append(states[k].groups)
        }
        func same(_ a: [[String]], _ b: [[String]]) -> Bool {
            Set(a.map { Set($0) }) == Set(b.map { Set($0) })
        }
        agrees = splits.count == partitions.count && zip(splits, partitions).allSatisfy { same($0, $1) }
        playback.reset(count: removed.count)
    }

    /// The number of removals after which the modularity is greatest (the first, on a tie).
    var bestStep: Int {
        states.indices.max { (states[$0].modularity, -$0) < (states[$1].modularity, -$1) }!
    }
}

let girvanNewmanModel = GirvanNewmanModel()

func describeRemoval(_ k: Int, _ model: GirvanNewmanModel) -> String {
    let link = model.removed[k - 1]
    let before = model.states[k - 1], after = model.states[k]
    let score = before.scores.first { $0.link == link }!.score
    let head = "Take out \(link.u)–\(link.v), the busiest link left. \(shareText(score)) of the shortest paths cross it."
    if after.groups.count > before.groups.count {
        return head + " The network falls apart into \(after.groups.count) groups. Modularity is now \(signedTwoPlaces(after.modularity))."
    }
    return head + " Its two ends can still reach each other, so no group splits. Every score is worked out again."
}

@View
struct GirvanNewmanLab {
    var body: some View {
        let model = girvanNewmanModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.removed.count
        let state = model.states[k]
        let just = k > 0 ? model.removed[k - 1] : nil
        let gone = Set(model.removed.prefix(k))
        let score = Dictionary(uniqueKeysWithValues: state.scores.map { ($0.link, $0.score) })
        let busiestNext = state.scores.max { $0.score < $1.score }?.link
        let nodes = crowdSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)), radius: 16,
                       classes: "pal\(state.colour[v] % 8)", nameAbove: spot.y < 100)
        }
        let edges = hangOut.map { pair in
            CanvasEdge(from: crowdIndex[pair.u]!, to: crowdIndex[pair.v]!, label: score[pair].map(shareText) ?? "",
                       classes: pair == just ? "route" : gone.contains(pair) ? "faint" : pair == busiestNext ? "active" : "")
        }
        let bestStep = model.bestStep

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The crowd")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twelve friends, a line between each pair who hang out, coloured by group", width: 660, height: 470, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line route")) {}; "just taken out" }
                        span { i(.class("line active")) {}; "the busiest link now" }
                        span { i(.class("line faint")) {}; "taken out before" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Every link taken out" : k == 0 ? "\(model.removed.count) links to take out" : "Removal \(k) of \(model.removed.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "The number on each link is its edge betweenness. It counts the shortest paths between pairs of friends that cross the link. Links between groups carry the most. Press Step to take out the busiest."
                            } else if finished {
                                "Nobody is left connected. Of all the splits on the way, the one after removal \(bestStep) has the highest modularity, \(signedTwoPlaces(model.states[bestStep].modularity)). Its \(model.states[bestStep].groups.count) groups are the usual answer."
                            } else {
                                describeRemoval(k, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Groups now" }
                        div(.class("stat")) {
                            div {
                                span(.class("num")) { "\(state.groups.count)" }
                                state.groups.count == 1 ? "group" : "groups"
                            }
                            div(.class(k == bestStep ? "good" : "")) {
                                span(.class("num")) { signedTwoPlaces(state.modularity) }
                                k == bestStep ? "modularity, the best" : "modularity"
                            }
                        }
                        div(.class("chips")) {
                            for group in state.groups.sorted(by: { crowdIndex[$0[0]]! < crowdIndex[$1[0]]! }) where group.count > 1 {
                                span(.class("chip pal\(state.colour[crowdIndex[group[0]]!] % 8)")) { group.sorted { crowdIndex[$0]! < crowdIndex[$1]! }.joined(separator: " ") }
                            }
                        }
                        if finished {
                            p(.class("note")) {
                                model.agrees
                                    ? "Each split is one of the \(model.partitions.count) partitions girvanNewmanCommunities() lists, in the same order."
                                    : "These splits differ from girvanNewmanCommunities()."
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
                    marbles: (1 ... model.removed.count).map { j in
                        let title = describeRemoval(j, model)
                        let split = model.states[j].groups.count > model.states[j - 1].groups.count
                        if !split { return Marble(kind: "m-grey", radius: 5, title: title) }
                        return Marble(kind: j == bestStep ? "m-green" : "m-blue", radius: 11, letter: "\(model.states[j].groups.count)", title: title)
                    },
                    legend: [
                        (Marble(kind: "m-grey", radius: 4), "a link taken out, nothing splits"),
                        (Marble(kind: "m-blue", radius: 6), "a split, with the number of groups"),
                        (Marble(kind: "m-green", radius: 6), "the split with the best modularity"),
                    ])
                p(.class("note")) { "Each step is one removal. girvanNewmanCommunities() reports only the splits. To show the removals in between, the page makes them itself and recomputes edgeBetweennessCentrality each time." }
            }
        }
    }
}

@View
struct GirvanNewmanCodePanel {
    var body: some View {
        let model = girvanNewmanModel
        let k = model.playback.k
        let state = model.states[k]
        func groupsText(_ groups: [[String]]) -> String {
            "[" + groups.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
        }
        return CodePanel(
            snippets: [
                .girvannewmanImports, .girvannewmanCrowd, .girvannewmanPartitions, .girvannewmanRemove,
                Snippet(lines: ["let gone = removed.prefix(\(k))"]),
                .girvannewmanAfter,
            ],
            results: [
                "\(model.partitions.count) partitions",
                groupsText(model.best),
                groupsText(state.groups),
            ])
    }
}

enum GirvanNewmanPage {
    static func mount() {
        mountView(GirvanNewmanLab(), in: "app")
        mountView(GirvanNewmanCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.louvain]), in: "names")
    }
}

