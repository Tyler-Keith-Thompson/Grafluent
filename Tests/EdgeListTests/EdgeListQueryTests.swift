// Graph queries, the transpose, conversions to the other representations, and values carried by
// position. Case IDs (EL-Qnn, EL-Xnn, EL-Knn, EL-Gnn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import EdgeListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("EdgeList queries")
struct EdgeListQueryTests {
    @Test("EL-Q01 / EL-Q03 contains(edge:) is true exactly for the listed edges, in their direction", .tags(.exhaustive), arguments: [DirectedFixture<Int>.boost24, .jgraphtSparseDirected, .petgraphCsr1, .directedPath3])
    func containsEdge(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let edges = Set(fixture.edges)
        for u in list.vertices {
            for v in list.vertices {
                let edge = DirectedEdge(from: u, to: v)
                #expect(list.contains(edge: edge) == edges.contains(edge), "\(edge)")
                #expect(list.contains(edge) == edges.contains(edge), "\(edge)")
            }
        }
    }

    @Test("EL-Q02 contains(edge:) with endpoints that are not vertices is false")
    func containsAbsentEndpoints() {
        let list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(!list.contains(edge: DirectedEdge(from: 9, to: 0)))
        #expect(!list.contains(edge: DirectedEdge(from: 0, to: 9)))
        #expect(!EdgeList<Int>().contains(edge: DirectedEdge(from: 0, to: 0)))
    }

