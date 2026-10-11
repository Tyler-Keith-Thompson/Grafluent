// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in a
// debug build; the benchmarks take timings. Every expected value is known by construction: a matrix
// from a multigraph at n = 2 048, m = 2 × 10⁴ (5 MB per orientation, api.md's benchmark shape),
// checked against the graph's rows; 10⁵ cell edits against a set, growing past many word
// boundaries; and the components of a matrix at density 1/8 against an incidence-list copy.
// See README.md.

import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import IncidenceMatrixModule
import Multigraphs
import Testing

@Suite("IncidenceMatrix at scale")
struct IncidenceMatrixStressTests {
    @Test("IncidenceMatrix of a multigraph at n = 2 048, m = 2 × 10⁴ equals the graph's incidence", .timeLimit(.minutes(1)))
    func fromGraphAtScale() async {
        await Task {
            let n = 2_048, m = 20_000
            var rng = SeededRandomNumberGenerator(seed: 5)
            let edges = (0 ..< m).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
            let matrix = IncidenceMatrix(graph)
            #expect(matrix.vertexCount == n && matrix.hyperedgeCount == m)
            let loops = edges.filter { $0.u == $0.v }.count
            #expect((0 ..< n).reduce(0) { $0 + matrix.degree(of: $1) } == 2 * m - loops)
            for v in stride(from: 0, to: n, by: 61) {
                // A loop is one bit, so the row is the graph's incident edges, each once.
                #expect(Array(matrix.incidentHyperedges(of: v)) == Array(Set(graph.incidentEdges(of: v))).sorted())
            }
            for p in stride(from: 0, to: m, by: 997) {
                #expect(Array(matrix.members(ofHyperedgeAt: p)) == Set([edges[p].u, edges[p].v]).sorted())
            }
            let oriented = OrientedIncidenceMatrix(graph)
            #expect(IncidenceMatrix(oriented) == matrix)
            #expect(oriented.transposed().transposed() == oriented && oriented.reversed.reversed == oriented)
        }.value
    }

    @Test("10⁵ cell edits on a matrix grown to 300 × 300 agree with a set", .timeLimit(.minutes(1)))
    func editsAtScale() async {
        await Task {
            var rng = SeededRandomNumberGenerator(seed: 9)
            var matrix = IncidenceMatrix()
            var cells = Set<Int>()
            for _ in 0 ..< 300 {
                matrix.appendVertex()
                matrix.insert(hyperedge: [] as [Int])
            }
            for _ in 0 ..< 100_000 {
                let v = Int.random(in: 0 ..< 300, using: &rng), p = Int.random(in: 0 ..< 300, using: &rng)
                if Bool.random(using: &rng) {
                    let changed = matrix.insert(v, intoHyperedgeAt: p)
                    #expect(changed == cells.insert(v * 300 + p).inserted)
                } else {
                    let changed = matrix.remove(v, fromHyperedgeAt: p)
                    #expect(changed == (cells.remove(v * 300 + p) != nil))
                }
            }
            #expect((0 ..< 300).reduce(0) { $0 + matrix.degree(of: $1) } == cells.count)
            #expect((0 ..< 300).reduce(0) { $0 + matrix.size(ofHyperedgeAt: $1) } == cells.count)
            for v in stride(from: 0, to: 300, by: 37) {
                #expect(Array(matrix.incidentHyperedges(of: v)) == (0 ..< 300).filter { cells.contains(v * 300 + $0) })
            }
            #expect(matrix.transposed().transposed() == matrix)
        }.value
    }

    @Test("Components of a 512 × 512 matrix at density 1/8 equal an incidence-list copy's", .timeLimit(.minutes(1)))
    func componentsAtScale() async {
        await Task {
            var rng = SeededRandomNumberGenerator(seed: 13)
            let n = 512
            let columns = (0 ..< n).map { _ in (0 ..< n).filter { _ in Int.random(in: 0 ..< 8, using: &rng) == 0 } }
            let matrix = IncidenceMatrix(vertexCount: n, hyperedges: columns)
            let list = UndirectedIncidenceList<Int>(matrix)
            #expect(matrix.connectedComponents() == list.connectedComponents())
            #expect(matrix.degreeHistogram() == list.degreeHistogram() && matrix.rank == list.rank)
            #expect(matrix.dual() == list.dual())
        }.value
    }
}
