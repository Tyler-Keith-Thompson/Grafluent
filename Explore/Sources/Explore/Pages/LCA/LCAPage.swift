import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import Reactivity
import TreeAlgorithms
import Trees

/// Each person and where they sit in the family tree, in SVG units of the 660 × 420 view box,
/// a generation to a row.
let familySpots: [(name: String, x: Double, y: Double)] = [
    ("Rose", 360, 45),
    ("Arthur", 200, 125), ("Beth", 520, 125),
    ("Clara", 120, 205), ("David", 280, 205), ("Ellen", 520, 205),
    ("Finn", 60, 285), ("Gemma", 170, 285), ("Harry", 280, 285), ("Iris", 470, 285), ("Jack", 590, 285),
    ("Kate", 170, 365), ("Leo", 470, 365),
]

let familyIndex: [String: Int] = Dictionary(uniqueKeysWithValues: familySpots.enumerated().map { ($0.element.name, $0.offset) })

@Reactive
final class LCAModel {
    var first = "Kate"
    var second = "Leo"
    var climb: [(String, String)] = []
    var ancestor = "Rose"
    var apart = 0
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1000, scrubID: "scrub-lca")

    init() {
        run()
    }

    func run() {
        (climb, ancestor, apart) = familyClimb(first, second)
        playback.reset(count: climb.count - 1)
        setProperty(id: "lca-first", "value", to: first)
        setProperty(id: "lca-second", "value", to: second)
    }

    func choose(first: String? = nil, second: String? = nil) {
        if let first { self.first = first }
        if let second { self.second = second }
        run()
    }
}

let lcaModel = LCAModel()

/// `great-great-grandparent` and the like: `greats` times "great-", then the word.
func greats(_ n: Int, _ word: String) -> String { String(repeating: "great-", count: max(n, 0)) + word }

/// What `a` is to `b`, from how many generations each is below their lowest common ancestor.
func relationship(_ a: String, _ b: String, up: Int, down: Int) -> String {
    switch (up, down) {
    case (0, 0): return "\(a) is \(b)"
    case (0, _): return "\(a) is \(b)’s " + (down == 1 ? "parent" : greats(down - 2, "grandparent"))
    case (_, 0): return "\(a) is \(b)’s " + (up == 1 ? "child" : greats(up - 2, "grandchild"))
    case (1, 1): return "\(a) and \(b) are siblings"
    case (1, _): return "\(a) is \(b)’s " + greats(down - 2, "aunt or uncle")
    case (_, 1): return "\(a) is \(b)’s " + greats(up - 2, "niece or nephew")
    default:
        let degree = min(up, down) - 1, removed = abs(up - down)
        let ordinal = ["first", "second", "third", "fourth", "fifth"][min(degree, 5) - 1]
        let times = removed == 0 ? "" : removed == 1 ? " once removed" : removed == 2 ? " twice removed" : " \(removed) times removed"
        return "\(a) and \(b) are \(ordinal) cousins" + times
    }
}

func describeClimb(_ k: Int, _ model: LCAModel) -> String {
    let (px, py) = model.climb[k - 1], (x, y) = model.climb[k]
    let moved = [px != x ? "\(px) up to \(x)" : nil, py != y ? "\(py) up to \(y)" : nil].compactMap { $0 }
    let why = moved.count == 2 ? "Both are in the same generation, so both step up: " : "\(px != x ? px : py) is a generation lower, so only that side steps up: "
    let head = why + moved.joined(separator: " and ") + "."
    return x == y ? head + " They meet at \(x): the lowest common ancestor." : head
}

