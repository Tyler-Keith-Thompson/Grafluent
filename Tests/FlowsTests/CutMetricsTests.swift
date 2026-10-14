// The cut metrics of a vertex set against its complement (catalog §CutMetrics): `cutSize`, `volume`,
// `conductance`, `normalizedCutSize`, `edgeExpansion`, `mixingExpansion`, `nodeExpansion` and
// `boundaryExpansion`, unweighted and weighted, exactly (NaN and infinity for a zero denominator);
// the cut size, volume and neighborhood written out here from the edges; a repeated vertex counted
// once. Directed rows are `AdjacencyList`, or `DirectedPseudograph` when an edge repeats; undirected
// rows `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each built by inserting the
// row's vertices, then its edges in order, so positions are the catalog's. In-test checks number
// vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates
// each row with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("Cut metrics")
struct CutMetricsTests {
    @Test("FL-553 empty set: every ratio over |S| is NaN")
    func fl553() {
        // undirected V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; cut metrics of []
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let s = [] as [Int]
        #expect(graph.cutSize(of: s) == 0)
        #expect(graph.volume(of: s) == 0)
        #expect((graph.conductance(of: s)).isNaN)
        #expect((graph.normalizedCutSize(of: s)).isNaN)
        #expect((graph.edgeExpansion(of: s)).isNaN)
        #expect(graph.mixingExpansion(of: s) == 0.0)
        #expect((graph.nodeExpansion(of: s)).isNaN)
        #expect((graph.boundaryExpansion(of: s)).isNaN)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(reached.isEmpty)
    }

