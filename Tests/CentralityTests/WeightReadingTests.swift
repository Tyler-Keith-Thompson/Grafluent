// How the closures are read. Closeness, harmonic and betweenness read the weight closure once per
// edge, in position order, before any search (api.md, "Weights" in Closeness and Betweenness): on a
// pseudograph with a loop and parallel copies, on a disconnected graph where the queried vertex
// reaches only part of the edges, on a digraph, on `graph.directed` (each arc once, in the view's
// `edges` order), on `UndirectedAdjacencyList` and on `CompressedSparseRow`. The iterative measures
// convert each weight once per edge (api.md, "Numerical policy"; the order is not specified, so the
// tests compare the sorted positions). The personalization closure is called once per vertex, in
// `vertices` order, before iterating (api.md, PageRank). No closure is called on an edgeless graph.
// Each test records the positions the closure is called with and compares them with the graph's own
// `edges.indices`.

import AdjacencyListModule
import Centrality
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Reading the weight and personalization closures")
struct WeightReadingTests {
    @Test("U(0-0, 0-1, 0-1, 1-2): every weighted entry point reads each edge once; the searches in position order")
    func pseudograph() {
        // U: 0-0, 0-1, 0-1, 1-2
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
        #expect(calls { _ = graph.closenessCentrality(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.closenessCentrality(weight: $0, wfImproved: false) } == order)
        #expect(calls { _ = graph.closenessCentrality(of: 2, weight: $0) } == order)
        #expect(doubleCalls { _ = graph.closenessCentrality(of: 0, weight: $0) } == order)
        #expect(calls { _ = graph.harmonicCentrality(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.harmonicCentrality(weight: $0) } == order)
        #expect(calls { _ = graph.harmonicCentrality(of: 1, weight: $0) } == order)
        #expect(doubleCalls { _ = graph.harmonicCentrality(of: 1, weight: $0) } == order)
        #expect(calls { _ = graph.betweennessCentrality(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.betweennessCentrality(weight: $0, normalized: false, endpoints: true) } == order)
        let eigenvector = doubleCalls { _ = graph.eigenvectorCentrality(weight: $0) }
        #expect(eigenvector.sorted() == order)
        let katz = doubleCalls { _ = graph.katzCentrality(weight: $0, alpha: 0.01) }
        #expect(katz.sorted() == order)
        let pageRank = doubleCalls { _ = graph.pageRank(weight: $0) }
        #expect(pageRank.sorted() == order)
        let personalized = doubleCalls { _ = graph.pageRank(weight: $0, personalization: { _ in 1 }) }
        #expect(personalized.sorted() == order)
    }

