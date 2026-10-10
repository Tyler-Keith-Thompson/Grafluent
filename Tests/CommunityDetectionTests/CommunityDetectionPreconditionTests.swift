// Preconditions, as exit tests. The catalog's trap rows (CD-155 – CD-172): a collection that is not
// a partition of the vertices (a vertex missing, listed twice, or not a vertex), a resolution that is
// negative or NaN, a threshold that is negative or NaN, and weights that are negative, NaN or
// infinite, on every entry point that takes them; then api.md's other preconditions (see the second
// half of this file). Each exit test builds its inputs inside the closure.
// Case IDs (CD-nnn) refer to the catalog; see README.md.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Community detection preconditions", .tags(.precondition))
struct CommunityDetectionPreconditionTests {
    @Test("CD-155 U(P(0,1,2)).modularity(of: [[0, 1]]) traps: Vertex 2 missing (NetworkX `NotAPartition`)")
    func modularity155() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1]]
            _ = graph.modularity(of: communities)
        }
    }

    @Test("CD-156 U(P(0,1,2)).modularity(of: [[0, 1], [1, 2]]) traps: Vertex 1 twice")
    func modularity156() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [1, 2]]
            _ = graph.modularity(of: communities)
        }
    }

    @Test("CD-157 U(P(0,1,2)).modularity(of: [[0, 1], [2, 7]]) traps: 7 is not a vertex")
    func modularity157() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2, 7]]
            _ = graph.modularity(of: communities)
        }
    }

    @Test("CD-158 U(P(0,1,2)).modularity(of: [[0, 1], [2]], resolution: -1) traps")
    func modularity158() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            _ = graph.modularity(of: communities, resolution: -1)
        }
    }

    @Test("CD-159 U(P(0,1,2)).modularity(of: [[0, 1], [2]], resolution: nan) traps")
    func modularity159() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            _ = graph.modularity(of: communities, resolution: .nan)
        }
    }

    @Test("CD-160 U(P(0,1,2)).modularity(of: [[0, 1], [2]], weight: [1, -1]) traps")
    func modularity160() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            let w: [Double] = [1, -1]
            _ = graph.modularity(of: communities, weight: { w[$0] })
        }
    }

    @Test("CD-161 U(P(0,1,2)).modularity(of: [[0, 1], [2]], weight: [1, nan]) traps")
    func modularity161() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            let w: [Double] = [1, .nan]
            _ = graph.modularity(of: communities, weight: { w[$0] })
        }
    }

    @Test("CD-162 U(P(0,1,2)).modularity(of: [[0, 1], [2]], weight: [1, inf]) traps")
    func modularity162() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            let w: [Double] = [1, .infinity]
            _ = graph.modularity(of: communities, weight: { w[$0] })
        }
    }

    @Test("CD-163 U(P(0,1,2)).partitionQuality(of: [[0, 1]]).coverage traps")
    func quality163() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1]]
            _ = graph.partitionQuality(of: communities)
        }
    }

    @Test("CD-164 U(P(0,1,2)).louvainCommunities(resolution: -0.5) traps")
    func louvain164() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.louvainCommunities(resolution: -0.5)
        }
    }

    @Test("CD-165 U(P(0,1,2)).louvainCommunities(threshold: -1) traps")
    func louvain165() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.louvainCommunities(threshold: -1)
        }
    }

    @Test("CD-166 U(P(0,1,2)).louvainCommunities(threshold: nan) traps")
    func louvain166() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.louvainCommunities(threshold: .nan)
        }
    }

    @Test("CD-167 U(P(0,1,2)).louvainCommunities(weight: [1, -2]) traps")
    func louvain167() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, -2]
            _ = graph.louvainCommunities(weight: { w[$0] })
        }
    }

    @Test("CD-168 D(P(0,1,2)).louvainCommunities(weight: [1, nan]) traps")
    func louvain168() async {
        await #expect(processExitsWith: .failure) {
            // D: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let w: [Double] = [1, .nan]
            _ = graph.louvainCommunities(weight: { w[$0] })
        }
    }

    @Test("CD-169 U(P(0,1,2)).greedyModularityCommunities(resolution: -1) traps")
    func greedy169() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.greedyModularityCommunities(resolution: -1)
        }
    }

    @Test("CD-170 U(P(0,1,2)).greedyModularityCommunities(weight: [1, -1]) traps")
    func greedy170() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, -1]
            _ = graph.greedyModularityCommunities(weight: { w[$0] })
        }
    }

    @Test("CD-171 U(P(0,1,2)).labelPropagationCommunities(weight: [1, -1]) traps")
    func labelPropagation171() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, -1]
            _ = graph.labelPropagationCommunities(weight: { w[$0] })
        }
    }

    @Test("CD-172 U(P(0,1,2)).asynchronousLabelPropagationCommunities(weight: [inf, 1]) traps")
    func asynchronousLabelPropagation172() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [.infinity, 1]
            _ = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })
        }
    }

    // MARK: - api.md's other preconditions

    @Test("Partition.community(of:) traps on a vertex that is not in the graph")
    func communityOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.louvainCommunities()
            _ = result.community(of: 7)
        }
    }

    @Test("Partition.community(of:) traps on a non-vertex of a directed graph")
    func communityOfNonVertexDirected() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.greedyModularityCommunities()
            _ = result.community(of: -1)
        }
    }

    @Test("Partition.community(ofIndex:) traps on -1")
    func communityOfIndexNegative() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.labelPropagationCommunities()
            _ = result.community(ofIndex: -1)
        }
    }

    @Test("Partition.community(ofIndex:) traps on the vertex count")
    func communityOfIndexPastEnd() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.asynchronousLabelPropagationCommunities()
            _ = result.community(ofIndex: 3)
        }
    }

    @Test("Partition.community(ofIndex:) traps on an empty graph's result")
    func communityOfIndexEmpty() async {
        await #expect(processExitsWith: .failure) {
            // U: []
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            let result = graph.greedyModularityCommunities()
            _ = result.community(ofIndex: 0)
        }
    }

    @Test("partitionQuality(of:) traps when a vertex is listed twice")
    func qualityVertexTwice() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2, 0]]
            _ = graph.partitionQuality(of: communities)
        }
    }

    @Test("partitionQuality(of:) traps on a non-vertex")
    func qualityNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1, 2, 3]]
            _ = graph.partitionQuality(of: communities)
        }
    }

    @Test("Directed modularity(of:) traps when a vertex is missing")
    func directedModularityMissing() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let communities: [[Int]] = [[0], [2]]
            _ = graph.modularity(of: communities)
        }
    }

    @Test("Directed partitionQuality(of:) traps when a vertex is listed twice")
    func directedQualityTwice() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let communities: [[Int]] = [[0, 1], [1], [2]]
            _ = graph.partitionQuality(of: communities)
        }
    }

    @Test("modularity(of:) on the empty graph traps when the collection lists a vertex")
    func modularityEmptyGraphNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: []
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            let communities: [[Int]] = [[0]]
            _ = graph.modularity(of: communities)
        }
    }

    @Test("modularity(of:resolution:) traps on an infinite resolution")
    func modularityInfiniteResolution() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            _ = graph.modularity(of: communities, resolution: .infinity)
        }
    }

    @Test("Directed modularity(of:weight:) traps on a weight of -infinity")
    func directedModularityNegativeInfinity() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            let w: [Double] = [1, -.infinity]
            _ = graph.modularity(of: communities, weight: { w[$0] })
        }
    }

    @Test("Directed modularity(of:resolution:) traps on a negative resolution")
    func directedModularityNegativeResolution() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            _ = graph.modularity(of: communities, resolution: -0.25)
        }
    }

    @Test("louvainCommunities(resolution:) traps on NaN")
    func louvainNaNResolution() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.louvainCommunities(resolution: .nan)
        }
    }

    @Test("louvainCommunities(resolution:) traps on infinity")
    func louvainInfiniteResolution() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.louvainCommunities(resolution: .infinity)
        }
    }

    @Test("louvainCommunities(threshold:) traps on infinity")
    func louvainInfiniteThreshold() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.louvainCommunities(threshold: .infinity)
        }
    }

    @Test("louvainCommunities(resolution:using:) traps on a negative resolution")
    func louvainUsingNegativeResolution() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.louvainCommunities(resolution: -1, using: &generator)
        }
    }

    @Test("louvainCommunities(threshold:using:) traps on NaN")
    func louvainUsingNaNThreshold() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.louvainCommunities(threshold: .nan, using: &generator)
        }
    }

    @Test("louvainCommunities(weight:using:) traps on a NaN weight")
    func louvainUsingNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [.nan, 1]
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.louvainCommunities(weight: { w[$0] }, using: &generator)
        }
    }

    @Test("Directed louvainCommunities(resolution:) traps on a negative resolution")
    func directedLouvainNegativeResolution() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            _ = graph.louvainCommunities(resolution: -1)
        }
    }

    @Test("Directed louvainCommunities(threshold:) traps on a negative threshold")
    func directedLouvainNegativeThreshold() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            _ = graph.louvainCommunities(threshold: -1e-9)
        }
    }

    @Test("Directed louvainCommunities(weight:using:) traps on a negative weight")
    func directedLouvainUsingNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let w: [Double] = [1, -1]
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.louvainCommunities(weight: { w[$0] }, using: &generator)
        }
    }

    @Test("greedyModularityCommunities(resolution:) traps on NaN")
    func greedyNaNResolution() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.greedyModularityCommunities(resolution: .nan)
        }
    }

    @Test("greedyModularityCommunities(weight:) traps on an infinite weight")
    func greedyInfiniteWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, .infinity]
            _ = graph.greedyModularityCommunities(weight: { w[$0] })
        }
    }

    @Test("Directed greedyModularityCommunities(weight:) traps on a negative weight")
    func directedGreedyNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let w: [Double] = [-2, 1]
            _ = graph.greedyModularityCommunities(weight: { w[$0] })
        }
    }

    @Test("Directed greedyModularityCommunities(resolution:) traps on infinity")
    func directedGreedyInfiniteResolution() async {
        await #expect(processExitsWith: .failure) {
            // D: 0>1, 1>2
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            _ = graph.greedyModularityCommunities(resolution: .infinity)
        }
    }

    @Test("labelPropagationCommunities(weight:) traps on a NaN weight")
    func labelPropagationNaNWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, .nan]
            _ = graph.labelPropagationCommunities(weight: { w[$0] })
        }
    }

    @Test("asynchronousLabelPropagationCommunities(weight:) traps on a negative weight")
    func asynchronousNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [-0.5, 1]
            _ = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })
        }
    }

    @Test("asynchronousLabelPropagationCommunities(weight:using:) traps on a weight of -infinity")
    func asynchronousUsingNegativeInfinity() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = [1, -.infinity]
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] }, using: &generator)
        }
    }

    @Test("A Float weight closure is checked too: modularity(of:weight:) traps on Float.nan")
    func floatWeightNaN() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [2]]
            let w: [Float] = [1, .nan]
            _ = graph.modularity(of: communities, weight: { w[$0] })
        }
    }
}
