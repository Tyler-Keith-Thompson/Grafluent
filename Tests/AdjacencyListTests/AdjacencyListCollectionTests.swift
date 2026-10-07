// The collection views (`vertices`, `edges`, `successors(of:)`, `predecessors(of:)`) must obey the
// Collection laws, and must be values: a view taken before a mutation is unaffected by it.
// The laws checked follow swift-collections' checkCollection (Apache-2.0); each test spells them
// out for its own view.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList collection views", .tags(.conformance))
struct AdjacencyListCollectionTests {
    @Test("S-03 `vertices` obeys the Collection laws", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func verticesView(_ fixture: DirectedFixture<Int>) {
        let view = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).vertices
        let elements = Array(view)

        #expect(Set(elements) == fixture.vertexSet)
        #expect(elements.count == fixture.vertexCount)
        #expect(Array(view) == elements, "two iterations gave different orders")
        #expect(view.count == elements.count)
        #expect(view.isEmpty == elements.isEmpty)
        #expect(view.underestimatedCount <= view.count)

        var indices: [Int] = []
        var i = view.startIndex
        while i != view.endIndex {
            indices.append(i)
            var j = i
            view.formIndex(after: &j)
            #expect(j == view.index(after: i))
            i = view.index(after: i)
        }
        #expect(indices.count == elements.count)
        #expect(indices.map { view[$0] } == elements)
        #expect(Array(view.indices) == indices)
        #expect(view.distance(from: view.startIndex, to: view.endIndex) == elements.count)
        for (offset, index) in (indices + [view.endIndex]).enumerated() {
            #expect(view.index(view.startIndex, offsetBy: offset) == index)
            #expect(view.index(index, offsetBy: elements.count - offset + 1, limitedBy: view.endIndex) == nil)
        }
        // Bidirectional and random-access laws.
        #expect(Array(view.reversed()) == elements.reversed())
        for (offset, index) in indices.enumerated() {
            #expect(view.index(before: view.index(after: index)) == index)
            #expect(view.index(view.endIndex, offsetBy: offset - elements.count) == index)
        }
        if elements.count >= 2 {
            #expect(Array(view[indices[1] ..< view.endIndex]) == Array(elements.dropFirst()))
        }
    }

    @Test("S-03 `edges` obeys the Collection laws", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func edgesView(_ fixture: DirectedFixture<Int>) {
        let view = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).edges
        let elements = Array(view)

        #expect(Set(elements) == fixture.edgeSet)
        #expect(elements.count == fixture.edgeCount)
        #expect(Array(view) == elements, "two iterations gave different orders")
        #expect(view.count == elements.count)
        #expect(view.isEmpty == elements.isEmpty)
        #expect(view.underestimatedCount <= view.count)

        var indices: [AdjacencyList<Int>.Edges.Index] = []
        var i = view.startIndex
        while i != view.endIndex {
            indices.append(i)
            var j = i
            view.formIndex(after: &j)
            #expect(j == view.index(after: i))
            i = view.index(after: i)
            if indices.count > elements.count {
                Issue.record("walking indices did not reach endIndex")
                return
            }
        }
        #expect(indices.count == elements.count)
        #expect(indices.map { view[$0] } == elements)
        #expect(Array(view.indices) == indices)
        #expect(zip(indices, indices.dropFirst()).allSatisfy { $0 < $1 }, "indices are not increasing")
        #expect(view.distance(from: view.startIndex, to: view.endIndex) == elements.count)
        for (offset, index) in (indices + [view.endIndex]).enumerated() {
            #expect(view.index(view.startIndex, offsetBy: offset) == index)
            #expect(view.distance(from: view.startIndex, to: index) == offset)
            #expect(view.index(index, offsetBy: elements.count - offset + 1, limitedBy: view.endIndex) == nil)
        }
        if elements.count >= 3 {
            #expect(Array(view[indices[1] ..< indices[elements.count - 1]]) == Array(elements[1 ..< elements.count - 1]))
        }
    }

    @Test("S-03 neighborhoods obey the Collection laws", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func neighborhoodViews(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for v in fixture.vertexSet {
            for (view, expected) in [
                (graph.successors(of: v), Set(fixture.edgeSet.filter { $0.source == v }.map(\.target))),
                (graph.predecessors(of: v), Set(fixture.edgeSet.filter { $0.target == v }.map(\.source))),
            ] {
                let elements = Array(view)
                #expect(Set(elements) == expected, "vertex \(v)")
                #expect(elements.count == expected.count, "vertex \(v): a neighbor is repeated")
                #expect(Array(view) == elements)
                #expect(view.count == elements.count)
                #expect(view.isEmpty == elements.isEmpty)
                var i = view.startIndex
                var walked: [Int] = []
                while i != view.endIndex {
                    walked.append(view[i])
                    i = view.index(after: i)
                }
                #expect(walked == elements)
                #expect(view.distance(from: view.startIndex, to: view.endIndex) == elements.count)
                #expect(Array(view.reversed()) == elements.reversed())
            }
        }
    }

    @Test("views of a graph with colliding vertex hashes are complete")
    func collidingViews() {
        let cube = DirectedFixture<Int>.cube
        let graph = AdjacencyList(edges: cube.edges.map { DirectedEdge(from: Collider($0.source), to: Collider($0.target)) })
        #expect(Set(graph.vertices) == Set(cube.vertexSet.map { Collider($0) }))
        #expect(graph.vertices.count == 8)
        #expect(graph.edges.count == 24)
        for v in cube.vertexSet {
            let expected = Set(cube.edgeSet.filter { $0.source == v }.map { Collider($0.target) })
            #expect(Set(graph.successors(of: Collider(v))) == expected)
            #expect(graph.successors(of: Collider(v)).count == 3)
        }
    }

    @Test("views taken before a mutation are unaffected by it", .tags(.copyOnWrite), arguments: DirectedFixture<Int>.nonempty)
    func viewsAreValues(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let v = fixture.vertexSet.min()!
        let vertices = graph.vertices
        let edges = graph.edges
        let out = graph.successors(of: v)
        let into = graph.predecessors(of: v)
        graph.removeAll()
        #expect(Set(vertices) == fixture.vertexSet)
        #expect(Set(edges) == fixture.edgeSet)
        #expect(Set(out) == Set(fixture.edgeSet.filter { $0.source == v }.map(\.target)))
        #expect(Set(into) == Set(fixture.edgeSet.filter { $0.target == v }.map(\.source)))
    }

    @Test("a graph and its views are Sendable")
    func sendable() {
        func requireSendable<T: Sendable>(_: T) {}
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        requireSendable(graph)
        requireSendable(graph.vertices)
        requireSendable(graph.edges)
        requireSendable(graph.edges.startIndex)
        requireSendable(graph.successors(of: 0))
        requireSendable(graph.predecessors(of: 0))
    }

    @Test("a graph can be shared across tasks", arguments: DirectedFixture<Int>.nonempty)
    func sharedAcrossTasks(_ fixture: DirectedFixture<Int>) async {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let sizes = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for _ in 0 ..< 8 {
                group.addTask {
                    var local = graph
                    local.removeAllEdges()
                    return local.edgeCount + graph.edgeCount
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
        #expect(sizes == Array(repeating: fixture.edgeCount, count: 8))
        #expect(Set(graph.edges) == fixture.edgeSet)
    }
}
