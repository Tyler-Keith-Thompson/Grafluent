// Conformance: the same answers on every representation and on relabelled copies. Graphs with the
// same rows (`Pseudograph`, `Multigraph` when loop-free, `ReferencePseudograph`, and a file-private
// conformer with no vertex or edge indices) give the same embedding and the same witness, position
// for position. `UndirectedAdjacencyList` (parallel edges collapsed), `AdjacencyList.undirected`
// (the second copy of a pair as the reverse arc) and `AdjacencyMatrix.undirected` (positions are
// cells) give the same yes/no answers, and each of their witnesses is checked against the
// definitions in api.md. A copy whose vertices are Strings gives the same embedding through the
// labels; a copy with its vertices listed and its edges inserted in another order gives the same
// answers and face count. An embedding keeps the graph it was made from. `KuratowskiSubgraph.Kind`
// is nested in a generic type, so kinds from different graph types compare through `== .k5`. See
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Planarity
import Testing
import Walks

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
/// Rows are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Planarity conformance across representations", .tags(.conformance))
struct PlanarityConformanceTests {
    @Test("Representations with the same rows give the same embedding and witness, position for position")
    func sameRows() throws {
        var rng = SeededRandomNumberGenerator(seed: 2026)
        var inputs: [(listed: [Int], pairs: [(Int, Int)])] = [
            (Array(0 ..< 5), [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]),
            (Array(0 ..< 6), [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]),
            (Array(0 ..< 4), [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (0, 0), (1, 2)]),
            ([3, 1, 0, 2], [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1), (2, 2)]),
            (Array(0 ..< 8), [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)]),
        ]
        for _ in 0 ..< 120 {
            let n = Int.random(in: 1 ... 8, using: &rng)
            let m = Int.random(in: 0 ... 3 * n, using: &rng)
            let pairs = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            inputs.append((Array(0 ..< n).shuffled(using: &rng), pairs))
        }
        for (listed, pairs) in inputs {
            let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
            let context = "\(pairs) on \(listed)"
            let graph = Pseudograph<Int>(vertices: listed, edges: edges)
            let reference = ReferencePseudograph<Int>(vertices: listed, edges: edges)
            let unindexed = UnindexedGraph<Int>(vertices: listed, edges: edges)
            #expect(unindexed.vertexIndexBound == nil && unindexed.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == listed && reference.vertices == listed)
            let planar = graph.isPlanar
            #expect(reference.isPlanar == planar && unindexed.isPlanar == planar, "\(context)")
            #expect(reference.isOuterplanar == graph.isOuterplanar && unindexed.isOuterplanar == graph.isOuterplanar, "\(context)")
            let loopFree = pairs.allSatisfy { $0.0 != $0.1 }
            let multigraph = loopFree ? Multigraph<Int>(vertices: listed, edges: edges) : nil
            #expect((multigraph != nil) == loopFree)
            if let multigraph { #expect(multigraph.isPlanar == planar && multigraph.isOuterplanar == graph.isOuterplanar, "\(context)") }
            if let embedding = graph.planarEmbedding() {
                let rotation = listed.map { Array(embedding.clockwiseIncidentEdges(of: $0)) }
                let faces = embedding.faces.map { [$0.vertices, $0.edges] }
                let r = try #require(reference.planarEmbedding(), "\(context)")
                let u = try #require(unindexed.planarEmbedding(), "\(context)")
                #expect(listed.map { Array(r.clockwiseIncidentEdges(of: $0)) } == rotation, "\(context)")
                #expect(listed.map { Array(u.clockwiseIncidentEdges(of: $0)) } == rotation, "\(context)")
                #expect(r.faces.map { [$0.vertices, $0.edges] } == faces && u.faces.map { [$0.vertices, $0.edges] } == faces, "\(context)")
                #expect(r.faceCount == embedding.faceCount && u.faceCount == embedding.faceCount)
                // Index space without indices: index i is the i-th vertex.
                for i in listed.indices {
                    #expect(Array(u.clockwiseNeighborIndices(ofIndex: i)) == Array(embedding.clockwiseNeighborIndices(ofIndex: i)), "\(context)")
                }
                if let multigraph {
                    let e = try #require(multigraph.planarEmbedding())
                    #expect(listed.map { Array(e.clockwiseIncidentEdges(of: $0)) } == rotation, "\(context)")
                }
                #expect(reference.findKuratowskiSubgraph() == nil && unindexed.findKuratowskiSubgraph() == nil)
            } else {
                #expect(!planar && reference.planarEmbedding() == nil && unindexed.planarEmbedding() == nil, "\(context)")
                let w = try #require(graph.findKuratowskiSubgraph(), "\(context)")
                let r = try #require(reference.findKuratowskiSubgraph(), "\(context)")
                let u = try #require(unindexed.findKuratowskiSubgraph(), "\(context)")
                #expect((r.kind == .k5) == (w.kind == .k5) && r.edges == w.edges && r.branchVertices == w.branchVertices && r.paths == w.paths, "\(context)")
                #expect((u.kind == .k5) == (w.kind == .k5) && u.edges == w.edges && u.branchVertices == w.branchVertices && u.paths == w.paths, "\(context)")
                if let multigraph {
                    let k = try #require(multigraph.findKuratowskiSubgraph())
                    #expect((k.kind == .k5) == (w.kind == .k5) && k.edges == w.edges && k.branchVertices == w.branchVertices && k.paths == w.paths, "\(context)")
                }
            }
        }
    }

    @Test("Every representation gives the same answers, and each embedding and witness meets the definitions")
    func everyRepresentation() throws {
        // The definitions, written out once for this test: a rotation over every edge position whose
        // face orbits are `faces` and meet Euler's formula, or a subdivision of K₅ or K₃,₃.
        func check<G: Graph>(_ graph: G, planar: Bool, outerplanar: Bool, _ context: String) throws {
            #expect(graph.isPlanar == planar, "\(context)")
            #expect(graph.isOuterplanar == outerplanar, "\(context)")
            let vertexList = Array(graph.vertices)
            let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
            if planar {
                let embedding = try #require(graph.planarEmbedding(), "\(context)")
                #expect(graph.findKuratowskiSubgraph() == nil, "\(context)")
                var rotation: [[G.Edges.Index]] = []
                for v in vertexList {
                    let row = Array(embedding.clockwiseIncidentEdges(of: v))
                    let incident = Array(graph.incidentEdges(of: v))
                    #expect(row.sorted() == incident.sorted() && row.first == incident.first, "\(context) at \(v)")
                    #expect(Array(embedding.clockwiseNeighbors(of: v)) == row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }, "\(context)")
                    rotation.append(row)
                }
                var slots: [G.Edges.Index: [(Int, Int)]] = [:]
                for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
                var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
                var orbits: [[G.Edges.Index]] = []
                for i in rotation.indices {
                    for s in rotation[i].indices where !seen[i][s] {
                        var edges: [G.Edges.Index] = []
                        var (x, y) = (i, s)
                        repeat {
                            seen[x][y] = true
                            edges.append(rotation[x][y])
                            let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                            (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                        } while (x, y) != (i, s)
                        orbits.append(edges)
                    }
                }
                #expect(embedding.faces.map(\.edges) == orbits, "\(context)")
                // Euler: Σ (2 − n_c + m_c) over components with an edge.
                var parent = Array(vertexList.indices)
                func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
                for e in graph.edges { parent[find(indexOf[e.u]!)] = find(indexOf[e.v]!) }
                var vertexCount = [Int: Int](), edgeCount = [Int: Int]()
                for i in vertexList.indices { vertexCount[find(i), default: 0] += 1 }
                for e in graph.edges { edgeCount[find(indexOf[e.u]!), default: 0] += 1 }
                let euler = edgeCount.map { 2 - vertexCount[$0.key]! + $0.value }.reduce(0, +)
                #expect(embedding.faceCount == euler && orbits.count == euler, "\(context)")
            } else {
                #expect(graph.planarEmbedding() == nil, "\(context)")
                let witness = try #require(graph.findKuratowskiSubgraph(), "\(context)")
                #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count, "\(context)")
                #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count, "\(context)")
                let branch = witness.branchVertices
                let order = branch.map { indexOf[$0]! }
                var pairs: [(Int, Int)] = []
                switch witness.kind {
                case .k5:
                    #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10, "\(context)")
                    for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
                case .k33:
                    #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted(), "\(context)")
                    #expect(witness.paths.count == 9, "\(context)")
                    for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
                }
                var inner = Set<G.Vertex>()
                var used: [G.Edges.Index] = []
                for (path, (i, j)) in zip(witness.paths, pairs) {
                    #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "\(context)")
                    for (k, p) in path.edges.enumerated() {
                        #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "\(context)")
                    }
                    for v in path.vertices.dropFirst().dropLast() { #expect(!branch.contains(v) && inner.insert(v).inserted, "\(context)") }
                    used += path.edges
                }
                #expect(used.sorted() == witness.edges, "\(context)")
            }
        }
        var rng = SeededRandomNumberGenerator(seed: 77)
        for round in 0 ..< 150 {
            let n = Int.random(in: 1 ... 9, using: &rng)
            let m = Int.random(in: 0 ... 3 * n, using: &rng)
            var pairs = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            if round == 0 { pairs = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)] }
            if round == 1 { pairs = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)] }
            let vertexTotal = max(n, (pairs.map { max($0.0, $0.1) }.max() ?? -1) + 1)
            let context = "\(pairs) on 0..<\(vertexTotal)"
            let graph = Pseudograph<Int>(vertices: 0 ..< vertexTotal, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let planar = graph.isPlanar, outerplanar = graph.isOuterplanar
            try check(graph, planar: planar, outerplanar: outerplanar, "Pseudograph \(context)")
            // Parallel edges collapsed: the answers do not change.
            try check(UndirectedAdjacencyList<Int>(vertices: 0 ..< vertexTotal, edges: pairs.map { UndirectedEdge($0.0, $0.1) }),
                      planar: planar, outerplanar: outerplanar, "UndirectedAdjacencyList \(context)")
            // Arcs: the first copy of a pair as written, the second reversed (a 2-cycle), any more dropped;
            // a loop once. The answers do not change.
            var arcs: [DirectedEdge<Int>] = []
            var arcSet = Set<[Int]>()
            for (a, b) in pairs {
                if arcSet.insert([a, b]).inserted { arcs.append(DirectedEdge(from: a, to: b)) } else if arcSet.insert([b, a]).inserted { arcs.append(DirectedEdge(from: b, to: a)) }
            }
            try check(AdjacencyList<Int>(vertices: 0 ..< vertexTotal, edges: arcs).undirected, planar: planar, outerplanar: outerplanar, "AdjacencyList.undirected \(context)")
            try check(AdjacencyMatrix(vertexCount: vertexTotal, edges: arcs).undirected, planar: planar, outerplanar: outerplanar, "AdjacencyMatrix.undirected \(context)")
        }
    }

    @Test("A relabelled copy gives the same embedding through the labels; a reordered copy the same answers")
    func relabelled() throws {
        var rng = SeededRandomNumberGenerator(seed: 4)
        for round in 0 ..< 150 {
            let n = Int.random(in: 1 ... 9, using: &rng)
            let m = Int.random(in: 0 ... 3 * n, using: &rng)
            var pairs = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            if round == 0 { pairs = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 5), (1, 6), (2, 7), (3, 8), (4, 9), (5, 7), (7, 9), (9, 6), (6, 8), (8, 5)] }  // Petersen
            let vertexTotal = max(n, (pairs.map { max($0.0, $0.1) }.max() ?? -1) + 1)
            let context = "\(pairs)"
            let graph = Pseudograph<Int>(vertices: 0 ..< vertexTotal, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let named = Pseudograph<String>(vertices: (0 ..< vertexTotal).map { "v\($0)" }, edges: pairs.map { UndirectedEdge("v\($0.0)", "v\($0.1)") })
            #expect(named.isPlanar == graph.isPlanar && named.isOuterplanar == graph.isOuterplanar, "\(context)")
            if let embedding = graph.planarEmbedding() {
                let e = try #require(named.planarEmbedding())
                for v in 0 ..< vertexTotal {
                    #expect(Array(e.clockwiseIncidentEdges(of: "v\(v)")) == Array(embedding.clockwiseIncidentEdges(of: v)), "\(context)")
                    #expect(Array(e.clockwiseNeighbors(of: "v\(v)")) == embedding.clockwiseNeighbors(of: v).map { "v\($0)" }, "\(context)")
                    #expect(Array(e.clockwiseNeighborIndices(ofIndex: v)) == Array(embedding.clockwiseNeighborIndices(ofIndex: v)), "\(context)")
                }
                #expect(e.faces.map(\.edges) == embedding.faces.map(\.edges), "\(context)")
                #expect(e.faces.map(\.vertices) == embedding.faces.map { $0.vertices.map { "v\($0)" } }, "\(context)")
            } else {
                let w = try #require(graph.findKuratowskiSubgraph())
                let k = try #require(named.findKuratowskiSubgraph())
                #expect((k.kind == .k5) == (w.kind == .k5) && k.edges == w.edges && k.branchVertices == w.branchVertices.map { "v\($0)" }, "\(context)")
                #expect(k.paths.map(\.edges) == w.paths.map(\.edges) && k.paths.map(\.vertices) == w.paths.map { $0.vertices.map { "v\($0)" } }, "\(context)")
            }
            // Vertices listed in another order and edges inserted in another order (some flipped).
            let listed = Array(0 ..< vertexTotal).shuffled(using: &rng)
            let shuffled = pairs.shuffled(using: &rng).map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            let reordered = Pseudograph<Int>(vertices: listed, edges: shuffled.map { UndirectedEdge($0.0, $0.1) })
            #expect(reordered.isPlanar == graph.isPlanar && reordered.isOuterplanar == graph.isOuterplanar, "\(context)")
            #expect(reordered.planarEmbedding()?.faceCount == graph.planarEmbedding()?.faceCount, "\(context)")
            #expect((reordered.findKuratowskiSubgraph() == nil) == graph.isPlanar, "\(context)")
        }
    }

    @Test("An embedding and a witness keep the graph they were made from")
    func valueSemantics() throws {
        var graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let embedding = try #require(graph.planarEmbedding())
        let before = (0 ..< 4).map { Array(embedding.clockwiseIncidentEdges(of: $0)) }
        let facesBefore = embedding.faces.map(\.vertices)
        _ = graph.insert(edge: UndirectedEdge(0, 2))
        _ = graph.insert(edge: UndirectedEdge(1, 3))
        _ = graph.insert(4)
        #expect((0 ..< 4).map { Array(embedding.clockwiseIncidentEdges(of: $0)) } == before)
        #expect(embedding.faces.map(\.vertices) == facesBefore && embedding.faceCount == 2)
        #expect(embedding.clockwiseNeighbors(safe: 4) == nil)
        #expect(embedding.face(from: 0, alongEdgeAt: 0).length == 4)
        // K4 now: still planar, with four triangles.
        #expect(try #require(graph.planarEmbedding()).faceCount == 4)
        var k5 = Pseudograph<Int>(vertices: 0 ..< 5, edges: (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { UndirectedEdge(i, $0) } })
        let witness = try #require(k5.findKuratowskiSubgraph())
        _ = k5.remove(edgeAt: 0)
        #expect(witness.kind == .k5 && witness.edges == Array(0 ..< 10) && witness.paths.count == 10)
        #expect(k5.isPlanar)
    }
}
