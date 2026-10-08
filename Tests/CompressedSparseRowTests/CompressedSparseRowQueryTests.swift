// Successors, degrees, binary-search lookup, edge indices and the transpose. Case IDs (CSR-Snn,
// CSR-Lnn, CSR-Enn, CSR-Tnn) refer to the harvested test catalog.

import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow successors and lookup")
struct CompressedSparseRowQueryTests {
    @Test("CSR-S01 / CSR-S02 successors are the row's slice of targets, ascending")
    func successors() {
        // neo4j tests/builder.rs.
        let graph = CompressedSparseRow(vertexCount: 5, edges: DirectedFixture<Int>.neo4jDirected.edges)
        #expect(Array(graph.successors(of: 0)) == [1, 2])
        #expect(Array(graph.successors(of: 1)) == [2, 3])
        #expect(Array(graph.successors(of: 2)) == [4])
        #expect(Array(graph.successors(of: 3)) == [4])
        #expect(graph.successors(of: 4).isEmpty)
        #expect((0 ..< 5).map(graph.outDegree(of:)) == [2, 2, 1, 1, 0])
    }

    @Test("CSR-S03 a successor slice's indices are the edges' indices", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func sliceIndicesAreEdgeIndices(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for v in 0 ..< fixture.vertexCount {
            let row = graph.successors(of: v)
            #expect(row.indices == graph.offsets[v] ..< graph.offsets[v + 1])
            for k in row.indices {
                #expect(graph.edgeIndex(of: DirectedEdge(from: v, to: row[k])) == k)
                #expect(graph.source(ofEdgeAt: k) == v)
                #expect(graph.target(ofEdgeAt: k) == row[k])
            }
        }
    }

    @Test("CSR-S04 / CSR-S07 empty rows at the start, middle and end")
    func emptyRows() {
        let graph = CompressedSparseRow(vertexCount: 6, edges: [DirectedEdge(from: 3, to: 4)])
        for v in [0, 1, 2, 4, 5] {
            #expect(graph.successors(of: v).isEmpty)
            #expect(graph.outDegree(of: v) == 0)
        }
        #expect(Array(graph.edges) == [DirectedEdge(from: 3, to: 4)])
        #expect(Array(CompressedSparseRow(vertexCount: 10).edges) == [])
    }

    @Test("CSR-S06 edges are row-major: sources non-decreasing, targets ascending within a source", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func rowMajorEdges(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let edges = Array(graph.edges)
        #expect(edges == fixture.edgeSet.sorted { ($0.source, $0.target) < ($1.source, $1.target) })
        #expect(Array(graph.edges.reversed()) == edges.reversed())
        // RandomAccessCollection: positions are edge indices.
        #expect(graph.edges.indices == 0 ..< fixture.edgeCount)
        for (k, edge) in edges.enumerated() {
            #expect(graph.edges[k] == edge)
        }
        #expect(graph.edges.distance(from: graph.edges.startIndex, to: graph.edges.endIndex) == fixture.edgeCount)
    }

    @Test("CSR-S08 a high-degree vertex's successors are complete and ascending")
    func highDegree() {
        let graph = CompressedSparseRow(vertexCount: 41, edges: (1 ... 40).reversed().map { DirectedEdge(from: 0, to: $0) })
        #expect(Array(graph.successors(of: 0)) == Array(1 ... 40))
        #expect(graph.outDegree(of: 0) == 40)
    }

    // MARK: Lookup

    @Test("CSR-L01 contains(edge:) is exact over every pair", .tags(.fixture, .exhaustive), arguments: DirectedFixture<Int>.zeroBased)
    func exhaustiveLookup(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for u in 0 ..< fixture.vertexCount {
            for v in 0 ..< fixture.vertexCount {
                let edge = DirectedEdge(from: u, to: v)
                #expect(graph.contains(edge: edge) == fixture.edgeSet.contains(edge), "\(edge)")
                #expect((graph.edgeIndex(of: edge) != nil) == fixture.edgeSet.contains(edge))
            }
        }
    }

    @Test("CSR-L02 lookups at and around a row's boundaries")
    func rowBoundaries() {
        let graph = CompressedSparseRow(vertexCount: 9, edges: [1, 3, 7].map { DirectedEdge(from: 4, to: $0) } + [DirectedEdge(from: 5, to: 0)])
        for (target, expected) in [(0, false), (1, true), (2, false), (3, true), (4, false), (7, true), (8, false)] {
            #expect(graph.contains(edge: DirectedEdge(from: 4, to: target)) == expected, "4→\(target)")
        }
    }

    @Test("CSR-L03 a lookup in an empty row never reads the next row")
    func emptyRowLookup() {
        // boostExample: row 0 is empty and row 1 starts with 2.
        let graph = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)))
        #expect(graph.edgeIndex(of: DirectedEdge(from: 0, to: 2)) == nil)
    }

    @Test("CSR-L04 self-loop lookup", .tags(.selfLoops))
    func selfLoopLookup() {
        let graph = CompressedSparseRow(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges)
        #expect(graph.contains(edge: DirectedEdge(from: 6, to: 6)))
        #expect(!graph.contains(edge: DirectedEdge(from: 5, to: 5)))
    }

    @Test("CSR-L05 rows on both sides of petgraph's 32-target linear/binary cutoff", arguments: [1, 2, 31, 32, 33, 1000])
    func searchCutoff(_ degree: Int) {
        // Every other target, so each probe between two targets is absent.
        let targets = (0 ..< degree).map { 2 * $0 + 1 }
        let graph = CompressedSparseRow(vertexCount: 2 * degree + 2, edges: targets.map { DirectedEdge(from: 0, to: $0) })
        for v in 0 ..< 2 * degree + 2 {
            #expect(graph.contains(edge: DirectedEdge(from: 0, to: v)) == (!v.isMultiple(of: 2) && v < 2 * degree), "0→\(v)")
        }
    }

    @Test("CSR-L06 out-of-range lookups are false, never a trap")
    func outOfRangeLookup() {
        let graph = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        for edge in [DirectedEdge(from: 5, to: 0), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 2, to: 0), DirectedEdge(from: -1, to: 0), DirectedEdge(from: 0, to: -1)] {
            #expect(!graph.contains(edge: edge), "\(edge)")
            #expect(graph.edgeIndex(of: edge) == nil)
        }
        #expect(!graph.contains(2))
        #expect(!graph.contains(-1))
        #expect(graph.contains(1))
    }

    @Test("CSR-L07 lookup agrees with the transpose", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func lookupAgreesWithTranspose(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let transposed = graph.transposed()
        for u in 0 ..< fixture.vertexCount {
            for v in 0 ..< fixture.vertexCount {
                #expect(graph.contains(edge: DirectedEdge(from: u, to: v)) == transposed.contains(edge: DirectedEdge(from: v, to: u)))
            }
        }
    }

    @Test("`edges` answers contains like the graph")
    func edgesContains() {
        let graph = CompressedSparseRow(vertexCount: 24, edges: DirectedFixture<Int>.boost24.edges)
        #expect(graph.edges.contains(DirectedEdge(from: 23, to: 16)))
        #expect(!graph.edges.contains(DirectedEdge(from: 16, to: 23)))
        #expect(!graph.edges.contains(DirectedEdge(from: 99, to: 0)))
    }
}

