// lexicographicBreadthFirstSearch() and maximumCardinalitySearch(): vertex orderings of the simple
// graph, ties unspecified. Forced orders, starts, components, loops and parallel edges, and a
// property test checking every step against the definitions (explicit labels and counts) on every
// undirected representation. Case IDs (TR-nn) refer to the catalog;
// see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import Testing
import Traversal

/// An undirected pseudograph without vertex indices.
private struct UnindexedPseudograph: Graph {
    let base: ReferencePseudograph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [UndirectedEdge<Int>] { base.edges }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

@Suite("Lexicographic breadth-first and maximum cardinality search")
struct ChordalOrderingTests {
    @Test("TR-270 forced orders: a path from an end, a square's far corner last, a star's center second")
    func handComputed() {
        let path = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(path.lexicographicBreadthFirstSearch() == [0, 1, 2, 3])
        #expect(path.maximumCardinalitySearch() == [0, 1, 2, 3])
        #expect(path.lexicographicBreadthFirstSearch(from: 3) == [3, 2, 1, 0])
        #expect(path.maximumCardinalitySearch(from: 3) == [3, 2, 1, 0])
        // From 2, both 1 and 3 have label [0]; after 1, 3 ([0]) beats 0 ([1]) under LexBFS.
        let middle = path.lexicographicBreadthFirstSearch(from: 2)
        #expect(middle[0] == 2 && Set(middle[1 ... 2]) == [1, 3] && (middle[1] == 3 || middle[2] == 3))
        // C4 = 0–1–2–3–0: LexBFS visits the corner opposite 0 last.
        let square = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let lex = square.lexicographicBreadthFirstSearch()
        #expect(lex[0] == 0 && lex[3] == 2 && Set(lex) == [0, 1, 2, 3])
        // Vertices in first-appearance order: 3, 0, 1, 2; the center has the most visited neighbors.
        let star = UndirectedAdjacencyList(edges: [UndirectedEdge(3, 0), UndirectedEdge(3, 1), UndirectedEdge(3, 2)])
        #expect(star.lexicographicBreadthFirstSearch()[0] == 3)
        #expect(star.lexicographicBreadthFirstSearch(from: 1)[0 ... 1] == [1, 3])
        #expect(star.maximumCardinalitySearch(from: 1)[0 ... 1] == [1, 3])
    }

