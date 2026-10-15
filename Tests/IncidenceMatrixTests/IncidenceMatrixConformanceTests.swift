// The matrices are the hypergraph protocols' second conformers. On seeded random matrices, every
// `Hypergraphs` algorithm run on an `IncidenceMatrix` must equal the same algorithm on an
// `UndirectedIncidenceList<Int>` copy, and on an `OrientedIncidenceMatrix` the same on an
// `IncidenceList<Int>` copy; `transposed()` is the lists' `dual()` and `reversed` their reversal.
// Then the conversions between the four types and from graphs, Codable round trips, copy-on-write,
// the resets and capacity, and Sendable. See README.md.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import IncidenceMatrixModule
import Multigraphs
import Testing

@Suite("IncidenceMatrix conformances and conversions", .tags(.conformance))
struct IncidenceMatrixConformanceTests {
    @Test("Hypergraph algorithms on IncidenceMatrix equal the same on an UndirectedIncidenceList copy", arguments: 1 ... 8)
    func unorientedAgainstList(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = seed * 9, m = seed * 8
        var matrix = IncidenceMatrix(vertexCount: n)
        for _ in 0 ..< m {
            matrix.insert(hyperedge: (0 ..< Int.random(in: 0 ... 5, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) })
        }
        if seed.isMultiple(of: 2) { matrix.insert(hyperedge: matrix.members(ofHyperedgeAt: 0)) }
        let list = UndirectedIncidenceList<Int>(matrix)
        #expect(Array(list.vertices) == Array(0 ..< n) && list.hyperedges.map { Array($0) } == matrix.hyperedges.map { Array($0) })
        #expect(IncidenceMatrix(list) == matrix)
        for v in 0 ..< n {
            #expect(matrix.neighbors(of: v) == list.neighbors(of: v))
            #expect(Array(matrix.incidentHyperedges(of: v)) == Array(list.incidentHyperedges(of: v)) && matrix.degree(of: v) == list.degree(of: v))
        }
        for p in 0 ..< matrix.hyperedgeCount {
            #expect(matrix.contains(hyperedge: Array(matrix.members(ofHyperedgeAt: p)).reversed()))
        }
        #expect(matrix.contains(hyperedge: [] as [Int]) == list.contains(hyperedge: [] as [Int]))
        #expect(!matrix.contains(hyperedge: [n]) && !matrix.contains(n) && !matrix.contains(-1) && matrix.contains(n - 1))
        #expect(matrix.rank == list.rank && matrix.isUniform(size: 2) == list.isUniform(size: 2))
        #expect(matrix.degreeHistogram() == list.degreeHistogram() && matrix.hyperedgeSizeHistogram() == list.hyperedgeSizeHistogram())
        #expect(matrix.dual() == list.dual() && matrix.dual().hyperedges.map { Array($0) } == list.dual().hyperedges.map { Array($0) })
        #expect(matrix.connectedComponents() == list.connectedComponents() && matrix.isConnected == list.isConnected)
        for s in 1 ... 3 {
            #expect(matrix.lineGraph(s: s) == list.lineGraph(s: s))
            #expect(matrix.sConnectedComponents(s: s) == list.sConnectedComponents(s: s))
        }
        #expect(matrix.cliqueExpansion() == list.cliqueExpansion())
        #expect(Array(matrix.incidenceGraphView.edges) == Array(list.incidenceGraphView.edges))
        // transposed() is the dual.
        #expect(matrix.transposed() == IncidenceMatrix(matrix.dual()))
        #expect(UndirectedIncidenceList<Int>(matrix.transposed()) == list.dual())
    }

