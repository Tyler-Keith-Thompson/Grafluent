// Seeded random graphs against oracles written in each test: Floyd–Warshall, the tree laws, the
// triangle inequality, the tie rule, A* against Dijkstra, the single-target query, breadth-first
// search, Johnson's reweighting and relabeling. n ∈ {1, 2, 5, 10, 30}, edge probability ∈ {0.05,
// 0.2, 0.5}, 50 graphs per pair; self-loops always possible and a parallel copy of an edge with
// probability 0.2 on the ReferenceDirectedMultigraph. Case IDs (SP-nn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import ShortestPaths
import Testing

@Suite("Shortest-path properties on random graphs", .tags(.randomized))
struct ShortestPathPropertyTests {
    @Test("SP-100 Dijkstra equals Floyd–Warshall on nonnegative weights, on four representations", arguments: [1, 2, 5, 10, 30])
    func dijkstraEqualsFloydWarshall(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(100 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: 0 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: 0 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                // Floyd–Warshall over the cheapest copy of each edge; nil is unreachable.
                var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
                for i in 0 ..< n { d[i][i] = 0 }
                for (u, v, w) in raw where d[u][v] == nil || w < d[u][v]! { d[u][v] = w }
                for k in 0 ..< n {
                    for i in 0 ..< n {
                        guard let ik = d[i][k] else { continue }
                        for j in 0 ..< n {
                            guard let kj = d[k][j] else { continue }
                            if d[i][j] == nil || ik + kj < d[i][j]! { d[i][j] = ik + kj }
                        }
                    }
                }
                let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
                let multigraph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges)
                // The simple representations hold one copy of each edge: give it the cheapest weight.
                var cheapest: [DirectedEdge<Int>: Int] = [:]
                for (u, v, w) in raw { cheapest[DirectedEdge(from: u, to: v)] = min(w, cheapest[DirectedEdge(from: u, to: v)] ?? w) }
                var edgeIndices: [Int] = []
                let sparse = CompressedSparseRow(vertexCount: n, edges: edges, edgeIndices: &edgeIndices)
                var sparseWeights = [Int](repeating: 0, count: sparse.edgeCount)
                for (i, k) in edgeIndices.enumerated() { sparseWeights[k] = cheapest[edges[i]]! }
                let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
                let listWeights = list.edges.map { cheapest[$0]! }
                let matrix = AdjacencyMatrix(vertexCount: n, edges: edges)
                for s in 0 ..< n {
                    let fromMultigraph = multigraph.dijkstraShortestPaths(from: s) { raw[$0].2 }
                    let fromSparse = sparse.dijkstraShortestPaths(from: s) { sparseWeights[$0] }
                    let fromList = list.dijkstraShortestPaths(from: s) { listWeights[$0] }
                    let fromMatrix = matrix.dijkstraShortestPaths(from: s) { cheapest[DirectedEdge(from: $0.source, to: $0.target)]! }
                    #expect((0 ..< n).map { fromMultigraph.distance(to: $0) } == d[s], "n \(n), p \(p), from \(s): \(raw)")
                    #expect((0 ..< n).map { fromSparse.distance(to: $0) } == d[s], "n \(n), p \(p), from \(s): \(raw)")
                    #expect((0 ..< n).map { fromList.distance(to: $0) } == d[s], "n \(n), p \(p), from \(s): \(raw)")
                    #expect((0 ..< n).map { fromMatrix.distance(to: $0) } == d[s], "n \(n), p \(p), from \(s): \(raw)")
                }
            }
        }
    }

    @Test("SP-101 Bellman–Ford equals Floyd–Warshall, and is nil exactly when a negative cycle is reachable", arguments: [1, 2, 5, 10, 30])
    func bellmanFordEqualsFloydWarshall(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(101 + n))
        var trees = 0
        var cycles = 0
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -3 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: -3 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                // Floyd–Warshall, floored so negative cycles cannot overflow; d[i][i] < 0 iff i is
                // on a negative cycle.
                var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
                for i in 0 ..< n { d[i][i] = 0 }
                for (u, v, w) in raw where d[u][v] == nil || w < d[u][v]! { d[u][v] = w }
                for k in 0 ..< n {
                    for i in 0 ..< n {
                        guard let ik = d[i][k] else { continue }
                        for j in 0 ..< n {
                            guard let kj = d[k][j] else { continue }
                            let through = max(ik + kj, -1_000_000)
                            if d[i][j] == nil || through < d[i][j]! { d[i][j] = through }
                        }
                    }
                }
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                // Three sources per graph keep the 750 graphs quick; the stress tests go deep.
                for s in Set([0, n / 2, n - 1]).sorted() {
                    let reachesNegativeCycle = (0 ..< n).contains { d[s][$0] != nil && d[$0][$0]! < 0 }
                    let tree = graph.bellmanFordShortestPaths(from: s) { raw[$0].2 }
                    let witness = graph.findNegativeCycle(from: s) { raw[$0].2 }
                    #expect((tree == nil) == reachesNegativeCycle, "n \(n), from \(s): \(raw)")
                    #expect((witness != nil) == reachesNegativeCycle, "n \(n), from \(s): \(raw)")
                    if let tree {
                        trees += 1
                        #expect((0 ..< n).map { tree.distance(to: $0) } == d[s], "n \(n), from \(s): \(raw)")
                    } else {
                        cycles += 1
                    }
                }
                let anywhere = (0 ..< n).contains { d[$0][$0]! < 0 }
                #expect((graph.findNegativeCycle { raw[$0].2 } != nil) == anywhere, "n \(n): \(raw)")
            }
        }
        #expect(trees > 0)
        if n >= 5 { #expect(cycles > 0) }
    }

    @Test("SP-102 tree laws for Dijkstra, Bellman–Ford and unweighted search", arguments: [1, 2, 5, 10, 30])
    func treeLaws(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(102 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -3 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: -3 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let sources = Array(Set((0 ..< 2).map { _ in Int.random(in: 0 ..< n, using: &rng) })).sorted()
                let nonnegative = raw.map { abs($0.2) }

                func laws(_ tree: ShortestPathTree<ReferenceDirectedMultigraph<Int>, Int>, weight: (Int) -> Int, _ name: String) {
                    #expect(tree.sources == sources, "\(name)")
                    for v in 0 ..< n {
                        guard let distance = tree.distance(to: v) else {
                            #expect(tree.parent(of: v) == nil && tree.parentEdge(of: v) == nil && tree.path(to: v) == nil && !tree.hasPath(to: v), "\(name): \(v)")
                            continue
                        }
                        #expect(tree.hasPath(to: v))
                        if let parent = tree.parent(of: v) {
                            let edge = tree.parentEdge(of: v)!
                            #expect(graph.source(ofEdgeAt: edge) == parent && graph.target(ofEdgeAt: edge) == v, "\(name): \(v)")
                            #expect(tree.distance(to: parent).map { $0 + weight(edge) } == distance, "\(name): \(v)")
                        } else {
                            #expect(sources.contains(v) && distance == 0 && tree.parentEdge(of: v) == nil, "\(name): \(v)")
                        }
                        // Parents lead to a source without repeating; the path is that walk reversed.
                        var walk = [v]
                        var total = 0
                        while let parent = tree.parent(of: walk.last!), walk.count <= n {
                            total += weight(tree.parentEdge(of: walk.last!)!)
                            walk.append(parent)
                        }
                        #expect(walk.count <= n && Set(walk).count == walk.count && sources.contains(walk.last!), "\(name): \(walk)")
                        #expect(tree.path(to: v) == walk.reversed(), "\(name): \(v)")
                        #expect(total == distance, "\(name): \(v)")
                    }
                }
                laws(graph.dijkstraShortestPaths(from: sources) { nonnegative[$0] }, weight: { nonnegative[$0] }, "Dijkstra \(raw)")
                if let tree = graph.bellmanFordShortestPaths(from: sources, weight: { raw[$0].2 }) {
                    laws(tree, weight: { raw[$0].2 }, "Bellman–Ford \(raw)")
                }
                laws(graph.shortestPaths(from: sources), weight: { _ in 1 }, "unweighted \(raw)")
            }
        }
    }

    @Test("SP-103 the triangle inequality, with and without a cutoff", arguments: [1, 2, 5, 10, 30])
    func triangleInequality(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(103 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: 0 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: 0 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let source = Int.random(in: 0 ..< n, using: &rng)
                let cutoff = Int.random(in: -1 ... 20, using: &rng)
                let tree = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }
                let limited = graph.dijkstraShortestPaths(from: source, cutoff: cutoff) { raw[$0].2 }
                for (u, v, w) in raw {
                    if let du = tree.distance(to: u) {
                        #expect(tree.distance(to: v).map { $0 <= du + w } == true, "\(raw)")
                    }
                    if let du = limited.distance(to: u), du + w <= cutoff {
                        #expect(limited.distance(to: v).map { $0 <= du + w } == true, "cutoff \(cutoff): \(raw)")
                    }
                }
                for v in 0 ..< n {
                    // Within the cutoff, exactly the vertices whose distance is at most the cutoff, at that distance.
                    let expected = tree.distance(to: v).flatMap { v == source || $0 <= cutoff ? $0 : nil }
                    #expect(limited.distance(to: v) == expected, "cutoff \(cutoff), \(v): \(raw)")
                }
            }
        }
    }

    @Test("SP-104 the tie rule: a determined parent is exact, any other is a candidate", arguments: [1, 2, 5, 10, 30])
    func tieRule(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(104 + n))
        var determined = 0
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        // Few distinct weights, so ties are common.
                        raw.append((u, v, Int.random(in: 0 ... 3, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: 0 ... 3, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let source = Int.random(in: 0 ..< n, using: &rng)
                let tree = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }
                for v in 0 ..< n where v != source {
                    guard let dv = tree.distance(to: v) else { continue }
                    // Candidates: each reached u with a shortest edge to v, its first such edge in
                    // outEdges order; keep those with the smallest distance.
                    var candidates: [(u: Int, edge: Int, du: Int)] = []
                    for u in 0 ..< n {
                        guard let du = tree.distance(to: u) else { continue }
                        if let edge = graph.outEdges(of: u).first(where: { graph.target(ofEdgeAt: $0) == v && du + raw[$0].2 == dv }) {
                            candidates.append((u, edge, du))
                        }
                    }
                    let nearest = candidates.map(\.du).min()!
                    let group = candidates.filter { $0.du == nearest }
                    if group.count == 1 {
                        determined += 1
                        #expect(tree.parent(of: v) == group[0].u, "\(v): \(raw)")
                        #expect(tree.parentEdge(of: v) == group[0].edge, "\(v): \(raw)")
                    } else {
                        #expect(group.contains { $0.u == tree.parent(of: v) && $0.edge == tree.parentEdge(of: v) }, "\(v): \(raw)")
                    }
                }
            }
        }
        if n >= 5 { #expect(determined > 0) }
    }

    @Test("SP-105 A* with zero, consistent and inconsistent admissible heuristics equals Dijkstra", arguments: [1, 2, 5, 10, 30])
    func aStarEqualsDijkstra(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(105 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: 0 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: 0 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let source = Int.random(in: 0 ..< n, using: &rng)
                let target = Int.random(in: 0 ..< n, using: &rng)
                // Exact distances to the target, from Dijkstra on the reversed graph.
                let reversed = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.1, to: $0.0) })
                let toTarget = reversed.dijkstraShortestPaths(from: target) { raw[$0].2 }
                let exact = (0 ..< n).map { toTarget.distance(to: $0) ?? 0 }
                let random = exact.map { Int.random(in: 0 ... $0, using: &rng) }
                let expected = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }.distance(to: target)
                let heuristics: [(String, (Int) -> Int)] = [("zero", { _ in 0 }), ("half", { exact[$0] / 2 }), ("random", { random[$0] })]
                for (name, heuristic) in heuristics {
                    let result = graph.aStarShortestPath(from: source, to: target, weight: { raw[$0].2 }, heuristic: heuristic)
                    #expect(result?.distance == expected, "\(name), \(source)→\(target): \(raw)")
                    guard let path = result?.path else { continue }
                    #expect(path.first == source && path.last == target)
                    var total = 0
                    for (u, v) in zip(path, path.dropFirst()) {
                        let copies = graph.outEdges(of: u).filter { graph.target(ofEdgeAt: $0) == v }.map { raw[$0].2 }
                        #expect(!copies.isEmpty, "\(name): \(u)→\(v) is not an edge")
                        total += copies.min() ?? 0
                    }
                    #expect(total == result?.distance, "\(name): \(path)")
                }
            }
        }
    }

    @Test("SP-106 the single-target query equals the tree and returns a shortest path", arguments: [1, 2, 5, 10, 30])
    func singleTargetEqualsTree(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(106 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: 0 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: 0 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let source = Int.random(in: 0 ..< n, using: &rng)
                let tree = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }
                for target in 0 ..< n {
                    let result = graph.dijkstraShortestPath(from: source, to: target) { raw[$0].2 }
                    #expect(result?.distance == tree.distance(to: target), "\(source)→\(target): \(raw)")
                    guard let path = result?.path else { continue }
                    #expect(path.first == source && path.last == target)
                    var total = 0
                    for (u, v) in zip(path, path.dropFirst()) {
                        let copies = graph.outEdges(of: u).filter { graph.target(ofEdgeAt: $0) == v }.map { raw[$0].2 }
                        #expect(!copies.isEmpty)
                        total += copies.min() ?? 0
                    }
                    #expect(total == result?.distance, "\(path)")
                }
            }
        }
    }

    @Test("SP-107 unweighted search: Dijkstra's distances with unit weights, parents by first discovery", arguments: [1, 2, 5, 10, 30])
    func unweightedEqualsUnitDijkstra(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(107 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v)) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let sources = Array(Set((0 ..< 2).map { _ in Int.random(in: 0 ..< n, using: &rng) })).sorted()
                let tree = graph.shortestPaths(from: sources)
                let dijkstra = graph.dijkstraShortestPaths(from: sources) { _ in 1 }
                // A first-in-first-out search in outEdges order.
                var distance = [Int?](repeating: nil, count: n)
                var parentEdge = [Int?](repeating: nil, count: n)
                var queue = sources
                for s in sources { distance[s] = 0 }
                var head = 0
                while head < queue.count {
                    let u = queue[head]
                    head += 1
                    for e in graph.outEdges(of: u) where distance[raw[e].1] == nil {
                        distance[raw[e].1] = distance[u]! + 1
                        parentEdge[raw[e].1] = e
                        queue.append(raw[e].1)
                    }
                }
                #expect((0 ..< n).map { tree.distance(to: $0) } == distance, "\(raw)")
                #expect((0 ..< n).map { dijkstra.distance(to: $0) } == distance, "\(raw)")
                #expect((0 ..< n).map { tree.parentEdge(of: $0) } == parentEdge, "\(raw)")
                #expect((0 ..< n).map { tree.parent(of: $0) } == parentEdge.map { $0.map { raw[$0].0 } }, "\(raw)")
            }
        }
    }

    @Test("SP-108 Johnson's reweighting: potentials from Bellman–Ford make Dijkstra exact", arguments: [1, 2, 5, 10, 30])
    func reweightingInvariance(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(108 + n))
        var reweighted = 0
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -2 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: -2 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                // Every vertex a source at 0 is Johnson's super-source.
                guard let potentials = graph.bellmanFordShortestPaths(from: 0 ..< n, weight: { raw[$0].2 }) else { continue }
                reweighted += 1
                let pi = (0 ..< n).map { potentials.distance(to: $0)! }
                let reduced = raw.map { $0.2 + pi[$0.0] - pi[$0.1] }
                #expect(reduced.allSatisfy { $0 >= 0 })
                let source = Int.random(in: 0 ..< n, using: &rng)
                let original = graph.bellmanFordShortestPaths(from: source) { raw[$0].2 }
                let dijkstra = graph.dijkstraShortestPaths(from: source) { reduced[$0] }
                for v in 0 ..< n {
                    #expect(dijkstra.distance(to: v) == original?.distance(to: v).map { $0 + pi[source] - pi[v] }, "\(v): \(raw)")
                }
            }
        }
        #expect(reweighted > 0)
    }

    @Test("SP-109 relabeling maps distances to distances and witnesses to witnesses", arguments: [1, 2, 5, 10, 30])
    func relabeling(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(109 + n))
        for p in [0.05, 0.2, 0.5] {
            for _ in 0 ..< 50 {
                var raw: [(Int, Int, Int)] = []
                for u in 0 ..< n {
                    for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &rng) < p {
                        raw.append((u, v, Int.random(in: -3 ... 10, using: &rng)))
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { raw.append((u, v, Int.random(in: -3 ... 10, using: &rng))) }
                    }
                }
                raw.shuffle(using: &rng)
                // Vertex i becomes label[i], listed in the same place, so the search runs identically.
                let label = (0 ..< n).map { 1000 + 7 * $0 }.shuffled(using: &rng)
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                let relabeled = ReferenceDirectedMultigraph(vertices: label, edges: raw.map { DirectedEdge(from: label[$0.0], to: label[$0.1]) })
                let source = Int.random(in: 0 ..< n, using: &rng)
                let nonnegative = raw.map { abs($0.2) }
                let dijkstra = graph.dijkstraShortestPaths(from: source) { nonnegative[$0] }
                let relabeledDijkstra = relabeled.dijkstraShortestPaths(from: label[source]) { nonnegative[$0] }
                #expect((0 ..< n).map { relabeledDijkstra.distance(to: label[$0]) } == (0 ..< n).map { dijkstra.distance(to: $0) })
                let bellmanFord = graph.bellmanFordShortestPaths(from: source) { raw[$0].2 }
                let relabeledBellmanFord = relabeled.bellmanFordShortestPaths(from: label[source]) { raw[$0].2 }
                #expect((0 ..< n).map { relabeledBellmanFord?.distance(to: label[$0]) } == (0 ..< n).map { bellmanFord?.distance(to: $0) })
                let witness = graph.findNegativeCycle(from: source) { raw[$0].2 }
                let relabeledWitness = relabeled.findNegativeCycle(from: label[source]) { raw[$0].2 }
                #expect(relabeledWitness == witness?.map { label[$0] }, "\(raw)")
                #expect(relabeled.findNegativeCycle { raw[$0].2 } == graph.findNegativeCycle { raw[$0].2 }?.map { label[$0] }, "\(raw)")
            }
        }
    }
}