    @Test("TR-271 LexBFS against MCS: a vertex adjacent to the earliest visited wins only under LexBFS")
    func labelsAgainstCounts() {
        // From 0 with the chain 0–1–2 forced first: 0–1, 1–2, then 3 is joined to 0 and 4 to 2.
        // After 0, 1, 2 both have one visited neighbor (MCS may take either), but 3's label [0]
        // beats 4's [2] under LexBFS.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 3), UndirectedEdge(2, 4), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
        ])
        // After 0: 1 [0] and 3 [0]; LexBFS takes 1 or 3. Every LexBFS from 0 visits 4 last: its
        // label never gets the 0.
        let lex = graph.lexicographicBreadthFirstSearch()
        #expect(lex[0] == 0 && lex[4] == 4)
        let mcs = graph.maximumCardinalitySearch()
        #expect(mcs[0] == 0 && Set(mcs) == Set(0 ..< 5))
    }

    @Test("TR-272 components, isolated vertices, the empty graph; loops and parallel copies change nothing; the same graph gives the same order")
    func edgeCases() {
        #expect(UndirectedAdjacencyList<Int>().lexicographicBreadthFirstSearch().isEmpty)
        #expect(UndirectedAdjacencyList<Int>().maximumCardinalitySearch().isEmpty)
        let split = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(4, 5), UndirectedEdge(1, 2)])
        let order = split.lexicographicBreadthFirstSearch(from: 4)
        #expect(order[0 ... 1] == [4, 5] && Set(order) == Set(0 ..< 6))
        #expect(split.maximumCardinalitySearch(from: 5)[0 ... 1] == [5, 4])
        #expect(split.lexicographicBreadthFirstSearch() == split.lexicographicBreadthFirstSearch())
        #expect(split.maximumCardinalitySearch() == split.maximumCardinalitySearch())
        let plain = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let messy = Pseudograph(vertices: 0 ..< 4, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(2, 2), UndirectedEdge(0, 0),
        ])
        #expect(messy.lexicographicBreadthFirstSearch()[3] == 2)
        #expect(plain.lexicographicBreadthFirstSearch()[3] == 2)
        // A graph whose refinement splits more classes than it has vertices, so emptied class
        // numbers must be reused.
        let busy = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [
            (0, 6), (1, 3), (1, 4), (1, 6), (2, 0), (2, 1), (2, 3), (2, 4), (3, 0), (4, 0), (4, 3), (4, 6), (5, 0), (5, 2), (5, 3), (5, 4), (6, 2), (6, 3), (6, 5),
        ].map { UndirectedEdge($0.0, $0.1) })
        #expect(Set(busy.lexicographicBreadthFirstSearch()) == Set(0 ..< 7))
        let named = UndirectedAdjacencyList(edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "c")])
        #expect(named.lexicographicBreadthFirstSearch() == ["b", "a", "c"])
        #expect(named.maximumCardinalitySearch() == ["b", "a", "c"])
    }

    @Test("TR-273 a source that is not a vertex traps")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).lexicographicBreadthFirstSearch(from: 5)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).maximumCardinalitySearch(from: 5)
        }
        await #expect(processExitsWith: .failure) {
            _ = UnindexedPseudograph(base: ReferencePseudograph(edges: [UndirectedEdge(0, 1)])).lexicographicBreadthFirstSearch(from: 5)
        }
    }

    @Test("TR-274 both orders are valid by their definitions, step by step, start where asked and repeat, on every representation")
    func againstDefinitions() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 22)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 9)) { raw, start in
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            func check<G: Graph<Int>>(_ g: G, _ name: String) {
                let listed = Array(g.vertices)
                let n = listed.count
                var index: [Int: Int] = [:]
                for (i, v) in listed.enumerated() { index[v] = i }
                var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
                for e in g.edges where e.u != e.v {
                    adjacent[index[e.u]!][index[e.v]!] = true
                    adjacent[index[e.v]!][index[e.u]!] = true
                }
                let first = start < n ? start : nil
                let lex = (first.map { g.lexicographicBreadthFirstSearch(from: listed[$0]) } ?? g.lexicographicBreadthFirstSearch()).map { index[$0]! }
                let mcs = (first.map { g.maximumCardinalitySearch(from: listed[$0]) } ?? g.maximumCardinalitySearch()).map { index[$0]! }
                #expect(lex.sorted() == Array(0 ..< n) && mcs.sorted() == Array(0 ..< n), "\(name)")
                #expect(lex.first == (first ?? 0) && mcs.first == (first ?? 0), "\(name)")
                // Each step takes a greatest label (LexBFS) or a greatest count (MCS) among the
                // unvisited vertices.
                func greater(_ a: [Int], _ b: [Int]) -> Bool {
                    for (x, y) in zip(a, b) where x != y { return x < y }
                    return a.count > b.count
                }
                var labels = [[Int]](repeating: [], count: n), counts = [Int](repeating: 0, count: n)
                var lexVisited = [Bool](repeating: false, count: n), mcsVisited = lexVisited
                for step in 0 ..< n {
                    let a = lex[step], b = mcs[step]
                    if step > 0 {
                        #expect(!(0 ..< n).contains { !lexVisited[$0] && greater(labels[$0], labels[a]) }, "\(name): LexBFS step \(step) of \(lex)")
                        #expect(!(0 ..< n).contains { !mcsVisited[$0] && counts[$0] > counts[b] }, "\(name): MCS step \(step) of \(mcs)")
                    }
                    lexVisited[a] = true
                    mcsVisited[b] = true
                    for w in 0 ..< n where adjacent[a][w] && !lexVisited[w] { labels[w].append(step) }
                    for w in 0 ..< n where adjacent[b][w] && !mcsVisited[w] { counts[w] += 1 }
                }
                // The same graph gives the same order.
                #expect((first.map { g.lexicographicBreadthFirstSearch(from: listed[$0]) } ?? g.lexicographicBreadthFirstSearch()).map { index[$0]! } == lex, "\(name)")
            }
            let reference = ReferencePseudograph(vertices: [4, 0, 8, 1, 7, 2, 6, 3, 5], edges: edges)
            check(reference, "ReferencePseudograph, vertices out of order")
            check(UnindexedPseudograph(base: reference), "without vertex indices")
            check(Pseudograph(vertices: 0 ..< 9, edges: edges), "Pseudograph")
            check(UndirectedAdjacencyList(vertices: 0 ..< 9, edges: edges), "UndirectedAdjacencyList")
        }
    }
}
