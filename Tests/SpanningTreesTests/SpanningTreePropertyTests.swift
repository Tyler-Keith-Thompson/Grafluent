// Seeded random multigraphs against oracles written in each test: the forest laws, cycle and cut
// optimality, brute force, a stable-sort Kruskal for the tie rule, the documented edge orders, the
// total, and relabeling and permuting. n ∈ {1, 2, 5, 10, 30}, edge probability ∈ {0.05, 0.2, 0.5},
// 40 graphs per pair; self-loops always possible and a parallel copy (written the other way round)
// with probability 0.2. Case IDs (ST-nn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import SpanningTrees
import Testing

@Suite("Spanning-tree properties on random graphs", .tags(.randomized))
struct SpanningTreePropertyTests {
    @Test("ST-100 every result is a forest: acyclic, n − c edges, the graph's components, no self-loop, no repeat", arguments: [1, 2, 5, 10, 30])
    func forestLaws(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(100_000 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 40 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in u ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -5 ... 5, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((v, u, Int.random(in: -5 ... 5, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
                // The graph's components, by union–find over every edge.
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for edge in raw {
                    let (ru, rv) = (find(edge.0), find(edge.1))
                    if ru != rv { parent[ru] = rv }
                }
                let component = (0 ..< n).map { find($0) }
                let componentCount = Set(component).count

                func laws(_ forest: [Int], spanning vertices: [Int], _ name: String) {
                    #expect(Set(forest).count == forest.count, "\(name) repeats a position: \(raw)")
                    #expect(forest.allSatisfy { raw[$0].0 != raw[$0].1 }, "\(name) has a self-loop: \(raw)")
                    let components = Set(vertices.map { component[$0] }).count
                    #expect(forest.count == vertices.count - components, "\(name): \(raw)")
                    var forestParent = Array(0 ..< n)
                    func forestFind(_ x: Int) -> Int {
                        var x = x
                        while forestParent[x] != x { x = forestParent[x] }
                        return x
                    }
                    for position in forest {
                        let (ru, rv) = (forestFind(raw[position].0), forestFind(raw[position].1))
                        #expect(ru != rv, "\(name): position \(position) closes a cycle: \(raw)")
                        forestParent[ru] = rv
                        #expect(vertices.contains(raw[position].0), "\(name): position \(position) is outside: \(raw)")
                    }
                    // The forest joins the endpoints of every graph edge among the vertices spanned.
                    for edge in raw where vertices.contains(edge.0) {
                        #expect(forestFind(edge.0) == forestFind(edge.1), "\(name): \(edge) not joined: \(raw)")
                    }
                }
                let everyVertex = Array(0 ..< n)
                laws(graph.minimumSpanningTree { raw[$0].2 }.edges, spanning: everyVertex, "default")
                laws(graph.kruskalMinimumSpanningTree { raw[$0].2 }.edges, spanning: everyVertex, "Kruskal")
                laws(graph.primMinimumSpanningTree { raw[$0].2 }.edges, spanning: everyVertex, "Prim")
                laws(graph.boruvkaMinimumSpanningTree { raw[$0].2 }.edges, spanning: everyVertex, "Borůvka")
                laws(graph.maximumSpanningTree { raw[$0].2 }.edges, spanning: everyVertex, "maximum")
                laws(graph.minimumSpanningTree().edges, spanning: everyVertex, "unweighted")
                #expect(graph.minimumSpanningTree().edges.count == n - componentCount)
                let root = Int.random(in: 0 ..< n, using: &rng)
                let rootComponent = (0 ..< n).filter { component[$0] == component[root] }
                laws(graph.primMinimumSpanningTree(from: root) { raw[$0].2 }.edges, spanning: rootComponent, "Prim from \(root)")
            }
        }
    }

    @Test("ST-101 cycle and cut optimality, for the minimum and the maximum", arguments: [1, 2, 5, 10, 30])
    func optimality(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(101_000 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 40 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in u ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -5 ... 5, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((v, u, Int.random(in: -5 ... 5, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })

                func check(_ forest: [Int], maximum: Bool, _ name: String) {
                    // `a` is no worse than `b`: lighter for the minimum, heavier for the maximum.
                    func noWorse(_ a: Int, _ b: Int) -> Bool { maximum ? a >= b : a <= b }
                    var adjacent = [[(Int, Int)]](repeating: [], count: n)
                    for position in forest {
                        adjacent[raw[position].0].append((raw[position].1, position))
                        adjacent[raw[position].1].append((raw[position].0, position))
                    }
                    // The tree edges on the path from `a` to `b`, or nil when there is none.
                    func treePath(_ a: Int, _ b: Int) -> [Int]? {
                        var via = [Int?](repeating: nil, count: n)
                        var seen = [Bool](repeating: false, count: n)
                        var stack = [a]
                        seen[a] = true
                        while let x = stack.popLast() {
                            for (y, position) in adjacent[x] where !seen[y] {
                                seen[y] = true
                                via[y] = position
                                stack.append(y)
                            }
                        }
                        guard seen[b] else { return nil }
                        var path: [Int] = []
                        var x = b
                        while x != a, let position = via[x] {
                            path.append(position)
                            x = raw[position].0 == x ? raw[position].1 : raw[position].0
                        }
                        return path
                    }
                    let inForest = Set(forest)
                    // Cycle optimality: a non-tree edge is no better than any tree edge it would replace.
                    for (position, edge) in raw.enumerated() where edge.0 != edge.1 && !inForest.contains(position) {
                        guard let path = treePath(edge.0, edge.1) else {
                            Issue.record("\(name): \(edge) has endpoints in different trees: \(raw)")
                            continue
                        }
                        #expect(path.allSatisfy { noWorse(raw[$0].2, edge.2) }, "\(name): \(edge) beats its cycle: \(raw)")
                    }
                    // Cut optimality: a tree edge is no worse than any edge across the cut it defines.
                    for treeEdge in forest {
                        var side = Set([raw[treeEdge].0])
                        var stack = [raw[treeEdge].0]
                        while let x = stack.popLast() {
                            for (y, position) in adjacent[x] where position != treeEdge && !side.contains(y) {
                                side.insert(y)
                                stack.append(y)
                            }
                        }
                        for edge in raw where side.contains(edge.0) != side.contains(edge.1) {
                            #expect(noWorse(raw[treeEdge].2, edge.2), "\(name): \(edge) beats tree edge \(treeEdge) across its cut: \(raw)")
                        }
                    }
                }
                check(graph.minimumSpanningTree { raw[$0].2 }.edges, maximum: false, "default")
                check(graph.primMinimumSpanningTree { raw[$0].2 }.edges, maximum: false, "Prim")
                check(graph.boruvkaMinimumSpanningTree { raw[$0].2 }.edges, maximum: false, "Borůvka")
                check(graph.maximumSpanningTree { raw[$0].2 }.edges, maximum: true, "maximum")
            }
        }
    }

    @Test("ST-102 the weight equals brute-force enumeration on ≤ 8 vertices and ≤ 12 edges", arguments: 0 ..< 5)
    func bruteForce(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(102_000 + seed))
        for _ in 0 ..< 60 {
            let n = Int.random(in: 1 ... 8, using: &rng)
            let m = Int.random(in: 0 ... 12, using: &rng)
            let raw = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: -9 ... 9, using: &rng)) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let candidates = raw.indices.filter { raw[$0].0 != raw[$0].1 }
            // n − c, from the components.
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for edge in raw {
                let (ru, rv) = (find(edge.0), find(edge.1))
                if ru != rv { parent[ru] = rv }
            }
            let size = n - (0 ..< n).filter { find($0) == $0 }.count
            // Every set of `size` non-loop edges that is a forest is a spanning forest.
            var lightest: Int?
            var heaviest: Int?
            var chosen: [Int] = []
            func extend(from start: Int) {
                if chosen.count == size {
                    var forestParent = Array(0 ..< n)
                    func forestFind(_ x: Int) -> Int {
                        var x = x
                        while forestParent[x] != x { x = forestParent[x] }
                        return x
                    }
                    for position in chosen {
                        let (ru, rv) = (forestFind(raw[position].0), forestFind(raw[position].1))
                        if ru == rv { return }
                        forestParent[ru] = rv
                    }
                    let total = chosen.reduce(0) { $0 + raw[$1].2 }
                    lightest = min(lightest ?? total, total)
                    heaviest = max(heaviest ?? total, total)
                    return
                }
                guard start < candidates.count else { return }
                for i in start ..< candidates.count {
                    chosen.append(candidates[i])
                    extend(from: i + 1)
                    chosen.removeLast()
                }
            }
            extend(from: 0)
            #expect(graph.minimumSpanningTree { raw[$0].2 }.weight == lightest, "\(raw)")
            #expect(graph.kruskalMinimumSpanningTree { raw[$0].2 }.weight == lightest, "\(raw)")
            #expect(graph.primMinimumSpanningTree { raw[$0].2 }.weight == lightest, "\(raw)")
            #expect(graph.boruvkaMinimumSpanningTree { raw[$0].2 }.weight == lightest, "\(raw)")
            #expect(graph.maximumSpanningTree { raw[$0].2 }.weight == heaviest, "\(raw)")
        }
    }

    @Test("ST-103 the tie rule: the default, Kruskal and Borůvka equal a stable-sort Kruskal on weights in {0, 1, 2}", arguments: [1, 2, 5, 10, 30])
    func tieRule(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(103_000 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 40 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in u ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: 0 ... 2, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((v, u, Int.random(in: 0 ... 2, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
                // Swift's sort is not documented as stable, so the position is the second key.
                func stableKruskal(maximum: Bool) -> [Int] {
                    let order = raw.indices.filter { raw[$0].0 != raw[$0].1 }.sorted {
                        raw[$0].2 != raw[$1].2 ? (raw[$0].2 < raw[$1].2) != maximum : $0 < $1
                    }
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    var taken: [Int] = []
                    for position in order {
                        let (ru, rv) = (find(raw[position].0), find(raw[position].1))
                        if ru != rv {
                            parent[ru] = rv
                            taken.append(position)
                        }
                    }
                    return taken
                }
                let minimum = stableKruskal(maximum: false)
                #expect(graph.minimumSpanningTree { raw[$0].2 }.edges == minimum, "\(raw)")
                #expect(graph.kruskalMinimumSpanningTree { raw[$0].2 }.edges == minimum, "\(raw)")
                let boruvka = graph.boruvkaMinimumSpanningTree { raw[$0].2 }.edges
                #expect(boruvka.count == minimum.count, "\(raw)")
                #expect(Set(boruvka) == Set(minimum), "\(raw)")
                #expect(graph.maximumSpanningTree { raw[$0].2 }.edges == stableKruskal(maximum: true), "\(raw)")
            }
        }
    }

    @Test("ST-104 edge order: Kruskal by (weight, position), the maximum by (−weight, position), Prim by joining", arguments: [1, 2, 5, 10, 30])
    func edgeOrder(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(104_000 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 40 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in u ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -3 ... 3, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((v, u, Int.random(in: -3 ... 3, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
                let kruskal = graph.kruskalMinimumSpanningTree { raw[$0].2 }.edges
                #expect(zip(kruskal, kruskal.dropFirst()).allSatisfy { (raw[$0].2, $0) < (raw[$1].2, $1) }, "\(kruskal): \(raw)")
                let maximum = graph.maximumSpanningTree { raw[$0].2 }.edges
                #expect(zip(maximum, maximum.dropFirst()).allSatisfy { (-raw[$0].2, $0) < (-raw[$1].2, $1) }, "\(maximum): \(raw)")
                let unweighted = graph.minimumSpanningTree().edges
                #expect(zip(unweighted, unweighted.dropFirst()).allSatisfy { $0 < $1 }, "\(unweighted): \(raw)")

                // Prim: each edge joins a spanned vertex to a new one; a new tree starts at the
                // first unspanned vertex, in vertices order, that has a non-loop edge.
                let touched = Set(raw.filter { $0.0 != $0.1 }.flatMap { [$0.0, $0.1] })
                let prim = graph.primMinimumSpanningTree { raw[$0].2 }.edges
                var spanned = Set<Int>()
                for position in prim {
                    let (u, v, _) = raw[position]
                    if !spanned.contains(u) && !spanned.contains(v) {
                        let restart = (0 ..< n).first { !spanned.contains($0) && touched.contains($0) }
                        #expect(restart == u || restart == v, "Prim restarted at the wrong vertex: \(prim): \(raw)")
                        if let restart { spanned.insert(restart) }
                    }
                    #expect(spanned.contains(u) != spanned.contains(v), "Prim's \(position) does not join a new vertex: \(prim): \(raw)")
                    spanned.formUnion([u, v])
                }
                // From a root: the first edge leaves the root, and every edge joins a new vertex.
                let root = Int.random(in: 0 ..< n, using: &rng)
                var reached: Set = [root]
                for position in graph.primMinimumSpanningTree(from: root, weight: { raw[$0].2 }).edges {
                    let (u, v, _) = raw[position]
                    #expect(reached.contains(u) != reached.contains(v), "Prim from \(root): \(raw)")
                    reached.formUnion([u, v])
                }
            }
        }
    }

    @Test("ST-105 weight is the sum of the edges' weights, and edges.count is n − c", arguments: [1, 2, 5, 10, 30])
    func totals(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(105_000 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 40 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in u ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -1000 ... 1000, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((v, u, Int.random(in: -1000 ... 1000, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for edge in raw {
                    let (ru, rv) = (find(edge.0), find(edge.1))
                    if ru != rv { parent[ru] = rv }
                }
                let size = n - (0 ..< n).filter { find($0) == $0 }.count
                let forests = [
                    ("default", graph.minimumSpanningTree { raw[$0].2 }),
                    ("Kruskal", graph.kruskalMinimumSpanningTree { raw[$0].2 }),
                    ("Prim", graph.primMinimumSpanningTree { raw[$0].2 }),
                    ("Borůvka", graph.boruvkaMinimumSpanningTree { raw[$0].2 }),
                    ("maximum", graph.maximumSpanningTree { raw[$0].2 }),
                ]
                for (name, forest) in forests {
                    #expect(forest.weight == forest.edges.reduce(0) { $0 + raw[$1].2 }, "\(name): \(raw)")
                    #expect(forest.edges.count == size, "\(name): \(raw)")
                }
                let unweighted = graph.minimumSpanningTree()
                #expect(unweighted.weight == unweighted.edges.count)
                #expect(unweighted.edges.count == size)
                let root = Int.random(in: 0 ..< n, using: &rng)
                let rooted = graph.primMinimumSpanningTree(from: root) { raw[$0].2 }
                #expect(rooted.weight == rooted.edges.reduce(0) { $0 + raw[$1].2 })
                #expect(rooted.edges.count == (0 ..< n).filter { find($0) == find(root) }.count - 1)
            }
        }
    }

    @Test("ST-106 relabeling and reversing change nothing; permuting positions changes the forest only among ties", arguments: [1, 2, 5, 10, 30])
    func invariance(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(106_000 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 40 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in u ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -3 ... 3, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((v, u, Int.random(in: -3 ... 3, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
                let tree = graph.minimumSpanningTree { raw[$0].2 }

                // Vertex i becomes label[i], and every edge is written the other way round: the
                // positions and weights are the same, so the canonical forest is too.
                let label = (0 ..< n).map { 1000 + 7 * $0 }.shuffled(using: &rng)
                let relabeled = ReferencePseudograph(vertices: label, edges: raw.map { UndirectedEdge(label[$0.1], label[$0.0]) })
                #expect(relabeled.minimumSpanningTree { raw[$0].2 }.edges == tree.edges, "\(raw)")
                #expect(relabeled.minimumSpanningTree { raw[$0].2 }.weight == tree.weight, "\(raw)")
                #expect(Set(relabeled.boruvkaMinimumSpanningTree { raw[$0].2 }.edges) == Set(tree.edges), "\(raw)")
                #expect(relabeled.primMinimumSpanningTree { raw[$0].2 }.weight == tree.weight, "\(raw)")
                #expect(relabeled.maximumSpanningTree { raw[$0].2 }.edges == graph.maximumSpanningTree { raw[$0].2 }.edges, "\(raw)")

                // Position j of the permuted graph is position order[j] of the original.
                let order = Array(raw.indices).shuffled(using: &rng)
                let permuted = ReferencePseudograph(vertices: 0 ..< n, edges: order.map { UndirectedEdge(raw[$0].0, raw[$0].1) })
                let permutedTree = permuted.minimumSpanningTree { raw[order[$0]].2 }
                #expect(permutedTree.weight == tree.weight, "\(raw)")
                // Every minimum spanning forest has the same multiset of weights.
                #expect(permutedTree.edges.map { raw[order[$0]].2 }.sorted() == tree.edges.map { raw[$0].2 }.sorted(), "\(raw)")
                // With distinct weights the forest is unique, so it is the same edges.
                let distinct = raw.indices.map { 10 * $0 + raw[$0].2 }
                let unique = graph.minimumSpanningTree { distinct[$0] }
                let permutedUnique = permuted.minimumSpanningTree { distinct[order[$0]] }
                #expect(Set(permutedUnique.edges.map { order[$0] }) == Set(unique.edges), "\(raw)")
            }
        }
    }
}

@Suite("Spanning-tree properties with shrinking", .tags(.randomized))
struct SpanningTreeShrinkingPropertyTests {
    @Test("ST-107 forest laws, cycle optimality and the tie rule together: a failure shrinks to a small edge list")
    func lawsWithShrinking() async {
        // Up to 24 edges on vertices 0..<8 with weights 0...3, so ties are common; repeats and
        // self-loops allowed. On a failure, PropertyBased shrinks the edge list and prints the
        // smallest one that still fails.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 8
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            // The canonical forest: a Kruskal over (weight, position).
            let order = raw.indices.filter { raw[$0].0 != raw[$0].1 }.sorted { (raw[$0].2, $0) < (raw[$1].2, $1) }
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            var canonical: [Int] = []
            for position in order {
                let (ru, rv) = (find(raw[position].0), find(raw[position].1))
                if ru != rv {
                    parent[ru] = rv
                    canonical.append(position)
                }
            }
            let tree = graph.minimumSpanningTree { raw[$0].2 }
            #expect(tree.edges == canonical)
            #expect(tree.weight == canonical.reduce(0) { $0 + raw[$1].2 })
            #expect(Set(graph.boruvkaMinimumSpanningTree { raw[$0].2 }.edges) == Set(canonical))

            let prim = graph.primMinimumSpanningTree { raw[$0].2 }
            #expect(prim.weight == tree.weight)
            #expect(prim.edges.count == canonical.count)
            for forest in [tree.edges, prim.edges] {
                // Acyclic, with no self-loop.
                var forestParent = Array(0 ..< n)
                func forestFind(_ x: Int) -> Int {
                    var x = x
                    while forestParent[x] != x { x = forestParent[x] }
                    return x
                }
                var adjacent = [[(Int, Int)]](repeating: [], count: n)
                for position in forest {
                    #expect(raw[position].0 != raw[position].1)
                    let (ru, rv) = (forestFind(raw[position].0), forestFind(raw[position].1))
                    #expect(ru != rv, "position \(position) closes a cycle")
                    forestParent[ru] = rv
                    adjacent[raw[position].0].append((raw[position].1, position))
                    adjacent[raw[position].1].append((raw[position].0, position))
                }
                // Cycle optimality: every tree edge on a non-tree edge's tree path is no heavier.
                for (position, edge) in raw.enumerated() where edge.0 != edge.1 && !forest.contains(position) {
                    var via = [Int?](repeating: nil, count: n)
                    var seen = [Bool](repeating: false, count: n)
                    var stack = [edge.0]
                    seen[edge.0] = true
                    while let x = stack.popLast() {
                        for (y, treeEdge) in adjacent[x] where !seen[y] {
                            seen[y] = true
                            via[y] = treeEdge
                            stack.append(y)
                        }
                    }
                    #expect(seen[edge.1], "\(edge) joins two trees")
                    var x = edge.1
                    while x != edge.0, let treeEdge = via[x] {
                        #expect(raw[treeEdge].2 <= edge.2, "\(edge) is lighter than tree edge \(treeEdge)")
                        x = raw[treeEdge].0 == x ? raw[treeEdge].1 : raw[treeEdge].0
                    }
                }
            }
        }
    }
}
