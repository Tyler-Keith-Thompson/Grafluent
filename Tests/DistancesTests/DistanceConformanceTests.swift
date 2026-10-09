// Conformance and representation-independence: `Eccentricities` is `Sendable` when its graph,
// vertices and distances are (sent across a `Task`), holds a copy of the graph (mutating the
// original afterwards changes nothing it answers), and has `DirectedView<Self>` as its graph for an
// undirected graph; the measures work from generic code over `some Graph` and `some DirectedGraph`;
// conformers private to this file without vertex or edge indices (numbering through a dictionary,
// `eccentricity(ofIndex:)` by position in `vertices`) and `Collider` vertices whose hashes all
// collide give the catalog's values. Literals are catalog cells (DI-101 – DI-110, DI-442 – DI-445).
// Case IDs (DI-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Distances
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

/// An undirected pseudograph with no vertex or edge indices, rows in position order (a self-loop
/// twice), so the algorithms number vertices through a dictionary.
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

@Suite("Distances conformance", .tags(.conformance))
struct DistanceConformanceTests {
    @Test("DI-101 Eccentricities is Sendable: computed in a Task on UndirectedAdjacencyList and read outside it")
    func sendable() async {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let eccentricities = await Task { graph.eccentricities() }.value
        let values = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(values == [2, 3, 2, 2, 3])
        // DI-104, DI-105, DI-102, DI-103
        #expect(eccentricities.radius == 2)
        #expect(eccentricities.diameter == 3)
        #expect(eccentricities.center == [1, 3, 4])
        #expect(eccentricities.periphery == [2, 5])
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let sent = requireSendable(eccentricities)
        #expect(sent.diameter == 3)
        let digraph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let directed = await Task { digraph.eccentricities(weight: { Double($0 + 1) }) }.value
        // Computed with ref.py: D(1>2, 1>3, 1>4, 3>4, 3>5, 4>5) with weights 1.0 … 6.0.
        #expect(requireSendable(directed).radius == 7.0)
        #expect(directed.diameter == nil)
    }

    @Test("DI-101 the value holds a copy of the graph: mutating the graph afterwards changes nothing it answers")
    func valueSemantics() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        var graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let eccentricities: Eccentricities<DirectedView<UndirectedAdjacencyList<Int>>, Int> = graph.eccentricities()
        _ = graph.insert(edge: UndirectedEdge(2, 5))
        _ = graph.remove(4)
        _ = graph.insert(9)
        let values = [1, 2, 3, 4, 5].map { eccentricities.eccentricity(of: $0) }
        #expect(values == [2, 3, 2, 2, 3])
        let byIndex = (0 ..< 5).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == [2, 3, 2, 2, 3])
        #expect(eccentricities.radius == 2)
        #expect(eccentricities.diameter == 3)
        #expect(eccentricities.center == [1, 3, 4])
        #expect(eccentricities.periphery == [2, 5])
    }

    @Test("DI-101 – DI-110 from generic code over some Graph, and DI-435 over some DirectedGraph")
    func genericCode() throws {
        func measures<G: Graph>(_ g: G) -> (radius: Int?, diameter: Int?, center: [G.Vertex], periphery: [G.Vertex], centroid: [G.Vertex], wiener: Int?, average: Double?, density: Double, path: Path<G.Vertex, G.Edges.Index>?) {
            (g.radius(), g.diameter(), g.center(), g.periphery(), g.centroid(), g.wienerIndex(), g.averageShortestPathLength(), g.density, g.diameterPath())
        }
        func directedEccentricities<G: DirectedGraph>(_ g: G) -> [Int?] {
            let e = g.eccentricities()
            return g.vertices.map { e.eccentricity(of: $0) }
        }
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let m = measures(graph)
        #expect(m.radius == 2)
        #expect(m.diameter == 3)
        #expect(m.center == [1, 3, 4])
        #expect(m.periphery == [2, 5])
        #expect(m.centroid == [1, 3, 4])
        #expect(m.wiener == 15)
        #expect(m.average == 1.5)
        #expect(m.density == 0.6)
        let path = try #require(m.path)
        #expect(path.vertices == [2, 1, 3, 5])
        #expect(path.edges == [0, 1, 4])
        #expect(directedEccentricities(graph.directed) == [2, 3, 2, 2, 3])
    }

    @Test("DI-101 – DI-110 on a conformer without vertex or edge indices: eccentricity(ofIndex:) is by position in vertices")
    func withoutIndices() throws {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = PlainGraph(vertices: [1, 2, 3, 4, 5], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< 5).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == [2, 3, 2, 2, 3])
        #expect(graph.eccentricity(of: 2) == 3)
        #expect(graph.center() == [1, 3, 4])
        #expect(graph.periphery() == [2, 5])
        #expect(graph.radius() == 2)
        #expect(graph.diameter() == 3)
        #expect(graph.centroid() == [1, 3, 4])
        #expect(graph.wienerIndex() == 15)
        #expect(graph.averageShortestPathLength() == 1.5)
        #expect(graph.density == 0.6)
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [2, 1, 3, 5])
        #expect(path.edges == [0, 1, 4])
        // DI-601, DI-606
        let w = [1, 2, 3, 1, 2, 3]
        let weighted = graph.eccentricities(weight: { w[$0] })
        let weightedByIndex = (0 ..< 5).map { weighted.eccentricity(ofIndex: $0) }
        #expect(weightedByIndex == [4, 5, 3, 4, 5])
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [2, 1, 3, 5])
        #expect(result.path.edges == [0, 1, 4])
        #expect(result.distance == 5)
    }

    @Test("DI-442 – DI-445 on a directed conformer without indices")
    func directedWithoutIndices() {
        // D: [0..9] lcg(10,25,3)
        let pairs: [(Int, Int)] = [
            (9, 3), (5, 8), (4, 3), (3, 2), (6, 9), (8, 5), (7, 6), (5, 6), (1, 6), (5, 4), (9, 4), (1, 9),
            (5, 8), (1, 3), (8, 9), (5, 9), (0, 6), (0, 7), (5, 9), (9, 8), (1, 6), (6, 1), (5, 6), (4, 1),
            (1, 0)
        ]
        let graph = PlainDigraph(vertices: Array(0 ... 9), edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< 10).map { eccentricities.eccentricity(ofIndex: $0) }
        let expected: [Int?] = [4, 3, nil, nil, 4, 4, 3, 4, 5, 4]
        #expect(byIndex == expected)
        #expect(graph.center() == [1, 6])
        #expect(eccentricities.center == [1, 6])
        #expect(graph.diameterPath() == nil)
        #expect(graph.centroid() == [1])
    }

    @Test("DI-101 – DI-110 with Collider vertices whose hashes all collide")
    func colliders() throws {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge(Collider($0.0), Collider($0.1)) })
        let eccentricities = graph.eccentricities()
        let values = (1 ... 5).map { eccentricities.eccentricity(of: Collider($0)) }
        #expect(values == [2, 3, 2, 2, 3])
        #expect(graph.center().map(\.value) == [1, 3, 4])
        #expect(graph.periphery().map(\.value) == [2, 5])
        #expect(graph.centroid().map(\.value) == [1, 3, 4])
        let path = try #require(graph.diameterPath())
        #expect(path.vertices.map(\.value) == [2, 1, 3, 5])
        #expect(path.edges == [0, 1, 4])
    }
}
