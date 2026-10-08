// Whole-matrix and whole-row operations: transpose, set algebra, complement, clearing a vertex's
// edges, inserting a row from a BitSet. Also decoding limits, large-matrix descriptions, and the
// Collection laws on wide random matrices. Case IDs (AM-Tnn, AM-Vnn, …) refer to the harvested test
// catalog.

import AdjacencyMatrixModule
import BitCollections
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix transpose")
struct AdjacencyMatrixTransposeTests {
    @Test("AM-T01 transposing reverses every edge")
    func reversesEdges() {
        // igraph reverse_edges fixture: 0→1, 1→2, 2→3, 3→1, 1→4.
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: DirectedFixture<Int>.igraphReverseEdges.edges)
        let expected = AdjacencyMatrix(vertexCount: 5, edges: [
            DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 4, to: 1),
        ])
        #expect(matrix.transposed() == expected)
    }

    @Test("AM-T02 transposing swaps successors with predecessors, out-degree with in-degree", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func swapsDirections(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let transposed = matrix.transposed()
        #expect(transposed.vertexCount == matrix.vertexCount)
        #expect(transposed.edgeCount == matrix.edgeCount)
        for v in 0 ..< fixture.vertexCount {
            #expect(Array(transposed.successors(of: v)) == Array(matrix.predecessors(of: v)))
            #expect(Array(transposed.predecessors(of: v)) == Array(matrix.successors(of: v)))
            #expect(transposed.outDegree(of: v) == matrix.inDegree(of: v))
            #expect(transposed.inDegree(of: v) == matrix.outDegree(of: v))
        }
    }

    @Test("AM-T03 transposing twice is the identity; the diagonal and symmetric matrices are fixed", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func involution(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(matrix.transposed().transposed() == matrix)
        for v in 0 ..< fixture.vertexCount {
            #expect(matrix.transposed()[v, v] == matrix[v, v])
        }
        let petersen = AdjacencyMatrix(vertexCount: 10, edges: DirectedFixture<Int>.petersen.edges)
        #expect(petersen.transposed() == petersen)
    }

    @Test(
        "AM-T04 transposing across word boundaries",
        .tags(.randomized),
        arguments: [1, 7, 8, 9, 63, 64, 65, 127, 128, 129]
    )
    func acrossWordBoundaries(_ n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(n))
        var matrix = AdjacencyMatrix(vertexCount: n)
        for i in 0 ..< n {
            for j in 0 ..< n where Int.random(in: 0 ..< 3, using: &rng) == 0 {
                matrix[i, j] = true
            }
        }
        let transposed = matrix.transposed()
        for i in 0 ..< n {
            for j in 0 ..< n {
                #expect(transposed[i, j] == matrix[j, i], "n = \(n), [\(i), \(j)]")
            }
        }
        #expect(transposed.edgeCount == matrix.edgeCount)
        // Padding stays zero: the transposed matrix grows like any other.
        var grown = transposed
        grown.appendVertex()
        #expect(grown.successors(of: n).isEmpty)
        #expect(grown.predecessors(of: n).isEmpty)
        #expect(grown.edgeCount == transposed.edgeCount)
    }
}

@Suite("AdjacencyMatrix set algebra and complement")
struct AdjacencyMatrixSetAlgebraTests {
    @Test("union, intersection, subtraction and symmetric difference follow the edge sets", .tags(.randomized), arguments: [1, 5, 63, 64, 65, 129])
    func setAlgebra(_ n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(n) &* 31)
        var aEdges = Set<DirectedEdge<Int>>()
        var bEdges = Set<DirectedEdge<Int>>()
        for i in 0 ..< n {
            for j in 0 ..< n {
                if Int.random(in: 0 ..< 3, using: &rng) == 0 { aEdges.insert(DirectedEdge(from: i, to: j)) }
                if Int.random(in: 0 ..< 3, using: &rng) == 0 { bEdges.insert(DirectedEdge(from: i, to: j)) }
            }
        }
        let a = AdjacencyMatrix(vertexCount: n, edges: aEdges)
        var b = AdjacencyMatrix(vertexCount: n, edges: bEdges)
        // A different row stride must not change the result.
        b.reserveCapacity(vertexCount: 300)

        let cases: [(AdjacencyMatrix, Set<DirectedEdge<Int>>)] = [
            (a.union(b), aEdges.union(bEdges)),
            (a.intersection(b), aEdges.intersection(bEdges)),
            (a.subtracting(b), aEdges.subtracting(bEdges)),
            (a.symmetricDifference(b), aEdges.symmetricDifference(bEdges)),
        ]
        for (result, expected) in cases {
            #expect(Set(result.edges) == expected)
            #expect(result.edgeCount == expected.count)
            #expect(result == AdjacencyMatrix(vertexCount: n, edges: expected))
            for v in 0 ..< n {
                #expect(result.outDegree(of: v) == expected.filter { $0.source == v }.count)
                #expect(result.inDegree(of: v) == expected.filter { $0.target == v }.count)
            }
        }

