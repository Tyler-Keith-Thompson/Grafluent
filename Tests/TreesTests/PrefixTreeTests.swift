// prefixTree(of:): the prefix tree (trie) of some sequences as an Arborescence on 0..<n, each
// edge's symbol, and where each sequence ends. Expected values are worked by hand; the first
// example is NetworkX's prefix_tree documentation example ("ab", "abs", "ad").

import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Trees

@Suite("Prefix trees")
struct PrefixTreeTests {
    @Test("ab, abs, ad: a root, a below it, b and d below a, s below b")
    func example() {
        let trie = prefixTree(of: ["ab", "abs", "ad"])
        let tree = trie.arborescence
        #expect(tree.vertexCount == 5)
        #expect(tree.root == 0)
        #expect(Array(tree.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 1, to: 4)])
        #expect((0 ..< 4).map { trie.symbol(ofEdgeAt: $0) } == ["a", "b", "s", "d"])
        #expect(Array(tree.children(of: 1)) == [2, 4])
        #expect(trie.sequenceEnds == [2, 3, 4])
        #expect((0 ..< 5).map { trie.isSequenceEnd($0) } == [false, false, true, true, true])
    }

    @Test("No sequences: the root alone; an empty sequence ends at the root")
    func empty() {
        let none = prefixTree(of: [[Int]]())
        #expect(none.arborescence.vertexCount == 1)
        #expect(none.sequenceEnds.isEmpty)
        #expect(!none.isSequenceEnd(0))
        let blank = prefixTree(of: [""])
        #expect(blank.arborescence.vertexCount == 1)
        #expect(blank.sequenceEnds == [0])
        #expect(blank.isSequenceEnd(0))
    }

    @Test("Repeated sequences share their end; a sequence that is a prefix of another ends inside it")
    func repeats() {
        let trie = prefixTree(of: [[1, 2], [1, 2], [1], [2]])
        #expect(trie.arborescence.vertexCount == 4)
        #expect(trie.sequenceEnds == [2, 2, 1, 3])
        #expect(trie.arborescence.parent(of: 3) == 0)
        #expect(trie.symbol(ofEdgeAt: 2) == 2)
        #expect((0 ..< 4).map { trie.isSequenceEnd($0) } == [false, true, true, true])
    }

    @Test("The sequences are read once, from a single-pass sequence of lazy sequences")
    func singlePass() {
        var reads = 0
        let words = AnySequence { () -> AnyIterator<[Character]> in
            var source = ["to", "tea", "ten", "i", "in", "inn"].makeIterator()
            return AnyIterator {
                guard let word = source.next() else { return nil }
                reads += 1
                return Array(word)
            }
        }
        let trie = prefixTree(of: words)
        #expect(reads == 6)
        // The root and t, to, te, tea, ten, i, in, inn.
        #expect(trie.arborescence.vertexCount == 9)
        #expect(trie.sequenceEnds.count == 6)
    }

    @Test("Equal inputs give equal prefix trees; a different order numbers the vertices differently")
    func equality() {
        let a = prefixTree(of: ["ab", "b"]), b = prefixTree(of: ["ab", "b"]), c = prefixTree(of: ["b", "ab"])
        #expect(a == b && a.hashValue == b.hashValue)
        #expect(a != c)
        // The same tree and symbols, the ends in another order.
        let d = prefixTree(of: ["a", "ab"]), e = prefixTree(of: ["ab", "a"])
        #expect(d.arborescence == e.arborescence && d.symbol(ofEdgeAt: 1) == e.symbol(ofEdgeAt: 1))
        #expect(d != e)
    }

    @Test("The checked: spellings throw for a position or vertex outside the tree")
    func checked() throws {
        let trie = prefixTree(of: ["ab"])
        #expect(try trie.symbol(checkedEdgeAt: 1) == "b")
        #expect(throws: EdgeNotFound.self) { _ = try trie.symbol(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound.self) { _ = try trie.symbol(checkedEdgeAt: -1) }
        #expect(try trie.isSequenceEnd(checked: 2))
        #expect(throws: VertexNotFound.self) { _ = try trie.isSequenceEnd(checked: 3) }
        #expect(throws: VertexNotFound.self) { _ = try trie.isSequenceEnd(checked: -1) }
    }

    @Test("The plain spellings trap outside the tree", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            _ = prefixTree(of: ["ab"]).symbol(ofEdgeAt: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = prefixTree(of: ["ab"]).isSequenceEnd(3)
        }
    }

    @Test("Random words: one vertex per distinct prefix, each end spells its sequence, ends are exactly the words", .tags(.randomized))
    func randomWords() async {
        let words = Gen.int(in: 0 ... 2).array(of: 0 ... 5).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: words) { words in
            let trie = prefixTree(of: words)
            let tree = trie.arborescence
            var prefixes = Set<[Int]>([[]])
            for word in words { for k in 0 ... word.count { prefixes.insert(Array(word.prefix(k))) } }
            #expect(tree.vertexCount == prefixes.count)
            #expect(Array(tree.vertices) == Array(0 ..< prefixes.count))
            // Spell each vertex's prefix from the root.
            var spelled = [[Int]](repeating: [], count: tree.vertexCount)
            for v in 1 ..< max(tree.vertexCount, 1) {
                let p = tree.parent(of: v)!
                #expect(p < v)
                #expect(tree.parentEdge(of: v) == v - 1)
                spelled[v] = spelled[p] + [trie.symbol(ofEdgeAt: v - 1)]
            }
            #expect(Set(spelled) == prefixes)
            for (i, word) in words.enumerated() { #expect(spelled[trie.sequenceEnds[i]] == word) }
            let wordSet = Set(words)
            for v in 0 ..< tree.vertexCount { #expect(trie.isSequenceEnd(v) == wordSet.contains(spelled[v])) }
            // Siblings carry distinct symbols.
            for v in 0 ..< tree.vertexCount {
                let symbols = tree.children(of: v).map { trie.symbol(ofEdgeAt: $0 - 1) }
                #expect(Set(symbols).count == symbols.count)
            }
        }
    }
}
