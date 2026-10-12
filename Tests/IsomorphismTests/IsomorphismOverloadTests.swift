// The overloads pass their arguments through: each colour closure reaches the problem it names,
// equal colours get equal ids in both graphs whatever order they first appear in, and each entry
// point solves its own problem (induced or not). Small graphs where dropping or mixing up an
// argument changes the answer, written out by hand.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism overloads pass their arguments through")
struct IsomorphismOverloadTests {
    @Test("Undirected edge colours that first appear in another order in the target still match")
    func undirectedEdgeColorOrder() {
        // The path 0–1–2–3 coloured red, red, blue in both graphs; the target lists its blue edge
        // first. The identity is the only coloured isomorphism (the reversal maps blue onto red).
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(2, 3), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternEdgeColor = ["red", "red", "blue"]
        let targetEdgeColor = ["blue", "red", "red"]
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(all == [[0, 1, 2, 3]])
        #expect(pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }))
    }

    @Test("Undirected monomorphism with edge colours keeps the pattern's edge colour")
    func undirectedPatternEdgeColor() {
        // A red edge into the path 0–1–2 coloured blue, red: only the red edge 1–2, both ways.
        let pattern = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternEdgeColor = ["red"]
        let targetEdgeColor = ["blue", "red"]
        let all = Set(pattern.monomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) })
        #expect(all == [[1, 2], [2, 1]])
        let induced = Set(pattern.subgraphIsomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) })
        #expect(induced == [[1, 2], [2, 1]])
    }

    @Test("Directed vertex colours that first appear in another order in the target still match")
    func directedVertexColorOrder() {
        // The arc 0 → 1 with 0 red and 1 blue; the target lists the blue vertex first.
        let pattern = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [5, 4], edges: [DirectedEdge(from: 4, to: 5)])
        let patternColor = [0: "red", 1: "blue"]
        let targetColor = [5: "blue", 4: "red"]
        #expect(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == [[4, 5]])
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
    }

    @Test("Directed isomorphism with edge colours: the colours decide between the two bijections")
    func directedEdgeColors() {
        // The 2-cycle 0 ⇄ 1 with 0 → 1 red and 1 → 0 blue, against one with 0 → 1 blue and 1 → 0
        // red: only the swap keeps colours.
        let pattern = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let patternEdgeColor = ["red", "blue"]
        let targetEdgeColor = ["blue", "red"]
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(all == [[1, 0]])
        #expect(pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == [1, 0])
    }

    @Test("Directed isIsomorphic and monomorphism with edge colours: a recoloured arc is no match")
    func directedEdgeColorsDecide() {
        // The path 0 → 1 → 2 coloured red, red against red, blue: isomorphic without colours,
        // not with them.
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let patternEdgeColor = ["red", "red"]
        let targetEdgeColor = ["red", "blue"]
        #expect(pattern.isIsomorphic(to: target))
        #expect(!pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }))
        #expect(!pattern.isMonomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }))
        #expect(pattern.monomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == nil)
    }

    @Test("Directed monomorphisms and subgraph isomorphisms differ on an arc into a 2-cycle")
    func directedInducedOrNot() {
        // One arc a → b into 0 ⇄ 1: two monomorphisms, no induced copy (the reverse arc is extra).
        let pattern = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Set(pattern.monomorphisms(to: target).map { Array($0.images) }) == [[0, 1], [1, 0]])
        #expect(pattern.isMonomorphic(to: target))
        #expect(Array(pattern.subgraphIsomorphisms(to: target)).isEmpty)
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The same with vertex colours (one class).
        #expect(Set(pattern.monomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }).map { Array($0.images) }) == [[0, 1], [1, 0]])
        #expect(pattern.subgraphIsomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }) == nil)
        #expect(!pattern.isSubgraphIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }))
    }

    @Test("Directed Weisfeiler–Leman with edge colours: recolouring an arc changes the hash")
    func directedHashEdgeColors() {
        let g = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let same = ["red", "red"], recoloured = ["red", "blue"]
        #expect(g.weisfeilerLehmanGraphHash(vertexColor: { _ in 0 }, edgeColor: { same[$0] }) != g.weisfeilerLehmanGraphHash(vertexColor: { _ in 0 }, edgeColor: { recoloured[$0] }))
        #expect(g.weisfeilerLehmanGraphHash(vertexColor: { _ in 0 }, edgeColor: { same[$0] }) == g.weisfeilerLehmanGraphHash(vertexColor: { _ in 0 }, edgeColor: { _ in "red" }))
    }

    @Test("Directed automorphism group with vertex colours: one coloured vertex leaves only the identity of C3")
    func directedGroupVertexColors() {
        let c3 = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        #expect(c3.automorphismGroup().order == 3)
        #expect(c3.automorphismGroup(vertexColor: { $0 == 0 ? "red" : "blue" }).order == 1)
        #expect(c3.automorphismGroup(vertexColor: { $0 == 0 ? "red" : "blue" }, edgeColor: { _ in 0 }).order == 1)
    }

    @Test("Directed preimage(safe:) is nil for a vertex outside the target")
    func directedSafePreimage() throws {
        let g = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let h = DirectedPseudograph<Int>(vertices: [5, 6], edges: [DirectedEdge(from: 6, to: 5)])
        let mapping = try #require(g.isomorphism(to: h))
        #expect(mapping.preimage(safe: 99) == nil)
        #expect(mapping.preimage(safe: 5) == 1)
    }

    @Test("Canonical forms keep direction: K2 is not the directed 2-cycle; a loop beside a vertex is not an arc")
    func canonicalFormsKeepDirection() {
        let edge = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let twoCycle = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(edge.canonicalLabeling().form != twoCycle.canonicalLabeling().form)
        let loop = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0)])
        let arc = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 0)])
        #expect(loop.canonicalLabeling().form != arc.canonicalLabeling().form)
        #expect(loop.canonicalLabeling().form == DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 1, to: 1)]).canonicalLabeling().form)
    }

    @Test("Undirected subgraph isomorphism with vertex colours stays induced: a path has no induced copy in a triangle")
    func undirectedInducedWithColors() {
        let path = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let triangle = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(Array(path.subgraphIsomorphisms(to: triangle, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 })).isEmpty)
        #expect(!path.isSubgraphIsomorphic(to: triangle, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }))
        #expect(path.subgraphIsomorphism(to: triangle, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }) == nil)
        #expect(Array(path.monomorphisms(to: triangle, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 })).count == 6)
    }

    @Test("Directed Weisfeiler–Leman with vertex colours: moving a colour changes the hash")
    func directedHashVertexColors() {
        let path = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(path.weisfeilerLehmanGraphHash(vertexColor: { $0 == 0 ? "red" : "blue" }) != path.weisfeilerLehmanGraphHash(vertexColor: { $0 == 2 ? "red" : "blue" }))
        #expect(path.weisfeilerLehmanGraphHash(vertexColor: { _ in "blue" }) != path.weisfeilerLehmanGraphHash(vertexColor: { $0 == 2 ? "red" : "blue" }))
    }
}

