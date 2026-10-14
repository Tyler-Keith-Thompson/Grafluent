// Chordal graphs: isChordal, perfectEliminationOrdering(), findHole(), chordalGraphCliques() and
// chordalGraphTreewidth(), on the simple graph. Hand-computed cases (NetworkX 3.7's chordal
// examples among them) and a property test against brute force over vertex subsets (a hole is a
// subset inducing a cycle of four or more), the definition of a perfect elimination ordering, and
// maximalCliques(), on every undirected representation. Case IDs (CQ-nnn) refer to the catalog;
// see README.md.

import AdjacencyListModule
import Cliques
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import Testing
import Traversal
import Walks

/// An undirected pseudograph without vertex indices.
private struct UnindexedPseudograph: Graph {
    let base: ReferencePseudograph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [UndirectedEdge<Int>] { base.edges }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

@Suite("Chordal graphs")
struct ChordalTests {
    @Test("CQ-900 NetworkX's chordal_graph_cliques example: cliques and treewidth")
    func networkXExample() {
        // nx.chordal_graph_cliques docs: edges below and an isolated 9.
        let graph = UndirectedAdjacencyList(vertices: 1 ... 9, edges: [
            UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(3, 5), UndirectedEdge(3, 6), UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(5, 6), UndirectedEdge(7, 8),
        ])
        #expect(graph.isChordal)
        #expect(graph.findHole() == nil)
        let cliques = graph.chordalGraphCliques()
        #expect(cliques.map { Set($0.map(Set.init)) } == [[1, 2, 3], [2, 3, 4], [3, 4, 5, 6], [7, 8], [9]])
        #expect(cliques?.allSatisfy { $0 == $0.sorted() } == true)
        #expect(graph.chordalGraphTreewidth() == 3)
        // The order: each vertex's later neighbors are a clique.
        let order = graph.perfectEliminationOrdering()!
        #expect(order == graph.maximumCardinalitySearch().reversed())
        #expect(Set(order) == Set(1 ... 9))
    }