@Suite("Shortest-path properties with shrinking", .tags(.randomized))
struct ShortestPathShrinkingPropertyTests {
    @Test("SP-131 Dijkstra's tree is its own certificate, and Bellman–Ford agrees: a failure shrinks to a small edge list")
    func certificate() async {
        // Up to 30 edges on vertices 0..<8 with weights 0...9; repeats and self-loops allowed. On a
        // failure, PropertyBased shrinks the edge list and prints the smallest one that still fails.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 7)) { raw, source in
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let tree = graph.dijkstraShortestPaths(from: source) { raw[$0].2 }
            #expect(tree.distance(to: source) == 0)
            #expect(tree.parent(of: source) == nil)
            for (k, edge) in raw.enumerated() {
                // No edge out of a reached vertex is shorter than the tree, and its target is reached.
                guard let du = tree.distance(to: edge.0) else { continue }
                let dv = tree.distance(to: edge.1)
                #expect(dv != nil && dv! <= du + edge.2, "edge \(k)")
            }
            for v in 0 ..< 8 where v != source {
                guard let dv = tree.distance(to: v) else {
                    #expect(tree.parent(of: v) == nil && tree.path(to: v) == nil)
                    continue
                }
                // Every reached vertex is as far as its parent plus its parent edge.
                let edge = tree.parentEdge(of: v)!
                #expect(raw[edge].0 == tree.parent(of: v) && raw[edge].1 == v)
                #expect(tree.distance(to: raw[edge].0)! + raw[edge].2 == dv)
                #expect(tree.path(to: v)?.first == source && tree.path(to: v)?.last == v)
            }
            let bellmanFord = graph.bellmanFordShortestPaths(from: source) { raw[$0].2 }
            #expect((0 ..< 8).map { bellmanFord?.distance(to: $0) } == (0 ..< 8).map { tree.distance(to: $0) })
        }
    }
}
