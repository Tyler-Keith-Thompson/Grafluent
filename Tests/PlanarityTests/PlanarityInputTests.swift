// Inputs (catalog PL-049 – PL-061): self-loops and parallel edges never change the answer; directed
// graphs go through `undirected` (AdjacencyList, each arc an edge, a 2-cycle two parallel edges).
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("Planarity inputs")
struct PlanarityInputTests {
    @Test("PL-049 one self-loop: isPlanar")
    func pl049() {
        // U: 0-0; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-050 two loops and an edge: isPlanar")
    func pl050() {
        // U: 0-0, 0-0, 0-1; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0),
            UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-051 four parallel edges: isPlanar")
    func pl051() {
        // U: 0=1, 0=1; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1),
            UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-052 K5 with a loop at every vertex: isPlanar")
    func pl052() {
        // U: K(5), 0-0, 1-1, 2-2, 3-3, 4-4; isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(0, 0), UndirectedEdge(1, 1), UndirectedEdge(2, 2), UndirectedEdge(3, 3),
            UndirectedEdge(4, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-053 K3,3 with every edge doubled: isPlanar")
    func pl053() {
        // U: 0=3, 0=4, 0=5, 1=3, 1=4, 1=5, 2=3, 2=4, 2=5; isPlanar → false
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 4), UndirectedEdge(0, 5),
            UndirectedEdge(0, 5), UndirectedEdge(1, 3), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 4), UndirectedEdge(2, 5),
            UndirectedEdge(2, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-054 K4 with a loop and a parallel pair: isPlanar")
    func pl054() {
        // U: K(4), 0-0, 1=2; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(0, 0), UndirectedEdge(1, 2), UndirectedEdge(1, 2)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-055 directed K5 (transitive tournament): undirected.isPlanar")
    func pl055() {
        // D: tt(5); undirected.isPlanar → false
        let graph = AdjacencyList<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 4)]).undirected
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-056 directed K4: undirected.isPlanar")
    func pl056() {
        // D: tt(4); undirected.isPlanar → true
        let graph = AdjacencyList<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)]).undirected
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-057 a 2-cycle: two parallel edges underneath: undirected.isPlanar")
    func pl057() {
        // D: 0>1, 1>0; undirected.isPlanar → true
        let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 1, to: 0)]).undirected
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-058 directed K3,3: undirected.isPlanar")
    func pl058() {
        // D: KB(0..2;3..5); undirected.isPlanar → false
        let graph = AdjacencyList<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 0, to: 4), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 1, to: 4), DirectedEdge(from: 1, to: 5), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 2, to: 5)]).undirected
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-059 directed K3,3, some arcs reversed: undirected.isPlanar")
    func pl059() {
        // D: 0>3, 4>0, 0>5, 3>1, 1>4, 5>1, 2>3, 2>4, 5>2; undirected.isPlanar → false
        let graph = AdjacencyList<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 3, to: 1),
            DirectedEdge(from: 1, to: 4), DirectedEdge(from: 5, to: 1), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 5, to: 2)]).undirected
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-060 directed: 2-cycle embedding: undirected.planarEmbedding()")
    func pl060() throws {
        // D: 0>1, 1>0, 1>2; undirected.planarEmbedding() → faceCount 2; face lengths {4, 2}; unique up to mirror image
        let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)]).undirected
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 2 && orbits.count == 2)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [4, 2])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1], [0, 2, 1], [2]]
        let rotationB: [[Int]] = [[0, 1], [0, 1, 2], [2]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-061 directed K5: witness: undirected.findKuratowskiSubgraph()")
    func pl061() throws {
        // D: tt(5); undirected.findKuratowskiSubgraph() → K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4]
        let graph = AdjacencyList<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 3, to: 4)]).undirected
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }
}