    @Test("EL-Q04 / EL-Q11 edgeCount counts every copy, and edges lists them in order", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func edgeCount(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        #expect(list.edgeCount == fixture.edges.count)
        #expect(Array(list.edges) == fixture.edges)
    }

    @Test("EL-Q16 the bulk degrees and multiplicities agree with the per-vertex queries", .tags(.fixture), arguments: DirectedFixture<Int>.all + DirectedFixture<Int>.realWorld)
    func bulkDegrees(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let out = list.outDegrees
        let into = list.inDegrees
        #expect(Set(out.keys) == Set(list.vertices))
        #expect(Set(into.keys) == Set(list.vertices))
        for v in list.vertices {
            #expect(out[v] == fixture.edges.filter { $0.source == v }.count, "outDegree(of: \(v))")
            #expect(into[v] == fixture.edges.filter { $0.target == v }.count, "inDegree(of: \(v))")
        }
        let multiplicities = list.multiplicities
        #expect(Set(multiplicities.keys) == Set(fixture.edges))
        for (edge, count) in multiplicities {
            #expect(count == fixture.edges.filter { $0 == edge }.count, "\(edge)")
        }
        #expect(multiplicities.values.reduce(0, +) == fixture.edges.count)
    }

    @Test("EL-Q17 bulk degrees of real data and of the multigraph fixtures")
    func bulkDegreesExact() {
        let gap = EdgeList(DirectedFixture<Int>.gap4.edges)
        // Vertex 5 is in no edge, so it has no entry; 1, 6 and 11 are targets only.
        let expected: [Int?] = [153, 0, 6, 8, 1, nil, 0, 23, 37, 9, 1, 0, 1, 17]
        #expect((0 ..< 14).map { gap.outDegrees[$0] } == expected)
        #expect(gap.inDegrees[13] == 41)
        #expect(gap.multiplicities[DirectedEdge(from: 0, to: 0)] == 27)
        let sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(sparse.outDegrees == [0: 1, 1: 4, 2: 3, 3: 1, 4: 1, 5: 1, 6: 0, 7: 2])
        #expect(sparse.inDegrees == [0: 1, 1: 1, 2: 0, 3: 0, 4: 5, 5: 2, 6: 3, 7: 1])
        #expect(EdgeList<Int>().outDegrees == [:])
        #expect(EdgeList<Int>().multiplicities == [:])
    }

    @Test("EL-Q18 the positions of an edge's copies, by the standard library's indices(of:)")
    func positionsOfCopies() {
        let list = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(list.indices(of: DirectedEdge(from: 2, to: 4)) == RangeSet(5 ..< 8))
        #expect(list.indices(of: DirectedEdge(from: 4, to: 2)).isEmpty)
        let loops = EdgeList(DirectedFixture<Int>.petgraphCsr1.edges)
        #expect(loops.indices(where: \.isSelfLoop).ranges.flatMap { Array($0) } == [0, 2, 5])
        var removed = loops
        removed.removeSubranges(loops.indices(where: \.isSelfLoop))
        #expect(Array(removed) == loops.filter { !$0.isSelfLoop })
    }

    @Test("EL-Q05 successors and predecessors in edge order, with multiplicity")
    func neighbors() {
        let house = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(Array(house.successors(of: 3)) == [4, 2])
        #expect(Array(house.predecessors(of: 1)) == [4, 2])
        #expect(Array(house.successors(of: 0)) == [])
        let sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(Array(sparse.predecessors(of: 4)) == [1, 2, 2, 2, 3])
    }

    @Test("EL-Q06 / EL-Q07 neighbor counts equal degrees, and the degrees sum to the edge count", .tags(.fixture), arguments: DirectedFixture<Int>.all + DirectedFixture<Int>.realWorld)
    func degreeIdentities(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        var outSum = 0
        var inSum = 0
        var degreeSum = 0
        for v in list.vertices {
            let out = list.outDegree(of: v)
            let into = list.inDegree(of: v)
            #expect(list.successors(of: v).count == out, "successors(of: \(v))")
            #expect(list.predecessors(of: v).count == into, "predecessors(of: \(v))")
            #expect(out == fixture.edges.filter { $0.source == v }.count, "outDegree(of: \(v))")
            #expect(into == fixture.edges.filter { $0.target == v }.count, "inDegree(of: \(v))")
            #expect(list.degree(of: v) == out + into)
            outSum += out
            inSum += into
            degreeSum += list.degree(of: v)
        }
        #expect(outSum == list.count)
        #expect(inSum == list.count)
        #expect(degreeSum == 2 * list.count)
    }

    @Test("EL-Q08 a vertex that is not an endpoint has no neighbors and degree 0, without trapping")
    func absentVertex() {
        let list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(list.outDegree(of: 42) == 0)
        #expect(list.inDegree(of: 42) == 0)
        #expect(list.degree(of: 42) == 0)
        #expect(list.successors(of: 42).isEmpty)
        #expect(list.predecessors(of: 42).isEmpty)
        #expect(list.multiplicity(of: DirectedEdge(from: 42, to: 5)) == 0)
    }

    @Test("EL-Q09 / EL-G05 a shuffled hub of out-degree 20 000", .tags(.randomized))
    func hub() {
        var generator = SeededRandomNumberGenerator(seed: 5)
        var edges = (1 ... 20_000).map { DirectedEdge(from: 0, to: $0) }
        edges += (1 ... 100).map { DirectedEdge(from: $0, to: $0 + 1) }
        edges.shuffle(using: &generator)
        var list = EdgeList(edges)
        #expect(list.outDegree(of: 0) == 20_000)
        #expect(list.successors(of: 0).count == 20_000)
        #expect(Set(list.successors(of: 0)) == Set(1 ... 20_000))
        #expect(list.removeEdges(incidentTo: 0) == 20_000)
        #expect(list.count == 100)
    }

    @Test("EL-Q10 degrees of real data, repeats counted")
    func realDataDegrees() {
        let gap = EdgeList(DirectedFixture<Int>.gap4.edges)
        let out = [153, 0, 6, 8, 1, 0, 0, 23, 37, 9, 1, 0, 1, 17]
        let into = [27, 14, 14, 12, 23, 0, 5, 33, 23, 33, 9, 9, 13, 41]
        for v in 0 ..< 14 {
            #expect(gap.outDegree(of: v) == out[v], "outDegree(of: \(v))")
            #expect(gap.inDegree(of: v) == into[v], "inDegree(of: \(v))")
        }
        let graph500 = EdgeList(DirectedFixture<Int>.graph500Scale8.edges)
        #expect(graph500.outDegree(of: 82) == 871)
        #expect(graph500.outDegree(of: 0) == 2)
        #expect(graph500.inDegree(of: 0) == 14)
    }

    @Test("EL-Q12 / EL-Q13 transposed() flips every edge, keeps order, and swaps degrees", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func transposed(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let transposed = list.transposed()
        #expect(Array(transposed) == fixture.edges.map { DirectedEdge(from: $0.target, to: $0.source) })
        #expect(transposed.transposed() == list)
        for v in list.vertices {
            #expect(transposed.outDegree(of: v) == list.inDegree(of: v))
            #expect(transposed.inDegree(of: v) == list.outDegree(of: v))
        }
    }

    @Test("EL-Q19 transpose() in place matches transposed()", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func transposeInPlace(_ fixture: DirectedFixture<Int>) {
        var list = EdgeList(fixture.edges)
        let copy = list
        list.transpose()
        #expect(list == copy.transposed())
        #expect(Array(copy) == fixture.edges)
        list.transpose()
        #expect(list == copy)
    }

    @Test("EL-Q12 the transpose of the house graph")
    func transposedHouse() {
        let list = EdgeList(DirectedFixture<Int>.house.edges)
        #expect(Array(list.transposed()) == [
            DirectedEdge(from: 3, to: 5), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 1, to: 4), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1),
        ])
        let loops = EdgeList(DirectedFixture<Int>.petgraphCsr1.edges)
        for k in loops.indices where loops[k].isSelfLoop {
            #expect(loops.transposed()[k] == loops[k])
        }
    }

    @Test("EL-Q14 self-loop queries", .tags(.selfLoops))
    func selfLoopQueries() {
        let list = EdgeList(DirectedFixture<Int>.petgraphEdgesDirected.edges)
        #expect(list.contains(edge: DirectedEdge(from: 6, to: 6)))
        #expect(list.successors(of: 6).contains(6))
        #expect(list.predecessors(of: 6).contains(6))
        #expect(list.multiplicity(of: DirectedEdge(from: 6, to: 6)) == 1)
    }

    @Test("EL-Q15 / EL-G06 multiplicity counts copies; 100 000 copies of one edge")
    func multiplicity() {
        let edge = DirectedEdge(from: 3, to: 7)
        let list = EdgeList(repeating: edge, count: 100_000)
        #expect(list.multiplicity(of: edge) == 100_000)
        #expect(list.multiplicity(of: DirectedEdge(from: 7, to: 3)) == 0)
        #expect(list.vertices == [3, 7])
        #expect(AdjacencyList(edges: list).edgeCount == 1)
        let sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        for edge in Set(sparse) {
            #expect(sparse.multiplicity(of: edge) == sparse.filter { $0 == edge }.count)
        }
    }
}

