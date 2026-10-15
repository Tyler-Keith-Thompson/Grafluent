// snippet: huffman-imports
import Trees
// snippet end

// The Huffman coding page's code. The marked regions are its code panel.

/// The letters of `text`, most common first (ties in alphabetical order), with their counts.
func huffmanLetters(_ text: String) -> (letters: [Character], counts: [Character: Int]) {
    // snippet: huffman-count
    var counts: [Character: Int] = [:]
    for letter in text { counts[letter, default: 0] += 1 }
    let letters = counts.keys.sorted { (counts[$1]!, $0) < (counts[$0]!, $1) }
    // snippet end
    return (letters, counts)
}

/// The Huffman tree of the letters' counts: leaf `i` is `letters[i]`.
func huffmanTree(_ letters: [Character], _ counts: [Character: Int]) -> BinaryTree<Int> {
    // snippet: huffman-tree
    let tree = BinaryTree<Int>.huffman(weights: letters.map { counts[$0]! })
    let size = tree.vertexCount  // →
    // snippet end
    _ = size
    return tree
}

/// Each letter's code word, read down the tree, and the length of the coded text against 8 bits
/// a letter.
func huffmanCodes(_ text: String, _ letters: [Character], _ tree: BinaryTree<Int>) -> (codes: [Character: String], bits: Int, plain: Int) {
    // snippet: huffman-codes
    var codes: [Character: String] = [:]
    for (leaf, letter) in letters.enumerated() {
        var word = "", v = leaf
        while let parent = tree.parent(of: v) {
            word = (tree.left(of: parent) == v ? "0" : "1") + word
            v = parent
        }
        codes[letter] = word.isEmpty ? "0" : word
    }
    let bits = text.reduce(0) { $0 + codes[$1]!.count }  // →
    let plain = 8 * text.count                            // →
    // snippet end
    return (codes, bits, plain)
}
