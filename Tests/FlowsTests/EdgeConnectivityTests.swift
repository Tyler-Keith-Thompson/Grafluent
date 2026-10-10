// `edgeConnectivity()` and `edgeConnectivity(from:to:)` (catalog §EdgeConnectivity): exact; parallel
// edges count, self-loops never; equal to the unit-capacity global cut and maximum flow; by brute
// force the fewest edges leaving a vertex set. Directed rows are `AdjacencyList`, or
// `DirectedPseudograph` when an edge repeats; undirected rows `UndirectedAdjacencyList`, or
// `Pseudograph` with parallel edges; each built by inserting the row's vertices, then its edges in
// order, so positions are the catalog's. In-test checks number vertices by their index in
// `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's
// models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("edgeConnectivity")
struct EdgeConnectivityTests {
    @Test("FL-322 empty graph: 0")
    func fl322() {
        // undirected V []; E []; edgeConnectivity()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
    }

    @Test("FL-325 one vertex: 0")
    func fl325() {
        // undirected V [0]; E []; edgeConnectivity()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
    }

    @Test("FL-328 two isolated vertices: 0")
    func fl328() {
        // undirected V [0, 1]; E []; edgeConnectivity()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-331 two isolated vertices: 0")
    func fl331() {
        // undirected V [0, 1]; E []; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 0)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-334 K(2): κ = n − 1: all but the first vertex: 1")
    func fl334() {
        // K(2); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-337 K(2): κ = n − 1: all but the first vertex: 1")
    func fl337() {
        // K(2); edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-340 K(2) with parallel edges: λ counts copies, κ does not: 3")
    func fl340() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 3)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-343 K(2) with parallel edges: λ counts copies, κ does not: 3")
    func fl343() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-346 self-loops ignored: 1")
    func fl346() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-349 self-loops ignored: 1")
    func fl349() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let lambda = graph.edgeConnectivity(from: 0, to: 2)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 2, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-352 path P(4): 1")
    func fl352() {
        // P(4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-355 path P(4): 1")
    func fl355() {
        // P(4); edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let lambda = graph.edgeConnectivity(from: 0, to: 3)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 3, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-358 path P(4): 1")
    func fl358() {
        // P(4); edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-361 cycle C(5): 2")
    func fl361() {
        // C(5); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 2)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-364 cycle C(5): 2")
    func fl364() {
        // C(5); edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let lambda = graph.edgeConnectivity(from: 0, to: 2)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 2, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-367 K(5): 4")
    func fl367() {
        // K(5); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 4)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-370 K(5): 4")
    func fl370() {
        // K(5); edgeConnectivity(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 4)!
        let lambda = graph.edgeConnectivity(from: 0, to: 4)
        #expect(lambda == 4)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 4, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-373 Kb(3,3): 3")
    func fl373() {
        // Kb(3,3); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 3)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-376 Kb(3,3): 3")
    func fl376() {
        // Kb(3,3); edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-379 Kb(3,3): 3")
    func fl379() {
        // Kb(3,3); edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let lambda = graph.edgeConnectivity(from: 0, to: 3)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 3, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-382 wheel(5): 3")
    func fl382() {
        // wheel(5); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 3)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-385 wheel(5): 3")
    func fl385() {
        // wheel(5); edgeConnectivity(from: 1, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 3)!
        let lambda = graph.edgeConnectivity(from: 1, to: 3)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 1, to: 3, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-388 two triangles sharing a vertex: κ 1, λ 2: 2")
    func fl388() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 2)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-391 two triangles sharing a vertex: κ 1, λ 2: 2")
    func fl391() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; edgeConnectivity(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 4)!
        let lambda = graph.edgeConnectivity(from: 0, to: 4)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 4, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-394 two K(4) joined by two edges: 2")
    func fl394() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 2)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-397 two K(4) joined by two edges: 2")
    func fl397() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; edgeConnectivity(from: 2, to: 6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 2)!
        let t = vertexList.firstIndex(of: 6)!
        let lambda = graph.edgeConnectivity(from: 2, to: 6)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 2, to: 6, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-400 disconnected: 0")
    func fl400() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-403 disconnected: 0")
    func fl403() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let lambda = graph.edgeConnectivity(from: 0, to: 3)
        #expect(lambda == 0)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 3, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-406 Petersen: 3")
    func fl406() {
        // nx(petersen_graph); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 3)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-409 Petersen: 3")
    func fl409() {
        // nx(petersen_graph); edgeConnectivity(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        let lambda = graph.edgeConnectivity(from: 0, to: 7)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 7, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-412 hypercube Q(3): 3")
    func fl412() {
        // Q(3); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 3)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-415 hypercube Q(3): 3")
    func fl415() {
        // Q(3); edgeConnectivity(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        let lambda = graph.edgeConnectivity(from: 0, to: 7)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 7, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-418 grid(3,4): 2")
    func fl418() {
        // grid(3,4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 2)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-421 grid(3,4): 2")
    func fl421() {
        // grid(3,4); edgeConnectivity(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 11)!
        let lambda = graph.edgeConnectivity(from: 0, to: 11)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 11, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] != inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-424 karate club: 1")
    func fl424() {
        // nx(karate_club_graph); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
    }

    @Test("FL-427 karate club: 10")
    func fl427() {
        // nx(karate_club_graph); edgeConnectivity(from: 0, to: 33)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let lambda = graph.edgeConnectivity(from: 0, to: 33)
        #expect(lambda == 10)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 33, capacity: { _ in 1 }))
    }

    @Test("FL-430 directed: one edge: 0")
    func fl430() {
        // V [0, 1]; E [0→1]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-433 directed: one edge: 1")
    func fl433() {
        // V [0, 1]; E [0→1]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-436 directed: one edge: 0")
    func fl436() {
        // V [0, 1]; E [0→1]; edgeConnectivity(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 0)!
        let lambda = graph.edgeConnectivity(from: 1, to: 0)
        #expect(lambda == 0)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 1, to: 0, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-439 directed: two-cycle: 1")
    func fl439() {
        // V [0, 1]; E [0→1, 1→0]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-442 directed: two-cycle: 1")
    func fl442() {
        // V [0, 1]; E [0→1, 1→0]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-445 directed: cycle Cd(4): 1")
    func fl445() {
        // Cd(4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-448 directed: cycle Cd(4): 1")
    func fl448() {
        // Cd(4); edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let lambda = graph.edgeConnectivity(from: 0, to: 2)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 2, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-451 directed: complete Kd(4): 3")
    func fl451() {
        // Kd(4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 3)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-454 directed: complete Kd(4): 3")
    func fl454() {
        // Kd(4); edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let lambda = graph.edgeConnectivity(from: 0, to: 3)
        #expect(lambda == 3)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 3, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-457 directed: adjacent pair counts the edge: 0")
    func fl457() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-460 directed: adjacent pair counts the edge: 2")
    func fl460() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-463 directed: adjacent pair counts the edge: 0")
    func fl463() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeConnectivity(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 0)!
        let lambda = graph.edgeConnectivity(from: 1, to: 0)
        #expect(lambda == 0)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 1, to: 0, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-466 directed: weakly but not strongly connected: 0")
    func fl466() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 0)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-469 directed: weakly but not strongly connected: 0")
    func fl469() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; edgeConnectivity(from: 3, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 3)!
        let t = vertexList.firstIndex(of: 0)!
        let lambda = graph.edgeConnectivity(from: 3, to: 0)
        #expect(lambda == 0)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 3, to: 0, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-472 directed: weakly but not strongly connected: 1")
    func fl472() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let lambda = graph.edgeConnectivity(from: 0, to: 3)
        #expect(lambda == 1)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 3, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-475 directed: bidirected C(5): 2")
    func fl475() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 2)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-478 directed: bidirected C(5): 2")
    func fl478() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let lambda = graph.edgeConnectivity(from: 0, to: 2)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 2, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-481 directed: parallel arcs: 1")
    func fl481() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let lambda = graph.edgeConnectivity()
        #expect(lambda == 1)
        // The minimum cut with unit capacities is one (api.md).
        #expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))
        // Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.
        var best = Int.max
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }

    @Test("FL-484 directed: parallel arcs: 2")
    func fl484() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let lambda = graph.edgeConnectivity(from: 0, to: 1)
        #expect(lambda == 2)
        // The maximum flow with unit capacities (Menger: edge-disjoint paths).
        #expect(lambda == graph.maximumFlowValue(from: 0, to: 1, capacity: { _ in 1 }))
        // Brute force: the fewest edges from a set holding s but not t.
        var best = Int.max
        for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var count = 0
            for (a, b) in ends where a != b {
                if inS[a] && !inS[b] { count += 1 }
            }
            best = min(best, count)
        }
        #expect(lambda == best)
    }
}