@Suite("CompressedSparseRow edge indices")
struct CompressedSparseRowEdgeIndexTests {
    @Test("CSR-E01 – E03 indices cover 0..<edgeCount in row-major order and round-trip", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func roundTrip(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        var seen = Set<Int>()
        for (k, edge) in graph.edges.enumerated() {
            #expect(graph.edgeIndex(of: edge) == k)
            #expect(graph.source(ofEdgeAt: k) == edge.source)
            #expect(graph.target(ofEdgeAt: k) == edge.target)
            seen.insert(k)
        }
        #expect(seen == Set(0 ..< fixture.edgeCount))
    }

    @Test("CSR-E02 the source of an edge index is found across empty rows")
    func sourceAcrossEmptyRows() {
        let graph = CompressedSparseRow(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 0)])
        #expect(graph.offsets == [0, 1, 1, 1, 3, 3])
        #expect(graph.targets == [1, 0, 2])
        #expect((0 ..< 3).map(graph.source(ofEdgeAt:)) == [0, 3, 3])
        #expect((0 ..< 3).map(graph.target(ofEdgeAt:)) == [1, 0, 2])
    }

    @Test("CSR-E05 an edge's index depends only on the edge set, not on input order or duplicates", .tags(.randomized), arguments: 0 ..< 10 as Range<UInt>)
    func stableAcrossInputOrder(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let edges = DirectedFixture<Int>.boostCsrUnsorted.edges
        let input = (edges + edges.prefix(3)).shuffled(using: &rng)
        let graph = CompressedSparseRow(vertexCount: 6, edges: input)
        #expect(graph.edgeIndex(of: DirectedEdge(from: 3, to: 2)) == 1)
        #expect(graph.edgeIndex(of: DirectedEdge(from: 5, to: 2)) == 5)
        #expect(graph.edgeIndex(of: DirectedEdge(from: 0, to: 2)) == 0)
    }

    @Test("CSR-E07 / CSR-E08 an array indexed by edge index lines up with `edges`")
    func edgePropertyArray() {
        // Boost.Graph csr_usage: distances in km, given here in reverse order.
        let input: [(DirectedEdge<Int>, Int)] = [
            (DirectedEdge(from: 2, to: 3), 200), (DirectedEdge(from: 1, to: 2), 310),
            (DirectedEdge(from: 0, to: 2), 775), (DirectedEdge(from: 0, to: 1), 460),
        ]
        let graph = CompressedSparseRow(vertexCount: 4, edges: input.map(\.0))
        var km = [Int](repeating: 0, count: graph.edgeCount)
        for (edge, distance) in input {
            km[graph.edgeIndex(of: edge)!] = distance
        }
        #expect(km == [460, 775, 310, 200])
        #expect(zip(graph.edges, km).map { "\($0)=\($1)" } == ["0→1=460", "0→2=775", "1→2=310", "2→3=200"])
    }
}