        var mutated = a
        mutated.formUnion(b)
        #expect(mutated == a.union(b))
        mutated = a
        mutated.formIntersection(b)
        #expect(mutated == a.intersection(b))
        mutated = a
        mutated.subtract(b)
        #expect(mutated == a.subtracting(b))
        mutated = a
        mutated.formSymmetricDifference(b)
        #expect(mutated == a.symmetricDifference(b))
    }

    @Test("complement excludes self-loops by default", arguments: [0, 1, 4, 63, 64, 65])
    func complement(_ n: Int) {
        let empty = AdjacencyMatrix(vertexCount: n)
        let complement = empty.complement()
        #expect(complement.edgeCount == n * (n - 1) || n == 0)
        for v in 0 ..< n {
            #expect(!complement[v, v])
            #expect(complement.outDegree(of: v) == n - 1)
            #expect(complement.inDegree(of: v) == n - 1)
        }
        let withSelfLoops = empty.complement(includingSelfLoops: true)
        #expect(withSelfLoops == AdjacencyMatrix(vertexCount: n, repeating: true))
        #expect(withSelfLoops.complement(includingSelfLoops: true) == empty)
    }

    @Test("the complement of a fixture holds exactly the missing cells", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func complementOfFixture(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let complement = matrix.complement(includingSelfLoops: true)
        #expect(complement.edgeCount == fixture.vertexCount * fixture.vertexCount - fixture.edgeCount)
        #expect(complement.intersection(matrix).edgeCount == 0)
        #expect(complement.union(matrix) == AdjacencyMatrix(vertexCount: fixture.vertexCount, repeating: true))
        // Growing the complement must not expose bits outside the old square.
        var grown = complement
        grown.appendVertex()
        #expect(grown.successors(of: fixture.vertexCount).isEmpty)
        #expect(grown.predecessors(of: fixture.vertexCount).isEmpty)
    }

    @Test("init(vertexCount:repeating:)", arguments: [0, 1, 7, 64, 65])
    func repeating(_ n: Int) {
        let full = AdjacencyMatrix(vertexCount: n, repeating: true)
        #expect(full.edgeCount == n * n)
        for v in 0 ..< n {
            #expect(full.outDegree(of: v) == n)
            #expect(full.inDegree(of: v) == n)
            #expect(Array(full.successors(of: v)) == Array(0 ..< n))
        }
        #expect(AdjacencyMatrix(vertexCount: n, repeating: false) == AdjacencyMatrix(vertexCount: n))
    }

    @Test("operands with different vertex counts trap", .tags(.precondition))
    func differentSizes() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 3).union(AdjacencyMatrix(vertexCount: 4))
        }
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix(vertexCount: 3)
            matrix.formIntersection(AdjacencyMatrix(vertexCount: 2))
        }
    }
}

@Suite("AdjacencyMatrix row and column operations")
struct AdjacencyMatrixRowOperationTests {
    @Test("AM-V04 removeEdges(incidentTo:) clears a vertex's row and column and keeps the vertex")
    func clearVertex() {
        // Boost.Graph clear_vertex on the adjacency_matrix example: vertex C (2) has C→A, C→C, B→C.
        var matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        #expect(matrix.removeEdges(incidentTo: 2) == 3)
        #expect(matrix.edgeCount == 4)
        #expect(matrix.vertexCount == 6)
        #expect(matrix.successors(of: 2).isEmpty)
        #expect(matrix.predecessors(of: 2).isEmpty)
        #expect(matrix.outDegree(of: 1) == 1)
        #expect(matrix.inDegree(of: 0) == 1)
        #expect(matrix.removeEdges(incidentTo: 2) == 0)
    }

