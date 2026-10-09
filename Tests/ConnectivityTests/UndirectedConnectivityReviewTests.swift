// Cases added after the critical review: a conformer with edge indices but no vertex indices,
// a conformer whose index rows break the protocol's laws (it traps rather than reading garbage),
// and UndirectedAdjacencyList after mutations that repack its rows (many vertex removals,
// removing every edge with and without keeping capacity, removing the last slot while it has a
// self-loop). Each compares every result with a ReferencePseudograph holding the same vertices
// and edges in the same order, whose answers the rest of the suite pins. Case IDs (CN-nn) refer
// to the catalog; see README.md.

import AdjacencyListModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

/// An undirected multigraph with edge indices (positions in `edges`) but no vertex indices.
private struct EdgeIndexedGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A triangle whose `neighborIndices(ofIndex:)` drops the last neighbor, breaking the law that
/// it parallels `incidentEdges(ofIndex:)`.
private struct BrokenRowsGraph: Graph {
    let vertices = [0, 1, 2]
    let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]
    func incidentEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].u == vertex || edges[$0].v == vertex } }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { 3 }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func neighborIndices(ofIndex index: Int) -> [Int] { Array(neighbors(of: index).dropLast()) }
    var edgeIndexBound: Int? { 3 }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Undirected connectivity review cases")
