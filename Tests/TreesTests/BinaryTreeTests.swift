// BinaryTree: positional left and right children, the three traversals, equality by position,
// the O(1) conversions to OrderedTree and Arborescence, the checked: lookups, every binary tree
// on n vertices (Knuth's Algorithm B) and Huffman trees. Expected values are worked by hand from
// the trees drawn in each test; the Huffman example is the classic six-letter one (5, 9, 12, 13,
// 16, 45), whose code words are 1100, 1101, 100, 101, 111 and 0.

import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Trees

@Suite("BinaryTree")
struct BinaryTreeTests {
    @Test("Left and right children, depth, and the three traversals of 4(2(1, 3), 6(_, 7))")
    func traversals() throws {
        let links: [Int: (Int?, Int?)] = [4: (2, 6), 2: (1, 3), 6: (nil, 7)]
        let tree = try #require(BinaryTree(root: 4) { links[$0] ?? (nil, nil) })
        #expect(tree.root == 4)
        #expect(tree.vertexCount == 6)
        #expect(tree.left(of: 4) == 2 && tree.right(of: 4) == 6)
        #expect(tree.left(of: 6) == nil && tree.right(of: 6) == 7)
        #expect(tree.left(of: 1) == nil && tree.right(of: 1) == nil)
        #expect(tree.parent(of: 7) == 6 && tree.parent(of: 4) == nil)
        #expect(tree.depth(of: 3) == 2 && tree.height == 2)
        #expect(Array(tree.preorder) == [4, 2, 1, 3, 6, 7])
        #expect(tree.inorder == [1, 2, 3, 4, 6, 7])
        #expect(tree.postorder == [1, 3, 2, 7, 6, 4])
        #expect(tree.contains(7) && !tree.contains(5))
        #expect(tree.description == "4(2(1, 3), 6(_, 7))")
        #expect(tree.debugDescription == "BinaryTree<Int>(vertexCount: 6, 4(2(1, 3), 6(_, 7)))")
    }

    @Test("A lone left child and a lone right child are different binary trees, the same ordered tree")
    func sides() throws {
        let leftOnly = try #require(BinaryTree(root: "a") { $0 == "a" ? ("b", nil) : (nil, nil) })
        let rightOnly = try #require(BinaryTree(root: "a") { $0 == "a" ? (nil, "b") : (nil, nil) })
        #expect(leftOnly != rightOnly)
        #expect(leftOnly.hashValue != rightOnly.hashValue)
        #expect(leftOnly.inorder == ["b", "a"])
        #expect(rightOnly.inorder == ["a", "b"])
        #expect(OrderedTree(leftOnly) == OrderedTree(rightOnly))
        #expect(Arborescence(leftOnly) == Arborescence(rightOnly))
        #expect(leftOnly.description == "\"a\"(\"b\", _)")
        #expect(rightOnly.description == "\"a\"(_, \"b\")")
        let again = try #require(BinaryTree(root: "a") { $0 == "a" ? ("b", nil) : (nil, nil) })
        #expect(again == leftOnly && again.hashValue == leftOnly.hashValue)
    }

    @Test("Conversions list the left child first and keep the vertices")
    func conversions() throws {
        let links: [Int: (Int?, Int?)] = [10: (30, 20), 20: (nil, 40)]
        let tree = try #require(BinaryTree(root: 10) { links[$0] ?? (nil, nil) })
        let ordered = OrderedTree(tree)
        #expect(Array(ordered.children(of: 10)) == [30, 20])
        #expect(Array(ordered.children(of: 20)) == [40])
        #expect(Array(ordered.preorder) == Array(tree.preorder))
        let arborescence = Arborescence(tree)
        #expect(arborescence.root == 10)
        #expect(Set(arborescence.edges) == [DirectedEdge(from: 10, to: 30), DirectedEdge(from: 10, to: 20), DirectedEdge(from: 20, to: 40)])
        #expect(Array(arborescence.successors(of: 10)) == [30, 20])
    }

