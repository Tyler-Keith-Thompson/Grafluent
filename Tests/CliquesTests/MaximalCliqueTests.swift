// §B: maximal cliques (CQ-101 – CQ-124). Each test compares the sequence with the catalog as a set
// of arrays, so every clique's members must be in `vertices` order exactly while the sequence order
// is free; no clique may repeat. CQ-101 and CQ-102 also pin the sequence order, as api.md does
// ("Order of maximal cliques": the degeneracy ordering decides it, so the pendant vertex's clique
// comes first). Every listed clique is checked to be a clique (`contains(edge:)` for each pair) and
// maximal (no outside vertex adjacent to all of it), and `graph.directed.undirected` must give the
// same set. Graphs: a triangle with a pendant, K₄, K₅, C₄, C₅, P₅, stars with the centre first and
// last, the bowtie, the diamond, the wheel W₆, K₃,₃ in two numberings, isolated vertices, loops and
// parallel edges, String labels with `vertices` reversed, Petersen, the karate club (36 cliques)
// and moon(4) (81). Every literal is a catalog cell (`ref.py`: api.md's model, brute force over
// vertex subsets, NetworkX 3.7 `find_cliques`). Case IDs (CQ-nnn) refer to the catalog; see
// README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

/// An undirected pseudograph whose incidence rows are reversed (the catalog's `~rev`): each row
/// is built in position order (a self-loop twice), then reversed. Vertex and edge indices are
/// positions.
private struct ReversedRowsPseudograph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>]) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { Array(inOrder.incidentEdges(of: $0).reversed()) }
    }

    init(edges: [UndirectedEdge<Vertex>]) {
        self.init(vertices: [], edges: edges)
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Maximal cliques")
struct MaximalCliqueTests {
    @Test("CQ-101 U(K(0..2), 2-3).maximalCliques is [[2, 3], [0, 1, 2]]: Vertex 3 is first in the degeneracy ordering, so its clique comes first. NetworkX's `find_cliques` gives `[[2, 0, 1], [2, 3]]` (set order)")
    func maximalCliques101() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        #expect(cliques == expected)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-102 U(K(0..2), 2-3 ~rev).maximalCliques is [[2, 3], [0, 1, 2]]: Rows reversed: same cliques, same order here")
    func maximalCliques102() {
        // U: K(0..2), 2-3 ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReversedRowsPseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[2, 3], [0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        #expect(cliques == expected)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-103 U(K(4)).maximalCliques is [[0, 1, 2, 3]]")
    func maximalCliques103() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-104 U(K(5)).maximalCliques is [[0, 1, 2, 3, 4]]")
    func maximalCliques104() {
        // U: K(5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-105 U(C(0..3)).maximalCliques is [[0, 1], [0, 3], [1, 2], [2, 3]]: C₄: four edges")
    func maximalCliques105() {
        // U: C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1], [0, 3], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-106 U(C(0..4)).maximalCliques is [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]")
    func maximalCliques106() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-107 U(P(0..4)).maximalCliques is [[0, 1], [3, 4], [1, 2], [2, 3]]")
    func maximalCliques107() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1], [3, 4], [1, 2], [2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-108 U(S(0;1..4)).maximalCliques is [[0, 1], [0, 2], [0, 3], [0, 4]]: Star: the centre first in no clique; each edge a clique")
    func maximalCliques108() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1], [0, 2], [0, 3], [0, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-109 U(S(4;0..3)).maximalCliques is [[4, 0], [4, 1], [4, 2], [4, 3]]: Centre last in `vertices`")
    func maximalCliques109() {
        // U: S(4;0..3)
        let pairs: [(Int, Int)] = [(4, 0), (4, 1), (4, 2), (4, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[4, 0], [4, 1], [4, 2], [4, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-110 U(K(0..2), K(2..4)).maximalCliques is [[0, 1, 2], [2, 3, 4]]: Bowtie: two triangles sharing vertex 2")
    func maximalCliques110() {
        // U: K(0..2), K(2..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2], [2, 3, 4]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-111 U(K(0..2), 1-3, 2-3).maximalCliques is [[0, 1, 2], [1, 2, 3]]: Diamond: K₄ less an edge")
    func maximalCliques111() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2], [1, 2, 3]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-112 U(S(0;1..5), C(1..5)).maximalCliques is [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]: Wheel W₆")
    func maximalCliques112() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-113 U(KB(0..2;3..5)).maximalCliques is [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]: K₃,₃: nine edges. `vertices` is 0, 3, 4, 5, 1, 2 (first appearance), so `[3, 1]` is in index order")
    func maximalCliques113() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-114 U(moon(2)).maximalCliques is [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]: Moon–Moser with 2 parts is K₃,₃ again, but numbered by part: 3² = 9 cliques")
    func maximalCliques114() {
        // U: moon(2)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-115 U([0, 1, 2] K(3..5)).maximalCliques is [[0], [1], [2], [3, 4, 5]]: Isolated vertices are maximal cliques of one (NetworkX, igraph)")
    func maximalCliques115() {
        // U: [0, 1, 2] K(3..5)
        let pairs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0], [1], [2], [3, 4, 5]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-116 U([0] 0-0, 1-1, 1-2).maximalCliques is [[0], [1, 2]]: Self-loops ignored: [0] alone, [1, 2]")
    func maximalCliques116() {
        // U: [0] 0-0, 1-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0], [1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-117 U(0-1, 1-2, 2-0, 0-1, 2-2).maximalCliques is [[0, 1, 2]]: Parallel and loop: one triangle")
    func maximalCliques117() {
        // U: 0-1, 1-2, 2-0, 0-1, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-118 U(a-b, b-c, c-a, c-d, d-e, e-c).maximalCliques is [[a, b, c], [c, d, e]]: Labels")
    func maximalCliques118() {
        // U: a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[String]] = [["a", "b", "c"], ["c", "d", "e"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-119 U([e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c).maximalCliques is [[e, d, c], [c, b, a]]: Labels, `vertices` reversed: each clique in `vertices` order")
    func maximalCliques119() {
        // U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e"), ("e", "c")]
        let graph = ReferencePseudograph(vertices: ["e", "d", "c", "b", "a"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[String]] = [["e", "d", "c"], ["c", "b", "a"]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-120 U(nx(petersen)).maximalCliques is listed below: Triangle-free: the 15 edges")
    func maximalCliques120() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7],
            [5, 8], [6, 8], [6, 9], [7, 9]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-121 U(nx(karate_club)).maximalCliques is listed below: 36 maximal cliques")
    func maximalCliques121() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [
            [0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17],
            [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10],
            [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33],
            [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30],
            [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]
        ]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-122 U(K(0..3), K(3..6), 0-6).maximalCliques is [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]")
    func maximalCliques122() {
        // U: K(0..3), K(3..6), 0-6
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6),
            (5, 6), (0, 6)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]
        let cliques = Array(graph.maximalCliques())
        #expect(Set(cliques) == Set(expected))
        #expect(cliques.count == expected.count)
        for clique in cliques {
            let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }
            #expect(unjoined.isEmpty, "\(clique) is not a clique")
            let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }
            #expect(extenders.isEmpty, "\(clique) is not maximal")
        }
        let viaArcs = Array(graph.directed.undirected.maximalCliques())
        #expect(Set(viaArcs) == Set(expected))
        #expect(viaArcs.count == expected.count)
    }

    @Test("CQ-123 U(nx(karate_club)).maximalCliques.count is #36: igraph `maximal_cliques`: 36")
    func maximalCliqueCount123() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cliques = Array(graph.maximalCliques())
        #expect(cliques.count == 36)
        #expect(Set(cliques).count == 36)
        #expect(cliques.allSatisfy { $0 == $0.sorted() })
    }

    @Test("CQ-124 U(moon(4)).maximalCliques.count is #81: 3⁴")
    func maximalCliqueCount124() {
        // U: moon(4)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 3), (1, 4),
            (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6),
            (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11),
            (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10),
            (5, 11), (6, 9), (6, 10), (6, 11), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cliques = Array(graph.maximalCliques())
        #expect(cliques.count == 81)
        #expect(Set(cliques).count == 81)
        #expect(cliques.allSatisfy { $0 == $0.sorted() })
    }
}