    @Test("DirectedHypergraph algorithms on OrientedIncidenceMatrix equal the same on an IncidenceList copy", arguments: 1 ... 8)
    func orientedAgainstList(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(100 + seed))
        let n = seed * 5 + 1
        var matrix = OrientedIncidenceMatrix(vertexCount: n)
        for _ in 0 ..< seed * 6 {
            matrix.insert(sources: (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) },
                          targets: (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) })
        }
        let list = IncidenceList<Int>(matrix)
        #expect(Array(list.vertices) == Array(0 ..< n))
        #expect(list.hyperedges.map { [Array($0.sources), Array($0.targets)] } == matrix.hyperedges.map { [Array($0.sources), Array($0.targets)] })
        #expect(OrientedIncidenceMatrix(list) == matrix)
        for v in 0 ..< n {
            #expect(matrix.bConnectedVertices(from: v) == list.bConnectedVertices(from: v))
            #expect(matrix.fConnectedVertices(to: v) == list.fConnectedVertices(to: v))
            #expect(Array(matrix.outHyperedges(of: v)) == Array(list.outHyperedges(of: v)))
            #expect(Array(matrix.inHyperedges(of: v)) == Array(list.inHyperedges(of: v)))
            #expect(matrix.degree(of: v) == list.degree(of: v))
            for p in 0 ..< matrix.hyperedgeCount {
                let entry = (matrix.targets(ofHyperedgeAt: p).contains(v) ? 1 : 0) - (matrix.sources(ofHyperedgeAt: p).contains(v) ? 1 : 0)
                #expect(matrix[vertex: v, hyperedge: p] == entry)
            }
        }
        #expect(matrix.stronglyConnectedComponents() == list.stronglyConnectedComponents())
        #expect(matrix.weaklyConnectedComponents() == list.weaklyConnectedComponents())
        #expect(matrix.isBHypergraph == list.isBHypergraph && matrix.isFHypergraph == list.isFHypergraph && matrix.isBFHypergraph == list.isBFHypergraph)
        #expect(matrix.cliqueExpansion() == list.cliqueExpansion())
        #expect(matrix.outDegreeHistogram() == list.outDegreeHistogram() && matrix.sourceSizeHistogram() == list.sourceSizeHistogram())
        #expect(Array(matrix.incidenceGraphView.edges) == Array(list.incidenceGraphView.edges))
        // transposed() is the dual, reversed the reversal, and the union matrix forgets the sides.
        #expect(matrix.transposed() == OrientedIncidenceMatrix(list.dual()))
        #expect(matrix.dual() == list.dual())
        #expect(IncidenceList<Int>(matrix.reversed) == list.reversed)
        #expect(IncidenceMatrix(matrix) == IncidenceMatrix(list))
    }

    @Test("Conversions from graphs: one column per edge in edges order, by vertex index")
    func fromGraphs() {
        let arcs = [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "b", to: "a")]
        let digraph = DirectedPseudograph<String>(vertices: ["a", "b", "c", "d"], edges: arcs)
        let oriented = OrientedIncidenceMatrix(digraph)
        #expect(oriented.vertexCount == 4 && oriented.hyperedgeCount == 4)
        #expect(oriented.hyperedges.map { [Array($0.sources), Array($0.targets)] } == digraph.edges.map { [[digraph.vertexIndex(of: $0.source)], [digraph.vertexIndex(of: $0.target)]] })
        #expect(IncidenceMatrix(digraph) == IncidenceMatrix(oriented))
        #expect(oriented == OrientedIncidenceMatrix(IncidenceList(digraph)))
        let simple = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)])
        #expect(OrientedIncidenceMatrix(simple) == OrientedIncidenceMatrix(vertexCount: 3, edges: simple.edges))
        let graph = Pseudograph<String>(vertices: ["x", "y", "z"], edges: [UndirectedEdge("y", "x"), UndirectedEdge("z", "z"), UndirectedEdge("x", "y")])
        let unoriented = IncidenceMatrix(graph)
        #expect(unoriented.hyperedges.map { Array($0) } == graph.edges.map { Set([graph.vertexIndex(of: $0.u), graph.vertexIndex(of: $0.v)]).sorted() })
        let fromUndirected = OrientedIncidenceMatrix(graph)
        #expect(fromUndirected.hyperedges.map { [Array($0.sources), Array($0.targets)] } == graph.edges.map { [[graph.vertexIndex(of: $0.u)], [graph.vertexIndex(of: $0.v)]] })
        #expect(IncidenceMatrix(fromUndirected) == unoriented)
        let undirectedList = UndirectedIncidenceList<String>(vertices: ["p"], hyperedges: [["q", "p"], []])
        #expect(IncidenceMatrix(undirectedList) == IncidenceMatrix(vertexCount: 2, hyperedges: [[0, 1], []]))
        let directedList = IncidenceList<String>(hyperedges: [(sources: ["q"], targets: ["p", "q"])])
        #expect(OrientedIncidenceMatrix(directedList) == OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [0, 1])]))
        #expect(IncidenceMatrix(directedList) == IncidenceMatrix(vertexCount: 2, hyperedges: [[0, 1]]))
    }

    @Test("Codable round trips keep shape, cells and column order", arguments: 1 ... 5)
    func codableRoundTrips(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(300 + seed))
        let n = seed * 13
        var matrix = IncidenceMatrix(vertexCount: n)
        var oriented = OrientedIncidenceMatrix(vertexCount: n)
        for _ in 0 ..< seed * 20 {
            matrix.insert(hyperedge: (0 ..< Int.random(in: 0 ... 4, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) })
            oriented.insert(sources: (0 ..< Int.random(in: 0 ... 2, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) },
                            targets: (0 ..< Int.random(in: 0 ... 2, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) })
        }
        matrix.appendVertex()
        oriented.appendVertex()
        #expect(try JSONDecoder().decode(IncidenceMatrix.self, from: JSONEncoder().encode(matrix)) == matrix)
        #expect(try JSONDecoder().decode(OrientedIncidenceMatrix.self, from: JSONEncoder().encode(oriented)) == oriented)
        #expect(try JSONDecoder().decode(IncidenceMatrix.self, from: JSONEncoder().encode(IncidenceMatrix())) == IncidenceMatrix())
    }

    @Test("IncidenceMatrix decoding rejects a negative count, a member out of range, a column not ascending, and storage over the limit")
    func unorientedDecodingRejects() throws {
        func decodes(_ json: String, limit: Int? = nil) -> Bool {
            let decoder = JSONDecoder()
            if let limit { decoder.userInfo[IncidenceMatrix.maximumDecodedWordCountKey] = limit }
            do {
                _ = try decoder.decode(IncidenceMatrix.self, from: Data(json.utf8))
                return true
            } catch DecodingError.dataCorrupted {
                return false
            } catch {
                Issue.record("unexpected error \(error)")
                return false
            }
        }
        #expect(decodes(#"{"vertexCount":3,"hyperedges":[[0,2],[],[1]]}"#))
        #expect(!decodes(#"{"vertexCount":-1,"hyperedges":[]}"#))
        #expect(!decodes(#"{"vertexCount":3,"hyperedges":[[0,3]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"hyperedges":[[-1]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"hyperedges":[[2,1]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"hyperedges":[[1,1]]}"#))
        // 43 bytes naming 2²⁸ vertices: 2²⁸ row words, 2²² column words, n + m counts, 4.3 GB.
        #expect(!decodes(#"{"vertexCount":268435456,"hyperedges":[[]]}"#))
        // No columns, but n counts and n empty rows still cost memory: 2⁴⁰ is over the limit.
        #expect(!decodes(#"{"vertexCount":1099511627776,"hyperedges":[]}"#))
        #expect(!decodes(#"{"vertexCount":9223372036854775807,"hyperedges":[[],[]]}"#))
        // The default limit is 2²⁴ words. n = 2²⁴ − 1 with m = 0 is n − 1 words below it plus n.
        #expect(IncidenceMatrix.defaultMaximumDecodedWordCount == 1 << 24)
        #expect(decodes(#"{"vertexCount":1000,"hyperedges":[]}"#))
        // The userInfo key: n·w(m) + m·w(n) + n + m. 3 × 2 is 3·1 + 2·1 + 3 + 2 = 10 words.
        #expect(decodes(#"{"vertexCount":3,"hyperedges":[[0],[1]]}"#, limit: 10))
        #expect(!decodes(#"{"vertexCount":3,"hyperedges":[[0],[1]]}"#, limit: 9))
        // 64 × 64: 64 + 64 + 64 + 64 = 256 words of 64 bits; 128 + 128 + 64 + 64 = 384 of 32 bits.
        let square = "{\"vertexCount\":64,\"hyperedges\":[" + Array(repeating: "[]", count: 64).joined(separator: ",") + "]}"
        #if _pointerBitWidth(_64)
        let words = 256
        #else
        let words = 384
        #endif
        #expect(decodes(square, limit: words) && !decodes(square, limit: words - 1))
        #expect(!decodes(#"{"vertexCount":0,"hyperedges":[]}"#, limit: -1))
    }

    @Test("OrientedIncidenceMatrix decoding rejects the same, two planes against the limit, and sides of different lengths")
    func orientedDecodingRejects() throws {
        func decodes(_ json: String, limit: Int? = nil) -> Bool {
            let decoder = JSONDecoder()
            if let limit { decoder.userInfo[IncidenceMatrix.maximumDecodedWordCountKey] = limit }
            do {
                _ = try decoder.decode(OrientedIncidenceMatrix.self, from: Data(json.utf8))
                return true
            } catch DecodingError.dataCorrupted {
                return false
            } catch {
                Issue.record("unexpected error \(error)")
                return false
            }
        }
        #expect(decodes(#"{"vertexCount":3,"sources":[[0],[]],"targets":[[1,2],[0]]}"#))
        #expect(!decodes(#"{"vertexCount":-2,"sources":[],"targets":[]}"#))
        #expect(!decodes(#"{"vertexCount":3,"sources":[[3]],"targets":[[]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"sources":[[]],"targets":[[0,5]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"sources":[[1,0]],"targets":[[]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"sources":[[]],"targets":[[2,2]]}"#))
        #expect(!decodes(#"{"vertexCount":3,"sources":[[0]],"targets":[]}"#))
        #expect(!decodes(#"{"vertexCount":3,"sources":[],"targets":[[0]]}"#))
        #expect(!decodes(#"{"vertexCount":268435456,"sources":[[]],"targets":[[]]}"#))
        #expect(!decodes(#"{"vertexCount":1099511627776,"sources":[],"targets":[]}"#))
        // Two planes of 3 × 2: 2 · 10 = 20 words.
        #expect(decodes(#"{"vertexCount":3,"sources":[[0],[]],"targets":[[],[1]]}"#, limit: 20))
        #expect(!decodes(#"{"vertexCount":3,"sources":[[0],[]],"targets":[[],[1]]}"#, limit: 19))
    }

    @Test("IncidenceMatrix(_:) of an oriented matrix is the cellwise union of its planes, counts included", arguments: 1 ... 4)
    func unionOfPlanes(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(400 + seed))
        let n = seed * 37, m = seed * 29
        var oriented = OrientedIncidenceMatrix(vertexCount: n)
        var cells = Set<[Int]>()
        for p in 0 ..< m {
            let sources = (0 ..< Int.random(in: 0 ... 6, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) }
            let targets = (0 ..< Int.random(in: 0 ... 6, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) }
            oriented.insert(sources: sources, targets: targets)
            for v in sources + targets { cells.insert([v, p]) }
        }
        // Grow past a word boundary so the planes' strides differ from their used widths.
        oriented.appendVertex()
        let union = IncidenceMatrix(oriented)
        #expect(union.vertexCount == n + 1 && union.hyperedgeCount == m)
        #expect(union.incidenceGraphView.edgeCount == cells.count)
        for v in 0 ... n {
            #expect(Array(union.incidentHyperedges(of: v)) == (0 ..< m).filter { cells.contains([v, $0]) })
            #expect(union.degree(of: v) == (0 ..< m).filter { cells.contains([v, $0]) }.count)
        }
        for p in 0 ..< m {
            #expect(Array(union.members(ofHyperedgeAt: p)) == (0 ... n).filter { cells.contains([$0, p]) })
            #expect(union.size(ofHyperedgeAt: p) == (0 ... n).filter { cells.contains([$0, p]) }.count)
        }
        var expected = IncidenceMatrix(vertexCount: n + 1)
        for p in 0 ..< m { expected.insert(hyperedge: (0 ... n).filter { cells.contains([$0, p]) }) }
        #expect(union == expected)
    }

    @Test("Copy-on-write: editing a copy leaves the original alone", .tags(.copyOnWrite))
    func copyOnWrite() {
        let original = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 1]])
        var copy = original
        copy.insert(2, intoHyperedgeAt: 0)
        copy.appendVertex()
        copy.insert(hyperedge: [3])
        #expect(Array(original.members(ofHyperedgeAt: 0)) == [0, 1] && original.vertexCount == 3 && original.hyperedgeCount == 1)
        #expect(Array(original.incidentHyperedges(of: 2)) == [] && original.degree(of: 2) == 0)
        let transposed = original.transposed()
        var edited = transposed
        edited.remove(0, fromHyperedgeAt: 0)
        #expect(transposed == original.transposed() && edited != transposed)
        let oriented = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        var orientedCopy = oriented.reversed
        orientedCopy.insert(0, intoTargetsOfHyperedgeAt: 0)
        #expect(oriented[vertex: 0, hyperedge: 0] == -1 && Array(oriented.inHyperedges(of: 0)) == [])
        #expect(orientedCopy[vertex: 0, hyperedge: 0] == 1)
    }

    @Test("removeAll and reserveCapacity: the empty matrix, and no change to the cells")
    func resetsAndCapacity() {
        for keep in [false, true] {
            var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 1], [2]])
            matrix.reserveCapacity(vertexCount: 200, hyperedgeCount: 300)
            #expect(matrix == IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 1], [2]]))
            matrix.removeAll(keepingCapacity: keep)
            #expect(matrix == IncidenceMatrix() && matrix.vertexCount == 0 && matrix.hyperedgeCount == 0)
            #expect(matrix.appendVertex() == 0 && matrix.insert(hyperedge: [0]) == 0)
            var oriented = OrientedIncidenceMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 2)])
            oriented.reserveCapacity(vertexCount: 100, hyperedgeCount: 100)
            #expect(oriented == OrientedIncidenceMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 2)]))
            oriented.removeAll(keepingCapacity: keep)
            #expect(oriented == OrientedIncidenceMatrix() && oriented.vertexIndexBound == 0 && oriented.hyperedgeIndexBound == 0)
        }
        #expect(IncidenceMatrix(vertexCount: 0) == IncidenceMatrix() && OrientedIncidenceMatrix(vertexCount: 0) == OrientedIncidenceMatrix())
    }

    @Test("Hashable agrees with ==, and description is not empty", .tags(.conformance))
    func hashableAndDescription() {
        let a = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 1], [], [2]])
        let b = IncidenceMatrix(vertexCount: 3, hyperedges: [[1, 0], [], [2]])
        #expect(a == b && a.hashValue == b.hashValue && Set([a, b, a.transposed()]).count == 2)
        let o = OrientedIncidenceMatrix(vertexCount: 2, hyperedges: [(sources: [0], targets: [0, 1])])
        #expect(Set([o, o.reversed, o.reversed.reversed]).count == 2)
        #expect(!a.description.isEmpty && !o.description.isEmpty)
    }

    @Test("Sendable", .tags(.conformance))
    func sendable() async {
        let matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0, 1]])
        let oriented = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        let counts = await Task.detached { (matrix.hyperedgeCount, oriented[vertex: 1, hyperedge: 0]) }.value
        #expect(counts == (1, 1))
    }
}
