// snippet: dominators-imports
import AdjacencyListModule
import Connectivity
import GraphProtocols
import Traversal
// snippet end

// A small function's control flow and the calls the dominators page makes. The marked regions
// are its code panels.

// snippet: dominators-program
// Each block of the function, and where it can jump next.
let jumps = [
    DirectedEdge(from: "entry", to: "loop"),
    DirectedEdge(from: "loop", to: "check"),    // another line to read
    DirectedEdge(from: "loop", to: "done"),     // no more lines
    DirectedEdge(from: "check", to: "add"),     // the line is a number
    DirectedEdge(from: "check", to: "warn"),    // it isn’t
    DirectedEdge(from: "add", to: "next"),
    DirectedEdge(from: "warn", to: "next"),
    DirectedEdge(from: "warn", to: "give up"),  // too many bad lines
    DirectedEdge(from: "next", to: "loop"),
    DirectedEdge(from: "done", to: "exit"),
    DirectedEdge(from: "give up", to: "exit"),
]

let program = AdjacencyList<String> {
    for jump in jumps { jump }
}
// snippet end

typealias ProgramTree = DominatorTree<AdjacencyList<String>>

/// The dominator tree from the entry.
func programDominators() -> ProgramTree {
    // snippet: dominators-tree
    let tree = program.dominatorTree(root: "entry")
    // snippet end
    return tree
}

/// The post-dominator tree to the exit.
func programPostDominators() -> ProgramTree {
    // snippet: dominators-post-tree
    let tree = program.postDominatorTree(exit: "exit")
    // snippet end
    return tree
}

/// What the tree says about `block`: the chain up to the root, its parent, and its children.
func treeFacts(_ tree: ProgramTree, block: String) -> (chain: [String]?, parent: String?, below: [String]) {
    // snippet: dominators-ask
    let chain = tree.dominators(of: block)           // →
    let parent = tree.immediateDominator(of: block)  // →
    let below = Array(tree.children(of: block))      // →
    // snippet end
    return (chain, parent, below)
}

/// The blocks the entry no longer reaches once `block` is taken out: `block` itself and every
/// block it dominates.
func cutOff(closing block: String) -> [String] {
    // snippet: dominators-close
    var closed = program
    closed.remove(block)
    var reached: [String] = []
    for case .discover(let v) in closed.lazy.breadthFirstSearch(from: "entry") {
        reached.append(v)
    }
    let cutOff = program.vertices.filter { !reached.contains($0) }  // →
    // snippet end
    return cutOff
}
