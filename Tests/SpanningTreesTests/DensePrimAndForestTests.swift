// Dense Prim, which `minimumSpanningTree(weight:)` runs on a graph with vertex indices and at
// least n²/4 edges (and at least 4n, its threshold for Prim over Kruskal), and the conversion
// `Forest(_:in:)`. Dense cases are built to clear both thresholds: complete graphs from K₉ up, a
// doubled K₉ with self-loops, K₁₂ + K₂ and K₁₀ plus an isolated vertex. Case IDs (ST-nn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import SpanningTrees
import Testing
import Trees

@Suite("Dense Prim")
struct DensePrimTests {
    @Test("ST-135 complete graphs K₉…K₁₆ with tied weights: the canonical forest, as Kruskal gives it", arguments: 9 ... 16)
    func completeGraphs(n: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(n))
        let pairs = (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        // Weights 0...3, so most comparisons are ties broken by position.
        let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 0 ... 3, using: &generator) }
        let dense = graph.minimumSpanningTree { weights[$0] }
        let kruskal = graph.kruskalMinimumSpanningTree { weights[$0] }
        #expect(dense == kruskal)
        #expect(dense.edges.count == n - 1)
        // Listed in nondecreasing (weight, position).
        for (a, b) in zip(dense.edges, dense.edges.dropFirst()) {
            #expect(weights[a] < weights[b] || (weights[a] == weights[b] && a < b))
        }
    }

    @Test("ST-136 all weights equal: the first n − 1 positions that make a forest, here the star at vertex 0")
    func allTied() {
        let n = 10
        let pairs = (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        let tree = graph.minimumSpanningTree { _ in 7 }
        // Positions 0…8 are the edges (0, 1)…(0, 9).
        #expect(tree.edges == Array(0 ..< n - 1))
        #expect(tree.weight == 7 * (n - 1))
    }

    @Test("ST-137 one strictly lightest path through a complete graph: exactly that path")
    func hiddenPath() {
        let n = 12
        let pairs = (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        // The path 11 – 10 – … – 0 weighs 1 per edge; every other edge 100. The last vertex is
        // reached from the far end, so a scan that stopped early or kept a stale key would differ.
        let weights = graph.edges.map { $0.v == $0.u + 1 ? 1 : 100 }
        let tree = graph.minimumSpanningTree { weights[$0] }
        #expect(tree.weight == n - 1)
        #expect(Set(tree.edges.map { graph.edges[$0] }) == Set((0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
        #expect(tree == graph.kruskalMinimumSpanningTree { weights[$0] })
    }

    @Test("ST-138 a later, lighter edge replaces a vertex's key")
    func keyDecreases() {
        // K₉, vertex 0's edges heavy except (0, 1); (1, v) light for v ≥ 2. Each v's first key comes
        // from 0 and must drop when 1 joins.
        let n = 9
        let pairs = (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        let weights = graph.edges.map { edge -> Int in
            if edge == UndirectedEdge(0, 1) { return 0 }
            if edge.u == 0 { return 50 }
            if edge.u == 1 { return 1 }
            return 90
        }
        let tree = graph.minimumSpanningTree { weights[$0] }
        #expect(tree.weight == n - 2)
        #expect(Set(tree.edges.map { graph.edges[$0] }) == Set([UndirectedEdge(0, 1)] + (2 ..< n).map { UndirectedEdge(1, $0) }))
    }

    @Test("ST-139 a doubled K₉ with self-loops: parallel ties go to the earlier position, loops are never taken or weighed")
    func parallelAndLoops() {
        let n = 9
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< n {
            edges.append(UndirectedEdge(u, u))
            for v in u + 1 ..< n {
                edges.append(UndirectedEdge(u, v))
                edges.append(UndirectedEdge(v, u))
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        var generator = SeededRandomNumberGenerator(seed: 139)
        // Each parallel pair equal, so only the position breaks the tie.
        var weights = [Int](repeating: 0, count: graph.edgeCount)
        var loops = Set<Int>()
        for position in graph.edges.indices {
            let edge = graph.edges[position]
            if edge.u == edge.v {
                loops.insert(position)
                weights[position] = -1_000
            }
        }
        var pairWeight: [UndirectedEdge<Int>: Int] = [:]
        for position in graph.edges.indices where !loops.contains(position) {
            let edge = graph.edges[position]
            let key = UndirectedEdge(min(edge.u, edge.v), max(edge.u, edge.v))
            if pairWeight[key] == nil { pairWeight[key] = Int.random(in: 0 ... 2, using: &generator) }
            weights[position] = pairWeight[key]!
        }
        var calls: [Int: Int] = [:]
        let tree = graph.minimumSpanningTree { position in
            calls[position, default: 0] += 1
            return weights[position]
        }
        #expect(tree == graph.kruskalMinimumSpanningTree { weights[$0] })
        #expect(tree.edges.count == n - 1)
        #expect(tree.edges.allSatisfy { !loops.contains($0) })
        // Each non-loop edge weighed exactly once, no loop at all.
        #expect(calls.count == graph.edgeCount - loops.count)
        #expect(calls.values.allSatisfy { $0 == 1 })
        #expect(calls.keys.allSatisfy { !loops.contains($0) })
        // Of each parallel pair, the earlier position.
        for position in tree.edges {
            let edge = graph.edges[position]
            let twins = graph.edges.indices.filter { Set([graph.edges[$0].u, graph.edges[$0].v]) == Set([edge.u, edge.v]) }
            #expect(position == twins.min())
        }
    }

    @Test("ST-140 disconnected dense graphs: K₁₂ + K₂, and K₁₀ with an isolated vertex")
    func disconnected() {
        var edges = (0 ..< 12).flatMap { u in (u + 1 ..< 12).map { UndirectedEdge(u, $0) } }
        edges.append(UndirectedEdge(12, 13))
        let two = UndirectedAdjacencyList(vertices: 0 ..< 14, edges: edges)
        var generator = SeededRandomNumberGenerator(seed: 140)
        let weights = (0 ..< two.edgeCount).map { _ in Int.random(in: -5 ... 5, using: &generator) }
        let forest = two.minimumSpanningTree { weights[$0] }
        #expect(forest == two.kruskalMinimumSpanningTree { weights[$0] })
        #expect(forest.edges.count == 12)
        #expect(forest.edges.contains(two.edges.count - 1))

        let isolated = UndirectedAdjacencyList(vertices: 0 ..< 11, edges: (0 ..< 10).flatMap { u in (u + 1 ..< 10).map { UndirectedEdge(u, $0) } })
        let w = (0 ..< isolated.edgeCount).map { _ in Int.random(in: 0 ... 9, using: &generator) }
        let spanning = isolated.minimumSpanningTree { w[$0] }
        #expect(spanning == isolated.kruskalMinimumSpanningTree { w[$0] })
        #expect(spanning.edges.count == 9)
        // Vertex 10 first in the order: an isolated vertex scanned before the big component.
        let first = UndirectedAdjacencyList(vertices: [10] + Array(0 ..< 10), edges: (0 ..< 10).flatMap { u in (u + 1 ..< 10).map { UndirectedEdge(u, $0) } })
        #expect(first.minimumSpanningTree { w[$0] } == first.kruskalMinimumSpanningTree { w[$0] })
    }

    @Test("ST-141 vertex indices without edge indices (AdjacencyMatrix.undirectedView, ReferencePseudograph): ranks are offsets in edges")
    func withoutEdgeIndices() {
        let n = 10
        var generator = SeededRandomNumberGenerator(seed: 141)
        let arcs = (0 ..< n).flatMap { u in (u + 1 ..< n).map { DirectedEdge(from: u, to: $0) } }
        let matrix = AdjacencyMatrix(vertexCount: n, edges: arcs).undirectedView
        let offset = Dictionary(uniqueKeysWithValues: matrix.edges.indices.enumerated().map { ($1, $0) })
        let weights = (0 ..< matrix.edgeCount).map { _ in Int.random(in: 0 ... 2, using: &generator) }
        let tree = matrix.minimumSpanningTree { weights[offset[$0]!] }
        #expect(tree == matrix.kruskalMinimumSpanningTree { weights[offset[$0]!] })
        #expect(tree.edges.count == n - 1)

        let reference = ReferencePseudograph(vertices: 0 ..< n, edges: arcs.map { UndirectedEdge($0.source, $0.target) } + arcs.map { UndirectedEdge($0.target, $0.source) })
        let doubled = (0 ..< reference.edgeCount).map { _ in Int.random(in: 0 ... 2, using: &generator) }
        let referenceTree = reference.minimumSpanningTree { doubled[$0] }
        #expect(referenceTree == reference.kruskalMinimumSpanningTree { doubled[$0] })
    }

    @Test("ST-142 infinite and negative weights are ordinary weights")
    func infinities() {
        let n = 9
        let pairs = (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        var generator = SeededRandomNumberGenerator(seed: 142)
        // Every edge at vertex 8 is +∞, so the tree takes exactly one of them.
        let finite: [Double] = [-1.5, 0, 2.25]
        let up = graph.edges.map { $0.v == 8 ? Double.infinity : finite.randomElement(using: &generator)! }
        let tree = graph.minimumSpanningTree { up[$0] }
        #expect(tree == graph.kruskalMinimumSpanningTree { up[$0] })
        #expect(tree.weight == .infinity)
        #expect(tree.edges.filter { up[$0] == .infinity }.count == 1)
        // −∞ on a random third of the edges: as many as a forest can hold are taken.
        let down = graph.edges.map { _ in Int.random(in: 0 ..< 3, using: &generator) == 0 ? -Double.infinity : finite.randomElement(using: &generator)! }
        let low = graph.minimumSpanningTree { down[$0] }
        #expect(low == graph.kruskalMinimumSpanningTree { down[$0] })
        #expect(low.weight == -.infinity)
    }

    @Test("ST-143 a NaN weight traps on the dense path", .tags(.precondition))
    func nan() async {
        await #expect(processExitsWith: .failure) {
            let n = 9
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } })
            _ = graph.minimumSpanningTree { $0 == 20 ? Double.nan : 1 }
        }
    }
}

@Suite("Prim over a heap, between the two thresholds")
struct HeapCanonicalPrimTests {
    @Test("ST-149 30 vertices and 150 edges (4n ≤ m < n²/4): the heap's canonical forest, with and without edge indices", arguments: 0 ..< 6)
    func betweenThresholds(seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(149 + seed))
        let n = 30
        let raw = (0 ..< 150).map { _ in (Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ... 3, using: &generator)) }
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
        let reference = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
        let tree = reference.minimumSpanningTree { raw[$0].2 }
        #expect(tree.edges == canonical)
        #expect(tree.weight == canonical.reduce(0) { $0 + raw[$1].2 })
        let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
        #expect(list.minimumSpanningTree { raw[$0].2 } == list.kruskalMinimumSpanningTree { raw[$0].2 })
    }
}

