// Properties every search must have, on seeded random graphs through every representation, on the
// real-world fixtures, and on deep or wide graphs; plus dispatch, value semantics and
// preconditions. Every oracle is written inside its test. Case IDs (TR-nn) refer to the catalog;
// see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Search properties on random graphs", .tags(.randomized))
struct SearchPropertyTests {
    @Test("TR-139 – TR-141 breadth-first distances are shortest, tree edges step one layer, and the tree is a tree", arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func breadthFirst(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 2, 5, 10, 40] {
            var edges: [DirectedEdge<Int>] = []
            for u in 0 ..< n {
                for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < 0.15 { edges.append(DirectedEdge(from: u, to: v)) }
            }
            let source = Int.random(in: 0 ..< n, using: &generator)
            // Oracle: unit-weight Bellman–Ford.
            var oracle = [Int?](repeating: nil, count: n)
            oracle[source] = 0
            for _ in 0 ..< n {
                for e in edges {
                    if let d = oracle[e.source], oracle[e.target].map({ d + 1 < $0 }) ?? true { oracle[e.target] = d + 1 }
                }
            }
            func check<G: DirectedGraph<Int>>(_ g: G) {
                var distance: [Int: Int] = [source: 0]
                var parent: [Int: Int] = [:]
                for event in g.breadthFirstSearch(from: source) {
                    switch event {
                    case .treeEdge(let e):
                        #expect(parent[e.target] == nil, "two tree edges into \(e.target)")
                        parent[e.target] = e.source
                        distance[e.target] = distance[e.source]! + 1
                    case .nonTreeEdge(let e):
                        #expect(distance[e.target]! <= distance[e.source]! + 1)
                    default: break
                    }
                }
                for v in 0 ..< n { #expect(distance[v] == oracle[v], "distance to \(v)") }
                for v in parent.keys {
                    var steps = 0
                    var u = v
                    while let p = parent[u] { u = p; steps += 1 }
                    #expect(u == source)
                    #expect(steps < n)
                }
            }
            check(AdjacencyList(vertices: 0 ..< n, edges: edges))
            check(AdjacencyMatrix(vertexCount: n, edges: edges))
            check(CompressedSparseRow(vertexCount: n, edges: edges))
            check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges + edges.prefix(3)))
        }
    }

    @Test("TR-142 – TR-145 / TR-150 depth-first parenthesis theorem, consistent classification, every edge once, back edge iff cycle", arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func depthFirst(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 50)
        for n in [1, 2, 5, 10, 40] {
            var edges: [DirectedEdge<Int>] = []
            for u in 0 ..< n {
                for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < 0.1 { edges.append(DirectedEdge(from: u, to: v)) }
            }
            // Oracle for acyclicity: Kahn's algorithm.
            var inDegree = [Int](repeating: 0, count: n)
            for e in edges { inDegree[e.target] += 1 }
            var ready = (0 ..< n).filter { inDegree[$0] == 0 }
            var emitted = 0
            while let v = ready.popLast() {
                emitted += 1
                for e in edges where e.source == v {
                    inDegree[e.target] -= 1
                    if inDegree[e.target] == 0 { ready.append(e.target) }
                }
            }
            let acyclic = emitted == n
            func check<G: DirectedGraph<Int>>(_ g: G, multiplicity: [DirectedEdge<Int>: Int]) -> [String] {
                var time = 0
                var discovered: [Int: Int] = [:]
                var finished: [Int: Int] = [:]
                var parent: [Int: Int] = [:]
                var seen: [DirectedEdge<Int>: Int] = [:]
                var hasBack = false
                var transcript: [String] = []
                for event in g.depthFirstSearch() {
                    transcript.append(event.description)
                    time += 1
                    switch event {
                    case .discover(let v): discovered[v] = time
                    case .finish(let v): finished[v] = time
                    case .treeEdge(let e):
                        #expect(discovered[e.target] == nil)
                        parent[e.target] = e.source
                        seen[e, default: 0] += 1
                    case .backEdge(let e):
                        #expect(discovered[e.target] != nil && finished[e.target] == nil)
                        hasBack = true
                        seen[e, default: 0] += 1
                    case .forwardEdge(let e):
                        #expect(finished[e.target] != nil && discovered[e.target]! > discovered[e.source]!)
                        seen[e, default: 0] += 1
                    case .crossEdge(let e):
                        #expect(finished[e.target] != nil && discovered[e.target]! < discovered[e.source]!)
                        seen[e, default: 0] += 1
                    }
                }
                // Every edge, once per copy.
                #expect(seen == multiplicity)
                #expect(hasBack == !acyclic)
                // Parenthesis theorem: intervals nest exactly along the tree.
                for u in 0 ..< n {
                    for v in 0 ..< n where u != v {
                        let (du, fu, dv, fv) = (discovered[u]!, finished[u]!, discovered[v]!, finished[v]!)
                        let nested = du < dv && fv < fu
                        let disjoint = fu < dv || fv < du
                        #expect(nested || disjoint || (dv < du && fu < fv))
                        var ancestor = parent[v]
                        while let a = ancestor, a != u { ancestor = parent[a] }
                        #expect(nested == (ancestor == u))
                    }
                }
                return transcript
            }
            var simple: [DirectedEdge<Int>: Int] = [:]
            for e in Set(edges) { simple[e] = 1 }
            _ = check(AdjacencyList(vertices: 0 ..< n, edges: edges), multiplicity: simple)
            let matrix = check(AdjacencyMatrix(vertexCount: n, edges: edges), multiplicity: simple)
            let sparse = check(CompressedSparseRow(vertexCount: n, edges: edges), multiplicity: simple)
            #expect(matrix == sparse)
            let doubled = edges + edges.filter { $0.source % 2 == 0 }
            var copies: [DirectedEdge<Int>: Int] = [:]
            for e in doubled { copies[e, default: 0] += 1 }
            _ = check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: doubled), multiplicity: copies)
        }
    }

    @Test("TR-146 – TR-148 topological orders exist exactly for DAGs, respect every edge, and generations are longest-path depths", arguments: [1, 2, 3, 4, 5, 6])
    func topological(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 90)
        for n in [1, 5, 10, 40] {
            // A random DAG (edges forward in a shuffled order), sometimes with one back edge added.
            let rank = Array(0 ..< n).shuffled(using: &generator)
            var edges: [DirectedEdge<Int>] = []
            for u in 0 ..< n {
                for v in 0 ..< n where rank[u] < rank[v] && Double.random(in: 0 ..< 1, using: &generator) < 0.2 {
                    edges.append(DirectedEdge(from: u, to: v))
                }
            }
            let cyclic = n > 1 && seed % 2 == 0 && !edges.isEmpty
            if cyclic { edges.append(DirectedEdge(from: edges[0].target, to: edges[0].source)) }
            let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
            let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
            for order in [list.topologicalSort(), sparse.topologicalSort(), list.lexicographicalTopologicalSort(), list.topologicalGenerations().map { Array($0.joined()) }] {
                #expect((order == nil) == cyclic)
                guard let order else { continue }
                #expect(order.sorted() == Array(0 ..< n))
                let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
                for e in edges { #expect(position[e.source]! < position[e.target]!) }
            }
            if !cyclic {
                // The lexicographical order is the smallest available vertex at every step.
                var remaining = Set(0 ..< n)
                var expected: [Int] = []
                while let next = remaining.filter({ v in !edges.contains { $0.target == v && remaining.contains($0.source) } }).min() {
                    expected.append(next)
                    remaining.remove(next)
                }
                #expect(list.lexicographicalTopologicalSort() == expected)
                // Generation k holds the vertices whose longest incoming path has k edges.
                var depth = [Int](repeating: 0, count: n)
                for v in expected {
                    for e in edges where e.source == v { depth[e.target] = max(depth[e.target], depth[v] + 1) }
                }
                for (k, generation) in list.topologicalGenerations()!.enumerated() {
                    for v in generation { #expect(depth[v] == k) }
                }
                #expect(list.findCycle() == nil)
            } else {
                #expect(list.findCycle() != nil)
            }
        }
    }

    @Test("TR-151 / TR-152 descendants equal search reach, ancestors are descendants of the reverse, and a search can be iterated twice", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func reach(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let reversed = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges.map { DirectedEdge(from: $0.target, to: $0.source) })
        for v in graph.vertices {
            let descendants = graph.descendants(of: v)
            let bfs = Set(graph.breadthFirstSearch(from: v).compactMap { if case .discover(let w) = $0 { w } else { nil } })
            let dfs = Set(graph.depthFirstSearch(from: v).preorder)
            #expect(descendants == bfs.subtracting([v]))
            #expect(descendants == dfs.subtracting([v]))
            #expect(graph.ancestors(of: v) == reversed.descendants(of: v))
            let search = graph.depthFirstSearch(from: v)
            #expect(Array(search) == Array(search))
        }
    }

    @Test("TR-149 a symmetric graph has no cross edges, and without self-loops back = tree + forward")
    func symmetric() {
        let cases: [(DirectedFixture<Int>, [Int])] = [(.petersen, [9, 15, 6]), (.cube, [7, 12, 5])]
        for (fixture, expected) in cases {
            var counts = [0, 0, 0, 0]
            for event in AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).depthFirstSearch(from: 0) {
                switch event {
                case .treeEdge: counts[0] += 1
                case .backEdge: counts[1] += 1
                case .forwardEdge: counts[2] += 1
                case .crossEdge: counts[3] += 1
                default: break
                }
            }
            #expect(Array(counts.prefix(3)) == expected, "\(fixture.name)")
            #expect(counts[3] == 0)
            #expect(counts[1] == counts[0] + counts[2])
        }
    }
}

