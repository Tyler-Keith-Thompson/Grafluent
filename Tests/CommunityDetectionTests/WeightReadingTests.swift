// How the weight closure is read (api.md: weights are read once per edge, in position order, and
// checked there): every weighted entry point, on a pseudograph with a self-loop and parallel edges,
// on `graph.directed` (each arc once, in its view's position order), on a directed multigraph, and on
// `UndirectedAdjacencyList`, `CompressedSparseRow` and `AdjacencyMatrix` positions; nothing is read
// on an edgeless graph. Weights of -0.0 are ≥ 0 and accepted, and a `Float` closure gives the
// `Double` closure's values. Case IDs (CD-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CommunityDetection
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Weight reading")
struct CommunityWeightReadingTests {
    @Test("CD-140, CD-127 every weighted entry point on Graph reads each edge once, in position order (a self-loop and parallel edges included)")
    func undirectedOrder() {
        // U: K(0..2), K(3..5), 2-3, 2-3, 0-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (2, 3), (0, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let positions = Array(0 ..< pairs.count)
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        var reads: [Int] = []
        _ = graph.modularity(of: communities, weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "modularity")
        reads = []
        _ = graph.modularity(of: communities, weight: { reads.append($0); return 1.0 }, resolution: 0.5)
        #expect(reads == positions, "modularity, resolution 0.5")
        reads = []
        _ = graph.louvainCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "louvainCommunities")
        reads = []
        var generator = SeededRandomNumberGenerator(seed: 1)
        _ = graph.louvainCommunities(weight: { reads.append($0); return 1.0 }, using: &generator)
        #expect(reads == positions, "louvainCommunities(using:)")
        reads = []
        _ = graph.greedyModularityCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "greedyModularityCommunities")
        reads = []
        _ = graph.labelPropagationCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "labelPropagationCommunities")
        reads = []
        _ = graph.asynchronousLabelPropagationCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "asynchronousLabelPropagationCommunities")
        reads = []
        _ = graph.asynchronousLabelPropagationCommunities(weight: { reads.append($0); return 1.0 }, using: &generator)
        #expect(reads == positions, "asynchronousLabelPropagationCommunities(using:)")
    }

    @Test("CD-083 on graph.directed: each arc once, in the view's position order")
    func directedViewOrder() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = graph.directed
        let positions = Array(arcs.edges.indices)
        #expect(positions.count == 14)
        var reads: [DirectedView<ReferencePseudograph<Int>>.Edges.Index] = []
        _ = arcs.modularity(of: [[0, 1, 2], [3, 4, 5]], weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "modularity")
        reads = []
        _ = arcs.louvainCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "louvainCommunities")
        reads = []
        _ = arcs.greedyModularityCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "greedyModularityCommunities")
    }

    @Test("CD-108, CD-131 every weighted entry point on DirectedGraph reads each arc once, in position order (parallel arcs and a loop included)")
    func directedOrder() {
        // D: C(0,1,2), C(3,4,5), 2>3, 2>3, 4>4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3), (2, 3), (4, 4)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let positions = Array(0 ..< pairs.count)
        var reads: [Int] = []
        _ = graph.modularity(of: [[0, 1, 2], [3, 4, 5]], weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "modularity")
        reads = []
        _ = graph.louvainCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "louvainCommunities")
        reads = []
        var generator = SeededRandomNumberGenerator(seed: 2)
        _ = graph.louvainCommunities(weight: { reads.append($0); return 1.0 }, using: &generator)
        #expect(reads == positions, "louvainCommunities(using:)")
        reads = []
        _ = graph.greedyModularityCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == positions, "greedyModularityCommunities")
    }

    @Test("CD-083, CD-108 on UndirectedAdjacencyList, CompressedSparseRow and AdjacencyMatrix: their own positions, once each, in order")
    func representations() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let list = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var reads: [Int] = []
        let louvain = list.louvainCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == Array(list.edges.indices))
        #expect(louvain.map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        reads = []
        _ = list.labelPropagationCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == Array(list.edges.indices))
        // D: C(0,1,2), C(3,4,5), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let csr = CompressedSparseRow(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        reads = []
        let greedy = csr.greedyModularityCommunities(weight: { reads.append($0); return 1.0 })
        #expect(reads == Array(csr.edges.indices))
        #expect(greedy.map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        var matrixReads: [AdjacencyMatrix.Edges.Index] = []
        let q = matrix.modularity(of: [[0, 1, 2], [3, 4, 5]], weight: { matrixReads.append($0); return 1.0 })
        #expect(matrixReads == Array(matrix.edges.indices))
        #expect(abs(q - 0.36734693877551017) <= 1e-12)
        matrixReads = []
        _ = matrix.louvainCommunities(weight: { matrixReads.append($0); return 1.0 })
        #expect(matrixReads == Array(matrix.edges.indices))
    }

    @Test("CD-017 – CD-020 an edgeless graph reads nothing")
    func edgeless() {
        // U: [0..3]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: [])
        var reads = 0
        let singletons: [[Int]] = [[0], [1], [2], [3]]
        #expect(abs(graph.modularity(of: singletons, weight: { _ in reads += 1; return 1.0 })) <= 1e-12)
        #expect(graph.louvainCommunities(weight: { _ in reads += 1; return 1.0 }).map { Array($0) } == singletons)
        #expect(graph.greedyModularityCommunities(weight: { _ in reads += 1; return 1.0 }).map { Array($0) } == singletons)
        #expect(graph.labelPropagationCommunities(weight: { _ in reads += 1; return 1.0 }).map { Array($0) } == singletons)
        #expect(graph.asynchronousLabelPropagationCommunities(weight: { _ in reads += 1; return 1.0 }).map { Array($0) } == singletons)
        #expect(reads == 0)
    }

    @Test("CD-049, CD-100 a weight of -0.0 is ≥ 0: accepted, and the same as 0")
    func negativeZero() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 1, 1, 1, 1, 1, -0.0]
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        // CD-049: a zero-weight bridge, ½.
        #expect(abs(graph.modularity(of: communities, weight: { w[$0] }) - 0.5) <= 1e-12)
        #expect(graph.louvainCommunities(weight: { w[$0] }).map { Array($0) } == communities)
        #expect(graph.greedyModularityCommunities(weight: { w[$0] }).map { Array($0) } == communities)
        #expect(graph.labelPropagationCommunities(weight: { w[$0] }).map { Array($0) } == communities)
        #expect(graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }).map { Array($0) } == communities)
    }

    @Test("CD-047, CD-100 a Float weight closure gives the Double closure's values")
    func floatWeights() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let heavy: [Float] = [1, 1, 1, 1, 1, 1, 5]
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        // CD-047: 0.0454545454545…
        #expect(abs(graph.modularity(of: communities, weight: { heavy[$0] }) - 0.045454545454545414) <= 1e-12)
        // CD-100: a bridge of weight 10.
        let bridge: [Float] = [1, 1, 1, 1, 1, 1, 10]
        #expect(graph.louvainCommunities(weight: { bridge[$0] }).map { Array($0) } == [[0, 1], [2, 3], [4, 5]])
    }
}
