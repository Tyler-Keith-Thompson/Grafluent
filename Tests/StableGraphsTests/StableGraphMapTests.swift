// Maps (catalog SG-131 – SG-134, SG-139 – SG-141): maps attached to the graph (`addEdgeMap(of:)`,
// `addEdgeMap(default:)`, `addVertexMap`), values by position or vertex, every removal path removing
// the removed element's values (a removed element has none: its checked read throws), several maps,
// a copy keeping its values, `changeTarget` keeping them, `removeEdgeMap`, defaults for every new
// element, `values(of:)`, and map pages freed with the graph's.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs maps")
struct StableGraphMapTests {
    @Test("SG-131 attached EdgeMap of an Optional: set, get, nil clears; a removed edge has no value")
    func sg131() throws {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0] / let labels = addEdgeMap(of: String.self) / [labels, ofEdgeAt: 0] = "a" / [labels, ofEdgeAt: 1] = "b" / [labels, ofEdgeAt: 2] = "c" / [labels, ofEdgeAt: 1] / [labels, ofEdgeAt: 2] = nil / [labels, ofEdgeAt: 2] / remove(edgeAt: 1) / [labels, checkedEdgeAt: 1] / insert(edge: 0→2) / [labels, ofEdgeAt: 3] / values of labels
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let labels = graph.addEdgeMap(of: String.self)
        graph[labels, ofEdgeAt: 0] = "a"
        graph[labels, ofEdgeAt: 1] = "b"
        graph[labels, ofEdgeAt: 2] = "c"
        #expect(graph[labels, ofEdgeAt: 1] == "b")
        graph[labels, ofEdgeAt: 2] = nil
        #expect(graph[labels, ofEdgeAt: 2] == nil)
        #expect(graph.remove(edgeAt: 1) == DirectedEdge(from: 1, to: 2))
        #expect(throws: EdgeNotFound.self) { try graph[labels, checkedEdgeAt: 1] }
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 2)) == 3)
        #expect(graph[labels, ofEdgeAt: 3] == nil)
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[labels, checkedEdgeAt: $0]) != nil } == [0])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[labels, checkedEdgeAt: $0] } == ["a"])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.vertices.indices) == [0, 1, 2])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 3)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [2, 0], [0, 2]])
        #expect(Array(graph.edges.indices) == [0, 2, 3])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 4)
        #expect(graph.vertexIndexBound == 3)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 3)
        #expect(graph.vertices.count == 3)
        #expect(graph.edgeCount == 3)
        #expect(graph.edges.count == 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [2, 0], [0, 2]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1, 2])
        #expect(Array(graph.outEdges(of: 0)) == [0, 3])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.inEdges(of: 0)) == [2])
        #expect(graph.outDegree(of: 0) == 2 && graph.inDegree(of: 0) == 1 && graph.degree(of: 0) == 3)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 1 && graph.degree(of: 1) == 1)
        #expect(graph.vertices.firstIndex(of: 2) == 2)
        #expect(graph.vertices[2] == 2)
        #expect(Array(graph.successors(of: 2)) == [0])
        #expect(Array(graph.outEdges(of: 2)) == [2])
        #expect(Array(graph.predecessors(of: 2)) == [0])
        #expect(Array(graph.inEdges(of: 2)) == [3])
        #expect(graph.outDegree(of: 2) == 1 && graph.inDegree(of: 2) == 1 && graph.degree(of: 2) == 2)
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(Array(graph.edges(from: 2, to: 0)) == [2])
        #expect(graph.edgeCount(from: 2, to: 0) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 2, to: 0)))
        #expect(Array(graph.edges(from: 0, to: 2)) == [3])
        #expect(graph.edgeCount(from: 0, to: 2) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 2)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { graph.vertex(atIndex: $0) } == [0, 1, 2])
    }

    @Test("SG-132 every edge removal path removes the values")
    func sg132() throws {
        // V [0, 1, 2, 3]; E [0→1, 0→1, 1→2, 2→3, 3→0, 0→2, 1→1, 2→2] / let w = addEdgeMap(of: Int.self) / [w, ofEdgeAt: 0] = 0 / [w, ofEdgeAt: 1] = 10 / [w, ofEdgeAt: 2] = 20 / [w, ofEdgeAt: 3] = 30 / [w, ofEdgeAt: 4] = 40 / [w, ofEdgeAt: 5] = 50 / [w, ofEdgeAt: 6] = 60 / [w, ofEdgeAt: 7] = 70 / remove(edge: 0→1) / values of w / removeAllEdges(from: 2, to: 3) / removeAllEdges(from: 0, where: { [5].contains($0) }) / removeAllEdges(where: { [6].contains($0) }) / remove(3) / values of w / removeAllEdges() / insert(edge: 1→2) / [w, ofEdgeAt: 0] / values of w
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 2)])
        let w = graph.addEdgeMap(of: Int.self)
        graph[w, ofEdgeAt: 0] = 0
        graph[w, ofEdgeAt: 1] = 10
        graph[w, ofEdgeAt: 2] = 20
        graph[w, ofEdgeAt: 3] = 30
        graph[w, ofEdgeAt: 4] = 40
        graph[w, ofEdgeAt: 5] = 50
        graph[w, ofEdgeAt: 6] = 60
        graph[w, ofEdgeAt: 7] = 70
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)) == DirectedEdge(from: 0, to: 1))
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [0, 2, 3, 4, 5, 6, 7])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[w, checkedEdgeAt: $0] } == [0, 20, 30, 40, 50, 60, 70])
        #expect(graph.removeAllEdges(from: 2, to: 3) == 1)
        do {
            var visited: [Int] = []
            let removed = graph.removeAllEdges(from: 0, where: { visited.append($0); return [5].contains($0) })
            #expect(removed == 1)
            #expect(visited == [0, 5])
        }
        do {
            var visited: [Int] = []
            let removed = graph.removeAllEdges(where: { visited.append($0); return [6].contains($0) })
            #expect(removed == 1)
            #expect(visited == [0, 2, 6, 7, 4])
        }
        #expect(graph.remove(3) == 3)
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [0, 2, 7])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[w, checkedEdgeAt: $0] } == [0, 20, 70])
        graph.removeAllEdges()
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 2)) == 0)
        #expect(graph[w, ofEdgeAt: 0] == nil)
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [] as [Int])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[w, checkedEdgeAt: $0] } == [] as [Int])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.vertices.indices) == [0, 1, 2])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 4)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 2]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == 1)
        #expect(graph.vertexCount == 3)
        #expect(graph.vertices.count == 3)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 2]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 1, to: 2)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [2])
        #expect(Array(graph.outEdges(of: 1)) == [0])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 1 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 1)
        #expect(graph.vertices.firstIndex(of: 2) == 2)
        #expect(graph.vertices[2] == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [0])
        #expect(graph.outDegree(of: 2) == 0 && graph.inDegree(of: 2) == 1 && graph.degree(of: 2) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [0])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 2)))
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0])
    }

    @Test("SG-133 attached VertexMap: by position and by vertex; removal and churn remove the values")
    func sg133() throws {
        // V [0, 1]; E [] / let names = addVertexMap(of: String.self) / [names, of: 0] = "zero" / [names, ofVertexAt: 1] = "one" / [names, of: 1] / [names, ofVertexAt: 0] / [names, checked: 9] / for i in 1..<2001 { insert(edge: i→i+1); remove(i) } / [names, of: 2001] = "last" / values of names / remove(0) / values of names / removeAll() / insert(edge: 5→6) / [names, ofVertexAt: 0] / values of names
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
        let names = graph.addVertexMap(of: String.self)
        graph[names, of: 0] = "zero"
        graph[names, ofVertexAt: 1] = "one"
        #expect(graph[names, of: 1] == "one")
        #expect(graph[names, ofVertexAt: 0] == "zero")
        #expect(throws: VertexNotFound.self) { try graph[names, checked: 9] }
        for i in 1 ..< 2001 { graph.insert(edge: DirectedEdge(from: i, to: i + 1)); graph.remove(i) }
        graph[names, of: 2001] = "last"
        #expect((0 ..< graph.vertices.endIndex).filter { (try? graph[names, checkedVertexAt: $0]) != nil } == [0, 2001])
        #expect((0 ..< graph.vertices.endIndex).compactMap { try? graph[names, checkedVertexAt: $0] } == ["zero", "last"])
        #expect(graph.remove(0) == 0)
        #expect((0 ..< graph.vertices.endIndex).filter { (try? graph[names, checkedVertexAt: $0]) != nil } == [2001])
        #expect((0 ..< graph.vertices.endIndex).compactMap { try? graph[names, checkedVertexAt: $0] } == ["last"])
        graph.removeAll()
        #expect(graph.insert(edge: DirectedEdge(from: 5, to: 6)) == 0)
        #expect(graph[names, ofVertexAt: 0] == nil)
        #expect((0 ..< graph.vertices.endIndex).filter { (try? graph[names, checkedVertexAt: $0]) != nil } == [] as [Int])
        #expect((0 ..< graph.vertices.endIndex).compactMap { try? graph[names, checkedVertexAt: $0] } == [] as [String])
        // Final state.
        #expect(Array(graph.vertices) == [5, 6])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[5, 6]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == 1)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[5, 6]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 5, to: 6)])
        #expect(graph.vertices.firstIndex(of: 5) == 0)
        #expect(graph.vertices[0] == 5)
        #expect(Array(graph.successors(of: 5)) == [6])
        #expect(Array(graph.outEdges(of: 5)) == [0])
        #expect(Array(graph.predecessors(of: 5)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 5)) == [] as [Int])
        #expect(graph.outDegree(of: 5) == 1 && graph.inDegree(of: 5) == 0 && graph.degree(of: 5) == 1)
        #expect(graph.vertices.firstIndex(of: 6) == 1)
        #expect(graph.vertices[1] == 6)
        #expect(Array(graph.successors(of: 6)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 6)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 6)) == [5])
        #expect(Array(graph.inEdges(of: 6)) == [0])
        #expect(graph.outDegree(of: 6) == 0 && graph.inDegree(of: 6) == 1 && graph.degree(of: 6) == 1)
        #expect(Array(graph.edges(from: 5, to: 6)) == [0])
        #expect(graph.edgeCount(from: 5, to: 6) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 5, to: 6)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [5, 6])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0])
    }

    @Test("SG-134 several maps, copy-on-write, changeTarget keeps values, removeEdgeMap")
    func sg134() throws {
        // V [0, 1, 2]; E [0→1, 1→2] / let a = addEdgeMap(of: Int.self) / let b = addEdgeMap(of: String.self) / [a, ofEdgeAt: 0] = 1 / [b, ofEdgeAt: 0] = "x" / [a, ofEdgeAt: 1] = 2 / let copy = graph / changeTarget(ofEdgeAt: 0, to: 2) / [a, ofEdgeAt: 0] / remove(edgeAt: 1) / [b, ofEdgeAt: 0] = "y" / values of a / values of b / values of a in copy / values of b in copy / removeEdgeMap(a) / values of b
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let a = graph.addEdgeMap(of: Int.self)
        let b = graph.addEdgeMap(of: String.self)
        graph[a, ofEdgeAt: 0] = 1
        graph[b, ofEdgeAt: 0] = "x"
        graph[a, ofEdgeAt: 1] = 2
        let copy = graph
        graph.changeTarget(ofEdgeAt: 0, to: 2)
        #expect(graph[a, ofEdgeAt: 0] == 1)
        #expect(graph.remove(edgeAt: 1) == DirectedEdge(from: 1, to: 2))
        graph[b, ofEdgeAt: 0] = "y"
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[a, checkedEdgeAt: $0]) != nil } == [0])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[a, checkedEdgeAt: $0] } == [1])
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[b, checkedEdgeAt: $0]) != nil } == [0])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[b, checkedEdgeAt: $0] } == ["y"])
        #expect((0 ..< copy.edges.endIndex).filter { (try? copy[a, checkedEdgeAt: $0]) != nil } == [0, 1])
        #expect((0 ..< copy.edges.endIndex).compactMap { try? copy[a, checkedEdgeAt: $0] } == [1, 2])
        #expect((0 ..< copy.edges.endIndex).filter { (try? copy[b, checkedEdgeAt: $0]) != nil } == [0])
        #expect((0 ..< copy.edges.endIndex).compactMap { try? copy[b, checkedEdgeAt: $0] } == ["x"])
        graph.removeEdgeMap(a)
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[b, checkedEdgeAt: $0]) != nil } == [0])
        #expect((0 ..< graph.edges.endIndex).compactMap { try? graph[b, checkedEdgeAt: $0] } == ["y"])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.vertices.indices) == [0, 1, 2])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 3)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 2)
        #expect(graph.vertexIndexBound == 3)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 3)
        #expect(graph.vertices.count == 3)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 2]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 2)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [2])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.vertices.firstIndex(of: 2) == 2)
        #expect(graph.vertices[2] == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 2)) == [0])
        #expect(Array(graph.inEdges(of: 2)) == [0])
        #expect(graph.outDegree(of: 2) == 0 && graph.inDegree(of: 2) == 1 && graph.degree(of: 2) == 1)
        #expect(Array(graph.edges(from: 0, to: 2)) == [0])
        #expect(graph.edgeCount(from: 0, to: 2) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 2)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2])
        #expect((0 ..< 3).map { graph.vertex(atIndex: $0) } == [0, 1, 2])
    }

    @Test("SG-139 a map with a default: every element has it until set, new ones too; checked reads throw for removed and out-of-range elements")
    func sg139() throws {
        // V [0, 1, 2]; E [0→1, 1→2] / let w = addEdgeMap(default: 1.5) / [w, ofEdgeAt: 1] = 4.0 / insert(edge: 2→0) / [w, ofEdgeAt: 2] / values of w / values(of: w) at the live positions / remove(edgeAt: 0) / [w, checkedEdgeAt: 1] / [w, checkedEdgeAt: 0] / [w, checkedEdgeAt: 3] / [w, checkedEdgeAt: -1] / values(of: w) at the live positions / values of w / let t = addVertexMap(default: 0) / [t, of: 2] = 7 / [t, checked: 2] / [t, checked: 9] / [t, checkedVertexAt: 5] / remove(2) / [t, checkedVertexAt: 2] / insert(3) / [t, of: 3] / values of t / values(of: t) at the live positions
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = graph.addEdgeMap(default: 1.5)
        graph[w, ofEdgeAt: 1] = 4.0
        #expect(graph.insert(edge: DirectedEdge(from: 2, to: 0)) == 2)
        #expect(graph[w, ofEdgeAt: 2] == 1.5)
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [0, 1, 2])
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] } == [1.5, 4.0, 1.5])
        do {
            let values = graph.values(of: w)
            #expect(graph.edges.indices.map { values[$0] } == [1.5, 4.0, 1.5])
        }
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(try graph[w, checkedEdgeAt: 1] == 4.0)
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 0] }
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 3] }
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: -1] }
        do {
            let values = graph.values(of: w)
            #expect(graph.edges.indices.map { values[$0] } == [4.0, 1.5])
        }
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [1, 2])
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] } == [4.0, 1.5])
        let t = graph.addVertexMap(default: 0)
        graph[t, of: 2] = 7
        #expect(try graph[t, checked: 2] == 7)
        #expect(throws: VertexNotFound.self) { try graph[t, checked: 9] }
        #expect(throws: VertexNotFound.self) { try graph[t, checkedVertexAt: 5] }
        #expect(graph.remove(2) == 2)
        #expect(throws: VertexNotFound.self) { try graph[t, checkedVertexAt: 2] }
        do {
            let result = graph.insert(3)
            #expect(result.inserted)
            #expect(result.memberAfterInsert == 3)
        }
        #expect(graph[t, of: 3] == 0)
        #expect((0 ..< graph.vertices.endIndex).filter { (try? graph[t, checkedVertexAt: $0]) != nil } == [0, 1, 3])
        #expect(graph.vertices.indices.map { graph[t, ofVertexAt: $0] } == [0, 0, 0])
        do {
            let values = graph.values(of: t)
            #expect(graph.vertices.indices.map { values[$0] } == [0, 0, 0])
        }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 3])
        #expect(Array(graph.vertices.indices) == [0, 1, 3])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 4)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 3)
        #expect(graph.edges.endIndex == 3)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 3)
        #expect(graph.vertices.count == 3)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.vertices.firstIndex(of: 3) == 3)
        #expect(graph.vertices[3] == 3)
        #expect(Array(graph.successors(of: 3)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 3)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 3)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 3)) == [] as [Int])
        #expect(graph.outDegree(of: 3) == 0 && graph.inDegree(of: 3) == 0 && graph.degree(of: 3) == 0)
    }

    @Test("SG-140 edge map pages are freed with the graph's: churn keeps a page per live value")
    func sg140() throws {
        // V [0, 1]; E [0→1, 1→0] / let w = addEdgeMap(default: -1) / [w, ofEdgeAt: 0] = 100 / for p in 2..<2502 { [w, ofEdgeAt: insert(edge: 0→1)] = p; remove(edgeAt: p - 1) } / pages of w / [w, ofEdgeAt: 2501] / [w, checkedEdgeAt: 1500] / values of w / remove(edgeAt: 2501) / pages of w / insert(edge: 1→1) / pages of w / values of w
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let w = graph.addEdgeMap(default: -1)
        graph[w, ofEdgeAt: 0] = 100
        for p in 2 ..< 2502 { graph[w, ofEdgeAt: graph.insert(edge: DirectedEdge(from: 0, to: 1))] = p; graph.remove(edgeAt: p - 1) }
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 1]])
        #expect(Array(graph.edges.indices) == [0, 2501])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 2502)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        do {
            // The pages allocated in the map's storage, by page number.
            let storage = graph.values(of: w)._storage
            #expect(storage.pages.indices.filter { !storage.pages[$0].isEmpty }.map { storage.firstPage + $0 } == [0, 2])
        }
        #expect(graph[w, ofEdgeAt: 2501] == 2501)
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 1500] }
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [0, 2501])
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] } == [100, 2501])
        #expect(graph.remove(edgeAt: 2501) == DirectedEdge(from: 0, to: 1))
        do {
            // The pages allocated in the map's storage, by page number.
            let storage = graph.values(of: w)._storage
            #expect(storage.pages.indices.filter { !storage.pages[$0].isEmpty }.map { storage.firstPage + $0 } == [0, 2])
        }
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 1)) == 2502)
        do {
            // The pages allocated in the map's storage, by page number.
            let storage = graph.values(of: w)._storage
            #expect(storage.pages.indices.filter { !storage.pages[$0].isEmpty }.map { storage.firstPage + $0 } == [0, 2])
        }
        #expect((0 ..< graph.edges.endIndex).filter { (try? graph[w, checkedEdgeAt: $0]) != nil } == [0, 2502])
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] } == [100, -1])
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 1]])
        #expect(Array(graph.edges.indices) == [0, 2502])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 2503)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 2)
        #expect(graph.edges.count == 2)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 1]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [1])
        #expect(Array(graph.outEdges(of: 1)) == [2502])
        #expect(Array(graph.predecessors(of: 1)) == [0, 1])
        #expect(Array(graph.inEdges(of: 1)) == [0, 2502])
        #expect(graph.outDegree(of: 1) == 1 && graph.inDegree(of: 1) == 2 && graph.degree(of: 1) == 3)
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(Array(graph.edges(from: 1, to: 1)) == [2502])
        #expect(graph.edgeCount(from: 1, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 1)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-141 vertex map pages are freed with the graph's")
    func sg141() throws {
        // V [0]; E [] / let t = addVertexMap(of: Int.self) / [t, of: 0] = 0 / for i in 1..<2101 { insert(i); [t, of: i] = i; remove(i - 1) } / pages of t / [t, of: 2100] / [t, checkedVertexAt: 7] / values of t / removeAll() / pages of t / insert(9) / [t, of: 9]
        var graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
        let t = graph.addVertexMap(of: Int.self)
        graph[t, of: 0] = 0
        for i in 1 ..< 2101 { graph.insert(i); graph[t, of: i] = i; graph.remove(i - 1) }
        #expect(Array(graph.vertices) == [2100])
        #expect(Array(graph.vertices.indices) == [2100])
        #expect(graph.vertices.startIndex == 2100)
        #expect(graph.vertices.endIndex == 2101)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == 0)
        do {
            // The pages allocated in the map's storage, by page number.
            let storage = graph.values(of: t)._storage
            #expect(storage.pages.indices.filter { !storage.pages[$0].isEmpty }.map { storage.firstPage + $0 } == [2])
        }
        #expect(graph[t, of: 2100] == 2100)
        #expect(throws: VertexNotFound.self) { try graph[t, checkedVertexAt: 7] }
        #expect((0 ..< graph.vertices.endIndex).filter { (try? graph[t, checkedVertexAt: $0]) != nil } == [2100])
        #expect((0 ..< graph.vertices.endIndex).compactMap { try? graph[t, checkedVertexAt: $0] } == [2100])
        graph.removeAll()
        do {
            // The pages allocated in the map's storage, by page number.
            let storage = graph.values(of: t)._storage
            #expect(storage.pages.indices.filter { !storage.pages[$0].isEmpty }.map { storage.firstPage + $0 } == [] as [Int])
        }
        do {
            let result = graph.insert(9)
            #expect(result.inserted)
            #expect(result.memberAfterInsert == 9)
        }
        #expect(graph[t, of: 9] == nil)
        // Final state.
        #expect(Array(graph.vertices) == [9])
        #expect(Array(graph.vertices.indices) == [0])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 1)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == 1)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 9) == 0)
        #expect(graph.vertices[0] == 9)
        #expect(Array(graph.successors(of: 9)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 9)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 9)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 9)) == [] as [Int])
        #expect(graph.outDegree(of: 9) == 0 && graph.inDegree(of: 9) == 0 && graph.degree(of: 9) == 0)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { graph.vertex(atIndex: $0) } == [9])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }
}