@Suite("Paths the dense one no longer covers")
struct BelowTheDenseThresholdTests {
    @Test("ST-150 AdjacencyMatrix.undirectedView with 4n ≤ m < n²/4: the heap's ranks are offsets in edges")
    func matrixBetweenThresholds() {
        var generator = SeededRandomNumberGenerator(seed: 150)
        let n = 30
        var arcs = Set<DirectedEdge<Int>>()
        while arcs.count < 160 {
            let u = Int.random(in: 0 ..< n, using: &generator), v = Int.random(in: 0 ..< n, using: &generator)
            if u < v { arcs.insert(DirectedEdge(from: u, to: v)) }
        }
        let matrix = AdjacencyMatrix(vertexCount: n, edges: Array(arcs)).undirectedView
        let offset = Dictionary(uniqueKeysWithValues: matrix.edges.indices.enumerated().map { ($1, $0) })
        // Two weights only, so nearly every comparison is a tie broken by offset.
        let weights = (0 ..< matrix.edgeCount).map { _ in Int.random(in: 0 ... 1, using: &generator) }
        let tree = matrix.minimumSpanningTree { weights[offset[$0]!] }
        #expect(tree == matrix.kruskalMinimumSpanningTree { weights[offset[$0]!] })
    }

    @Test("ST-151 between the thresholds the total is added in the listed order, not in Prim's, which would overflow")
    func heapTotalOrder() {
        // 0 – 1 weighs Int.max − 10, 1 – 2 weighs 20, 2 – 3 weighs −100, and 3 joins 121 edges of
        // weight 0 among 3…29. Prim from 0 meets Int.max − 10 and then 20; the listed order adds
        // −100 first.
        let n = 30
        var edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]
        var weights = [Int.max - 10, 20, -100]
        outer: for u in 3 ..< n {
            for v in u + 1 ..< n {
                edges.append(UndirectedEdge(u, v))
                weights.append(0)
                if edges.count == 124 { break outer }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        #expect(graph.edgeCount >= 4 * n && graph.edgeCount < n * n / 4)
        let tree = graph.minimumSpanningTree { weights[$0] }
        #expect(tree.weight == Int.max - 90)
        #expect(tree == graph.kruskalMinimumSpanningTree { weights[$0] })
    }

    @Test("ST-152 a NaN weight traps where ranks come from walking edges (vertex indices without edge indices)", .tags(.precondition))
    func nanWithoutEdgeIndices() async {
        // A triangle weighing 1, 2 and NaN by offset: the NaN edge sorts last (its comparisons are
        // ties, broken by offset) and closes a cycle, so it is never taken; only the check traps.
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)]).undirectedView
            let offset = Dictionary(uniqueKeysWithValues: matrix.edges.indices.enumerated().map { ($1, $0) })
            let weights = [1, 2, Double.nan]
            _ = matrix.kruskalMinimumSpanningTree { weights[offset[$0]!] }
        }
    }
}

