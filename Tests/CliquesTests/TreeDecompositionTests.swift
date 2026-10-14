// treewidthMinDegree(), treewidthMinFillIn() and isTreeDecomposition(_:). Hand-computed bags and
// trees on small graphs; the empty graph, one vertex, a disconnected graph, self-loops and
// parallel edges; known treewidths (paths and trees 1, cycles 2, K_n n − 1, the 3 × 3 grid 3,
// the Petersen graph 4), never undercut; chordal graphs exact under minimum fill-in; invalid
// decompositions of each kind rejected; and random graphs against a naive port of both
// heuristics and the exact treewidth over every elimination order.

import AdjacencyListModule
import Cliques
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("Tree decompositions")
struct TreeDecompositionTests {
    @Test("The empty graph: one empty bag, width −1, valid")
    func empty() {
        let graph = UndirectedAdjacencyList<Int>()
        for decomposition in [graph.treewidthMinDegree(), graph.treewidthMinFillIn()] {
            #expect(decomposition.bags == [[]])
            #expect(decomposition.edges.isEmpty)
            #expect(decomposition.width == -1)
            #expect(graph.isTreeDecomposition(decomposition))
        }
    }

    @Test("One vertex, with a self-loop: one bag, width 0")
    func oneVertex() {
        let graph = Pseudograph(vertices: [7], edges: [UndirectedEdge(7, 7)])
        for decomposition in [graph.treewidthMinDegree(), graph.treewidthMinFillIn()] {
            #expect(decomposition.bags == [[7]])
            #expect(decomposition.width == 0)
            #expect(graph.isTreeDecomposition(decomposition))
        }
    }

