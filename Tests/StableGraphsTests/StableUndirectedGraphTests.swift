// StableUndirectedGraph by hand: construction, positions that survive removals, a vertex's edges
// in position order (a self-loop twice in a row), either orientation in the
// edge queries, the newest copy in `remove(edge:)`, holes and the dense bounds, resets, and the
// `checked` spellings. Expected values are worked out in each test's comments. See README.md.

import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("StableUndirectedGraph")
struct StableUndirectedGraphTests {
    @Test("Construction: vertices first, endpoints in first-appearance order, every copy at 0, 1, … in its orientation")
    func construction() {
        let empty = StableUndirectedGraph<Int>()
        #expect(empty.vertexCount == 0 && empty.edgeCount == 0)
        #expect(empty.vertices.endIndex == 0 && empty.edges.endIndex == 0)
        #expect(empty.vertexIndexBound == 0 && empty.edgeIndexBound == 0)

        let graph = StableUndirectedGraph(vertices: [5, 5], edges: [UndirectedEdge(3, 5), UndirectedEdge(5, 4), UndirectedEdge(4, 5), UndirectedEdge(3, 3)])
        #expect(Array(graph.vertices) == [5, 3, 4])
        #expect(Array(graph.vertices.indices) == [0, 1, 2])
        #expect(Array(graph.edges) == [UndirectedEdge(3, 5), UndirectedEdge(5, 4), UndirectedEdge(4, 5), UndirectedEdge(3, 3)])
        // Each edge keeps its orientation.
        #expect(graph.edges.map { [$0.u, $0.v] } == [[3, 5], [5, 4], [4, 5], [3, 3]])
        // Iterating keeps the orientation too.
        var iterated: [[Int]] = []
        for e in graph.edges { iterated.append([e.u, e.v]) }
        #expect(iterated == [[3, 5], [5, 4], [4, 5], [3, 3]])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.vertexIndexBound == 3 && graph.edgeIndexBound == 4)

        #expect(Array(StableUndirectedGraph(vertices: ["a", "b", "a"]).vertices) == ["a", "b"])
        let fromEdges = StableUndirectedGraph(edges: [UndirectedEdge(2, 0), UndirectedEdge(1, 2)])
        #expect(Array(fromEdges.vertices) == [2, 0, 1])
        let built = StableUndirectedGraph<String> {
            "z"
            UndirectedEdge("a", "b")
            UndirectedEdge("b", "a")
        }
        #expect(Array(built.vertices) == ["z", "a", "b"] && built.edgeCount == 2)
    }