    @Test("FL-554 whole vertex set: T empty")
    func fl554() {
        // undirected V [0, 1, 2]; E [0–1, 1–2]; cut metrics of [0, 1, 2]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let s = [0, 1, 2] as [Int]
        #expect(graph.cutSize(of: s) == 0)
        #expect(graph.volume(of: s) == 4)
        #expect((graph.conductance(of: s)).isNaN)
        #expect((graph.normalizedCutSize(of: s)).isNaN)
        #expect((graph.edgeExpansion(of: s)).isNaN)
        #expect(graph.mixingExpansion(of: s) == 0.0)
        #expect(graph.nodeExpansion(of: s) == 1.0)
        #expect(graph.boundaryExpansion(of: s) == 0.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-555 path P(4), first half")
    func fl555() {
        // P(4); cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let s = [0, 1] as [Int]
        #expect(graph.cutSize(of: s) == 1)
        #expect(graph.volume(of: s) == 3)
        #expect(graph.conductance(of: s) == 0.3333333333333333)
        #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
        #expect(graph.edgeExpansion(of: s) == 0.5)
        #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
        #expect(graph.nodeExpansion(of: s) == 1.5)
        #expect(graph.boundaryExpansion(of: s) == 0.5)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-556 NetworkX doc: C(4), S = {0, 1}")
    func fl556() {
        // C(4); cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let s = [0, 1] as [Int]
        #expect(graph.cutSize(of: s) == 2)
        #expect(graph.volume(of: s) == 4)
        #expect(graph.conductance(of: s) == 0.5)
        #expect(graph.normalizedCutSize(of: s) == 1.0)
        #expect(graph.edgeExpansion(of: s) == 1.0)
        #expect(graph.mixingExpansion(of: s) == 0.25)
        #expect(graph.nodeExpansion(of: s) == 2.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-557 NetworkX doc: C(6), S = {0, 2, 4}")
    func fl557() {
        // C(6); cut metrics of [0, 2, 4]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let s = [0, 2, 4] as [Int]
        #expect(graph.cutSize(of: s) == 6)
        #expect(graph.volume(of: s) == 6)
        #expect(graph.conductance(of: s) == 1.0)
        #expect(graph.normalizedCutSize(of: s) == 2.0)
        #expect(graph.edgeExpansion(of: s) == 2.0)
        #expect(graph.mixingExpansion(of: s) == 0.5)
        #expect(graph.nodeExpansion(of: s) == 1.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-558 K(5), S = {0, 1}")
    func fl558() {
        // K(5); cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let s = [0, 1] as [Int]
        #expect(graph.cutSize(of: s) == 6)
        #expect(graph.volume(of: s) == 8)
        #expect(graph.conductance(of: s) == 0.75)
        #expect(graph.normalizedCutSize(of: s) == 1.25)
        #expect(graph.edgeExpansion(of: s) == 3.0)
        #expect(graph.mixingExpansion(of: s) == 0.3)
        #expect(graph.nodeExpansion(of: s) == 2.5)
        #expect(graph.boundaryExpansion(of: s) == 1.5)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-559 Petersen, the outer cycle")
    func fl559() {
        // nx(petersen_graph); cut metrics of [0, 1, 2, 3, 4]
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let s = [0, 1, 2, 3, 4] as [Int]
        #expect(graph.cutSize(of: s) == 5)
        #expect(graph.volume(of: s) == 15)
        #expect(graph.conductance(of: s) == 0.3333333333333333)
        #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
        #expect(graph.edgeExpansion(of: s) == 1.0)
        #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
        #expect(graph.nodeExpansion(of: s) == 2.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-560 self-loops count twice in the volume")
    func fl560() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let s = [0] as [Int]
        #expect(graph.cutSize(of: s) == 1)
        #expect(graph.volume(of: s) == 3)
        #expect(graph.conductance(of: s) == 0.3333333333333333)
        #expect(graph.normalizedCutSize(of: s) == 0.5333333333333333)
        #expect(graph.edgeExpansion(of: s) == 1.0)
        #expect(graph.mixingExpansion(of: s) == 0.125)
        #expect(graph.nodeExpansion(of: s) == 2.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-561 parallel edges each cross")
    func fl561() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 3, 0–1 5, 1–2 7]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1), (1, 2)]
        let weights: [Int] = [2, 3, 5, 7]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let s = [0] as [Int]
        #expect(graph.cutSize(of: s) == 3)
        #expect(graph.volume(of: s) == 3)
        #expect(graph.conductance(of: s) == 1.0)
        #expect(graph.normalizedCutSize(of: s) == 1.6)
        #expect(graph.edgeExpansion(of: s) == 3.0)
        #expect(graph.mixingExpansion(of: s) == 0.375)
        #expect(graph.nodeExpansion(of: s) == 1.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 10)
        #expect(graph.volume(of: s, weight: { weights[$0] }) == 10)
        #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.0)
        #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.4166666666666665)
        #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 10.0)
        #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.29411764705882354)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
        // `weight` is called once per edge, self-loops included, in position order.
        var asked: [Int] = []
        _ = graph.cutSize(of: s) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(asked == Array(pairs.indices))
    }

    @Test("FL-562 weighted, isolated vertex: vol(S) = 0")
    func fl562() {
        // undirected V [0, 1, 2, 3]; E [0–1 1, 1–2 2, 0–2 4]; cut metrics of [3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let weights: [Int] = [1, 2, 4]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let s = [3] as [Int]
        #expect(graph.cutSize(of: s) == 0)
        #expect(graph.volume(of: s) == 0)
        #expect((graph.conductance(of: s)).isNaN)
        #expect((graph.normalizedCutSize(of: s)).isNaN)
        #expect(graph.edgeExpansion(of: s) == 0.0)
        #expect(graph.mixingExpansion(of: s) == 0.0)
        #expect(graph.nodeExpansion(of: s) == 0.0)
        #expect(graph.boundaryExpansion(of: s) == 0.0)
        #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 0)
        #expect(graph.volume(of: s, weight: { weights[$0] }) == 0)
        #expect((graph.conductance(of: s, weight: { Double(weights[$0]) })).isNaN)
        #expect((graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) })).isNaN)
        #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
        #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
        // `weight` is called once per edge, self-loops included, in position order.
        var asked: [Int] = []
        _ = graph.cutSize(of: s) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(asked == Array(pairs.indices))
    }

    @Test("FL-563 weighted lcgund(10,25,6,9)")
    func fl563() {
        // lcgund(10,25,6,9); cut metrics of [0, 2, 3, 7]
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let weights: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let s = [0, 2, 3, 7] as [Int]
        #expect(graph.cutSize(of: s) == 12)
        #expect(graph.volume(of: s) == 22)
        #expect(graph.conductance(of: s) == 0.5454545454545454)
        #expect(graph.normalizedCutSize(of: s) == 0.974025974025974)
        #expect(graph.edgeExpansion(of: s) == 3.0)
        #expect(graph.mixingExpansion(of: s) == 0.24)
        #expect(graph.nodeExpansion(of: s) == 2.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 70)
        #expect(graph.volume(of: s, weight: { weights[$0] }) == 136)
        #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 0.546875)
        #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.0615808823529411)
        #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 17.5)
        #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.26515151515151514)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.reduce(0) { $0 + (inS[$1.0] ? 1 : 0) + (inS[$1.1] ? 1 : 0) })
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1) + ends.filter { inS[$0.1] }.map(\.0))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
        // `weight` is called once per edge, self-loops included, in position order.
        var asked: [Int] = []
        _ = graph.cutSize(of: s) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(asked == Array(pairs.indices))
    }

