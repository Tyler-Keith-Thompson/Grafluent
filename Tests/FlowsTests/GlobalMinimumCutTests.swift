// `minimumCut(capacity:)` (catalog §GlobalMinimumCut, §DirectedGlobalMinimumCut): Nagamochi–Ibaraki
// on `Graph`, Hao–Orlin on `DirectedGraph`; the value exactly; the sides exactly where the catalog
// pins them (the only minimum cut, or the first vertex's component when the positive edges leave
// several); nil below two vertices; the cut's edges and value checked here from its sides, the first
// vertex on the source side of an undirected cut; by brute force the least cut over every nonempty
// proper vertex set; the same cut on a second call. Directed rows are `AdjacencyList`, or
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

@Suite("minimumCut(capacity:)")
struct GlobalMinimumCutTests {
    @Test("FL-227 empty graph: nil")
    func fl227() {
        // undirected V []; E []; minimumCut(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        // Fewer than two vertices: no nonempty proper vertex set.
        #expect(result == nil)
    }

    @Test("FL-228 one vertex: nil")
    func fl228() {
        // undirected V [0]; E [0–0 3]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 0)]
        let capacities: [Int] = [3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        // Fewer than two vertices: no nonempty proper vertex set.
        #expect(result == nil)
    }

    @Test("FL-229 two vertices, one edge: value 4; S [0]; T [1]; cut [0]")
    func fl229() throws {
        // undirected V [0, 1]; E [0–1 4]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [4]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
        #expect(cut.value == 4)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-230 two vertices, parallel edges: weights add: value 7; S [0]; T [1]; cut [0, 1r, 2]")
    func fl230() throws {
        // undirected V [0, 1]; E [0–1 4, 1–0 1, 0–1 2]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
        let capacities: [Int] = [4, 1, 2]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r", "2"] as [String])
        #expect(cut.value == 7)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-231 two vertices, no edge: value 0; S [0]; T [1]; cut []")
    func fl231() throws {
        // undirected V [0, 1]; E []; minimumCut(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
        #expect(cut.value == 0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-232 disconnected: value 0, the first vertex's component: value 0; S [0, 1]; T [2, 3]; cut []")
    func fl232() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 5, 2–3 6]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let capacities: [Int] = [5, 6]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
        #expect(cut.value == 0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-233 disconnected, first vertex isolated: value 0; S [0]; T [1, 2]; cut []")
    func fl233() throws {
        // undirected V [0, 1, 2]; E [1–2 5]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 2)]
        let capacities: [Int] = [5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0] as [Int])
        #expect(Array(cut.sinkSide) == [1, 2] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
        #expect(cut.value == 0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-234 connected only by a zero edge: positive edges decide the components: value 0; S [0, 1]; T [2, 3]; cut [1]")
    func fl234() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 5, 1–2 0, 2–3 6]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [5, 0, 6]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1"] as [String])
        #expect(cut.value == 0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-235 self-loops ignored: value 5; S [0, 2]; T [1]; cut [1, 2r]")
    func fl235() throws {
        // undirected V [0, 1, 2]; E [0–0 9, 0–1 2, 1–2 3, 2–2 9, 0–2 4]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2), (0, 2)]
        let capacities: [Int] = [9, 2, 3, 9, 4]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 2] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2r"] as [String])
        #expect(cut.value == 5)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-236 triangle, equal weights: ties: three minimum cuts: value 2 (one of several minimum cuts)")
    func fl236() throws {
        // K(3); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let capacities: [Int] = [1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 2)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-237 path P(5): value 1 (one of several minimum cuts)")
    func fl237() throws {
        // P(5); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let capacities: [Int] = [1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 1)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-238 cycle C(6): value 2 (one of several minimum cuts)")
    func fl238() throws {
        // C(6); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 2)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-239 K(5): value 4 (one of several minimum cuts)")
    func fl239() throws {
        // K(5); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 4)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-240 Stoer–Wagner paper (1997, figure 1): value 4: value 4; S [1, 2, 5, 6]; T [3, 4, 7, 8]; cut [2, 10]")
    func fl240() throws {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
        #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
        #expect(cut.value == 4)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-241 NetworkX stoer_wagner docs example: value 4 (one of several minimum cuts)")
    func fl241() throws {
        // undirected V [x, a, b, c, d, e, y]; E [x–a 3, x–b 1, a–c 3, b–c 5, b–d 4, d–e 2, c–y 2, e–y 3]; minimumCut(capacity:)
        let pairs: [(String, String)] = [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")]
        let capacities: [Int] = [3, 1, 3, 5, 4, 2, 2, 3]
        let graph = UndirectedAdjacencyList<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["x", "a", "b", "c", "d", "e", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 4)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-242 Wikipedia Gomory–Hu graph: value 6 (one of several minimum cuts)")
    func fl242() throws {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 6)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-243 two K(4) joined by one light edge: value 1; S [0, 1, 2, 3]; T [4, 5, 6, 7]; cut [12]")
    func fl243() throws {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1 3, 0–2 3, 0–3 3, 1–2 3, 1–3 3, 2–3 3, 4–5 3, 4–6 3, 4–7 3, 5–6 3, 5–7 3, 6–7 3, 3–4 1]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (3, 4)]
        let capacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3] as [Int])
        #expect(Array(cut.sinkSide) == [4, 5, 6, 7] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["12"] as [String])
        #expect(cut.value == 1)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-244 Petersen, unit: value 3 (one of several minimum cuts)")
    func fl244() throws {
        // nx(petersen_graph); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 3)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-245 grid(3,4), unit: a corner: value 2 (one of several minimum cuts)")
    func fl245() throws {
        // grid(3,4); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 2)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-246 lcgund(10,25,6,9): value 3; S [0, 1, 2, 3, 4, 5, 6, 7, 9]; T [8]; cut [20r, 24r]")
    func fl246() throws {
        // lcgund(10,25,6,9); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let capacities: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 9] as [Int])
        #expect(Array(cut.sinkSide) == [8] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20r", "24r"] as [String])
        #expect(cut.value == 3)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-247 lcgund(12,40,7,20): value 27; S [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11]; T [3]; cut [5r, 34r]")
    func fl247() throws {
        // lcgund(12,40,7,20); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(2, 11), (5, 1), (4, 0), (10, 7), (9, 10), (3, 0), (4, 1), (6, 5), (8, 5), (1, 2), (5, 11), (7, 4), (1, 11), (2, 8), (0, 8), (6, 8), (5, 8), (7, 4), (6, 7), (1, 11), (11, 5), (11, 8), (9, 2), (7, 4), (6, 1), (6, 0), (8, 0), (11, 2), (11, 7), (9, 1), (4, 10), (0, 9), (8, 2), (8, 7), (3, 0), (11, 5), (0, 8), (6, 2), (2, 11), (2, 10)]
        let capacities: [Int] = [14, 20, 20, 16, 6, 12, 15, 5, 14, 16, 10, 13, 9, 5, 7, 15, 15, 17, 20, 1, 1, 19, 11, 6, 11, 16, 18, 8, 6, 15, 16, 4, 6, 12, 15, 4, 6, 2, 8, 11]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(Array(cut.sinkSide) == [3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["5r", "34r"] as [String])
        #expect(cut.value == 27)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-248 Double weights: value 0.375; S [0, 1]; T [2]; cut [1, 2]")
    func fl248() throws {
        // Double undirected V [0, 1, 2]; E [0–1 0.5, 1–2 0.25, 0–2 0.125]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [Double] = [0.5, 0.25, 0.125]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2"] as [String])
        #expect(cut.value == 0.375)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Double? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == cut.value)
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-250 directed: one vertex: nil")
    func fl250() {
        // V [0]; E []; minimumCut(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        // Fewer than two vertices: no nonempty proper vertex set.
        #expect(result == nil)
    }

    @Test("FL-251 directed: one edge: 1 cannot reach 0: value 0: value 0; S [1]; T [0]; cut []")
    func fl251() throws {
        // V [0, 1]; E [0→1 4]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [4]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [1] as [Int])
        #expect(Array(cut.sinkSide) == [0] as [Int])
        #expect(cut.edges == [] as [Int])
        #expect(cut.value == 0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-252 directed: two-cycle: value 2; S [1]; T [0]; cut [1]")
    func fl252() throws {
        // V [0, 1]; E [0→1 4, 1→0 2]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [4, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [1] as [Int])
        #expect(Array(cut.sinkSide) == [0] as [Int])
        #expect(cut.edges == [1] as [Int])
        #expect(cut.value == 2)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-253 directed: cycle Cd(4): value 1 (one of several minimum cuts)")
    func fl253() throws {
        // Cd(4); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let capacities: [Int] = [1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 1)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-254 directed: complete Kd(4): value 3 (one of several minimum cuts)")
    func fl254() throws {
        // Kd(4); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 3)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-255 directed: CLRS figure 26.1: t has no out-edge: value 0 (one of several minimum cuts)")
    func fl255() throws {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; minimumCut(capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-256 directed: lcgnet(8,30,8,9): value 4; S [0, 1, 3, 4, 5, 6, 7]; T [2]; cut [14, 21]")
    func fl256() throws {
        // lcgnet(8,30,8,9); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(4, 0), (3, 6), (2, 3), (5, 7), (6, 3), (0, 6), (6, 0), (1, 4), (5, 6), (3, 6), (0, 4), (2, 1), (0, 7), (1, 3), (5, 2), (6, 5), (0, 5), (0, 7), (0, 5), (3, 1), (4, 7), (4, 2), (7, 4), (1, 3), (0, 1), (5, 7), (7, 4), (2, 5), (4, 1), (7, 4)]
        let capacities: [Int] = [6, 6, 2, 2, 5, 6, 3, 5, 5, 7, 1, 5, 9, 9, 3, 4, 2, 2, 3, 1, 4, 1, 5, 9, 1, 3, 4, 9, 4, 9]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1, 3, 4, 5, 6, 7] as [Int])
        #expect(Array(cut.sinkSide) == [2] as [Int])
        #expect(cut.edges == [14, 21] as [Int])
        #expect(cut.value == 4)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-257 directed: lcgnet(10,40,21,5): value 5 (one of several minimum cuts)")
    func fl257() throws {
        // lcgnet(10,40,21,5); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 9), (6, 5), (6, 2), (2, 8), (2, 3), (0, 8), (4, 0), (8, 7), (6, 0), (3, 1), (9, 0), (8, 7), (7, 8), (7, 1), (0, 9), (1, 3), (1, 5), (6, 4), (1, 7), (4, 3), (3, 8), (2, 3), (4, 7), (7, 0), (8, 6), (4, 8), (0, 6), (4, 8), (4, 5), (4, 1), (7, 6), (6, 1), (7, 8), (9, 4), (0, 1), (5, 7), (0, 4), (2, 5), (6, 9), (5, 0)]
        let capacities: [Int] = [4, 5, 5, 1, 5, 4, 3, 3, 3, 2, 3, 4, 1, 1, 4, 2, 2, 5, 2, 2, 3, 4, 4, 4, 4, 1, 1, 1, 5, 2, 4, 3, 3, 3, 1, 5, 3, 2, 1, 1]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 5)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-492 UInt8, every vertex within 255: a merged group's connection passes 255")
    func fl492() throws {
        // UInt8 undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [1–5 5, 2–3 16, 4–7 21, 4–0 3, 3–7 39, 6–3 33, 6–0 43, 2–0 46, 5–0 1, 6–2 39, 2–6 119, 6–1 12, 0–7 33, 7–2 20, 0–4 66, 4–5 24, 1–3 42, 5–1 10, 7–3 40,…
        let pairs: [(Int, Int)] = [(1, 5), (2, 3), (4, 7), (4, 0), (3, 7), (6, 3), (6, 0), (2, 0), (5, 0), (6, 2), (2, 6), (6, 1), (0, 7), (7, 2), (0, 4), (4, 5), (1, 3), (5, 1), (7, 3), (1, 4), (4, 7), (4, 1), (3, 0), (3, 0), (6, 3), (3, 6), (2, 3)]
        let capacities: [UInt8] = [5, 16, 21, 3, 39, 33, 43, 46, 1, 39, 119, 12, 33, 20, 66, 24, 42, 10, 40, 22, 50, 20, 20, 12, 8, 1, 7]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 6, 7] as [Int])
        #expect(Array(cut.sinkSide) == [5] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "8r", "15", "17r"] as [String])
        #expect(cut.value == 40)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-493 UInt8, labels shuffled: the fuzzer's case: the greatest vertex sum 229")
    func fl493() throws {
        // UInt8 undirected V [6, 2, 3, 5, 4, 0, 1]; E [2–3 40, 3–6 63, 6–4 63, 2–0 63, 2–5 63, 6–5 63, 5–1 40, 4–5 63]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(2, 3), (3, 6), (6, 4), (2, 0), (2, 5), (6, 5), (5, 1), (4, 5)]
        let capacities: [UInt8] = [40, 63, 63, 63, 63, 63, 40, 63]
        let graph = UndirectedAdjacencyList<Int>(vertices: [6, 2, 3, 5, 4, 0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [6, 2, 3, 5, 4, 0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [6, 2, 3, 5, 4, 0] as [Int])
        #expect(Array(cut.sinkSide) == [1] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["6"] as [String])
        #expect(cut.value == 40)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-494 UInt8 star, the centre's sum past 255: the answer 200 fits: value 200 (one of several minimum cuts)")
    func fl494() throws {
        // UInt8 undirected V [0, 1, 2, 3]; E [0–1 200, 0–2 200, 0–3 200]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let capacities: [UInt8] = [200, 200, 200]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 200)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-497 directed: UInt8, the capacities into a vertex past 255: value 8 (one of several minimum cuts)")
    func fl497() throws {
        // UInt8 V [0, 1, 2]; E [1→0 200, 2→0 200, 0→1 5, 0→2 5, 1→2 3, 2→1 3]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 0), (2, 0), (0, 1), (0, 2), (1, 2), (2, 1)]
        let capacities: [UInt8] = [200, 200, 5, 5, 3, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 8)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-498 directed: UInt8, the review's edges as arcs: value 11; S [5]; T [0, 1, 2, 3, 4, 6, 7]; cut [8, 17]")
    func fl498() throws {
        // UInt8 V [0, 1, 2, 3, 4, 5, 6, 7]; E [1→5 5, 2→3 16, 4→7 21, 4→0 3, 3→7 39, 6→3 33, 6→0 43, 2→0 46, 5→0 1, 6→2 39, 2→6 119, 6→1 12, 0→7 33, 7→2 20, 0→4 66, 4→5 24, 1→3 42, 5→1 10, 7→3 40, 1→4 22, 4→…
        let pairs: [(Int, Int)] = [(1, 5), (2, 3), (4, 7), (4, 0), (3, 7), (6, 3), (6, 0), (2, 0), (5, 0), (6, 2), (2, 6), (6, 1), (0, 7), (7, 2), (0, 4), (4, 5), (1, 3), (5, 1), (7, 3), (1, 4), (4, 7), (4, 1), (3, 0), (3, 0), (6, 3), (3, 6), (2, 3)]
        let capacities: [UInt8] = [5, 16, 21, 3, 39, 33, 43, 46, 1, 39, 119, 12, 33, 20, 66, 24, 42, 10, 40, 22, 50, 20, 20, 12, 8, 1, 7]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [5] as [Int])
        #expect(Array(cut.sinkSide) == [0, 1, 2, 3, 4, 6, 7] as [Int])
        #expect(cut.edges == [8, 17] as [Int])
        #expect(cut.value == 11)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-499 Double cycle, ties: value 1.0 (one of several minimum cuts)")
    func fl499() throws {
        // Double undirected V [0, 1, 2, 3]; E [0–1 0.5, 1–2 0.5, 2–3 0.5, 3–0 0.5]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let capacities: [Double] = [0.5, 0.5, 0.5, 0.5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 1.0)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Double? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == cut.value)
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-500 Double, one light edge: value 0.875; S [0, 1]; T [2, 3]; cut [1, 3r, 4]")
    func fl500() throws {
        // Double undirected V [0, 1, 2, 3]; E [0–1 0.75, 1–2 0.25, 2–3 0.75, 3–0 0.5, 0–2 0.125]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let capacities: [Double] = [0.75, 0.25, 0.75, 0.5, 0.125]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "3r", "4"] as [String])
        #expect(cut.value == 0.875)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Double? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == cut.value)
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-501 directed: Double: value 0.25 (one of several minimum cuts)")
    func fl501() throws {
        // Double V [0, 1, 2]; E [0→1 0.25, 1→2 0.5, 2→0 0.75, 1→0 0.125]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 0)]
        let capacities: [Double] = [0.25, 0.5, 0.75, 0.125]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 0.25)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        #expect(cut.edges == pairs.indices.filter { ends[$0].0 != ends[$0].1 && !reaches[ends[$0].0] && reaches[ends[$0].1] })
        #expect(cut.value == cut.edges.reduce(0) { $0 + capacities[$1] })
        // Brute force: the least cut over every nonempty proper vertex set.
        var best: Double? = nil
        for mask in 1 ..< (1 << n) - 1 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] && !inS[b] { value += capacities[k] }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == cut.value)
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-526 Int.max path: the middle vertex's sum passes Int, so the sums run in Int128")
    func fl526() throws {
        // undirected V [0, 1, 2]; E [0–1 9223372036854775807, 1–2 9223372036854775807]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        // Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.
        #expect(cut.value == 9223372036854775807)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int128? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int128 = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int128(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int128(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-528 found only in a later phase: Nagamochi–Ibaraki's first phase misses it")
    func fl528() throws {
        // undirected V [0, 1, 2, 3, 4, 5]; E [2–0 1, 4–1 1, 5–2 2, 4–0 2, 0–5 2, 3–1 3, 1–0 1]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(2, 0), (4, 1), (5, 2), (4, 0), (0, 5), (3, 1), (1, 0)]
        let capacities: [Int] = [1, 1, 2, 2, 2, 3, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 2, 4, 5] as [Int])
        #expect(Array(cut.sinkSide) == [1, 3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "6r"] as [String])
        #expect(cut.value == 2)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Int? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Int = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += Int(capacities[k]) }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == Int(cut.value))
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }

    @Test("FL-529 Double, found only in a later phase: on the heap rather than the bucket queue")
    func fl529() throws {
        // Double undirected V [0, 1, 2, 3, 4, 5]; E [0–3 2.25, 0–1 2.0, 2–3 1.5, 2–3 2.0, 4–0 2.0, 4–5 2.0, 1–5 1.25]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (2, 3), (2, 3), (4, 0), (4, 5), (1, 5)]
        let capacities: [Double] = [2.25, 2.0, 1.5, 2.0, 2.0, 2.0, 1.25]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.minimumCut { position in
            asked.append(position)
            return capacities[position]
        }
        // `capacity` is called once per non-loop edge, in position order; self-loops are never asked.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let cut = try #require(result)
        #expect(Array(cut.sourceSide) == [0, 1, 4, 5] as [Int])
        #expect(Array(cut.sinkSide) == [2, 3] as [Int])
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
        #expect(cut.value == 2.25)
        let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }
        #expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })
        #expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        // Its edges are every edge from the source side to the sink side; its value is their capacity.
        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && reaches[ends[$0].0] != reaches[ends[$0].1] }
        #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { reaches[ends[$0].1] ? "\($0)" : "\($0)r" })
        #expect(cut.value == crossing.reduce(0) { $0 + capacities[$1] })
        // The first vertex is on the source side.
        #expect(!reaches[0])
        // Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).
        var best: Double? = nil
        for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {
            let inS = (0 ..< n).map { mask & (1 << $0) != 0 }
            var value: Double = 0
            for k in pairs.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if inS[a] != inS[b] { value += capacities[k] }
            }
            if best == nil || value < best! { best = value }
        }
        #expect(best == cut.value)
        // The same cut on a second call.
        #expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)
    }
}
