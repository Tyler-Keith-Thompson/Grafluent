// The representations a family builds in one bulk step, read past the edge list: in-rows and
// in-degrees, the rows' order after edits, parallel copies, `BipartiteGraph`'s sides after removals,
// and a balanced tree of branching factor 0. A generated graph must behave exactly like the same graph
// inserted edge by edge, in the same order, through every later insertion and removal. Hand-written;
// each test is self-contained. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import GraphProtocols
import Multigraphs
import NamedGraphs
import Testing
import Trees

@Suite("NamedGraphs bulk construction, read through every row and edited afterwards")
struct BulkConstructionTests {
    @Test("AdjacencyMatrix: a generated wheel and star have every in-degree")
    func matrixInDegrees() {
        let wheel = AdjacencyMatrix.wheel(vertexCount: 6)
        #expect((0 ..< 6).map { wheel.inDegree(of: $0) } == [0, 2, 2, 2, 2, 2])
        #expect((0 ..< 6).map { wheel.outDegree(of: $0) } == [5, 1, 1, 1, 1, 1])
        let star = AdjacencyMatrix.star(vertexCount: 4)
        #expect((0 ..< 4).map { star.inDegree(of: $0) } == [0, 1, 1, 1])
    }

    @Test("AdjacencyList<Int>: a generated wheel has the in-rows of its edge-by-edge build, and keeps every row in step through edits")
    func adjacencyListRows() {
        var bulk = AdjacencyList<Int>.wheel(vertexCount: 6)
        var built = AdjacencyList<Int>(vertices: 0 ..< 6)
        for e in Array(bulk.edges) { built.insert(edge: e) }
        for step in 0 ..< 7 {
            switch step {
            case 1: bulk.insert(edge: DirectedEdge(from: 2, to: 0)); built.insert(edge: DirectedEdge(from: 2, to: 0))
            case 2: bulk.insert(edge: DirectedEdge(from: 1, to: 3)); built.insert(edge: DirectedEdge(from: 1, to: 3))
            case 3: #expect(bulk.remove(edge: DirectedEdge(from: 0, to: 2)) != nil && built.remove(edge: DirectedEdge(from: 0, to: 2)) != nil)
            case 4: #expect(bulk.remove(edge: DirectedEdge(from: 3, to: 4)) != nil && built.remove(edge: DirectedEdge(from: 3, to: 4)) != nil)
            case 5: #expect(bulk.remove(1) == 1 && built.remove(1) == 1)
            case 6: #expect(bulk.remove(0) == 0 && built.remove(0) == 0)
            default: break
            }
            #expect(Array(bulk.edges) == Array(built.edges), "step \(step)")
            for v in built.vertices.sorted() {
                #expect(Array(bulk.successors(of: v)) == Array(built.successors(of: v)), "step \(step), successors of \(v)")
                #expect(Array(bulk.predecessors(of: v)) == Array(built.predecessors(of: v)), "step \(step), predecessors of \(v)")
                #expect(bulk.inDegree(of: v) == built.inDegree(of: v), "step \(step), in-degree of \(v)")
            }
        }
    }

    @Test("DirectedPseudograph<Int>: a generated wheel has the rows of its edge-by-edge build, and keeps them in step through edits and parallel copies")
    func directedPseudographRows() {
        var bulk = DirectedPseudograph<Int>.wheel(vertexCount: 6)
        var built = DirectedPseudograph<Int>(vertices: 0 ..< 6)
        for e in Array(bulk.edges) { _ = built.insert(edge: e) }
        for step in 0 ..< 8 {
            switch step {
            case 1: _ = bulk.insert(edge: DirectedEdge(from: 2, to: 0)); _ = built.insert(edge: DirectedEdge(from: 2, to: 0))
            case 2: _ = bulk.insert(edge: DirectedEdge(from: 0, to: 3)); _ = built.insert(edge: DirectedEdge(from: 0, to: 3))
            case 3: #expect(bulk.remove(edge: DirectedEdge(from: 0, to: 2)) != nil && built.remove(edge: DirectedEdge(from: 0, to: 2)) != nil)
            case 4: #expect(bulk.remove(edge: DirectedEdge(from: 0, to: 3)) != nil && built.remove(edge: DirectedEdge(from: 0, to: 3)) != nil)
            case 5: #expect(bulk.remove(edge: DirectedEdge(from: 0, to: 3)) != nil && built.remove(edge: DirectedEdge(from: 0, to: 3)) != nil)
            case 6: #expect(bulk.remove(1) == 1 && built.remove(1) == 1)
            case 7: #expect(bulk.remove(0) == 0 && built.remove(0) == 0)
            default: break
            }
            #expect(Array(bulk.edges) == Array(built.edges), "step \(step)")
            #expect(bulk == built, "step \(step)")
            for v in built.vertices.sorted() {
                #expect(Array(bulk.successors(of: v)) == Array(built.successors(of: v)), "step \(step), successors of \(v)")
                #expect(Array(bulk.predecessors(of: v)) == Array(built.predecessors(of: v)), "step \(step), predecessors of \(v)")
            }
        }
        #expect(!bulk.contains(edge: DirectedEdge(from: 3, to: 0)))
    }

