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

    @Test("incidenceGraph of a 1 024 × 1 024 matrix at density 1/8 reads exactly as an incidence-list copy's", .timeLimit(.minutes(1)))
    func incidenceGraphAtScale() async {
        await Task {
            // Every row and every edge of the view: before the view kept the hyperedges' first
            // incidence numbers, each read on a matrix cost O(m) and this walk O(p·m).
            var rng = SeededRandomNumberGenerator(seed: 17)
            let n = 1024
            let columns = (0 ..< n).map { _ in (0 ..< n).filter { _ in Int.random(in: 0 ..< 8, using: &rng) == 0 } }
            let matrix = IncidenceMatrix(vertexCount: n, hyperedges: columns)
            let list = UndirectedIncidenceList<Int>(matrix)
            let view = matrix.incidenceGraph, listView = list.incidenceGraph
            #expect(view.vertexCount == 2 * n && view.edgeCount == columns.map(\.count).reduce(0, +))
            #expect(view.edgeCount == listView.edgeCount)
            for x in view.vertices {
                #expect(Array(view.neighbors(of: x)) == Array(listView.neighbors(of: x)))
                #expect(Array(view.incidentEdges(of: x)) == Array(listView.incidentEdges(of: x)))
                #expect(view.degree(of: x) == listView.degree(of: x))
            }
            #expect(Array(view.edges) == Array(listView.edges))
            for q in stride(from: 0, to: view.edgeCount, by: 97) {
                #expect(view.endpointIndices(ofEdgeAt: q) == listView.endpointIndices(ofEdgeAt: q))
            }
        }.value
    }

    @Test("incidenceGraph of a 512 × 512 oriented matrix at density 1/16 per side reads exactly as an incidence-list copy's", .timeLimit(.minutes(1)))
    func directedIncidenceGraphAtScale() async {
        await Task {
            var rng = SeededRandomNumberGenerator(seed: 19)
            let n = 512
            let oriented = OrientedIncidenceMatrix(vertexCount: n, hyperedges: (0 ..< n).map { _ in
                (sources: (0 ..< n).filter { _ in Int.random(in: 0 ..< 16, using: &rng) == 0 },
                 targets: (0 ..< n).filter { _ in Int.random(in: 0 ..< 16, using: &rng) == 0 })
            })
            let list = IncidenceList<Int>(oriented)
            let view = oriented.incidenceGraph, listView = list.incidenceGraph
            #expect(view.edgeCount == listView.edgeCount)
            for x in view.vertices {
                #expect(Array(view.successors(of: x)) == Array(listView.successors(of: x)))
                #expect(Array(view.predecessors(of: x)) == Array(listView.predecessors(of: x)))
                #expect(Array(view.outEdges(of: x)) == Array(listView.outEdges(of: x)))
                #expect(Array(view.inEdges(of: x)) == Array(listView.inEdges(of: x)))
            }
            #expect(Array(view.edges) == Array(listView.edges))
            #expect(oriented.weaklyConnectedComponents() == list.weaklyConnectedComponents())
            #expect(oriented.stronglyConnectedComponents() == list.stronglyConnectedComponents())
            #expect(oriented.bConnectedVertices(from: 0) == list.bConnectedVertices(from: 0))
            #expect(oriented.isBHypergraph == list.isBHypergraph && oriented.targetSizeHistogram() == list.targetSizeHistogram())
        }.value
    }
}