    @Test("CQ-901 a square has a hole, itself; with a chord it is chordal; trees and complete graphs are")
    func squares() {
        let square = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(!square.isChordal)
        #expect(square.perfectEliminationOrdering() == nil)
        #expect(square.chordalGraphCliques() == nil)
        #expect(square.chordalGraphTreewidth() == nil)
        let hole = square.findHole()
        #expect(hole?.vertices == [0, 1, 2, 3])
        #expect(hole?.edges == [0, 1, 2, 3])
        let chorded = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(1, 3)])
        #expect(chorded.isChordal)
        #expect(chorded.chordalGraphTreewidth() == 2)
        #expect(chorded.chordalGraphCliques().map { Set($0.map(Set.init)) } == [[0, 1, 3], [1, 2, 3]])
        let tree = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(2, 3), UndirectedEdge(2, 4)])
        #expect(tree.isChordal)
        #expect(tree.chordalGraphTreewidth() == 1)
        #expect(tree.chordalGraphCliques()?.count == 4)
        var complete: [UndirectedEdge<Int>] = []
        for u in 0 ..< 6 { for v in u + 1 ..< 6 { complete.append(UndirectedEdge(u, v)) } }
        let k6 = UndirectedAdjacencyList(edges: complete)
        #expect(k6.chordalGraphCliques() == [[0, 1, 2, 3, 4, 5]])
        #expect(k6.chordalGraphTreewidth() == 5)
    }

    @Test("CQ-902 a long hole in a larger graph; the hole is a chordless cycle of the graph, canonical")
    func longHole() {
        // An 8-cycle with a triangle fan on one side (chordal there) and a pendant.
        var edges = (0 ..< 8).map { UndirectedEdge($0, ($0 + 1) % 8) }
        edges += [UndirectedEdge(0, 9), UndirectedEdge(1, 9), UndirectedEdge(9, 10)]
        let graph = UndirectedAdjacencyList(edges: edges)
        #expect(!graph.isChordal)
        let hole = graph.findHole()!
        #expect(hole.length >= 4)
        #expect(Cycle(vertices: hole.vertices, edges: hole.edges, in: graph) != nil)
        #expect(hole.vertices[0] == hole.vertices.min())
        let members = Set(hole.vertices)
        #expect(graph.edges.filter { members.contains($0.u) && members.contains($0.v) }.count == hole.length)
    }

    @Test("CQ-903 loops and parallel copies are ignored; the hole's edges are the first copies")
    func multigraphs() {
        let graph = Pseudograph(edges: [
            UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(2, 2),
        ])
        #expect(!graph.isChordal)
        #expect(graph.findHole()?.edges == [0, 2, 3, 4])
        let triangle = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 0), UndirectedEdge(1, 2)])
        #expect(triangle.isChordal)
        #expect(triangle.chordalGraphCliques() == [[0, 1, 2]])
    }

    @Test("CQ-904 the empty graph, a vertex, String vertices, a conformer without vertex indices")
    func edgeCases() {
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.isChordal)
        #expect(empty.perfectEliminationOrdering() == [])
        #expect(empty.chordalGraphCliques() == [])
        #expect(empty.chordalGraphTreewidth() == -1)
        let one = UndirectedAdjacencyList(vertices: [7], edges: [])
        #expect(one.chordalGraphCliques() == [[7]])
        #expect(one.chordalGraphTreewidth() == 0)
        let named = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("d", "a")])
        #expect(named.findHole()?.vertices == ["a", "b", "c", "d"])
        let unindexed = UnindexedPseudograph(base: ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]))
        #expect(unindexed.isChordal)
        #expect(unindexed.chordalGraphCliques() == [[0, 1, 2]])
    }

    @Test("CQ-905 every answer against brute force over vertex subsets, on every representation")
    func againstBruteForce() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: pairs) { raw in
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
                // A hole: a subset of four or more inducing a connected 2-regular graph.
                var hasHole = false
                for mask in 0 ..< (1 << n) where mask.nonzeroBitCount >= 4 && !hasHole {
                    let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
                    guard members.allSatisfy({ v in members.filter { adjacent[v][$0] }.count == 2 }) else { continue }
                    var seen: Set = [members[0]], stack = [members[0]]
                    while let v = stack.popLast() {
                        for w in members where adjacent[v][w] && seen.insert(w).inserted { stack.append(w) }
                    }
                    if seen.count == members.count { hasHole = true }
                }
                #expect(g.isChordal == !hasHole, "\(name)")
                if let order = g.perfectEliminationOrdering() {
                    let place = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
                    for v in listed {
                        let later = listed.filter { adjacent[index[v]!][index[$0]!] && place[$0]! > place[v]! }
                        for a in later { for b in later where a != b { #expect(adjacent[index[a]!][index[b]!], "\(name): \(order)") } }
                    }
                    let maximal = Set(g.maximalCliques().map(Set.init))
                    let cliques = g.chordalGraphCliques()!
                    #expect(Set(cliques.map(Set.init)) == maximal && cliques.count == maximal.count, "\(name)")
                    #expect(g.chordalGraphTreewidth() == (maximal.map(\.count).max() ?? 0) - 1, "\(name)")
                } else {
                    #expect(hasHole, "\(name)")
                    let hole = g.findHole()!
                    #expect(Cycle(vertices: hole.vertices, edges: hole.edges, in: g) != nil, "\(name)")
                    let members = hole.vertices.map { index[$0]! }
                    #expect(members.count >= 4, "\(name)")
                    #expect(members.allSatisfy { v in members.filter { adjacent[v][$0] }.count == 2 }, "\(name): \(hole) has a chord")
                    #expect(members[0] == members.min(), "\(name)")
                    #expect(hole.edges[0] < hole.edges[hole.edges.count - 1], "\(name)")
                }
            }
            let reference = ReferencePseudograph(vertices: [3, 0, 7, 1, 6, 2, 5, 4], edges: edges)
            check(reference, "ReferencePseudograph, vertices out of order")
            check(UnindexedPseudograph(base: reference), "without vertex indices")
            check(Pseudograph(vertices: 0 ..< 8, edges: edges), "Pseudograph")
            check(UndirectedAdjacencyList(vertices: 0 ..< 8, edges: edges), "UndirectedAdjacencyList")
        }
    }
}
