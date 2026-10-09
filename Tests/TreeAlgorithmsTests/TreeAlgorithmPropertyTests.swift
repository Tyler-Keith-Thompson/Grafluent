// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Trees are grown from a list of attachment choices (vertex i + 1 hangs from choice mod (i + 1)),
// then their edges are shuffled and flipped and their vertices listed in a shuffled order by a
// seed, so positions, orientations, row order and vertex order (index ≠ value) all vary; seed 0
// keeps the grown order. The oracles use only the Trees API and definitions: ancestor chains for
// the lowest common ancestor; `Tree.path(from:to:)` and `Path.weight` for distances, all pairs;
// recursion over `children(of:)` for the Euler tour and the heavy-first preorder; subtree sizes
// from `descendants(of:)` for heavy children; the path's positions cut into runs on one heavy path
// for segments; component sizes after removing each vertex for the centroid; and a decomposition
// over vertex sets for the centroid tree. Weights are `Int` in 0 … 3 and `Double` quarters in
// 0 … 3 (zeros included; quarters keep every sum exact, so ties do not depend on summation order).
// See README.md.

import Foundation
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import TreeAlgorithms
import Trees
import Walks

@Suite("TreeAlgorithms properties against oracles, with shrinking", .tags(.randomized))
struct TreeAlgorithmPropertyTests {
    @Test("TA-111 – TA-121 lowestCommonAncestor and distance agree with ancestor chains and path lengths on random trees, at a random root, on all four entry points")
    func lowestCommonAncestors() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 1_000)) { choice, seed, rootChoice in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let tree = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            let rooted = RootedTree(tree, root: listed[rootChoice % n])
            let arborescence = Arborescence(rooted)
            let lca = LowestCommonAncestors(rooted)
            let fromArborescence = LowestCommonAncestors(arborescence)
            let hld = HeavyLightDecomposition(rooted)
            var chains: [Int: [Int]] = [:]
            for v in tree.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
            for a in tree.vertices {
                for b in tree.vertices {
                    let onChainOfB = Set(chains[b, default: []])
                    guard let expected = chains[a, default: []].first(where: { onChainOfB.contains($0) }) else {
                        Issue.record("no common ancestor of \(a) and \(b)")
                        return
                    }
                    #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "\(pairs) at \(rooted.root): (\(a), \(b))")
                    #expect(arborescence.lowestCommonAncestor(of: a, b) == expected)
                    #expect(lca.lowestCommonAncestor(of: a, b) == expected)
                    #expect(fromArborescence.lowestCommonAncestor(of: a, b) == expected)
                    #expect(hld.lowestCommonAncestor(of: a, b) == expected)
                    let (i, j) = (tree.vertexIndex(of: a), tree.vertexIndex(of: b))
                    #expect(lca.lowestCommonAncestor(ofIndex: i, j) == tree.vertexIndex(of: expected))
                    let length = tree.path(from: a, to: b).length
                    #expect(lca.distance(from: a, to: b) == length)
                    #expect(lca.distance(fromIndex: i, toIndex: j) == length)
                }
            }
        }
    }

    @Test("TA-116 – TA-119 LowestCommonAncestors on random trees of 60 – 300 vertices (several 64-entry blocks) agrees with parent climbing on every pair")
    func lowestCommonAncestorsAcrossBlocks() async {
        let choices = Gen.int(in: 0 ... 1_000_000).array(of: 59 ... 299)
        await propertyCheck(count: 30, input: choices, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 3)) { choice, seed, shape in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Shapes: uniform attachment, path-like (attach near the end), star-like, caterpillar.
            var pairs: [(Int, Int)] = (0 ..< choice.count).map { i in
                switch shape {
                case 0: (choice[i] % (i + 1), i + 1)
                case 1: (max(0, i - choice[i] % 3), i + 1)
                case 2: (choice[i] % min(i + 1, 3), i + 1)
                default: (i % 2 == 0 ? i / 2 : choice[i] % (i + 1), i + 1)
                }
            }
            pairs.shuffle(using: &rng)
            guard let tree = Tree(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            let rooted = RootedTree(tree, root: seed % n)
            let lca = LowestCommonAncestors(rooted)
            let parent = (0 ..< n).map { rooted.parent(ofIndex: $0) ?? -1 }
            let depth = (0 ..< n).map { rooted.depth(ofIndex: $0) }
            var mismatches: [String] = []
            for i in 0 ..< n {
                for j in 0 ..< n {
                    var (x, y) = (i, j)
                    while depth[x] > depth[y] { x = parent[x] }
                    while depth[y] > depth[x] { y = parent[y] }
                    while x != y { (x, y) = (parent[x], parent[y]) }
                    let got = lca.lowestCommonAncestor(ofIndex: i, j)
                    let distance = lca.distance(fromIndex: i, toIndex: j)
                    if got != x || distance != depth[i] + depth[j] - 2 * depth[x] {
                        mismatches.append("(\(i), \(j)): \(got), \(distance)")
                    }
                }
            }
            #expect(mismatches.isEmpty, "n = \(n), shape \(shape), root \(rooted.root): \(mismatches.prefix(5))")
        }
    }

    @Test("TA-201 – TA-212 eulerTour agrees with recursion over children(of:) on random trees, at a random root")
    func eulerTour() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 1_000)) { choice, seed, rootChoice in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let tree = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            let rooted = RootedTree(tree, root: listed[rootChoice % n])
            var vertices: [Int] = []
            var edges: [Int] = []
            func visit(_ v: Int) {
                vertices.append(v)
                for c in rooted.children(of: v) {
                    guard let e = rooted.parentEdge(of: c) else { return }
                    edges.append(e)
                    visit(c)
                    edges.append(e)
                    vertices.append(v)
                }
            }
            visit(rooted.root)
            let tour = rooted.eulerTour
            #expect(tour.vertices == vertices, "\(pairs) at \(rooted.root)")
            #expect(tour.edges == edges)
            #expect(tour.vertices.count == 2 * n - 1)
            #expect(tour.isClosed)
            #expect(Walk(vertices: tour.vertices, edges: tour.edges, in: rooted) != nil)
            #expect(RootedTree(Arborescence(rooted)).eulerTour == tour)
        }
    }

    @Test("TA-301 – TA-335 HeavyLightDecomposition agrees with its definitions on random trees: heavy children, heads, positions, subtrees, and segments on every pair")
    func heavyLightDecomposition() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 1_000)) { choice, seed, rootChoice in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let tree = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            let rooted = RootedTree(tree, root: listed[rootChoice % n])
            let hld = HeavyLightDecomposition(rooted)
            // Sizes, heavy children (first strict maximum in children order), heads.
            var size: [Int: Int] = [:]
            for v in tree.vertices { size[v] = rooted.descendants(of: v).count + 1 }
            var heavy: [Int: Int] = [:]
            for v in tree.vertices {
                var best = 0
                for c in rooted.children(of: v) where size[c, default: 0] > best {
                    best = size[c, default: 0]
                    heavy[v] = c
                }
            }
            var head: [Int: Int] = [:]
            for v in rooted.preorder {
                if let p = rooted.parent(of: v), heavy[p] == v { head[v] = head[p] } else { head[v] = v }
            }
            // Positions: the preorder that visits the heavy child first.
            var order: [Int] = []
            func visit(_ v: Int) {
                order.append(v)
                if let h = heavy[v] { visit(h) }
                for c in rooted.children(of: v) where c != heavy[v] { visit(c) }
            }
            visit(rooted.root)
            var position: [Int: Int] = [:]
            for (offset, v) in order.enumerated() { position[v] = offset }
            #expect(Array(hld.preorder) == order, "\(pairs) at \(rooted.root)")
            for v in tree.vertices {
                #expect(hld.heavyChild(of: v) == heavy[v], "heavy child of \(v)")
                #expect(hld.head(of: v) == head[v], "head of \(v)")
                #expect(hld.position(of: v) == position[v])
                #expect(hld.position(ofIndex: tree.vertexIndex(of: v)) == position[v])
                let start = position[v, default: 0]
                #expect(hld.subtree(of: v) == start ..< start + size[v, default: 0])
            }
            // Segments: the path's positions cut into runs on one heavy path; without the common
            // ancestor its position leaves its run, and an emptied run goes.
            let bound = 2 * Int(log2(Double(n))) + 1
            for a in tree.vertices {
                for b in tree.vertices {
                    let path = tree.path(from: a, to: b).vertices
                    let ancestor = rooted.lowestCommonAncestor(of: a, b)
                    var runs: [[Int]] = []
                    for (k, v) in path.enumerated() {
                        if k > 0, head[v] == head[path[k - 1]] {
                            runs[runs.count - 1].append(position[v, default: 0])
                        } else {
                            runs.append([position[v, default: 0]])
                        }
                    }
                    for including in [true, false] {
                        var kept = runs
                        if !including {
                            let p = position[ancestor, default: 0]
                            kept = kept.map { $0.filter { $0 != p } }.filter { !$0.isEmpty }
                        }
                        let expectedRanges = kept.map { ($0.min() ?? 0) ..< ($0.max() ?? 0) + 1 }
                        let expectedFlags = kept.map { $0.count >= 2 && $0[0] > $0[1] }
                        let segments = hld.segments(from: a, to: b, includingCommonAncestor: including)
                        #expect(segments.map(\.positions) == expectedRanges, "\(pairs) at \(rooted.root): (\(a), \(b), \(including))")
                        #expect(segments.map(\.isReversed) == expectedFlags, "(\(a), \(b), \(including))")
                        #expect(segments.count <= bound)
                    }
                }
            }
        }
    }

    @Test("TA-401 – TA-412 TA-601 – TA-613 center(), diameter() and diameterPath() agree with all-pairs path lengths on random trees")
    func unweightedMeasures() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 1_000)) { choice, seed, rootChoice in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let built = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            // Through a rooted tree at a random root: the answer must not depend on it.
            let tree = Tree(RootedTree(built, root: listed[rootChoice % n]))
            let vertices = Array(tree.vertices)
            let distance = vertices.map { a in vertices.map { b in tree.path(from: a, to: b).length } }
            let eccentricity = distance.map { $0.max() ?? 0 }
            let least = eccentricity.min() ?? 0
            let greatest = eccentricity.max() ?? 0
            let center = vertices.indices.filter { eccentricity[$0] == least }.map { vertices[$0] }
            #expect(tree.center() == center, "\(pairs) listed \(listed)")
            #expect(tree.diameter() == greatest)
            // The lexicographically least pair of indices at the diameter.
            var ends = (0, 0)
            search: for i in 0 ..< n {
                for j in 0 ..< n where distance[i][j] == greatest {
                    ends = (i, j)
                    break search
                }
            }
            let expectedPath = tree.path(from: vertices[ends.0], to: vertices[ends.1])
            let path = tree.diameterPath()
            #expect(path.vertices == expectedPath.vertices, "\(pairs) listed \(listed)")
            #expect(path.edges == expectedPath.edges)
            #expect(path.length == greatest)
            // Unit weights give the unweighted answers.
            #expect(tree.center(weight: { _ in 1 }) == center)
            #expect(tree.diameter(weight: { _ in 1 }) == greatest)
            #expect(tree.diameterPath(weight: { _ in 1 }).path == path)
            // One center, or two adjacent ones.
            #expect(center.count == 1 || (center.count == 2 && tree.contains(edge: UndirectedEdge(center[0], center[1]))))
        }
    }

    @Test("TA-413 – TA-420 TA-614 – TA-624 weighted center, diameter and diameterPath agree with all-pairs Path.weight, Int and Double weights with zeros")
    func weightedMeasures() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 12)
        let weights = Gen.int(in: 0 ... 12).array(of: 1 ... 13)
        await propertyCheck(count: 200, input: choices, weights, Gen.int(in: 0 ... 1_000_000)) { choice, quarters, seed in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let tree = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            let vertices = Array(tree.vertices)
            // Int weights 0 … 3, and Double weights in quarters 0 … 3.
            let intWeight = (0 ..< n - 1).map { quarters[$0 % quarters.count] % 4 }
            let doubleWeight = (0 ..< n - 1).map { Double(quarters[$0 % quarters.count]) / 4 }
            for useDouble in [false, true] {
                let distance: [[Double]] = vertices.map { a in
                    vertices.map { b in
                        let path = tree.path(from: a, to: b)
                        return useDouble ? path.weight { doubleWeight[$0] } : Double(path.weight { intWeight[$0] })
                    }
                }
                let eccentricity = distance.map { $0.max() ?? 0 }
                let least = eccentricity.min() ?? 0
                let greatest = eccentricity.max() ?? 0
                let center = vertices.indices.filter { eccentricity[$0] == least }.map { vertices[$0] }
                var ends = (0, 0)
                search: for i in 0 ..< n {
                    for j in 0 ..< n where distance[i][j] == greatest {
                        ends = (i, j)
                        break search
                    }
                }
                let expectedPath = tree.path(from: vertices[ends.0], to: vertices[ends.1])
                if useDouble {
                    #expect(tree.center(weight: { doubleWeight[$0] }) == center, "\(pairs) \(doubleWeight)")
                    #expect(tree.diameter(weight: { doubleWeight[$0] }) == greatest)
                    let result = tree.diameterPath(weight: { doubleWeight[$0] })
                    #expect(result.path == expectedPath, "\(pairs) \(doubleWeight)")
                    #expect(result.path.vertices == expectedPath.vertices)
                    #expect(result.distance == greatest)
                } else {
                    #expect(tree.center(weight: { intWeight[$0] }) == center, "\(pairs) \(intWeight)")
                    #expect(tree.diameter(weight: { intWeight[$0] }) == Int(greatest))
                    let result = tree.diameterPath(weight: { intWeight[$0] })
                    #expect(result.path == expectedPath, "\(pairs) \(intWeight)")
                    #expect(result.path.vertices == expectedPath.vertices)
                    #expect(result.distance == Int(greatest))
                }
            }
        }
    }

    @Test("TA-501 – TA-510 centroid() agrees with component sizes after removing each vertex")
    func centroid() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 0 ... 1_000_000)) { choice, seed in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let tree = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            var expected: [Int] = []
            for v in tree.vertices {
                // The largest component of the tree without v, by search from each neighbour.
                var largest = 0
                var seen: Set<Int> = [v]
                for start in tree.neighbors(of: v) where !seen.contains(start) {
                    var stack = [start]
                    seen.insert(start)
                    var size = 0
                    while let x = stack.popLast() {
                        size += 1
                        for y in tree.neighbors(of: x) where !seen.contains(y) {
                            seen.insert(y)
                            stack.append(y)
                        }
                    }
                    largest = max(largest, size)
                }
                if 2 * largest <= n { expected.append(v) }
            }
            let centroid = tree.centroid()
            #expect(centroid == expected, "\(pairs) listed \(listed)")
            #expect(centroid.count == 1 || (centroid.count == 2 && tree.contains(edge: UndirectedEdge(centroid[0], centroid[1]))))
        }
    }

    @Test("TA-511 – TA-519 centroidDecomposition() agrees with a decomposition over vertex sets: parents, vertices order, edges, height ≤ ⌊log₂ n⌋")
    func centroidDecomposition() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 20)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 0 ... 1_000_000)) { choice, seed in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            guard let tree = Tree(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            // Components of a vertex set inside the tree.
            func components(of members: Set<Int>) -> [Set<Int>] {
                var left = members
                var result: [Set<Int>] = []
                for start in tree.vertices where left.contains(start) {
                    var component: Set<Int> = [start]
                    var stack = [start]
                    left.remove(start)
                    while let x = stack.popLast() {
                        for y in tree.neighbors(of: x) where left.contains(y) {
                            left.remove(y)
                            component.insert(y)
                            stack.append(y)
                        }
                    }
                    result.append(component)
                }
                return result
            }
            var parent: [Int: Int] = [:]
            var jobs: [(members: Set<Int>, above: Int?)] = [(Set(tree.vertices), nil)]
            while let (members, above) = jobs.popLast() {
                // The first vertex in `vertices` order whose removal leaves no part above half.
                guard let centroid = tree.vertices.first(where: { v in
                    members.contains(v) && components(of: members.subtracting([v])).allSatisfy { 2 * $0.count <= members.count }
                }) else {
                    Issue.record("no centroid in \(members)")
                    return
                }
                if let above { parent[centroid] = above }
                for part in components(of: members.subtracting([centroid])) { jobs.append((part, centroid)) }
            }
            let decomposition = tree.centroidDecomposition()
            #expect(Array(decomposition.vertices) == Array(tree.vertices))
            for v in tree.vertices { #expect(decomposition.parent(of: v) == parent[v], "parent of \(v) in \(pairs) listed \(listed)") }
            // Parent-function rule: one edge (parent, child) per non-root vertex, in vertex order.
            let expectedEnds = tree.vertices.compactMap { v in parent[v].map { [$0, v] } }
            #expect(decomposition.edges.map { [$0.u, $0.v] } == expectedEnds)
            #expect(decomposition.height <= Int(log2(Double(n))))
            #expect(decomposition.root == tree.centroid()[0])
        }
    }
}
