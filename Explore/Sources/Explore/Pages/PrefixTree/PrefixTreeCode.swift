// snippet: prefixtree-imports
import GraphProtocols
import Trees
// snippet end

// The word list of the prefix tree page and the questions it asks. The marked regions are its
// code panel.

let wordList = ["car", "card", "care", "cart", "cat", "do", "dog", "dot", "dove"]

/// The prefix tree of the first `added` words, the vertex the letters of `typed` lead to (or
/// nil when no word starts that way), and the words that start with `typed`.
func autocomplete(added: Int, typed: String) -> (tree: PrefixTree<Character>, node: Int?, suggestions: [String]) {
    let words = wordList
    // snippet: prefixtree-build
    let tree = prefixTree(of: words.prefix(added))
    // snippet end
    // snippet: prefixtree-complete
    var node: Int? = 0
    for letter in typed {
        node = node.flatMap { at in
            tree.arborescence.children(of: at).first { tree.symbol(ofEdgeAt: $0 - 1) == letter }
        }
    }
    let ends = node.map { at in
        tree.arborescence.preorder.filter { tree.isSequenceEnd($0) && ($0 == at || tree.arborescence.isAncestor(at, of: $0)) }
    } ?? []
    let suggestions = ends.map { words[tree.sequenceEnds.firstIndex(of: $0)!] }        // →
    // snippet end
    return (tree, node, suggestions)
}
