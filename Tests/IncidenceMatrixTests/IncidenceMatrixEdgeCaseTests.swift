// Cases the catalog rows and the properties do not reach, each pinned to one behavior: the
// descriptions and their elision, hashing across storage strides, near-miss membership and
// equality, the trapping index reads, the decoder's overflow guards, and edge subscripts on the
// oriented matrix's incidence graph. See README.md.

import Foundation
import GraphProtocols
import Hypergraphs
import IncidenceMatrixModule
import Testing

@Suite("IncidenceMatrix edge cases")
struct IncidenceMatrixEdgeCaseTests {
    @Test("Descriptions: rows of cells, column 0 leftmost, eliding past 16 rows and 64 columns")
    func descriptions() {
        #expect(IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 2], [1, 2]]).description == "3×2 [10, 01, 11]")
        let oriented = OrientedIncidenceMatrix(vertexCount: 3, hyperedges: [(sources: [0], targets: [1]), (sources: [1], targets: [2])])
        #expect(oriented.description == "3×2 [-0, +-, 0+]")
        #expect(OrientedIncidenceMatrix(vertexCount: 1, hyperedges: [(sources: [0], targets: [0])]).description == "1×1 [0]")
        let wide = IncidenceMatrix(vertexCount: 17, hyperedges: (0 ..< 65).map { [$0 % 17] })
        let row: (Int) -> String = { v in String((0 ..< 64).map { $0 % 17 == v ? "1" : "0" }) + "…" }
        #expect(wide.description == "17×65 [" + (0 ..< 16).map(row).joined(separator: ", ") + ", …]")
        let exact = IncidenceMatrix(vertexCount: 16, hyperedges: (0 ..< 64).map { _ in [Int]() })
        #expect(exact.description == "16×64 [" + Array(repeating: String(repeating: "0", count: 64), count: 16).joined(separator: ", ") + "]")
    }

    @Test("Hashing: equal matrices hash alike whatever their storage strides, and differing ones apart")
    func hashing() {
        let a = IncidenceMatrix(vertexCount: 2, hyperedges: [[0]])
        var b = a
        b.reserveCapacity(vertexCount: 200, hyperedgeCount: 300)
        #expect(a == b && a.hashValue == b.hashValue)
        let c = IncidenceMatrix(vertexCount: 2, hyperedges: [[1]])
        #expect(a != c && a.hashValue != c.hashValue)
        let forward = OrientedIncidenceMatrix(vertexCount: 3, hyperedges: [(sources: [0], targets: [1])])
        let elsewhere = OrientedIncidenceMatrix(vertexCount: 3, hyperedges: [(sources: [0], targets: [2])])
        #expect(forward != elsewhere && forward.hashValue != elsewhere.hashValue)
    }

    @Test("contains: a column sharing the first member and the size, and each side of an oriented column")
    func containsNearMisses() {
        let matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 1]])
        #expect(!matrix.contains(hyperedge: [0, 2]) && matrix.contains(hyperedge: [1, 0]))
        let oriented = OrientedIncidenceMatrix(vertexCount: 3, hyperedges: [(sources: [0], targets: [1]), (sources: [], targets: [2])])
        #expect(!oriented.contains(sources: [] as [Int], targets: [] as [Int]))
        #expect(!oriented.contains(sources: [] as [Int], targets: [1]))
        #expect(!oriented.contains(sources: [0], targets: [2]) && !oriented.contains(sources: [2], targets: [1]))
        #expect(oriented.contains(sources: [0], targets: [1]) && oriented.contains(sources: [] as [Int], targets: [2]))
    }

    @Test("The index reads and the column subscript trap outside their ranges, even with no words to read")
    func indexRanges() async {
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 2).vertexIndex(of: -1) }
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 2).vertexIndex(of: 2) }
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 2).vertex(atIndex: 2) }
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 1, hyperedges: [[0]]).hyperedgeIndex(of: -1) }
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 1, hyperedges: [[0]]).hyperedgeIndex(of: 1) }
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 0, hyperedges: [[Int]()]).hyperedges[1] }
        await #expect(processExitsWith: .failure) { _ = IncidenceMatrix(vertexCount: 1).incidentHyperedgeIndices(ofIndex: 1) }
        await #expect(processExitsWith: .failure) {
            var matrix = IncidenceMatrix(vertexCount: 1)
            matrix.reserveCapacity(vertexCount: 1, hyperedgeCount: -1)
        }
        let matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[1]])
        #expect(matrix.vertexIndex(of: 1) == 1 && matrix.vertex(atIndex: 0) == 0 && matrix.hyperedgeIndex(of: 0) == 0)
        #expect(Array(matrix.incidentHyperedgeIndices(ofIndex: 1)) == [0] && Array(matrix.hyperedges[0]) == [1])
    }

    @Test("Decoding throws, never traps, for shapes whose stored word count overflows")
    func overflowingShapes() {
        let half = Int.max / 2
        let wide = Data(#"{"vertexCount":\#(half + 1),"hyperedges":\#(Array(repeating: [Int](), count: 65))}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(IncidenceMatrix.self, from: wide) }
        let deep = Data(#"{"vertexCount":\#(half),"hyperedges":\#(Array(repeating: [Int](), count: 128))}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(IncidenceMatrix.self, from: deep) }
        let tall = Data(#"{"vertexCount":\#(half + 1),"sources":[],"targets":[]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(OrientedIncidenceMatrix.self, from: tall) }
        let small = Data(#"{"vertexCount":2,"sources":[[0]],"targets":[[1]]}"#.utf8)
        #expect((try? JSONDecoder().decode(OrientedIncidenceMatrix.self, from: small)) == OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]))
    }

    @Test("The oriented matrix's incidence graph: edge subscripts and ends agree with iteration on both sides")
    func orientedViewSubscripts() {
        let oriented = OrientedIncidenceMatrix(vertexCount: 4, hyperedges: [
            (sources: [0, 2], targets: [1, 3]), (sources: [], targets: [0, 2, 3]), (sources: [3], targets: []), (sources: [1, 2], targets: [0, 1]),
        ])
        let view = oriented.incidenceGraphView
        let iterated = Array(view.edges)
        #expect(iterated.count == 12 && view.edgeCount == 12)
        for q in view.edges.indices {
            #expect(view.edges[q] == iterated[q])
            #expect(view.source(ofEdgeAt: q) == iterated[q].source && view.target(ofEdgeAt: q) == iterated[q].target)
        }
        let list = IncidenceList(oriented)
        #expect(iterated == Array(list.incidenceGraphView.edges))
    }
}
