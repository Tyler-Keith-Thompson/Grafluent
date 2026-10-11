// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the call, so the trap is the call's and not the
// setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing
import Traversal

@Suite("DirectedAcyclicGraph preconditions", .tags(.precondition))
struct DirectedAcyclicGraphPreconditionTests {
    @Test("DAG-052 remove(edgeAt:) out of range traps")
    func dag052() async throws {
        // DirectedPseudograph; V [0, 1]; E [0→1] / remove(edgeAt: 1) → **trap**
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])!
            _ = graph.remove(edgeAt: 1)
        }
        // Without the call: the state the call would apply to.
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)]))
        #expect(Array(graph.topologicalOrder) == [0, 1])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.edges.indices) == [0])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(Array(graph.base.vertices) == [0, 1] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [0] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [1] && graph.outEdges(safe: 0).map { Array($0) } == [0] && graph.outDegree(safe: 0) == 1)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(safe: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(graph.successors(safe: 1).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 1) == 0)
        #expect(graph.predecessors(safe: 1).map { Array($0) } == [0] && graph.inEdges(safe: 1).map { Array($0) } == [0] && graph.inDegree(safe: 1) == 1)
        #expect(!graph.contains(101) && graph.topologicalPosition(safe: 101) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect(graph.successors(safe: 101) == nil && graph.predecessors(safe: 101) == nil && graph.outEdges(safe: 101) == nil)
        #expect(graph.inEdges(safe: 101) == nil && graph.outDegree(safe: 101) == nil && graph.inDegree(safe: 101) == nil)
    }

    @Test("DAG-053 remove(edgeAt:) at a Stable hole traps")
    func dag053() async throws {
        // StableDirectedGraph; V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0) / remove(edgeAt: 0) → 0→1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])!
            _ = graph.remove(edgeAt: 0)
            _ = graph.remove(edgeAt: 0)
        }
        // Without the call: the state the call would apply to.
        var graph = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.topologicalOrder) == [0, 1])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.edges.indices) == [1])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(Array(graph.base.vertices) == [0, 1] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [1] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [1] && graph.outEdges(safe: 0).map { Array($0) } == [1] && graph.outDegree(safe: 0) == 1)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(safe: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [1] && graph.inDegree(of: 1) == 1)
        #expect(graph.successors(safe: 1).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 1) == 0)
        #expect(graph.predecessors(safe: 1).map { Array($0) } == [0] && graph.inEdges(safe: 1).map { Array($0) } == [1] && graph.inDegree(safe: 1) == 1)
        #expect(!graph.contains(101) && graph.topologicalPosition(safe: 101) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect(graph.successors(safe: 101) == nil && graph.predecessors(safe: 101) == nil && graph.outEdges(safe: 101) == nil)
        #expect(graph.inEdges(safe: 101) == nil && graph.outDegree(safe: 101) == nil && graph.inDegree(safe: 101) == nil)
    }

    @Test("DAG-071 topologicalPosition(of:) non-vertex traps")
    func dag071() async throws {
        // DirectedPseudograph; V [0]; E [] / topologicalPosition(of: 9) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0], edges: [] as [DirectedEdge<Int>])!
            _ = graph.topologicalPosition(of: 9)
        }
        // Without the call: the state the call would apply to.
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0], edges: [] as [DirectedEdge<Int>]))
        #expect(Array(graph.topologicalOrder) == [0])
        #expect(Array(graph.vertices) == [0])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 1 && graph.topologicalOrder.indices == 0 ..< 1)
        #expect(Array(graph.base.vertices) == [0] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 0) == 0)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(!graph.contains(100) && graph.topologicalPosition(safe: 100) == nil && graph.topologicalOrder.firstIndex(of: 100) == nil)
        #expect(graph.successors(safe: 100) == nil && graph.predecessors(safe: 100) == nil && graph.outEdges(safe: 100) == nil)
        #expect(graph.inEdges(safe: 100) == nil && graph.outDegree(safe: 100) == nil && graph.inDegree(safe: 100) == nil)
    }

    @Test("DAG-074 topologicalOrder subscript out of range traps")
    func dag074() async throws {
        // DirectedPseudograph; V [0]; E [] / topologicalOrder[1] → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0], edges: [] as [DirectedEdge<Int>])!
            _ = graph.topologicalOrder[1]
        }
        // Without the call: the state the call would apply to.
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0], edges: [] as [DirectedEdge<Int>]))
        #expect(Array(graph.topologicalOrder) == [0])
        #expect(Array(graph.vertices) == [0])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 1 && graph.topologicalOrder.indices == 0 ..< 1)
        #expect(Array(graph.base.vertices) == [0] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 0) == 0)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(!graph.contains(100) && graph.topologicalPosition(safe: 100) == nil && graph.topologicalOrder.firstIndex(of: 100) == nil)
        #expect(graph.successors(safe: 100) == nil && graph.predecessors(safe: 100) == nil && graph.outEdges(safe: 100) == nil)
        #expect(graph.inEdges(safe: 100) == nil && graph.outDegree(safe: 100) == nil && graph.inDegree(safe: 100) == nil)
    }

    @Test("DAG-078 hasPath: non-vertex traps")
    func dag078() async throws {
        // DirectedPseudograph; V [0]; E [] / hasPath(from: 0, to: 9) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0], edges: [] as [DirectedEdge<Int>])!
            _ = graph.hasPath(from: 0, to: 9)
        }
        // Without the call: the state the call would apply to.
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0], edges: [] as [DirectedEdge<Int>]))
        #expect(Array(graph.topologicalOrder) == [0])
        #expect(Array(graph.vertices) == [0])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 1 && graph.topologicalOrder.indices == 0 ..< 1)
        #expect(Array(graph.base.vertices) == [0] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 0) == 0)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(!graph.contains(100) && graph.topologicalPosition(safe: 100) == nil && graph.topologicalOrder.firstIndex(of: 100) == nil)
        #expect(graph.successors(safe: 100) == nil && graph.predecessors(safe: 100) == nil && graph.outEdges(safe: 100) == nil)
        #expect(graph.inEdges(safe: 100) == nil && graph.outDegree(safe: 100) == nil && graph.inDegree(safe: 100) == nil)
    }

    @Test("topologicalPosition(of:) traps for a non-vertex on every base, and for a removed vertex")
    func positionOfNonVertices() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
            _ = graph.topologicalPosition(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
            _ = graph.topologicalPosition(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1, 2])
            _ = graph.remove(1)
            _ = graph.topologicalPosition(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1, 2])
            _ = graph.remove(0)
            _ = graph.topologicalPosition(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
            _ = graph.topologicalPosition(of: 0)
        }
        // Without the calls: the vertices that remain answer, and the safe spelling answers nil.
        var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1, 2])
        _ = stable.remove(1)
        #expect(stable.topologicalPosition(of: 2) == 1 && stable.topologicalPosition(safe: 1) == nil)
        var dense = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1, 2])
        _ = dense.remove(0)
        #expect(dense.topologicalPosition(of: 2) == 1 && dense.topologicalPosition(safe: 0) == nil)
    }

    @Test("hasPath(from:to:) traps for a non-vertex at either end, even when the other end decides the answer")
    func hasPathOfNonVertices() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0])
            _ = graph.hasPath(from: 9, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0])
            _ = graph.hasPath(from: 9, to: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
            _ = graph.hasPath(from: 1, to: 7)
        }
        // Without the calls: the vertices answer.
        let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
        #expect(graph.hasPath(from: 1, to: 1) && !graph.hasPath(from: 1, to: 0) && !graph.hasPath(from: 0, to: 1))
    }

    @Test("topologicalOrder's subscript traps below 0 and at count, on an empty graph too")
    func orderOutOfRange() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
            _ = graph.topologicalOrder[-1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
            _ = graph.topologicalOrder[2]
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
            _ = graph.topologicalOrder[0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2])
            _ = graph.remove(2)
            _ = graph.topologicalOrder[2]
        }
        await #expect(processExitsWith: .failure) {
            // A hole in the middle: the last place is count - 1, though a slot lies past it.
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2, 3])
            _ = graph.remove(1)
            _ = graph.topologicalOrder[3]
        }
        await #expect(processExitsWith: .failure) {
            // A source placed first: free slots lie before place 0.
            var graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0])
            _ = graph.insert(edge: DirectedEdge(from: 5, to: 0))
            _ = graph.topologicalOrder[-1]
        }
        // Without the calls: the last place answers.
        let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
        #expect(graph.topologicalOrder[1] == 1 && graph.topologicalOrder[0] == 0)
        var holed = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2, 3])
        _ = holed.remove(1)
        #expect(holed.topologicalOrder[2] == 3 && holed.topologicalOrder.count == 3)
        var prepended = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0])
        _ = prepended.insert(edge: DirectedEdge(from: 5, to: 0))
        #expect(prepended.topologicalOrder[0] == 5 && prepended.topologicalOrder[1] == 0)
    }

    @Test("Maps through the wrapper trap as the base's do: a value for a non-vertex or a vacated position, a detached map")
    func mapPreconditions() async throws {
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
            let map = graph.addVertexMap(of: Int.self)
            graph[map, of: 9] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(edges: [DirectedEdge(from: 0, to: 1)])!
            let map = graph.addEdgeMap(of: Int.self)
            _ = graph.remove(edgeAt: 0)
            graph[map, ofEdgeAt: 0] = 1
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
            let map = graph.addVertexMap(of: Int.self)
            graph.removeVertexMap(map)
            _ = graph[map, ofVertexAt: 0]
        }
        // Without the calls: removing the value of a non-vertex is allowed, and reading it is nil.
        var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
        let map = graph.addVertexMap(of: Int.self)
        graph[map, of: 9] = nil
        graph[map, of: 1] = 4
        #expect(graph[map, of: 9] == nil && graph[map, ofVertexAt: 1] == 4)
    }

    @Test("longestPath(weight:) traps on a NaN distance")
    func longestPathNaN() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(edges: [DirectedEdge(from: 0, to: 1)])!
            _ = graph.longestPath(weight: { _ in Double.nan })
        }
        // Without the NaN: infinities are ordinary values.
        let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(edges: [DirectedEdge(from: 0, to: 1)])!
        #expect(graph.longestPath(weight: { _ in Double.infinity })?.edges == [0])
    }

    @Test("remove(edgeAt:) traps below 0, past the end, and at a position a removal vacated")
    func removeEdgeAtOutOfRange() async throws {
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1)])!
            _ = graph.remove(edgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])!
            _ = graph.remove(edgeAt: 0)
            _ = graph.remove(edgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(edges: [DirectedEdge(from: 0, to: 1)])!
            _ = graph.remove(edgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])!
            _ = graph.remove(1)
            _ = graph.remove(edgeAt: 0)
        }
        // Without the calls: the live positions answer, and the order is untouched.
        var dense = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(dense.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(dense.remove(edgeAt: 0) == DirectedEdge(from: 1, to: 2))
        #expect(Array(dense.topologicalOrder) == [0, 1, 2] && dense.edgeCount == 0)
        var stable = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(stable.remove(edgeAt: 1) == DirectedEdge(from: 1, to: 2))
        #expect(stable.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(stable.topologicalOrder) == [0, 1, 2] && stable.edgeCount == 0)
    }

    @Test("Index-space reads of the wrapper trap as the base's do")
    func indexSpaceOutOfRange() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
            _ = graph.vertex(atIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1])
            _ = Array(graph.successorIndices(ofIndex: 2))
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
            _ = graph.vertexIndex(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1])
            _ = Array(graph.successors(of: 5))
        }
        // Without the calls: the last index answers.
        let graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
        #expect(graph.vertex(atIndex: 1) == 1 && graph.vertexIndex(of: 1) == 1)
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [] as [Int])
    }
}
