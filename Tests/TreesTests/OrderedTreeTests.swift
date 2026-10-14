// OrderedTree: construction from a children closure, the rooted queries in child order, equality
// and hashing by ordered structure, the O(1) conversions to and from RootedTree and Arborescence,
// the checked: lookups and descriptions. Expected values are worked by hand from the trees drawn
// in each test.

import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Trees

@Suite("OrderedTree")
struct OrderedTreeTests {
    @Test("Children come out in the order given, and preorder and postorder follow it")
    func childOrder() throws {
        // a(b(d, e), c)
        let lists: [String: [String]] = ["a": ["b", "c"], "b": ["d", "e"]]
        let tree = try #require(OrderedTree(root: "a") { lists[$0, default: []] })
        #expect(tree.root == "a")
        #expect(tree.vertexCount == 5)
        #expect(Array(tree.children(of: "a")) == ["b", "c"])
        #expect(Array(tree.children(of: "b")) == ["d", "e"])
        #expect(tree.children(of: "e").isEmpty)
        #expect(Array(tree.preorder) == ["a", "b", "d", "e", "c"])
        #expect(tree.postorder == ["d", "e", "b", "c", "a"])
        #expect(tree.parent(of: "a") == nil)
        #expect(tree.parent(of: "e") == "b")
        #expect(tree.depth(of: "d") == 2)
        #expect(tree.height == 2)
        #expect(tree.contains("c"))
        #expect(!tree.contains("z"))
    }

    @Test("Reversing a vertex's children changes the ordered tree but not the rooted tree")
    func orderIsPartOfTheValue() throws {
        let lists: [Int: [Int]] = [0: [1, 2], 1: [3, 4]]
        let mirrored: [Int: [Int]] = [0: [2, 1], 1: [3, 4]]
        let a = try #require(OrderedTree(root: 0) { lists[$0, default: []] })
        let b = try #require(OrderedTree(root: 0) { mirrored[$0, default: []] })
        #expect(a != b)
        #expect(RootedTree(a) == RootedTree(b))
        #expect(Arborescence(a) == Arborescence(b))
        #expect(Array(b.preorder) == [0, 2, 1, 3, 4])
    }

    @Test("Equal ordered trees built with their vertices numbered differently hash alike")
    func equalAcrossNumberings() throws {
        // 0(1(3), 2) built directly, and through a RootedTree whose vertices are listed 3, 2, 1, 0.
        let lists: [Int: [Int]] = [0: [1, 2], 1: [3]]
        let a = try #require(OrderedTree(root: 0) { lists[$0, default: []] })
        let rooted = try #require(RootedTree(vertices: [3, 2, 1, 0]) { [3: 1, 2: 0, 1: 0][$0] })
        #expect(Array(rooted.children(of: 0)) == [2, 1])
        let b = OrderedTree(rooted)
        #expect(a != b)
        let swapped = try #require(RootedTree(vertices: [3, 1, 2, 0]) { [3: 1, 2: 0, 1: 0][$0] })
        let c = OrderedTree(swapped)
        #expect(Array(c.children(of: 0)) == [1, 2])
        #expect(a == c)
        #expect(a.hashValue == c.hashValue)
    }

    @Test("Different roots or different child counts along the same preorder are unequal")
    func preorderAloneIsNotEnough() throws {
        // 0(1, 2) and 0(1(2)) share the preorder 0, 1, 2.
        let star: [Int: [Int]] = [0: [1, 2]]
        let path: [Int: [Int]] = [0: [1], 1: [2]]
        let a = try #require(OrderedTree(root: 0) { star[$0, default: []] })
        let b = try #require(OrderedTree(root: 0) { path[$0, default: []] })
        #expect(Array(a.preorder) == Array(b.preorder))
        #expect(a != b)
        #expect(a.hashValue != b.hashValue)
        let c = try #require(OrderedTree(root: 1) { [1: [0, 2]][$0, default: []] })
        #expect(a != c)
        let small = try #require(OrderedTree(root: 0) { [0: [1]][$0, default: []] })
        #expect(a != small)
    }

    @Test("A single vertex")
    func singleVertex() throws {
        let tree = try #require(OrderedTree(root: "x") { _ in [String]() })
        #expect(tree.vertexCount == 1)
        #expect(Array(tree.preorder) == ["x"])
        #expect(tree.postorder == ["x"])
        #expect(tree.height == 0)
        #expect(tree.description == "\"x\"")
        let one = try #require(OrderedTree(root: 5) { _ in [Int]() })
        #expect(one.root == 5)
        #expect(RootedTree(one).root == 5)
    }