    @Test("removeEdges(from:) and removeEdges(to:) clear exactly a row or a column", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func clearRowAndColumn(_ fixture: DirectedFixture<Int>) {
        for v in 0 ..< fixture.vertexCount {
            var rowCleared = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(rowCleared.removeEdges(from: v) == fixture.outDegree[v])
            #expect(Set(rowCleared.edges) == fixture.edgeSet.filter { $0.source != v })
            #expect(rowCleared.outDegree(of: v) == 0)
            for w in 0 ..< fixture.vertexCount {
                #expect(rowCleared.inDegree(of: w) == fixture.edgeSet.filter { $0.target == w && $0.source != v }.count)
            }

            var columnCleared = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(columnCleared.removeEdges(to: v) == fixture.inDegree[v])
            #expect(Set(columnCleared.edges) == fixture.edgeSet.filter { $0.target != v })
            #expect(columnCleared.inDegree(of: v) == 0)
            for w in 0 ..< fixture.vertexCount {
                #expect(columnCleared.outDegree(of: w) == fixture.edgeSet.filter { $0.source == w && $0.target != v }.count)
            }

            var bothCleared = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let incident = fixture.edgeSet.filter { $0.source == v || $0.target == v }
            #expect(bothCleared.removeEdges(incidentTo: v) == incident.count, "a self-loop counts once")
            #expect(Set(bothCleared.edges) == fixture.edgeSet.subtracting(incident))
        }
    }

    @Test("insertEdges(from:to:) unions a row with a BitSet")
    func insertRow() {
        var matrix = AdjacencyMatrix(vertexCount: 130, edges: [DirectedEdge(from: 5, to: 1)])
        let targets: BitSet = [0, 1, 63, 64, 65, 129]
        #expect(matrix.insertEdges(from: 5, to: targets) == 5)
        #expect(matrix.successors(of: 5) == targets)
        #expect(matrix.outDegree(of: 5) == 6)
        #expect(matrix.inDegree(of: 129) == 1)
        #expect(matrix.edgeCount == 6)
        #expect(matrix.insertEdges(from: 5, to: targets) == 0)
    }

    @Test("Warshall's transitive closure, written with whole-row unions")
    func transitiveClosureByRows() {
        // NetworkX test_dag.py: the closure of the path 1→2→3→4 holds its 6 reachable pairs; the
        // closure of a 3-cycle holds all 9 pairs, self-loops included.
        func closure(_ matrix: AdjacencyMatrix) -> AdjacencyMatrix {
            var result = matrix
            for k in 0 ..< result.vertexCount {
                let throughK = result.successors(of: k)
                for i in 0 ..< result.vertexCount where result[i, k] {
                    result.insertEdges(from: i, to: throughK)
                }
            }
            return result
        }
        let path = AdjacencyMatrix(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        #expect(closure(path).edgeCount == 6)
        #expect(closure(path) == [[0, 1, 1, 1], [0, 0, 1, 1], [0, 0, 0, 1], [0, 0, 0, 0]])
        let cycle = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        #expect(closure(cycle) == AdjacencyMatrix(vertexCount: 3, repeating: true))
    }

    @Test("successors and predecessors answer membership like the matrix", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func viewMembership(_ fixture: DirectedFixture<Int>) {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for u in 0 ..< fixture.vertexCount {
            let successors = matrix.successors(of: u)
            let predecessors = matrix.predecessors(of: u)
            for v in 0 ..< fixture.vertexCount {
                #expect(successors.contains(v) == matrix[u, v])
                #expect(predecessors.contains(v) == matrix[v, u])
                #expect(matrix.edges.contains(DirectedEdge(from: u, to: v)) == matrix[u, v])
            }
            #expect(!successors.contains(fixture.vertexCount))
        }
        #expect(!matrix.edges.contains(DirectedEdge(from: -1, to: 0)))
    }
}

@Suite("AdjacencyMatrix edge positions")
struct AdjacencyMatrixEdgeIndexTests {
    @Test("an edge position names the same cell after the matrix grows")
    func positionsSurviveGrowth() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 2)])
        let position = matrix.edges.firstIndex(of: DirectedEdge(from: 2, to: 1))!
        #expect(position.source == 2)
        #expect(position.target == 1)
        for _ in 0 ..< 70 { matrix.appendVertex() }
        #expect(matrix.edges[position] == DirectedEdge(from: 2, to: 1))
    }

    @Test("slices of the edges and of a row")
    func slices() {
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges)
        let edges = matrix.edges
        let second = edges.index(after: edges.startIndex)
        #expect(Array(edges[second...]) == Array(Array(edges).dropFirst()))
        #expect(Array(edges[..<second]) == [DirectedEdge(from: 0, to: 1)])
        let row = matrix.successors(of: 0)
        let afterFirst = row.index(after: row.startIndex)
        #expect(Array(row[afterFirst...]) == [2, 3, 5])
    }

    @Test(
        "the Collection laws hold on wide random matrices with sparse high bits",
        .tags(.randomized, .conformance),
        arguments: [63, 64, 65, 129, 1000]
    )
    func collectionLawsWide(_ n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(n) &+ 7)
        var matrix = AdjacencyMatrix(vertexCount: n)
        for i in stride(from: 0, to: n, by: Swift.max(1, n / 40)) {
            matrix[i, n - 1] = true
            matrix[i, Int.random(in: 0 ..< n, using: &rng)] = true
            if n > 64 { matrix[i, 64] = true }
        }
        let edges = Array(matrix.edges)
        #expect(edges.count == matrix.edgeCount)
        #expect(edges == edges.sorted { ($0.source, $0.target) < ($1.source, $1.target) })
        #expect(Array(matrix.edges.reversed()) == edges.reversed())
        var forward: [DirectedEdge<Int>] = []
        var i = matrix.edges.startIndex
        while i != matrix.edges.endIndex {
            forward.append(matrix.edges[i])
            let next = matrix.edges.index(after: i)
            #expect(matrix.edges.index(before: next) == i)
            i = next
        }
        #expect(forward == edges)
        #expect(matrix.edges.distance(from: matrix.edges.startIndex, to: matrix.edges.endIndex) == edges.count)
        #expect(matrix.edges.last == edges.last)
        for v in [0, n / 2, n - 1] {
            let row = matrix.successors(of: v)
            #expect(Array(row.reversed()) == Array(row).reversed())
            let column = matrix.predecessors(of: v)
            #expect(Array(column.reversed()) == Array(column).reversed())
            #expect(column.count == matrix.inDegree(of: v))
        }
    }

    @Test("invalid positions trap", .tags(.precondition))
    func invalidPositions() async {
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.edges.index(after: matrix.edges.endIndex)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.edges.index(before: matrix.edges.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
            // A position at a cell with no edge.
            let unset = matrix.edges.endIndex
            _ = matrix.edges[unset]
        }
    }
}