    @Test("DirectedMultigraph<Int>: a generated complete digraph keeps its rows in step with its edge-by-edge build through edits and parallel copies")
    func directedMultigraphRows() {
        var bulk = DirectedMultigraph<Int>.complete(vertexCount: 4)
        var built = DirectedMultigraph<Int>(vertices: 0 ..< 4)
        for e in Array(bulk.edges) { _ = built.insert(edge: e) }
        for step in 0 ..< 6 {
            switch step {
            case 1: _ = bulk.insert(edge: DirectedEdge(from: 1, to: 2)); _ = built.insert(edge: DirectedEdge(from: 1, to: 2))
            case 2: #expect(bulk.remove(edge: DirectedEdge(from: 1, to: 2)) != nil && built.remove(edge: DirectedEdge(from: 1, to: 2)) != nil)
            case 3: #expect(bulk.remove(edge: DirectedEdge(from: 1, to: 2)) != nil && built.remove(edge: DirectedEdge(from: 1, to: 2)) != nil)
            case 4: #expect(bulk.remove(edge: DirectedEdge(from: 3, to: 0)) != nil && built.remove(edge: DirectedEdge(from: 3, to: 0)) != nil)
            case 5: #expect(bulk.remove(0) == 0 && built.remove(0) == 0)
            default: break
            }
            #expect(Array(bulk.edges) == Array(built.edges), "step \(step)")
            #expect(bulk == built, "step \(step)")
            for v in built.vertices.sorted() {
                #expect(Array(bulk.successors(of: v)) == Array(built.successors(of: v)), "step \(step), successors of \(v)")
                #expect(Array(bulk.predecessors(of: v)) == Array(built.predecessors(of: v)), "step \(step), predecessors of \(v)")
            }
        }
        #expect(!bulk.contains(edge: DirectedEdge(from: 1, to: 2)))
    }

