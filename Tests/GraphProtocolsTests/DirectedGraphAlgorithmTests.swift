// Algorithms written once against DirectedGraph give the same answers on every representation.
// Each test declares its algorithm as a local generic function. Expected values were computed
// with NetworkX, not with Grafluent. Case IDs (DG-Ann) refer to the catalog in README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Generic algorithms on every representation")
struct DirectedGraphAlgorithmTests {
    @Test("DG-A01 – A03 breadth-first distances")
    func breadthFirstDistances() {
        func distances<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> [G.Vertex: Int] {
            var distance = [source: 0]
            var queue = [source]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in g.successors(of: v) where distance[w] == nil {
                    distance[w] = distance[v]! + 1
                    queue.append(w)
                }
            }
            return distance
        }
        let cases: [(DirectedFixture<Int>, Int, [Int: Int])] = [
            (.house, 5, [5: 0, 3: 1, 2: 2, 4: 2, 0: 3, 1: 3]),
            (.boost24, 7, [
                7: 0, 11: 1, 17: 1, 4: 2, 15: 2, 19: 2, 20: 2, 0: 3, 5: 3, 6: 3, 13: 3, 18: 3, 22: 3, 23: 3,
                3: 4, 8: 4, 9: 4, 14: 4, 16: 4, 21: 4, 1: 5, 10: 5, 12: 5, 2: 6,
            ]),
            (.scc9, 1, [1: 0, 7: 1, 4: 2, 5: 2, 8: 3, 2: 4, 6: 4, 0: 5, 3: 6]),
        ]
        for (fixture, source, expected) in cases {
            #expect(distances(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges), from: source) == expected, "\(fixture.name)")
            #expect(distances(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges), from: source) == expected, "\(fixture.name)")
            #expect(distances(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges), from: source) == expected, "\(fixture.name)")
            #expect(distances(Multigraph(vertices: fixture.vertices, edges: fixture.edges), from: source) == expected, "\(fixture.name)")
        }
    }

    @Test("DG-A04 breadth-first order with successors visited in ascending order")
    func breadthFirstOrder() {
        func order<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> [G.Vertex] where G.Vertex: Comparable {
            var seen: Set = [source]
            var queue = [source]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in g.successors(of: v).sorted() where seen.insert(w).inserted {
                    queue.append(w)
                }
            }
            return queue
        }
        let fixture = DirectedFixture<Int>.petgraphEdgesDirected
        let graphs: [[Int]] = [
            order(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges), from: 0),
            order(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges), from: 0),
            order(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges), from: 0),
            order(Multigraph(vertices: fixture.vertices, edges: fixture.edges), from: 0),
        ]
        for result in graphs { #expect(result == [0, 1, 2, 3, 5, 4]) }
        #expect(order(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges), from: 6) == [6])
    }

    @Test("DG-A05 depth-first preorder with successors visited in ascending order")
    func depthFirstPreorder() {
        func preorder<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> [G.Vertex] where G.Vertex: Comparable {
            var seen = Set<G.Vertex>()
            var order: [G.Vertex] = []
            func visit(_ v: G.Vertex) {
                guard seen.insert(v).inserted else { return }
                order.append(v)
                for w in g.successors(of: v).sorted() { visit(w) }
            }
            visit(source)
            return order
        }
        let edgesDirected = DirectedFixture<Int>.petgraphEdgesDirected
        let neo4j = DirectedFixture<Int>.neo4jDirected
        for fixture in [edgesDirected, neo4j] {
            let expected = fixture.name == edgesDirected.name ? [0, 1, 3, 2, 4, 5] : [0, 1, 2, 4, 3]
            #expect(preorder(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected)
            #expect(preorder(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges), from: 0) == expected)
            #expect(preorder(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges), from: 0) == expected)
            #expect(preorder(Multigraph(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected)
        }
        let dag = DirectedFixture<String>.petgraphDAG
        #expect(preorder(AdjacencyList(vertices: dag.vertices, edges: dag.edges), from: "a") == ["a", "b", "c", "e", "g", "d", "f"])
        #expect(preorder(Multigraph(vertices: dag.vertices, edges: dag.edges), from: "a") == ["a", "b", "c", "e", "g", "d", "f"])
    }

    @Test("DG-A06 / DG-A08 topological generations by Kahn's algorithm, and cycles")
    func topologicalGenerations() {
        // Returns nil when the graph has a cycle.
        func generations<G: DirectedGraph>(_ g: G) -> [Set<G.Vertex>]? {
            var inDegree: [G.Vertex: Int] = [:]
            for v in g.vertices { inDegree[v] = 0 }
            for e in g.edges { inDegree[e.target, default: 0] += 1 }
            var current = Set(g.vertices.filter { inDegree[$0] == 0 })
            var result: [Set<G.Vertex>] = []
            var emitted = 0
            while !current.isEmpty {
                result.append(current)
                emitted += current.count
                var next = Set<G.Vertex>()
                for v in current {
                    for w in g.successors(of: v) {
                        inDegree[w]! -= 1
                        if inDegree[w] == 0 { next.insert(w) }
                    }
                }
                current = next
            }
            return emitted == g.vertexCount ? result : nil
        }
        let cases: [(DirectedFixture<Int>, [Set<Int>])] = [
            (.house, [[5], [3], [2, 4], [1], [0]]),
            (.neo4jDirected, [[0], [1], [2, 3], [4]]),
            (.boostCsrUnsorted, [[3, 4, 5], [0, 1], [2]]),
            (.scipyConstructor2, [[0, 1, 2, 3, 5], [4]]),
        ]
        for (fixture, expected) in cases {
            #expect(generations(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(generations(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(generations(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)) == expected, "\(fixture.name)")
        }
        for (fixture, expected) in cases {
            #expect(generations(Multigraph(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
        }
        // Without the listed vertices, only the endpoints remain.
        #expect(generations(Multigraph(edges: DirectedFixture<Int>.scipyConstructor2.edges)) == [[3], [4]])
        let dag = DirectedFixture<String>.petgraphDAG
        #expect(generations(AdjacencyList(vertices: dag.vertices, edges: dag.edges)) == [["a"], ["d"], ["b", "f"], ["c"], ["e"], ["g"]])
        let abcd = DirectedFixture<String>.networkXABCD
        #expect(generations(AdjacencyList(vertices: abcd.vertices, edges: abcd.edges)) == [["A", "G", "J", "K"], ["B"], ["C"], ["D"]])
        #expect(generations(Multigraph(edges: abcd.edges)) == [["A"], ["B"], ["C"], ["D"]])
        for fixture in [DirectedFixture<Int>.scc9, .directedCycle4, .boost24] {
            #expect(generations(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == nil, "\(fixture.name)")
            #expect(generations(Multigraph(vertices: fixture.vertices, edges: fixture.edges)) == nil, "\(fixture.name)")
        }
        for fixture in [DirectedFixture<Int>.scc9, .boost24] {
            #expect(generations(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)) == nil, "\(fixture.name)")
            #expect(generations(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)) == nil, "\(fixture.name)")
        }
    }

    @Test("DG-A07 Kahn's algorithm on a multigraph: a repeated edge is a repeated successor")
    func kahnOnMultigraph() {
        // In-degrees count both copies of 1→3, so successors must list 3 twice, or 3 is never emitted.
        func order<G: DirectedGraph>(_ g: G) -> [G.Vertex] {
            var inDegree: [G.Vertex: Int] = [:]
            for v in g.vertices { inDegree[v] = 0 }
            for e in g.edges { inDegree[e.target, default: 0] += 1 }
            var ready = g.vertices.filter { inDegree[$0] == 0 }
            var result: [G.Vertex] = []
            while let v = ready.popLast() {
                result.append(v)
                for w in g.successors(of: v) {
                    inDegree[w]! -= 1
                    if inDegree[w] == 0 { ready.append(w) }
                }
            }
            return result
        }
        let chord = DirectedFixture<Int>.pathWithChord
        #expect(order(Multigraph(edges: chord.edges)) == [0, 1, 2, 3, 4, 5])
        #expect(order(AdjacencyList(vertices: chord.vertices, edges: chord.edges)) == [0, 1, 2, 3, 4, 5])
    }

    @Test("DG-A09 strongly connected components by Tarjan's algorithm, using successors only")
    func tarjan() {
        func components<G: DirectedGraph>(_ g: G) -> Set<Set<G.Vertex>> {
            var index: [G.Vertex: Int] = [:]
            var lowLink: [G.Vertex: Int] = [:]
            var onStack = Set<G.Vertex>()
            var stack: [G.Vertex] = []
            var result = Set<Set<G.Vertex>>()
            var counter = 0
            func connect(_ v: G.Vertex) {
                index[v] = counter
                lowLink[v] = counter
                counter += 1
                stack.append(v)
                onStack.insert(v)
                for w in g.successors(of: v) {
                    if index[w] == nil {
                        connect(w)
                        lowLink[v] = min(lowLink[v]!, lowLink[w]!)
                    } else if onStack.contains(w) {
                        lowLink[v] = min(lowLink[v]!, index[w]!)
                    }
                }
                if lowLink[v] == index[v] {
                    var component = Set<G.Vertex>()
                    while true {
                        let w = stack.removeLast()
                        onStack.remove(w)
                        component.insert(w)
                        if w == v { break }
                    }
                    result.insert(component)
                }
            }
            for v in g.vertices where index[v] == nil { connect(v) }
            return result
        }
        let cases: [(DirectedFixture<Int>, Set<Set<Int>>)] = [
            (.scc9, [[0, 3, 6], [1, 4, 7], [2, 5, 8]]),
            (.boost24, [[0], [7], Set(1 ... 6).union(8 ... 23)]),
            (.petgraphEdgesDirected, [[0, 2, 4], [1], [3], [5], [6]]),
            (.igraphReverseEdges, [[0], [1, 2, 3], [4]]),
            (.networkXFunctionGraph, [[0, 1], [2], [3], [4]]),
            (.boostExample, [[0], [1], [2], [3, 4], [5]]),
        ]
        for (fixture, expected) in cases {
            #expect(components(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(components(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(components(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(components(Multigraph(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
        }
    }

    @Test("DG-A10 strongly connected components by Kosaraju's algorithm, using predecessors")
    func kosaraju() {
        func components<G: BidirectionalDirectedGraph>(_ g: G) -> Set<Set<G.Vertex>> {
            var seen = Set<G.Vertex>()
            var finished: [G.Vertex] = []
            func forward(_ v: G.Vertex) {
                guard seen.insert(v).inserted else { return }
                for w in g.successors(of: v) { forward(w) }
                finished.append(v)
            }
            for v in g.vertices { forward(v) }
            var assigned = Set<G.Vertex>()
            var result = Set<Set<G.Vertex>>()
            for root in finished.reversed() where !assigned.contains(root) {
                var component = Set<G.Vertex>()
                var stack = [root]
                assigned.insert(root)
                while let v = stack.popLast() {
                    component.insert(v)
                    for u in g.predecessors(of: v) where assigned.insert(u).inserted {
                        stack.append(u)
                    }
                }
                result.insert(component)
            }
            return result
        }
        let cases: [(DirectedFixture<Int>, Set<Set<Int>>)] = [
            (.scc9, [[0, 3, 6], [1, 4, 7], [2, 5, 8]]),
            (.boost24, [[0], [7], Set(1 ... 6).union(8 ... 23)]),
            (.petgraphEdgesDirected, [[0, 2, 4], [1], [3], [5], [6]]),
            (.igraphReverseEdges, [[0], [1, 2, 3], [4]]),
            (.boostExample, [[0], [1], [2], [3, 4], [5]]),
        ]
        for (fixture, expected) in cases {
            #expect(components(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(components(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(components(Multigraph(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
        }
    }

    @Test("DG-A11 reverse reachability through predecessors")
    func ancestors() {
        func ancestors<G: BidirectionalDirectedGraph>(_ g: G, of target: G.Vertex) -> Set<G.Vertex> {
            var seen = Set<G.Vertex>()
            var stack = [target]
            while let v = stack.popLast() {
                for u in g.predecessors(of: v) where seen.insert(u).inserted { stack.append(u) }
            }
            seen.remove(target)
            return seen
        }
        let cases: [(DirectedFixture<Int>, Int, Set<Int>)] = [
            (.scc9, 8, [1, 2, 4, 5, 7]),
            (.petgraphBellmanFord, 8, [4, 5, 6, 7]),
            (.boostExample, 5, [1]),
        ]
        for (fixture, target, expected) in cases {
            #expect(ancestors(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges), of: target) == expected, "\(fixture.name)")
            #expect(ancestors(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges), of: target) == expected, "\(fixture.name)")
            #expect(ancestors(Multigraph(vertices: fixture.vertices, edges: fixture.edges), of: target) == expected, "\(fixture.name)")
        }
    }

    @Test("DG-A12 the same algorithm through existentials")
    func existentials() {
        func reachable(_ g: any DirectedGraph<Int>, from source: Int) -> Set<Int> {
            var seen: Set = [source]
            var stack = [source]
            while let v = stack.popLast() {
                for w in g.successors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            return seen
        }
        let house = DirectedFixture<Int>.house
        let graphs: [any DirectedGraph<Int>] = [
            AdjacencyList(vertices: house.vertices, edges: house.edges),
            AdjacencyMatrix(vertexCount: 6, edges: house.edges),
            CompressedSparseRow(vertexCount: 6, edges: house.edges),
            Multigraph(edges: house.edges),
        ]
        for g in graphs {
            #expect(reachable(g, from: 5) == [0, 1, 2, 3, 4, 5])
            #expect(reachable(g, from: 2) == [0, 1, 2])
        }
    }
}