    @Test("FL-564 directed: both directions cross, out-degree volume")
    func fl564() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→0, 1→3, 3→3]; cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 0), (1, 3), (3, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let s = [0, 1] as [Int]
        #expect(graph.cutSize(of: s) == 2)
        #expect(graph.volume(of: s) == 3)
        #expect(graph.conductance(of: s) == 1.0)
        #expect(graph.normalizedCutSize(of: s) == 1.6666666666666665)
        #expect(graph.edgeExpansion(of: s) == 1.0)
        #expect(graph.mixingExpansion(of: s) == 0.2)
        #expect(graph.nodeExpansion(of: s) == 1.5)
        #expect(graph.boundaryExpansion(of: s) == 0.5)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.filter { inS[$0.0] }.count)
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-565 directed: successors, not predecessors")
    func fl565() {
        // V [0, 1, 2, 3]; E [0→1, 2→0, 3→0]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 1), (2, 0), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let s = [0] as [Int]
        #expect(graph.cutSize(of: s) == 3)
        #expect(graph.volume(of: s) == 1)
        #expect(graph.conductance(of: s) == 3.0)
        #expect(graph.normalizedCutSize(of: s) == 4.5)
        #expect(graph.edgeExpansion(of: s) == 3.0)
        #expect(graph.mixingExpansion(of: s) == 0.5)
        #expect(graph.nodeExpansion(of: s) == 1.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.filter { inS[$0.0] }.count)
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
    }

    @Test("FL-566 directed: self-loop counts once")
    func fl566() {
        // V [0, 1]; E [0→0 3, 0→1 2, 1→0 5]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let weights: [Int] = [3, 2, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let s = [0] as [Int]
        #expect(graph.cutSize(of: s) == 2)
        #expect(graph.volume(of: s) == 2)
        #expect(graph.conductance(of: s) == 2.0)
        #expect(graph.normalizedCutSize(of: s) == 3.0)
        #expect(graph.edgeExpansion(of: s) == 2.0)
        #expect(graph.mixingExpansion(of: s) == 0.3333333333333333)
        #expect(graph.nodeExpansion(of: s) == 2.0)
        #expect(graph.boundaryExpansion(of: s) == 1.0)
        #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 7)
        #expect(graph.volume(of: s, weight: { weights[$0] }) == 5)
        #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.4)
        #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 2.8000000000000003)
        #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 7.0)
        #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.35)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.filter { inS[$0.0] }.count)
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
        // `weight` is called once per edge, self-loops included, in position order.
        var asked: [Int] = []
        _ = graph.cutSize(of: s) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(asked == Array(pairs.indices))
    }

    @Test("FL-567 directed: CLRS figure 26.1")
    func fl567() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; cut metrics of [s, v1, v2]
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let weights: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        let s = ["s", "v1", "v2"] as [String]
        #expect(graph.cutSize(of: s) == 3)
        #expect(graph.volume(of: s) == 5)
        #expect(graph.conductance(of: s) == 0.75)
        #expect(graph.normalizedCutSize(of: s) == 1.35)
        #expect(graph.edgeExpansion(of: s) == 1.0)
        #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
        #expect(graph.nodeExpansion(of: s) == 1.3333333333333333)
        #expect(graph.boundaryExpansion(of: s) == 0.6666666666666666)
        #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 35)
        #expect(graph.volume(of: s, weight: { weights[$0] }) == 59)
        #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 0.875)
        #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.468220338983051)
        #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 11.666666666666666)
        #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.17676767676767677)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.filter { inS[$0.0] }.count)
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
        // `weight` is called once per edge, self-loops included, in position order.
        var asked: [Int] = []
        _ = graph.cutSize(of: s) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(asked == Array(pairs.indices))
    }

    @Test("FL-568 directed: lcgnet(12,40,3,5)")
    func fl568() {
        // lcgnet(12,40,3,5); cut metrics of [1, 4, 5, 6, 11]
        let pairs: [(Int, Int)] = [(11, 7), (10, 0), (7, 5), (9, 7), (8, 9), (5, 3), (7, 8), (10, 11), (5, 11), (7, 1), (1, 6), (7, 5), (9, 3), (9, 0), (0, 5), (2, 5), (1, 5), (5, 11), (8, 5), (2, 1), (11, 3), (1, 11), (0, 6), (2, 9), (7, 3), (3, 9), (9, 3), (0, 9), (10, 4), (9, 11), (2, 11), (3, 9), (2, 10), (4, 9), (9, 4), (5, 0), (8, 5), (11, 9), (11, 1), (11, 3)]
        let weights: [Int] = [1, 4, 5, 3, 4, 5, 1, 2, 4, 5, 2, 4, 4, 2, 1, 2, 2, 2, 2, 1, 2, 5, 5, 1, 4, 5, 5, 4, 5, 1, 1, 4, 1, 1, 2, 5, 2, 1, 4, 2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let s = [1, 4, 5, 6, 11] as [Int]
        #expect(graph.cutSize(of: s) == 21)
        #expect(graph.volume(of: s) == 13)
        #expect(graph.conductance(of: s) == 1.6153846153846154)
        #expect(graph.normalizedCutSize(of: s) == 2.393162393162393)
        #expect(graph.edgeExpansion(of: s) == 4.2)
        #expect(graph.mixingExpansion(of: s) == 0.2625)
        #expect(graph.nodeExpansion(of: s) == 1.6)
        #expect(graph.boundaryExpansion(of: s) == 0.8)
        #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 55)
        #expect(graph.volume(of: s, weight: { weights[$0] }) == 36)
        #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.5277777777777777)
        #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 2.2152777777777777)
        #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 11.0)
        #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.23706896551724138)
        // The definitions written out: the edges with one end in S, the (out-)degree sums, the neighborhood.
        let inS = vertexList.map { s.contains($0) }
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.cutSize(of: s) == ends.filter { inS[$0.0] != inS[$0.1] }.count)
        #expect(graph.volume(of: s) == ends.filter { inS[$0.0] }.count)
        let reached = Set(ends.filter { inS[$0.0] }.map(\.1))
        #expect(graph.nodeExpansion(of: s) == Double(reached.count) / Double(s.count))
        #expect(graph.boundaryExpansion(of: s) == Double(reached.filter { !inS[$0] }.count) / Double(s.count))
        // A vertex listed twice counts once.
        #expect(graph.cutSize(of: s + s) == graph.cutSize(of: s))
        #expect(graph.volume(of: s + s) == graph.volume(of: s))
        #expect(graph.nodeExpansion(of: s + s) == graph.nodeExpansion(of: s))
        // `weight` is called once per edge, self-loops included, in position order.
        var asked: [Int] = []
        _ = graph.cutSize(of: s) { position in
            asked.append(position)
            return weights[position]
        }
        #expect(asked == Array(pairs.indices))
    }
}
