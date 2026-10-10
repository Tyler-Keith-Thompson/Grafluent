// `BipartiteGraph` as a `Graph`: the protocol laws (Sources/GraphProtocols/Graph.swift) and the
// side invariant, checked on every vertex and edge of several graphs, fresh and after removals
// that move slots, side entries and edge positions. Every requirement forwards to the
// `UndirectedAdjacencyList` inside, `_withIncidentIndexRows` included (api.md, Summary), so the
// stored rows are read back and compared with `neighborIndices(ofIndex:)` and
// `incidentEdgeIndices(ofIndex:)`. The expected rows are computed in each test from the graph's
// own `edges`; rows are compared as multisets after removals, which reorder them. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("BipartiteGraph as a Graph: protocol laws and the side invariant")
struct BipartiteGraphLawTests {
    @Test("Graph's laws and the side invariant hold on fresh graphs and after removals")
    func laws() throws {
        let pathPairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")]
        let path = try #require(BipartiteGraph(left: ["a", "b", "c"], right: ["x", "y"], edges: pathPairs.map { UndirectedEdge($0.0, $0.1) }))
        let k33Pairs: [(String, String)] = [("a", "x"), ("y", "a"), ("a", "z"), ("x", "b"), ("b", "y"), ("z", "b"), ("c", "x"), ("c", "y"), ("z", "c")]
        let k33 = try #require(BipartiteGraph(left: ["a", "b", "c"], right: ["x", "y", "z"], edges: k33Pairs.map { UndirectedEdge($0.0, $0.1) }))
        var afterVertexRemoval = k33
        afterVertexRemoval.remove("a")
        afterVertexRemoval.remove("y")
        var afterEdgeRemoval = k33
        afterEdgeRemoval.remove(edge: UndirectedEdge("a", "x"))
        afterEdgeRemoval.remove(edge: UndirectedEdge("b", "y"))
        var withIsolated = path
        withIsolated.insert("q", on: .right)
        withIsolated.insert("p", on: .left)
        withIsolated.remove("b")
        var rebuilt = BipartiteGraph<String>()
        rebuilt.insert("x", on: .right)
        rebuilt.insert("a", on: .left)
        rebuilt.insert(edge: UndirectedEdge("x", "a"))
        rebuilt.remove("x")
        rebuilt.insert("x", on: .left)
        rebuilt.insert("w", on: .right)
        rebuilt.insert(edge: UndirectedEdge("w", "x"))
        rebuilt.insert(edge: UndirectedEdge("a", "w"))
        let graphs = [BipartiteGraph<String>(), path, k33, afterVertexRemoval, afterEdgeRemoval, withIsolated, rebuilt]

        for graph in graphs {
            let vertices = Array(graph.vertices)
            let edges = Array(graph.edges)
            #expect(graph.vertexCount == vertices.count)
            #expect(Set(vertices).count == vertices.count)
            #expect(graph.edgeCount == edges.count)
            #expect(Array(graph.edges.indices) == Array(0 ..< edges.count))
            #expect(graph.vertexIndexBound == vertices.count)
            #expect(graph.edgeIndexBound == edges.count)
            var degreeSum = 0
            for (i, v) in vertices.enumerated() {
                #expect(graph.contains(v))
                #expect(graph.vertex(atIndex: i) == v)
                #expect(graph.vertexIndex(of: v) == i)
                let row = Array(graph.incidentEdges(of: v))
                let expectedRow = edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == v }.map { _ in k } }
                #expect(row.sorted() == expectedRow, "row of \(v) in \(graph)")
                #expect(Array(graph.neighbors(of: v)) == row.map { edges[$0].oppositeVertex(to: v) })
                #expect(row.allSatisfy { graph.oppositeVertex(to: v, acrossEdgeAt: $0) == edges[$0].oppositeVertex(to: v) })
                #expect(graph.degree(of: v) == row.count)
                #expect(Array(graph.incidentEdges(ofIndex: i)) == row)
                #expect(Array(graph.neighborIndices(ofIndex: i)) == graph.neighbors(of: v).map { graph.vertexIndex(of: $0) })
                #expect(Array(graph.incidentEdgeIndices(ofIndex: i)) == row.map { graph.edgeIndex(of: $0) })
                degreeSum += graph.degree(of: v)
                for w in vertices {
                    #expect(graph.contains(edge: UndirectedEdge(v, w)) == edges.contains(UndirectedEdge(v, w)))
                }
            }
            #expect(degreeSum == 2 * graph.edgeCount)
            #expect(edges.indices.map { graph.edgeIndex(of: $0) } == Array(0 ..< edges.count))
            for edge in edges {
                #expect(graph.contains(edge: edge))
                #expect(graph.contains(edge: UndirectedEdge(edge.v, edge.u)))
                #expect(!edge.isSelfLoop)
            }
            #expect(!graph.contains("absent"))
            #expect(!graph.contains(edge: UndirectedEdge("absent", "a")))
            #expect(!graph.contains(edge: UndirectedEdge("absent", "absent")))

