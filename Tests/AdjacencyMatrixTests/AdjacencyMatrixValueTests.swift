// Value semantics, the Collection laws of the views, Sendable, and a model-based randomized test.
// Case IDs (AM-Qnn, AM-Znn) refer to the harvested test catalog.

import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix value semantics", .tags(.copyOnWrite))
struct AdjacencyMatrixValueSemanticsTests {
    @Test("AM-Q06 every mutation leaves an existing copy unchanged", arguments: DirectedFixture<Int>.zeroBased.filter { $0.vertexCount > 0 })
    func copiesAreIndependent(_ fixture: DirectedFixture<Int>) {
        let original = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)

        var toggled = original
        toggled[0, 0].toggle()
        var inserted = original
        inserted.insert(edge: DirectedEdge(from: fixture.vertexCount - 1, to: 0))
        var removed = original
        if let edge = fixture.edges.first { removed.remove(edge: edge) }
        var grown = original
        for _ in 0 ..< 70 { grown.appendVertex() }
        var cleared = original
        cleared.removeAllEdges()
        var emptied = original
        emptied.removeAll()
        var reserved = original
        reserved.reserveCapacity(vertexCount: 300)

        #expect(original.vertexCount == fixture.vertexCount)
        #expect(original.edgeCount == fixture.edgeCount)
        #expect(Set(original.edges) == fixture.edgeSet)
        for i in 0 ..< fixture.vertexCount {
            for j in 0 ..< fixture.vertexCount {
                #expect(original[i, j] == fixture.edgeSet.contains(DirectedEdge(from: i, to: j)))
            }
        }
        #expect(toggled[0, 0] != original[0, 0])
        #expect(grown.vertexCount == fixture.vertexCount + 70)
        #expect(cleared.edgeCount == 0)
        #expect(emptied.vertexCount == 0)
        #expect(reserved == original)
    }

    @Test("views taken before a mutation are unaffected by it", arguments: DirectedFixture<Int>.zeroBased.filter { $0.edgeCount > 0 })
    func viewsAreValues(_ fixture: DirectedFixture<Int>) {
        var matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let v = fixture.edges[0].source
        let edges = matrix.edges
        let successors = matrix.successors(of: v)
        let predecessors = matrix.predecessors(of: v)
        let expectedSuccessors = fixture.edgeSet.filter { $0.source == v }.map(\.target).sorted()
        let expectedPredecessors = fixture.edgeSet.filter { $0.target == v }.map(\.source).sorted()
        matrix.removeAllEdges()
        matrix.appendVertex()
        #expect(Set(edges) == fixture.edgeSet)
        #expect(Array(successors) == expectedSuccessors)
        #expect(Array(predecessors) == expectedPredecessors)
    }

    @Test("a matrix and its views are Sendable")
    func sendable() {
        // Compile-time checks: this test fails to build if any of these is not Sendable.
        func requireSendable<T: Sendable>(_: T) {}
        let matrix = AdjacencyMatrix(vertexCount: 24, edges: DirectedFixture<Int>.boost24.edges)
        requireSendable(matrix)
        requireSendable(matrix.edges)
        requireSendable(matrix.edges.startIndex)
        requireSendable(matrix.edges.makeIterator())
        requireSendable(matrix.successors(of: 0))
        requireSendable(matrix.predecessors(of: 0))
        func requireBitwiseCopyable<T: BitwiseCopyable>(_: T.Type) {}
        requireBitwiseCopyable(DirectedEdge<Int>.self)
    }
}

@Suite("AdjacencyMatrix collection views", .tags(.conformance))
struct AdjacencyMatrixCollectionTests {
    @Test("`edges`, `successors` and `predecessors` obey the BidirectionalCollection laws", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func collectionLaws(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)

        // `edges`.
        let edges = Array(matrix.edges)
        #expect(edges.count == matrix.edges.count)
        #expect(Array(matrix.edges) == edges)
        #expect(Array(matrix.edges.reversed()) == edges.reversed())
        var walked: [DirectedEdge<Int>] = []
        var i = matrix.edges.startIndex
        while i != matrix.edges.endIndex {
            walked.append(matrix.edges[i])
            let next = matrix.edges.index(after: i)
            #expect(matrix.edges.index(before: next) == i)
            #expect(i < next)
            i = next
        }
        #expect(walked == edges)
        #expect(matrix.edges.distance(from: matrix.edges.startIndex, to: matrix.edges.endIndex) == edges.count)
        #expect(matrix.edges.isEmpty == edges.isEmpty)

        // `successors` and `predecessors`.
        for v in 0 ..< fixture.vertexCount {
            for (view, expected) in [
                (matrix.successors(of: v), fixture.edgeSet.filter { $0.source == v }.map(\.target).sorted()),
                (matrix.predecessors(of: v), fixture.edgeSet.filter { $0.target == v }.map(\.source).sorted()),
            ] {
                #expect(Array(view) == expected, "vertex \(v)")
                #expect(view.count == expected.count)
                #expect(view.isEmpty == expected.isEmpty)
                #expect(Array(view.reversed()) == expected.reversed())
                var index = view.startIndex
                var items: [Int] = []
                while index != view.endIndex {
                    items.append(view[index])
                    let next = view.index(after: index)
                    #expect(view.index(before: next) == index)
                    index = next
                }
                #expect(items == expected)
                #expect(view.distance(from: view.startIndex, to: view.endIndex) == expected.count)
                #expect(view.first == expected.first)
                #expect(view.last == expected.last)
            }
        }
    }

