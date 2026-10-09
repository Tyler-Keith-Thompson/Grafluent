// Cases added after planting bugs and after the review: girth's early stop must not cut a search
// short when a longer cycle was found from an earlier root (a 4-cycle on the first vertices, a
// triangle later); shapes on which a round or girth used to cost the whole graph (a windmill whose
// hub is the last vertex, a large grid with a bound, forests and DAGs for girth); conformers whose
// rows break the laws in ways that used to pass silently; iterators copied mid-way; Traversal's
// directed findCycle against simpleCycles. Case IDs (CY-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cycles
import GraphProtocols
import Testing
import Traversal
import Walks

/// A triangle plus an edge 0–1 that only vertex 0's row lists.
private struct HalfListedEdgeGraph: Graph {
    let vertices = [0, 1, 2]
    let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 1)]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.filter { ($0 < 3 || vertex == 0) && (edges[$0].u == vertex || edges[$0].v == vertex) }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { 3 }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { 4 }
    func edgeIndex(of position: Int) -> Int { position }
}

/// Counts the hashes of every `HashCountingVertex` that shares it.
private final class HashCounter: @unchecked Sendable {
    var hashes = 0
}

/// A vertex that counts how often it is hashed.
private struct HashCountingVertex: Hashable {
    let value: Int
    let counter: HashCounter
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.value == rhs.value }
    func hash(into hasher: inout Hasher) {
        counter.hashes += 1
        hasher.combine(value)
    }
}

/// A triangle whose `edgeIndex(of:)` is its position plus 10: out of `0..<edgeIndexBound`.
private struct ShiftedEdgeIndexGraph: Graph {
    let vertices = [0, 1, 2]
    let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]
    func incidentEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].u == vertex || edges[$0].v == vertex } }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { 3 }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { 3 }
    func edgeIndex(of position: Int) -> Int { position + 10 }
}

/// A triangle plus an edge 0–1 that no incidence row lists.
private struct MissingEdgeGraph: Graph {
    let vertices = [0, 1, 2]
    let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 1)]
    func incidentEdges(of vertex: Int) -> [Int] { (0 ..< 3).filter { edges[$0].u == vertex || edges[$0].v == vertex } }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { 3 }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { 4 }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Cycle review cases")
