// k-components (Moody and White): for each k, the maximal vertex sets whose induced subgraph has
// more than k vertices and no vertex cut of fewer than k vertices. Parallel edges count once,
// self-loops not at all. Hand-computed graphs, the representations, exits, and a property test
// against every vertex subset and every small cut.

import AdjacencyListModule
import AdjacencyMatrixModule
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("k-components")
struct KComponentTests {
    @Test("No edge between distinct vertices: no level at all")
    func empty() {
        let none = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(none.kComponents().maximumK == 0)
        #expect(none.kComponents()[1].isEmpty)
        let loops = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 0), UndirectedEdge(2, 2)])
        #expect(loops.kComponents().maximumK == 0)
        #expect(loops.kComponents()[1].isEmpty)
        #expect(loops.kComponents().description == "[]")
    }

    @Test("A path, a doubled edge and an isolated vertex: level 1 only, the isolated vertex in none")
    func treeLike() {
        let edges = [(0, 1), (1, 2), (3, 4), (3, 4), (4, 4)].map { UndirectedEdge($0.0, $0.1) }
        let result = ReferencePseudograph(vertices: 0 ..< 6, edges: edges).kComponents()
        #expect(result.maximumK == 1)
        #expect(result[1].map(Array.init) == [[0, 1, 2], [3, 4]])
        #expect(result[2].isEmpty)
        #expect(result.description == "[1: [[0, 1, 2], [3, 4]]]")
    }

    @Test("K₅: one component at every level up to 4")
    func complete() {
        var pairs: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append(UndirectedEdge(u, v)) } }
        let result = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs).kComponents()
        #expect(result.maximumK == 4)
        for k in 1 ... 4 { #expect(result[k].map(Array.init) == [Array(0 ..< 5)]) }
        #expect(result[5].isEmpty)
    }

    @Test("Two K₄s sharing a vertex: one 1-component, the two K₄s at levels 2 and 3")
    func sharedVertex() {
        var pairs: [UndirectedEdge<Int>] = []
        for base in [0, 3] { for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append(UndirectedEdge(base + u, base + v)) } } }
        let result = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: pairs).kComponents()
        #expect(result.maximumK == 3)
        #expect(result[1].map(Array.init) == [Array(0 ..< 7)])
        #expect(result[2].map(Array.init) == [[0, 1, 2, 3], [3, 4, 5, 6]])
        #expect(result[3].map(Array.init) == [[0, 1, 2, 3], [3, 4, 5, 6]])
    }

    @Test("Two K₄s sharing an edge: biconnected as a whole, the K₄s overlap in two vertices at level 3")
    func sharedEdge() {
        var pairs: [UndirectedEdge<Int>] = []
        for base in [0, 2] { for u in 0 ..< 4 { for v in u + 1 ..< 4 where !(base == 2 && u == 0 && v == 1) { pairs.append(UndirectedEdge(base + u, base + v)) } } }
        let result = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs).kComponents()
        #expect(result.maximumK == 3)
        #expect(result[2].map(Array.init) == [Array(0 ..< 6)])
        #expect(result[3].map(Array.init) == [[0, 1, 2, 3], [2, 3, 4, 5]])
    }

    @Test("Two K₅s joined by two disjoint edges: one 2-component, split by a two-vertex cut at level 3")
    func splitByCut() {
        var pairs: [UndirectedEdge<Int>] = []
        for base in [0, 5] { for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append(UndirectedEdge(base + u, base + v)) } } }
        pairs += [UndirectedEdge(0, 5), UndirectedEdge(1, 6)]
        let result = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs).kComponents()
        #expect(result.maximumK == 4)
        #expect(result[2].map(Array.init) == [Array(0 ..< 10)])
        #expect(result[3].map(Array.init) == [Array(0 ..< 5), Array(5 ..< 10)])
        #expect(result[4].map(Array.init) == [Array(0 ..< 5), Array(5 ..< 10)])
    }

    @Test("The wheel on five rim vertices and K₃,₃ are 3-connected; a cycle is only 2-connected")
    func families() {
        var wheel = (1 ... 5).map { UndirectedEdge(0, $0) }
        wheel += (1 ... 5).map { UndirectedEdge($0, $0 % 5 + 1) }
        let w = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: wheel).kComponents()
        #expect(w.maximumK == 3)
        #expect(w[3].map(Array.init) == [Array(0 ..< 6)])
        var bipartite: [UndirectedEdge<Int>] = []
        for u in 0 ..< 3 { for v in 3 ..< 6 { bipartite.append(UndirectedEdge(u, v)) } }
        let b = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: bipartite).kComponents()
        #expect(b.maximumK == 3)
        #expect(b[3].map(Array.init) == [Array(0 ..< 6)])
        let cycle = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: (0 ..< 6).map { UndirectedEdge($0, ($0 + 1) % 6) }).kComponents()
        #expect(cycle.maximumK == 2)
        #expect(cycle[2].map(Array.init) == [Array(0 ..< 6)])
    }

    @Test("A triangle with a pendant vertex and a separate K₄: components ordered by their vertex lists")
    func ordering() {
        var pairs = [(5, 6), (6, 7), (7, 5), (7, 8)].map { UndirectedEdge($0.0, $0.1) }
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append(UndirectedEdge(u, v)) } }
        let result = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs).kComponents()
        #expect(result[1].map(Array.init) == [[0, 1, 2, 3], [5, 6, 7, 8]])
        #expect(result[2].map(Array.init) == [[0, 1, 2, 3], [5, 6, 7]])
        #expect(result[3].map(Array.init) == [[0, 1, 2, 3]])
        #expect(result == UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.reversed()).kComponents())
    }

    @Test("Representations: AdjacencyList and AdjacencyMatrix through undirectedView, whose opposite arcs are parallel edges, and string vertices")
    func representations() {
        let arcs = [(0, 1), (1, 2), (2, 0), (1, 0), (2, 3), (3, 0), (0, 2), (3, 1)]
        let list = AdjacencyList(vertices: 0 ..< 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView.kComponents()
        #expect(list.maximumK == 3)
        #expect(list[3].map(Array.init) == [[0, 1, 2, 3]])
        let rows = AdjacencyMatrix(vertexCount: 5, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView.kComponents()
        #expect(rows[1].map(Array.init) == [[0, 1, 2, 3]])
        #expect(rows[3].map(Array.init) == [[0, 1, 2, 3]])
        let names = ["a", "b", "c", "d"]
        let labeled = UndirectedAdjacencyList(vertices: names, edges: [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d")].map { UndirectedEdge($0.0, $0.1) }).kComponents()
        #expect(labeled[1].map(Array.init) == [["a", "b", "c", "d"]])
        #expect(labeled[2].map(Array.init) == [["a", "b", "c"]])
    }

    @Test("A two-vertex cut met first: 0 and 1, adjacent to every vertex, part two K₄s, so level 3 holds each K₄ with them")
    func cutAmongFirstVertices() {
        var pairs = [UndirectedEdge(0, 1)]
        for v in 2 ..< 10 { pairs += [UndirectedEdge(0, v), UndirectedEdge(1, v)] }
        for base in [2, 6] { for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append(UndirectedEdge(base + u, base + v)) } } }
        let result = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs).kComponents()
        #expect(result.maximumK == 5)
        #expect(result[2].map(Array.init) == [Array(0 ..< 10)])
        for k in 3 ... 5 { #expect(result[k].map(Array.init) == [[0, 1, 2, 3, 4, 5], [0, 1, 6, 7, 8, 9]]) }
    }

    @Test("A 3-component whose vertex-disjoint paths need a path undone: the flows cancel along a used edge")
    func cancelledPath() {
        let pairs = [(10, 4), (5, 8), (9, 7), (1, 11), (4, 1), (1, 9), (4, 9), (3, 4), (0, 10), (6, 11), (2, 10), (6, 9), (4, 5), (7, 3), (4, 0), (4, 8), (6, 0), (11, 9), (8, 6), (5, 1)]
        let result = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) }).kComponents()
        #expect(result.maximumK == 3)
        #expect(result[2].map(Array.init) == [[0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11]])
        #expect(result[3].map(Array.init) == [[1, 4, 5, 6, 8, 9, 11]])
    }

    @Test("The subscript traps on k < 1")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).kComponents()[0]
        }
    }

    @Test("Each level is the maximal sets of more than k vertices that no fewer than k removed vertices disconnect", .tags(.randomized))
    func againstSubsets() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 22)
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 7), edges) { n, raw in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // Whether the vertices of the bit set `set` induce a connected subgraph.
            func connected(_ set: Int) -> Bool {
                guard set != 0 else { return false }
                var reached = set & -set
                while true {
                    var grown = reached
                    for (a, b) in pairs where set & (1 << a) != 0 && set & (1 << b) != 0 {
                        if reached & (1 << a) != 0 { grown |= 1 << b }
                        if reached & (1 << b) != 0 { grown |= 1 << a }
                    }
                    if grown == reached { return reached == set }
                    reached = grown
                }
            }
            let all = (1 << n) - 1
            let result = graph.kComponents()
            var top = 0
            for k in 1 ... n {
                var cohesive: [Int] = []
                for set in 1 ... all where set.nonzeroBitCount > k {
                    var ok = true
                    for removed in 0 ... set where removed & ~set == 0 && removed.nonzeroBitCount < k {
                        if !connected(set & ~removed) {
                            ok = false
                            break
                        }
                    }
                    if ok { cohesive.append(set) }
                }
                let maximal = cohesive.filter { set in !cohesive.contains { $0 != set && $0 & set == set } }
                let expected = maximal.map { set in (0 ..< n).filter { set & (1 << $0) != 0 } }.sorted { $0.lexicographicallyPrecedes($1) }
                if !expected.isEmpty { top = k }
                #expect(result[k].map(Array.init) == expected, "\(pairs) k = \(k)")
            }
            #expect(result.maximumK == top, "\(pairs)")
        }
    }
}