@Suite("Searches on large and real graphs")
struct SearchStressTests {
    @Test("TR-153 a 100 000-vertex path does not overflow the stack")
    func deepPath() async {
        let n = 100_000
        let edges = (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) }
        let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
        let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
        await Task {
            #expect(Array(sparse.depthFirstSearch(from: 0).preorder) == Array(0 ..< n))
            #expect(Array(sparse.depthFirstSearch(from: 0).postorder) == Array((0 ..< n).reversed()))
            #expect(sparse.topologicalSort() == Array(0 ..< n))
            #expect(sparse.breadthFirstLayers(from: 0).count == n)
            #expect(Array(list.depthFirstSearch(from: 0).preorder) == Array(0 ..< n))
            #expect(list.topologicalSort() == Array(0 ..< n))
        }.value
    }

    @Test("TR-154 a 100 000-vertex cycle: one back edge, and the whole cycle is found")
    func deepCycle() {
        let n = 100_000
        let sparse = CompressedSparseRow(vertexCount: n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
        let backEdges = sparse.depthFirstSearch().filter { if case .backEdge = $0 { true } else { false } }
        #expect(backEdges == [.backEdge(DirectedEdge(from: n - 1, to: 0))])
        #expect(sparse.findCycle() == Array(0 ..< n))
        #expect(sparse.topologicalSort() == nil)
    }

    @Test("TR-155 / TR-156 a wide out-star and in-star")
    func stars() {
        let n = 100_000
        let out = CompressedSparseRow(vertexCount: n, edges: (1 ..< n).map { DirectedEdge(from: 0, to: $0) })
        #expect(out.breadthFirstLayers(from: 0).map(\.count) == [1, n - 1])
        #expect(Array(out.depthFirstSearch(from: 0).prefix(7)).map(\.description) == [
            "discover(0)", "treeEdge(0→1)", "discover(1)", "finish(1)", "treeEdge(0→2)", "discover(2)", "finish(2)",
        ])
        let into = CompressedSparseRow(vertexCount: 4, edges: (1 ..< 4).map { DirectedEdge(from: $0, to: 0) })
        #expect(into.depthFirstSearch().map(\.description).joined(separator: " ") == "discover(0) finish(0) discover(1) crossEdge(1→0) finish(1) discover(2) crossEdge(2→0) finish(2) discover(3) crossEdge(3→0) finish(3)")
    }

    @Test("TR-157 – TR-159 the real-world fixtures")
    func realWorld() {
        func counts<G: DirectedGraph<Int>>(_ search: DepthFirstSearch<G>) -> [Int] {
            var counts = [0, 0, 0, 0]
            for event in search {
                switch event {
                case .treeEdge: counts[0] += 1
                case .backEdge: counts[1] += 1
                case .forwardEdge: counts[2] += 1
                case .crossEdge: counts[3] += 1
                default: break
                }
            }
            return counts
        }
        let graph500 = DirectedFixture<Int>.graph500Scale8
        let g = CompressedSparseRow(vertexCount: 256, edges: graph500.edges)
        #expect(g.breadthFirstLayers(from: 82).map(\.count) == [1, 167, 66, 1])
        #expect(counts(g.depthFirstSearch(from: 82)) == [234, 19, 192, 1715])
        #expect(counts(g.depthFirstSearch()) == [223, 19, 37, 1892])
        // Every cycle is a self-loop, so the back-edge count is the same on any representation.
        let list = AdjacencyList(vertices: 0 ..< 256, edges: graph500.edges)
        #expect(counts(list.depthFirstSearch(from: 82))[1] == 19)
        #expect(counts(list.depthFirstSearch(from: 82))[0] == 234)
        let gap = CompressedSparseRow(vertexCount: 14, edges: DirectedFixture<Int>.gap4.edges)
        #expect(gap.breadthFirstLayers(from: 0).map(\.count) == [1, 12])
        #expect(counts(gap.depthFirstSearch(from: 0)) == [12, 5, 9, 32])
        #expect(gap.findCycle() == [0])
        let ligra = CompressedSparseRow(vertexCount: 128, edges: DirectedFixture<Int>.ligraRMat.edges)
        #expect(ligra.breadthFirstLayers(from: 0).map(\.count) == [1, 8, 20, 50, 41, 5])
        #expect(counts(ligra.depthFirstSearch(from: 0)) == [124, 354, 230, 0])
        #expect(ligra.findCycle() == [0, 22])
    }

    @Test("TR-160 / TR-161 a complete digraph, and the real-world fixtures agree across representations")
    func agreement() {
        let complete = AdjacencyMatrix(vertexCount: 10, edges: DirectedFixture<Int>.completeDirected10.edges)
        var counts = [0, 0, 0, 0]
        for event in complete.depthFirstSearch(from: 0) {
            switch event {
            case .treeEdge: counts[0] += 1
            case .backEdge: counts[1] += 1
            case .forwardEdge: counts[2] += 1
            case .crossEdge: counts[3] += 1
            default: break
            }
        }
        #expect(counts == [9, 45, 36, 0])
        #expect(Array(complete.depthFirstSearch(from: 0).preorder) == Array(0 ..< 10))
        for fixture in DirectedFixture<Int>.realWorld {
            let list = AdjacencyList(vertices: 0 ..< fixture.vertexCount, edges: fixture.edges)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            for source in stride(from: 0, to: fixture.vertexCount, by: 17) {
                #expect(list.breadthFirstLayers(from: source).map(Set.init) == sparse.breadthFirstLayers(from: source).map(Set.init), "\(fixture.name) from \(source)")
            }
        }
    }
}