struct CycleReviewTests {
    @Test("CY-1001 girth finds a triangle after a 4-cycle was found from earlier roots")
    func girthAfterLongerCycle() {
        // 0-1-2-3-0, then 4-5-6-4: roots 0 … 3 find 4 first; the triangle must still win.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 4),
        ])
        #expect(graph.girth() == 3)
    }

    @Test("CY-1002 girth finds a 5-cycle after a 6-cycle was found from earlier roots")
    func girthOddAfterEven() {
        let hexagon = (0 ..< 6).map { UndirectedEdge($0, ($0 + 1) % 6) }
        let pentagon = (0 ..< 5).map { UndirectedEdge(6 + $0, 6 + ($0 + 1) % 5) }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 11, edges: hexagon + pentagon)
        #expect(graph.girth() == 5)
    }

    @Test("CY-1003 directed girth finds a 2-cycle after a 3-cycle was found from earlier roots")
    func directedGirthAfterLongerCycle() {
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3),
        ])
        #expect(graph.girth() == 2)
    }

    @Test("CY-1004 a windmill of 20 000 triangles whose hub is the last vertex: each round costs its triangle", .timeLimit(.minutes(1)))
    func windmillHubLast() async {
        await Task {
            let k = 20_000
            let hub = 2 * k
            var edges: [UndirectedEdge<Int>] = []
            for t in 0 ..< k {
                edges.append(UndirectedEdge(2 * t, 2 * t + 1))
                edges.append(UndirectedEdge(2 * t + 1, hub))
                edges.append(UndirectedEdge(hub, 2 * t))
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ... hub, edges: edges)
            var count = 0
            for cycle in graph.simpleCycles() {
                #expect(cycle.vertices == [2 * count, 2 * count + 1, hub])
                count += 1
            }
            #expect(count == k)
            let bounded = graph.simpleCycles(maxLength: 3).reduce(0) { n, _ in n + 1 }
            #expect(bounded == k)
            #expect(graph.girth() == 3)
        }.value
    }

    @Test("CY-1005 a 100 × 100 grid with a bound of 4 and 6: its squares and dominoes", .timeLimit(.minutes(1)))
    func boundedGrid() async {
        await Task {
            let side = 100
            var edges: [UndirectedEdge<Int>] = []
            for v in 0 ..< side * side {
                if v % side + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                if v + side < side * side { edges.append(UndirectedEdge(v, v + side)) }
            }
            let grid = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
            // 99² unit squares; 2 · 99 · 98 dominoes (NetworkX on a 7 × 9 grid: 48 and 82).
            let squares = 99 * 99, dominoes = 2 * 99 * 98
            let upToFour = grid.simpleCycles(maxLength: 4).reduce(0) { n, _ in n + 1 }
            let upToSix = grid.simpleCycles(maxLength: 6).reduce(0) { n, _ in n + 1 }
            #expect(upToFour == squares)
            #expect(upToSix == squares + dominoes)
            #expect(grid.girth() == 4)
        }.value
    }

    @Test("CY-1006 girth of forests and DAGs of 100 000 vertices is nil without a search from every vertex", .timeLimit(.minutes(1)))
    func girthWithoutCycles() async {
        await Task {
            let n = 100_000
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(path.girth() == nil)
            let tree = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge($0, ($0 - 1) / 2) })
            #expect(tree.girth() == nil)
            let tail = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) } + [UndirectedEdge(n - 1, n - 3)])
            #expect(tail.girth() == 3)
            let dag = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).flatMap { [DirectedEdge(from: $0, to: $0 + 1), DirectedEdge(from: $0, to: min($0 + 7, n - 1))] })
            #expect(dag.girth() == nil)
            let back = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) } + [DirectedEdge(from: n - 1, to: n - 4)])
            #expect(back.girth() == 4)
        }.value
    }

    @Test("CY-1007 findCycle traps on an edge index outside 0..<edgeIndexBound")
    func shiftedEdgeIndexTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = ShiftedEdgeIndexGraph().findCycle()
        }
        await #expect(processExitsWith: .failure) {
            _ = ShiftedEdgeIndexGraph().findCycle(from: [1])
        }
    }

    @Test("CY-1008 an edge that no incidence row lists, or only one of its ends lists, traps in cycleBasis, simpleCycles and girth")
    func missingEdgeTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = HalfListedEdgeGraph().cycleBasis()
        }
        await #expect(processExitsWith: .failure) {
            _ = Array(HalfListedEdgeGraph().simpleCycles())
        }
        await #expect(processExitsWith: .failure) {
            _ = MissingEdgeGraph().cycleBasis()
        }
        await #expect(processExitsWith: .failure) {
            _ = Array(MissingEdgeGraph().simpleCycles())
        }
        await #expect(processExitsWith: .failure) {
            _ = MissingEdgeGraph().girth()
        }
    }

    @Test("CY-1009 an iterator copied part-way continues independently, both giving the rest")
    func copiedIterator() {
        // K₄ undirected (7 cycles) and directed both ways (20 cycles).
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let undirected = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let all = Array(undirected.simpleCycles())
        #expect(all.count == 7)
        var iterator = undirected.simpleCycles().makeIterator()
        _ = iterator.next()
        _ = iterator.next()
        var copy = iterator
        var rest: [Cycle<Int, Int>] = [], restOfCopy: [Cycle<Int, Int>] = []
        while let c = iterator.next() { rest.append(c) }
        while let c = copy.next() { restOfCopy.append(c) }
        let expectedVertices: [[Int]] = all.dropFirst(2).map(\.vertices)
        let expectedEdges: [[Int]] = all.dropFirst(2).map(\.edges)
        #expect(rest.map(\.vertices) == expectedVertices)
        #expect(rest.map(\.edges) == expectedEdges)
        #expect(restOfCopy.map(\.vertices) == expectedVertices)
        #expect(restOfCopy.map(\.edges) == expectedEdges)

        let directed = AdjacencyList(vertices: 0 ..< 4, edges: pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] })
        let arcs = Array(directed.simpleCycles())
        #expect(arcs.count == 20)
        var first = directed.simpleCycles(maxLength: 3).makeIterator()
        for _ in 0 ..< 5 { _ = first.next() }
        var second = first
        let a = Array(IteratorSequence(first)), b = Array(IteratorSequence(second))
        let bVertices: [[Int]] = b.map(\.vertices), bEdges: [[Int]] = b.map(\.edges)
        #expect(a.map(\.vertices) == bVertices)
        #expect(a.map(\.edges) == bEdges)
        let short = arcs.filter { $0.length <= 3 }.count
        #expect(a.count + 5 == short)
        _ = second.next()
    }

    @Test("CY-1010 Traversal's directed findCycle is one of simpleCycles, equal up to rotation")
    func directedFindCycleIsSimple() {
        let graphs: [[(Int, Int)]] = [
            [(0, 1), (1, 2), (2, 0)],
            [(0, 1), (1, 2), (2, 3), (3, 1), (3, 0)],
            [(3, 2), (2, 1), (1, 3), (0, 3)],
            [(0, 0)],
            [(0, 1), (1, 0), (1, 2), (2, 1)],
        ]
        for pairs in graphs {
            let n = pairs.reduce(0) { max($0, $1.0, $1.1) } + 1
            let graph = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let found: Cycle<Int, Int>? = graph.findCycle()
            let cycles = Array(graph.simpleCycles())
            #expect(found != nil, "\(pairs)")
            if let found { #expect(cycles.contains(found), "\(pairs): \(found)") }
        }
    }

    @Test("CY-1011 isAcyclic on an indexed adjacency list never hashes a vertex, forest or not")
    func isAcyclicNoHashing() {
        let counter = HashCounter()
        func vertex(_ value: Int) -> HashCountingVertex { HashCountingVertex(value: value, counter: counter) }
        // A tree on 7 vertices (m < n, so no shortcut), and the same with one more edge.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let tree = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge(vertex($0.0), vertex($0.1)) })
        var cyclic = tree
        _ = cyclic.insert(edge: UndirectedEdge(vertex(3), vertex(4)))
        _ = cyclic.remove(edge: UndirectedEdge(vertex(2), vertex(6)))
        counter.hashes = 0
        #expect(tree.isAcyclic)
        #expect(!cyclic.isAcyclic)
        #expect(counter.hashes == 0, "isAcyclic hashed \(counter.hashes) times")
    }
}
