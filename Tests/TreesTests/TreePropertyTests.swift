// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Graphs are multigraphs with self-loops on 1 … 6 vertices; trees are grown from a list of
// attachment choices (vertex i + 1 hangs from choice mod (i + 1)), then their edges are shuffled,
// flipped and their vertices listed in a shuffled order by a seed, so positions, orientations and
// vertex order all vary. The oracles: union–find for recognition and components, in-degree counts
// and a breadth-first search for arborescences, recursion over position-ordered rows for preorder
// and postorder, a breadth-first parent map for paths, ancestor chains for `isAncestor`, the
// textbook least-leaf loop for Prüfer codes, and a parent-chain walk for parent arrays. api.md's
// equivalences (`isTree ⇔ Tree(g) != nil`, `isArborescence ⇔ Arborescence(g) != nil`,
// `isAcyclic ⇔ Forest(g) != nil`) are checked on every input. See README.md.

import Cycles
import Foundation
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Trees

@Suite("Tree properties against oracles, with shrinking", .tags(.randomized))
struct TreePropertyTests {
    @Test("isTree, Tree(g), Forest(g), isAcyclic, trees and component(of:) agree with union–find on random multigraphs")
    func undirectedRecognition() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 8)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 6)) { raw, size in
            let n = size
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // Union–find; acyclic when no edge joins two vertices already joined (a loop always does).
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            var acyclic = true
            for (a, b) in pairs {
                let (ra, rb) = (find(a), find(b))
                if ra == rb { acyclic = false } else { parent[max(ra, rb)] = min(ra, rb) }
            }
            let componentCount = (0 ..< n).filter { find($0) == $0 }.count
            let expectedTree = acyclic && componentCount == 1
            #expect(graph.isTree == expectedTree, "\(pairs) on \(n)")
            #expect((Tree(graph) != nil) == expectedTree, "\(pairs) on \(n)")
            #expect((Tree(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) != nil) == expectedTree)
            #expect(graph.isAcyclic == acyclic, "\(pairs) on \(n)")
            let forest = Forest(graph)
            #expect((forest != nil) == acyclic, "\(pairs) on \(n)")
            #expect((RootedTree(graph, root: n - 1) != nil) == expectedTree)
            guard let forest else { return }
            // Trees by least vertex: component offsets in order of each component's first vertex.
            var offsetOfRoot: [Int: Int] = [:]
            for v in 0 ..< n where offsetOfRoot[find(v)] == nil { offsetOfRoot[find(v)] = offsetOfRoot.count }
            #expect(forest.trees.count == componentCount)
            for v in 0 ..< n { #expect(forest.component(of: v) == offsetOfRoot[find(v)], "\(v) in \(pairs)") }
            for (offset, tree) in forest.trees.enumerated() {
                let members = (0 ..< n).filter { offsetOfRoot[find($0)] == offset }
                #expect(Array(tree.vertices) == members)
                let memberEdges = pairs.filter { offsetOfRoot[find($0.0)] == offset }
                #expect(Array(tree.edges) == memberEdges.map { UndirectedEdge($0.0, $0.1) })
            }
        }
    }

    @Test("isArborescence and Arborescence(g) agree with in-degree counts and a search from the root on random multidigraphs")
    func directedRecognition() async {
        let arcs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 7)
        await propertyCheck(count: 300, input: arcs, Gen.int(in: 1 ... 6)) { raw, size in
            let n = size
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            var inDegree = [Int](repeating: 0, count: n)
            for (_, b) in pairs { inDegree[b] += 1 }
            let roots = (0 ..< n).filter { inDegree[$0] == 0 }
            var expected = false
            if roots.count == 1, inDegree.allSatisfy({ $0 <= 1 }) {
                var reached: Set<Int> = [roots[0]]
                var queue = [roots[0]]
                while let v = queue.popLast() {
                    for (a, b) in pairs where a == v && !reached.contains(b) {
                        reached.insert(b)
                        queue.append(b)
                    }
                }
                expected = reached.count == n
            }
            #expect(graph.isArborescence == expected, "\(pairs) on \(n)")
            let arborescence = Arborescence(graph)
            #expect((arborescence != nil) == expected, "\(pairs) on \(n)")
            if let arborescence {
                #expect(arborescence.root == roots[0])
                #expect(Array(arborescence.edges) == pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
                // Read as undirected, an arborescence is a tree.
                #expect(graph.undirected.isTree)
            }
        }
    }

    @Test("Rooted queries agree with recursion over position-ordered rows on random trees, at a random root")
    func rootedQueries() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 9)
        await propertyCheck(count: 300, input: choices, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 1_000)) { choice, seed, rootChoice in
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
            let root = listed[rootChoice % n]
            let rooted = RootedTree(tree, root: root)
            // Rows in position order.
            func row(_ v: Int) -> [Int] { pairs.indices.filter { pairs[$0].0 == v || pairs[$0].1 == v } }
            func other(_ e: Int, _ v: Int) -> Int { pairs[e].0 == v ? pairs[e].1 : pairs[e].0 }
            var parentOf: [Int: Int] = [:]
            var parentEdgeOf: [Int: Int] = [:]
            var depthOf: [Int: Int] = [root: 0]
            var childrenOf: [Int: [Int]] = [:]
            var pre: [Int] = []
            var post: [Int] = []
            func visit(_ v: Int, _ arrivedBy: Int?) {
                pre.append(v)
                childrenOf[v] = []
                for e in row(v) where e != arrivedBy {
                    let w = other(e, v)
                    parentOf[w] = v
                    parentEdgeOf[w] = e
                    depthOf[w] = depthOf[v]! + 1
                    childrenOf[v]!.append(w)
                    visit(w, e)
                }
                post.append(v)
            }
            visit(root, nil)
            #expect(Array(rooted.preorder) == pre, "\(pairs) at \(root)")
            #expect(rooted.postorder == post, "\(pairs) at \(root)")
            #expect(rooted.height == depthOf.values.max())
            for v in 0 ..< n {
                #expect(rooted.parent(of: v) == parentOf[v])
                #expect(rooted.parentEdge(of: v) == parentEdgeOf[v])
                #expect(rooted.depth(of: v) == depthOf[v])
                #expect(Array(rooted.children(of: v)) == childrenOf[v])
                var chain: [Int] = []
                var x = v
                while let p = parentOf[x] {
                    chain.append(p)
                    x = p
                }
                #expect(Array(rooted.ancestors(of: v)) == chain)
                // The subtree in preorder: every vertex with v on its parent chain.
                let subtree = pre.filter { w in
                    var y = w
                    while let p = parentOf[y] {
                        if p == v { return true }
                        y = p
                    }
                    return false
                }
                #expect(Array(rooted.descendants(of: v)) == subtree, "descendants of \(v)")
                for w in 0 ..< n {
                    let strict = Array(rooted.ancestors(of: w)).contains(v)
                    #expect(rooted.isAncestor(v, of: w) == strict)
                }
            }
            // The arborescence and the round trips agree.
            let arborescence = Arborescence(rooted)
            #expect(Array(arborescence.preorder) == pre)
            #expect(arborescence.postorder == post)
            for e in pairs.indices {
                let (a, b) = pairs[e]
                let arc = arborescence.edges[e]
                #expect(arc == (parentOf[b] == a ? DirectedEdge(from: a, to: b) : DirectedEdge(from: b, to: a)))
            }
            #expect(RootedTree(arborescence) == rooted)
            #expect(Tree(rooted) == tree)
            #expect(Array(Tree(rooted).edges) == Array(tree.edges))
        }
    }

    @Test("path(from:to:) is the breadth-first path, with positions, on random trees; Forest and Arborescence agree")
    func paths() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 9)
        await propertyCheck(count: 300, input: choices, Gen.int(in: 0 ... 1_000_000)) { choice, seed in
            let n = choice.count + 1
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            guard let tree = Tree(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            let forest = Forest(tree)
            let arborescence = Arborescence(RootedTree(tree, root: 0))
            for a in 0 ..< n {
                // Breadth-first from a: the edge each vertex was reached by.
                var reachedBy: [Int: Int] = [:]
                var seen: Set<Int> = [a]
                var queue = [a]
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for e in pairs.indices where pairs[e].0 == v || pairs[e].1 == v {
                        let w = pairs[e].0 == v ? pairs[e].1 : pairs[e].0
                        if seen.insert(w).inserted {
                            reachedBy[w] = e
                            queue.append(w)
                        }
                    }
                }
                for b in 0 ..< n {
                    var vertices = [b]
                    var edges: [Int] = []
                    var x = b
                    while let e = reachedBy[x] {
                        edges.append(e)
                        x = pairs[e].0 == x ? pairs[e].1 : pairs[e].0
                        vertices.append(x)
                    }
                    vertices.reverse()
                    edges.reverse()
                    let path = tree.path(from: a, to: b)
                    #expect(path.vertices == vertices, "\(a) to \(b) in \(pairs)")
                    #expect(path.edges == edges, "\(a) to \(b) in \(pairs)")
                    #expect(forest.path(from: a, to: b) == path)
                    let down = arborescence.path(from: a, to: b)
                    #expect((down != nil) == (a == b || arborescence.isAncestor(a, of: b)))
                    if let down { #expect(down == path) }
                }
            }
        }
    }

    @Test("Prüfer: decoding then encoding is the identity; decoding agrees with the textbook least-leaf loop; codes of random trees decode back")
    func prufer() async {
        let codes = Gen.int(in: 0 ... 1_000).array(of: 0 ... 8)
        await propertyCheck(count: 300, input: codes, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = raw.count + 2
            let code = raw.map { $0 % n }
            guard let tree = Tree(pruferSequence: code) else {
                Issue.record("rejected \(code)")
                return
            }
            #expect(tree.pruferSequence == code)
            #expect(Array(tree.vertices) == Array(0 ..< n))
            // Textbook: n − 2 times join the least leaf (degree 1 in the remaining tree) to the next element.
            var degree = [Int](repeating: 1, count: n)
            for x in code { degree[x] += 1 }
            var removed = [Bool](repeating: false, count: n)
            var expected: [UndirectedEdge<Int>] = []
            for x in code {
                let leaf = (0 ..< n).first { !removed[$0] && degree[$0] == 1 }!
                expected.append(UndirectedEdge(leaf, x))
                removed[leaf] = true
                degree[x] -= 1
            }
            let last = (0 ..< n).filter { !removed[$0] }
            expected.append(UndirectedEdge(last[0], last[1]))
            #expect(Array(tree.edges) == expected, "\(code)")
            // Out of range elements are rejected.
            #expect(Tree(pruferSequence: code + [n + 1]) == nil)
            #expect(Tree(pruferSequence: [-1] + code) == nil)
            // List the vertices in a random order, vertex i written perm[i]: ranked by index, the code
            // is the original mapped through perm, whatever the values' order (TS-515's rule).
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let perm = Array(0 ..< n).shuffled(using: &rng)
            let relabeled = Tree(vertices: perm, edges: Array(tree.edges).map { UndirectedEdge(perm[$0.u], perm[$0.v]) })
            #expect(relabeled?.pruferSequence == code.map { perm[$0] })
        }
    }

    @Test("Parent arrays: Arborescence(parents:) and RootedTree(parents:) are non-nil exactly for one root and no cycle; edges one per non-root in vertex order")
    func parentArrays() async {
        let entries = Gen.int(in: -1 ... 6).optional(valueRate: 0.85).array(of: 0 ... 6)
        await propertyCheck(count: 400, input: entries) { parents in
            let n = parents.count
            let inRange = parents.allSatisfy { p in p.map { (0 ..< n).contains($0) } ?? true }
            let noSelf = parents.indices.allSatisfy { parents[$0] != $0 }
            let roots = parents.indices.filter { parents[$0] == nil }
            var valid = n > 0 && inRange && noSelf && roots.count == 1
            if valid {
                // Every vertex reaches the root by parents within n steps.
                for v in 0 ..< n {
                    var x = v
                    var steps = 0
                    while let p = parents[x], steps <= n {
                        x = p
                        steps += 1
                    }
                    if parents[x] != nil { valid = false }
                }
            }
            let arborescence = Arborescence(parents: parents)
            let rooted = RootedTree(parents: parents)
            #expect((arborescence != nil) == valid, "\(parents)")
            #expect((rooted != nil) == valid, "\(parents)")
            guard let arborescence, let rooted else { return }
            let expectedArcs = (0 ..< n).compactMap { v in parents[v].map { DirectedEdge(from: $0, to: v) } }
            #expect(Array(arborescence.edges) == expectedArcs)
            #expect(Array(rooted.edges) == expectedArcs.map { UndirectedEdge($0.source, $0.target) })
            #expect(arborescence.root == roots[0])
            #expect(rooted.root == roots[0])
            for v in 0 ..< n {
                #expect(arborescence.parent(of: v) == parents[v])
                #expect(rooted.parent(of: v) == parents[v])
                #expect(Array(rooted.children(of: v)) == (0 ..< n).filter { parents[$0] == v })
            }
            // The closure initializer with the same function is the same value.
            let viaClosure = Arborescence(vertices: 0 ..< n, parent: { parents[$0] })
            #expect(viaClosure == arborescence)
        }
    }

    @Test("Equality ignores edge order, orientation and vertex order; hashes agree; Codable round-trips")
    func equalityAndCoding() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 9)
        await propertyCheck(count: 200, input: choices, Gen.int(in: 1 ... 1_000_000)) { choice, seed in
            let n = choice.count + 1
            let pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let shuffled = pairs.shuffled(using: &rng).map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            guard let a = Tree(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }),
                  let b = Tree(vertices: listed, edges: shuffled.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            #expect(a == b)
            #expect(a.hashValue == b.hashValue)
            let root = Int.random(in: 0 ..< n, using: &rng)
            #expect(RootedTree(a, root: root) == RootedTree(b, root: root))
            #expect(RootedTree(a, root: root).hashValue == RootedTree(b, root: root).hashValue)
            #expect(Arborescence(RootedTree(a, root: root)) == Arborescence(RootedTree(b, root: root)))
            #expect(Forest(a) == Forest(b))
            if n > 1 {
                let otherRoot = (root + 1) % n
                #expect(RootedTree(a, root: root) != RootedTree(a, root: otherRoot))
                #expect(Arborescence(RootedTree(a, root: root)) != Arborescence(RootedTree(a, root: otherRoot)))
            }
            let decoded = try JSONDecoder().decode(Tree<Int>.self, from: JSONEncoder().encode(b))
            #expect(decoded == b)
            #expect(Array(decoded.vertices) == listed)
            #expect(Array(decoded.edges) == Array(b.edges))
            let rooted = RootedTree(b, root: root)
            let decodedRooted = try JSONDecoder().decode(RootedTree<Int>.self, from: JSONEncoder().encode(rooted))
            #expect(decodedRooted == rooted)
            #expect(Array(decodedRooted.preorder) == Array(rooted.preorder))
            let arborescence = Arborescence(rooted)
            let decodedArborescence = try JSONDecoder().decode(Arborescence<Int>.self, from: JSONEncoder().encode(arborescence))
            #expect(decodedArborescence == arborescence)
        }
    }
}
