// Event transcripts on random graphs against a reference written inside each test: a plain
// recursive depth-first search and a queue-based breadth-first search over `successors(of:)`,
// sharing no code with Traversal. Covered: both ways of consuming a search (pulling with for-in,
// pushing with forEach), graphs with and without vertex indices, Int vertices outside 0..<n,
// String vertices, and an adjacency list after vertex removals. Case IDs (TR-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

/// Supplies only what DirectedGraph requires: no vertex indices, so searches use dictionaries.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Search transcripts against a reference", .tags(.randomized))
struct SearchReferenceTests {
    @Test("TR-177 depth-first and breadth-first transcripts match the reference on every kind of graph", arguments: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    func transcripts(_ seed: Int) {
        // The references: plain, recursive, over successors(of:), written for this test only.
        func referenceDepthFirst<G: DirectedGraph>(_ g: G, roots: [G.Vertex], limit: Int?) -> [String] {
            var events: [String] = []
            var order: [G.Vertex: Int] = [:]
            var finished: Set<G.Vertex> = []
            func visit(_ u: G.Vertex, depth: Int) {
                order[u] = order.count
                events.append("discover(\(u))")
                if limit.map({ depth < $0 }) ?? true {
                    for w in g.successors(of: u) {
                        let edge = DirectedEdge(from: u, to: w)
                        if order[w] == nil {
                            events.append("treeEdge(\(edge))")
                            visit(w, depth: depth + 1)
                        } else if !finished.contains(w) {
                            events.append("backEdge(\(edge))")
                        } else if order[w]! > order[u]! {
                            events.append("forwardEdge(\(edge))")
                        } else {
                            events.append("crossEdge(\(edge))")
                        }
                    }
                }
                finished.insert(u)
                events.append("finish(\(u))")
            }
            for root in roots where order[root] == nil { visit(root, depth: 0) }
            return events
        }
        func referenceBreadthFirst<G: DirectedGraph>(_ g: G, sources: [G.Vertex], limit: Int?) -> [String] {
            var events: [String] = []
            var depth: [G.Vertex: Int] = [:]
            var queue: [G.Vertex] = []
            for s in sources where depth[s] == nil {
                depth[s] = 0
                queue.append(s)
                events.append("discover(\(s))")
            }
            var head = 0
            while head < queue.count {
                let u = queue[head]
                head += 1
                if limit.map({ depth[u]! < $0 }) ?? true {
                    for w in g.successors(of: u) {
                        let edge = DirectedEdge(from: u, to: w)
                        if depth[w] == nil {
                            depth[w] = depth[u]! + 1
                            queue.append(w)
                            events.append("treeEdge(\(edge))")
                            events.append("discover(\(w))")
                        } else {
                            events.append("nonTreeEdge(\(edge))")
                        }
                    }
                }
                events.append("finish(\(u))")
            }
            return events
        }
        func check<G: DirectedGraph>(_ g: G, _ name: String, roots: [G.Vertex], limit: Int?) {
            let depthFirst = referenceDepthFirst(g, roots: roots, limit: limit)
            #expect(g.depthFirstSearch(from: roots, depthLimit: limit).map(\.description) == depthFirst, "\(name) depth-first, pulled")
            var pushed: [String] = []
            g.depthFirstSearch(from: roots, depthLimit: limit).forEach { pushed.append($0.description) }
            #expect(pushed == depthFirst, "\(name) depth-first, pushed")
            let breadthFirst = referenceBreadthFirst(g, sources: roots, limit: limit)
            #expect(g.breadthFirstSearch(from: roots, depthLimit: limit).map(\.description) == breadthFirst, "\(name) breadth-first, pulled")
            pushed = []
            g.breadthFirstSearch(from: roots, depthLimit: limit).forEach { pushed.append($0.description) }
            #expect(pushed == breadthFirst, "\(name) breadth-first, pushed")
            // The whole graph, roots in vertices order.
            let all = Array(g.vertices)
            #expect(g.depthFirstSearch().map(\.description) == referenceDepthFirst(g, roots: all, limit: nil), "\(name) whole graph")
            pushed = []
            g.depthFirstSearch().forEach { pushed.append($0.description) }
            #expect(pushed == referenceDepthFirst(g, roots: all, limit: nil), "\(name) whole graph, pushed")
        }
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 700)
        for n in [1, 3, 8, 20] {
            var pairs: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &generator) {
                pairs.append((Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)))
            }
            let rootCount = Int.random(in: 1 ... min(3, n), using: &generator)
            let roots = (0 ..< rootCount).map { _ in Int.random(in: 0 ..< n, using: &generator) }
            let limit: Int? = Bool.random(using: &generator) ? nil : Int.random(in: 0 ... 3, using: &generator)
            let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            check(CompressedSparseRow(vertexCount: n, edges: edges), "CSR", roots: roots, limit: limit)
            check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges), "multigraph", roots: roots, limit: limit)
            check(DictionaryGraph(vertices: Array(0 ..< n), edges: edges), "no indices", roots: roots, limit: limit)
            // Int vertices that are not 0..<n, and String vertices.
            let spread = pairs.map { DirectedEdge(from: $0.0 * 7 - 30, to: $0.1 * 7 - 30) }
            check(AdjacencyList(vertices: (0 ..< n).map { $0 * 7 - 30 }, edges: spread), "spread", roots: roots.map { $0 * 7 - 30 }, limit: limit)
            let named = pairs.map { DirectedEdge(from: "v\($0.0)", to: "v\($0.1)") }
            check(AdjacencyList(vertices: (0 ..< n).map { "v\($0)" }, edges: named), "String", roots: roots.map { "v\($0)" }, limit: limit)
            check(DictionaryGraph(vertices: (0 ..< n).map { "v\($0)" }, edges: named), "String, no indices", roots: roots.map { "v\($0)" }, limit: limit)
            // An adjacency list after removals, whose slots have moved.
            var removed = AdjacencyList(vertices: 0 ..< n + 3, edges: edges + [DirectedEdge(from: n, to: n + 1), DirectedEdge(from: n + 2, to: 0)])
            removed.remove(n + 2)
            removed.remove(n)
            check(removed, "after removals", roots: roots, limit: limit)
        }
    }

    @Test("TR-178 the topological sort, cycle and reachability answers match references on graphs without indices and with String vertices", arguments: [1, 2, 3, 4, 5, 6])
    func queries(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 800)
        for n in [1, 4, 12] {
            var edges: [DirectedEdge<String>] = []
            for _ in 0 ..< Int.random(in: 0 ... 2 * n, using: &generator) {
                let u = Int.random(in: 0 ..< n, using: &generator)
                let v = Int.random(in: 0 ..< n, using: &generator)
                // Mostly forward, so many graphs are acyclic.
                if u < v || Int.random(in: 0 ..< 4, using: &generator) == 0 { edges.append(DirectedEdge(from: "v\(u)", to: "v\(v)")) }
            }
            let vertices = (0 ..< n).map { "v\($0)" }
            let unindexed = DictionaryGraph(vertices: vertices, edges: edges)
            let list = AdjacencyList(vertices: vertices, edges: edges)
            // Reference reachability by repeated relaxation.
            var reach: [String: Set<String>] = [:]
            for v in vertices { reach[v] = Set(edges.filter { $0.source == v }.map(\.target)) }
            for _ in 0 ..< n {
                for v in vertices { reach[v] = reach[v]!.union(reach[v]!.flatMap { reach[$0]! }) }
            }
            let cyclic = vertices.contains { reach[$0]!.contains($0) }
            for g in [unindexed.topologicalSort(), list.topologicalSort(), unindexed.topologicalGenerations().map { Array($0.joined()) }] {
                #expect((g == nil) == cyclic)
            }
            #expect((unindexed.findCycle() == nil) == !cyclic)
            #expect((list.findCycle() == nil) == !cyclic)
            for v in vertices {
                let expected = reach[v]!.subtracting([v])
                #expect(unindexed.descendants(of: v) == expected)
                #expect(list.descendants(of: v) == expected)
                #expect(list.ancestors(of: v) == Set(vertices.filter { reach[$0]!.contains(v) && $0 != v }))
                for w in vertices { #expect(unindexed.hasPath(from: v, to: w) == (v == w || reach[v]!.contains(w))) }
            }
        }
    }

    @Test("TR-179 forEach stops at the first error and rethrows it")
    func forEachThrows() {
        struct Stop: Error, Equatable {}
        let graph = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.house.edges)
        var seen: [String] = []
        #expect(throws: Stop()) {
            try graph.depthFirstSearch(from: 5).forEach { event throws(Stop) in
                seen.append(event.description)
                if event == .discover(2) { throw Stop() }
            }
        }
        #expect(seen == ["discover(5)", "treeEdge(5→3)", "discover(3)", "treeEdge(3→2)", "discover(2)"])
        var count = 0
        #expect(throws: Stop()) {
            try graph.breadthFirstSearch(from: 5).forEach { (_: BreadthFirstSearchEvent<Int>) throws(Stop) in
                count += 1
                if count == 3 { throw Stop() }
            }
        }
        #expect(count == 3)
    }

    @Test("TR-180 a 100 000-state chain through a successor closure")
    func deepClosure() async {
        await Task {
            let preorder = depthFirstSearch(from: [0], successors: { (k: Int) in k < 99_999 ? [k + 1] : [] })
                .compactMap { if case .discover(let v) = $0 { v } else { nil } }
            #expect(preorder.count == 100_000)
            #expect(preorder.last == 99_999)
            #expect(topologicalSort(from: [0], successors: { (k: Int) in k < 99_999 ? [k + 1] : [] })?.count == 100_000)
        }.value
    }

    @Test("TR-181 findCycle(from:) finds only cycles reachable from the roots")
    func findCycleFromRoots() {
        // 0→1, and a cycle 2→3→2 that 0 cannot reach.
        let graph = CompressedSparseRow(vertexCount: 4, edges: [(0, 1), (2, 3), (3, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.findCycle(from: [0]) == nil)
        #expect(graph.findCycle(from: [3]) == [3, 2])
        #expect(graph.findCycle(from: [0, 2]) == [2, 3])
        #expect(graph.findCycle() == [2, 3])
    }
}