    @Test("`vertices` is exactly 0..<vertexCount")
    func vertices() {
        #expect(AdjacencyMatrix().vertices == 0 ..< 0)
        #expect(AdjacencyMatrix(vertexCount: 65).vertices == 0 ..< 65)
    }
}

@Suite("AdjacencyMatrix against a reference model", .tags(.randomized))
struct AdjacencyMatrixModelTests {
    // Start sizes straddle word boundaries, so rows longer than one word, and restrides when an
    // append crosses 64 or 128 columns, are randomized too.
    @Test(
        "AM-Z05 random operations agree with a vertex count and an edge set",
        .timeLimit(.minutes(1)),
        arguments: [0, 3, 60, 63, 64, 120], 0 ..< 10 as Range<UInt>
    )
    func randomOperations(start: Int, seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        var matrix = AdjacencyMatrix(vertexCount: start)
        var modelVertexCount = start
        var modelEdges = Set<DirectedEdge<Int>>()

        for step in 0 ..< 400 {
            let copy: AdjacencyMatrix? = Bool.random(using: &rng) ? matrix : nil
            let edgesBefore = modelEdges
            let vertexCountBefore = modelVertexCount

            let roll = Int.random(in: 0 ..< 100, using: &rng)
            if modelVertexCount == 0 || roll < 8 {
                #expect(matrix.appendVertex() == modelVertexCount, "step \(step)")
                modelVertexCount += 1
            } else {
                let u = Int.random(in: 0 ..< modelVertexCount, using: &rng)
                let v = Int.random(in: 0 ..< modelVertexCount, using: &rng)
                let edge = DirectedEdge(from: u, to: v)
                switch roll {
                case 8 ..< 50:
                    #expect(matrix.insert(edge: edge).inserted == !modelEdges.contains(edge), "step \(step)")
                    modelEdges.insert(edge)
                case 50 ..< 80:
                    #expect((matrix.remove(edge: edge) != nil) == modelEdges.contains(edge), "step \(step)")
                    modelEdges.remove(edge)
                case 80 ..< 92:
                    let value = Bool.random(using: &rng)
                    matrix[u, v] = value
                    if value { modelEdges.insert(edge) } else { modelEdges.remove(edge) }
                case 92 ..< 94:
                    let removed = modelEdges.filter { $0.source == u }
                    #expect(matrix.removeEdges(from: u) == removed.count, "step \(step)")
                    modelEdges.subtract(removed)
                case 94 ..< 96:
                    let removed = modelEdges.filter { $0.target == u }
                    #expect(matrix.removeEdges(to: u) == removed.count, "step \(step)")
                    modelEdges.subtract(removed)
                case 96 ..< 98:
                    let removed = modelEdges.filter { $0.source == u || $0.target == u }
                    #expect(matrix.removeEdges(incidentTo: u) == removed.count, "step \(step)")
                    modelEdges.subtract(removed)
                case 98:
                    matrix.removeAllEdges(keepingCapacity: Bool.random(using: &rng))
                    modelEdges = []
                default:
                    matrix = matrix.transposed()
                    modelEdges = Set(modelEdges.map { DirectedEdge(from: $0.target, to: $0.source) })
                }
            }

            #expect(matrix.vertexCount == modelVertexCount, "step \(step)")
            #expect(matrix.edgeCount == modelEdges.count, "step \(step)")
            #expect(matrix.edges.count == modelEdges.count, "step \(step)")
            #expect(Set(matrix.edges) == modelEdges, "step \(step)")
            for w in 0 ..< modelVertexCount {
                let expectedSuccessors = modelEdges.filter { $0.source == w }.map(\.target).sorted()
                let expectedPredecessors = modelEdges.filter { $0.target == w }.map(\.source).sorted()
                #expect(Array(matrix.successors(of: w)) == expectedSuccessors, "step \(step)")
                #expect(Array(matrix.predecessors(of: w)) == expectedPredecessors, "step \(step)")
                #expect(matrix.outDegree(of: w) == expectedSuccessors.count, "step \(step)")
                #expect(matrix.inDegree(of: w) == expectedPredecessors.count, "step \(step)")
            }
            #expect(Array(matrix.edges.reversed()) == Array(matrix.edges).reversed(), "step \(step)")
            let rebuilt = AdjacencyMatrix(vertexCount: modelVertexCount, edges: modelEdges)
            #expect(matrix == rebuilt, "step \(step)")
            #expect(matrix.hashValue == rebuilt.hashValue, "step \(step)")
            if let copy {
                #expect(copy.vertexCount == vertexCountBefore, "step \(step): copy changed")
                #expect(Set(copy.edges) == edgesBefore, "step \(step): copy changed")
            }
        }
    }
}
