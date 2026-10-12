// Pairs that joint colour refinement decides at the root, before any branching: colour classes of
// unequal sizes, classes of one vertex per graph whose neighbourhoods differ, and degree classes of
// a multigraph that split unevenly between the two graphs. Then the subgraph search on parallel
// edges and its per-colour cutting rule. Each pair is written out with its answer.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism decided by refinement at the root, and subgraph search pruning")
struct IsomorphismRefinementTests {
    @Test("Colour classes of different sizes: not isomorphic, with or without an edge")
    func unequalColourClasses() {
        let g = Pseudograph<Int>(vertices: [0, 1], edges: [])
        let h = Pseudograph<Int>(vertices: [0, 1], edges: [])
        let gColor = [0: "r", 1: "r"], hColor = [0: "r", 1: "b"]
        #expect(!g.isIsomorphic(to: h, vertexColor: { gColor[$0]! }, otherVertexColor: { hColor[$0]! }))
        #expect(Array(g.isomorphisms(to: h, vertexColor: { gColor[$0]! }, otherVertexColor: { hColor[$0]! })).isEmpty)
        let ge = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
        let he = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
        let gc = [0: "r", 1: "r", 2: "b"], hc = [0: "r", 1: "b", 2: "b"]
        #expect(ge.isomorphism(to: he, vertexColor: { gc[$0]! }, otherVertexColor: { hc[$0]! }) == nil)
    }

    @Test("One vertex per colour in each graph: the path a–b–c against a–c–b is not isomorphic; against its relabelling it is, once")
    func singletonClasses() {
        // Every colour class holds one vertex of each graph, so the colours alone pair the
        // vertices; the neighbourhoods must still agree.
        let g = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let h = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let gColor = [0: "a", 1: "b", 2: "c"]
        let wrong = [0: "a", 1: "c", 2: "b"]
        #expect(!g.isIsomorphic(to: h, vertexColor: { gColor[$0]! }, otherVertexColor: { wrong[$0]! }))
        #expect(Array(g.isomorphisms(to: h, vertexColor: { gColor[$0]! }, otherVertexColor: { wrong[$0]! })).isEmpty)
        let reversed = [0: "c", 1: "b", 2: "a"]
        #expect(g.isomorphisms(to: h, vertexColor: { gColor[$0]! }, otherVertexColor: { reversed[$0]! }).map { Array($0.images) } == [[2, 1, 0]])
        // Directed: a → b → c against a → c → b.
        let dg = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(!dg.isIsomorphic(to: dg, vertexColor: { gColor[$0]! }, otherVertexColor: { wrong[$0]! }))
    }

    @Test("Degrees 1, 1, 3, 3 against 1, 1, 2, 4 with four edges each (a parallel pair against a loop): not isomorphic")
    func unevenDegreeClasses() {
        // G: 0–2, 1–3 and 2–3 twice. H: 0–2, 1–3, 2–3 and a loop at 3 (which counts twice).
        let g = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 3)])
        let h = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 3)])
        #expect(g.edgeCount == h.edgeCount)
        #expect(!g.isIsomorphic(to: h))
        #expect(g.isomorphism(to: h) == nil)
        #expect(Array(g.isomorphisms(to: h)).isEmpty)
        // Six vertices: degrees 1, 1, 3, 3, 2, 2 against 1, 1, 2, 4, 2, 2 (a path 4–5 added to both).
        let g6 = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 3), UndirectedEdge(4, 5), UndirectedEdge(4, 5)])
        let h6 = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 3), UndirectedEdge(4, 5), UndirectedEdge(4, 5)])
        #expect(!g6.isIsomorphic(to: h6))
    }

    @Test("A parallel pair has no monomorphism into a triangle, and two into a triangle with one doubled edge")
    func parallelPatternIntoSimpleTarget() {
        let pattern = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let triangle = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(!pattern.isMonomorphic(to: triangle))
        #expect(Array(pattern.monomorphisms(to: triangle)).isEmpty)
        #expect(!pattern.isSubgraphIsomorphic(to: triangle))
        let doubled = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 0)])
        #expect(Set(pattern.monomorphisms(to: doubled).map { Array($0.images) }) == [[0, 2], [2, 0]])
        // Directed: a pair of parallel arcs into a directed triangle.
        let arcs = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let cycle = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        #expect(!arcs.isMonomorphic(to: cycle))
    }

    @Test("Per-colour cutting: a candidate without the needed colour fails, and the next one with it still matches")
    func colourCutAfterFailedCandidate() {
        // Pattern a (R) – b (B). Target: x1 (B) – y1 (G), x2 (B) – y2 (R), and three isolated R
        // vertices, so that b (the rarer colour in the target) is matched first: x1 has no R
        // neighbour, x2 has one.
        let pattern = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let target = Pseudograph<String>(vertices: ["x1", "y1", "x2", "y2", "r1", "r2", "r3"], edges: [UndirectedEdge("x1", "y1"), UndirectedEdge("x2", "y2")])
        let patternColor = ["a": "R", "b": "B"]
        let targetColor = ["x1": "B", "y1": "G", "x2": "B", "y2": "R", "r1": "R", "r2": "R", "r3": "R"]
        #expect(pattern.monomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == [["y2", "x2"]])
        #expect(pattern.subgraphIsomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == [["y2", "x2"]])
    }
}
