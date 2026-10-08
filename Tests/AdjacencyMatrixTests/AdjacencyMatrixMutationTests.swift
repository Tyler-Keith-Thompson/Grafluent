// The cell subscript, edge insertion and removal, and clearing. Case IDs (AM-Snn, AM-Enn, AM-Vnn,
// AM-Lnn) refer to the harvested test catalog.

import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix cells and edge mutation")
struct AdjacencyMatrixMutationTests {
    // MARK: Subscript

    @Test("AM-S01 reading a cell tests for the edge, and direction matters")
    func readCell() {
        // petgraph src/matrix_graph.rs: a→b, b→c.
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(matrix[0, 1])
        #expect(matrix[1, 2])
        #expect(!matrix[0, 2])
        #expect(!matrix[1, 0])
        #expect(!matrix[2, 1])
    }

    @Test("AM-S02 / AM-S03 writing true inserts, writing false removes, and counts never drift", arguments: [false, true])
    func writeCell(isShared: Bool) {
        // Boost.Graph test/adjacency_matrix_test.cpp test_remove_edges.
        var matrix = AdjacencyMatrix(vertexCount: 2)
        let copy: AdjacencyMatrix? = isShared ? matrix : nil

        matrix[0, 1] = true
        #expect(matrix.edgeCount == 1)
        matrix[0, 1] = true
        #expect(matrix.edgeCount == 1)
        #expect(matrix.contains(edge: DirectedEdge(from: 0, to: 1)))

        matrix[0, 1] = false
        #expect(matrix.edgeCount == 0)
        matrix[0, 1] = false
        #expect(matrix.edgeCount == 0)
        #expect(!matrix.contains(edge: DirectedEdge(from: 0, to: 1)))

        if let copy {
            #expect(copy.edgeCount == 0)
            #expect(!copy[0, 1])
        }
    }

    @Test("toggling a cell through the subscript")
    func toggleCell() {
        var matrix = AdjacencyMatrix(vertexCount: 4)
        matrix[3, 2].toggle()
        #expect(matrix[3, 2])
        #expect(matrix.edgeCount == 1)
        matrix[3, 2].toggle()
        #expect(!matrix[3, 2])
        #expect(matrix.edgeCount == 0)
    }

    // MARK: Insert and remove

    @Test("AM-E01 insert reports whether the edge was new", arguments: [false, true])
    func insertReportsNovelty(isShared: Bool) {
        var matrix = AdjacencyMatrix(vertexCount: 3)
        let copy: AdjacencyMatrix? = isShared ? matrix : nil

        let first = matrix.insert(edge: DirectedEdge(from: 0, to: 2))
        #expect(first.inserted)
        #expect(first.memberAfterInsert == DirectedEdge(from: 0, to: 2))
        let second = matrix.insert(edge: DirectedEdge(from: 0, to: 2))
        #expect(!second.inserted)
        #expect(second.memberAfterInsert == DirectedEdge(from: 0, to: 2))
        #expect(matrix.edgeCount == 1)

        if let copy {
            #expect(copy.edgeCount == 0)
        }
    }