@View
struct LCALab {
    var body: some View {
        let model = lcaModel
        let playback = model.playback
        let k = playback.k
        let finished = k == model.climb.count - 1
        let (x, y) = model.climb[k]
        let pathA = Set(model.climb.prefix(k + 1).map(\.0)), pathB = Set(model.climb.prefix(k + 1).map(\.1))
        let up = family.depth(of: model.first) - family.depth(of: model.ancestor)
        let down = family.depth(of: model.second) - family.depth(of: model.ancestor)
        let nodes = familySpots.map { spot in
            let name = spot.name
            return CanvasNode(x: spot.x, y: spot.y, name: name, badge: String(name.prefix(1)), radius: 17,
                              classes: (finished && name == model.ancestor ? "cut" : pathA.contains(name) && pathB.contains(name) ? "visited" : pathA.contains(name) ? "pal1" : pathB.contains(name) ? "pal2" : "")
                                  + (name == x || name == y ? " current" : ""),
                              nameAbove: false)
        }
        let edges = childOf.map { link -> CanvasEdge in
            let a = pathA.contains(link.child) && pathA.contains(link.parent) && link.child != x
            let b = pathB.contains(link.child) && pathB.contains(link.parent) && link.child != y
            return CanvasEdge(from: familyIndex[link.parent]!, to: familyIndex[link.child]!, classes: a ? "pal1" : b ? "pal2" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The family tree")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A family tree over five generations, from Rose at the top", width: 660, height: 420, nodes: nodes, edges: edges,
                                onNode: { lcaModel.choose(second: familySpots[$0].name) }, nodeAction: "Compare with")
                    div(.class("legend")) {
                        span { i(.class("dot pal1")) {}; "\(model.first)’s climb" }
                        span { i(.class("dot pal2")) {}; "\(model.second)’s climb" }
                        span { i(.class("dot cut")) {}; "where they meet" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Found" : k == 0 ? "\(model.climb.count - 1) steps to climb" : "Step \(k) of \(model.climb.count - 1)" }
                        p(.class("narration")) {
                            if model.climb.count == 1 {
                                "Pick two different people."
                            } else if k == 0 {
                                "Who is the most recent ancestor \(model.first) and \(model.second) share? Climb from both: whoever is in a later generation steps up to their parent, and once they are level, both step up together, until they stand on the same person. Press Step."
                            } else {
                                describeClimb(k, model)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The answer" }
                        div(.class("stat")) {
                            div(.class(finished ? "good" : "")) {
                                span(.class("num")) { finished ? model.ancestor : "?" }
                                "lowest common ancestor"
                            }
                            div {
                                span(.class("num")) { finished ? "\(model.apart)" : "?" }
                                "links apart"
                            }
                        }
                        if finished {
                            p(.class("narration")) { relationship(model.first, model.second, up: up, down: down) + "." }
                            p(.class("note")) { "\(model.first) is \(up) and \(model.second) \(down) generations below \(model.ancestor); those two numbers name the relationship, and add up to the links between them." }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    label(.class("field"), .for("lca-first")) {
                        "From "
                        select(.id("lca-first")) {
                            for spot in familySpots {
                                option(.value(spot.name)) { spot.name }.attributes(.selected, when: spot.name == model.first)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue { lcaModel.choose(first: value) }
                        }
                    }
                    label(.class("field"), .for("lca-second")) {
                        "and "
                        select(.id("lca-second")) {
                            for spot in familySpots {
                                option(.value(spot.name)) { spot.name }.attributes(.selected, when: spot.name == model.second)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue { lcaModel.choose(second: value) }
                        }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ..< max(model.climb.count, 1)).map { j in
                        let (px, py) = model.climb[j - 1], (x, y) = model.climb[j]
                        let title = describeClimb(j, model)
                        if x == y { return Marble(kind: "m-red", radius: 11, letter: String(x.prefix(1)), title: title) }
                        return px != x && py != y ? Marble(kind: "m-violet", radius: 8, title: title) : Marble(kind: px != x ? "m-pal1" : "m-pal2", radius: 8, title: title)
                    },
                    legend: [
                        (Marble(kind: "m-pal1", radius: 6), "\(model.first)’s side steps up"),
                        (Marble(kind: "m-pal2", radius: 6), "\(model.second)’s side steps up"),
                        (Marble(kind: "m-violet", radius: 6), "both step up"),
                        (Marble(kind: "m-red", radius: 6), "they meet"),
                    ])
                p(.class("note")) { "The steps are the climb in the code, with depth(of:) and parent(of:); lowestCommonAncestor(of:_:) gives the same person directly. Click anyone in the tree to compare with them." }
            }
        }
    }
}

@View
struct LCACodePanel {
    var body: some View {
        let model = lcaModel
        CodePanel(
            snippets: [
                .lcaImports, .lcaFamily,
                Snippet(lines: ["let a = \"\(model.first)\"", "let b = \"\(model.second)\""]),
                .lcaClimb, .lcaAnswer,
            ],
            results: ["\"\(model.ancestor)\"", "\(model.apart)"])
    }
}

enum LCAPage {
    static func mount() {
        mountView(LCALab(), in: "app")
        mountView(LCACodePanel(), in: "code")
    }
}
