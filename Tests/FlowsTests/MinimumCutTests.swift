// `minimumCut(from:to:capacity:)` (catalog §MinimumCut): the canonical cut exactly (the least sink
// side); its edges every edge from the source side to the sink side; its value their capacity; by
// brute force over every s–t cut, the least value and the least sink side among the minimum cuts;
// the same `Cut` as every maximum flow's. Directed rows are `AdjacencyList`, or
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

@Suite("minimumCut(from:to:capacity:)")
struct MinimumCutTests {
    @Test("FL-005 one edge: value 5; S [0]; T [1]; cut [0]")
    func fl005() {
        // V [0, 1]; E [0→1 5]; minimumCut(from: 0, to: 1, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 5)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-010 no edge: value 0, the sink alone on its side: value 0; S [0]; T [1]; cut []")
    func fl010() {
        // V [0, 1]; E []; minimumCut(from: 0, to: 1, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-015 no path: edge into the source only: value 0; S [0]; T [1]; cut []")
    func fl015() {
        // V [0, 1]; E [1→0 5]; minimumCut(from: 0, to: 1, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-020 no path: disconnected: value 0; S [0, 1]; T [2, 3]; cut []")
    func fl020() {
        // V [0, 1, 2, 3]; E [0→1 4, 2→3 4]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-025 zero capacity: a zero edge still crosses the cut: value 0; S [0]; T [1]; cut [0]")
    func fl025() {
        // V [0, 1]; E [0→1 0]; minimumCut(from: 0, to: 1, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 0)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-030 zero capacities on the only path: value 0; S [0, 1]; T [2]; cut [1]")
    func fl030() {
        // V [0, 1, 2]; E [0→1 3, 1→2 0]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 0)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-035 path: the first bottleneck from the sink: every edge is a minimum cut; the one nearest t")
    func fl035() {
        // V [0, 1, 2, 3]; E [0→1 2, 1→2 2, 2→3 2]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [2] as [Int])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-040 path with a later bottleneck: value 1; S [0]; T [1, 2, 3]; cut [0]")
    func fl040() {
        // V [0, 1, 2, 3]; E [0→1 1, 1→2 3, 2→3 2]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 1)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-045 source and sink not first and last: value 2; S [s]; T [a, t]; cut [0]")
    func fl045() {
        // V [a, t, s]; E [s→a 2, a→t 3]; minimumCut(from: s, to: t, capacity:)
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
        let cut = graph.minimumCut(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["s"] as [String])
        #expect(Array(cut.sinkSide) == ["a", "t"] as [String])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-050 isolated extra vertex: unreachable vertices sit on the source side: value 3; S [0, 1]; T [2]; cut [0]")
    func fl050() {
        // V [0, 1, 2]; E [0→2 3]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 3)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-055 vertex reaching only the sink: 1 can reach t: sink side: value 3; S [0]; T [1, 2]; cut [0]")
    func fl055() {
        // V [0, 1, 2]; E [0→2 3, 1→2 9]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges == [0] as [Int])
        #expect(cut.value == 3)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-060 dead end off the source: value 3; S [0, 1]; T [2]; cut [1]")
    func fl060() {
        // V [0, 1, 2]; E [0→1 7, 0→2 3]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 3)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-065 self-loop ignored: loops carry no flow, never cross: value 4; S [0]; T [1]; cut [1]")
    func fl065() {
        // V [0, 1]; E [0→0 9, 0→1 4, 1→1 9]; minimumCut(from: 0, to: 1, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 1) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 4)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-070 parallel edges add: value 5; S [0]; T [1, 2]; cut [0, 1]")
    func fl070() {
        // V [0, 1, 2]; E [0→1 2, 0→1 3, 1→2 1, 1→2 9]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges == [0, 1] as [Int])
        #expect(cut.value == 5)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-075 antiparallel pair: each arc its own reverse: value 4; S [0, 1]; T [2]; cut [2]")
    func fl075() {
        // V [0, 1, 2]; E [0→1 5, 1→0 3, 1→2 4]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [2] as [Int])
        #expect(cut.value == 4)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-080 antiparallel pair on the path: value 6; S [0, 1, 2]; T [3]; cut [4, 5]")
    func fl080() {
        // V [0, 1, 2, 3]; E [0→1 3, 0→2 3, 1→2 2, 2→1 2, 1→3 1, 2→3 5]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [4, 5] as [Int])
        #expect(cut.value == 6)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-085 edge into the source and out of the sink: value 2; S [0, 1]; T [2]; cut [3]")
    func fl085() {
        // V [0, 1, 2]; E [1→0 4, 0→1 3, 2→1 6, 1→2 2, 2→0 8]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [3] as [Int])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-090 CLRS figure 26.1: value 23: value 23; S [s, v1, v2, v4]; T [v3, t]; cut [2, 7, 8]")
    func fl090() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; minimumCut(from: s, to: t, capacity:)
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
        let cut = graph.minimumCut(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
        #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
        #expect(cut.edges == [2, 7, 8] as [Int])
        #expect(cut.value == 23)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-095 CLRS 2nd ed., with v1⇄v2: value 23; S [s, v1, v2, v4]; T [v3, t]; cut [4, 8, 9]")
    func fl095() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v2 10, v2→v1 4, v1→v3 12, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; minimumCut(from: s, to: t, capacity:)
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
        let cut = graph.minimumCut(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
        #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
        #expect(cut.edges == [4, 8, 9] as [Int])
        #expect(cut.value == 23)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-100 Ford–Fulkerson's slow case: Edmonds–Karp needs two augmentations: value 2000; S [s, a, b]; T [t]; cut [3, 4]")
    func fl100() {
        // V [s, a, b, t]; E [s→a 1000, s→b 1000, a→b 1, a→t 1000, b→t 1000]; minimumCut(from: s, to: t, capacity:)
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
        let cut = graph.minimumCut(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["s", "a", "b"] as [String])
        #expect(Array(cut.sinkSide) == ["t"] as [String])
        #expect(cut.edges == [3, 4] as [Int])
        #expect(cut.value == 2000)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-105 NetworkX docs example: value 3.0; S [x, a, c]; T [b, d, e, y]; cut [1, 6]")
    func fl105() {
        // Double V [x, a, b, c, d, e, y]; E [x→a 3.0, x→b 1.0, a→c 3.0, b→c 5.0, b→d 4.0, d→e 2.0, c→y 2.0, e→y 3.0]; minimumCut(from: x, to: y, capacity:)
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
        let cut = graph.minimumCut(from: "x", to: "y") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["x", "a", "c"] as [String])
        #expect(Array(cut.sinkSide) == ["b", "d", "e", "y"] as [String])
        #expect(cut.edges == [1, 6] as [Int])
        #expect(cut.value == 3.0)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Double? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "x", to: "y", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "x", to: "y", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "x", to: "y", capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-110 diamond, two equal cuts: value 2; S [0, 1, 2]; T [3]; cut [2, 3]")
    func fl110() {
        // V [0, 1, 2, 3]; E [0→1 1, 0→2 1, 1→3 1, 2→3 1]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges == [2, 3] as [Int])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-115 cut not at either end: value 2; S [0, 1, 2]; T [3, 4, 5]; cut [2, 3]")
    func fl115() {
        // V [0, 1, 2, 3, 4, 5]; E [0→1 5, 0→2 5, 1→3 1, 2→4 1, 3→5 5, 4→5 5, 1→2 3]; minimumCut(from: 0, to: 5, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 5) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3, 4, 5] as [Int])
        #expect(cut.edges == [2, 3] as [Int])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-120 bipartite matching as flow: value 3; S [s, a, b, c, x, y, z]; T [t]; cut [8, 9, 10]")
    func fl120() {
        // V [s, a, b, c, x, y, z, t]; E [s→a 1, s→b 1, s→c 1, a→x 1, a→y 1, b→x 1, c→x 1, c→z 1, x→t 1, y→t 1, z→t 1]; minimumCut(from: s, to: t, capacity:)
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
        let cut = graph.minimumCut(from: "s", to: "t") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["s", "a", "b", "c", "x", "y", "z"] as [String])
        #expect(Array(cut.sinkSide) == ["t"] as [String])
        #expect(cut.edges == [8, 9, 10] as [Int])
        #expect(cut.value == 3)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-125 lcgnet(8,20,8,9): value 13; S [0, 1, 2, 3, 4, 5, 6]; T [7]; cut [3, 12, 17]")
    func fl125() {
        // lcgnet(8,20,8,9); minimumCut(from: 0, to: 7, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 7) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6] as [Int])
        #expect(Array(cut.sinkSide) == [7] as [Int])
        #expect(cut.edges == [3, 12, 17] as [Int])
        #expect(cut.value == 13)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 7, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-130 lcgnet(10,30,10,20): value 29; S [0, 1, 2, 3, 4, 5, 6, 7, 8]; T [9]; cut [3, 9, 10, 21]")
    func fl130() {
        // lcgnet(10,30,10,20); minimumCut(from: 0, to: 9, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(Array(cut.sinkSide) == [9] as [Int])
        #expect(cut.edges == [3, 9, 10, 21] as [Int])
        #expect(cut.value == 29)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-135 lcgnet(12,40,3,5): value 5; S [0, 3, 4, 6, 9]; T [1, 2, 5, 7, 8, 10, 11]; cut [3, 14, 29]")
    func fl135() {
        // lcgnet(12,40,3,5); minimumCut(from: 0, to: 11, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 11) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 3, 4, 6, 9] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 5, 7, 8, 10, 11] as [Int])
        #expect(cut.edges == [3, 14, 29] as [Int])
        #expect(cut.value == 5)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 11, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 11, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 11, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-143 lcgnet(30,150,5,50)")
    func fl143() {
        // lcgnet(30,150,5,50); minimumCut(from: 0, to: 29, capacity:)
        let pairs: [(Int, Int)] = [(22, 23), (11, 29), (20, 24), (24, 18), (3, 17), (3, 22), (10, 4), (12, 21), (1, 24), (19, 20), (5, 3), (23, 15), (20, 11), (18, 10), (10, 0), (16, 8), (2, 20), (6, 0), (1, 7), (12, 21), (4, 16), (28, 2), (15, 29), (22, 28), (1, 22), (11, 28), (4, 25), (1, 7), (27, 22), (27, 28), (24, 25), (21, 17), (16, 5), (23, 19), (17, 3), (24, 5), (3, 27), (23, 1), (29, 15), (8, 23), (24, 13), (2, 13), (6, 19), (2, 28), (7, 17), (15, 24), (19, 15), (25, 10), (26, 0), (13, 29), (12, 14), (18, 13), (18, 21), (7, 27), (16, 9), (2, 7), (13, 12), (5, 19), (15, 5), (3, 4), (29, 12), (9, 2), (17, 23), (14, 23), (7, 28), (16, 17), (5, 27), (12, 29), (15, 8), (10, 19), (4, 18), (1, 11), (4, 2), (5, 20), (12, 14), (16, 4), (5, 13), (9, 1), (27, 2), (1, 0), (24, 7), (1, 14), (18, 11), (8, 0), (12, 16), (26, 24), (8, 4), (6, 7), (18, 13), (25, 14), (29, 16), (5, 22), (15, 20), (14, 20), (29, 15), (14, 28), (23, 17), (11, 5), (16, 2), (16, 2), (22, 10), (2, 9), (29, 3), (15, 16), (12, 5), (6, 19), (24, 26), (4, 21), (2, 17), (29, 5), (28, 10), (9, 10), (10, 21), (2, 22), (5, 13), (1, 15), (19, 26), (24, 2), (7, 28), (0, 12), (3, 5), (11, 23), (17, 7), (7, 11), (1, 12), (17, 9), (0, 21), (27, 29), (5, 13), (5, 28), (18, 23), (5, 14), (16, 13), (24, 18), (17, 22), (6, 1), (2, 7), (12, 17), (14, 6), (23, 12), (7, 1), (15, 6), (10, 29), (3, 29), (9, 7), (19, 15), (13, 7), (26, 9), (0, 25), (1, 3)]
        let capacities: [Int] = [35, 10, 6, 22, 19, 41, 29, 15, 20, 40, 16, 40, 15, 35, 5, 25, 18, 1, 42, 26, 22, 41, 12, 20, 43, 31, 18, 2, 43, 17, 9, 15, 2, 11, 45, 9, 49, 26, 24, 13, 6, 4, 25, 3, 13, 8, 41, 3, 20, 35, 22, 40, 33, 5, 44, 32, 22, 15, 13, 32, 41, 34, 31, 3, 28, 17, 12, 6, 48, 45, 42, 37, 41, 26, 20, 2, 19, 31, 17, 46, 20, 20, 46, 28, 46, 20, 11, 27, 8, 16, 4, 9, 47, 27, 19, 10, 28, 27, 36, 43, 18, 11, 47, 22, 48, 49, 48, 18, 22, 44, 17, 28, 5, 49, 25, 6, 13, 37, 44, 7, 6, 44, 18, 3, 49, 48, 6, 17, 42, 32, 3, 40, 45, 48, 35, 20, 22, 49, 48, 47, 42, 48, 47, 29, 42, 48, 13, 7, 24, 25]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let cut = graph.minimumCut(from: 0, to: 29) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 25] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29] as [Int])
        #expect(cut.edges == [47, 89, 119, 126] as [Int])
        #expect(cut.value == 32)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 29, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 29, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 29, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-150 Double, dyadic: exact in binary: value 1.125; S [0, 1]; T [2, 3]; cut [1, 2, 4]")
    func fl150() {
        // Double V [0, 1, 2, 3]; E [0→1 0.5, 0→2 0.75, 1→3 0.25, 2→3 1.0, 1→2 0.125]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges == [1, 2, 4] as [Int])
        #expect(cut.value == 1.125)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Double? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-168 undirected: one edge both ways: flow -5 on edge 0: value 5; S [1]; T [0]; cut [0r]")
    func fl168() {
        // undirected V [0, 1]; E [0–1 5]; minimumCut(from: 1, to: 0, capacity:)
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
        let cut = graph.minimumCut(from: 1, to: 0) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [1] as [Int])
        #expect(Array(cut.sinkSide) == [0] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0r"] as [String])
        #expect(cut.value == 5)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 1, to: 0, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-173 undirected path: value 2; S [0]; T [1, 2]; cut [0]")
    func fl173() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–2 3]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-178 undirected: an edge used against its order: value 4; S [0, 1, 2]; T [3]; cut [2]")
    func fl178() {
        // undirected V [0, 1, 2, 3]; E [0–1 4, 2–1 4, 2–3 4, 0–2 1]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
        #expect(cut.value == 4)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-183 undirected: parallel edges and a loop: value 4; S [0]; T [1, 2]; cut [0, 1r]")
    func fl183() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 2, 1–1 7, 1–2 9]; minimumCut(from: 0, to: 2, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 2) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
        #expect(cut.value == 4)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-188 undirected: flows meet head on: value 6; S [0, 1, 2]; T [3]; cut [3, 4]")
    func fl188() {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 0–2 3, 1–2 5, 1–3 1, 2–3 5]; minimumCut(from: 0, to: 3, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 3) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "4"] as [String])
        #expect(cut.value == 6)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-193 undirected Stoer–Wagner paper graph, 1 to 8: value 4; S [1, 2, 5, 6]; T [3, 4, 7, 8]; cut [2, 10]")
    func fl193() {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; minimumCut(from: 1, to: 8, capacity:)
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
        let cut = graph.minimumCut(from: 1, to: 8) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
        #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
        #expect(cut.value == 4)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 1, to: 8, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 1, to: 8, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 1, to: 8, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-198 undirected Wikipedia Gomory–Hu graph, 0 to 5: value 6; S [0, 1, 2, 4]; T [3, 5]; cut [3, 6r, 8]")
    func fl198() {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; minimumCut(from: 0, to: 5, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 5) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
        #expect(Array(cut.sinkSide) == [3, 5] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "6r", "8"] as [String])
        #expect(cut.value == 6)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-203 undirected lcgund(10,25,6,9): value 15; S [0, 1, 2, 3, 4, 5, 6, 7, 8]; T [9]; cut [1r, 2, 18r]")
    func fl203() {
        // lcgund(10,25,6,9); minimumCut(from: 0, to: 9, capacity:)
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
        let cut = graph.minimumCut(from: 0, to: 9) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(Array(cut.sinkSide) == [9] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1r", "2", "18r"] as [String])
        #expect(cut.value == 15)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Int? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-207 undirected grid(4,4), unit: value 2; S [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]; T [15]; cut [20, 23]")
    func fl207() {
        // grid(4,4); minimumCut(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let cut = graph.minimumCut(from: 0, to: 15) { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
        #expect(Array(cut.sinkSide) == [15] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20", "23"] as [String])
        #expect(cut.value == 2)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: 0, to: 15, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] }).minimumCut)
    }

    @Test("FL-212 undirected Double: value 0.75; S [a]; T [b, c]; cut [0, 2]")
    func fl212() {
        // Double undirected V [a, b, c]; E [a–b 0.5, b–c 1.5, a–c 0.25]; minimumCut(from: a, to: c, capacity:)
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
        let cut = graph.minimumCut(from: "a", to: "c") { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        #expect(Array(cut.sourceSide) == ["a"] as [String])
        #expect(Array(cut.sinkSide) == ["b", "c"] as [String])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "2"] as [String])
        #expect(cut.value == 0.75)
        // Its edges are every edge from the source side to the sink side, zero capacities included; its
        // value is their capacity.
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // Brute force over every cut separating s from t: the least value, and the least sink side among
        // the minimum cuts, their intersection (minimum cuts form a lattice).
        let others = (0 ..< n).filter { $0 != s && $0 != t }
        var best: Double? = nil
        var leastSink = Set(0 ..< n)
        for mask in 0 ..< (1 << others.count) {
            var inS = [Bool](repeating: false, count: n)
            inS[s] = true
            for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            let sink = Set((0 ..< n).filter { !inS[$0] })
            if best == nil || value < best! {
                best = value
                leastSink = sink
            } else if value == best! {
                leastSink.formIntersection(sink)
            }
        }
        #expect(best == cut.value)
        #expect(leastSink == Set((0 ..< n).filter { reaches[$0] }))
        // The same cut as every maximum flow's.
        #expect(cut == graph.maximumFlow(from: "a", to: "c", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.edmondsKarpMaximumFlow(from: "a", to: "c", capacity: { capacities[$0] }).minimumCut)
        #expect(cut == graph.dinicMaximumFlow(from: "a", to: "c", capacity: { capacities[$0] }).minimumCut)
    }
}
