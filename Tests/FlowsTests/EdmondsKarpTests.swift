// `edmondsKarpMaximumFlow(from:to:capacity:)` (catalog §EdmondsKarp): the per-edge flow exactly,
// pinned by the documented procedure (residual rows in edge-position order, breadth-first search
// stopped at the sink, bottleneck augmentation); capacity and conservation; the canonical cut, from
// this flow's residual network too. Directed rows are `AdjacencyList`, or `DirectedPseudograph` when
// an edge repeats; undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges;
// each built by inserting the row's vertices, then its edges in order, so positions are the
// catalog's. In-test checks number vertices by their index in `vertices`. Generated from cases.md by
// swiftgen.py, which re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("edmondsKarpMaximumFlow(from:to:capacity:)")
struct EdmondsKarpTests {
    @Test("FL-002 one edge: value 5; flow [5]; S [0]; T [1]; cut [0]")
    func fl002() {
        // V [0, 1]; E [0→1 5]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 5)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [5] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 5)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-007 no edge: value 0, the sink alone on its side: value 0; flow []; S [0]; T [1]; cut []")
    func fl007() {
        // V [0, 1]; E []; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-012 no path: edge into the source only: value 0; flow [0]; S [0]; T [1]; cut []")
    func fl012() {
        // V [0, 1]; E [1→0 5]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(1, 0)]
        let capacities: [Int] = [5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-017 no path: disconnected: value 0; flow [0, 0]; S [0, 1]; T [2, 3]; cut []")
    func fl017() {
        // V [0, 1, 2, 3]; E [0→1 4, 2→3 4]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let capacities: [Int] = [4, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-022 zero capacity: a zero edge still crosses the cut: value 0; flow [0]; S [0]; T [1]; cut [0]")
    func fl022() {
        // V [0, 1]; E [0→1 0]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [0]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 0)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-027 zero capacities on the only path: value 0; flow [0, 0]; S [0, 1]; T [2]; cut [1]")
    func fl027() {
        // V [0, 1, 2]; E [0→1 3, 1→2 0]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [3, 0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 0)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-032 path: the first bottleneck from the sink: every edge is a minimum cut; the one nearest t")
    func fl032() {
        // V [0, 1, 2, 3]; E [0→1 2, 1→2 2, 2→3 2]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [2, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 2)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 2, 2] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [2] as [Int])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-037 path with a later bottleneck: value 1; flow [1, 1, 1]; S [0]; T [1, 2, 3]; cut [0]")
    func fl037() {
        // V [0, 1, 2, 3]; E [0→1 1, 1→2 3, 2→3 2]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [1, 3, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 1)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 1, 1] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 1)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-042 source and sink not first and last: value 2; flow [2, 2]; S [s]; T [a, t]; cut [0]")
    func fl042() {
        // V [a, t, s]; E [s→a 2, a→t 3]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t")]
        let capacities: [Int] = [2, 3]
        let graph = AdjacencyList<String>(vertices: ["a", "t", "s"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "t", "s"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 2)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 2] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["s"] as [String])
        #expect(Array(cut.sinkSide) == ["a", "t"] as [String])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-047 isolated extra vertex: unreachable vertices sit on the source side: value 3; flow [3]; S [0, 1]; T [2]; cut [0]")
    func fl047() {
        // V [0, 1, 2]; E [0→2 3]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 2)]
        let capacities: [Int] = [3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 3)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [3] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 3)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-052 vertex reaching only the sink: 1 can reach t: sink side: value 3; flow [3, 0]; S [0]; T [1, 2]; cut [0]")
    func fl052() {
        // V [0, 1, 2]; E [0→2 3, 1→2 9]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let capacities: [Int] = [3, 9]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 3)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [3, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 3)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-057 dead end off the source: value 3; flow [0, 3]; S [0, 1]; T [2]; cut [1]")
    func fl057() {
        // V [0, 1, 2]; E [0→1 7, 0→2 3]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let capacities: [Int] = [7, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 3)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 3] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 3)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-062 self-loop ignored: loops carry no flow, never cross: value 4; flow [0, 4, 0]; S [0]; T [1]; cut [1]")
    func fl062() {
        // V [0, 1]; E [0→0 9, 0→1 4, 1→1 9]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let capacities: [Int] = [9, 4, 9]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 4)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 4, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 4)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-067 parallel edges add: value 5; flow [2, 3, 1, 4]; S [0]; T [1, 2]; cut [0, 1]")
    func fl067() {
        // V [0, 1, 2]; E [0→1 2, 0→1 3, 1→2 1, 1→2 9]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (1, 2)]
        let capacities: [Int] = [2, 3, 1, 9]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 5)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [2, 3, 1, 4] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges == [0, 1] as [Int])
        #expect(cut.value == 5)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-072 antiparallel pair: each arc its own reverse: value 4; flow [4, 0, 4]; S [0, 1]; T [2]; cut [2]")
    func fl072() {
        // V [0, 1, 2]; E [0→1 5, 1→0 3, 1→2 4]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let capacities: [Int] = [5, 3, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 4)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [4, 0, 4] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [2] as [Int])
        #expect(cut.value == 4)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-077 antiparallel pair on the path: value 6; flow [3, 3, 2, 0, 1, 5]; S [0, 1, 2]; T [3]; cut [4, 5]")
    func fl077() {
        // V [0, 1, 2, 3]; E [0→1 3, 0→2 3, 1→2 2, 2→1 2, 1→3 1, 2→3 5]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 2, 2, 1, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 6)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [3, 3, 2, 0, 1, 5] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [4, 5] as [Int])
        #expect(cut.value == 6)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-082 edge into the source and out of the sink: value 2; flow [0, 2, 0, 2, 0]; S [0, 1]; T [2]; cut [3]")
    func fl082() {
        // V [0, 1, 2]; E [1→0 4, 0→1 3, 2→1 6, 1→2 2, 2→0 8]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(1, 0), (0, 1), (2, 1), (1, 2), (2, 0)]
        let capacities: [Int] = [4, 3, 6, 2, 8]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 2)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 2, 0, 2, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [3] as [Int])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-087 CLRS figure 26.1: value 23")
    func fl087() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 23)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
        #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
        #expect(cut.edges == [2, 7, 8] as [Int])
        #expect(cut.value == 23)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-092 CLRS 2nd ed., with v1⇄v2")
    func fl092() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v2 10, v2→v1 4, v1→v3 12, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v2"), ("v2", "v1"), ("v1", "v3"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 10, 4, 12, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 23)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [12, 11, 0, 0, 12, 11, 0, 19, 7, 4] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
        #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
        #expect(cut.edges == [4, 8, 9] as [Int])
        #expect(cut.value == 23)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-097 Ford–Fulkerson's slow case: Edmonds–Karp needs two augmentations")
    func fl097() {
        // V [s, a, b, t]; E [s→a 1000, s→b 1000, a→b 1, a→t 1000, b→t 1000]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("a", "b"), ("a", "t"), ("b", "t")]
        let capacities: [Int] = [1000, 1000, 1, 1000, 1000]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "b", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 2000)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [1000, 1000, 0, 1000, 1000] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["s", "a", "b"] as [String])
        #expect(Array(cut.sinkSide) == ["t"] as [String])
        #expect(cut.edges == [3, 4] as [Int])
        #expect(cut.value == 2000)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-102 NetworkX docs example")
    func fl102() {
        // Double V [x, a, b, c, d, e, y]; E [x→a 3.0, x→b 1.0, a→c 3.0, b→c 5.0, b→d 4.0, d→e 2.0, c→y 2.0, e→y 3.0]; edmondsKarpMaximumFlow(from: x, to: y, capacity:)
        let pairs: [(String, String)] = [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")]
        let capacities: [Double] = [3.0, 1.0, 3.0, 5.0, 4.0, 2.0, 2.0, 3.0]
        let graph = AdjacencyList<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["x", "a", "b", "c", "d", "e", "y"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "x")!
        let t = vertexList.firstIndex(of: "y")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "x", to: "y") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "x" && flow.sink == "y")
        #expect(flow.value == 3.0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [2.0, 1.0, 2.0, 0.0, 1.0, 1.0, 2.0, 1.0] as [Double])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Double](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += flows[k]
            excess[ends[k].0] -= flows[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(abs(excess[x]) <= 1e-12, "at \(vertexList[x])") }
        #expect(abs(excess[t] - flow.value) <= 1e-12)
        #expect(abs(excess[s] + flow.value) <= 1e-12)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["x", "a", "c"] as [String])
        #expect(Array(cut.sinkSide) == ["b", "d", "e", "y"] as [String])
        #expect(cut.edges == [1, 6] as [Int])
        #expect(cut.value == 3.0)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-107 diamond, two equal cuts: value 2; flow [1, 1, 1, 1]; S [0, 1, 2]; T [3]; cut [2, 3]")
    func fl107() {
        // V [0, 1, 2, 3]; E [0→1 1, 0→2 1, 1→3 1, 2→3 1]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 2)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 1, 1, 1] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [2, 3] as [Int])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-112 cut not at either end: value 2; flow [1, 1, 1, 1, 1, 1, 0]; S [0, 1, 2]; T [3, 4, 5]; cut [2, 3]")
    func fl112() {
        // V [0, 1, 2, 3, 4, 5]; E [0→1 5, 0→2 5, 1→3 1, 2→4 1, 3→5 5, 4→5 5, 1→2 3]; edmondsKarpMaximumFlow(from: 0, to: 5, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (1, 2)]
        let capacities: [Int] = [5, 5, 1, 1, 5, 5, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 5)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 5)
        #expect(flow.value == 2)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 1, 1, 1, 1, 1, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3, 4, 5] as [Int])
        #expect(cut.edges == [2, 3] as [Int])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-117 bipartite matching as flow")
    func fl117() {
        // V [s, a, b, c, x, y, z, t]; E [s→a 1, s→b 1, s→c 1, a→x 1, a→y 1, b→x 1, c→x 1, c→z 1, x→t 1, y→t 1, z→t 1]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("s", "c"), ("a", "x"), ("a", "y"), ("b", "x"), ("c", "x"), ("c", "z"), ("x", "t"), ("y", "t"), ("z", "t")]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "b", "c", "x", "y", "z", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "b", "c", "x", "y", "z", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 3)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["s", "a", "b", "c", "x", "y", "z"] as [String])
        #expect(Array(cut.sinkSide) == ["t"] as [String])
        #expect(cut.edges == [8, 9, 10] as [Int])
        #expect(cut.value == 3)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-122 lcgnet(8,20,8,9)")
    func fl122() {
        // lcgnet(8,20,8,9); edmondsKarpMaximumFlow(from: 0, to: 7, capacity:)
        let pairs: [(Int, Int)] = [(4, 0), (3, 6), (2, 3), (5, 7), (6, 3), (0, 6), (6, 0), (1, 4), (5, 6), (3, 6), (0, 4), (2, 1), (0, 7), (1, 3), (5, 2), (6, 5), (0, 5), (0, 7), (0, 5), (3, 1)]
        let capacities: [Int] = [6, 6, 2, 2, 5, 6, 3, 5, 5, 7, 1, 5, 9, 9, 3, 4, 2, 2, 3, 1]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 7) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 7)
        #expect(flow.value == 13)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 2, 2, 0, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6] as [Int])
        #expect(Array(cut.sinkSide) == [7] as [Int])
        #expect(cut.edges == [3, 12, 17] as [Int])
        #expect(cut.value == 13)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-127 lcgnet(10,30,10,20)")
    func fl127() {
        // lcgnet(10,30,10,20); edmondsKarpMaximumFlow(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(9, 2), (9, 5), (5, 7), (5, 9), (2, 6), (0, 8), (1, 3), (8, 7), (4, 5), (0, 9), (4, 9), (7, 5), (0, 1), (9, 2), (3, 2), (4, 5), (6, 5), (2, 6), (7, 6), (0, 5), (5, 6), (1, 9), (5, 0), (6, 2), (1, 5), (8, 1), (2, 4), (4, 6), (6, 0), (3, 0)]
        let capacities: [Int] = [4, 16, 7, 10, 8, 7, 3, 5, 12, 12, 5, 6, 12, 19, 18, 6, 19, 20, 10, 5, 5, 2, 13, 10, 2, 19, 8, 17, 1, 14]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 9)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 9)
        #expect(flow.value == 29)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0, 0, 10, 0, 5, 3, 5, 0, 12, 5, 3, 7, 0, 3, 0, 0, 0, 2, 5, 0, 2, 0, 2, 2, 0, 5, 0, 0, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(Array(cut.sinkSide) == [9] as [Int])
        #expect(cut.edges == [3, 9, 10, 21] as [Int])
        #expect(cut.value == 29)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-132 lcgnet(12,40,3,5)")
    func fl132() {
        // lcgnet(12,40,3,5); edmondsKarpMaximumFlow(from: 0, to: 11, capacity:)
        let pairs: [(Int, Int)] = [(11, 7), (10, 0), (7, 5), (9, 7), (8, 9), (5, 3), (7, 8), (10, 11), (5, 11), (7, 1), (1, 6), (7, 5), (9, 3), (9, 0), (0, 5), (2, 5), (1, 5), (5, 11), (8, 5), (2, 1), (11, 3), (1, 11), (0, 6), (2, 9), (7, 3), (3, 9), (9, 3), (0, 9), (10, 4), (9, 11), (2, 11), (3, 9), (2, 10), (4, 9), (9, 4), (5, 0), (8, 5), (11, 9), (11, 1), (11, 3)]
        let capacities: [Int] = [1, 4, 5, 3, 4, 5, 1, 2, 4, 5, 2, 4, 4, 2, 1, 2, 2, 2, 2, 1, 2, 5, 5, 1, 4, 5, 5, 4, 5, 1, 1, 4, 1, 1, 2, 5, 2, 1, 4, 2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 11)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 11) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 11)
        #expect(flow.value == 5)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0, 0, 3, 3, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 3, 4, 6, 9] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 5, 7, 8, 10, 11] as [Int])
        #expect(cut.edges == [3, 14, 29] as [Int])
        #expect(cut.value == 5)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-137 lcgnet(16,60,4,100)")
    func fl137() {
        // lcgnet(16,60,4,100); edmondsKarpMaximumFlow(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(10, 12), (11, 1), (1, 5), (8, 15), (14, 8), (7, 12), (0, 10), (7, 10), (13, 0), (13, 11), (3, 8), (8, 6), (1, 2), (2, 14), (5, 13), (15, 10), (0, 6), (3, 4), (12, 10), (10, 5), (4, 13), (5, 1), (3, 5), (5, 6), (12, 7), (8, 7), (0, 14), (13, 12), (2, 8), (0, 10), (14, 12), (4, 12), (12, 15), (11, 1), (9, 12), (5, 2), (13, 2), (8, 15), (14, 8), (8, 15), (9, 8), (15, 1), (11, 2), (13, 9), (8, 14), (15, 8), (11, 12), (8, 7), (14, 12), (9, 11), (12, 3), (5, 8), (13, 11), (12, 13), (9, 6), (12, 5), (1, 3), (14, 9), (10, 6), (5, 10)]
        let capacities: [Int] = [75, 8, 15, 15, 92, 98, 59, 79, 47, 1, 30, 36, 69, 55, 21, 4, 48, 32, 64, 42, 80, 45, 38, 70, 69, 63, 22, 30, 50, 89, 90, 37, 94, 80, 16, 2, 57, 12, 80, 46, 48, 22, 80, 23, 76, 61, 20, 2, 69, 62, 82, 44, 74, 52, 49, 62, 86, 76, 80, 62]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 15)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 15) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 15)
        #expect(flow.value == 139)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [75, 0, 0, 15, 22, 0, 59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 22, 0, 0, 58, 0, 0, 75, 0, 0, 0, 0, 12, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0, 0] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 6, 10] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15] as [Int])
        #expect(cut.edges == [0, 19, 26] as [Int])
        #expect(cut.value == 139)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-147 Double, dyadic: exact in binary")
    func fl147() {
        // Double V [0, 1, 2, 3]; E [0→1 0.5, 0→2 0.75, 1→3 0.25, 2→3 1.0, 1→2 0.125]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
        let capacities: [Double] = [0.5, 0.75, 0.25, 1.0, 0.125]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 1.125)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [0.375, 0.75, 0.25, 0.875, 0.125] as [Double])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Double](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += flows[k]
            excess[ends[k].0] -= flows[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(abs(excess[x]) <= 1e-12, "at \(vertexList[x])") }
        #expect(abs(excess[t] - flow.value) <= 1e-12)
        #expect(abs(excess[s] + flow.value) <= 1e-12)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges == [1, 2, 4] as [Int])
        #expect(cut.value == 1.125)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-154 Double, irrational-like")
    func fl154() {
        // Double V [0, 1, 2, 3]; E [0→1 1.4142135623730951, 0→2 1.7320508075688772, 1→2 1.0, 1→3 1.0, 2→3 2.0]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Double] = [1.4142135623730951, 1.7320508075688772, 1.0, 1.0, 2.0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(abs(flow.value - 3.0) <= 1e-12)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        let expectedFlows: [Double] = [1.2679491924311228, 1.7320508075688772, 0.2679491924311228, 1.0, 2.0]
        #expect(zip(flows, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 }, "\(flows)")
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Double](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += flows[k]
            excess[ends[k].0] -= flows[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(abs(excess[x]) <= 1e-12, "at \(vertexList[x])") }
        #expect(abs(excess[t] - flow.value) <= 1e-12)
        #expect(abs(excess[s] + flow.value) <= 1e-12)
        // Capacities that are not dyadic: residuals near zero depend on rounding, so the cut is checked
        // against the catalog only (api.md: the cut follows residuals > 0 as computed).
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [3, 4] as [Int])
        #expect(cut.value == 3.0)
        #expect(abs(cut.value - flow.value) <= 1e-12)
    }

    @Test("FL-157 Int8 near overflow: source capacities sum to Int8.max")
    func fl157() {
        // Int8 V [0, 1, 2, 3]; E [0→1 100, 0→2 27, 1→3 127, 2→3 127]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int8] = [100, 27, 127, 127]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 127)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [100, 27, 100, 27] as [Int8])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
        #expect(cut.edges == [0, 1] as [Int])
        #expect(cut.value == 127)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-162 Int, large: 2^63 - 1 total, Int.max")
    func fl162() {
        // V [0, 1, 2]; E [0→1 4611686018427387904, 0→2 4611686018427387903, 1→2 4611686018427387904]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let capacities: [Int] = [4611686018427387904, 4611686018427387903, 4611686018427387904]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 9223372036854775807)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(flows == [4611686018427387904, 4611686018427387903, 4611686018427387904] as [Int])
        // Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow
        // equals outflow at every vertex but the ends; the value is the net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, "self-loop \(k)") }
            excess[ends[k].1] += Int(flows[k])
            excess[ends[k].0] -= Int(flows[k])
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == Int(flow.value))
        #expect(excess[s] == -Int(flow.value))
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && flows[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && flows[k] > 0 {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [1, 2] as [Int])
        #expect(cut.value == 9223372036854775807)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-165 undirected: one edge both ways: flow -5 on edge 0: value 5; flow [-5]; S [1]; T [0]; cut [0r]")
    func fl165() {
        // undirected V [0, 1]; E [0–1 5]; edmondsKarpMaximumFlow(from: 1, to: 0, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 0)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 0) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 1 && flow.sink == 0)
        #expect(flow.value == 5)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [-5] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [1] as [Int])
        #expect(Array(cut.sinkSide) == [0] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0r"] as [String])
        #expect(cut.value == 5)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-170 undirected path: value 2; flow [2, 2]; S [0]; T [1, 2]; cut [0]")
    func fl170() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–2 3]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [2, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 2)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [2, 2] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-175 undirected: an edge used against its order: value 4; flow [3, -3, 4, 1]; S [0, 1, 2]; T [3]; cut [2]")
    func fl175() {
        // undirected V [0, 1, 2, 3]; E [0–1 4, 2–1 4, 2–3 4, 0–2 1]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (0, 2)]
        let capacities: [Int] = [4, 4, 4, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 4)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [3, -3, 4, 1] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
        #expect(cut.value == 4)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-180 undirected: parallel edges and a loop: value 4; flow [2, -2, 0, 4]; S [0]; T [1, 2]; cut [0, 1r]")
    func fl180() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 2, 1–1 7, 1–2 9]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, 2)]
        let capacities: [Int] = [2, 2, 7, 9]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 4)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [2, -2, 0, 4] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
        #expect(cut.value == 4)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-185 undirected: flows meet head on: value 6; flow [3, 3, 2, 1, 5]; S [0, 1, 2]; T [3]; cut [3, 4]")
    func fl185() {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 0–2 3, 1–2 5, 1–3 1, 2–3 5]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 5, 1, 5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 6)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [3, 3, 2, 1, 5] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "4"] as [String])
        #expect(cut.value == 6)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-190 undirected Stoer–Wagner paper graph, 1 to 8")
    func fl190() {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; edmondsKarpMaximumFlow(from: 1, to: 8, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 8)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 8) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 1 && flow.sink == 8)
        #expect(flow.value == 4)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [2, 2, 3, -1, 0, 2, 1, 0, 2, 1, 1, 2] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
        #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
        #expect(cut.value == 4)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-195 undirected Wikipedia Gomory–Hu graph, 0 to 5")
    func fl195() {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; edmondsKarpMaximumFlow(from: 0, to: 5, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 5)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 5)
        #expect(flow.value == 6)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [1, 5, -1, 3, -1, 4, -1, 4, 2] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
        #expect(Array(cut.sinkSide) == [3, 5] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "6r", "8"] as [String])
        #expect(cut.value == 6)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-200 undirected lcgund(10,25,6,9)")
    func fl200() {
        // lcgund(10,25,6,9); edmondsKarpMaximumFlow(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let capacities: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 9)!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 9)
        #expect(flow.value == 15)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [0, -3, 9, -8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -3, -4, 0, -3, 0, 0, 0] as [Int])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, "at \(vertexList[x])") }
        #expect(excess[t] == flow.value)
        #expect(excess[s] == -flow.value)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(Array(cut.sinkSide) == [9] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1r", "2", "18r"] as [String])
        #expect(cut.value == 15)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-209 undirected Double: value 0.75; flow [0.5, 0.5, 0.25]; S [a]; T [b, c]; cut [0, 2]")
    func fl209() {
        // Double undirected V [a, b, c]; E [a–b 0.5, b–c 1.5, a–c 0.25]; edmondsKarpMaximumFlow(from: a, to: c, capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("a", "c")]
        let capacities: [Double] = [0.5, 1.5, 0.25]
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "b", "c"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "a")!
        let t = vertexList.firstIndex(of: "c")!
        var asked: [Int] = []
        let flow = graph.edmondsKarpMaximumFlow(from: "a", to: "c") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "a" && flow.sink == "c")
        #expect(flow.value == 0.75)
        // The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
        #expect(signed == [0.5, 0.5, 0.25] as [Double])
        // Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the
        // net flow out of the source.
        var excess = [Double](repeating: 0, count: n)
        for k in pairs.indices {
            excess[ends[k].1] += signed[k]
            excess[ends[k].0] -= signed[k]
        }
        for x in 0 ..< n where x != s && x != t { #expect(abs(excess[x]) <= 1e-12, "at \(vertexList[x])") }
        #expect(abs(excess[t] - flow.value) <= 1e-12)
        #expect(abs(excess[s] + flow.value) <= 1e-12)
        // The canonical cut, found here: the sink side is every vertex that can still reach the sink in this
        // flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above
        // minus the capacity).
        var reaches = [Bool](repeating: false, count: n)
        reaches[t] = true
        var queue = [t]
        while let y = queue.popLast() {
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if b == y && !reaches[a] && signed[k] < capacities[k] {
                    reaches[a] = true
                    queue.append(a)
                }
                if a == y && !reaches[b] && signed[k] > -capacities[k] {
                    reaches[b] = true
                    queue.append(b)
                }
            }
        }
        let cut = flow.minimumCut
        #expect(Array(cut.sourceSide) == ["a"] as [String])
        #expect(Array(cut.sinkSide) == ["b", "c"] as [String])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "2"] as [String])
        #expect(cut.value == 0.75)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }
}