    @Test("AM-E02 remove returns the edge when present, and nil afterwards or when never inserted")
    func removeReportsPresence() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(matrix.remove(edge: DirectedEdge(from: 0, to: 1)) == DirectedEdge(from: 0, to: 1))
        #expect(matrix.remove(edge: DirectedEdge(from: 0, to: 1)) == nil)
        #expect(matrix.remove(edge: DirectedEdge(from: 0, to: 2)) == nil)
        #expect(matrix.edgeCount == 0)
    }

    @Test("removing an edge with an out-of-range endpoint returns nil and changes nothing")
    func removeOutOfRange() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        let before = matrix
        #expect(matrix.remove(edge: DirectedEdge(from: 3, to: 0)) == nil)
        #expect(matrix.remove(edge: DirectedEdge(from: 0, to: 3)) == nil)
        #expect(matrix.remove(edge: DirectedEdge(from: -1, to: 0)) == nil)
        #expect(matrix == before)
        #expect(matrix.vertexCount == 3)
    }

    @Test("AM-E03 antiparallel edges are distinct")
    func antiparallel() {
        var matrix = AdjacencyMatrix(vertexCount: 3)
        matrix.insert(edge: DirectedEdge(from: 0, to: 2))
        #expect(!matrix.contains(edge: DirectedEdge(from: 2, to: 0)))
        matrix.insert(edge: DirectedEdge(from: 2, to: 0))
        #expect(matrix.edgeCount == 2)
        matrix.remove(edge: DirectedEdge(from: 0, to: 2))
        #expect(matrix.contains(edge: DirectedEdge(from: 2, to: 0)))
        #expect(matrix.edgeCount == 1)
    }

    @Test("AM-E04 removing an edge leaves every other edge intact", .tags(.randomized), arguments: 0 ..< 10 as Range<UInt>)
    func removeLeavesOthers(seed: UInt) {
        // gonum simple/densegraph_test.go: 100 vertices, 0–4 random successors each.
        var rng = SeededRandomNumberGenerator(seed: seed)
        var edges = Set<DirectedEdge<Int>>()
        for u in 0 ..< 100 {
            for _ in 0 ..< Int.random(in: 0 ... 4, using: &rng) {
                edges.insert(DirectedEdge(from: u, to: Int.random(in: 0 ..< 100, using: &rng)))
            }
        }
        var matrix = AdjacencyMatrix(vertexCount: 100, edges: edges)
        var remaining = edges
        for edge in edges.sorted(by: { ($0.source, $0.target) < ($1.source, $1.target) }).shuffled(using: &rng) {
            #expect(matrix.remove(edge: edge) == edge)
            remaining.remove(edge)
            #expect(!matrix.contains(edge: edge))
            #expect(matrix.edgeCount == remaining.count)
            #expect(matrix.vertexCount == 100)
        }
        #expect(matrix == AdjacencyMatrix(vertexCount: 100))
    }

    @Test("AM-E06 a self-loop on every vertex gives the identity matrix", .tags(.selfLoops))
    func selfLoopsAreTheIdentity() {
        var matrix = AdjacencyMatrix(vertexCount: 100)
        for v in 0 ..< 100 {
            #expect(matrix.insert(edge: DirectedEdge(from: v, to: v)).inserted)
        }
        #expect(matrix.edgeCount == 100)
        for i in 0 ..< 100 {
            #expect(Array(matrix.successors(of: i)) == [i])
            #expect(Array(matrix.predecessors(of: i)) == [i])
        }
    }

    @Test("AM-L07 removing an absent self-loop changes nothing", .tags(.selfLoops))
    func removeAbsentSelfLoop() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(matrix.remove(edge: DirectedEdge(from: 2, to: 2)) == nil)
        #expect(matrix.edgeCount == 1)
    }

    @Test("AM-E07 inserting the same edges in any order gives equal matrices", .tags(.randomized), arguments: 1 ... 10 as ClosedRange<UInt>)
    func insertionOrder(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let fixture = DirectedFixture<Int>.boost24
        var a = AdjacencyMatrix(vertexCount: 24)
        for edge in fixture.edges { a.insert(edge: edge) }
        var b = AdjacencyMatrix(vertexCount: 24)
        for edge in fixture.edges.shuffled(using: &rng) { b.insert(edge: edge) }
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: Clearing

    @Test("AM-V06 removeAllEdges keeps every vertex")
    func removeAllEdges() {
        var matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        matrix.removeAllEdges()
        #expect(matrix.vertexCount == 6)
        #expect(matrix.edgeCount == 0)
        #expect(matrix == AdjacencyMatrix(vertexCount: 6))
        #expect(matrix.appendVertex() == 6)
        #expect(matrix.successors(of: 6).isEmpty)
        #expect(matrix.predecessors(of: 6).isEmpty)
        #expect(matrix.edges.isEmpty)
    }

    @Test("removeAll leaves the 0-vertex matrix, still usable", arguments: [false, true])
    func removeAll(keepingCapacity: Bool) {
        var matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        matrix.removeAll(keepingCapacity: keepingCapacity)
        #expect(matrix.vertexCount == 0)
        #expect(matrix.edgeCount == 0)
        #expect(matrix == AdjacencyMatrix())
        #expect(matrix.appendVertex() == 0)
        matrix[0, 0] = true
        #expect(matrix.edgeCount == 1)
        #expect(Array(matrix.successors(of: 0)) == [0])
    }

    @Test("removing every edge while iterating over `edges`", arguments: DirectedFixture<Int>.zeroBased)
    func removeWhileIterating(_ fixture: DirectedFixture<Int>) {
        var matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        var visited: [DirectedEdge<Int>] = []
        for edge in matrix.edges {
            visited.append(edge)
            #expect(matrix.remove(edge: edge) != nil)
        }
        #expect(Set(visited) == fixture.edgeSet)
        #expect(visited.count == fixture.edgeCount)
        #expect(matrix.edgeCount == 0)
    }
}

