// Tree edit distance (Zhang–Shasha) on OrderedTree: hand-worked distances, unit and weighted
// costs, the number of cost calls, and a property test against the recursive forest-distance
// definition, memoized, written inside the test.

import GrafluentTestSupport
import PropertyBased
import Testing
import TreeAlgorithms
import Trees

@Suite("Tree edit distance")
struct TreeEditDistanceTests {
    @Test("Zhang and Shasha's example: f(d(a, c(b)), e) to f(c(d(a, b)), e) costs 2 with label relabelling")
    func paperExample() throws {
        let a: [String: [String]] = ["f": ["d", "e"], "d": ["a", "c"], "c": ["b"]]
        let b: [String: [String]] = ["f": ["c", "e"], "c": ["d"], "d": ["a", "b"]]
        let t = try #require(OrderedTree(root: "f") { a[$0, default: []] })
        let u = try #require(OrderedTree(root: "f") { b[$0, default: []] })
        let d = t.treeEditDistance(to: u, substitutionCost: { $0 == $1 ? 0 : 1 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 })
        #expect(d == 2)
        let back = u.treeEditDistance(to: t, substitutionCost: { $0 == $1 ? 0 : 1 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 })
        #expect(back == 2)
        // The shapes differ only by moving c above d: one deletion and one insertion.
        #expect(t.treeEditDistance(to: u) == 2)
    }

    @Test("Single vertices: free to substitute at unit cost, 1 when relabelled")
    func singleVertices() throws {
        let x = try #require(OrderedTree(root: "x") { _ in [String]() })
        let y = try #require(OrderedTree(root: "y") { _ in [String]() })
        #expect(x.treeEditDistance(to: y) == 0)
        #expect(x.treeEditDistance(to: y, substitutionCost: { $0 == $1 ? 0 : 1 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 }) == 1)
        // Substituting at 5 is dearer than deleting and inserting at 1 each.
        #expect(x.treeEditDistance(to: y, substitutionCost: { _, _ in 5 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 }) == 2)
    }

    @Test("Sibling order matters: a(b, c) to a(c, b) costs 2 with labels, 0 for the shapes")
    func siblingOrder() throws {
        let t = try #require(OrderedTree(root: "a") { $0 == "a" ? ["b", "c"] : [] })
        let u = try #require(OrderedTree(root: "a") { $0 == "a" ? ["c", "b"] : [] })
        #expect(t.treeEditDistance(to: u, substitutionCost: { $0 == $1 ? 0 : 1 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 }) == 2)
        #expect(t.treeEditDistance(to: u) == 0)
    }

    @Test("A path of three to a star of three: delete the middle vertex, insert a leaf")
    func pathToStar() throws {
        let path = try #require(OrderedTree(root: 0) { $0 < 2 ? [$0 + 1] : [] })
        let star = try #require(OrderedTree(root: 0) { $0 == 0 ? [1, 2] : [] })
        #expect(path.treeEditDistance(to: star) == 2)
        #expect(star.treeEditDistance(to: path) == 2)
        #expect(path.treeEditDistance(to: path) == 0)
    }

    @Test("Deleting an inner vertex splices its children into its place among its siblings")
    func splice() throws {
        // r(a, m(x, y), b) to r(a, x, y, b): delete m only.
        let t = try #require(OrderedTree(root: "r") { ["r": ["a", "m", "b"], "m": ["x", "y"]][$0, default: []] })
        let u = try #require(OrderedTree(root: "r") { $0 == "r" ? ["a", "x", "y", "b"] : [] })
        let labelled = t.treeEditDistance(to: u, substitutionCost: { $0 == $1 ? 0 : 10 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 })
        #expect(labelled == 1)
        #expect(u.treeEditDistance(to: t, substitutionCost: { $0 == $1 ? 0 : 10 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 }) == 1)
    }

    @Test("Growing a single vertex into n vertices costs the inserted vertices' costs")
    func insertions() throws {
        let one = try #require(OrderedTree(root: 0) { _ in [Int]() })
        let big = try #require(OrderedTree(root: 0) { $0 == 0 ? [1, 2, 3] : $0 == 2 ? [4] : [] })
        #expect(one.treeEditDistance(to: big) == 4)
        let weighted = one.treeEditDistance(to: big, substitutionCost: { _, _ in 0.0 }, deletionCost: { _ in 1.0 }, insertionCost: { Double($0) / 4 })
        // Substitute the lone vertex for 4, the dearest to insert (free), and insert 0, 1, 2 and 3
        // at a quarter of their value.
        #expect(weighted == 1.5)
        let reverse = big.treeEditDistance(to: one, substitutionCost: { _, _ in 0.0 }, deletionCost: { Double($0) / 4 }, insertionCost: { _ in 1.0 })
        #expect(reverse == 1.5)
    }