    @Test("UndirectedAdjacencyList<Int>: a generated wheel keeps its rows and incident edges in step with its edge-by-edge build through edits")
    func undirectedRows() {
        var bulk = UndirectedAdjacencyList<Int>.wheel(vertexCount: 6)
        var built = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6)
        for e in Array(bulk.edges) { built.insert(edge: e) }
        for step in 0 ..< 6 {
            switch step {
            case 1: bulk.insert(edge: UndirectedEdge(0, 6)); built.insert(edge: UndirectedEdge(0, 6))
            case 2: bulk.insert(edge: UndirectedEdge(2, 4)); built.insert(edge: UndirectedEdge(2, 4))
            case 3: #expect(bulk.remove(edge: UndirectedEdge(0, 2)) != nil && built.remove(edge: UndirectedEdge(0, 2)) != nil)
            case 4: #expect(bulk.remove(1) == 1 && built.remove(1) == 1)
            case 5: #expect(bulk.remove(0) == 0 && built.remove(0) == 0)
            default: break
            }
            #expect(Array(bulk.edges).map { [$0.u, $0.v] } == Array(built.edges).map { [$0.u, $0.v] }, "step \(step)")
            for v in built.vertices.sorted() {
                #expect(Array(bulk.neighbors(of: v)) == Array(built.neighbors(of: v)), "step \(step), neighbors of \(v)")
                #expect(Array(bulk.incidentEdges(of: v)) == Array(built.incidentEdges(of: v)), "step \(step), incident edges of \(v)")
            }
        }
    }

    @Test("Pseudograph<Int>: a generated wheel keeps its rows in step with its edge-by-edge build through edits and parallel copies")
    func pseudographRows() {
        var bulk = Pseudograph<Int>.wheel(vertexCount: 6)
        var built = Pseudograph<Int>(vertices: 0 ..< 6)
        for e in Array(bulk.edges) { _ = built.insert(edge: e) }
        for step in 0 ..< 7 {
            switch step {
            case 1: _ = bulk.insert(edge: UndirectedEdge(1, 2)); _ = built.insert(edge: UndirectedEdge(1, 2))
            case 2: _ = bulk.insert(edge: UndirectedEdge(3, 3)); _ = built.insert(edge: UndirectedEdge(3, 3))
            case 3: #expect(bulk.remove(edge: UndirectedEdge(1, 2)) != nil && built.remove(edge: UndirectedEdge(1, 2)) != nil)
            case 4: #expect(bulk.remove(edge: UndirectedEdge(1, 2)) != nil && built.remove(edge: UndirectedEdge(1, 2)) != nil)
            case 5: #expect(bulk.remove(edge: UndirectedEdge(0, 4)) != nil && built.remove(edge: UndirectedEdge(0, 4)) != nil)
            case 6: #expect(bulk.remove(1) == 1 && built.remove(1) == 1)
            default: break
            }
            #expect(Array(bulk.edges).map { [$0.u, $0.v] } == Array(built.edges).map { [$0.u, $0.v] }, "step \(step)")
            #expect(bulk == built, "step \(step)")
            for v in built.vertices.sorted() {
                #expect(Array(bulk.neighbors(of: v)) == Array(built.neighbors(of: v)), "step \(step), neighbors of \(v)")
                #expect(Array(bulk.incidentEdges(of: v)) == Array(built.incidentEdges(of: v)), "step \(step), incident edges of \(v)")
            }
        }
        #expect(!bulk.contains(edge: UndirectedEdge(1, 2)))
    }

    @Test("Multigraph<Int>: a generated complete graph keeps its rows in step with its edge-by-edge build through edits and parallel copies")
    func multigraphRows() {
        var bulk = Multigraph<Int>.complete(vertexCount: 5)
        var built = Multigraph<Int>(vertices: 0 ..< 5)
        for e in Array(bulk.edges) { _ = built.insert(edge: e) }
        for step in 0 ..< 6 {
            switch step {
            case 1: _ = bulk.insert(edge: UndirectedEdge(2, 3)); _ = built.insert(edge: UndirectedEdge(2, 3))
            case 2: #expect(bulk.remove(edge: UndirectedEdge(2, 3)) != nil && built.remove(edge: UndirectedEdge(2, 3)) != nil)
            case 3: #expect(bulk.remove(edge: UndirectedEdge(0, 1)) != nil && built.remove(edge: UndirectedEdge(0, 1)) != nil)
            case 4: #expect(bulk.remove(edge: UndirectedEdge(2, 3)) != nil && built.remove(edge: UndirectedEdge(2, 3)) != nil)
            case 5: #expect(bulk.remove(4) == 4 && built.remove(4) == 4)
            default: break
            }
            #expect(Array(bulk.edges).map { [$0.u, $0.v] } == Array(built.edges).map { [$0.u, $0.v] }, "step \(step)")
            #expect(bulk == built, "step \(step)")
            for v in built.vertices.sorted() {
                #expect(Array(bulk.neighbors(of: v)) == Array(built.neighbors(of: v)), "step \(step), neighbors of \(v)")
            }
        }
        #expect(!bulk.contains(edge: UndirectedEdge(2, 3)) && !bulk.contains(edge: UndirectedEdge(0, 1)))
    }

    @Test("BipartiteGraph.completeBipartite: removing right and left vertices keeps the sides")
    func bipartiteSidesAfterRemovals() {
        var graph = BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: 3)
        #expect(graph.remove(2) == 2)
        #expect(Set(graph.left) == [0, 1] && Set(graph.right) == [3, 4])
        #expect(graph.remove(3) == 3)
        #expect(Set(graph.left) == [0, 1] && Set(graph.right) == [4])
        #expect(graph.remove(0) == 0)
        #expect(Set(graph.left) == [1] && Set(graph.right) == [4])
        #expect(graph.side(of: 1) == .left && graph.side(of: 4) == .right)
        #expect(graph.edgeCount == 1 && graph.contains(edge: UndirectedEdge(1, 4)))
    }

    @Test("balancedTree with branching factor 0 is the root alone, whatever the height, at once")
    func balancedTreeOfBranchingZero() {
        let graph = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 0, height: Int.max)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        let tree = Tree<Int>.balancedTree(branchingFactor: 0, height: Int.max)
        #expect(tree.vertexCount == 1 && tree.edgeCount == 0)
    }
}