/// Counts the hashes made through it, so a test can tell index-based adjacency from a traversal
/// that maps every neighbor back to its index.
private final class HashCounter: @unchecked Sendable {
    var hashes = 0
}

private struct HashCountingVertex: Hashable {
    let value: Int
    let counter: HashCounter

    static func == (lhs: HashCountingVertex, rhs: HashCountingVertex) -> Bool { lhs.value == rhs.value }

    func hash(into hasher: inout Hasher) {
        counter.hashes += 1
        hasher.combine(value)
    }
}

/// Supplies only what DirectedGraph requires: no vertex indices, so searches use dictionaries.
private struct UnindexedGraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func successors(of vertex: Int) -> [Int] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
}

@Suite("Search dispatch, value semantics and preconditions")
struct SearchDispatchTests {
    @Test("TR-162 / TR-165 an adjacency list is searched in index space: hashing only to find the source, even through another generic layer")
    func indexSpace() {
        let counter = HashCounter()
        let boost = DirectedFixture<Int>.boost24
        let graph = AdjacencyList(edges: boost.edges.map { DirectedEdge(from: HashCountingVertex(value: $0.source, counter: counter), to: HashCountingVertex(value: $0.target, counter: counter)) })
        let source = HashCountingVertex(value: 7, counter: counter)
        func run<G: DirectedGraph>(_ g: G, from s: G.Vertex) -> Int { Array(g.breadthFirstSearch(from: s)).count + Array(g.depthFirstSearch(from: s)).count }
        counter.hashes = 0
        let events = run(graph, from: source)
        #expect(events > 43)
        // Two searches, each looking up its source (and checking it is a vertex): a few hashes, not one per edge.
        #expect(counter.hashes <= 8)
    }