    @Test("A repeated vertex fails: a cycle back to the root, a shared child, a child listed twice")
    func repeatedVertices() {
        #expect(OrderedTree(root: 0) { $0 == 0 ? [1] : $0 == 1 ? [0] : [] } == nil)
        #expect(OrderedTree(root: 0) { $0 == 0 ? [0] : [] } == nil)
        #expect(OrderedTree(root: 0) { [0: [1, 2], 1: [3], 2: [3]][$0, default: []] } == nil)
        #expect(OrderedTree(root: 0) { $0 == 0 ? [1, 1] : [] } == nil)
    }

    @Test("The children closure is called once per vertex, level by level, and its error propagates")
    func closureCalls() throws {
        struct Stop: Error {}
        var calls: [Int] = []
        let lists: [Int: [Int]] = [0: [1, 2], 1: [3], 2: [4]]
        let tree = try #require(OrderedTree(root: 0) { v in
            calls.append(v)
            return lists[v, default: []]
        })
        #expect(calls == [0, 1, 2, 3, 4])
        #expect(tree.vertexCount == 5)
        #expect(throws: Stop.self) {
            _ = try OrderedTree(root: 0) { (v: Int) throws(Stop) -> [Int] in
                if v == 1 { throw Stop() }
                return v == 0 ? [1] : []
            }
        }
    }

    @Test("Conversions keep vertices, child order and the root, both ways")
    func conversions() throws {
        // 10(30, 20(40)): Int vertices that are not 0..<n.
        let lists: [Int: [Int]] = [10: [30, 20], 20: [40]]
        let tree = try #require(OrderedTree(root: 10) { lists[$0, default: []] })
        let rooted = RootedTree(tree)
        #expect(rooted.root == 10)
        #expect(Array(rooted.children(of: 10)) == [30, 20])
        #expect(OrderedTree(rooted) == tree)
        let arborescence = Arborescence(tree)
        #expect(Array(arborescence.successors(of: 10)) == [30, 20])
        #expect(Set(arborescence.edges) == [DirectedEdge(from: 10, to: 30), DirectedEdge(from: 10, to: 20), DirectedEdge(from: 20, to: 40)])
        #expect(OrderedTree(arborescence) == tree)
        // A rooted tree's children are in edge-position order, which the ordered tree keeps.
        let built = try #require(RootedTree(vertices: 0 ..< 4) { [1: 0, 2: 0, 3: 0][$0] })
        #expect(Array(OrderedTree(built).children(of: 0)) == [1, 2, 3])
    }

    @Test("Int vertices 0..<n in any order, and String vertices past the small-tree scan, look up correctly")
    func numberings() throws {
        let lists: [Int: [Int]] = [3: [0, 4], 0: [2], 4: [1]]
        let tree = try #require(OrderedTree(root: 3) { lists[$0, default: []] })
        #expect(Array(tree.preorder) == [3, 0, 2, 4, 1])
        for v in 0 ..< 5 { #expect(tree.parent(of: v) == [3: nil, 0: 3, 4: 3, 2: 0, 1: 4][v]!) }
        let names = (0 ..< 12).map { "v\($0)" }
        let wide = try #require(OrderedTree(root: "v0") { $0 == "v0" ? Array(names.dropFirst().reversed()) : [] })
        #expect(Array(wide.children(of: "v0")) == Array(names.dropFirst().reversed()))
        #expect(wide.parent(of: "v7") == "v0")
        #expect(!wide.contains("v12"))
        // 0, 1 and 3: Int vertices that are not a permutation of 0..<3.
        let gap = try #require(OrderedTree(root: 0) { $0 == 0 ? [1, 3] : [] })
        #expect(Array(gap.children(of: 0)) == [1, 3])
        #expect(gap.parent(of: 3) == 0)
        #expect(!gap.contains(2))
    }

    @Test("The checked: lookups throw VertexNotFound for a missing vertex")
    func checked() throws {
        let tree = try #require(OrderedTree(root: 0) { $0 == 0 ? [1] : [] })
        #expect(try tree.parent(checked: 1) == 0)
        #expect(try tree.parent(checked: 0) == nil)
        #expect(try Array(tree.children(checked: 0)) == [1])
        #expect(try tree.depth(checked: 1) == 1)
        #expect(throws: VertexNotFound.self) { _ = try tree.parent(checked: 2) }
        #expect(throws: VertexNotFound.self) { _ = try tree.children(checked: -1) }
        #expect(throws: VertexNotFound.self) { _ = try tree.depth(checked: 9) }
    }

    @Test("The plain lookups trap on a missing vertex", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let tree = OrderedTree(root: 0) { $0 == 0 ? [1] : [] }!
            _ = tree.parent(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let tree = OrderedTree(root: "a") { _ in [String]() }!
            _ = tree.children(of: "b")
        }
        await #expect(processExitsWith: .failure) {
            let tree = OrderedTree(root: 0) { $0 == 0 ? [1] : [] }!
            _ = tree.depth(of: 5)
        }
    }

    @Test("The description nests each vertex's children in parentheses, up to 16 vertices")
    func descriptions() throws {
        let lists: [Int: [Int]] = [0: [1, 2], 1: [3, 4]]
        let tree = try #require(OrderedTree(root: 0) { lists[$0, default: []] })
        #expect(tree.description == "0(1(3, 4), 2)")
        #expect(tree.debugDescription == "OrderedTree<Int>(vertexCount: 5, 0(1(3, 4), 2))")
        let path = try #require(OrderedTree(root: 0) { $0 < 19 ? [$0 + 1] : [] })
        #expect(path.description == "0(1(2(3(4(5(6(7(8(9(10(11(12(13(14(15(…))))))))))))))))")
        let star = try #require(OrderedTree(root: 0) { $0 == 0 ? Array(1 ..< 20) : [] })
        #expect(star.description == "0(" + (1 ... 15).map(String.init).joined(separator: ", ") + ", …)")
    }

    @Test("Random ordered trees: preorder, postorder and children match the lists; == and hashing see renumbering but not sibling swaps", .tags(.randomized))
    func randomTrees() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: choices, Gen.int(in: 0 ... 1_000_000)) { choice, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Vertex i + 1 hangs from choice mod (i + 1), each vertex's children then shuffled,
            // and the vertices relabelled by a random permutation.
            let n = choice.count + 1
            let label = Array(0 ..< n).shuffled(using: &rng)
            var lists = [[Int]](repeating: [], count: n)
            var parent = [Int: Int]()
            for (i, c) in choice.enumerated() {
                lists[label[c % (i + 1)]].append(label[i + 1])
                parent[label[i + 1]] = label[c % (i + 1)]
            }
            for v in 0 ..< n { lists[v].shuffle(using: &rng) }
            guard let tree = OrderedTree(root: label[0], children: { lists[$0] }) else {
                Issue.record("not a tree: \(choice)")
                return
            }
            var preorder: [Int] = [], postorder: [Int] = []
            var stack: [(Int, Int)] = [(label[0], 0)]
            preorder.append(label[0])
            while let (v, k) = stack.last {
                if k < lists[v].count {
                    stack[stack.count - 1].1 += 1
                    preorder.append(lists[v][k])
                    stack.append((lists[v][k], 0))
                } else {
                    postorder.append(v)
                    stack.removeLast()
                }
            }
            #expect(Array(tree.preorder) == preorder)
            #expect(tree.postorder == postorder)
            for v in 0 ..< n {
                #expect(Array(tree.children(of: v)) == lists[v])
                #expect(tree.parent(of: v) == parent[v])
            }
            #expect(OrderedTree(RootedTree(tree)) == tree)
            #expect(OrderedTree(Arborescence(tree)) == tree)
            // Listed in postorder, a rooted tree numbers its vertices differently but keeps every
            // sibling order.
            guard let renumbered = RootedTree(vertices: postorder, parent: { parent[$0] }) else {
                Issue.record("not a tree: \(choice)")
                return
            }
            let same = OrderedTree(renumbered)
            #expect(same == tree)
            #expect(same.hashValue == tree.hashValue)
            if let v = (0 ..< n).first(where: { lists[$0].count >= 2 }) {
                var swapped = lists
                swapped[v].swapAt(0, 1)
                let other = OrderedTree(root: label[0], children: { swapped[$0] })
                #expect(other != nil && other != tree)
            }
        }
    }
}
