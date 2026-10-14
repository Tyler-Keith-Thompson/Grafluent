// chordlessCycles(maxLength:): the simple cycles whose vertices induce no other edge, directed and
// undirected. Hand-computed cases (complete graphs, wheels, grids, chords), self-loops and
// parallel edges against NetworkX 3.7's `chordless_cycles`, and a property test against
// `simpleCycles()` filtered by an induced-edge count, in content and order, with rows in position
// order or shuffled. Case IDs (CY-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Walks

/// An undirected multigraph on 0..<vertexCount whose incidence rows are shuffled by a seeded
/// generator, unless the seed is 0.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed multigraph on 0..<vertexCount whose out-edge rows are shuffled by a seeded
/// generator, unless the seed is 0.
private struct ShuffledDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [DirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() { rows[edge.source].append(k) }
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.rows = rows
    }

    func outEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func successors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
}

/// A directed multigraph without vertex indices.
private struct UnindexedDigraph: DirectedGraph {
    let base: ReferenceDirectedMultigraph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges }
    func successors(of vertex: Int) -> [Int] { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.outEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

@Suite("Chordless cycles")
struct ChordlessCycleTests {
    @Test("CY-900 K4: the four triangles, canonical, in order")
    func completeGraph() {
        // K(4): 0–1, 0–2, 0–3, 1–2, 1–3, 2–3 at positions 0 … 5.
        var pairs: [UndirectedEdge<Int>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append(UndirectedEdge(u, v)) } }
        let graph = ReferencePseudograph(edges: pairs)
        let cycles = Array(graph.chordlessCycles())
        #expect(cycles.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]])
        #expect(cycles.map(\.edges) == [[0, 3, 1], [0, 4, 2], [1, 5, 2], [3, 5, 4]])
        // K5 and K6: only triangles, C(n, 3) of them.
        for n in [5, 6] {
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< n { for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) } }
            let cycles = Array(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges).chordlessCycles())
            #expect(cycles.count == n * (n - 1) * (n - 2) / 6)
            #expect(cycles.allSatisfy { $0.length == 3 })
        }
    }

    @Test("CY-901 a chord splits a cycle; a grid's chordless cycles are its faces and its outer ring")
    func chordsAndGrids() {
        let pentagon = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        #expect(Array(pentagon.chordlessCycles()).map(\.vertices) == [[0, 1, 2, 3, 4]])
        let chorded = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0), UndirectedEdge(0, 2)])
        let cycles = Array(chorded.chordlessCycles())
        // The square leaves 0 through 4–0 (position 4), the lesser of its two edges there.
        #expect(cycles.map(\.vertices) == [[0, 1, 2], [0, 4, 3, 2]])
        #expect(cycles.map(\.edges) == [[0, 1, 5], [4, 3, 2, 5]])
        // grid(3, 3): four unit squares and the ring of eight around the center.
        var grid: [UndirectedEdge<Int>] = []
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                if c < 2 { grid.append(UndirectedEdge(3 * r + c, 3 * r + c + 1)) }
                if r < 2 { grid.append(UndirectedEdge(3 * r + c, 3 * r + c + 3)) }
            }
        }
        let faces = Array(ReferencePseudograph(edges: grid).chordlessCycles()).map { Set($0.vertices) }
        #expect(Set(faces) == [[0, 1, 3, 4], [1, 2, 4, 5], [3, 4, 6, 7], [4, 5, 7, 8], [0, 1, 2, 5, 8, 7, 6, 3]])
        #expect(faces.count == 5)
        // A wheel W(0; 1..5): five triangles through the hub, and the rim, which has no chord.
        var wheel = (1 ... 5).map { UndirectedEdge(0, $0) }
        wheel += (1 ... 5).map { UndirectedEdge($0, $0 % 5 + 1) }
        let spokes = Array(ReferencePseudograph(edges: wheel).chordlessCycles())
        #expect(spokes.count == 6)
        #expect(spokes.filter { $0.length == 3 }.count == 5)
        #expect(spokes.contains { Set($0.vertices) == [1, 2, 3, 4, 5] })
    }

    @Test("CY-902 directed: opposite edges make a cycle of length 2, and an edge back across a cycle is a chord")
    func directed() {
        // NetworkX 3.7: chordless_cycles(DiGraph([(0,1),(1,0),(1,2),(2,0)])) is [[0, 1]].
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let cycles = Array(graph.chordlessCycles())
        #expect(cycles.map(\.vertices) == [[0, 1]])
        #expect(cycles.map(\.edges) == [[0, 1]])
        // A directed triangle with the chord 0→2: 0→2 and 2→0 make a cycle of length 2.
        let forward = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        #expect(Array(forward.chordlessCycles()).map(\.vertices) == [[0, 2]])
        #expect(Array(forward.chordlessCycles()).map(\.edges) == [[3, 2]])
        // A directed 4-cycle, and the same with one diagonal.
        let square = CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
        #expect(Array(square.chordlessCycles()).map(\.vertices) == [[0, 1, 2, 3]])
        let diagonal = AdjacencyList(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 0, to: 2),
        ])
        #expect(Array(diagonal.chordlessCycles()).map(\.vertices) == [[0, 2, 3]])
    }

    @Test("CY-903 self-loops and parallel edges, as NetworkX 3.7 reads a multigraph")
    func loopsAndParallelEdges() {
        // MultiGraph([(0,1),(0,1),(1,2),(2,0),(2,2)]) → [[2], [1, 0]]: the doubled edge is a
        // cycle, the loop is one, and the triangle has a chord twice over.
        let multi = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 2)])
        let cycles = Array(multi.chordlessCycles())
        #expect(cycles.map(\.vertices) == [[0, 1], [2]])
        #expect(cycles.map(\.edges) == [[0, 1], [4]])
        // Three parallel edges, or two loops at a vertex: no chordless cycle.
        #expect(Array(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)]).chordlessCycles()).isEmpty)
        #expect(Array(ReferencePseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)]).chordlessCycles()).isEmpty)
        // A loop on a triangle's corner leaves the loop alone.
        let looped = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(1, 1)])
        #expect(Array(looped.chordlessCycles()).map(\.vertices) == [[1]])
        // MultiDiGraph([(0,1),(0,1),(1,0)]) → []: the second copy is a chord.
        #expect(Array(ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]).chordlessCycles()).isEmpty)
        let directedLoop = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)])
        #expect(Array(directedLoop.chordlessCycles()).map(\.edges) == [[2]])
    }

    @Test("CY-904 maxLength drops the longer cycles, keeping the order; zero keeps none")
    func lengthBound() {
        let chorded = ReferencePseudograph(edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0), UndirectedEdge(0, 2), UndirectedEdge(3, 3),
            UndirectedEdge(5, 6), UndirectedEdge(5, 6),
        ])
        #expect(Array(chorded.chordlessCycles()).map(\.vertices) == [[0, 1, 2], [3], [5, 6]])
        #expect(Array(chorded.chordlessCycles(maxLength: 2)).map(\.vertices) == [[3], [5, 6]])
        #expect(Array(chorded.chordlessCycles(maxLength: 1)).map(\.vertices) == [[3]])
        #expect(Array(chorded.chordlessCycles(maxLength: 0)).isEmpty)
        let ring = CompressedSparseRow(vertexCount: 5, edges: (0 ..< 5).map { DirectedEdge(from: $0, to: ($0 + 1) % 5) })
        #expect(Array(ring.chordlessCycles(maxLength: 4)).isEmpty)
        #expect(Array(ring.chordlessCycles(maxLength: 5)).count == 1)
        #expect(ring.chordlessCycles(maxLength: 4).maxLength == 4)
    }

    @Test("CY-905 acyclic, empty and String-vertex graphs; vertices without indices; value semantics")
    func edgeCases() {
        #expect(Array(AdjacencyList<Int>().chordlessCycles()).isEmpty)
        #expect(Array(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).chordlessCycles()).isEmpty)
        let named = AdjacencyList(edges: [DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "b")])
        // Least vertex in `vertices` order: "b" was listed first.
        #expect(Array(named.chordlessCycles()).map(\.vertices) == [["b", "c", "a"]])
        let unindexed = UnindexedDigraph(base: ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]))
        #expect(Array(unindexed.chordlessCycles()).map(\.vertices) == [[0, 1]])
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let cycles = graph.chordlessCycles()
        graph.insert(edge: DirectedEdge(from: 0, to: 0))
        #expect(Array(cycles).count == 1)
        #expect(Array(cycles) == Array(cycles))
        #expect(Array(graph.chordlessCycles()).map(\.vertices) == [[0]])
    }

    @Test("CY-906 a negative maxLength traps")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).chordlessCycles(maxLength: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).chordlessCycles(maxLength: -1)
        }
    }

    @Test("CY-907 undirected: simpleCycles() filtered to the induced cycles, in content and order, rows shuffled or not")
    func undirectedAgainstFilter() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 7)) { raw, seed, bound in
            let n = 7
            let maxLength = bound == 7 ? Int.max : bound
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            func isChordless(_ cycle: Cycle<Int, Int>) -> Bool {
                let members = Set(cycle.vertices)
                return raw.filter { members.contains($0.0) && members.contains($0.1) }.count == cycle.length
            }
            let expected = Array(graph.simpleCycles(maxLength: maxLength)).filter(isChordless)
            let cycles = Array(graph.chordlessCycles(maxLength: maxLength))
            #expect(cycles.map(\.vertices) == expected.map(\.vertices))
            #expect(cycles.map(\.edges) == expected.map(\.edges))
            for cycle in cycles { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil) }
        }
    }

    @Test("CY-908 directed: simpleCycles() filtered to the induced cycles, in content and order, on every representation")
    func directedAgainstFilter() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 7)) { raw, seed, bound in
            let n = 7
            let maxLength = bound == 7 ? Int.max : bound
            let arcs = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String) {
                func isChordless(_ cycle: Cycle<Int, G.Edges.Index>) -> Bool {
                    let members = Set(cycle.vertices)
                    return graph.edges.filter { members.contains($0.source) && members.contains($0.target) }.count == cycle.length
                }
                let expected = Array(graph.simpleCycles(maxLength: maxLength)).filter(isChordless)
                let cycles = Array(graph.chordlessCycles(maxLength: maxLength))
                #expect(cycles.map(\.vertices) == expected.map(\.vertices), "\(name)")
                #expect(cycles.map(\.edges) == expected.map(\.edges), "\(name)")
                for cycle in cycles { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil, "\(name)") }
            }
            check(ShuffledDigraph(vertexCount: n, edges: arcs, seed: seed), "shuffled rows")
            check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: arcs), "ReferenceDirectedMultigraph")
            check(UnindexedDigraph(base: ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: arcs)), "without vertex indices")
            check(CompressedSparseRow(vertexCount: n, edges: arcs), "CompressedSparseRow")
            check(AdjacencyList(vertices: 0 ..< n, edges: arcs), "AdjacencyList")
            check(AdjacencyMatrix(vertexCount: n, edges: arcs), "AdjacencyMatrix")
        }
    }
}