@Suite("CompressedSparseRow transpose")
struct CompressedSparseRowTransposeTests {
    @Test("CSR-T02 the transpose has canonical rows: exact arrays", .tags(.fixture))
    func exactTransposes() {
        let cases: [(DirectedFixture<Int>, offsets: [Int], targets: [Int])] = [
            (.directedPath3, [0, 0, 1, 2], [0, 1]),
            (.networkXFunctionGraph, [0, 1, 3, 5, 6, 6], [1, 0, 1, 0, 1, 0]),
            (.house, [0, 2, 4, 5, 6, 7, 7], [1, 4, 2, 4, 3, 5, 3]),
            (.scc9, [0, 1, 2, 3, 4, 5, 7, 9, 10, 11], [6, 4, 8, 0, 7, 2, 7, 3, 8, 1, 5]),
            (.boostExample, [0, 2, 2, 4, 5, 6, 7], [2, 5, 1, 2, 4, 3, 1]),
            (.boostCsrUnsorted, [0, 2, 3, 6, 6, 6, 6], [4, 5, 4, 0, 3, 5]),
            (.boostWebGraph, [0, 3, 6, 8, 10, 11, 13], [1, 2, 5, 0, 3, 4, 0, 5, 0, 1, 3, 1, 2]),
            (.petgraphCsr1, [0, 2, 3, 6], [0, 1, 1, 0, 1, 2]),
            (.petgraphBellmanFord, [0, 1, 3, 5, 7, 7, 8, 8, 10, 11], [1, 0, 1, 0, 1, 1, 2, 4, 5, 6, 7]),
            (.neo4jDirected, [0, 0, 1, 3, 4, 6], [0, 0, 1, 1, 2, 3]),
            (.jgraphtSparseDirected, [0, 1, 2, 2, 2, 5, 7, 10, 11], [1, 0, 1, 2, 3, 1, 4, 1, 5, 7, 7]),
            (.boost24, [0, 2, 4, 5, 6, 9, 11, 13, 13, 16, 17, 19, 21, 23, 25, 26, 29, 30, 32, 34, 37, 38, 39, 41, 43],
             [3, 4, 8, 9, 1, 6, 11, 12, 13, 2, 4, 15, 16, 10, 12, 13, 18, 2, 3, 7, 9, 14, 16, 20, 21, 5, 10, 11, 13, 23, 7, 8, 19, 21, 10, 11, 12, 17, 22, 14, 15, 19, 20]),
        ]
        for (fixture, offsets, targets) in cases {
            let transposed = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).transposed()
            #expect(transposed.offsets == offsets, "\(fixture.name)")
            #expect(transposed.targets == targets, "\(fixture.name)")
        }
    }

    @Test("CSR-T01 / CSR-T03 / CSR-T04 transposing reverses edges, keeps counts, is an involution, and gives in-degrees", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func properties(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let transposed = graph.transposed()
        #expect(transposed.vertexCount == graph.vertexCount)
        #expect(transposed.edgeCount == graph.edgeCount)
        #expect(Set(transposed.edges) == Set(fixture.edgeSet.map { DirectedEdge(from: $0.target, to: $0.source) }))
        #expect(transposed.transposed() == graph)
        for v in 0 ..< fixture.vertexCount {
            #expect(transposed.outDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
            #expect(Array(transposed.successors(of: v)) == fixture.edgeSet.filter { $0.target == v }.map(\.source).sorted())
        }
        // I08: the transpose satisfies the invariants too.
        #expect(transposed == (try? CompressedSparseRow(offsets: transposed.offsets, targets: transposed.targets)))
    }

    @Test("CSR-T05 a symmetric graph is its own transpose; an asymmetric one is not")
    func symmetric() {
        for fixture in [DirectedFixture<Int>.petersen, .cube, .completeDirected3, .completeDirected10] {
            let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(graph.transposed() == graph, "\(fixture.name)")
        }
        let path = CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges)
        #expect(path.transposed() != path)
    }

    @Test("CSR-T06 a self-loop stays in place", .tags(.selfLoops))
    func selfLoopStays() {
        let transposed = CompressedSparseRow(vertexCount: 8, edges: DirectedFixture<Int>.jgraphtSparseDirected.edges).transposed()
        #expect(transposed.contains(edge: DirectedEdge(from: 7, to: 7)))
        #expect(Array(transposed.successors(of: 7)) == [7])
    }

    @Test("CSR-T07 transposing empty and edgeless graphs keeps the vertex count")
    func edgeless() {
        #expect(CompressedSparseRow().transposed().offsets == [0])
        #expect(CompressedSparseRow(vertexCount: 10).transposed().offsets == Array(repeating: 0, count: 11))
    }
}

