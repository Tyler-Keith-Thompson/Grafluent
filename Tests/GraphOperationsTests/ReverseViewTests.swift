// reverseView (catalog GO-001 – GO-009): every arc flipped, vertices, indices and positions the
// base's; successors are the base's predecessors in its in-row order; the reverse of a reverse
// is the base; a label-space row hashes once and an index-space row not at all.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphOperations
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphOperations reverseView")
struct ReverseViewTests {
    @Test("GO-001 empty")
    func go001() {
        // AL V []; E [] / .reverseView
        // Expected: V []; E []; bounds 0/0
        let graph = AdjacencyList<String>(vertices: [] as [String], edges: [] as [DirectedEdge<String>])
        let view = graph.reverseView
        #expect(Array(view.vertices) == [] as [String])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [] as [Int])
        #expect((0 ..< 0).map { view.vertex(atIndex: $0) } == [] as [String])
        #expect(view.vertexCount == 0 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 0 && view.edgeIndexBound == 0)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
    }

    @Test("GO-002 isolated vertices keep their order")
    func go002() {
        // AL V [a, b, c]; E [] / .reverseView
        // Expected: V [a#0, b#1, c#2]; E []; bounds 3/0
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [] as [DirectedEdge<String>])
        let view = graph.reverseView
        #expect(Array(view.vertices) == ["a", "b", "c"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { view.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(view.vertexCount == 3 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 3 && view.edgeIndexBound == 0)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 0)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [] as [Int])
        #expect(Array(view.outEdges(of: "b")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 1)) == [] as [Int])
        #expect(view.outDegree(of: "b") == 0 && view.outDegree(ofIndex: 1) == 0)
        #expect(Array(view.predecessors(of: "b")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [] as [Int])
        #expect(Array(view.inEdges(of: "b")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 1)) == [] as [Int])
        #expect(view.inDegree(of: "b") == 0 && view.inDegree(ofIndex: 1) == 0 && view.degree(of: "b") == 0)
        #expect(view.contains("c"))
        #expect(Array(view.successors(of: "c")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 2)) == [] as [Int])
        #expect(Array(view.outEdges(of: "c")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 2)) == [] as [Int])
        #expect(view.outDegree(of: "c") == 0 && view.outDegree(ofIndex: 2) == 0)
        #expect(Array(view.predecessors(of: "c")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 2)) == [] as [Int])
        #expect(Array(view.inEdges(of: "c")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 2)) == [] as [Int])
        #expect(view.inDegree(of: "c") == 0 && view.inDegree(ofIndex: 2) == 0 && view.degree(of: "c") == 0)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, false, false, false, false, false, false, false, false])
    }

    @Test("GO-003 path: arcs flip, positions kept")
    func go003() {
        // AL V [a, b, c]; E [a→b, b→c] / .reverseView
        // Expected: V [a#0, b#1, c#2]; E [0:b→a, 1:c→b]; bounds 3/2; rows [a: ; b: a; c: b]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let view = graph.reverseView
        #expect(Array(view.vertices) == ["a", "b", "c"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { view.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(view.vertexCount == 3 && view.edgeCount == 2 && view.edges.count == 2)
        #expect(view.vertexIndexBound == 3 && view.edgeIndexBound == 2)
        #expect(Array(view.edges.indices) == [0, 1])
        #expect(view.edges.map { [$0.source, $0.target] } == [["b", "a"], ["c", "b"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["b", "a"], ["c", "b"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0], [2, 1]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0, 1])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == ["b"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.inEdges(of: "a")) == [0])
        #expect(Array(view.inEdges(ofIndex: 0)) == [0])
        #expect(view.inDegree(of: "a") == 1 && view.inDegree(ofIndex: 0) == 1 && view.degree(of: "a") == 1)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == ["a"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.outEdges(of: "b")) == [0])
        #expect(Array(view.outEdges(ofIndex: 1)) == [0])
        #expect(view.outDegree(of: "b") == 1 && view.outDegree(ofIndex: 1) == 1)
        #expect(Array(view.predecessors(of: "b")) == ["c"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [2])
        #expect(Array(view.inEdges(of: "b")) == [1])
        #expect(Array(view.inEdges(ofIndex: 1)) == [1])
        #expect(view.inDegree(of: "b") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "b") == 2)
        #expect(view.contains("c"))
        #expect(Array(view.successors(of: "c")) == ["b"])
        #expect(Array(view.successorIndices(ofIndex: 2)) == [1])
        #expect(Array(view.outEdges(of: "c")) == [1])
        #expect(Array(view.outEdges(ofIndex: 2)) == [1])
        #expect(view.outDegree(of: "c") == 1 && view.outDegree(ofIndex: 2) == 1)
        #expect(Array(view.predecessors(of: "c")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 2)) == [] as [Int])
        #expect(Array(view.inEdges(of: "c")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 2)) == [] as [Int])
        #expect(view.inDegree(of: "c") == 0 && view.inDegree(ofIndex: 2) == 0 && view.degree(of: "c") == 1)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, false, false, true, false, false, false, true, false])
    }

    @Test("GO-004 self-loop stays a self-loop")
    func go004() {
        // AL V [a]; E [a→a] / .reverseView
        // Expected: V [a#0]; E [0:a→a]; bounds 1/1; rows [a: a]
        let graph = DirectedPseudograph<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
        let view = graph.reverseView
        #expect(Array(view.vertices) == ["a"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { view.vertex(atIndex: $0) } == ["a"])
        #expect(view.vertexCount == 1 && view.edgeCount == 1 && view.edges.count == 1)
        #expect(view.vertexIndexBound == 1 && view.edgeIndexBound == 1)
        #expect(Array(view.edges.indices) == [0])
        #expect(view.edges.map { [$0.source, $0.target] } == [["a", "a"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["a", "a"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == ["a"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [0])
        #expect(Array(view.outEdges(of: "a")) == [0])
        #expect(Array(view.outEdges(ofIndex: 0)) == [0])
        #expect(view.outDegree(of: "a") == 1 && view.outDegree(ofIndex: 0) == 1)
        #expect(Array(view.predecessors(of: "a")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [0])
        #expect(Array(view.inEdges(of: "a")) == [0])
        #expect(Array(view.inEdges(ofIndex: 0)) == [0])
        #expect(view.inDegree(of: "a") == 1 && view.inDegree(ofIndex: 0) == 1 && view.degree(of: "a") == 2)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [true])
    }

    @Test("GO-005 parallel arcs keep both positions")
    func go005() {
        // AL V [a, b]; E [a→b, a→b, b→a] / .reverseView
        // Expected: V [a#0, b#1]; E [0:b→a, 1:b→a, 2:a→b]; bounds 2/3; rows [a: b; b: a a]
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        let view = graph.reverseView
        #expect(Array(view.vertices) == ["a", "b"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { view.vertex(atIndex: $0) } == ["a", "b"])
        #expect(view.vertexCount == 2 && view.edgeCount == 3 && view.edges.count == 3)
        #expect(view.vertexIndexBound == 2 && view.edgeIndexBound == 3)
        #expect(Array(view.edges.indices) == [0, 1, 2])
        #expect(view.edges.map { [$0.source, $0.target] } == [["b", "a"], ["b", "a"], ["a", "b"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["b", "a"], ["b", "a"], ["a", "b"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0], [1, 0], [0, 1]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0, 1, 2])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == ["b"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.outEdges(of: "a")) == [2])
        #expect(Array(view.outEdges(ofIndex: 0)) == [2])
        #expect(view.outDegree(of: "a") == 1 && view.outDegree(ofIndex: 0) == 1)
        #expect(Array(view.predecessors(of: "a")) == ["b", "b"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [1, 1])
        #expect(Array(view.inEdges(of: "a")) == [0, 1])
        #expect(Array(view.inEdges(ofIndex: 0)) == [0, 1])
        #expect(view.inDegree(of: "a") == 2 && view.inDegree(ofIndex: 0) == 2 && view.degree(of: "a") == 3)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == ["a", "a"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [0, 0])
        #expect(Array(view.outEdges(of: "b")) == [0, 1])
        #expect(Array(view.outEdges(ofIndex: 1)) == [0, 1])
        #expect(view.outDegree(of: "b") == 2 && view.outDegree(ofIndex: 1) == 2)
        #expect(Array(view.predecessors(of: "b")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.inEdges(of: "b")) == [2])
        #expect(Array(view.inEdges(ofIndex: 1)) == [2])
        #expect(view.inDegree(of: "b") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "b") == 3)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, true, true, false])
    }

    @Test("GO-006 successors are the base's predecessors in in-row order")
    func go006() {
        // AL V [a, b, c, d]; E [b→a, c→a, d→a, a→b] / .reverseView
        // Expected: V [a#0, b#1, c#2, d#3]; E [0:a→b, 1:a→c, 2:a→d, 3:b→a]; bounds 4/4; rows [a: b c d; b: a; c: ; d: ]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "d", to: "a"), DirectedEdge(from: "a", to: "b")])
        let view = graph.reverseView
        #expect(Array(view.vertices) == ["a", "b", "c", "d"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1, 2, 3])
        #expect((0 ..< 4).map { view.vertex(atIndex: $0) } == ["a", "b", "c", "d"])
        #expect(view.vertexCount == 4 && view.edgeCount == 4 && view.edges.count == 4)
        #expect(view.vertexIndexBound == 4 && view.edgeIndexBound == 4)
        #expect(Array(view.edges.indices) == [0, 1, 2, 3])
        #expect(view.edges.map { [$0.source, $0.target] } == [["a", "b"], ["a", "c"], ["a", "d"], ["b", "a"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "c"], ["a", "d"], ["b", "a"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1], [0, 2], [0, 3], [1, 0]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0, 1, 2, 3])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == ["b", "c", "d"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [1, 2, 3])
        #expect(Array(view.outEdges(of: "a")) == [0, 1, 2])
        #expect(Array(view.outEdges(ofIndex: 0)) == [0, 1, 2])
        #expect(view.outDegree(of: "a") == 3 && view.outDegree(ofIndex: 0) == 3)
        #expect(Array(view.predecessors(of: "a")) == ["b"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.inEdges(of: "a")) == [3])
        #expect(Array(view.inEdges(ofIndex: 0)) == [3])
        #expect(view.inDegree(of: "a") == 1 && view.inDegree(ofIndex: 0) == 1 && view.degree(of: "a") == 4)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == ["a"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.outEdges(of: "b")) == [3])
        #expect(Array(view.outEdges(ofIndex: 1)) == [3])
        #expect(view.outDegree(of: "b") == 1 && view.outDegree(ofIndex: 1) == 1)
        #expect(Array(view.predecessors(of: "b")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.inEdges(of: "b")) == [0])
        #expect(Array(view.inEdges(ofIndex: 1)) == [0])
        #expect(view.inDegree(of: "b") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "b") == 2)
        #expect(view.contains("c"))
        #expect(Array(view.successors(of: "c")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 2)) == [] as [Int])
        #expect(Array(view.outEdges(of: "c")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 2)) == [] as [Int])
        #expect(view.outDegree(of: "c") == 0 && view.outDegree(ofIndex: 2) == 0)
        #expect(Array(view.predecessors(of: "c")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 2)) == [0])
        #expect(Array(view.inEdges(of: "c")) == [1])
        #expect(Array(view.inEdges(ofIndex: 2)) == [1])
        #expect(view.inDegree(of: "c") == 1 && view.inDegree(ofIndex: 2) == 1 && view.degree(of: "c") == 1)
        #expect(view.contains("d"))
        #expect(Array(view.successors(of: "d")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 3)) == [] as [Int])
        #expect(Array(view.outEdges(of: "d")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 3)) == [] as [Int])
        #expect(view.outDegree(of: "d") == 0 && view.outDegree(ofIndex: 3) == 0)
        #expect(Array(view.predecessors(of: "d")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 3)) == [0])
        #expect(Array(view.inEdges(of: "d")) == [2])
        #expect(Array(view.inEdges(ofIndex: 3)) == [2])
        #expect(view.inDegree(of: "d") == 1 && view.inDegree(ofIndex: 3) == 1 && view.degree(of: "d") == 1)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false])
    }

    @Test("GO-007 edge indices forwarded")
    func go007() {
        // AL V [x, y, z]; E [x→y, y→z, z→x] / .reverseView
        // Expected: V [x#0, y#1, z#2]; E [0:y→x, 1:z→y, 2:x→z]; bounds 3/3; edgeIndex(of: 2) 2; sourceIndex(ofEdgeAt: 2) 0
        let graph = AdjacencyList<String>(vertices: ["x", "y", "z"], edges: [DirectedEdge(from: "x", to: "y"), DirectedEdge(from: "y", to: "z"), DirectedEdge(from: "z", to: "x")])
        let view = graph.reverseView
        #expect(view.edgeIndex(of: 2) == 2 && view.sourceIndex(ofEdgeAt: 2) == 0)
        #expect(Array(view.vertices) == ["x", "y", "z"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { view.vertex(atIndex: $0) } == ["x", "y", "z"])
        #expect(view.vertexCount == 3 && view.edgeCount == 3 && view.edges.count == 3)
        #expect(view.vertexIndexBound == 3 && view.edgeIndexBound == 3)
        #expect(Array(view.edges.indices) == [0, 1, 2])
        #expect(view.edges.map { [$0.source, $0.target] } == [["y", "x"], ["z", "y"], ["x", "z"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["y", "x"], ["z", "y"], ["x", "z"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0], [2, 1], [0, 2]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0, 1, 2])
        #expect(view.contains("x"))
        #expect(Array(view.successors(of: "x")) == ["z"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [2])
        #expect(Array(view.outEdges(of: "x")) == [2])
        #expect(Array(view.outEdges(ofIndex: 0)) == [2])
        #expect(view.outDegree(of: "x") == 1 && view.outDegree(ofIndex: 0) == 1)
        #expect(Array(view.predecessors(of: "x")) == ["y"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.inEdges(of: "x")) == [0])
        #expect(Array(view.inEdges(ofIndex: 0)) == [0])
        #expect(view.inDegree(of: "x") == 1 && view.inDegree(ofIndex: 0) == 1 && view.degree(of: "x") == 2)
        #expect(view.contains("y"))
        #expect(Array(view.successors(of: "y")) == ["x"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.outEdges(of: "y")) == [0])
        #expect(Array(view.outEdges(ofIndex: 1)) == [0])
        #expect(view.outDegree(of: "y") == 1 && view.outDegree(ofIndex: 1) == 1)
        #expect(Array(view.predecessors(of: "y")) == ["z"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [2])
        #expect(Array(view.inEdges(of: "y")) == [1])
        #expect(Array(view.inEdges(ofIndex: 1)) == [1])
        #expect(view.inDegree(of: "y") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "y") == 2)
        #expect(view.contains("z"))
        #expect(Array(view.successors(of: "z")) == ["y"])
        #expect(Array(view.successorIndices(ofIndex: 2)) == [1])
        #expect(Array(view.outEdges(of: "z")) == [1])
        #expect(Array(view.outEdges(ofIndex: 2)) == [1])
        #expect(view.outDegree(of: "z") == 1 && view.outDegree(ofIndex: 2) == 1)
        #expect(Array(view.predecessors(of: "z")) == ["x"])
        #expect(Array(view.predecessorIndices(ofIndex: 2)) == [0])
        #expect(Array(view.inEdges(of: "z")) == [2])
        #expect(Array(view.inEdges(ofIndex: 2)) == [2])
        #expect(view.inDegree(of: "z") == 1 && view.inDegree(ofIndex: 2) == 1 && view.degree(of: "z") == 2)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, false, true, true, false, false, false, true, false])
    }

    @Test("GO-008 reverse of the reverse is the base (same type, O(1))")
    func go008() {
        // AL V [a, b, c]; E [a→b, b→c] / .reverseView.reverseView
        // Expected: V [a#0, b#1, c#2]; E [0:a→b, 1:b→c]; bounds 3/2; is the base: true
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let view = graph.reverseView.reverseView
        // The reverse of a reverse is the base itself, of the base's type.
        let back: AdjacencyList<String> = graph.reverseView.reverseView
        #expect(back == graph)
        #expect(Array(view.vertices) == ["a", "b", "c"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { view.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(view.vertexCount == 3 && view.edgeCount == 2 && view.edges.count == 2)
        #expect(view.vertexIndexBound == 3 && view.edgeIndexBound == 2)
        #expect(Array(view.edges.indices) == [0, 1])
        #expect(view.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1], [1, 2]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0, 1])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == ["b"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.outEdges(of: "a")) == [0])
        #expect(Array(view.outEdges(ofIndex: 0)) == [0])
        #expect(view.outDegree(of: "a") == 1 && view.outDegree(ofIndex: 0) == 1)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 1)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == ["c"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [2])
        #expect(Array(view.outEdges(of: "b")) == [1])
        #expect(Array(view.outEdges(ofIndex: 1)) == [1])
        #expect(view.outDegree(of: "b") == 1 && view.outDegree(ofIndex: 1) == 1)
        #expect(Array(view.predecessors(of: "b")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.inEdges(of: "b")) == [0])
        #expect(Array(view.inEdges(ofIndex: 1)) == [0])
        #expect(view.inDegree(of: "b") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "b") == 2)
        #expect(view.contains("c"))
        #expect(Array(view.successors(of: "c")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 2)) == [] as [Int])
        #expect(Array(view.outEdges(of: "c")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 2)) == [] as [Int])
        #expect(view.outDegree(of: "c") == 0 && view.outDegree(ofIndex: 2) == 0)
        #expect(Array(view.predecessors(of: "c")) == ["b"])
        #expect(Array(view.predecessorIndices(ofIndex: 2)) == [1])
        #expect(Array(view.inEdges(of: "c")) == [1])
        #expect(Array(view.inEdges(ofIndex: 2)) == [1])
        #expect(view.inDegree(of: "c") == 1 && view.inDegree(ofIndex: 2) == 1 && view.degree(of: "c") == 1)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, true, false, false, false, true, false, false, false])
    }

    @Test("GO-009 a vertex lookup hashes once, rows none")
    func go009() {
        // AL V [a, b, c]; E [a→b, c→b] / .reverseView
        // Expected: V [a#0, b#1, c#2]; E [0:b→a, 1:b→c]; bounds 3/2; outEdges(of: b) [0, 1]; inEdges(ofIndex: 1) []; hashes 1
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "b")])
        let view = graph.reverseView
        #expect(Array(view.vertices) == ["a", "b", "c"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { view.vertex(atIndex: $0) } == ["a", "b", "c"])
        #expect(view.vertexCount == 3 && view.edgeCount == 2 && view.edges.count == 2)
        #expect(view.vertexIndexBound == 3 && view.edgeIndexBound == 2)
        #expect(Array(view.edges.indices) == [0, 1])
        #expect(view.edges.map { [$0.source, $0.target] } == [["b", "a"], ["b", "c"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["b", "a"], ["b", "c"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0], [1, 2]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0, 1])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == ["b"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.inEdges(of: "a")) == [0])
        #expect(Array(view.inEdges(ofIndex: 0)) == [0])
        #expect(view.inDegree(of: "a") == 1 && view.inDegree(ofIndex: 0) == 1 && view.degree(of: "a") == 1)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == ["a", "c"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [0, 2])
        #expect(Array(view.outEdges(of: "b")) == [0, 1])
        #expect(Array(view.outEdges(ofIndex: 1)) == [0, 1])
        #expect(view.outDegree(of: "b") == 2 && view.outDegree(ofIndex: 1) == 2)
        #expect(Array(view.predecessors(of: "b")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [] as [Int])
        #expect(Array(view.inEdges(of: "b")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 1)) == [] as [Int])
        #expect(view.inDegree(of: "b") == 0 && view.inDegree(ofIndex: 1) == 0 && view.degree(of: "b") == 2)
        #expect(view.contains("c"))
        #expect(Array(view.successors(of: "c")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 2)) == [] as [Int])
        #expect(Array(view.outEdges(of: "c")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 2)) == [] as [Int])
        #expect(view.outDegree(of: "c") == 0 && view.outDegree(ofIndex: 2) == 0)
        #expect(Array(view.predecessors(of: "c")) == ["b"])
        #expect(Array(view.predecessorIndices(ofIndex: 2)) == [1])
        #expect(Array(view.inEdges(of: "c")) == [1])
        #expect(Array(view.inEdges(ofIndex: 2)) == [1])
        #expect(view.inDegree(of: "c") == 1 && view.inDegree(ofIndex: 2) == 1 && view.degree(of: "c") == 1)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, false, false, true, false, true, false, false, false])
        // Hashes, on the same graph over a counting vertex type.
        do {
            // Vertex hashes, counted by a vertex type whose hash(into:) counts. The base's dictionary
            // hashes a vertex once per lookup.
            final class Tally {
                var hashes = 0
            }
            struct Counted: Hashable {
                let name: String
                let tally: Tally
                static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
                func hash(into hasher: inout Hasher) {
                    tally.hashes += 1
                    hasher.combine(name)
                }
            }
            let tally = Tally()
            func label(_ name: String) -> Counted { Counted(name: name, tally: tally) }
            let counted = AdjacencyList<Counted>(vertices: ["a", "b", "c"].map(label), edges: [DirectedEdge(from: label("a"), to: label("b")), DirectedEdge(from: label("c"), to: label("b"))])
            let reversed = counted.reverseView
            tally.hashes = 0
            let out = Array(reversed.outEdges(of: label("b")))
            #expect(tally.hashes == 1)
            tally.hashes = 0
            let into = Array(reversed.inEdges(ofIndex: 1))
            let row = Array(reversed.successorIndices(ofIndex: 1)) + Array(reversed.predecessorIndices(ofIndex: 1))
            #expect(tally.hashes == 0)
            #expect(out == [0, 1] && into == [] && row == [0, 2])
        }
    }
}