struct UndirectedConnectivityReviewTests {
    @Test("CN-400 a conformer with edge indices but no vertex indices gives the pseudograph's answers", .tags(.randomized), arguments: 0 ..< 8)
    func edgeIndicesOnly(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(400 + seed))
        for _ in 0 ..< 40 {
            let n = Int.random(in: 1 ... 9, using: &rng)
            // Vertices listed in a shuffled order, so numbering by `vertices` matters.
            let listed = Array(0 ..< n).shuffled(using: &rng)
            var edges: [UndirectedEdge<Int>] = []
            for _ in 0 ..< Int.random(in: 0 ... 14, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                edges.append(UndirectedEdge(u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.2 { edges.append(UndirectedEdge(v, u)) }
            }
            let graph = EdgeIndexedGraph(vertices: listed, edges: edges)
            let reference = ReferencePseudograph(vertices: listed, edges: edges)
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == edges.count)
            #expect(graph.connectedComponents().map(Array.init) == reference.connectedComponents().map(Array.init), "\(listed) \(edges)")
            #expect(graph.bridges() == reference.bridges(), "\(listed) \(edges)")
            #expect(graph.articulationPoints() == reference.articulationPoints(), "\(listed) \(edges)")
            let blocks = graph.biconnectedComponents()
            let expected = reference.biconnectedComponents()
            #expect(blocks.map(Array.init) == expected.map(Array.init), "\(listed) \(edges)")
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected.indices.map { Array(expected.vertices(ofComponentAt: $0)) })
            #expect(edges.indices.map { blocks.component(ofEdgeAt: $0) } == edges.indices.map { expected.component(ofEdgeAt: $0) })
            #expect(listed.map { Array(blocks.components(containing: $0)) } == listed.map { Array(expected.components(containing: $0)) })
            #expect(graph.biEdgeConnectedComponents().map(Array.init) == reference.biEdgeConnectedComponents().map(Array.init))
            #expect(graph.isConnected == reference.isConnected && graph.hasBridges == reference.hasBridges)
            #expect(graph.isBiconnected == reference.isBiconnected && graph.isBiEdgeConnected == reference.isBiEdgeConnected)
            #expect(graph.blockCutTree().edgeCount == reference.blockCutTree().edgeCount)
        }
    }

    @Test("CN-401 UndirectedAdjacencyList after removing most of its vertices (its rows are repacked) agrees with a pseudograph of its edges", .tags(.randomized), arguments: 0 ..< 6)
    func afterManyRemovals(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(401 + seed))
        let n = 60
        var list = UndirectedAdjacencyList<Int>(vertices: 0 ..< n)
        for _ in 0 ..< 150 { list.insert(edge: UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
        for _ in 0 ..< 10 { list.insert(edge: UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
        // Remove 40 vertices, then add a few edges among the rest, so rows move and grow again.
        for v in Array(0 ..< n).shuffled(using: &rng).prefix(40) { list.remove(v) }
        let left = Array(list.vertices)
        for _ in 0 ..< 15 { list.insert(edge: UndirectedEdge(left.randomElement(using: &rng)!, left.randomElement(using: &rng)!)) }
        let reference = ReferencePseudograph(vertices: Array(list.vertices), edges: Array(list.edges))
        #expect(list.connectedComponents().map(Array.init) == reference.connectedComponents().map(Array.init))
        #expect(list.bridges() == reference.bridges())
        #expect(list.articulationPoints() == reference.articulationPoints())
        let blocks = list.biconnectedComponents()
        let expected = reference.biconnectedComponents()
        #expect(blocks.map(Array.init) == expected.map(Array.init))
        #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expected.indices.map { Array(expected.vertices(ofComponentAt: $0)) })
        #expect(list.biEdgeConnectedComponents().map(Array.init) == reference.biEdgeConnectedComponents().map(Array.init))
        #expect(list.isBiconnected == reference.isBiconnected && list.isBiEdgeConnected == reference.isBiEdgeConnected)
    }

    @Test("CN-402 UndirectedAdjacencyList after removeAllEdges, keeping capacity or not, then new edges")
    func afterRemovingAllEdges() {
        for keepingCapacity in [false, true] {
            var list = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 3)])
            list.removeAllEdges(keepingCapacity: keepingCapacity)
            #expect(list.bridges().isEmpty && list.articulationPoints().isEmpty && list.biconnectedComponents().isEmpty)
            #expect(list.connectedComponents().count == 4)
            // A path 3–0–1 and the loop 2–2.
            list.insert(edge: UndirectedEdge(3, 0))
            list.insert(edge: UndirectedEdge(0, 1))
            list.insert(edge: UndirectedEdge(2, 2))
            let reference = ReferencePseudograph(vertices: Array(list.vertices), edges: Array(list.edges))
            #expect(list.bridges() == reference.bridges())
            #expect(list.bridges().count == 2)
            #expect(list.articulationPoints() == [0])
            #expect(list.biconnectedComponents().map(Array.init) == reference.biconnectedComponents().map(Array.init))
            #expect(list.biconnectedComponents().component(ofEdgeAt: 2) == nil)
        }
    }

    @Test("CN-403 removing the vertex in the last slot while it has a self-loop, then the answers of what is left")
    func removeLastSlotWithSelfLoop() {
        // 0–1–2–0 and 3 with a self-loop and an edge to 2; 3 is last.
        var list = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 3), UndirectedEdge(2, 3)])
        #expect(list.articulationPoints() == [2])
        list.remove(3)
        let reference = ReferencePseudograph(vertices: Array(list.vertices), edges: Array(list.edges))
        #expect(list.articulationPoints().isEmpty)
        #expect(list.bridges() == reference.bridges())
        #expect(list.bridges().isEmpty)
        #expect(list.biconnectedComponents().map(Array.init) == reference.biconnectedComponents().map(Array.init))
        #expect(list.isBiconnected && list.isBiEdgeConnected)
        // Remove a middle vertex too: the last slot moves into its place.
        var other = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 3)])
        other.remove(1)
        let otherReference = ReferencePseudograph(vertices: Array(other.vertices), edges: Array(other.edges))
        #expect(other.bridges() == otherReference.bridges())
        #expect(other.articulationPoints() == otherReference.articulationPoints())
        #expect(other.biconnectedComponents().map(Array.init) == otherReference.biconnectedComponents().map(Array.init))
        #expect(other.connectedComponents().map(Array.init) == otherReference.connectedComponents().map(Array.init))
    }

    @Test("CN-404 index rows that break the laws trap instead of being read out of step", .tags(.precondition))
    func brokenRowsTrap() async {
        await #expect(processExitsWith: .failure) {
            _ = BrokenRowsGraph().bridges()
        }
        await #expect(processExitsWith: .failure) {
            _ = BrokenRowsGraph().biconnectedComponents()
        }
    }
}