@Suite("CompressedSparseRow edge slices")
struct CompressedSparseRowEdgeSliceTests {
    @Test("CSR-S11 every slice of the edges holds the same edges as the slice of an array", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func everySlice(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let array = Array(graph.edges)
        let m = graph.edgeCount
        for a in 0 ... m {
            for b in a ... m {
                let slice = graph.edges[a ..< b]
                #expect(Array(slice) == Array(array[a ..< b]), "\(a)..<\(b)")
                #expect(slice.startIndex == a)
                #expect(slice.endIndex == b)
                #expect(slice.count == b - a)
            }
        }
    }

    @Test("CSR-S12 the Collection algorithms that slice agree with an array")
    func slicingAlgorithms() {
        let graph = CompressedSparseRow(vertexCount: 24, edges: DirectedFixture<Int>.boost24.edges)
        let edges = graph.edges
        let array = Array(edges)
        #expect(Array(edges.dropFirst(5)) == Array(array.dropFirst(5)))
        #expect(Array(edges.dropLast(7)) == Array(array.dropLast(7)))
        #expect(Array(edges.prefix(9)) == Array(array.prefix(9)))
        #expect(Array(edges.suffix(4)) == Array(array.suffix(4)))
        #expect(edges.first == array.first)
        #expect(edges.last == array.last)
        #expect(edges.dropFirst(10).first == array[10])
        #expect(edges.dropFirst(10).last == array.last)
        #expect(Array(edges.dropFirst(3).dropLast(3).reversed()) == Array(array.dropFirst(3).dropLast(3).reversed()))
        #expect(edges.split { $0.isSelfLoop }.map(Array.init) == array.split { $0.isSelfLoop }.map(Array.init))
        // A slice of a slice keeps edge indices as positions.
        let inner = edges[10 ..< 30][15 ..< 20]
        #expect(inner.indices == 15 ..< 20)
        #expect(Array(inner) == Array(array[15 ..< 20]))
        for k in inner.indices {
            #expect(inner[k] == array[k])
        }
        #expect(inner.index(before: 20) == 19)
        #expect(inner.index(after: 15) == 16)
    }

    @Test("CSR-S13 a slice starting inside a row, or across empty rows, starts with the right source")
    func sliceStartsMidRow() {
        // Rows: 0 → {1, 2, 3}, 1 and 2 empty, 3 → {0}, 4 empty, 5 → {4, 5}.
        let graph = CompressedSparseRow(vertexCount: 6, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 3, to: 0), DirectedEdge(from: 5, to: 4), DirectedEdge(from: 5, to: 5),
        ])
        #expect(Array(graph.edges[1 ..< 4]) == [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 0)])
        #expect(Array(graph.edges[3 ..< 6]) == [DirectedEdge(from: 3, to: 0), DirectedEdge(from: 5, to: 4), DirectedEdge(from: 5, to: 5)])
        #expect(Array(graph.edges[5 ..< 6]) == [DirectedEdge(from: 5, to: 5)])
        #expect(Array(graph.edges[6 ..< 6]) == [])
        #expect(Array(graph.edges[0 ..< 0]) == [])
    }

    @Test("CSR-S14 contains, firstIndex and lastIndex answer by binary search, and only within a slice")
    func lookupInSlices() {
        let graph = CompressedSparseRow(vertexCount: 24, edges: DirectedFixture<Int>.boost24.edges)
        let array = Array(graph.edges)
        for (k, edge) in array.enumerated() {
            #expect(graph.edges.firstIndex(of: edge) == k)
            #expect(graph.edges.lastIndex(of: edge) == k)
            #expect(graph.edges.contains(edge))
        }
        let slice = graph.edges[10 ..< 20]
        for (k, edge) in array.enumerated() {
            #expect(slice.contains(edge) == (10 ..< 20).contains(k), "\(edge)")
            #expect(slice.firstIndex(of: edge) == ((10 ..< 20).contains(k) ? k : nil), "\(edge)")
            #expect(slice.lastIndex(of: edge) == ((10 ..< 20).contains(k) ? k : nil), "\(edge)")
        }
        #expect(graph.edges.firstIndex(of: DirectedEdge(from: 0, to: 0)) == nil)
        #expect(graph.edges.firstIndex(of: DirectedEdge(from: -1, to: 99)) == nil)
    }

    @Test("CSR-S15 indices and positions of a slice of the empty graph")
    func emptySlices() {
        let graph = CompressedSparseRow()
        #expect(graph.edges[0 ..< 0].isEmpty)
        #expect(graph.edges.dropFirst().isEmpty)
        #expect(graph.edges.last == nil)
        #expect(CompressedSparseRow(vertexCount: 5).edges.suffix(3).isEmpty)
    }
}

