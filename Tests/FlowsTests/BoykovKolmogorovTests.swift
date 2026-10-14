// `boykovKolmogorovMaximumFlow(from:to:capacity:)` (catalog §BoykovKolmogorov): the value and the
// canonical cut exactly; the flow checked here for capacity and conservation, and its residual
// network for the cut. Directed rows are `AdjacencyList`, or `DirectedPseudograph` when an edge
// repeats; undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each
// built by inserting the row's vertices, then its edges in order, so positions are the catalog's.
// In-test checks number vertices by their index in `vertices`. Generated from cases.md by
// swiftgen.py, which re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("boykovKolmogorovMaximumFlow(from:to:capacity:)")
struct BoykovKolmogorovTests {
    @Test("FL-532 one edge: value 5; S [0]; T [1]; cut [0]")
    func fl532() {
        // V [0, 1]; E [0→1 5]; boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 5)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-533 no edge: value 0; S [0]; T [1]; cut []")
    func fl533() {
        // V [0, 1]; E []; boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-534 no path: disconnected: value 0; S [0, 1]; T [2, 3]; cut []")
    func fl534() {
        // V [0, 1, 2, 3]; E [0→1 4, 2→3 4]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-535 zero capacities on the only path: value 0; S [0, 1]; T [2]; cut [1]")
    func fl535() {
        // V [0, 1, 2]; E [0→1 3, 1→2 0]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-536 self-loop ignored: value 4; S [0]; T [1]; cut [1]")
    func fl536() {
        // V [0, 1]; E [0→0 9, 0→1 4, 1→1 9]; boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 1)
        #expect(flow.value == 4)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-537 parallel edges add: value 5; S [0]; T [1, 2]; cut [0, 1]")
    func fl537() {
        // V [0, 1, 2]; E [0→1 2, 0→1 3, 1→2 1, 1→2 9]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 5)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-538 antiparallel pair on the path: value 6; S [0, 1, 2]; T [3]; cut [4, 5]")
    func fl538() {
        // V [0, 1, 2, 3]; E [0→1 3, 0→2 3, 1→2 2, 2→1 2, 1→3 1, 2→3 5]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 6)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-539 CLRS figure 26.1: value 23; S [s, v1, v2, v4]; T [v3, t]; cut [2, 7, 8]")
    func fl539() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; boykovKolmogorovMaximumFlow(from: s, to: t, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 23)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-540 Ford–Fulkerson's slow case: value 2000; S [s, a, b]; T [t]; cut [3, 4]")
    func fl540() {
        // V [s, a, b, t]; E [s→a 1000, s→b 1000, a→b 1, a→t 1000, b→t 1000]; boykovKolmogorovMaximumFlow(from: s, to: t, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "s" && flow.sink == "t")
        #expect(flow.value == 2000)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-541 NetworkX docs example: value 3.0; S [x, a, c]; T [b, d, e, y]; cut [1, 6]")
    func fl541() {
        // Double V [x, a, b, c, d, e, y]; E [x→a 3.0, x→b 1.0, a→c 3.0, b→c 5.0, b→d 4.0, d→e 2.0, c→y 2.0, e→y 3.0]; boykovKolmogorovMaximumFlow(from: x, to: y, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: "x", to: "y") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == "x" && flow.sink == "y")
        #expect(flow.value == 3.0)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-542 trees meet in the middle, then orphans re-adopt: value 5; S [0, 1, 2, 3, 4]; T [5, 6, 7]; cut [5, 6, 10]")
    func fl542() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0→1 4, 0→2 4, 1→3 2, 2→3 2, 3→4 3, 4→5 2, 4→6 2, 5→7 4, 6→7 4, 1→4 1, 2→5 1]; boykovKolmogorovMaximumFlow(from: 0, to: 7, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (4, 5), (4, 6), (5, 7), (6, 7), (1, 4), (2, 5)]
        let capacities: [Int] = [4, 4, 2, 2, 3, 2, 2, 4, 4, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        var asked: [Int] = []
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 7) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 7)
        #expect(flow.value == 5)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4] as [Int])
        #expect(Array(cut.sinkSide) == [5, 6, 7] as [Int])
        #expect(cut.edges == [5, 6, 10] as [Int])
        #expect(cut.value == 5)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-543 lcgnet(10,30,10,20): value 29; S [0, 1, 2, 3, 4, 5, 6, 7, 8]; T [9]; cut [3, 9, 10, 21]")
    func fl543() {
        // lcgnet(10,30,10,20); boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 9)
        #expect(flow.value == 29)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-544 lcgnet(16,60,4,100): value 139; S [0, 6, 10]; T [1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15]; cut [0, 19, 26]")
    func fl544() {
        // lcgnet(16,60,4,100); boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 15)
        #expect(flow.value == 139)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-545 lcgnet(30,150,5,50)")
    func fl545() {
        // lcgnet(30,150,5,50); boykovKolmogorovMaximumFlow(from: 0, to: 29, capacity:)
        let pairs: [(Int, Int)] = [(22, 23), (11, 29), (20, 24), (24, 18), (3, 17), (3, 22), (10, 4), (12, 21), (1, 24), (19, 20), (5, 3), (23, 15), (20, 11), (18, 10), (10, 0), (16, 8), (2, 20), (6, 0), (1, 7), (12, 21), (4, 16), (28, 2), (15, 29), (22, 28), (1, 22), (11, 28), (4, 25), (1, 7), (27, 22), (27, 28), (24, 25), (21, 17), (16, 5), (23, 19), (17, 3), (24, 5), (3, 27), (23, 1), (29, 15), (8, 23), (24, 13), (2, 13), (6, 19), (2, 28), (7, 17), (15, 24), (19, 15), (25, 10), (26, 0), (13, 29), (12, 14), (18, 13), (18, 21), (7, 27), (16, 9), (2, 7), (13, 12), (5, 19), (15, 5), (3, 4), (29, 12), (9, 2), (17, 23), (14, 23), (7, 28), (16, 17), (5, 27), (12, 29), (15, 8), (10, 19), (4, 18), (1, 11), (4, 2), (5, 20), (12, 14), (16, 4), (5, 13), (9, 1), (27, 2), (1, 0), (24, 7), (1, 14), (18, 11), (8, 0), (12, 16), (26, 24), (8, 4), (6, 7), (18, 13), (25, 14), (29, 16), (5, 22), (15, 20), (14, 20), (29, 15), (14, 28), (23, 17), (11, 5), (16, 2), (16, 2), (22, 10), (2, 9), (29, 3), (15, 16), (12, 5), (6, 19), (24, 26), (4, 21), (2, 17), (29, 5), (28, 10), (9, 10), (10, 21), (2, 22), (5, 13), (1, 15), (19, 26), (24, 2), (7, 28), (0, 12), (3, 5), (11, 23), (17, 7), (7, 11), (1, 12), (17, 9), (0, 21), (27, 29), (5, 13), (5, 28), (18, 23), (5, 14), (16, 13), (24, 18), (17, 22), (6, 1), (2, 7), (12, 17), (14, 6), (23, 12), (7, 1), (15, 6), (10, 29), (3, 29), (9, 7), (19, 15), (13, 7), (26, 9), (0, 25), (1, 3)]
        let capacities: [Int] = [35, 10, 6, 22, 19, 41, 29, 15, 20, 40, 16, 40, 15, 35, 5, 25, 18, 1, 42, 26, 22, 41, 12, 20, 43, 31, 18, 2, 43, 17, 9, 15, 2, 11, 45, 9, 49, 26, 24, 13, 6, 4, 25, 3, 13, 8, 41, 3, 20, 35, 22, 40, 33, 5, 44, 32, 22, 15, 13, 32, 41, 34, 31, 3, 28, 17, 12, 6, 48, 45, 42, 37, 41, 26, 20, 2, 19, 31, 17, 46, 20, 20, 46, 28, 46, 20, 11, 27, 8, 16, 4, 9, 47, 27, 19, 10, 28, 27, 36, 43, 18, 11, 47, 22, 48, 49, 48, 18, 22, 44, 17, 28, 5, 49, 25, 6, 13, 37, 44, 7, 6, 44, 18, 3, 49, 48, 6, 17, 42, 32, 3, 40, 45, 48, 35, 20, 22, 49, 48, 47, 42, 48, 47, 29, 42, 48, 13, 7, 24, 25]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 29)!
        var asked: [Int] = []
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 29) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 29)
        #expect(flow.value == 32)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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
        #expect(Array(cut.sourceSide) == [0, 25] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29] as [Int])
        #expect(cut.edges == [47, 89, 119, 126] as [Int])
        #expect(cut.value == 32)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-546 Double, dyadic: value 1.125; S [0, 1]; T [2, 3]; cut [1, 2, 4]")
    func fl546() {
        // Double V [0, 1, 2, 3]; E [0→1 0.5, 0→2 0.75, 1→3 0.25, 2→3 1.0, 1→2 0.125]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 1.125)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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

    @Test("FL-547 UInt8: value 55; S [0, 1]; T [2]; cut [1, 2]")
    func fl547() {
        // UInt8 V [0, 1, 2]; E [0→1 200, 1→2 50, 0→2 5]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [UInt8] = [200, 50, 5]
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 55)
        let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
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
        #expect(cut.value == 55)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-548 undirected: an edge used against its order: value 4; S [0, 1, 2]; T [3]; cut [2]")
    func fl548() {
        // undirected V [0, 1, 2, 3]; E [0–1 4, 2–1 4, 2–3 4, 0–2 1]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 3)
        #expect(flow.value == 4)
        // The flow is over `directedView`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: false)) } == forward.map(Optional.some))
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: true)) } == backward.map(Optional.some))
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
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

    @Test("FL-549 undirected: parallel edges and a loop: value 4; S [0]; T [1, 2]; cut [0, 1r]")
    func fl549() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 2, 1–1 7, 1–2 9]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 2)
        #expect(flow.value == 4)
        // The flow is over `directedView`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: false)) } == forward.map(Optional.some))
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: true)) } == backward.map(Optional.some))
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
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

    @Test("FL-550 undirected grid(4,4), unit: value 2; S [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]; T [15]; cut [20, 23]")
    func fl550() {
        // grid(4,4); boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 15)!
        var asked: [Int] = []
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 15)
        #expect(flow.value == 2)
        // The flow is over `directedView`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: false)) } == forward.map(Optional.some))
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: true)) } == backward.map(Optional.some))
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
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
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
        #expect(Array(cut.sinkSide) == [15] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20", "23"] as [String])
        #expect(cut.value == 2)
        #expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity, the flow's value (so both are optimal).
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        #expect(cut.value == flow.value)
    }

    @Test("FL-551 undirected lcgund(10,25,6,9): value 15; S [0, 1, 2, 3, 4, 5, 6, 7, 8]; T [9]; cut [1r, 2, 18r]")
    func fl551() {
        // lcgund(10,25,6,9); boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity:)
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
        let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(flow.source == 0 && flow.sink == 9)
        #expect(flow.value == 15)
        // The flow is over `directedView`: an edge's flow along its stored order is on the forward arc, against
        // it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.
        let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: false)) } == forward.map(Optional.some))
        #expect(pairs.indices.map { try? flow.flow(checkedEdgeAt: .init(position: $0, reversed: true)) } == backward.map(Optional.some))
        for k in pairs.indices {
            #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), "edge \(k)")
            #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, "self-loop \(k)") }
        }
        let signed = pairs.indices.map { forward[$0] - backward[$0] }
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
}
