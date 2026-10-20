import AdjacencyListModule
import CommunityDetection
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each person and where they sit, in SVG units of the 640 × 470 view box: teams in tight knots,
/// the two teams of a department side by side.
let companySpots: [(name: String, x: Double, y: Double)] = {
    let teamCentres: [(Double, Double)] = [(95, 95), (215, 95), (95, 375), (215, 375), (470, 95), (560, 335)]
    let offsets: [(Double, Double)] = [(-26, -26), (26, -26), (-26, 26), (26, 26)]
    var spots: [(String, Double, Double)] = []
    for (team, centre) in zip(companyTeams, teamCentres) {
        for (person, offset) in zip(team, offsets) { spots.append((person, centre.0 + offset.0, centre.1 + offset.1)) }
    }
    return spots
}()

/// The index in `companySpots` of each person.
let companyIndex: [String: Int] = Dictionary(uniqueKeysWithValues: companySpots.enumerated().map { ($0.element.name, $0.offset) })

/// The two ends of each working pair, as offsets in `companySpots`, by position in `company`.
let companyEnds: [(Int, Int)] = company.edges.map { (companyIndex[$0.u]!, companyIndex[$0.v]!) }

/// The hierarchy page's state: the cap, the hierarchy it gives, and the playback over its levels.
@Reactive
final class HierarchyModel {
    var cap = 6
    @ReactiveIgnored var tree = companyHierarchy(cap: 6)
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1500, scrubID: "scrub-hierarchy")

    init() {
        playback.reset(count: tree.levelCount)
    }

    func choose(cap: Int) {
        self.cap = cap
        tree = companyHierarchy(cap: cap)
        playback.reset(count: tree.levelCount)
        setProperty(id: "hierarchy-cap", "value", to: "\(cap)")
    }
}

let hierarchyModel = HierarchyModel()

/// `[[Ada, Bo], …]`.
func companyGroupList(_ groups: [[String]]) -> String { "[" + groups.map { "[" + $0.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]" }

/// Each community of `level` numbered from 0, for its colour.
func companyColours<G: DirectedGraph>(_ tree: CommunityHierarchy<G>, _ level: Int) -> [Int: Int] {
    var map = [Int: Int]()
    for (i, c) in tree.communities(atLevel: level).enumerated() { map[c] = i }
    return map
}

/// The community each person is in at `level`: the deepest community at or above that level.
func communityAtLevel<G: DirectedGraph>(_ tree: CommunityHierarchy<G>, _ level: Int, of vertex: G.Vertex) -> Int {
    var c = tree.community(of: vertex)
    while tree.level(of: c) > level, let p = tree.parent(of: c) { c = p }
    return c
}

/// The sentence for one level.
func describeLevel<G: DirectedGraph>(_ tree: CommunityHierarchy<G>, _ level: Int, cap: Int) -> String {
    let range = tree.communities(atLevel: level)
    let sizes = range.map { tree[$0].count }
    let over = range.filter { tree[$0].count > cap }
    let split = over.filter { !tree.children(of: $0).isEmpty }
    var text = level == 0
        ? "Level 0: Leiden on the whole company finds \(range.count) communities, of \(nameList(sizes.map { "\($0)" })) people."
        : "Level \(level): \(range.count) communities, of \(nameList(sizes.map { "\($0)" })) people, split from the ones over the cap."
    if over.isEmpty {
        text += " None is over the cap of \(cap), so this is the last level."
    } else if split.isEmpty {
        text += " \(over.count) \(over.count == 1 ? "is" : "are") over the cap, but Leiden keeps \(over.count == 1 ? "it" : "them") in one piece, so \(over.count == 1 ? "it stays" : "they stay") final."
    } else {
        text += " \(split.count) of them \(split.count == 1 ? "is" : "are") over the cap of \(cap) and \(split.count == 1 ? "gets" : "get") clustered again on \(split.count == 1 ? "its" : "their") own."
    }
    return text
}

/// The company coloured by the communities of one level.
@View
struct HierarchyLab {
    var body: some View {
        let model = hierarchyModel
        let playback = model.playback
        let tree = model.tree
        let k = playback.k
        let level = max(0, k - 1)
        let shown = k > 0
        let colourOf = companyColours(tree, level)
        let community = companySpots.map { shown ? communityAtLevel(tree, level, of: $0.name) : -1 }
        let nodes = companySpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 13,
                       classes: shown ? "pal\((colourOf[community[v]] ?? 0) % 8)" : "")
        }
        let edges = companyEnds.map { ends in
            CanvasEdge(from: ends.0, to: ends.1, classes: shown && community[ends.0] != community[ends.1] ? "faint" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The company's community hierarchy")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twenty-four people in six teams, coloured by the community of the level shown", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal0")) {}; "one community of this level" }
                        span { i(.class("line faint")) {}; "a pair across communities" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { shown ? "Level \(level) of \(tree.levelCount - 1)" : "Before we start" }
                        p(.class("narration")) {
                            if !shown {
                                "Leiden finds communities. Any community with more than \(model.cap) people is clustered again on its own, and so on, until every community fits or will not split. Press Step to see each level."
                            } else {
                                describeLevel(tree, level, cap: model.cap)
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("hierarchy-cap")) {
                                "Cap: at most "
                                select(.id("hierarchy-cap")) {
                                    for n in [3, 4, 6, 8, 12, 24] {
                                        option(.value("\(n)")) { "\(n)" }.attributes(.selected, when: model.cap == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { hierarchyModel.choose(cap: n) }
                                }
                                " people"
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The tree so far" }
                        div(.class("queue")) {
                            if !shown { p(.class("empty")) { "None yet" } }
                            for l in 0 ..< (shown ? level + 1 : 0) {
                                for c in tree.communities(atLevel: l) {
                                    div(.class(l == level ? "qrow top" : "qrow plain")) {
                                        span { String(repeating: "· ", count: l) + nameList(Array(tree[c])) }
                                        span(.class("num")) { tree.children(of: c).isEmpty ? "final" : "splits" }
                                    }
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
                    marbles: (0 ..< tree.levelCount).map { l in
                        Marble(kind: "m-pal\(l % 8)", radius: 6 + Double(tree.communities(atLevel: l).count), letter: "\(tree.communities(atLevel: l).count)",
                               title: describeLevel(tree, l, cap: model.cap))
                    },
                    legend: [(Marble(kind: "m-pal1", radius: 8), "one level, with its number of communities")])
                p(.class("note")) { "hierarchicalLeidenCommunities(maximumCommunitySize:) computes every level at once. Each step shows one." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct HierarchyCodePanel {
    var body: some View {
        let model = hierarchyModel
        let tree = model.tree
        let list = companyGroupList
        let parent = tree.parent(of: tree.community(of: "Ada")).map { "Optional(\($0))" } ?? "nil"
        CodePanel(snippets: [.hierarchyImports, .hierarchyCompany, Snippet(lines: ["let cap = \(model.cap)"]), .hierarchyLeiden],
                  results: ["\(tree.levelCount)", list(tree.communities(atLevel: 0).map { Array(tree[$0]) }), list(tree.leaves.map { Array(tree[$0]) }), parent])
    }
}

enum HierarchyPage {
    static func mount() {
        mountView(HierarchyLab(), in: "app")
        mountView(HierarchyCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.leiden, Names.louvain]), in: "names")
    }
}
