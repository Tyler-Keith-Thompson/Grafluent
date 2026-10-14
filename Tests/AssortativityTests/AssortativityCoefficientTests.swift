// Degree, attribute and numeric assortativity on hand-computed graphs. Undirected graphs read
// every edge in both directions (a self-loop twice); directed graphs read every arc once, with the
// tail's `source` degree against the head's `target` degree. Expected values are worked out by
// hand (fractions in the comments) and agree with NetworkX 3.7 to within 1e-12, which the tests
// allow for rounding.

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Assortativity coefficients")
struct AssortativityCoefficientTests {
    @Test("A star is perfectly disassortative: r = −1")
    func star() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let r = try #require(graph.degreeAssortativityCoefficient())
        #expect(r == -1)
    }

    @Test("The path P4: pairs (1,2)×2, (2,1)×2, (2,2)×2 give r = −1/2")
    func path() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let r = try #require(graph.degreeAssortativityCoefficient())
        #expect(abs(r - -0.5) <= 1e-12)
    }

    @Test("A triangle with a pendant: r = −5/7")
    func trianglePendant() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let r = try #require(graph.degreeAssortativityCoefficient())
        #expect(abs(r - -5.0 / 7.0) <= 1e-12)
    }

    @Test("Two disjoint stars of different sizes joined by nothing are still disassortative")
    func twoStars() throws {
        // Degrees: hubs 2 and 3, leaves 1. Pairs (2,1)×2, (1,2)×2, (3,1)×3, (1,3)×3.
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(3, 4), UndirectedEdge(3, 5), UndirectedEdge(3, 6)])
        let pairs: [(Double, Double)] = [(2, 1), (2, 1), (1, 2), (1, 2), (3, 1), (3, 1), (3, 1), (1, 3), (1, 3), (1, 3)]
        let mx = pairs.map(\.0).reduce(0, +) / 10, my = pairs.map(\.1).reduce(0, +) / 10
        let cov = pairs.map { ($0.0 - mx) * ($0.1 - my) }.reduce(0, +)
        let vx = pairs.map { ($0.0 - mx) * ($0.0 - mx) }.reduce(0, +), vy = pairs.map { ($0.1 - my) * ($0.1 - my) }.reduce(0, +)
        let r = try #require(graph.degreeAssortativityCoefficient())
        #expect(abs(r - cov / (vx * vy).squareRoot()) <= 1e-12)
        #expect(r < 0)
    }

    @Test("Undefined without edges or with every degree equal: nil")
    func undefined() {
        #expect(UndirectedAdjacencyList<Int>().degreeAssortativityCoefficient() == nil)
        #expect(UndirectedAdjacencyList(vertices: 0 ..< 3, edges: []).degreeAssortativityCoefficient() == nil)
        // K3 and C5 are regular.
        #expect(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]).degreeAssortativityCoefficient() == nil)
        let cycle = UndirectedAdjacencyList(edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        #expect(cycle.degreeAssortativityCoefficient() == nil)
        // One edge: both ends degree 1.
        #expect(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).degreeAssortativityCoefficient() == nil)
        let weighted = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(weighted.degreeAssortativityCoefficient(weight: { _ in 1.0 }) != nil)
        // A path whose weights make every weighted degree 2.
        let even = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let w: [Double] = [2, 0, 2]
        #expect(even.degreeAssortativityCoefficient(weight: { w[$0] }) == nil)
    }

    @Test("A self-loop is read twice and counts 2 in its vertex's degree")
    func selfLoop() throws {
        // Edges 0–1, 1–2, loop at 2: degrees 1, 2, 3. Edge ends: (1,2), (2,1), (2,3), (3,2), (3,3), (3,3).
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        let pairs: [(Double, Double)] = [(1, 2), (2, 1), (2, 3), (3, 2), (3, 3), (3, 3)]
        let mx = pairs.map(\.0).reduce(0, +) / 6
        let cov = pairs.map { ($0.0 - mx) * ($0.1 - mx) }.reduce(0, +)
        let v = pairs.map { ($0.0 - mx) * ($0.0 - mx) }.reduce(0, +)
        let r = try #require(graph.degreeAssortativityCoefficient())
        #expect(abs(r - cov / v) <= 1e-12)
    }

    @Test("Parallel edges each count, at both ends and in the degrees")
    func parallelEdges() throws {
        // 0–1 twice, 1–2: degrees 2, 3, 1. Ends: (2,3)×2, (3,2)×2, (3,1), (1,3).
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let pairs: [(Double, Double)] = [(2, 3), (2, 3), (3, 2), (3, 2), (3, 1), (1, 3)]
        let mx = pairs.map(\.0).reduce(0, +) / 6
        let cov = pairs.map { ($0.0 - mx) * ($0.1 - mx) }.reduce(0, +)
        let v = pairs.map { ($0.0 - mx) * ($0.0 - mx) }.reduce(0, +)
        let r = try #require(graph.degreeAssortativityCoefficient())
        #expect(abs(r - cov / v) <= 1e-12)
    }

    @Test("Weighted degrees: the triangle with a pendant, weights 1, 2, 0.5, 4")
    func weighted() throws {
        // Strengths: 0 → 3, 1 → 1.5, 2 → 6.5, 3 → 4.
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let w: [Double] = [1, 2, 0.5, 4]
        let r = try #require(graph.degreeAssortativityCoefficient(weight: { w[$0] }))
        #expect(abs(r - -0.37723424270931327) <= 1e-12)
        let single = try #require(graph.degreeAssortativityCoefficient(weight: { Float(w[$0]) }))
        #expect(abs(single - r) <= 1e-12)
    }

    @Test("Directed: every pairing of in- and out-degree on a six-arc digraph")
    func directedPairings() throws {
        // Arcs 0→1, 0→2, 1→2, 2→0, 2→3, 3→2. Out: 2, 1, 2, 1. In: 1, 1, 3, 1.
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let expected: [(DegreeType, DegreeType, Double)] = [
            (.in, .in, -0.7071067811865474), (.in, .out, -0.25), (.out, .in, -0.7071067811865485), (.out, .out, -0.5),
        ]
        for (x, y, value) in expected {
            let r = try #require(graph.degreeAssortativityCoefficient(source: x, target: y))
            #expect(abs(r - value) <= 1e-12, "\(x) \(y)")
        }
        #expect(graph.degreeAssortativityCoefficient() == graph.degreeAssortativityCoefficient(source: .out, target: .in))
        // Total degrees: 3, 2, 5, 2; arcs pair (3,2), (3,5), (2,5), (5,3), (5,2), (2,5).
        let pairs: [(Double, Double)] = [(3, 2), (3, 5), (2, 5), (5, 3), (5, 2), (2, 5)]
        let mx = pairs.map(\.0).reduce(0, +) / 6, my = pairs.map(\.1).reduce(0, +) / 6
        let cov = pairs.map { ($0.0 - mx) * ($0.1 - my) }.reduce(0, +)
        let vx = pairs.map { ($0.0 - mx) * ($0.0 - mx) }.reduce(0, +), vy = pairs.map { ($0.1 - my) * ($0.1 - my) }.reduce(0, +)
        let total = try #require(graph.degreeAssortativityCoefficient(source: .total, target: .total))
        #expect(abs(total - cov / (vx * vy).squareRoot()) <= 1e-12)
    }

    @Test("Directed: an out-star has every tail of out-degree 3 and every head of in-degree 1: nil")
    func directedUndefined() {
        let star = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3)])
        #expect(star.degreeAssortativityCoefficient() == nil)
        #expect(star.degreeAssortativityCoefficient(source: .in, target: .out) == nil)
        #expect(AdjacencyList<Int>(vertices: 0 ..< 4, edges: []).degreeAssortativityCoefficient() == nil)
        #expect(AdjacencyList<Int>().degreeAssortativityCoefficient(source: .total, target: .total) == nil)
    }

    @Test("Directed weighted: tails' weighted out-degrees against heads' weighted in-degrees")
    func directedWeighted() throws {
        // Arcs 0→1 (1), 0→2 (3), 1→2 (2): out 4, 2, 0; in 0, 1, 5. Pairs (4,1), (4,5), (2,5).
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        let w: [Double] = graph.edges.map { $0.source == 0 && $0.target == 1 ? 1 : $0.source == 0 ? 3 : 2 }
        let pairs: [(Double, Double)] = [(4, 1), (4, 5), (2, 5)]
        let mx = pairs.map(\.0).reduce(0, +) / 3, my = pairs.map(\.1).reduce(0, +) / 3
        let cov = pairs.map { ($0.0 - mx) * ($0.1 - my) }.reduce(0, +)
        let vx = pairs.map { ($0.0 - mx) * ($0.0 - mx) }.reduce(0, +), vy = pairs.map { ($0.1 - my) * ($0.1 - my) }.reduce(0, +)
        let r = try #require(graph.degreeAssortativityCoefficient(weight: { w[$0] }))
        #expect(abs(r - cov / (vx * vy).squareRoot()) <= 1e-12)
    }

    @Test("A directed self-loop is one arc from the vertex to itself")
    func directedSelfLoop() throws {
        // Arcs 0→0, 0→1, 1→2: out 2, 1, 0; in 1, 1, 1 → heads' in-degrees all 1: nil for y = in.
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.degreeAssortativityCoefficient() == nil)
        // y = out: pairs (2,2), (2,1), (1,0).
        let pairs: [(Double, Double)] = [(2, 2), (2, 1), (1, 0)]
        let mx = pairs.map(\.0).reduce(0, +) / 3, my = pairs.map(\.1).reduce(0, +) / 3
        let cov = pairs.map { ($0.0 - mx) * ($0.1 - my) }.reduce(0, +)
        let vx = pairs.map { ($0.0 - mx) * ($0.0 - mx) }.reduce(0, +), vy = pairs.map { ($0.1 - my) * ($0.1 - my) }.reduce(0, +)
        let r = try #require(graph.degreeAssortativityCoefficient(source: .out, target: .out))
        #expect(abs(r - cov / (vx * vy).squareRoot()) <= 1e-12)
    }

    @Test("Attribute assortativity: classes split evenly by the triangle's bridge give r = 0")
    func attributeZero() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let classes = ["a", "a", "b", "b"]
        let r = try #require(graph.attributeAssortativityCoefficient(attribute: { classes[$0] }))
        #expect(abs(r) <= 1e-12)
    }

    @Test("Attribute assortativity: 1 when every edge stays in its class, −1 for a bipartition")
    func attributeExtremes() throws {
        let twoTriangles = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        #expect(try #require(twoTriangles.attributeAssortativityCoefficient(attribute: { $0 < 3 })) == 1)
        let square = UndirectedAdjacencyList(edges: (0 ..< 4).map { UndirectedEdge($0, ($0 + 1) % 4) })
        #expect(try #require(square.attributeAssortativityCoefficient(attribute: { $0 % 2 })) == -1)
    }

    @Test("Attribute assortativity: nil without edges, or with every edge inside one class")
    func attributeUndefined() {
        #expect(UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: []).attributeAssortativityCoefficient(attribute: { $0 }) == nil)
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        // Vertex 3 is in class 1 but has no edge.
        #expect(graph.attributeAssortativityCoefficient(attribute: { $0 == 3 ? 1 : 0 }) == nil)
        #expect(graph.attributeAssortativityCoefficient(attribute: { $0 == 0 ? 1 : 0 }) != nil)
    }

    @Test("Attribute assortativity: three classes on a path, (Σ e_cc − Σ a_c²) / (1 − Σ a_c²)")
    func attributeThreeClasses() throws {
        // Path 0–1–2–3–4, classes a a b c c: edges (a,a), (a,b), (b,c), (c,c), each both ways, 8
        // ends. e_aa = e_cc = 2/8; a_a = 3/8, a_b = 2/8, a_c = 3/8.
        let graph = UndirectedAdjacencyList(edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let classes: [Character] = ["a", "a", "b", "c", "c"]
        let s = (9.0 + 4 + 9) / 64
        let expected = (4.0 / 8 - s) / (1 - s)
        let r = try #require(graph.attributeAssortativityCoefficient(attribute: { classes[$0] }))
        #expect(abs(r - expected) <= 1e-12)
    }

    @Test("Attribute assortativity, directed: arcs only from class a to class b give 0, within classes 1, both ways across −1")
    func attributeDirected() throws {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 0, to: 3)])
        // e_ab = 1, a_a = 1, b_b = 1, so Σ a_c b_c = 0: (0 − 0) / (1 − 0) = 0.
        let r = try #require(graph.attributeAssortativityCoefficient(attribute: { $0 < 2 }))
        #expect(r == 0)
        // Every arc within class: 1.
        let within = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3)])
        #expect(try #require(within.attributeAssortativityCoefficient(attribute: { $0 < 2 })) == 1)
        // Arcs both ways across: −1.
        let across = AdjacencyList(edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 1)])
        #expect(try #require(across.attributeAssortativityCoefficient(attribute: { $0 < 2 })) == -1)
        // The six-arc digraph with classes a a b b, as NetworkX gives.
        let six = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        #expect(abs(try #require(six.attributeAssortativityCoefficient(attribute: { $0 < 2 }))) <= 1e-12)
    }

    @Test("Numeric assortativity: Pearson's r of the values at edge ends")
    func numeric() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let x: [Double] = [1, 2, 3, 5]
        let r = try #require(graph.numericAssortativityCoefficient(attribute: { x[$0] }))
        #expect(abs(r - 1.0 / 6.0) <= 1e-12)
        // The degrees as values give the degree coefficient.
        let byDegree = try #require(graph.numericAssortativityCoefficient(attribute: { Double(graph.degree(of: $0)) }))
        #expect(abs(byDegree - -5.0 / 7.0) <= 1e-12)
        #expect(graph.numericAssortativityCoefficient(attribute: { _ in 4.0 }) == nil)
        #expect(UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: []).numericAssortativityCoefficient(attribute: { Double($0) }) == nil)
    }

    @Test("Numeric assortativity, directed: tail values against head values")
    func numericDirected() throws {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let x: [Double] = [1, 2, 3, 5]
        let r = try #require(graph.numericAssortativityCoefficient(attribute: { x[$0] }))
        #expect(abs(r - 0.14882641804174723) <= 1e-12)
        // A chain whose values rise along every arc: r = 1.
        let chain = AdjacencyList(edges: (0 ..< 4).map { DirectedEdge(from: $0, to: $0 + 1) })
        #expect(abs(try #require(chain.numericAssortativityCoefficient(attribute: { Double($0) })) - 1) <= 1e-12)
        #expect(chain.numericAssortativityCoefficient(attribute: { Float($0 % 1) }) == nil)
    }

    @Test("The attribute is called once per vertex, in vertices order")
    func attributeCalls() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(2, 0), UndirectedEdge(0, 1)])
        var seen: [Int] = []
        _ = graph.attributeAssortativityCoefficient(attribute: { (v: Int) -> Int in seen.append(v); return v })
        #expect(seen == Array(graph.vertices))
        seen = []
        _ = graph.numericAssortativityCoefficient(attribute: { (v: Int) -> Double in seen.append(v); return Double(v) })
        #expect(seen == Array(graph.vertices))
        let digraph = AdjacencyList(edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)])
        seen = []
        _ = digraph.attributeAssortativityCoefficient(attribute: { (v: Int) -> Int in seen.append(v); return v })
        #expect(seen == Array(digraph.vertices))
        seen = []
        _ = digraph.numericAssortativityCoefficient(attribute: { (v: Int) -> Double in seen.append(v); return Double(v) })
        #expect(seen == Array(digraph.vertices))
    }

    @Test("The weight is called once per edge, in position order")
    func weightCalls() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(2, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 3)])
        var seen: [Int] = []
        _ = graph.degreeAssortativityCoefficient(weight: { (p: Int) -> Double in seen.append(p); return 1 })
        #expect(seen == Array(graph.edges.indices))
        let digraph = AdjacencyList(edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)])
        seen = []
        _ = digraph.degreeAssortativityCoefficient(weight: { (p: Int) -> Double in seen.append(p); return 1 })
        #expect(seen == Array(digraph.edges.indices))
    }
}