    @Test("A repeated vertex fails: both children the same, a cycle to the root, a shared child")
    func repeated() {
        #expect(BinaryTree(root: 0) { $0 == 0 ? (1, 1) : (nil, nil) } == nil)
        #expect(BinaryTree(root: 0) { $0 == 0 ? (1, nil) : $0 == 1 ? (nil, 0) : (nil, nil) } == nil)
        #expect(BinaryTree(root: 0) { $0 == 0 ? (0, nil) : (nil, nil) } == nil)
        let links: [Int: (Int?, Int?)] = [0: (1, 2), 1: (3, nil), 2: (nil, 3)]
        #expect(BinaryTree(root: 0) { links[$0] ?? (nil, nil) } == nil)
    }

    @Test("A single vertex; Int vertices 0..<n in any order; String vertices past the small-tree scan")
    func numberings() throws {
        let one = try #require(BinaryTree(root: 3) { _ in (nil, nil) })
        #expect(one.vertexCount == 1 && one.inorder == [3] && one.description == "3")
        let links: [Int: (Int?, Int?)] = [2: (0, 4), 0: (nil, 1), 4: (3, nil)]
        let tree = try #require(BinaryTree(root: 2) { links[$0] ?? (nil, nil) })
        #expect(tree.inorder == [0, 1, 2, 3, 4])
        #expect(tree.right(of: 0) == 1 && tree.left(of: 4) == 3 && tree.left(of: 0) == nil)
        let names = (0 ..< 20).map { "v\($0)" }
        // A right spine v0 → v1 → … → v19, each with no left child.
        let spine = try #require(BinaryTree(root: "v0") { v in
            let k = Int(v.dropFirst())!
            return (nil, k < 19 ? names[k + 1] : nil)
        })
        #expect(spine.inorder == names)
        #expect(spine.right(of: "v18") == "v19" && spine.left(of: "v18") == nil)
        #expect(spine.description.hasSuffix("v15\"(_, …))))))))))))))))"))
    }

    @Test("The checked: lookups throw VertexNotFound for a missing vertex")
    func checked() throws {
        let tree = try #require(BinaryTree(root: 0) { $0 == 0 ? (nil, 1) : (nil, nil) })
        #expect(try tree.left(checked: 0) == nil)
        #expect(try tree.right(checked: 0) == 1)
        #expect(try tree.parent(checked: 1) == 0)
        #expect(try tree.depth(checked: 1) == 1)
        #expect(throws: VertexNotFound.self) { _ = try tree.left(checked: 2) }
        #expect(throws: VertexNotFound.self) { _ = try tree.right(checked: 2) }
        #expect(throws: VertexNotFound.self) { _ = try tree.parent(checked: -1) }
        #expect(throws: VertexNotFound.self) { _ = try tree.depth(checked: 9) }
    }

    @Test("The plain lookups trap on a missing vertex; a negative count and no weights trap", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let tree = BinaryTree(root: 0) { _ in (nil, nil) }!
            _ = tree.left(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            let tree = BinaryTree(root: 0) { _ in (nil, nil) }!
            _ = tree.right(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = BinaryTree.allBinaryTrees(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = BinaryTree.huffman(weights: [Int]())
        }
    }

    @Test("allBinaryTrees gives the Catalan number of distinct trees, each numbered in preorder", .tags(.exhaustive))
    func catalan() {
        let catalan = [0, 1, 2, 5, 14, 42, 132, 429, 1430]
        for n in 0 ... 8 {
            let trees = Array(BinaryTree.allBinaryTrees(vertexCount: n))
            #expect(trees.count == catalan[n], "n = \(n)")
            #expect(Set(trees).count == catalan[n], "n = \(n)")
            for tree in trees {
                #expect(tree.vertexCount == n)
                #expect(Array(tree.preorder) == Array(0 ..< n))
                #expect(tree.inorder.sorted() == Array(0 ..< n))
            }
        }
        let three = BinaryTree.allBinaryTrees(vertexCount: 3).map(\.description)
        #expect(Set(three) == ["0(1(2, _), _)", "0(1(_, 2), _)", "0(1, 2)", "0(_, 1(2, _))", "0(_, 1(_, 2))"])
        #expect(three.first == "0(1(2, _), _)")
        var iterator = BinaryTree.allBinaryTrees(vertexCount: 1).makeIterator()
        #expect(iterator.next()?.description == "0")
        #expect(iterator.next() == nil)
        #expect(iterator.next() == nil)
    }

    @Test("The six-letter Huffman example: code words 1100, 1101, 100, 101, 111, 0")
    func huffmanExample() {
        let tree = BinaryTree.huffman(weights: [5, 9, 12, 13, 16, 45])
        #expect(tree.vertexCount == 11)
        #expect(tree.root == 10)
        var codes: [String] = []
        for leaf in 0 ..< 6 {
            #expect(tree.left(of: leaf) == nil && tree.right(of: leaf) == nil)
            var word = "", v = leaf
            while let p = tree.parent(of: v) {
                word = (tree.left(of: p) == v ? "0" : "1") + word
                v = p
            }
            codes.append(word)
        }
        #expect(codes == ["1100", "1101", "100", "101", "111", "0"])
        for v in 6 ..< 11 { #expect(tree.left(of: v) != nil && tree.right(of: v) != nil) }
        #expect(tree.left(of: 6) == 0 && tree.right(of: 6) == 1)
        #expect(BinaryTree.huffman(weights: [7.5]).description == "0")
        // Ties: leaves before joined trees, earlier before later.
        let even = BinaryTree.huffman(weights: [1, 1, 1, 1])
        #expect(even.description == "6(4(0, 1), 5(2, 3))")
        let tie = BinaryTree.huffman(weights: [2, 1, 1])
        #expect(tie.description == "4(0, 3(1, 2))")
    }

    @Test("Random Huffman trees: full, leaves 0..<n, and weighted depth equal to the sum of greedy merges", .tags(.randomized))
    func huffmanProperty() async {
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 20).array(of: 1 ... 12)) { weights in
            let tree = BinaryTree.huffman(weights: weights)
            let n = weights.count
            #expect(tree.vertexCount == 2 * n - 1)
            var cost = 0
            for v in 0 ..< 2 * n - 1 {
                let l = tree.left(of: v), r = tree.right(of: v)
                #expect((l == nil) == (r == nil))
                #expect((l == nil) == (v < n))
                if v < n { cost += weights[v] * tree.depth(of: v) }
            }
            var pool = weights, merges = 0
            while pool.count > 1 {
                pool.sort()
                let joined = pool[0] + pool[1]
                merges += joined
                pool.removeFirst(2)
                pool.append(joined)
            }
            #expect(cost == merges, "\(weights)")
        }
    }

    @Test("Random search trees: inorder is sorted, preorder follows the links, and swapping a lone child's side breaks equality", .tags(.randomized))
    func searchTrees() async {
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 1_000_000), Gen.int(in: 1 ... 30)) { seed, n in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let keys = Array(0 ..< n).shuffled(using: &rng)
            var left = [Int?](repeating: nil, count: n), right = [Int?](repeating: nil, count: n)
            for key in keys.dropFirst() {
                var v = keys[0]
                while true {
                    if key < v {
                        guard let l = left[v] else { left[v] = key; break }
                        v = l
                    } else {
                        guard let r = right[v] else { right[v] = key; break }
                        v = r
                    }
                }
            }
            guard let tree = BinaryTree(root: keys[0], children: { (left[$0], right[$0]) }) else {
                Issue.record("not a binary tree")
                return
            }
            #expect(tree.inorder == Array(0 ..< n))
            var preorder: [Int] = [], postorder: [Int] = [], stack = [(keys[0], 0)]
            preorder.append(keys[0])
            while let (v, k) = stack.last {
                let next = k == 0 ? left[v] : k == 1 ? right[v] : nil
                stack[stack.count - 1].1 += 1
                if let next {
                    preorder.append(next)
                    stack.append((next, 0))
                } else if k >= 2 {
                    postorder.append(v)
                    stack.removeLast()
                }
            }
            #expect(Array(tree.preorder) == preorder)
            #expect(tree.postorder == postorder)
            for v in 0 ..< n { #expect(tree.left(of: v) == left[v] && tree.right(of: v) == right[v]) }
            #expect(OrderedTree(tree) == OrderedTree(Arborescence(tree)))
            if let v = (0 ..< n).first(where: { (left[$0] == nil) != (right[$0] == nil) }) {
                var l = left, r = right
                (l[v], r[v]) = (r[v], l[v])
                let flipped = BinaryTree(root: keys[0], children: { (l[$0], r[$0]) })
                #expect(flipped != nil && flipped != tree)
                #expect(OrderedTree(flipped!) == OrderedTree(tree))
            }
        }
    }
}