            // The stored rows, read back: three entries per vertex index (start, length, unused).
            let stored = graph._withIncidentIndexRows { neighbors, neighborRows, edgeStorage, edgeRows -> [([Int], [Int])] in
                (0 ..< vertices.count).map { v in
                    (Array(neighbors[neighborRows[3 * v] ..< neighborRows[3 * v] + neighborRows[3 * v + 1]]),
                     Array(edgeStorage[edgeRows[3 * v] ..< edgeRows[3 * v] + edgeRows[3 * v + 1]]))
                }
            }
            let rows = try #require(stored, "BipartiteGraph forwards _withIncidentIndexRows")
            for i in vertices.indices {
                #expect(rows[i].0 == Array(graph.neighborIndices(ofIndex: i)))
                #expect(rows[i].1 == Array(graph.incidentEdgeIndices(ofIndex: i)))
            }

            // The sides: a partition of the vertices, every edge across, stored left endpoint first.
            let left = Array(graph.left)
            let right = Array(graph.right)
            #expect(left.count + right.count == vertices.count)
            #expect(Set(left).union(right) == Set(vertices))
            #expect(Set(left).isDisjoint(with: right))
            #expect(Array(graph.left.indices) == Array(0 ..< left.count))
            for v in left { #expect(graph.side(of: v) == .left) }
            for v in right { #expect(graph.side(of: v) == .right) }
            for edge in edges {
                #expect(graph.side(of: edge.u) == .left, "\(edge) stored left endpoint first")
                #expect(graph.side(of: edge.v) == .right)
            }
            // Asking again gives the same answer.
            #expect(Array(graph.vertices) == vertices)
            #expect(Array(graph.edges) == edges)
            #expect(Array(graph.left) == left)
        }
    }

    @Test("Generic code over some Graph sees the same graph; isBipartite is true and bipartition() is the stored sides when built canonically")
    func genericCode() throws {
        func summary<G: Graph>(_ graph: G) -> (Int, Int, [G.Vertex], Int) {
            (graph.vertexCount, graph.edgeCount, Array(graph.vertices), graph.vertices.map { graph.degree(of: $0) }.reduce(0, +))
        }
        let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (4, 5), (0, 5)]
        let graph = try #require(BipartiteGraph(left: [0, 2, 4], right: [1, 3, 5], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let copy = UndirectedAdjacencyList(graph)
        let a = summary(graph)
        let b = summary(copy)
        #expect(a.0 == b.0 && a.1 == b.1 && a.2 == b.2 && a.3 == b.3)
        #expect(Array(copy.edges) == Array(graph.edges))
        #expect(graph.isBipartite)
        #expect(graph.findOddCycle() == nil)
        let bipartition = try #require(graph.bipartition())
        // Least vertex of the single component (0, the first slot) is left: the stored sides.
        #expect(Array(bipartition.left) == Array(graph.left))
        #expect(Array(bipartition.right) == Array(graph.right))
        #expect(BipartiteGraph(graph) == graph)
        #expect(BipartiteGraph(copy) == graph)
        #expect(BipartiteGraph(graph, left: Array(graph.left)) == graph)
    }

    @Test("A graph whose stored sides are not the canonical ones: bipartition() of it swaps them, the value keeps its own")
    func storedSidesAreNotRecomputed() throws {
        // The first vertex, x, is on the right.
        let graph = try #require(BipartiteGraph(left: ["a"], right: ["x"], edges: [UndirectedEdge("x", "a")]))
        #expect(Array(graph.vertices) == ["a", "x"])
        var moved = graph
        moved.remove("a")
        moved.insert("a", on: .left)
        moved.insert(edge: UndirectedEdge("a", "x"))
        #expect(Array(moved.vertices) == ["x", "a"])
        #expect(moved.side(of: "x") == .right)
        let bipartition = try #require(moved.bipartition())
        #expect(Array(bipartition.left) == ["x"])
        #expect(Array(bipartition.right) == ["a"])
        #expect(moved == graph)
        // Rebuilt from the graph: canonical sides, so a different value.
        let canonical = try #require(BipartiteGraph(moved))
        #expect(canonical.side(of: "x") == .left)
        #expect(canonical != moved)
    }
}