    @Test("Deletion and insertion costs are read once per vertex, substitution once per pair")
    func costCalls() throws {
        let t = try #require(OrderedTree(root: 0) { [0: [1, 2], 1: [3, 4], 2: [5]][$0, default: []] })
        let u = try #require(OrderedTree(root: 0) { [0: [1], 1: [2, 3]][$0, default: []] })
        var deletions: [Int] = [], insertions: [Int] = []
        var pairs: [[Int]] = []
        _ = t.treeEditDistance(to: u, substitutionCost: { pairs.append([$0, $1]); return 1 },
                               deletionCost: { deletions.append($0); return 1 }, insertionCost: { insertions.append($0); return 1 })
        #expect(deletions.sorted() == Array(0 ..< 6))
        #expect(insertions.sorted() == Array(0 ..< 4))
        #expect(pairs.count == 24)
        #expect(Set(pairs).count == 24)
    }

    @Test("Random trees: agrees with the recursive forest distance, at unit and weighted costs", .tags(.randomized))
    func againstRecursion() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 6)
        await propertyCheck(count: 200, input: choices, choices, Gen.int(in: 0 ... 1_000_000)) { first, second, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var trees: [OrderedTree<Int>] = []
            var lists: [[[Int]]] = []
            for (k, choice) in [first, second].enumerated() {
                // Vertex i + 1 hangs from choice mod (i + 1); the second tree's vertices are 100 up.
                let n = choice.count + 1
                var rows = [[Int]](repeating: [], count: n)
                for (i, c) in choice.enumerated() { rows[c % (i + 1)].append(i + 1) }
                for v in 0 ..< n { rows[v].shuffle(using: &rng) }
                lists.append(rows)
                let offset = 100 * k
                guard let tree = OrderedTree(root: offset, children: { rows[$0 - offset].map { $0 + offset } }) else {
                    Issue.record("not a tree")
                    return
                }
                trees.append(tree)
            }
            let sub: (Int, Int) -> Int = { $0 % 3 == ($1 - 100) % 3 ? 0 : 2 }
            let del: (Int) -> Int = { $0 % 2 + 1 }
            let ins: (Int) -> Int = { ($0 - 100) % 3 + 1 }
            // Forests as lists of roots; F − v replaces the rightmost root v by its children.
            var memo: [String: Int] = [:]
            func distance(_ f: [Int], _ g: [Int]) -> Int {
                let key = "\(f)|\(g)"
                if let known = memo[key] { return known }
                var best: Int
                if f.isEmpty && g.isEmpty {
                    best = 0
                } else if g.isEmpty {
                    let v = f.last!
                    best = distance(f.dropLast() + lists[0][v], g) + del(v)
                } else if f.isEmpty {
                    let w = g.last!
                    best = distance(f, g.dropLast() + lists[1][w]) + ins(w + 100)
                } else {
                    let v = f.last!, w = g.last!
                    best = distance(f.dropLast() + lists[0][v], g) + del(v)
                    best = min(best, distance(f, g.dropLast() + lists[1][w]) + ins(w + 100))
                    best = min(best, distance(lists[0][v], lists[1][w]) + distance(Array(f.dropLast()), Array(g.dropLast())) + sub(v, w + 100))
                }
                memo[key] = best
                return best
            }
            let expected = distance([0], [0])
            #expect(trees[0].treeEditDistance(to: trees[1], substitutionCost: sub, deletionCost: del, insertionCost: ins) == expected, "\(lists)")
            memo = [:]
            let unitSub: (Int, Int) -> Int = { _, _ in 0 }
            func unit(_ f: [Int], _ g: [Int]) -> Int {
                let key = "\(f)|\(g)"
                if let known = memo[key] { return known }
                var best: Int
                if f.isEmpty || g.isEmpty {
                    best = f.isEmpty ? (g.isEmpty ? 0 : unit(f, g.dropLast() + lists[1][g.last!]) + 1) : unit(f.dropLast() + lists[0][f.last!], g) + 1
                } else {
                    let v = f.last!, w = g.last!
                    best = min(unit(f.dropLast() + lists[0][v], g) + 1, unit(f, g.dropLast() + lists[1][w]) + 1)
                    best = min(best, unit(lists[0][v], lists[1][w]) + unit(Array(f.dropLast()), Array(g.dropLast())) + unitSub(v, w))
                }
                memo[key] = best
                return best
            }
            #expect(trees[0].treeEditDistance(to: trees[1]) == unit([0], [0]))
            #expect(trees[0].treeEditDistance(to: trees[0]) == 0)
            #expect(trees[1].treeEditDistance(to: trees[0]) == trees[0].treeEditDistance(to: trees[1]))
        }
    }
}
