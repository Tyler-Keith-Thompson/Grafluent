// Conformance and representation-independence: `Partition` is a `RandomAccessCollection` of vertex
// slices in canonical order (indices 0..<count, slices that keep their flat indices, as
// `Components`), `Equatable` by its communities whatever algorithm or graph made them, printed as
// a list of lists, and `Sendable` when its graph and vertices are (computed in a `Task` and read
// outside it); `PartitionQuality` is `Hashable` and `Sendable`. A result holds a copy of the graph
// (mutating the original afterwards changes nothing it answers) and has `DirectedView<Self>` as its
// graph for an undirected graph. Every entry point works from generic code over `some Graph` and
// `some DirectedGraph`; `modularity(of:)` and `partitionQuality(of:)` take any collection of vertex
// collections (sets, `Components`, another algorithm's `Partition`). Conformers private to this file
// without vertex or edge indices (numbering through `vertices`, here not value order, and
// `community(ofIndex:)` by position in `vertices`) and `Collider` vertices whose hashes all collide
// give the catalog's values. The `using:` overloads draw from the generator, and a seeded generator
// repeats its result. Literals are the catalog rows named in each test, at the full precision of
// ref.py's model. Case IDs (CD-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CommunityDetection
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import Testing

/// An undirected pseudograph with no vertex or edge indices, rows in position order (a self-loop
/// twice), so the algorithms number vertices by position in `vertices`.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// A directed multigraph with no vertex or edge indices, out-edges in position order.
private struct PlainDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// A seeded generator that counts the words drawn from it.
private struct CountingGenerator: RandomNumberGenerator {
    var base: SeededRandomNumberGenerator
    var draws = 0
    init(seed: UInt) { base = SeededRandomNumberGenerator(seed: seed) }
    mutating func next() -> UInt64 {
        draws += 1
        return base.next()
    }
}

@Suite("Community detection conformance", .tags(.conformance))
struct CommunityDetectionConformanceTests {
    @Test("CD-083, CD-108, CD-070 Partition and PartitionQuality are Sendable: computed in a Task and read outside it")
    func sendable() async {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let louvain = await Task { graph.louvainCommunities() }.value
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let sent = requireSendable(louvain)
        #expect(sent.map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        #expect(sent.community(of: 4) == 1)
        let quality = await Task { graph.partitionQuality(of: [[0, 1, 2], [3, 4, 5]]) }.value
        #expect(abs(requireSendable(quality).performance - 0.9333333333333333) <= 1e-12)
        // D: C(0,1,2), C(3,4,5), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let digraph = AdjacencyList(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let directed = await Task { digraph.louvainCommunities() }.value
        #expect(requireSendable(directed).map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
    }