    @Test("A path of five: the ends eliminated in turn, the last edge the root")
    func path() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let decomposition = graph.treewidthMinDegree()
        #expect(decomposition.bags == [[3, 4], [0, 1], [1, 2], [2, 3]])
        #expect(decomposition.edges == [UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(decomposition.width == 1)
        #expect(graph.isTreeDecomposition(decomposition))
        #expect(graph.treewidthMinFillIn() == decomposition)
    }

    @Test("A 5-cycle: width 2; min fill-in eliminates 0, then 1, leaving the triangle 2, 3, 4")
    func cycle() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        let fill = graph.treewidthMinFillIn()
        // Every vertex has fill-in 1 at first, so 0 goes (adding 1–4); every one of the four
        // left still has fill-in 1, so 1 goes (adding 2–4), leaving a triangle.
        #expect(fill.bags == [[2, 3, 4], [0, 1, 4], [1, 2, 4]])
        #expect(fill.edges == [UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(fill.width == 2)
        #expect(graph.isTreeDecomposition(fill))
        let degree = graph.treewidthMinDegree()
        #expect(degree.width == 2)
        #expect(graph.isTreeDecomposition(degree))
    }

    @Test("A complete graph is one bag; parallel edges change nothing")
    func complete() {
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { edges += [UndirectedEdge(u, v), UndirectedEdge(v, u)] } }
        let graph = Pseudograph(vertices: 0 ..< 5, edges: edges)
        for decomposition in [graph.treewidthMinDegree(), graph.treewidthMinFillIn()] {
            #expect(decomposition.bags == [[0, 1, 2, 3, 4]])
            #expect(decomposition.width == 4)
            #expect(graph.isTreeDecomposition(decomposition))
        }
    }

    @Test("A disconnected graph: isolated vertices and two edges, width 1, one tree of bags")
    func disconnected() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(3, 4)])
        let decomposition = graph.treewidthMinDegree()
        // Least degree, least vertex: 2 (degree 0), then 5, then 0 (degree 1), leaving 1, 3, 4,
        // then 1 (degree 0), leaving the edge 3–4.
        #expect(decomposition.bags == [[3, 4], [2], [5], [0, 1], [1]])
        #expect(decomposition.edges == [UndirectedEdge(1, 0), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        #expect(decomposition.width == 1)
        #expect(graph.isTreeDecomposition(decomposition))
        #expect(graph.isTreeDecomposition(graph.treewidthMinFillIn()))
    }

    @Test("Known treewidths are never undercut: a tree 1, the 3 × 3 grid 3, the Petersen graph 4")
    func knownTreewidths() {
        let tree = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 5), UndirectedEdge(2, 6)])
        #expect(tree.treewidthMinDegree().width == 1)
        #expect(tree.treewidthMinFillIn().width == 1)
        var gridEdges: [UndirectedEdge<Int>] = []
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                if c < 2 { gridEdges.append(UndirectedEdge(3 * r + c, 3 * r + c + 1)) }
                if r < 2 { gridEdges.append(UndirectedEdge(3 * r + c, 3 * r + c + 3)) }
            }
        }
        let grid = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: gridEdges)
        for decomposition in [grid.treewidthMinDegree(), grid.treewidthMinFillIn()] {
            #expect(decomposition.width >= 3)
            #expect(grid.isTreeDecomposition(decomposition))
        }
        var petersenEdges: [UndirectedEdge<Int>] = []
        for i in 0 ..< 5 {
            petersenEdges.append(UndirectedEdge(i, (i + 1) % 5))
            petersenEdges.append(UndirectedEdge(i, i + 5))
            petersenEdges.append(UndirectedEdge(i + 5, (i + 2) % 5 + 5))
        }
        let petersen = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersenEdges)
        for decomposition in [petersen.treewidthMinDegree(), petersen.treewidthMinFillIn()] {
            #expect(decomposition.width >= 4)
            #expect(petersen.isTreeDecomposition(decomposition))
        }
    }

    @Test("A chordal graph: minimum fill-in finds its treewidth")
    func chordal() {
        // Two triangles and a K4 glued along edges and vertices.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 3), UndirectedEdge(1, 3),
            UndirectedEdge(3, 4), UndirectedEdge(3, 5), UndirectedEdge(3, 6), UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(5, 6),
        ])
        #expect(graph.chordalGraphTreewidth() == 3)
        let decomposition = graph.treewidthMinFillIn()
        #expect(decomposition.width == 3)
        #expect(graph.isTreeDecomposition(decomposition))
    }

    @Test("Min fill-in takes fill-in 0 at a higher degree over fill-in 1 at a lower one")
    func fillBeatsDegree() {
        // A 4-cycle 0–1–2–3 (degree 2, fill-in 1 each) and K5 on 4…8 (degree 4, fill-in 0).
        var edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)]
        for u in 4 ..< 9 { for v in u + 1 ..< 9 { edges.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: edges)
        let decomposition = graph.treewidthMinFillIn()
        #expect(decomposition.bags[1] == [4, 5, 6, 7, 8])
        #expect(decomposition.width == 4)
        #expect(graph.treewidthMinDegree().bags[1] == [0, 1, 3])
    }

    @Test("String vertices: bags in vertices order")
    func labels() {
        let graph = UndirectedAdjacencyList(vertices: ["d", "c", "b", "a"], edges: [UndirectedEdge("d", "c"), UndirectedEdge("c", "b"), UndirectedEdge("b", "a")])
        let decomposition = graph.treewidthMinDegree()
        #expect(decomposition.bags == [["b", "a"], ["d", "c"], ["c", "b"]])
        #expect(graph.isTreeDecomposition(decomposition))
    }

    @Test("Invalid decompositions are rejected, one fault at a time")
    func invalid() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let valid = graph.treewidthMinDegree()
        #expect(graph.isTreeDecomposition(valid))
        let bags = valid.bags, edges = valid.edges
        // No bags; a vertex missing; a foreign vertex; an edge uncovered; a bag edge to itself;
        // an edge to a bag that does not exist; too few or too many edges; disconnected bags;
        // a vertex whose bags are not connected; a cycle of bags; an empty bag cut off.
        let faults: [TreeDecomposition<Int>] = [
            TreeDecomposition(bags: [], edges: []),
            TreeDecomposition(bags: [[0, 1], [1, 2]], edges: [UndirectedEdge(0, 1)]),
            TreeDecomposition(bags: bags + [[9]], edges: edges + [UndirectedEdge(bags.count, 0)]),
            TreeDecomposition(bags: [[0, 1], [1, 2], [3]], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]),
            TreeDecomposition(bags: [[0, 1, 2, 3], [0]], edges: [UndirectedEdge(0, 0)]),
            TreeDecomposition(bags: [[0, 1, 2, 3], [0]], edges: [UndirectedEdge(1, 2)]),
            TreeDecomposition(bags: [[0, 1, 2, 3], [0]], edges: []),
            TreeDecomposition(bags: [[0, 1, 2, 3], [0], [1]], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]),
            TreeDecomposition(bags: [[0, 1], [1, 2], [2, 3], [0]], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]),
            TreeDecomposition(bags: [[0, 1, 2, 3], [0], [1]], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]),
            TreeDecomposition(bags: [[0, 1, 2, 3], [0], []], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]),
        ]
        for (k, fault) in faults.enumerated() {
            #expect(!graph.isTreeDecomposition(fault), "fault \(k)")
        }
        // A vertex listed twice in a bag is still one vertex.
        #expect(graph.isTreeDecomposition(TreeDecomposition(bags: [[0, 1, 1], [1, 2, 3, 2]], edges: [UndirectedEdge(0, 1)])))
    }

    @Test("Random graphs: both heuristics match a naive port, are valid, and never undercut the exact treewidth", .tags(.randomized))
    func againstNaive() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 18)
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 7), edges) { n, raw in
            let pairs = raw.filter { $0.0 < n && $0.1 < n }
            let graph = Pseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var adjacency = [Set<Int>](repeating: [], count: n)
            for (u, v) in pairs where u != v {
                adjacency[u].insert(v)
                adjacency[v].insert(u)
            }
            // The naive heuristics: eliminate until the rest is a clique; bags and parents as
            // documented.
            func naive(_ fillIn: Bool) -> (bags: [[Int]], edges: [UndirectedEdge<Int>]) {
                var adj = adjacency
                var alive = Array(0 ..< n)
                var order: [Int] = [], around: [[Int]] = []
                while !alive.isEmpty {
                    let byDegree = alive.sorted { (adj[$0].count, $0) < (adj[$1].count, $1) }
                    if adj[byDegree[0]].count == alive.count - 1 { break }
                    var v = byDegree[0]
                    if fillIn {
                        var best = Int.max
                        for u in byDegree {
                            let nbrs = Array(adj[u])
                            var missing = 0
                            for i in nbrs.indices { for j in nbrs.indices where i < j && !adj[nbrs[i]].contains(nbrs[j]) { missing += 1 } }
                            if missing < best {
                                best = missing
                                v = u
                            }
                        }
                    }
                    let nbrs = adj[v]
                    for a in nbrs {
                        adj[a].formUnion(nbrs.subtracting([a]))
                        adj[a].remove(v)
                    }
                    adj[v] = []
                    alive.removeAll { $0 == v }
                    order.append(v)
                    around.append(nbrs.sorted())
                }
                var bags = [alive.sorted()]
                var edges: [UndirectedEdge<Int>] = []
                for (i, v) in order.enumerated() {
                    bags.append(([v] + around[i]).sorted())
                    let later = around[i].compactMap { order.firstIndex(of: $0) }.min()
                    edges.append(UndirectedEdge(i + 1, later.map { $0 + 1 } ?? 0))
                }
                return (bags, edges)
            }
            // The exact treewidth: the least, over every elimination order, of the largest
            // neighborhood met.
            var exact = n == 0 ? -1 : n - 1
            func search(_ adj: [Set<Int>], _ left: [Int], _ worst: Int) {
                if worst >= exact { return }
                if left.isEmpty {
                    exact = worst
                    return
                }
                for v in left {
                    var next = adj
                    let nbrs = adj[v]
                    for a in nbrs {
                        next[a].formUnion(nbrs.subtracting([a]))
                        next[a].remove(v)
                    }
                    next[v] = []
                    search(next, left.filter { $0 != v }, max(worst, nbrs.count))
                }
            }
            search(adjacency, Array(0 ..< n), n == 0 ? -1 : 0)
            for (fillIn, decomposition) in [(false, graph.treewidthMinDegree()), (true, graph.treewidthMinFillIn())] {
                let expected = naive(fillIn)
                #expect(decomposition.bags == expected.bags, "\(n) \(pairs) fill-in \(fillIn)")
                #expect(decomposition.edges == expected.edges, "\(n) \(pairs) fill-in \(fillIn)")
                #expect(graph.isTreeDecomposition(decomposition), "\(n) \(pairs)")
                #expect(decomposition.width >= exact, "\(n) \(pairs)")
            }
        }
    }
}