    @Test("TR-182 ancestors and bidirectional search on an adjacency list run in index space too")
    func backwardIndexSpace() {
        // A complete digraph on 30 vertices: 870 edges, so hashing per edge would be obvious next to
        // the 29 vertices of each result.
        let counter = HashCounter()
        let vertex = { HashCountingVertex(value: $0, counter: counter) }
        let edges = (0 ..< 30).flatMap { u in (0 ..< 30).filter { $0 != u }.map { DirectedEdge(from: vertex(u), to: vertex($0)) } }
        let graph = AdjacencyList(edges: edges)
        counter.hashes = 0
        #expect(graph.ancestors(of: vertex(0)).count == 29)
        // Looking up 0, and inserting 29 vertices into the result as it grows.
        #expect(counter.hashes < 150)
        counter.hashes = 0
        #expect(graph.bidirectionalShortestPath(from: vertex(3), to: vertex(7))?.count == 2)
        #expect(counter.hashes <= 8)
    }

    @Test("TR-163 successorIndices agree with successors through vertexIndex", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func successorIndices(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph>(_ g: G) {
            for v in g.vertices {
                let i = g.vertexIndex(of: v)
                #expect(Array(g.successorIndices(ofIndex: i)) == g.successors(of: v).map { g.vertexIndex(of: $0) })
                #expect(Array(g.predecessorIndices(ofIndex: i)) == g.predecessors(of: v).map { g.vertexIndex(of: $0) })
            }
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(ReferenceDirectedMultigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            for v in sparse.vertices { #expect(Array(sparse.successorIndices(ofIndex: v)) == Array(sparse.successors(of: v))) }
        }
    }

    @Test("TR-164 a graph without vertex indices is searched on dictionaries, with the same transcript")
    func withoutIndices() {
        let house = DirectedFixture<Int>.house
        let unindexed = UnindexedGraph(vertices: [0, 1, 2, 3, 4, 5], edges: house.edges.sorted())
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: house.edges)
        #expect(Array(unindexed.breadthFirstSearch(from: 5)) == Array(matrix.breadthFirstSearch(from: 5)))
        #expect(Array(unindexed.depthFirstSearch()) == Array(matrix.depthFirstSearch()))
        #expect(unindexed.topologicalSort() == matrix.topologicalSort())
        #expect(unindexed.topologicalGenerations() == matrix.topologicalGenerations())
        #expect(unindexed.findCycle() == nil)
    }

    @Test("TR-166 existentials")
    func existentials() {
        func preorder(_ g: some DirectedGraph<Int>) -> [Int] { Array(g.depthFirstSearch(from: 5).preorder) }
        let house = DirectedFixture<Int>.house
        let graphs: [any DirectedGraph<Int>] = [
            AdjacencyMatrix(vertexCount: 6, edges: house.edges),
            CompressedSparseRow(vertexCount: 6, edges: house.edges),
            ReferenceDirectedMultigraph(edges: house.edges.sorted()),
        ]
        for g in graphs {
            #expect(preorder(g) == [5, 3, 2, 1, 0, 4])
            #expect(g.descendants(of: 5) == [0, 1, 2, 3, 4])
            #expect(g.topologicalSort() == [5, 3, 4, 2, 1, 0])
        }
    }

    @Test("TR-167 a search holds a copy of the graph")
    func valueSemantics() {
        var graph = AdjacencyList(edges: DirectedFixture<Int>.house.edges)
        let search = graph.depthFirstSearch(from: 5)
        graph.insert(edge: DirectedEdge(from: 0, to: 5))
        #expect(!search.contains { if case .backEdge = $0 { true } else { false } })
        #expect(graph.depthFirstSearch(from: 5).contains { if case .backEdge = $0 { true } else { false } })
    }

    @Test("TR-168 searches and their events are Sendable")
    func sendable() async {
        let search = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).depthFirstSearch(from: 5)
        let count = await Task.detached { Array(search).count }.value
        #expect(count == 19)
    }

    @Test("TR-169 one source or a sequence of them, with String vertices")
    func overloads() {
        let dag = DirectedFixture<String>.petgraphDAG
        let graph = AdjacencyList(vertices: dag.vertices, edges: dag.edges)
        #expect(Array(graph.breadthFirstSearch(from: "a")) == Array(graph.breadthFirstSearch(from: ["a"])))
        #expect(Set(graph.depthFirstSearch(from: ["a", "d"]).preorder) == Set(dag.vertices).union(dag.edges.flatMap { [$0.source, $0.target] }))
    }

    @Test("TR-170 / TR-171 a source that is not a vertex, or a negative depth limit, traps", .tags(.precondition))
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            _ = Array(AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).breadthFirstSearch(from: 9))
        }
        await #expect(processExitsWith: .failure) {
            _ = Array(AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).depthFirstSearch(from: 9))
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).descendants(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).hasPath(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).depthFirstSearch(from: 0, depthLimit: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).breadthFirstSearch(from: 0, depthLimit: -1)
        }
    }

    @Test("TR-173 events are Hashable and print readably")
    func events() {
        let search = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.house.edges).depthFirstSearch(from: 5)
        #expect(Set(search).count == 19)
        #expect(DepthFirstSearchEvent.treeEdge(DirectedEdge(from: 0, to: 1)).description == "treeEdge(0→1)")
        #expect(BreadthFirstSearchEvent.discover("a").description == "discover(a)")
    }
}