@Suite("EdgeList conversions")
struct EdgeListConversionTests {
    @Test("EL-X01 / EL-M09 an adjacency list collapses repeats; the edge list keeps them")
    func toAdjacencyListCollapses() {
        let gap = EdgeList(DirectedFixture<Int>.gap4.edges)
        let gapGraph = AdjacencyList(edges: gap)
        #expect(gapGraph.edgeCount == 58)
        #expect(gapGraph.vertexCount == 13)
        #expect(gap.count == 256)
        let graph500 = AdjacencyList(edges: EdgeList(DirectedFixture<Int>.graph500Scale8.edges))
        #expect(graph500.edgeCount == 2171)
        #expect(graph500.vertexCount == 241)
    }

    @Test("EL-X02 the adjacency list forgets order and multiplicity", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func adjacencyListForgetsOrder(_ fixture: DirectedFixture<Int>) {
        var generator = SeededRandomNumberGenerator(seed: 2)
        let list = EdgeList(fixture.edges)
        let graph = AdjacencyList(edges: list)
        #expect(graph == AdjacencyList(edges: list.shuffled(using: &generator)))
        #expect(graph == AdjacencyList(edges: Array(Set(list))))
        #expect(graph.vertexCount == list.vertexCount)
    }

    @Test("EL-X03 / EL-X04 a round trip through an adjacency list, with the vertices passed for isolated ones", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func roundTripThroughAdjacencyList(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let list = EdgeList(graph.edges)
        #expect(list.count == graph.edgeCount)
        #expect(Set(list).count == list.count)
        #expect(AdjacencyList(vertices: graph.vertices, edges: list) == graph)
        let withoutIsolated = AdjacencyList(edges: list)
        #expect(withoutIsolated.vertexCount == list.vertexCount)
    }

    @Test("EL-X05 / EL-X08 a compressed sparse row graph from the list, with an explicit vertex count", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func toCompressedSparseRow(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: list)
        #expect(graph == CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
        #expect(graph.vertexCount == fixture.vertexCount)
    }

    @Test("EL-X06 compressed sparse row edge indices map list positions to edges, repeats sharing one")
    func compressedSparseRowEdgeIndices() {
        let list = EdgeList(DirectedFixture<Int>.pathWithChord.edges)
        var edgeIndices: [Int] = []
        _ = CompressedSparseRow(vertexCount: 6, edges: list, edgeIndices: &edgeIndices)
        #expect(edgeIndices == [0, 1, 3, 4, 5, 2, 2])
    }

    @Test("EL-X07 a round trip through compressed sparse row sorts and deduplicates")
    func roundTripThroughCompressedSparseRow() {
        let unsorted = EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges)
        #expect(Array(EdgeList(CompressedSparseRow(vertexCount: 6, edges: unsorted).edges)) == [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 5, to: 0), DirectedEdge(from: 5, to: 2),
        ])
        let gap = EdgeList(DirectedFixture<Int>.gap4.edges)
        let canonical = EdgeList(CompressedSparseRow(vertexCount: 14, edges: gap).edges)
        #expect(canonical.count == 58)
        #expect(Array(canonical) == Set(gap).sorted())
    }

    @Test("EL-X08 trailing isolated vertices survive only through the explicit count")
    func explicitCount() {
        let list = EdgeList(DirectedFixture<Int>.scipyConstructor2.edges)
        #expect(list.vertexCount == 2)
        #expect(CompressedSparseRow(vertexCount: 6, edges: list).vertexCount == 6)
    }

    @Test("EL-X09 / EL-X10 an adjacency matrix collapses repeats, and its edges are row-major")
    func adjacencyMatrix() {
        let sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(AdjacencyMatrix(vertexCount: 8, edges: sparse).edgeCount == 11)
        let example = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        #expect(Array(EdgeList(example.edges)) == [
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 5), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 2),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 5, to: 0),
        ])
    }

    @Test("EL-X14 String vertices through an adjacency list")
    func stringConversion() {
        let abcd = DirectedFixture<String>.networkXABCD
        let list = EdgeList(abcd.edges)
        #expect(AdjacencyList(edges: list).vertexCount == 4)
        #expect(AdjacencyList(vertices: abcd.vertices, edges: list).vertexCount == 7)
    }
}

