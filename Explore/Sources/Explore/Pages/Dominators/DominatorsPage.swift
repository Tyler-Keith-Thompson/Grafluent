import AdjacencyListModule
import Connectivity
import ElementaryUI
import GraphProtocols
import Reactivity

/// Each block of the function and where it sits, in SVG units of the 640 × 500 view box.
let programBlocks: [(name: String, x: Double, y: Double)] = [
    ("entry", 110, 40), ("loop", 110, 140), ("check", 300, 220), ("add", 210, 325), ("warn", 410, 325),
    ("next", 300, 430), ("give up", 490, 430), ("done", 560, 140), ("exit", 590, 470),
]

/// The index in `programBlocks` of each block's name.
let programIndex: [String: Int] = Dictionary(uniqueKeysWithValues: programBlocks.enumerated().map { ($0.element.name, $0.offset) })

/// The jumps, as offsets in `programBlocks`, in `program`'s edge order.
let programJumps: [(from: Int, to: Int)] = program.edges.map { (programIndex[$0.source]!, programIndex[$0.target]!) }

/// `entry, loop and check`.
func blockList(_ names: [String]) -> String {
    names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// Where each block of `tree` sits in a drawing of the tree in a `width` × `height` view box:
/// leaves spread evenly in depth-first order, each parent centred over its children, a row per
/// depth. Blocks not in the tree are not placed.
func treeSpots(_ tree: ProgramTree, width: Double, height: Double) -> [Int: (x: Double, y: Double)] {
    var depth: [Int: Int] = [:]
    var leaves: [Int] = []
    var order: [Int] = []
    func walk(_ block: String, _ d: Int) {
        let v = programIndex[block]!
        depth[v] = d
        order.append(v)
        let below = tree.children(of: block)
        if below.isEmpty { leaves.append(v) }
        for child in below { walk(child, d + 1) }
    }
    walk(tree.root, 0)
    let rows = (depth.values.max() ?? 0) + 1
    var x: [Int: Double] = [:]
    let gap = leaves.count > 1 ? (width - 60) / Double(leaves.count - 1) : 0
    for (i, leaf) in leaves.enumerated() { x[leaf] = 30 + Double(i) * gap }
    for v in order.reversed() where x[v] == nil {
        let below = tree.children(of: programBlocks[v].name).map { x[programIndex[$0]!]! }
        x[v] = below.reduce(0, +) / Double(below.count)
    }
    let rowGap = rows > 1 ? (height - 70) / Double(rows - 1) : 0
    var spots: [Int: (x: Double, y: Double)] = [:]
    for v in order { spots[v] = (x[v]!, 30 + Double(depth[v]!) * rowGap) }
    return spots
}

/// One step of the closing-off check: a block taken out, and the blocks the entry no longer
/// reaches, the block itself among them, as offsets in `programBlocks`.
struct ClosingStep {
    var block: Int
    var cutOff: [Int]
}

/// The dominators page's state: which tree, the block asked about, the closing-off steps, and
/// their playhead.
@Reactive
final class DominatorsModel {
    /// 0 for the dominator tree from the entry, 1 for the post-dominator tree to the exit.
    var mode = 0
    var selected = programIndex["exit"]!
    @ReactiveIgnored let dominatorTree = programDominators()
    @ReactiveIgnored let postDominatorTree = programPostDominators()
    @ReactiveIgnored let steps: [ClosingStep]
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1100, scrubID: "scrub-closing")

    init() {
        steps = programBlocks.indices.dropFirst().map { v in
            ClosingStep(block: v, cutOff: cutOff(closing: programBlocks[v].name).map { programIndex[$0]! })
        }
        playback.reset(count: steps.count)
    }

    var tree: ProgramTree { mode == 0 ? dominatorTree : postDominatorTree }

    func select(_ block: Int) { selected = block }

    func choose(mode: Int) {
        self.mode = mode
        setProperty(id: "dominators-mode", "value", to: "\(mode)")
    }

    /// Each block's dominators after the first `k` steps: the entry, and every block closed so
    /// far that cut it off, in block order.
    func found(after k: Int) -> [[Int]] {
        programBlocks.indices.map { b in
            [0] + steps.prefix(k).filter { $0.cutOff.contains(b) }.map(\.block)
        }
    }
}

let dominatorsModel = DominatorsModel()