@Suite("AdjacencyMatrix vertex growth")
struct AdjacencyMatrixGrowthTests {
    @Test("AM-G01 appendVertex returns the new index, and the new vertex is isolated")
    func appendReturnsIndex() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        #expect(matrix.appendVertex() == 3)
        #expect(matrix.vertexCount == 4)
        #expect(matrix.edgeCount == 2)
        #expect(matrix.successors(of: 3).isEmpty)
        #expect(matrix.predecessors(of: 3).isEmpty)
        for v in 0 ..< 4 {
            #expect(!matrix[v, 3])
            #expect(!matrix[3, v])
        }
        #expect(matrix[0, 1])
        #expect(matrix[2, 2])
    }

    @Test(
        "AM-G02 growth preserves every existing cell",
        .tags(.randomized),
        arguments: [0, 1, 3, 4, 7, 8, 31, 32, 63, 64, 65, 127, 128], [1, 2, 64]
    )
    func growthPreservesCells(start: Int, appended: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(start * 1000 + appended))
        var cells = Set<DirectedEdge<Int>>()
        for i in 0 ..< start {
            for j in 0 ..< start where Int.random(in: 0 ..< 4, using: &rng) == 0 {
                cells.insert(DirectedEdge(from: i, to: j))
            }
        }
        var matrix = AdjacencyMatrix(vertexCount: start, edges: cells)
        for k in 0 ..< appended {
            #expect(matrix.appendVertex() == start + k)
        }
        let n = start + appended
        #expect(matrix.vertexCount == n)
        #expect(matrix.edgeCount == cells.count)
        for i in 0 ..< n {
            for j in 0 ..< n {
                #expect(matrix[i, j] == cells.contains(DirectedEdge(from: i, to: j)), "[\(i), \(j)]")
            }
        }
    }

    @Test("AM-G03 reserveCapacity changes nothing observable")
    func reserveCapacity() {
        var matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        let before = matrix
        matrix.reserveCapacity(vertexCount: 500)
        #expect(matrix == before)
        #expect(matrix.hashValue == before.hashValue)
        #expect(matrix.vertexCount == 6)
        #expect(Array(matrix.edges) == Array(before.edges))
        matrix.reserveCapacity(vertexCount: 0)
        #expect(matrix == before)
    }

    @Test("AM-G06 growing across a 64-bit word boundary")
    func growAcrossWordBoundary() {
        // fixedbitset tests: grow from 48 to 72 bits; here rows of 63 grow to 65.
        var matrix = AdjacencyMatrix(vertexCount: 63)
        for i in 0 ..< 63 {
            for j in 0 ..< 63 { matrix[i, j] = true }
        }
        matrix.appendVertex()
        matrix.appendVertex()
        #expect(matrix.vertexCount == 65)
        #expect(matrix.edgeCount == 63 * 63)
        #expect(Array(matrix.successors(of: 0)) == Array(0 ..< 63))
        #expect(matrix.predecessors(of: 63).isEmpty)
        #expect(matrix.predecessors(of: 64).isEmpty)
        matrix[64, 64] = true
        #expect(Array(matrix.successors(of: 64)) == [64])
        #expect(matrix.edgeCount == 63 * 63 + 1)
    }

    @Test("AM-G07 appending to the empty matrix")
    func appendToEmpty() {
        var matrix = AdjacencyMatrix(vertexCount: 0)
        #expect(matrix.appendVertex() == 0)
        matrix[0, 0] = true
        #expect(matrix.edgeCount == 1)
        #expect(matrix.description == "1")
    }

    @Test("AM-W07 a diagonal pattern survives growth from 0 to 129, one vertex at a time", .tags(.selfLoops))
    func diagonalThroughGrowth() {
        var matrix = AdjacencyMatrix()
        for n in 1 ... 129 {
            let v = matrix.appendVertex()
            #expect(v == n - 1)
            matrix[v, v] = true
            #expect(matrix.edgeCount == n)
            if [1, 63, 64, 65, 127, 128, 129].contains(n) {
                for i in 0 ..< n {
                    #expect(Array(matrix.successors(of: i)) == [i], "n = \(n), vertex \(i)")
                    #expect(Array(matrix.predecessors(of: i)) == [i], "n = \(n), vertex \(i)")
                }
            }
        }
    }

    // Whether growth is amortized is a performance property, measured by the benchmarks; this
    // checks that thousands of appends, crossing many restrides, keep every cell.
    @Test("appending 4096 vertices one at a time keeps every cell")
    func manyAppends() {
        var matrix = AdjacencyMatrix()
        for _ in 0 ..< 4096 {
            let v = matrix.appendVertex()
            if v > 0 { matrix[v, v - 1] = true }
        }
        #expect(matrix.vertexCount == 4096)
        #expect(matrix.edgeCount == 4095)
        #expect(matrix[4095, 4094])
        #expect(matrix[1, 0])
        #expect(!matrix[0, 1])
    }
}
