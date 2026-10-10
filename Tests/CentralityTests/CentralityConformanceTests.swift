// Conformance and representation-independence: `CentralityScores` and `HubAndAuthorityScores` are
// `Sendable` when their graph and vertices are (computed in a `Task` and read outside it); a result
// holds a copy of the graph (mutating the original afterwards changes nothing it answers) and has
// `DirectedView<Self>` as its graph for an undirected graph; every measure works from generic code
// over `some Graph` and `some DirectedGraph`; conformers private to this file without vertex or
// edge indices (numbering through `vertices`, `score(ofIndex:)` by position in `vertices`, here not
// value order) and `Collider` vertices whose hashes all collide give the catalog's values. Literals
// are the catalog rows named in each test, at the full precision of ref.py's model. Case IDs
// (CE-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Centrality
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

@Suite("Centrality conformance", .tags(.conformance))
struct CentralityConformanceTests {
    @Test("CE-090, CE-197 CentralityScores and HubAndAuthorityScores are Sendable: computed in a Task and read outside it")
    func sendable() async throws {
        // U: P(0..4)
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let betweenness = await Task { graph.betweennessCentrality() }.value
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let sent = requireSendable(betweenness)
        let expected: [Double] = [0, 0.5, 0.6666666666666666, 0.5, 0]
        for (v, value) in zip(0 ..< 5, expected) {
            let error = abs(sent.score(of: v) - value)
            #expect(error <= 1e-12, "vertex \(v)")
        }
        // D: 0>1, 0>2, 3>1
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let digraph = AdjacencyList(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let hits = try #require(await Task { digraph.hits() }.value)
        let hubs = requireSendable(hits).hubs
        let expectedHubs: [Double] = [0.6180339887498947, 0, 0, 0.38196601125010526]
        for (i, value) in expectedHubs.enumerated() {
            let error = abs(hubs.score(ofIndex: i) - value)
            #expect(error <= 1e-4, "index \(i)")
        }
        let pageRank = try #require(await Task { graph.pageRank() }.value)
        #expect(requireSendable(pageRank).scores.count == 5)
    }

    @Test("CE-090, CE-050 the result holds a copy of the graph: mutating the graph afterwards changes nothing it answers")
    func valueSemantics() {
        // U: P(0..4)
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let betweenness: CentralityScores<DirectedView<UndirectedAdjacencyList<Int>>> = graph.betweennessCentrality()
        let closeness = graph.closenessCentrality()
        _ = graph.insert(edge: UndirectedEdge(0, 4))
        _ = graph.remove(2)
        _ = graph.insert(9)
        let expected: [Double] = [0, 0.5, 0.6666666666666666, 0.5, 0]
        let expectedCloseness: [Double] = [0.4, 0.5714285714285714, 0.6666666666666666, 0.5714285714285714, 0.4]
        for v in 0 ..< 5 {
            let error = abs(betweenness.score(of: v) - expected[v])
            #expect(error <= 1e-12, "vertex \(v)")
            let closenessError = abs(closeness.score(of: v) - expectedCloseness[v])
            #expect(closenessError <= 1e-12, "vertex \(v)")
        }
        #expect(betweenness.scores.count == 5)
        #expect(closeness.scores.count == 5)
    }

    @Test("CE-030, CE-050, CE-070, CE-090, CE-094, CE-132, CE-160, CE-181 from generic code over some Graph, and CE-121, CE-177 over some DirectedGraph")
    func genericCode() throws {
        func undirected<G: Graph>(_ g: G, at v: G.Vertex) -> [Double?] {
            [
                g.degreeCentrality().score(of: v),
                g.closenessCentrality().score(of: v),
                g.closenessCentrality(of: v),
                g.harmonicCentrality().score(of: v),
                g.harmonicCentrality(of: v),
                g.betweennessCentrality().score(of: v),
                g.eigenvectorCentrality()?.score(of: v),
                g.katzCentrality()?.score(of: v),
                g.pageRank()?.score(of: v)
            ]
        }
        func directed<G: DirectedGraph>(_ g: G, at v: G.Vertex) -> [Double?] {
            [
                g.betweennessCentrality(normalized: false).score(of: v),
                g.pageRank()?.score(of: v),
                g.hits()?.hubs.score(of: v)
            ]
        }
        // U: S(0;1..4): CE-030, CE-094, CE-132, CE-181 at the hub
        let star = ReferencePseudograph(vertices: 0 ..< 5, edges: (1 ... 4).map { UndirectedEdge(0, $0) })
        let hub = undirected(star, at: 0)
        let hubDegree = try #require(hub[0])
        #expect(abs(hubDegree - 1) <= 1e-12)
        let hubBetweenness = try #require(hub[5])
        #expect(abs(hubBetweenness - 1) <= 1e-12)
        let hubEigenvector = try #require(hub[6])
        #expect(abs(hubEigenvector - 0.7071067811865479) <= 1e-4)
        let hubPageRank = try #require(hub[8])
        #expect(abs(hubPageRank - 0.47567567567567465) <= 1e-4)
        // U: P(0..4): CE-050, CE-070 at vertex 2; U: P(0,1,2): CE-160 at vertex 1
        let path = ReferencePseudograph(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let middle = undirected(path, at: 2)
        let closeness = try #require(middle[1])
        #expect(abs(closeness - 0.6666666666666666) <= 1e-12)
        let closenessOne = try #require(middle[2])
        #expect(abs(closenessOne - 0.6666666666666666) <= 1e-12)
        let harmonic = try #require(middle[3])
        #expect(abs(harmonic - 3) <= 1e-12)
        let harmonicOne = try #require(middle[4])
        #expect(abs(harmonicOne - 3) <= 1e-12)
        let short = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let katz = try #require(undirected(short, at: 1)[7])
        #expect(abs(katz - 0.6107839182711452) <= 1e-4)
        // D: 0>1, 0>2, 1>3, 2>3, 3>4: CE-121 at vertex 3
        let diamond: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
        let dag = ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: diamond.map { DirectedEdge(from: $0.0, to: $0.1) })
        let three = try #require(directed(dag, at: 3)[0])
        #expect(abs(three - 3) <= 1e-12)
        // D: 0>1, 0>2, 1>2, 2>0, 3>2: CE-177 at vertex 2
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let rank = try #require(directed(digraph, at: 2)[1])
        #expect(abs(rank - 0.39414923685698067) <= 1e-4)
    }

    @Test("CE-108, CE-140 on a conformer without indices, vertices listed as [3, 1, 0, 2]: score(ofIndex:) is by position in vertices")
    func withoutIndices() throws {
        // U: 0-1, 0-1, 1-2, 0-3, 3-2, vertices listed [3, 1, 0, 2]
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (0, 3), (3, 2)]
        let graph = PlainGraph(vertices: [3, 1, 0, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        // By vertex value (the catalog's order 0, 1, 2, 3).
        let betweennessByValue: [Double] = [0.6666666666666666, 0.6666666666666666, 0.3333333333333333, 0.3333333333333333]
        let eigenvectorByValue: [Double] = [0.6015009550075454, 0.6015009550075454, 0.37174803446018484, 0.37174803446018484]
        let betweenness = graph.betweennessCentrality(normalized: false)
        let eigenvector = try #require(graph.eigenvectorCentrality())
        for (i, v) in graph.vertices.enumerated() {
            let byIndex = abs(betweenness.score(ofIndex: i) - betweennessByValue[v])
            #expect(byIndex <= 1e-12, "index \(i)")
            let byVertex = abs(betweenness.score(of: v) - betweennessByValue[v])
            #expect(byVertex <= 1e-12, "vertex \(v)")
            let eigen = abs(eigenvector.score(ofIndex: i) - eigenvectorByValue[v])
            #expect(eigen <= 1e-4, "index \(i)")
        }
        let byPosition = graph.vertices.map { betweenness.score(of: $0) }
        #expect(byPosition == betweenness.scores)
    }

    @Test("CE-177, CE-121, CE-197, CE-198 on a directed conformer without indices, vertices listed in reverse")
    func directedWithoutIndices() throws {
        // D: 0>1, 0>2, 1>2, 2>0, 3>2, vertices listed [3, 2, 1, 0]
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0), (3, 2)]
        let graph = PlainDigraph(vertices: [3, 2, 1, 0], edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let pageRankByValue: [Double] = [0.3725268513284352, 0.1958239118145841, 0.39414923685698067, 0.037500000000000006]
        let pageRank = try #require(graph.pageRank())
        for (i, v) in graph.vertices.enumerated() {
            let error = abs(pageRank.score(ofIndex: i) - pageRankByValue[v])
            #expect(error <= 1e-4, "index \(i)")
        }
        // D: 0>1, 0>2, 1>3, 2>3, 3>4, vertices listed [4, 3, 2, 1, 0]
        let diamond: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]
        let dag = PlainDigraph(vertices: [4, 3, 2, 1, 0], edges: diamond.map { DirectedEdge(from: $0.0, to: $0.1) })
        let betweennessByValue: [Double] = [0, 1, 1, 3, 0]
        let betweenness = dag.betweennessCentrality(normalized: false)
        for (i, v) in dag.vertices.enumerated() {
            let error = abs(betweenness.score(ofIndex: i) - betweennessByValue[v])
            #expect(error <= 1e-12, "index \(i)")
        }
        // D: 0>1, 0>2, 3>1, vertices listed [3, 2, 1, 0]
        let hubPairs: [(Int, Int)] = [(0, 1), (0, 2), (3, 1)]
        let small = PlainDigraph(vertices: [3, 2, 1, 0], edges: hubPairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let hits = try #require(small.hits())
        let hubsByValue: [Double] = [0.6180339887498947, 0, 0, 0.38196601125010526]
        let authoritiesByValue: [Double] = [0, 0.6180339887498951, 0.3819660112501048, 0]
        for v in 0 ..< 4 {
            let hubError = abs(hits.hubs.score(of: v) - hubsByValue[v])
            #expect(hubError <= 1e-4, "vertex \(v)")
            let authorityError = abs(hits.authorities.score(of: v) - authoritiesByValue[v])
            #expect(authorityError <= 1e-4, "vertex \(v)")
        }
    }

    @Test("Deterministic summation order (api.md, Numerical policy): the same call twice, and ReferencePseudograph and UndirectedAdjacencyList with the same rows, give bitwise equal scores on the karate club")
    func deterministic() throws {
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
        let w = (0 ..< pairs.count).map { Double($0 % 7 + 1) / 3 }
        func all<G: Graph>(_ g: G) throws -> [[Double]] {
            [
                g.closenessCentrality(weight: { w[g.edges.distance(from: g.edges.startIndex, to: $0)] }).scores,
                g.harmonicCentrality().scores,
                g.betweennessCentrality().scores,
                g.betweennessCentrality(weight: { w[g.edges.distance(from: g.edges.startIndex, to: $0)] }).scores,
                try #require(g.eigenvectorCentrality()).scores,
                try #require(g.katzCentrality()).scores,
                try #require(g.pageRank()).scores,
                try #require(g.directed.hits()).hubs.scores
            ]
        }
        let first = try all(reference)
        let second = try all(reference)
        #expect(first == second)
        let other = try all(list)
        #expect(first == other)
    }

    @Test("CE-073, CE-079 with Collider vertices whose hashes all collide")
    func colliders() {
        // D: C(0,1,2), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: Collider($0.0), to: Collider($0.1)) })
        let expected: [Double] = [1.5, 1.5, 1.5, 1.8333333333333333]
        let harmonic = graph.harmonicCentrality()
        for v in 0 ..< 4 {
            let error = abs(harmonic.score(of: Collider(v)) - expected[v])
            #expect(error <= 1e-12, "vertex \(v)")
        }
        let one = graph.harmonicCentrality(of: Collider(3))
        #expect(abs(one - 1.8333333333333333) <= 1e-12)
        let undirected = ReferencePseudograph(edges: arcs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) })
        let degree = undirected.degreeCentrality()
        let byVertex = undirected.vertices.map { degree.score(of: $0) }
        #expect(byVertex == degree.scores)
    }
}
