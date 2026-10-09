// How the weight closure is read (api.md, "Weights"): once per edge, in position order, before any
// search, by every weighted entry point: on a pseudograph with a loop and parallel copies (DI-501's
// graph), on a disconnected graph where the first search already decides the answer (DI-301's
// graph: still every edge is read), on a digraph, on `graph.directed` (each arc once, in the
// view's `edges` order), on `UndirectedAdjacencyList` and on `CompressedSparseRow`; never on K₁ or
// an edgeless graph (DI-023, DI-024). Each test records the positions the closure is called with
// and compares them with the graph's own `edges.indices`. Case IDs (DI-nnn) refer to the catalog;
// see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Distances
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Reading the weight closure")
struct WeightReadingTests {
    @Test("DI-501's graph U(0-0, 0-1, 0-1, 1-2): every weighted entry point calls the closure once per edge, in position order")
    func pseudograph() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [3, 1, 2, 5]
        func calls(_ run: (_ weight: (Int) -> Int) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return w[$0] }
            return seen
        }
        func doubleCalls(_ run: (_ weight: (Int) -> Double) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return Double(w[$0]) }
            return seen
        }
        let order = Array(graph.edges.indices)
        #expect(order == [0, 1, 2, 3])
        #expect(calls { _ = graph.eccentricities(weight: $0) } == order)
        #expect(calls { _ = graph.eccentricity(of: 2, weight: $0) } == order)
        #expect(calls { _ = graph.radius(weight: $0) } == order)
        #expect(calls { _ = graph.diameter(weight: $0) } == order)
        #expect(calls { _ = graph.center(weight: $0) } == order)
        #expect(calls { _ = graph.periphery(weight: $0) } == order)
        #expect(calls { _ = graph.diameterPath(weight: $0) } == order)
        #expect(calls { _ = graph.centroid(weight: $0) } == order)
        #expect(calls { _ = graph.wienerIndex(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.averageShortestPathLength(weight: $0) } == order)
    }

    @Test("DI-301's graph U(P(0..2), 3-4), not connected: every edge is still read once, in position order, by every weighted entry point")
    func disconnected() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        func calls(_ run: (_ weight: (Int) -> Int) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return 1 }
            return seen
        }
        func doubleCalls(_ run: (_ weight: (Int) -> Double) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return 1 }
            return seen
        }
        let order = [0, 1, 2]
        #expect(calls { _ = graph.eccentricities(weight: $0) } == order)
        #expect(calls { _ = graph.eccentricity(of: 0, weight: $0) } == order)
        #expect(calls { _ = graph.radius(weight: $0) } == order)
        #expect(calls { _ = graph.diameter(weight: $0) } == order)
        #expect(calls { _ = graph.center(weight: $0) } == order)
        #expect(calls { _ = graph.periphery(weight: $0) } == order)
        #expect(calls { _ = graph.diameterPath(weight: $0) } == order)
        #expect(calls { _ = graph.centroid(weight: $0) } == order)
        #expect(calls { _ = graph.wienerIndex(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.averageShortestPathLength(weight: $0) } == order)
    }

    @Test("DI-620's digraph D(C(0..2), 0>2): every weighted entry point calls the closure once per arc, in position order")
    func digraph() {
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 1, 1, 5]
        func calls(_ run: (_ weight: (Int) -> Int) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return w[$0] }
            return seen
        }
        func doubleCalls(_ run: (_ weight: (Int) -> Double) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return Double(w[$0]) }
            return seen
        }
        let order = [0, 1, 2, 3]
        #expect(calls { _ = graph.eccentricities(weight: $0) } == order)
        #expect(calls { _ = graph.eccentricity(of: 1, weight: $0) } == order)
        #expect(calls { _ = graph.radius(weight: $0) } == order)
        #expect(calls { _ = graph.diameter(weight: $0) } == order)
        #expect(calls { _ = graph.center(weight: $0) } == order)
        #expect(calls { _ = graph.periphery(weight: $0) } == order)
        #expect(calls { _ = graph.diameterPath(weight: $0) } == order)
        #expect(calls { _ = graph.centroid(weight: $0) } == order)
        #expect(calls { _ = graph.wienerIndex(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.averageShortestPathLength(weight: $0) } == order)
    }

    @Test("graph.directed reads each arc once, in the view's edges order (u→v, then v→u, edge by edge)")
    func directedView() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        typealias Arc = DirectedView<ReferencePseudograph<Int>>.Edges.Index
        func calls(_ run: (_ weight: (Arc) -> Int) -> Void) -> [Arc] {
            var seen: [Arc] = []
            run { seen.append($0); return 1 }
            return seen
        }
        let order = Array(view.edges.indices)
        #expect(order.count == 8)
        #expect(calls { _ = view.eccentricities(weight: $0) } == order)
        #expect(calls { _ = view.diameter(weight: $0) } == order)
        #expect(calls { _ = view.diameterPath(weight: $0) } == order)
        #expect(calls { _ = view.wienerIndex(weight: $0) } == order)
    }

    @Test("UndirectedAdjacencyList and CompressedSparseRow: the closure once per edge, in each representation's position order")
    func representations() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var seen: [Int] = []
        _ = graph.eccentricities(weight: { seen.append($0); return 1 })
        #expect(seen == Array(graph.edges.indices))
        seen = []
        _ = graph.diameter(weight: { seen.append($0); return 1 })
        #expect(seen == Array(graph.edges.indices))
        // D: [0..9] arcs in row-major order
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (2, 3), (3, 1), (5, 9), (9, 5)]
        let csr = CompressedSparseRow(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        seen = []
        _ = csr.eccentricities(weight: { seen.append($0); return 1 })
        #expect(seen == Array(csr.edges.indices))
        seen = []
        _ = csr.diameter(weight: { seen.append($0); return 1 })
        #expect(seen == Array(csr.edges.indices))
    }

    @Test("DI-023 DI-024 K₁ and an edgeless graph never call the closure, in any weighted entry point")
    func neverCalledWithoutEdges() {
        let single = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let isolated = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [])
        let digraph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1], edges: [])
        let empty = ReferencePseudograph<Int>(vertices: [], edges: [])
        var count = 0
        let weight = { (_: Int) -> Int in
            count += 1
            return 1
        }
        let doubleWeight = { (_: Int) -> Double in
            count += 1
            return 1
        }
        for graph in [single, isolated, empty] {
            _ = graph.eccentricities(weight: weight)
            _ = graph.radius(weight: weight)
            _ = graph.diameter(weight: weight)
            _ = graph.center(weight: weight)
            _ = graph.periphery(weight: weight)
            _ = graph.diameterPath(weight: weight)
            _ = graph.centroid(weight: weight)
            _ = graph.wienerIndex(weight: weight)
            _ = graph.averageShortestPathLength(weight: doubleWeight)
            if let v = graph.vertices.first { _ = graph.eccentricity(of: v, weight: weight) }
        }
        _ = digraph.eccentricities(weight: weight)
        _ = digraph.diameter(weight: weight)
        _ = digraph.eccentricity(of: 1, weight: weight)
        #expect(count == 0)
        // DI-023, DI-024: K₁'s answers.
        #expect(single.center(weight: weight) == [0])
        let path = single.diameterPath(weight: weight)
        #expect(path?.path.vertices == [0])
        #expect(path?.path.edges == [])
        #expect(path?.distance == 0)
        #expect(count == 0)
    }
}