@Suite("EdgeList values carried by position")
struct EdgeListEdgeValueTests {
    @Test("EL-K01 / EL-K02 a stable argsort of weights orders the positions, keeping each edge with its weight")
    func argsort() {
        // Boost.Graph example/kruskal-example.cpp.
        let list: EdgeList<Int> = [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 1),
        ]
        let weights = [1, 1, 2, 7, 3, 1, 1, 1]
        let order = list.indices.sorted { weights[$0] < weights[$1] }
        #expect(order == [0, 1, 5, 6, 7, 2, 4, 3])
        let sortedList = EdgeList(order.map { list[$0] })
        let sortedWeights = order.map { weights[$0] }
        #expect(Array(sortedList) == [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 1),
        ])
        #expect(sortedWeights == [1, 1, 1, 1, 1, 2, 3, 7])
    }

    @Test("EL-K03 sorting the list alone misaligns a separate weight array; sorting positions does not")
    func sortingAloneMisaligns() {
        let edges = [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0)]
        let weights = [7, 1, 4]
        let weightOf = Dictionary(uniqueKeysWithValues: zip(edges, weights))
        var sortedAlone = EdgeList(edges)
        sortedAlone.sort()
        #expect(sortedAlone.indices.map { weightOf[sortedAlone[$0]]! } == [1, 4, 7])
        #expect(sortedAlone.indices.map { weightOf[sortedAlone[$0]]! } != weights)
        let list = EdgeList(edges)
        let order = list.indices.sorted { list[$0] < list[$1] }
        #expect(order.map { list[$0] } == Array(sortedAlone))
        #expect(order.map { weights[$0] } == [1, 4, 7])
    }

    @Test("EL-K04 a removal mirrored in the weight array keeps every pair aligned")
    func mirroredRemoval() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        var weights = Array(10 ..< 17)
        let expected = Dictionary(uniqueKeysWithValues: zip(DirectedFixture<Int>.house.edges, weights))
        list.remove(at: 2)
        weights.remove(at: 2)
        list.remove(at: 0)
        weights.remove(at: 0)
        for (edge, weight) in zip(list, weights) {
            #expect(expected[edge] == weight, "\(edge)")
        }
    }
}

@Suite("EdgeList on real data")
struct EdgeListRealWorldTests {
    @Test("EL-G01 GAP 4.el in file order")
    func gap4() {
        let list = EdgeList(DirectedFixture<Int>.gap4.edges)
        #expect(list.count == 256)
        #expect(Array(list.prefix(3)) == [DirectedEdge(from: 0, to: 13), DirectedEdge(from: 0, to: 13), DirectedEdge(from: 0, to: 9)])
        #expect(list.last == DirectedEdge(from: 0, to: 9))
        #expect(Set(list).count == 58)
    }

    @Test("EL-G02 Graph500 scale 8 in file order")
    func graph500() {
        let list = EdgeList(DirectedFixture<Int>.graph500Scale8.edges)
        #expect(list.count == 4096)
        #expect(list.first == DirectedEdge(from: 17, to: 138))
        #expect(list.last == DirectedEdge(from: 82, to: 1))
        #expect(list.filter(\.isSelfLoop).count == 85)
        #expect(Set(list).count == 2171)
    }

    @Test("EL-G03 Ligra rMat is already sorted and repeat-free")
    func ligra() {
        let list = EdgeList(DirectedFixture<Int>.ligraRMat.edges)
        #expect(list.count == 708)
        #expect(Array(list) == list.sorted())
        #expect(Set(list).count == 708)
    }

    @Test("EL-G04 a million appends, then removing half, keeps count and order", .tags(.randomized))
    func large() {
        var list = EdgeList<Int>()
        for k in 0 ..< 1_000_000 {
            list.append(DirectedEdge(from: k, to: k &* 7 % 1000))
        }
        list.removeAll { $0.source % 2 == 1 }
        #expect(list.count == 500_000)
        #expect(list.first == DirectedEdge(from: 0, to: 0))
        #expect(list[1] == DirectedEdge(from: 2, to: 14))
        #expect(list.last == DirectedEdge(from: 999_998, to: 999_998 &* 7 % 1000))
    }
}