    @Test("U(P(0,1,2), 3-4), not connected: the one-vertex forms still read every edge once, in position order")
    func disconnected() {
        // U: P(0,1,2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        func calls(_ run: (_ weight: (Int) -> Int) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return 1 }
            return seen
        }
        let order = Array(graph.edges.indices)
        #expect(calls { _ = graph.closenessCentrality(of: 0, weight: $0) } == order)
        #expect(calls { _ = graph.closenessCentrality(of: 4, weight: $0) } == order)
        #expect(calls { _ = graph.harmonicCentrality(of: 0, weight: $0) } == order)
        #expect(calls { _ = graph.betweennessCentrality(weight: $0) } == order)
    }

    @Test("D(0>1, 1>1, 1>2, 2>0, 0>1): every weighted entry point on a digraph, HITS included")
    func digraph() {
        // D: 0>1, 1>1, 1>2, 2>0, 0>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [2, 1, 3, 1, 4]
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
        #expect(calls { _ = graph.closenessCentrality(weight: $0) } == order)
        #expect(calls { _ = graph.closenessCentrality(of: 0, weight: $0) } == order)
        #expect(doubleCalls { _ = graph.harmonicCentrality(weight: $0) } == order)
        #expect(doubleCalls { _ = graph.harmonicCentrality(of: 2, weight: $0) } == order)
        #expect(calls { _ = graph.betweennessCentrality(weight: $0) } == order)
        let eigenvector = doubleCalls { _ = graph.eigenvectorCentrality(weight: $0) }
        #expect(eigenvector.sorted() == order)
        let katz = doubleCalls { _ = graph.katzCentrality(weight: $0, alpha: 0.01) }
        #expect(katz.sorted() == order)
        let pageRank = doubleCalls { _ = graph.pageRank(weight: $0) }
        #expect(pageRank.sorted() == order)
        let hits = doubleCalls { _ = graph.hits(weight: $0) }
        #expect(hits.sorted() == order)
    }

    @Test("graph.directed: each arc once, in the view's edges order")
    func directedView() {
        // U: 0-1, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = graph.directed
        typealias Arc = DirectedView<ReferencePseudograph<Int>>.Edges.Index
        func calls(_ run: (_ weight: (Arc) -> Int) -> Void) -> [Arc] {
            var seen: [Arc] = []
            run { seen.append($0); return 1 }
            return seen
        }
        func doubleCalls(_ run: (_ weight: (Arc) -> Double) -> Void) -> [Arc] {
            var seen: [Arc] = []
            run { seen.append($0); return 1 }
            return seen
        }
        let order = Array(arcs.edges.indices)
        #expect(order.count == 6)
        #expect(calls { _ = arcs.closenessCentrality(weight: $0) } == order)
        #expect(calls { _ = arcs.harmonicCentrality(of: 0, weight: $0) } == order)
        #expect(calls { _ = arcs.betweennessCentrality(weight: $0) } == order)
        let pageRank = doubleCalls { _ = arcs.pageRank(weight: $0) }
        #expect(pageRank.sorted() == order)
        let hits = doubleCalls { _ = arcs.hits(weight: $0) }
        #expect(hits.sorted() == order)
    }

    @Test("UndirectedAdjacencyList and CompressedSparseRow: in the representation's own position order")
    func representations() {
        // U: P(0,1,2,3), 0-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (0, 2)]
        let list = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        // D: [0..3] 2>3, 0>1, 1>2, 0>2 (CompressedSparseRow numbers them row-major)
        let arcs: [(Int, Int)] = [(2, 3), (0, 1), (1, 2), (0, 2)]
        let csr = CompressedSparseRow(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
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
        let listOrder = Array(list.edges.indices)
        #expect(calls { _ = list.closenessCentrality(weight: $0) } == listOrder)
        #expect(calls { _ = list.harmonicCentrality(of: 3, weight: $0) } == listOrder)
        #expect(calls { _ = list.betweennessCentrality(weight: $0) } == listOrder)
        let listEigenvector = doubleCalls { _ = list.eigenvectorCentrality(weight: $0) }
        #expect(listEigenvector.sorted() == listOrder)
        let csrOrder = Array(csr.edges.indices)
        #expect(calls { _ = csr.closenessCentrality(weight: $0) } == csrOrder)
        #expect(calls { _ = csr.harmonicCentrality(weight: $0) } == csrOrder)
        #expect(calls { _ = csr.betweennessCentrality(weight: $0) } == csrOrder)
        let csrKatz = doubleCalls { _ = csr.katzCentrality(weight: $0) }
        #expect(csrKatz.sorted() == csrOrder)
        let csrHITS = doubleCalls { _ = csr.hits(weight: $0) }
        #expect(csrHITS.sorted() == csrOrder)
    }

    @Test("The personalization closure: once per vertex, in vertices order (not value order), both overloads, Graph and DirectedGraph")
    func personalization() {
        // D: [2, 0, 1] 0>1, 1>2
        let digraph = ReferenceDirectedMultigraph(vertices: [2, 0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        // U: [2, 0, 1] 0-1, 1-2
        let graph = ReferencePseudograph(vertices: [2, 0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        func calls(_ run: (_ personalization: (Int) -> Double) -> Void) -> [Int] {
            var seen: [Int] = []
            run { seen.append($0); return 1 }
            return seen
        }
        let w: [Double] = [1, 2]
        #expect(calls { _ = digraph.pageRank(personalization: $0) } == [2, 0, 1])
        #expect(calls { _ = digraph.pageRank(weight: { w[$0] }, personalization: $0) } == [2, 0, 1])
        #expect(calls { _ = graph.pageRank(dampingFactor: 0.5, personalization: $0) } == [2, 0, 1])
        #expect(calls { _ = graph.pageRank(weight: { w[$0] }, personalization: $0) } == [2, 0, 1])
        #expect(calls { _ = graph.directed.pageRank(personalization: $0) } == [2, 0, 1])
    }

    @Test("No closure is read on an edgeless graph (K₁, three isolated vertices): weights are read per edge")
    func edgeless() {
        let one = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let three = ReferenceDirectedMultigraph<Int>(vertices: 0 ..< 3, edges: [])
        var reads = 0
        _ = one.closenessCentrality(weight: { (_: Int) -> Int in reads += 1; return 1 })
        _ = one.harmonicCentrality(of: 0, weight: { (_: Int) -> Double in reads += 1; return 1 })
        _ = one.betweennessCentrality(weight: { (_: Int) -> Int in reads += 1; return 1 })
        _ = one.eigenvectorCentrality(weight: { (_: Int) -> Double in reads += 1; return 1 })
        _ = three.katzCentrality(weight: { (_: Int) -> Double in reads += 1; return 1 })
        _ = three.pageRank(weight: { (_: Int) -> Double in reads += 1; return 1 })
        _ = three.hits(weight: { (_: Int) -> Double in reads += 1; return 1 })
        #expect(reads == 0)
    }
}