/// The function's flow with the chosen block's dominators lit, and the tree beside it.
@View
struct DominatorsLab {
    var body: some View {
        let model = dominatorsModel
        let tree = model.tree
        let block = programBlocks[model.selected].name
        let chain = tree.dominators(of: block) ?? []
        let chainSet = Set(chain.map { programIndex[$0]! })
        let parent = tree.immediateDominator(of: block)
        let post = model.mode == 1
        let nodes = programBlocks.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, radius: 18,
                classes: (v == model.selected ? "visited selected" : chainSet.contains(v) ? "frontier" : "")
                    + (v == (post ? programIndex["exit"]! : 0) ? " source" : ""))
        }
        let edges = programJumps.enumerated().map { j, jump in
            CanvasEdge(from: jump.from, to: jump.to, directed: true, bend: j == 8 ? -60 : 0)
        }
        let spots = treeSpots(tree, width: 420, height: 330)
        let treeOrder = programBlocks.indices.filter { spots[$0] != nil }
        let treeNodes = treeOrder.map { v in
            CanvasNode(
                x: spots[v]!.x, y: spots[v]!.y, name: programBlocks[v].name, radius: 13,
                classes: v == model.selected ? "visited selected" : chainSet.contains(v) ? "frontier" : "")
        }
        let treeEdges: [CanvasEdge] = treeOrder.compactMap { v in
            guard let up = tree.immediateDominator(of: programBlocks[v].name) else { return nil }
            let u = programIndex[up]!
            let onChain = chainSet.contains(v) && chainSet.contains(u)
            return CanvasEdge(from: treeOrder.firstIndex(of: u)!, to: treeOrder.firstIndex(of: v)!, directed: true, classes: onChain ? "route" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Dominators of a block")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A function’s control flow: nine blocks and the jumps between them; click a block to see what dominates it", width: 640, height: 500,
                                nodes: nodes, edges: edges, onNode: { dominatorsModel.select($0) }, nodeAction: "Ask about")
                    div(.class("legend")) {
                        span { i(.class("dot selected")) {}; "the block asked about" }
                        span { i(.class("dot frontier")) {}; post ? "every path from it to the exit passes here" : "every path from the entry to it passes here" }
                    }
                    p(.class("note")) { "Click any block, here or in the tree." }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { post ? "Post-dominators of \(block)" : "Dominators of \(block)" }
                        p(.class("narration")) {
                            if post {
                                if chain.count <= 1 {
                                    "\(block) is the exit. Every path ends here, so it post-dominates every block that can reach it."
                                } else {
                                    "Every path from \(block) to the exit runs through "
                                    em { blockList(chain.dropFirst().map { $0 }) }
                                    ". The nearest, \(parent!), is its immediate post-dominator. Once \(block) runs, \(parent!) is sure to run after it."
                                }
                            } else if chain.count <= 1 {
                                "\(block) is the entry. Every block is reached through it, so it dominates them all."
                            } else {
                                "Every path from the entry to \(block) runs through "
                                em { blockList(chain.dropFirst().reversed().map { $0 }) }
                                ". The nearest, \(parent!), is its immediate dominator and its parent in the tree."
                                if block == "exit" { " The exit can be reached through done or through give up, so neither one is unavoidable." }
                                if block == "next" { " Next can be reached through add or through warn, so neither one is unavoidable." }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { post ? "Post-dominator tree, from the exit" : "Dominator tree, from the entry" }
                        GraphCanvas(label: post ? "The post-dominator tree: each block under its immediate post-dominator" : "The dominator tree: each block under its immediate dominator",
                                    width: 420, height: 330, nodes: treeNodes, edges: treeEdges,
                                    onNode: { dominatorsModel.select(treeOrder[$0]) }, nodeAction: "Ask about")
                        p(.class("note")) { post ? "A block’s ancestors are what must run after it." : "A block’s ancestors are what must run before it." }
                    }
                    div(.class("panel")) {
                        label(.class("field"), .for("dominators-mode")) {
                            "Ask "
                            select(.id("dominators-mode")) {
                                option(.value("0")) { "what must run before" }.attributes(.selected, when: model.mode == 0)
                                option(.value("1")) { "what must run after" }.attributes(.selected, when: model.mode == 1)
                            }
                            .onInput { event in
                                if let value = event.targetValue, let n = Int(value) { dominatorsModel.choose(mode: n) }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The lab's code panel: the program, the tree, and what it says about the chosen block.
@View
struct DominatorsCodePanel {
    var body: some View {
        let model = dominatorsModel
        let block = programBlocks[model.selected].name
        let facts = treeFacts(model.tree, block: block)
        CodePanel(
            snippets: [
                .dominatorsImports, .dominatorsProgram, model.mode == 0 ? .dominatorsTree : .dominatorsPostTree,
                Snippet(lines: ["let block = \"\(block)\""]), .dominatorsAsk,
            ],
            results: [
                facts.chain.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ", ") + "]" } ?? "nil",
                facts.parent.map { "\"\($0)\"" } ?? "nil",
                "[" + facts.below.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
            ])
    }
}

/// The sentence for one step of the closing-off check.
func describeClosing(_ step: ClosingStep) -> String {
    let name = programBlocks[step.block].name
    let others = step.cutOff.filter { $0 != step.block }.map { programBlocks[$0].name }
    return others.isEmpty
        ? "Take out \(name). Everything else is still reachable from the entry, so \(name) dominates only itself."
        : "Take out \(name). The entry can no longer reach \(blockList(others)). Every path to \(others.count == 1 ? "it" : "them") ran through \(name), so \(name) dominates \(others.count == 1 ? "it" : "them")."
}

/// The check by definition: take out each block in turn and see what the entry stops reaching.
@View
struct ClosingLab {
    var body: some View {
        let model = dominatorsModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let last = k > 0 ? steps[k - 1] : nil
        let found = model.found(after: k)
        let finished = k == steps.count
        let tree = model.dominatorTree
        let agrees = programBlocks.indices.allSatisfy { b in
            Set(found[b].map { programBlocks[$0].name }) == Set(tree.dominators(of: programBlocks[b].name) ?? [])
        }
        let nodes = programBlocks.enumerated().map { v, spot in
            CanvasNode(
                x: spot.x, y: spot.y, name: spot.name, radius: 18,
                classes: last?.block == v ? "closed" : last?.cutOff.contains(v) == true ? "cut" : last != nil ? "visited" : "")
        }
        let edges = programJumps.enumerated().map { j, jump in
            let gone = last.map { jump.from == $0.block || jump.to == $0.block } ?? false
            return CanvasEdge(from: jump.from, to: jump.to, directed: true, classes: gone ? "faint" : "", bend: j == 8 ? -60 : 0)
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Take out one block at a time")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The same function, with one block taken out and the blocks the entry no longer reaches marked", width: 640, height: 500,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot visited")) {}; "still reached from the entry" }
                        span { i(.class("dot cut")) {}; "cut off: the block taken out dominates it" }
                        span { i(.class("line faint")) {}; "jumps into or out of the block taken out" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Done after \(steps.count) blocks" : "Block \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                "Take each block out in turn and search from the entry. Whatever the entry no longer reaches, that block dominates. Press Step to begin."
                            } else if finished {
                                describeClosing(last!) + " Every block has been taken out once."
                                agrees
                                    ? " The lists agree with program.dominatorTree(root: \"entry\")."
                                    : " The lists disagree with program.dominatorTree(root: \"entry\")."
                            } else {
                                describeClosing(last!)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Dominators found so far" }
                        div(.class("queue")) {
                            for (b, spot) in programBlocks.enumerated() {
                                div(.class(last?.cutOff.contains(b) == true ? "qrow top" : "qrow plain")) {
                                    span { spot.name }
                                    span(.class("num")) { found[b].map { programBlocks[$0].name }.joined(separator: ", ") }
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
                    marbles: steps.map { step in
                        let others = step.cutOff.count - 1
                        return others > 0
                            ? Marble(kind: "m-red", radius: 5 + Double(others), letter: "\(others)", title: describeClosing(step))
                            : Marble(kind: "m-hollow", radius: 6, title: describeClosing(step))
                    },
                    legend: [
                        (Marble(kind: "m-red", radius: 7), "a block taken out cuts others off, with how many"),
                        (Marble(kind: "m-hollow", radius: 6), "it cuts off nothing else"),
                    ])
                p(.class("note")) { "This timeline is the definition, checked by the page: each step removes one block and runs lazy.breadthFirstSearch(from:) from the entry. dominatorTree(root:) reaches the same answer in one pass and reports no steps." }
            }
        }
    }
}

/// The closing-off check's code panel, for the block the playhead last took out.
@View
struct ClosingCodePanel {
    var body: some View {
        let model = dominatorsModel
        let k = model.playback.k
        let step = model.steps[max(0, k - 1)]
        CodePanel(
            snippets: [.dominatorsImports, .dominatorsProgram, Snippet(lines: ["let block = \"\(programBlocks[step.block].name)\""]), .dominatorsClose],
            results: ["[" + step.cutOff.map { "\"\(programBlocks[$0].name)\"" }.joined(separator: ", ") + "]"])
    }
}

enum DominatorsPage {
    static func mount() {
        mountView(DominatorsLab(), in: "app")
        mountView(DominatorsCodePanel(), in: "code")
        mountView(ClosingLab(), in: "closing")
        mountView(ClosingCodePanel(), in: "code-closing")
        mountView(NamesStrip(names: [Names.lengauer]), in: "names")
    }
}