@Suite("Dense Prim properties", .tags(.randomized))
struct DensePrimPropertyTests {
    @Test("ST-144 dense random multigraphs on 9 vertices: the canonical forest of a reference Kruskal over (weight, offset)")
    func againstReference() async {
        // 36…80 edges on 9 vertices clears both thresholds (4n = 36, n²/4 = 20); repeats and
        // self-loops allowed, weights 0...3 so ties are common.
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 3)).array(of: 36 ... 80)
        await propertyCheck(count: 200, input: edges) { raw in
            let n = 9
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
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
            // With edge indices: the same forest Kruskal gives.
            #expect(list.minimumSpanningTree { raw[$0].2 } == list.kruskalMinimumSpanningTree { raw[$0].2 })
        }
    }
}

@Suite("Forest(_:in:)")
struct SpanningForestConversionTests {
    @Test("ST-145 the vertices in graph order, the edges in forest order, each as the graph holds it")
    func roundTrip() {
        // Two components and an isolated vertex, listed out of numeric order.
        let edges = [UndirectedEdge(5, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 5), UndirectedEdge(3, 4), UndirectedEdge(0, 0)]
        let graph = UndirectedAdjacencyList(vertices: [5, 3, 0, 1, 2, 4, 6], edges: edges)
        let weights = [3, 1, 2, 7, -1]
        let spanning = graph.minimumSpanningTree { weights[$0] }
        let forest = Forest(spanning, in: graph)
        #expect(Array(forest.vertices) == Array(graph.vertices))
        #expect(forest.edgeCount == spanning.edges.count)
        for (k, position) in spanning.edges.enumerated() { #expect(forest.edges[k] == graph.edges[position]) }
        // {5, 1, 2}, {3, 4} and the one-vertex trees {0} and {6}: c = n − (n − c).
        #expect(forest.trees.count == graph.vertexCount - spanning.edges.count)
        #expect(forest.component(of: 0) != forest.component(of: 6))
        #expect(forest.component(of: 5) == forest.component(of: 2))
        #expect(forest.component(of: 3) == forest.component(of: 4))
        #expect(forest.component(of: 3) != forest.component(of: 1))
        // A path in the forest uses only forest edges.
        let path = forest.path(from: 5, to: 2)!
        #expect(path.vertices.first == 5 && path.vertices.last == 2)
        #expect(forest.path(from: 0, to: 6) == nil)
    }

    @Test("ST-146 every algorithm's forest converts, on Int 0..<n and on String vertices")
    func everyAlgorithm() {
        var generator = SeededRandomNumberGenerator(seed: 146)
        let n = 12
        var pairs: [UndirectedEdge<Int>] = []
        for _ in 0 ..< 30 { pairs.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator))) }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 0 ... 5, using: &generator) }
        let forests = [
            graph.minimumSpanningTree { weights[$0] },
            graph.kruskalMinimumSpanningTree { weights[$0] },
            graph.primMinimumSpanningTree { weights[$0] },
            graph.boruvkaMinimumSpanningTree { weights[$0] },
            graph.maximumSpanningTree { weights[$0] },
        ]
        for spanning in forests {
            let forest = Forest(spanning, in: graph)
            #expect(Array(forest.vertices) == Array(0 ..< n))
            #expect(Array(forest.edges) == spanning.edges.map { graph.edges[$0] })
            // The graph's components: two vertices share a tree exactly when a graph path joins them.
            var root = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while root[x] != x { x = root[x] }
                return x
            }
            for pair in pairs { root[find(pair.u)] = find(pair.v) }
            for u in 0 ..< n {
                for v in 0 ..< n {
                    #expect((forest.component(of: u) == forest.component(of: v)) == (find(u) == find(v)))
                }
            }
        }
        let named = UndirectedAdjacencyList(vertices: (0 ..< n).map { "v\($0)" }, edges: pairs.map { UndirectedEdge("v\($0.u)", "v\($0.v)") })
        let spanning = named.minimumSpanningTree { weights[$0] }
        let forest = Forest(spanning, in: named)
        #expect(Array(forest.vertices) == (0 ..< n).map { "v\($0)" })
        #expect(Array(forest.edges) == spanning.edges.map { named.edges[$0] })
        #expect(forest.trees.count == n - spanning.edges.count)
    }

    @Test("ST-147 the empty graph and an edgeless graph")
    func empty() {
        let none = UndirectedAdjacencyList<Int>()
        let empty = Forest(none.minimumSpanningTree { _ in 1 }, in: none)
        #expect(empty.vertexCount == 0)
        #expect(empty.edgeCount == 0)
        let three = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3)
        let isolated = Forest(three.minimumSpanningTree { _ in 1 }, in: three)
        #expect(isolated.vertexCount == 3)
        #expect(isolated.trees.count == 3)
    }

    @Test("ST-148 a forest applied to a graph where its edges close a cycle traps", .tags(.precondition))
    func wrongGraph() async {
        await #expect(processExitsWith: .failure) {
            let path = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let triangle = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            // The path's forest is positions 0, 1, 2: the triangle's three edges.
            _ = Forest(path.minimumSpanningTree { _ in 1 }, in: triangle)
        }
    }
}