@Suite("CompressedSparseRow in-degrees and raw buffers")
struct CompressedSparseRowInDegreeTests {
    @Test("CSR-T10 inDegrees counts the edges entering each vertex", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func inDegrees(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let inDegrees = graph.inDegrees
        #expect(inDegrees.count == fixture.vertexCount)
        for v in 0 ..< fixture.vertexCount {
            #expect(inDegrees[v] == fixture.inDegree[v], "inDegree(of: \(v))")
        }
        #expect(inDegrees.reduce(0, +) == graph.edgeCount)
    }

    @Test("CSR-T11 inDegrees of graphs with no edges")
    func inDegreesWithoutEdges() {
        #expect(CompressedSparseRow().inDegrees == [])
        #expect(CompressedSparseRow(vertexCount: 3).inDegrees == [0, 0, 0])
    }

    @Test("CSR-S16 the raw buffers are the offsets and targets, and errors pass through")
    func rawBuffers() throws {
        let graph = CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.boostWebGraph.edges)
        let copied = graph.withUnsafeBufferPointers { offsets, targets in
            (Array(offsets), Array(targets))
        }
        #expect(copied.0 == graph.offsets)
        #expect(copied.1 == graph.targets)

        var sum = 0
        graph.withUnsafeBufferPointers { offsets, targets in
            for v in 0 ..< offsets.count - 1 {
                for k in offsets[v] ..< offsets[v + 1] { sum += targets[k] }
            }
        }
        #expect(sum == graph.targets.reduce(0, +))

        struct Stop: Error, Equatable {}
        #expect(throws: Stop()) {
            try graph.withUnsafeBufferPointers { (_, _) throws(Stop) in throw Stop() }
        }
        #expect(CompressedSparseRow().withUnsafeBufferPointers { offsets, targets in offsets.count + targets.count } == 1)
    }
}
