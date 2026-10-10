// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirected` (each edge an arc as written) and
// `AdjacencyMatrix.undirected`. CompressedSparseRow and AdjacencyMatrix number edges by row-major
// cell, so there each catalog edge's position is looked up, a cut's edges are listed in that order,
// and Edmonds–Karp's flow (which follows positions) was recomputed by swiftgen.py with ref.py's
// model on those positions. Everything else is the catalog's. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members. Rows
/// are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("gomoryHuTree on every representation")
struct GomoryHuTreeRepresentationTests {
    @Test("FL-258 empty graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl258() {
        // undirected V []; E []; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-259 one vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl259() throws {
        // undirected V [0]; E []; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [] as [Int]
            let treeCapacities: [Int] = []
            for k in 0 ..< 0 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
            _ = (parents, treeCapacities)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [] as [Int]
            let treeCapacities: [Int] = []
            for k in 0 ..< 0 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
            _ = (parents, treeCapacities)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [] as [Int]
            let treeCapacities: [Int] = []
            for k in 0 ..< 0 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
            _ = (parents, treeCapacities)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [] as [Int]
            let treeCapacities: [Int] = []
            for k in 0 ..< 0 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
            _ = (parents, treeCapacities)
        }
    }

    @Test("FL-260 two vertices, on ReferencePseudograph, no indices")
    func fl260() throws {
        // undirected V [0, 1]; E [0–1 2, 0–1 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let capacities: [Int] = [2, 3]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0] as [Int]
            let treeCapacities: [Int] = [5]
            for k in 0 ..< 1 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0] as [Int]
            let treeCapacities: [Int] = [5]
            for k in 0 ..< 1 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-261 disconnected: zero edges join the pieces, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl261() throws {
        // undirected V [0, 1, 2]; E [1–2 4]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(1, 2)]
        let capacities: [Int] = [4]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [4, 0]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [4, 0]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [4, 0]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [4, 0]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-262 path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl262() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 1–2 1, 2–3 2]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [3, 1, 2]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1, 2] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1, 2] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1, 2] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1, 2] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-263 star, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl263() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 0–2 1, 0–3 2]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let capacities: [Int] = [3, 1, 2]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [Int] = [3, 1, 2]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-264 triangle, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl264() throws {
        // undirected V [0, 1, 2]; E [0–1 1, 1–2 2, 0–2 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [Int] = [1, 2, 3]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [3, 4]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [3, 4]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [3, 4]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0] as [Int]
            let treeCapacities: [Int] = [3, 4]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-265 K(4), unit, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl265() throws {
        // K(4); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [3, 3, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [3, 3, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [3, 3, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [3, 3, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-266 cycle C(5), unit, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl266() throws {
        // C(5); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let capacities: [Int] = [1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 4, 4, 0] as [Int]
            let treeCapacities: [Int] = [2, 2, 2, 2]
            for k in 0 ..< 4 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 4, 4, 0] as [Int]
            let treeCapacities: [Int] = [2, 2, 2, 2]
            for k in 0 ..< 4 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 4, 4, 0] as [Int]
            let treeCapacities: [Int] = [2, 2, 2, 2]
            for k in 0 ..< 4 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 4, 4, 0] as [Int]
            let treeCapacities: [Int] = [2, 2, 2, 2]
            for k in 0 ..< 4 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-267 Wikipedia Gomory–Hu graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl267() throws {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 0, 4, 2, 3] as [Int]
            let treeCapacities: [Int] = [7, 8, 6, 6, 8]
            for k in 0 ..< 5 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 0, 4, 2, 3] as [Int]
            let treeCapacities: [Int] = [7, 8, 6, 6, 8]
            for k in 0 ..< 5 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 0, 4, 2, 3] as [Int]
            let treeCapacities: [Int] = [7, 8, 6, 6, 8]
            for k in 0 ..< 5 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 0, 4, 2, 3] as [Int]
            let treeCapacities: [Int] = [7, 8, 6, 6, 8]
            for k in 0 ..< 5 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-268 Stoer–Wagner paper graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl268() throws {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [5, 2, 3, 1, 5, 4, 7] as [Int]
            let treeCapacities: [Int] = [7, 4, 7, 5, 6, 7, 5]
            for k in 0 ..< 7 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [5, 2, 3, 1, 5, 4, 7] as [Int]
            let treeCapacities: [Int] = [7, 4, 7, 5, 6, 7, 5]
            for k in 0 ..< 7 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [5, 2, 3, 1, 5, 4, 7] as [Int]
            let treeCapacities: [Int] = [7, 4, 7, 5, 6, 7, 5]
            for k in 0 ..< 7 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 4), (1, 5), (2, 3), (2, 6), (3, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 1, 2, 0, 4, 3, 6] as [Int]
            let treeCapacities: [Int] = [7, 4, 7, 5, 6, 7, 5]
            for k in 0 ..< 7 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-269 igraph example: triangle with a pendant, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl269() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 1, 1–2 1, 2–0 1, 2–3 1]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0, 2] as [Int]
            let treeCapacities: [Int] = [2, 2, 1]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0, 2] as [Int]
            let treeCapacities: [Int] = [2, 2, 1]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0, 2] as [Int]
            let treeCapacities: [Int] = [2, 2, 1]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [2, 0, 2] as [Int]
            let treeCapacities: [Int] = [2, 2, 1]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-270 labels, not indices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl270() throws {
        // undirected V [d, b, a, c]; E [a–b 1, b–c 2, c–d 3, d–a 4, a–c 5]; gomoryHuTree(capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "a"), ("a", "c")]
        let capacities: [Int] = [1, 2, 3, 4, 5]
        do { // Pseudograph
            let graph = Pseudograph<String>(vertices: ["d", "b", "a", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = ["d", "b", "a", "c"] as [String]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = ["c", "d", "a"] as [String]
            let treeCapacities: [Int] = [3, 7, 9]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<String>(vertices: ["d", "b", "a", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = ["d", "b", "a", "c"] as [String]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = ["c", "d", "a"] as [String]
            let treeCapacities: [Int] = [3, 7, 9]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<String>(vertices: ["d", "b", "a", "c"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = ["d", "b", "a", "c"] as [String]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = ["c", "d", "a"] as [String]
            let treeCapacities: [Int] = [3, 7, 9]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 1), (1, 3), (3, 0), (0, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [3, 0, 2] as [Int]
            let treeCapacities: [Int] = [3, 7, 9]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-271 self-loop and parallel edges, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl271() throws {
        // undirected V [0, 1, 2]; E [0–0 5, 0–1 1, 1–0 1, 1–2 3]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0), (1, 2)]
        let capacities: [Int] = [5, 1, 1, 3]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [2, 3]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [2, 3]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [2, 3]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [2, 3]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-272 lcgund(9,20,10,9), on ReferencePseudograph, no indices")
    func fl272() throws {
        // lcgund(9,20,10,9); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(5, 1), (1, 0), (7, 4), (4, 7), (7, 6), (7, 2), (5, 3), (1, 5), (1, 6), (4, 0), (6, 2), (8, 5), (5, 6), (3, 2), (5, 2), (3, 1), (6, 7), (8, 0), (4, 1), (5, 6)]
        let capacities: [Int] = [3, 2, 2, 7, 9, 8, 3, 1, 6, 9, 4, 5, 8, 2, 7, 7, 9, 7, 7, 8]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [6, 6, 1, 0, 6, 4, 6, 0] as [Int]
            let treeCapacities: [Int] = [24, 21, 12, 16, 35, 23, 35, 12]
            for k in 0 ..< 8 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [6, 6, 1, 0, 6, 4, 6, 0] as [Int]
            let treeCapacities: [Int] = [24, 21, 12, 16, 35, 23, 35, 12]
            for k in 0 ..< 8 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-273 Petersen, unit, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl273() throws {
        // nx(petersen_graph); gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [9, 9, 9, 9, 9, 9, 9, 9, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3]
            for k in 0 ..< 9 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [9, 9, 9, 9, 9, 9, 9, 9, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3]
            for k in 0 ..< 9 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [9, 9, 9, 9, 9, 9, 9, 9, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3]
            for k in 0 ..< 9 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [9, 9, 9, 9, 9, 9, 9, 9, 0] as [Int]
            let treeCapacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3]
            for k in 0 ..< 9 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-495 UInt8, every vertex within 255, on ReferencePseudograph, no indices")
    func fl495() throws {
        // UInt8 undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [1–5 5, 2–3 16, 4–7 21, 4–0 3, 3–7 39, 6–3 33, 6–0 43, 2–0 46, 5–0 1, 6–2 39, 2–6 119, 6–1 12, 0–7 33, 7–2 20, 0–4 66, 4–5 24, 1–3 42, 5–1 10, 7–3 40,…
        let pairs: [(Int, Int)] = [(1, 5), (2, 3), (4, 7), (4, 0), (3, 7), (6, 3), (6, 0), (2, 0), (5, 0), (6, 2), (2, 6), (6, 1), (0, 7), (7, 2), (0, 4), (4, 5), (1, 3), (5, 1), (7, 3), (1, 4), (4, 7), (4, 1), (3, 0), (3, 0), (6, 3), (3, 6), (2, 3)]
        let capacities: [UInt8] = [5, 16, 21, 3, 39, 33, 43, 46, 1, 39, 119, 12, 33, 20, 66, 24, 42, 10, 40, 22, 50, 20, 20, 12, 8, 1, 7]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 6, 0, 0, 4, 0, 0] as [Int]
            let treeCapacities: [UInt8] = [111, 247, 218, 195, 40, 186, 203]
            for k in 0 ..< 7 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [4, 6, 0, 0, 4, 0, 0] as [Int]
            let treeCapacities: [UInt8] = [111, 247, 218, 195, 40, 186, 203]
            for k in 0 ..< 7 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-496 UInt8 star, the centre's sum past 255, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl496() throws {
        // UInt8 undirected V [0, 1, 2, 3]; E [0–1 200, 0–2 200, 0–3 200]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let capacities: [UInt8] = [200, 200, 200]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [UInt8] = [200, 200, 200]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [UInt8] = [200, 200, 200]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [UInt8] = [200, 200, 200]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2, 3] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 0, 0] as [Int]
            let treeCapacities: [UInt8] = [200, 200, 200]
            for k in 0 ..< 3 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }

    @Test("FL-527 Int.max path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl527() throws {
        // undirected V [0, 1, 2]; E [0–1 9223372036854775807, 1–2 9223372036854775807]; gomoryHuTree(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [9223372036854775807, 9223372036854775807]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [9223372036854775807, 9223372036854775807]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.gomoryHuTree(capacity: { capacities[$0] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [9223372036854775807, 9223372036854775807]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.gomoryHuTree(capacity: { capacities[edgeOf[$0]!] })
            let gomoryHu = try #require(result)
            let vertexList = [0, 1, 2] as [Int]
            #expect(Array(gomoryHu.tree.vertices) == vertexList)
            let parents = [0, 1] as [Int]
            let treeCapacities: [Int] = [9223372036854775807, 9223372036854775807]
            for k in 0 ..< 2 {
                let edge = gomoryHu.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), "tree edge \(k)")
                #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], "tree edge \(k)")
            }
        }
    }
}