    @Test("CD-083, CD-115 the result holds a copy of the graph: mutating the graph afterwards changes nothing it answers")
    func valueSemantics() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let louvain: Partition<DirectedView<UndirectedAdjacencyList<Int>>> = graph.louvainCommunities()
        let greedy = graph.greedyModularityCommunities()
        _ = graph.insert(edge: UndirectedEdge(0, 5))
        _ = graph.remove(1)
        _ = graph.insert(9)
        for result in [louvain, greedy] {
            #expect(result.map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
            for v in 0 ..< 6 {
                #expect(result.community(of: v) == (v < 3 ? 0 : 1), "vertex \(v)")
            }
        }
    }

    @Test("The result types: Partition<DirectedView<Self>> on Graph, Partition<Self> on DirectedGraph, PartitionQuality")
    func resultTypes() {
        // U: 0-1
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let louvain: Partition<DirectedView<ReferencePseudograph<Int>>> = graph.louvainCommunities()
        let greedy: Partition<DirectedView<ReferencePseudograph<Int>>> = graph.greedyModularityCommunities()
        let semi: Partition<DirectedView<ReferencePseudograph<Int>>> = graph.labelPropagationCommunities()
        let asynchronous: Partition<DirectedView<ReferencePseudograph<Int>>> = graph.asynchronousLabelPropagationCommunities()
        #expect([louvain, greedy, semi, asynchronous].allSatisfy { $0.map { Array($0) } == [[0, 1]] })
        // D: 0>1
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let directed: Partition<ReferenceDirectedMultigraph<Int>> = digraph.louvainCommunities()
        let directedGreedy: Partition<ReferenceDirectedMultigraph<Int>> = digraph.greedyModularityCommunities()
        #expect(directed.map { Array($0) } == [[0], [1]])
        #expect(directedGreedy.count >= 1)
        let quality: PartitionQuality = graph.partitionQuality(of: [[0, 1]])
        #expect(quality.coverage == 1)
        #expect(quality.performance == 1)
        #expect(quality == graph.partitionQuality(of: [[1, 0]]))
        #expect(quality != graph.partitionQuality(of: [[0], [1]]))
        #expect(Set([quality, graph.partitionQuality(of: [[1, 0]])]).count == 1)
    }

    @Test("CD-102 Partition as a RandomAccessCollection: indices 0..<count, communities as slices of one flat storage that keep their indices, iteration and reversal")
    func collection() {
        // U: C(0,1,2,3,4,5,6,7,8,9)
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: (0 ..< 10).map { UndirectedEdge($0, ($0 + 1) % 10) })
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]
        #expect(result.startIndex == 0)
        #expect(result.endIndex == 3)
        #expect(result.indices == 0 ..< 3)
        #expect(result.count == 3)
        #expect(!result.isEmpty)
        #expect(result.index(after: 0) == 1)
        #expect(result.index(before: 3) == 2)
        #expect(result.distance(from: 0, to: 3) == 3)
        // Each community keeps the indices of the flat storage it is cut from.
        #expect(result[0].startIndex == 0)
        #expect(result[1].startIndex == 4)
        #expect(result[2].startIndex == 8)
        #expect(result[2].endIndex == 10)
        #expect(result[1].first == 3)
        #expect(Array(result[2]) == [7, 8])
        #expect(result.reversed().map { Array($0) } == expected.reversed())
        #expect(Array(result.joined()) == [0, 1, 2, 9, 3, 4, 5, 6, 7, 8])
        var seen: [[Int]] = []
        for community in result { seen.append(Array(community)) }
        #expect(seen == expected)
        #expect(result.map { $0.count } == [4, 4, 2])
    }

    @Test("CD-004, CD-083 description: the communities as a list of lists")
    func description() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.louvainCommunities().description == "[[0, 1, 2], [3, 4, 5]]")
        #expect("\(graph.greedyModularityCommunities())" == "[[0, 1, 2], [3, 4, 5]]")
        let empty = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(empty.louvainCommunities().description == "[]")
        #expect(empty.louvainCommunities().isEmpty)
    }

    @Test("CD-083, CD-097, CD-115, CD-133, CD-143 Equatable compares the communities: every algorithm, and graphs that differ, give equal partitions when the communities are the same")
    func equatable() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let bridged = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let louvain = bridged.louvainCommunities()
        #expect(louvain == bridged.greedyModularityCommunities())
        #expect(louvain == bridged.labelPropagationCommunities())
        #expect(louvain == bridged.asynchronousLabelPropagationCommunities())
        // U: K(0..2), K(3..5): another graph value, the same communities.
        let separate = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.dropLast().map { UndirectedEdge($0.0, $0.1) })
        #expect(separate.louvainCommunities() == louvain)
        // U: 0-1, 1-2, 2-3, 3-4, 4-5: different communities.
        let path = ReferencePseudograph(vertices: 0 ..< 6, edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        #expect(path.louvainCommunities() != louvain)
        #expect(path.louvainCommunities() == path.louvainCommunities())
    }

    @Test("CD-083, CD-115, CD-133, CD-143, CD-042, CD-069 from generic code over some Graph, and CD-108, CD-131, CD-065 over some DirectedGraph")
    func genericCode() {
        func undirected<G: Graph>(_ g: G, _ communities: [[G.Vertex]]) -> ([[[G.Vertex]]], Double, Double) {
            var generator = SeededRandomNumberGenerator(seed: 5)
            var again = SeededRandomNumberGenerator(seed: 5)
            let results = [
                g.louvainCommunities().map { Array($0) },
                g.louvainCommunities(using: &generator).map { Array($0) },
                g.greedyModularityCommunities().map { Array($0) },
                g.labelPropagationCommunities().map { Array($0) },
                g.asynchronousLabelPropagationCommunities().map { Array($0) },
                g.asynchronousLabelPropagationCommunities(using: &again).map { Array($0) }
            ]
            return (results, g.modularity(of: communities), g.partitionQuality(of: communities).coverage)
        }
        func directed<G: DirectedGraph>(_ g: G, _ communities: [[G.Vertex]]) -> ([[[G.Vertex]]], Double) {
            let results = [g.louvainCommunities().map { Array($0) }, g.greedyModularityCommunities().map { Array($0) }]
            return (results, g.modularity(of: communities))
        }
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let (results, q, coverage) = undirected(graph, [[0, 1, 2], [3, 4, 5]])
        for result in results {
            #expect(result == [[0, 1, 2], [3, 4, 5]])
        }
        #expect(abs(q - 0.35714285714285715) <= 1e-12)
        #expect(abs(coverage - 0.8571428571428571) <= 1e-12)
        // D: C(0,1,2), C(3,4,5), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let (directedResults, directedQ) = directed(digraph, [[0, 1, 2], [3, 4, 5]])
        for result in directedResults {
            #expect(result == [[0, 1, 2], [3, 4, 5]])
        }
        #expect(abs(directedQ - 0.36734693877551017) <= 1e-12)
    }

    @Test("CD-042, CD-050, CD-083 modularity(of:) and partitionQuality(of:) take any collection of vertex collections: sets, Components, another Partition, slices, in any community order")
    func anyCollection() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected = 0.35714285714285715
        let sets: [Set<Int>] = [[5, 4, 3], [2, 0, 1]]
        #expect(abs(graph.modularity(of: sets) - expected) <= 1e-12)
        let slices: [ArraySlice<Int>] = [[9, 0, 1, 2].dropFirst(), [3, 4, 5]]
        #expect(abs(graph.modularity(of: slices) - expected) <= 1e-12)
        let reordered: [[Int]] = [[4, 3, 5], [], [1, 2, 0]]
        #expect(abs(graph.modularity(of: reordered) - expected) <= 1e-12)
        let louvain = graph.louvainCommunities()
        #expect(abs(graph.modularity(of: louvain) - expected) <= 1e-12)
        #expect(abs(graph.directed.modularity(of: louvain) - expected) <= 1e-12)
        let quality = graph.partitionQuality(of: louvain)
        #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12)
        #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12)
        #expect(graph.partitionQuality(of: sets) == quality)
        // CD-050: connectedComponents() is a partition (one community here, so Q = 0).
        #expect(abs(graph.modularity(of: graph.connectedComponents())) <= 1e-12)
        let lazy = (0 ..< 2).map { c in (0 ..< 3).lazy.map { 3 * c + $0 } }
        #expect(abs(graph.modularity(of: lazy) - expected) <= 1e-12)
    }

    @Test("CD-105, CD-129, CD-142, CD-152 on a conformer without indices, vertices listed by first appearance (not value order): community(ofIndex:) is by position in vertices")
    func withoutIndices() {
        // U: lcg(40,90,7), generated as the catalog does: m pseudo-random non-loop pairs over 0..<n.
        var state: UInt64 = 7
        var pairs: [(Int, Int)] = []
        while pairs.count < 90 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let u = Int((state >> 33) % 40)
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let v = Int((state >> 33) % 40)
            if u != v { pairs.append((u, v)) }
        }
        var listed: [Int] = []
        for (u, v) in pairs {
            if !listed.contains(u) { listed.append(u) }
            if !listed.contains(v) { listed.append(v) }
        }
        #expect(listed.prefix(4) == [38, 31, 25, 19])
        let graph = PlainGraph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let louvain = graph.louvainCommunities()
        let expectedLouvain: [[Int]] = [
            [38, 29, 2, 16, 37, 8, 10, 28, 21, 22], [31, 36, 33, 14, 18, 30, 11],
            [25, 32, 0, 5, 9, 27, 12, 15, 34, 1, 17, 23], [19, 24, 4, 6, 13, 35, 39, 7], [20, 26, 3]
        ]
        #expect(louvain.map { Array($0) } == expectedLouvain)
        let greedy = graph.greedyModularityCommunities()
        let expectedGreedy: [[Int]] = [
            [38, 29, 2, 16, 33, 8, 10, 26, 11, 21, 22], [31, 19, 24, 36, 13, 35, 39, 17],
            [25, 32, 0, 37, 9, 27, 15, 28, 34], [4, 6, 18, 30, 20, 3, 7], [5, 14, 12, 1, 23]
        ]
        #expect(greedy.map { Array($0) } == expectedGreedy)
        let semi = graph.labelPropagationCommunities()
        let expectedSemi: [[Int]] = [
            [38, 31, 5, 14, 18, 30, 12, 8, 10, 20, 26, 3, 1, 23, 7],
            [25, 4, 6, 32, 0, 16, 33, 37, 9, 27, 15, 28, 34, 11], [19, 13, 39, 17], [24, 36, 35], [29, 2, 21, 22]
        ]
        #expect(semi.map { Array($0) } == expectedSemi)
        let asynchronous = graph.asynchronousLabelPropagationCommunities()
        #expect(asynchronous.map { Array($0) } == [listed])
        for result in [louvain, greedy, semi, asynchronous] {
            for (i, v) in listed.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
                #expect(result[result.community(of: v)].contains(v), "vertex \(v)")
            }
        }
        #expect(abs(graph.modularity(of: louvain) - graph.modularity(of: expectedLouvain)) <= 1e-12)
    }

    @Test("CD-110, CD-132 on a directed conformer without indices, vertices listed by first appearance")
    func directedWithoutIndices() {
        // D: lcg(40,100,5)
        var state: UInt64 = 5
        var arcs: [(Int, Int)] = []
        while arcs.count < 100 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let u = Int((state >> 33) % 40)
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let v = Int((state >> 33) % 40)
            if u != v { arcs.append((u, v)) }
        }
        var listed: [Int] = []
        for (u, v) in arcs {
            if !listed.contains(u) { listed.append(u) }
            if !listed.contains(v) { listed.append(v) }
        }
        let graph = PlainDigraph(vertices: listed, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let louvain = graph.louvainCommunities()
        let expectedLouvain: [[Int]] = [
            [32, 34, 5, 35, 33, 37, 21, 7, 31, 39, 27, 26], [13, 2, 20, 17, 22], [15, 29, 10, 24, 30, 25, 4, 16],
            [11, 19, 28, 23, 8, 1, 9, 12, 3, 18], [14, 38, 36, 0, 6]
        ]
        #expect(louvain.map { Array($0) } == expectedLouvain)
        let greedy = graph.greedyModularityCommunities()
        let expectedGreedy: [[Int]] = [
            [32, 34, 5, 35, 33, 37, 31, 39], [13, 2, 20, 17, 22], [15, 29, 30, 25, 4, 7, 16, 26],
            [11, 19, 10, 24, 28, 23, 8, 1, 9, 12, 27, 3, 18], [21, 14, 38, 36, 0, 6]
        ]
        #expect(greedy.map { Array($0) } == expectedGreedy)
        for result in [louvain, greedy] {
            for (i, v) in listed.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
        }
    }

    @Test("CD-083, CD-115, CD-133, CD-143, CD-042, CD-108 with Collider vertices whose hashes all collide")
    func colliders() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) })
        let expected = [[0, 1, 2], [3, 4, 5]].map { $0.map { Collider($0) } }
        #expect(graph.louvainCommunities().map { Array($0) } == expected)
        #expect(graph.greedyModularityCommunities().map { Array($0) } == expected)
        #expect(graph.labelPropagationCommunities().map { Array($0) } == expected)
        #expect(graph.asynchronousLabelPropagationCommunities().map { Array($0) } == expected)
        #expect(graph.louvainCommunities().community(of: Collider(4)) == 1)
        #expect(abs(graph.modularity(of: expected) - 0.35714285714285715) <= 1e-12)
        // D: C(0,1,2), C(3,4,5), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let digraph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: Collider($0.0), to: Collider($0.1)) })
        #expect(digraph.louvainCommunities().map { Array($0) } == expected)
        let plain = PlainGraph(vertices: (0 ..< 6).map { Collider(5 - $0) }, edges: pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) })
        #expect(plain.louvainCommunities().count == 2)
        #expect(plain.louvainCommunities().community(of: Collider(0)) == 1)
    }

    @Test("CD-088, CD-091, CD-119, CD-121, CD-136, CD-146 deterministic: the same call twice, and ReferencePseudograph, UndirectedAdjacencyList and a conformer without indices with the same numbering, give the same partitions on the karate club")
    func deterministic() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let reference = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let list = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let plain = PlainGraph(vertices: Array(0 ..< 34), edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = (0 ..< pairs.count).map { Double($0 % 7 + 1) / 3 }
        func all<G: Graph>(_ g: G) -> [[[Int]]] where G.Vertex == Int {
            let offset = { (p: G.Edges.Index) in g.edges.distance(from: g.edges.startIndex, to: p) }
            var generator = SeededRandomNumberGenerator(seed: 11)
            var again = SeededRandomNumberGenerator(seed: 12)
            return [
                g.louvainCommunities().map { Array($0) },
                g.louvainCommunities(weight: { w[offset($0)] }).map { Array($0) },
                g.louvainCommunities(resolution: 1.5, using: &generator).map { Array($0) },
                g.greedyModularityCommunities().map { Array($0) },
                g.greedyModularityCommunities(weight: { w[offset($0)] }).map { Array($0) },
                g.labelPropagationCommunities().map { Array($0) },
                g.labelPropagationCommunities(weight: { w[offset($0)] }).map { Array($0) },
                g.asynchronousLabelPropagationCommunities().map { Array($0) },
                g.asynchronousLabelPropagationCommunities(using: &again).map { Array($0) }
            ]
        }
        let first = all(reference)
        #expect(first[0] == [
            [0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
            [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]
        ])
        #expect(first[3] == [
            [0, 4, 5, 6, 10, 11, 16, 19], [1, 2, 3, 7, 9, 12, 13, 17, 21],
            [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]
        ])
        #expect(all(reference) == first)
        #expect(all(list) == first)
        #expect(all(plain) == first)
        let q = reference.modularity(of: first[1], weight: { w[$0] })
        #expect(abs(q - list.modularity(of: first[1], weight: { w[$0] })) <= 1e-12)
    }

    @Test("CD-088 the using: overloads draw from the generator (Fisher–Yates over each level: at least n − 1 draws), and the same seed repeats the result")
    func usingDraws() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var louvainGenerator = CountingGenerator(seed: 3)
        let louvain = graph.louvainCommunities(using: &louvainGenerator)
        #expect(louvainGenerator.draws >= 33)
        var louvainAgain = CountingGenerator(seed: 3)
        #expect(graph.louvainCommunities(using: &louvainAgain) == louvain)
        #expect(louvainAgain.draws == louvainGenerator.draws)
        var asynchronousGenerator = CountingGenerator(seed: 3)
        let asynchronous = graph.asynchronousLabelPropagationCommunities(using: &asynchronousGenerator)
        #expect(asynchronousGenerator.draws >= 33)
        var asynchronousAgain = CountingGenerator(seed: 3)
        #expect(graph.asynchronousLabelPropagationCommunities(using: &asynchronousAgain) == asynchronous)
        #expect(asynchronousAgain.draws == asynchronousGenerator.draws)
        // D: the karate club as arcs u → v, u < v (CD-109): Louvain's directed overload draws too.
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        var directedGenerator = CountingGenerator(seed: 3)
        let directed = digraph.louvainCommunities(using: &directedGenerator)
        #expect(directedGenerator.draws >= 33)
        var directedAgain = CountingGenerator(seed: 3)
        #expect(digraph.louvainCommunities(using: &directedAgain) == directed)
        // One vertex, or no edges: nothing to order, and the result is the singletons.
        var idle = CountingGenerator(seed: 3)
        let edgeless = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: [])
        #expect(edgeless.louvainCommunities(using: &idle).map { Array($0) } == [[0], [1], [2], [3]])
        #expect(edgeless.asynchronousLabelPropagationCommunities(using: &idle).map { Array($0) } == [[0], [1], [2], [3]])
    }

    @Test("CD-145, CD-088 shuffled orders differ from index order: asynchronous propagation on the ring of cliques finds the four cliques for some seed in 1...20, and Louvain on the karate club gives more than one partition over those seeds")
    func usingChangesOrder() {
        // U: nx(ring_of_cliques,4,4)
        let ring: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6),
            (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (9, 12), (10, 11), (12, 13),
            (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: ring.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.asynchronousLabelPropagationCommunities().count == 1)
        let cliques: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
        var found = false
        for seed in UInt(1) ... 20 {
            var generator = SeededRandomNumberGenerator(seed: seed)
            let result = graph.asynchronousLabelPropagationCommunities(using: &generator)
            if result.map({ Array($0) }) == cliques { found = true }
        }
        #expect(found)
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let karate = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var partitions = Set<[[Int]]>()
        for seed in UInt(1) ... 20 {
            var generator = SeededRandomNumberGenerator(seed: seed)
            partitions.insert(karate.louvainCommunities(using: &generator).map { Array($0) })
        }
        #expect(partitions.count > 1)
    }
}
