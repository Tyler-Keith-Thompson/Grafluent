// `maximumFlowValue(from:to:capacity:)` (catalog §MaximumFlowValue): the value exactly (within 1e-12
// on rows whose capacities are not dyadic), equal to `maximumFlow`'s and the minimum cut's. Directed
// rows are `AdjacencyList`, or `DirectedPseudograph` when an edge repeats; undirected rows
// `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each built by inserting the row's
// vertices, then its edges in order, so positions are the catalog's. In-test checks number vertices
// by their index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row
// with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("maximumFlowValue(from:to:capacity:)")
struct MaximumFlowValueTests {
    @Test("FL-004 one edge: 5")
    func fl004() {
        // V [0, 1]; E [0→1 5]; maximumFlowValue(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 5)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] }).value)
    }

    @Test("FL-009 no edge: value 0, the sink alone on its side: 0")
    func fl009() {
        // V [0, 1]; E []; maximumFlowValue(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 0)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] }).value)
    }

    @Test("FL-014 no path: edge into the source only: 0")
    func fl014() {
        // V [0, 1]; E [1→0 5]; maximumFlowValue(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(1, 0)]
        let capacities: [Int] = [5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 0)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] }).value)
    }

    @Test("FL-019 no path: disconnected: 0")
    func fl019() {
        // V [0, 1, 2, 3]; E [0→1 4, 2→3 4]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let capacities: [Int] = [4, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 0)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-024 zero capacity: a zero edge still crosses the cut: 0")
    func fl024() {
        // V [0, 1]; E [0→1 0]; maximumFlowValue(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [0]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 0)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] }).value)
    }

    @Test("FL-029 zero capacities on the only path: 0")
    func fl029() {
        // V [0, 1, 2]; E [0→1 3, 1→2 0]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [3, 0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 0)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-034 path: the first bottleneck from the sink: every edge is a minimum cut; the one nearest t: 2")
    func fl034() {
        // V [0, 1, 2, 3]; E [0→1 2, 1→2 2, 2→3 2]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [2, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-039 path with a later bottleneck: 1")
    func fl039() {
        // V [0, 1, 2, 3]; E [0→1 1, 1→2 3, 2→3 2]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [1, 3, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 1)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-044 source and sink not first and last: 2")
    func fl044() {
        // V [a, t, s]; E [s→a 2, a→t 3]; maximumFlowValue(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t")]
        let capacities: [Int] = [2, 3]
        let graph = AdjacencyList<String>(vertices: ["a", "t", "s"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "t", "s"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "s", to: "t", capacity: { capacities[$0] }).value)
    }

    @Test("FL-049 isolated extra vertex: unreachable vertices sit on the source side: 3")
    func fl049() {
        // V [0, 1, 2]; E [0→2 3]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 2)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 3)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-054 vertex reaching only the sink: 1 can reach t: sink side: 3")
    func fl054() {
        // V [0, 1, 2]; E [0→2 3, 1→2 9]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let capacities: [Int] = [3, 9]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 3)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-059 dead end off the source: 3")
    func fl059() {
        // V [0, 1, 2]; E [0→1 7, 0→2 3]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let capacities: [Int] = [7, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 3)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-064 self-loop ignored: loops carry no flow, never cross: 4")
    func fl064() {
        // V [0, 1]; E [0→0 9, 0→1 4, 1→1 9]; maximumFlowValue(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let capacities: [Int] = [9, 4, 9]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 4)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 1, capacity: { capacities[$0] }).value)
    }

    @Test("FL-069 parallel edges add: 5")
    func fl069() {
        // V [0, 1, 2]; E [0→1 2, 0→1 3, 1→2 1, 1→2 9]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (1, 2)]
        let capacities: [Int] = [2, 3, 1, 9]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 5)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-074 antiparallel pair: each arc its own reverse: 4")
    func fl074() {
        // V [0, 1, 2]; E [0→1 5, 1→0 3, 1→2 4]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let capacities: [Int] = [5, 3, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 4)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-079 antiparallel pair on the path: 6")
    func fl079() {
        // V [0, 1, 2, 3]; E [0→1 3, 0→2 3, 1→2 2, 2→1 2, 1→3 1, 2→3 5]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 2, 2, 1, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 6)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-084 edge into the source and out of the sink: 2")
    func fl084() {
        // V [0, 1, 2]; E [1→0 4, 0→1 3, 2→1 6, 1→2 2, 2→0 8]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(1, 0), (0, 1), (2, 1), (1, 2), (2, 0)]
        let capacities: [Int] = [4, 3, 6, 2, 8]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-089 CLRS figure 26.1: value 23: 23")
    func fl089() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; maximumFlowValue(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 23)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "s", to: "t", capacity: { capacities[$0] }).value)
    }

    @Test("FL-094 CLRS 2nd ed., with v1⇄v2: 23")
    func fl094() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v2 10, v2→v1 4, v1→v3 12, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; maximumFlowValue(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v2"), ("v2", "v1"), ("v1", "v3"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 10, 4, 12, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 23)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "s", to: "t", capacity: { capacities[$0] }).value)
    }

    @Test("FL-099 Ford–Fulkerson's slow case: Edmonds–Karp needs two augmentations: 2000")
    func fl099() {
        // V [s, a, b, t]; E [s→a 1000, s→b 1000, a→b 1, a→t 1000, b→t 1000]; maximumFlowValue(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("a", "b"), ("a", "t"), ("b", "t")]
        let capacities: [Int] = [1000, 1000, 1, 1000, 1000]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "b", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2000)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "s", to: "t", capacity: { capacities[$0] }).value)
    }

    @Test("FL-104 NetworkX docs example: 3.0")
    func fl104() {
        // Double V [x, a, b, c, d, e, y]; E [x→a 3.0, x→b 1.0, a→c 3.0, b→c 5.0, b→d 4.0, d→e 2.0, c→y 2.0, e→y 3.0]; maximumFlowValue(from: x, to: y, capacity:)
        let pairs: [(String, String)] = [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")]
        let capacities: [Double] = [3.0, 1.0, 3.0, 5.0, 4.0, 2.0, 2.0, 3.0]
        let graph = AdjacencyList<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["x", "a", "b", "c", "d", "e", "y"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "x", to: "y") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 3.0)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "x", to: "y", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "x", to: "y", capacity: { capacities[$0] }).value)
    }

    @Test("FL-109 diamond, two equal cuts: 2")
    func fl109() {
        // V [0, 1, 2, 3]; E [0→1 1, 0→2 1, 1→3 1, 2→3 1]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-114 cut not at either end: 2")
    func fl114() {
        // V [0, 1, 2, 3, 4, 5]; E [0→1 5, 0→2 5, 1→3 1, 2→4 1, 3→5 5, 4→5 5, 1→2 3]; maximumFlowValue(from: 0, to: 5, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (1, 2)]
        let capacities: [Int] = [5, 5, 1, 1, 5, 5, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 5) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 5, capacity: { capacities[$0] }).value)
    }

    @Test("FL-119 bipartite matching as flow: 3")
    func fl119() {
        // V [s, a, b, c, x, y, z, t]; E [s→a 1, s→b 1, s→c 1, a→x 1, a→y 1, b→x 1, c→x 1, c→z 1, x→t 1, y→t 1, z→t 1]; maximumFlowValue(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("s", "c"), ("a", "x"), ("a", "y"), ("b", "x"), ("c", "x"), ("c", "z"), ("x", "t"), ("y", "t"), ("z", "t")]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "b", "c", "x", "y", "z", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "b", "c", "x", "y", "z", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 3)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "s", to: "t", capacity: { capacities[$0] }).value)
    }

    @Test("FL-124 lcgnet(8,20,8,9): 13")
    func fl124() {
        // lcgnet(8,20,8,9); maximumFlowValue(from: 0, to: 7, capacity:)
        let pairs: [(Int, Int)] = [(4, 0), (3, 6), (2, 3), (5, 7), (6, 3), (0, 6), (6, 0), (1, 4), (5, 6), (3, 6), (0, 4), (2, 1), (0, 7), (1, 3), (5, 2), (6, 5), (0, 5), (0, 7), (0, 5), (3, 1)]
        let capacities: [Int] = [6, 6, 2, 2, 5, 6, 3, 5, 5, 7, 1, 5, 9, 9, 3, 4, 2, 2, 3, 1]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 7) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 13)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 7, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 7, capacity: { capacities[$0] }).value)
    }

    @Test("FL-129 lcgnet(10,30,10,20): 29")
    func fl129() {
        // lcgnet(10,30,10,20); maximumFlowValue(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(9, 2), (9, 5), (5, 7), (5, 9), (2, 6), (0, 8), (1, 3), (8, 7), (4, 5), (0, 9), (4, 9), (7, 5), (0, 1), (9, 2), (3, 2), (4, 5), (6, 5), (2, 6), (7, 6), (0, 5), (5, 6), (1, 9), (5, 0), (6, 2), (1, 5), (8, 1), (2, 4), (4, 6), (6, 0), (3, 0)]
        let capacities: [Int] = [4, 16, 7, 10, 8, 7, 3, 5, 12, 12, 5, 6, 12, 19, 18, 6, 19, 20, 10, 5, 5, 2, 13, 10, 2, 19, 8, 17, 1, 14]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 29)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 9, capacity: { capacities[$0] }).value)
    }

    @Test("FL-134 lcgnet(12,40,3,5): 5")
    func fl134() {
        // lcgnet(12,40,3,5); maximumFlowValue(from: 0, to: 11, capacity:)
        let pairs: [(Int, Int)] = [(11, 7), (10, 0), (7, 5), (9, 7), (8, 9), (5, 3), (7, 8), (10, 11), (5, 11), (7, 1), (1, 6), (7, 5), (9, 3), (9, 0), (0, 5), (2, 5), (1, 5), (5, 11), (8, 5), (2, 1), (11, 3), (1, 11), (0, 6), (2, 9), (7, 3), (3, 9), (9, 3), (0, 9), (10, 4), (9, 11), (2, 11), (3, 9), (2, 10), (4, 9), (9, 4), (5, 0), (8, 5), (11, 9), (11, 1), (11, 3)]
        let capacities: [Int] = [1, 4, 5, 3, 4, 5, 1, 2, 4, 5, 2, 4, 4, 2, 1, 2, 2, 2, 2, 1, 2, 5, 5, 1, 4, 5, 5, 4, 5, 1, 1, 4, 1, 1, 2, 5, 2, 1, 4, 2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 11) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 5)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 11, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 11, capacity: { capacities[$0] }).value)
    }

    @Test("FL-139 lcgnet(16,60,4,100): 139")
    func fl139() {
        // lcgnet(16,60,4,100); maximumFlowValue(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(10, 12), (11, 1), (1, 5), (8, 15), (14, 8), (7, 12), (0, 10), (7, 10), (13, 0), (13, 11), (3, 8), (8, 6), (1, 2), (2, 14), (5, 13), (15, 10), (0, 6), (3, 4), (12, 10), (10, 5), (4, 13), (5, 1), (3, 5), (5, 6), (12, 7), (8, 7), (0, 14), (13, 12), (2, 8), (0, 10), (14, 12), (4, 12), (12, 15), (11, 1), (9, 12), (5, 2), (13, 2), (8, 15), (14, 8), (8, 15), (9, 8), (15, 1), (11, 2), (13, 9), (8, 14), (15, 8), (11, 12), (8, 7), (14, 12), (9, 11), (12, 3), (5, 8), (13, 11), (12, 13), (9, 6), (12, 5), (1, 3), (14, 9), (10, 6), (5, 10)]
        let capacities: [Int] = [75, 8, 15, 15, 92, 98, 59, 79, 47, 1, 30, 36, 69, 55, 21, 4, 48, 32, 64, 42, 80, 45, 38, 70, 69, 63, 22, 30, 50, 89, 90, 37, 94, 80, 16, 2, 57, 12, 80, 46, 48, 22, 80, 23, 76, 61, 20, 2, 69, 62, 82, 44, 74, 52, 49, 62, 86, 76, 80, 62]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 15) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 139)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 15, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 15, capacity: { capacities[$0] }).value)
    }

    @Test("FL-142 lcgnet(30,150,5,50): 32")
    func fl142() {
        // lcgnet(30,150,5,50); maximumFlowValue(from: 0, to: 29, capacity:)
        let pairs: [(Int, Int)] = [(22, 23), (11, 29), (20, 24), (24, 18), (3, 17), (3, 22), (10, 4), (12, 21), (1, 24), (19, 20), (5, 3), (23, 15), (20, 11), (18, 10), (10, 0), (16, 8), (2, 20), (6, 0), (1, 7), (12, 21), (4, 16), (28, 2), (15, 29), (22, 28), (1, 22), (11, 28), (4, 25), (1, 7), (27, 22), (27, 28), (24, 25), (21, 17), (16, 5), (23, 19), (17, 3), (24, 5), (3, 27), (23, 1), (29, 15), (8, 23), (24, 13), (2, 13), (6, 19), (2, 28), (7, 17), (15, 24), (19, 15), (25, 10), (26, 0), (13, 29), (12, 14), (18, 13), (18, 21), (7, 27), (16, 9), (2, 7), (13, 12), (5, 19), (15, 5), (3, 4), (29, 12), (9, 2), (17, 23), (14, 23), (7, 28), (16, 17), (5, 27), (12, 29), (15, 8), (10, 19), (4, 18), (1, 11), (4, 2), (5, 20), (12, 14), (16, 4), (5, 13), (9, 1), (27, 2), (1, 0), (24, 7), (1, 14), (18, 11), (8, 0), (12, 16), (26, 24), (8, 4), (6, 7), (18, 13), (25, 14), (29, 16), (5, 22), (15, 20), (14, 20), (29, 15), (14, 28), (23, 17), (11, 5), (16, 2), (16, 2), (22, 10), (2, 9), (29, 3), (15, 16), (12, 5), (6, 19), (24, 26), (4, 21), (2, 17), (29, 5), (28, 10), (9, 10), (10, 21), (2, 22), (5, 13), (1, 15), (19, 26), (24, 2), (7, 28), (0, 12), (3, 5), (11, 23), (17, 7), (7, 11), (1, 12), (17, 9), (0, 21), (27, 29), (5, 13), (5, 28), (18, 23), (5, 14), (16, 13), (24, 18), (17, 22), (6, 1), (2, 7), (12, 17), (14, 6), (23, 12), (7, 1), (15, 6), (10, 29), (3, 29), (9, 7), (19, 15), (13, 7), (26, 9), (0, 25), (1, 3)]
        let capacities: [Int] = [35, 10, 6, 22, 19, 41, 29, 15, 20, 40, 16, 40, 15, 35, 5, 25, 18, 1, 42, 26, 22, 41, 12, 20, 43, 31, 18, 2, 43, 17, 9, 15, 2, 11, 45, 9, 49, 26, 24, 13, 6, 4, 25, 3, 13, 8, 41, 3, 20, 35, 22, 40, 33, 5, 44, 32, 22, 15, 13, 32, 41, 34, 31, 3, 28, 17, 12, 6, 48, 45, 42, 37, 41, 26, 20, 2, 19, 31, 17, 46, 20, 20, 46, 28, 46, 20, 11, 27, 8, 16, 4, 9, 47, 27, 19, 10, 28, 27, 36, 43, 18, 11, 47, 22, 48, 49, 48, 18, 22, 44, 17, 28, 5, 49, 25, 6, 13, 37, 44, 7, 6, 44, 18, 3, 49, 48, 6, 17, 42, 32, 3, 40, 45, 48, 35, 20, 22, 49, 48, 47, 42, 48, 47, 29, 42, 48, 13, 7, 24, 25]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 29) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 32)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 29, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 29, capacity: { capacities[$0] }).value)
    }

    @Test("FL-145 lcgnet(30,150,5,50) reversed ends: 100")
    func fl145() {
        // lcgnet(30,150,5,50); maximumFlowValue(from: 29, to: 0, capacity:)
        let pairs: [(Int, Int)] = [(22, 23), (11, 29), (20, 24), (24, 18), (3, 17), (3, 22), (10, 4), (12, 21), (1, 24), (19, 20), (5, 3), (23, 15), (20, 11), (18, 10), (10, 0), (16, 8), (2, 20), (6, 0), (1, 7), (12, 21), (4, 16), (28, 2), (15, 29), (22, 28), (1, 22), (11, 28), (4, 25), (1, 7), (27, 22), (27, 28), (24, 25), (21, 17), (16, 5), (23, 19), (17, 3), (24, 5), (3, 27), (23, 1), (29, 15), (8, 23), (24, 13), (2, 13), (6, 19), (2, 28), (7, 17), (15, 24), (19, 15), (25, 10), (26, 0), (13, 29), (12, 14), (18, 13), (18, 21), (7, 27), (16, 9), (2, 7), (13, 12), (5, 19), (15, 5), (3, 4), (29, 12), (9, 2), (17, 23), (14, 23), (7, 28), (16, 17), (5, 27), (12, 29), (15, 8), (10, 19), (4, 18), (1, 11), (4, 2), (5, 20), (12, 14), (16, 4), (5, 13), (9, 1), (27, 2), (1, 0), (24, 7), (1, 14), (18, 11), (8, 0), (12, 16), (26, 24), (8, 4), (6, 7), (18, 13), (25, 14), (29, 16), (5, 22), (15, 20), (14, 20), (29, 15), (14, 28), (23, 17), (11, 5), (16, 2), (16, 2), (22, 10), (2, 9), (29, 3), (15, 16), (12, 5), (6, 19), (24, 26), (4, 21), (2, 17), (29, 5), (28, 10), (9, 10), (10, 21), (2, 22), (5, 13), (1, 15), (19, 26), (24, 2), (7, 28), (0, 12), (3, 5), (11, 23), (17, 7), (7, 11), (1, 12), (17, 9), (0, 21), (27, 29), (5, 13), (5, 28), (18, 23), (5, 14), (16, 13), (24, 18), (17, 22), (6, 1), (2, 7), (12, 17), (14, 6), (23, 12), (7, 1), (15, 6), (10, 29), (3, 29), (9, 7), (19, 15), (13, 7), (26, 9), (0, 25), (1, 3)]
        let capacities: [Int] = [35, 10, 6, 22, 19, 41, 29, 15, 20, 40, 16, 40, 15, 35, 5, 25, 18, 1, 42, 26, 22, 41, 12, 20, 43, 31, 18, 2, 43, 17, 9, 15, 2, 11, 45, 9, 49, 26, 24, 13, 6, 4, 25, 3, 13, 8, 41, 3, 20, 35, 22, 40, 33, 5, 44, 32, 22, 15, 13, 32, 41, 34, 31, 3, 28, 17, 12, 6, 48, 45, 42, 37, 41, 26, 20, 2, 19, 31, 17, 46, 20, 20, 46, 28, 46, 20, 11, 27, 8, 16, 4, 9, 47, 27, 19, 10, 28, 27, 36, 43, 18, 11, 47, 22, 48, 49, 48, 18, 22, 44, 17, 28, 5, 49, 25, 6, 13, 37, 44, 7, 6, 44, 18, 3, 49, 48, 6, 17, 42, 32, 3, 40, 45, 48, 35, 20, 22, 49, 48, 47, 42, 48, 47, 29, 42, 48, 13, 7, 24, 25]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 29, to: 0) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 100)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 29, to: 0, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 29, to: 0, capacity: { capacities[$0] }).value)
    }

    @Test("FL-149 Double, dyadic: exact in binary: 1.125")
    func fl149() {
        // Double V [0, 1, 2, 3]; E [0→1 0.5, 0→2 0.75, 1→3 0.25, 2→3 1.0, 1→2 0.125]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
        let capacities: [Double] = [0.5, 0.75, 0.25, 1.0, 0.125]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 1.125)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-152 Double, rounding: 0.1 + 0.2 > 0.3 in Double: the cut is the 0.3 edge: 0.3")
    func fl152() {
        // Double V [0, 1, 2]; E [0→1 0.1, 0→1 0.2, 1→2 0.3]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let capacities: [Double] = [0.1, 0.2, 0.3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(abs(value - 0.3) <= 1e-12)
        // The value of the maximum flow and of the minimum cut.
        #expect(abs(value - graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value) <= 1e-12)
        #expect(abs(value - graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value) <= 1e-12)
    }

    @Test("FL-155 Double, irrational-like: 3.0")
    func fl155() {
        // Double V [0, 1, 2, 3]; E [0→1 1.4142135623730951, 0→2 1.7320508075688772, 1→2 1.0, 1→3 1.0, 2→3 2.0]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Double] = [1.4142135623730951, 1.7320508075688772, 1.0, 1.0, 2.0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(abs(value - 3.0) <= 1e-12)
        // The value of the maximum flow and of the minimum cut.
        #expect(abs(value - graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value) <= 1e-12)
        #expect(abs(value - graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value) <= 1e-12)
    }

    @Test("FL-158 Int8 near overflow: source capacities sum to Int8.max: 127")
    func fl158() {
        // Int8 V [0, 1, 2, 3]; E [0→1 100, 0→2 27, 1→3 127, 2→3 127]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int8] = [100, 27, 127, 127]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 127)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-160 UInt8: 55")
    func fl160() {
        // UInt8 V [0, 1, 2]; E [0→1 200, 1→2 50, 0→2 5]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [UInt8] = [200, 50, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 55)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-163 Int, large: 2^63 - 1 total, Int.max: 9223372036854775807")
    func fl163() {
        // V [0, 1, 2]; E [0→1 4611686018427387904, 0→2 4611686018427387903, 1→2 4611686018427387904]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let capacities: [Int] = [4611686018427387904, 4611686018427387903, 4611686018427387904]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 9223372036854775807)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-167 undirected: one edge both ways: flow -5 on edge 0: 5")
    func fl167() {
        // undirected V [0, 1]; E [0–1 5]; maximumFlowValue(from: 1, to: 0, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 1, to: 0) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 5)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 1, to: 0, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 1, to: 0, capacity: { capacities[$0] }).value)
    }

    @Test("FL-172 undirected path: 2")
    func fl172() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–2 3]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [2, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-177 undirected: an edge used against its order: 4")
    func fl177() {
        // undirected V [0, 1, 2, 3]; E [0–1 4, 2–1 4, 2–3 4, 0–2 1]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (0, 2)]
        let capacities: [Int] = [4, 4, 4, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 4)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-182 undirected: parallel edges and a loop: 4")
    func fl182() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 2, 1–1 7, 1–2 9]; maximumFlowValue(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, 2)]
        let capacities: [Int] = [2, 2, 7, 9]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 4)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 2, capacity: { capacities[$0] }).value)
    }

    @Test("FL-187 undirected: flows meet head on: 6")
    func fl187() {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 0–2 3, 1–2 5, 1–3 1, 2–3 5]; maximumFlowValue(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 5, 1, 5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 6)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 3, capacity: { capacities[$0] }).value)
    }

    @Test("FL-192 undirected Stoer–Wagner paper graph, 1 to 8: 4")
    func fl192() {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; maximumFlowValue(from: 1, to: 8, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 1, to: 8) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 4)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 1, to: 8, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 1, to: 8, capacity: { capacities[$0] }).value)
    }

    @Test("FL-197 undirected Wikipedia Gomory–Hu graph, 0 to 5: 6")
    func fl197() {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; maximumFlowValue(from: 0, to: 5, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 5) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 6)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 5, capacity: { capacities[$0] }).value)
    }

    @Test("FL-202 undirected lcgund(10,25,6,9): 15")
    func fl202() {
        // lcgund(10,25,6,9); maximumFlowValue(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let capacities: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 15)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 9, capacity: { capacities[$0] }).value)
    }

    @Test("FL-206 undirected grid(4,4), unit: 2")
    func fl206() {
        // grid(4,4); maximumFlowValue(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: 0, to: 15) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 2)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: 0, to: 15, capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: 0, to: 15, capacity: { capacities[$0] }).value)
    }

    @Test("FL-211 undirected Double: 0.75")
    func fl211() {
        // Double undirected V [a, b, c]; E [a–b 0.5, b–c 1.5, a–c 0.25]; maximumFlowValue(from: a, to: c, capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("a", "c")]
        let capacities: [Double] = [0.5, 1.5, 0.25]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "b", "c"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let value = graph.maximumFlowValue(from: "a", to: "c") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(value == 0.75)
        // The value of the maximum flow and of the minimum cut.
        #expect(value == graph.maximumFlow(from: "a", to: "c", capacity: { capacities[$0] }).value)
        #expect(value == graph.minimumCut(from: "a", to: "c", capacity: { capacities[$0] }).value)
    }
}