    @Test("init(_:) copies any graph in order and orientation; a StableUndirectedGraph is returned unchanged, holes and ends kept")
    func conversion() {
        let pseudograph = Pseudograph(vertices: [9], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1)])
        let copy = StableUndirectedGraph(pseudograph)
        #expect(Array(copy.vertices) == [9, 0, 1])
        #expect(Array(copy.edges) == Array(pseudograph.edges))
        #expect(copy.edges.map { $0.u } == [0, 1, 1])
        var holed = copy
        holed.remove(9)
        holed.remove(edgeAt: 1)
        let same = StableUndirectedGraph(holed)
        #expect(Array(same.vertices.indices) == [1, 2] && same.vertices.endIndex == 3)
        #expect(Array(same.edges.indices) == [0, 2] && same.edges.endIndex == 3)
        // And back: the compacted copy numbers the live edges 0, 1, ….
        let compacted = Pseudograph(holed)
        #expect(Array(compacted.vertices) == [0, 1])
        #expect(Array(compacted.edges) == [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
    }

    @Test("A vertex's edges in position order, whichever end it is, a self-loop twice in a row")
    func incidence() throws {
        // Positions: 0 a–b, 1 c–a, 2 a–a, 3 b–a, 4 a–c.
        let graph = StableUndirectedGraph(edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "a"), UndirectedEdge("a", "a"), UndirectedEdge("b", "a"), UndirectedEdge("a", "c")])
        // a is an end of every edge; the loop at 2 counts twice.
        #expect(Array(graph.incidentEdges(of: "a")) == [0, 1, 2, 2, 3, 4])
        #expect(Array(graph.neighbors(of: "a")) == ["b", "c", "a", "a", "b", "c"])
        #expect(graph.degree(of: "a") == 6)
        #expect(graph.neighbors(of: "a").underestimatedCount == 6 && graph.incidentEdges(of: "a").underestimatedCount == 6)
        #expect(Array(graph.incidentEdges(of: "b")) == [0, 3])
        #expect(Array(graph.neighbors(of: "c")) == ["a", "a"])
        // The degrees sum to twice the edges.
        #expect(graph.vertices.map { graph.degree(of: $0) }.reduce(0, +) == 2 * graph.edgeCount)
        #expect(graph.oppositeVertex(to: "a", acrossEdgeAt: 1) == "c")
        #expect(graph.oppositeVertex(to: "c", acrossEdgeAt: 1) == "a")
        #expect(graph.oppositeVertex(to: "a", acrossEdgeAt: 2) == "a")
        // The index-space rows say the same while there are no holes.
        #expect(Array(graph.neighborIndices(ofIndex: 0)) == [1, 2, 0, 0, 1, 2])
        var visited: [Int] = []
        graph._forEachNeighborIndex(ofIndex: 0) { visited.append($0) }
        #expect(visited == [1, 2, 0, 0, 1, 2])
        #expect(Array(graph.incidentEdges(ofIndex: 0)) == [0, 1, 2, 2, 3, 4])
        #expect(Array(graph.incidentEdgeIndices(ofIndex: 0)) == [0, 1, 2, 2, 3, 4])
        #expect(graph.degree(ofIndex: 0) == 6)
        let ends = graph.endpointIndices(ofEdgeAt: 1)
        #expect(ends.u == 2 && ends.v == 0)
        #expect(try graph.degree(checked: "c") == 2)
        #expect(Array(try graph.neighbors(checked: "b")) == ["a", "a"])
        #expect(Array(try graph.incidentEdges(checked: "b")) == [0, 3])
        #expect(try graph.vertexIndex(checked: "c") == 2)
        #expect(throws: VertexNotFound.self) { try graph.degree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try graph.neighbors(checked: "z") }
        #expect(throws: VertexNotFound.self) { try graph.incidentEdges(checked: "z") }
        #expect(throws: VertexNotFound.self) { try graph.vertexIndex(checked: "z") }
    }

    @Test("Edge queries take either orientation: contains(edge:), edges(between:and:) oldest first, edgeCount(between:and:)")
    func edgeQueries() {
        // Positions: 0 0–1, 1 1–0, 2 1–2, 3 0–1, 4 2–2, 5 2–2.
        let graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 2), UndirectedEdge(2, 2)])
        #expect(graph.contains(edge: UndirectedEdge(1, 0)) && graph.contains(edge: UndirectedEdge(0, 1)))
        #expect(graph.contains(edge: UndirectedEdge(2, 1)) && graph.contains(edge: UndirectedEdge(2, 2)))
        #expect(!graph.contains(edge: UndirectedEdge(0, 2)) && !graph.contains(edge: UndirectedEdge(0, 0)))
        #expect(!graph.contains(edge: UndirectedEdge(0, 9)) && !graph.contains(edge: UndirectedEdge(8, 9)))
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1, 3])
        #expect(Array(graph.edges(between: 1, and: 0)) == [0, 1, 3])
        #expect(Array(graph.edges(between: 2, and: 1)) == [2])
        // A self-loop once each.
        #expect(Array(graph.edges(between: 2, and: 2)) == [4, 5])
        #expect(Array(graph.edges(between: 0, and: 2)).isEmpty && Array(graph.edges(between: 0, and: 7)).isEmpty)
        #expect(graph.edgeCount(between: 1, and: 0) == 3 && graph.edgeCount(between: 2, and: 2) == 2 && graph.edgeCount(between: 5, and: 6) == 0)
    }

    @Test("Removals leave holes and move nothing; remove(edge:) takes the newest copy in either orientation")
    func removals() {
        var graph = StableUndirectedGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        // The newest copy of {0, 1} is 1–0 at position 1, returned in its orientation.
        let removed = graph.remove(edge: UndirectedEdge(0, 1))
        #expect(removed == UndirectedEdge(1, 0) && removed?.u == 1)
        #expect(Array(graph.edges.indices) == [0, 2, 3] && graph.edges.endIndex == 4)
        #expect(graph.edgeIndexBound == nil && graph.vertexIndexBound == 3)
        #expect(!graph.edges.indices.contains(1) && graph.edges.indices.contains(2))
        // A fresh edge gets a fresh position.
        #expect(graph.insert(edge: UndirectedEdge(1, 0)) == 4)
        #expect(graph.remove(edge: UndirectedEdge(1, 0)) == UndirectedEdge(1, 0))
        #expect(graph.remove(edge: UndirectedEdge(0, 2)) == nil && graph.remove(edge: UndirectedEdge(0, 9)) == nil)
        #expect(graph.vertexCount == 3)
        #expect(graph.remove(edge: UndirectedEdge(2, 2)) == UndirectedEdge(2, 2))
        #expect(graph.remove(edgeAt: 2) == UndirectedEdge(1, 2))
        #expect(Array(graph.edges) == [UndirectedEdge(0, 1)] && Array(graph.edges.indices) == [0])
        // A vertex removal makes its edges holes; the other vertex keeps its position.
        graph.insert(edge: UndirectedEdge(2, 0))
        #expect(graph.remove(0) == 0 && graph.remove(0) == nil)
        #expect(Array(graph.vertices) == [1, 2] && Array(graph.vertices.indices) == [1, 2])
        #expect(graph.vertexIndexBound == nil && graph.edgeCount == 0)
        #expect(graph.degree(of: 1) == 0 && graph.degree(of: 2) == 0)
        // A re-inserted vertex is new and comes last.
        let inserted = graph.insert(0)
        #expect(inserted.inserted && inserted.memberAfterInsert == 0)
        #expect(Array(graph.vertices.indices) == [1, 2, 3])
        #expect(!graph.insert(2).inserted)
    }

    @Test("removeAllEdges(between:and:) in both orientations, removeAllEdges(where:), and the resets")
    func bulkRemovals() throws {
        var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 1)])
        #expect(graph.removeAllEdges(between: 1, and: 0) == 2)
        #expect(graph.removeAllEdges(between: 1, and: 1) == 2)
        #expect(graph.removeAllEdges(between: 0, and: 2) == 0 && graph.removeAllEdges(between: 7, and: 8) == 0)
        #expect(Array(graph.edges.indices) == [3])
        graph.insert(edge: UndirectedEdge(2, 0))
        graph.insert(edge: UndirectedEdge(0, 0))
        // The predicate sees each edge once.
        var seen: [Int] = []
        #expect(graph.removeAllEdges { seen.append($0); return $0 != 3 } == 2)
        #expect(seen.sorted() == [3, 5, 6])
        #expect(Array(graph.edges.indices) == [3])
        struct Stop: Error {}
        #expect(throws: Stop.self) { try graph.removeAllEdges { (_: Int) throws(Stop) -> Bool in throw Stop() } }
        #expect(graph.edgeCount == 1)
        graph.removeAllEdges()
        #expect(graph.edgeCount == 0 && graph.edges.endIndex == 0 && graph.vertexCount == 3)
        #expect(graph.insert(edge: UndirectedEdge(2, 1)) == 0)
        graph.remove(0)
        graph.removeAll(keepingCapacity: true)
        #expect(graph.vertexCount == 0 && graph.vertices.endIndex == 0 && graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == 0 && graph.edgeIndexBound == 0)
        graph.reserveCapacity(vertexCount: 100, edgeCount: 100)
        #expect(graph.insert(edge: UndirectedEdge(4, 5)) == 0)
    }

    @Test("insert(checked:) inserts only between existing vertices, and otherwise throws and changes nothing")
    func checkedInsertion() throws {
        var graph = StableUndirectedGraph(vertices: [0, 1])
        #expect(try graph.insert(checked: UndirectedEdge(1, 0)) == 0)
        let before = graph.generation
        #expect(throws: VertexNotFound.self) { try graph.insert(checked: UndirectedEdge(0, 2)) }
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.generation == before)
    }
}