@Suite("AdjacencyMatrix decoding limits and large descriptions", .tags(.conformance))
struct AdjacencyMatrixLimitTests {
    @Test("a tiny payload naming a huge vertex count throws instead of allocating")
    func hostileVertexCount() {
        for count in [16_385, 100_000, 3_037_000_499, Int.max] {
            let json = #"{"vertexCount": \#(count), "edges": []}"#
            #expect(throws: (any Error).self, "\(count)") {
                try JSONDecoder().decode(AdjacencyMatrix.self, from: Data(json.utf8))
            }
        }
    }

    @Test("the default limit admits 16,384 vertices, and userInfo can lower or raise it")
    func configurableLimit() throws {
        let json = Data(#"{"vertexCount": 20, "edges": [0, 1]}"#.utf8)
        let lowered = JSONDecoder()
        lowered.userInfo[AdjacencyMatrix.maximumDecodedVertexCountKey] = 10
        #expect(throws: (any Error).self) {
            try lowered.decode(AdjacencyMatrix.self, from: json)
        }
        let raised = JSONDecoder()
        raised.userInfo[AdjacencyMatrix.maximumDecodedVertexCountKey] = 20_000
        let big = try raised.decode(AdjacencyMatrix.self, from: Data(#"{"vertexCount": 20000, "edges": [19999, 0]}"#.utf8))
        #expect(big.vertexCount == 20_000)
        #expect(big[19_999, 0])
        #expect(AdjacencyMatrix.defaultMaximumDecodedVertexCount == 16_384)
        let atLimit = try JSONDecoder().decode(AdjacencyMatrix.self, from: Data(#"{"vertexCount": 16384, "edges": []}"#.utf8))
        #expect(atLimit.vertexCount == 16_384)
    }

    @Test("matrices over 64 vertices are summarized, not printed cell by cell")
    func largeDescription() {
        var matrix = AdjacencyMatrix(vertexCount: 65)
        matrix[64, 0] = true
        #expect(matrix.description == "AdjacencyMatrix(vertexCount: 65, edgeCount: 1)")
        #expect(AdjacencyMatrix(vertexCount: 64).description.split(separator: "\n").count == 64)
    }

    @Test("debugDescription shows the counts and the first 16 edges")
    func debugDescription() {
        let small = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        #expect(small.debugDescription == "AdjacencyMatrix(vertexCount: 3, edgeCount: 2, edges: [0→1, 2→2])")
        let full = AdjacencyMatrix(vertexCount: 5, repeating: true)
        #expect(full.debugDescription.hasSuffix(", …])"))
        #expect(full.debugDescription.hasPrefix("AdjacencyMatrix(vertexCount: 5, edgeCount: 25, edges: [0→0, 0→1"))
    }

    @Test("reserveCapacity and init trap when the storage would overflow", .tags(.precondition))
    func overflow() async {
        await #expect(processExitsWith: .failure) {
            var matrix = AdjacencyMatrix()
            matrix.reserveCapacity(vertexCount: Int.max)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix(vertexCount: 1 << 33, repeating: false)
        }
    }
}
