// Pairs where every wrong branch of the joint search fails deep, so that the search gives up and
// the pair is decided by its components (each matched by canonical labeling) or, when connected,
// by the canonical labelings of the whole graphs. The graphs are the CFI graph over K4 and its
// twisted form, which colour refinement cannot tell apart until several vertices are fixed: their
// disjoint union (two components), its complement (connected), and coloured and directed forms.
// Each isomorphic pair is checked mapping by mapping, and each non-isomorphic one answers no.

import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism decided by components and canonical labelings")
struct IsomorphismFallbackTests {
    @Test("CFI(K4) and its twisted form side by side, against a relabelled copy: valid mappings, as many as automorphisms")
    func componentsOfUnion() throws {
        // CFI over K4: per base vertex 4 middle vertices (the even subsets of its 3 edges) and a
        // pair a0, a1 per incident edge; middle S joins a1 of the edges in S and a0 of the others;
        // each base edge joins the pairs at its ends straight, or crossed on the first edge when
        // twisted. 40 vertices, 60 edges.
        func cfi(twisted: Bool, offset: Int) -> [(Int, Int)] {
            let base = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            var incident = [[Int]](repeating: [], count: 4)
            for (k, e) in base.enumerated() { incident[e.0].append(k); incident[e.1].append(k) }
            var next = offset
            var pair = [[Int: [Int]]](repeating: [:], count: 4)
            var edges: [(Int, Int)] = []
            for v in 0 ..< 4 {
                var middles: [(Int, Int)] = []
                for mask in 0 ..< 8 where mask.nonzeroBitCount % 2 == 0 {
                    middles.append((next, mask))
                    next += 1
                }
                for j in 0 ..< 3 {
                    pair[v][incident[v][j]] = [next, next + 1]
                    next += 2
                }
                for (m, mask) in middles {
                    for j in 0 ..< 3 { edges.append((m, pair[v][incident[v][j]]![(mask >> j) & 1])) }
                }
            }
            for (k, e) in base.enumerated() {
                let t = twisted && k == 0 ? 1 : 0
                for i in 0 ..< 2 { edges.append((pair[e.0][k]![i], pair[e.1][k]![i ^ t])) }
            }
            return edges
        }
        let union = cfi(twisted: false, offset: 0) + cfi(twisted: true, offset: 40)
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 51)
        // The twisted half takes the low numbers in H, so that the joint search tries the wrong half
        // first and gives up.
        let permutation = Array(40 ..< 80).shuffled(using: &rng) + Array(0 ..< 40).shuffled(using: &rng)
        let g = Pseudograph<Int>(vertices: Array(0 ..< 80), edges: union.map { UndirectedEdge($0.0, $0.1) })
        let h = Pseudograph<Int>(vertices: Array(0 ..< 80), edges: union.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.0], permutation[$0.1]) })
        let plain = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: cfi(twisted: false, offset: 0).map { UndirectedEdge($0.0, $0.1) })
        let twisted = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: cfi(twisted: true, offset: 0).map { UndirectedEdge($0.0, $0.1) })
        #expect(!plain.isIsomorphic(to: twisted))
        func isValid(_ images: [Int]) -> Bool {
            guard Set(images).count == 80 else { return false }
            return g.edges.allSatisfy { h.contains(edge: UndirectedEdge(images[$0.u], images[$0.v])) }
        }
        let first = try #require(g.isomorphism(to: h))
        #expect(isValid(Array(first.images)))
        // Every mapping counted; the first 50 checked and distinct.
        var count = 0
        var seen = Set<[Int]>()
        for mapping in g.isomorphisms(to: h) {
            count += 1
            if count <= 50 {
                #expect(isValid(Array(mapping.images)))
                seen.insert(Array(mapping.images))
            }
        }
        #expect(seen.count == min(count, 50))
        #expect(Double(count) == g.automorphismGroup().order)
        #expect(Double(count) == plain.automorphismGroup().order * twisted.automorphismGroup().order)
    }

    @Test("The complement of CFI(K4) beside its twisted form (connected) against a relabelled copy: valid mappings, as many as automorphisms")
    func canonicalLabelingsOfConnectedPair() throws {
        func cfi(twisted: Bool, offset: Int) -> [(Int, Int)] {
            let base = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            var incident = [[Int]](repeating: [], count: 4)
            for (k, e) in base.enumerated() { incident[e.0].append(k); incident[e.1].append(k) }
            var next = offset
            var pair = [[Int: [Int]]](repeating: [:], count: 4)
            var edges: [(Int, Int)] = []
            for v in 0 ..< 4 {
                var middles: [(Int, Int)] = []
                for mask in 0 ..< 8 where mask.nonzeroBitCount % 2 == 0 {
                    middles.append((next, mask))
                    next += 1
                }
                for j in 0 ..< 3 {
                    pair[v][incident[v][j]] = [next, next + 1]
                    next += 2
                }
                for (m, mask) in middles {
                    for j in 0 ..< 3 { edges.append((m, pair[v][incident[v][j]]![(mask >> j) & 1])) }
                }
            }
            for (k, e) in base.enumerated() {
                let t = twisted && k == 0 ? 1 : 0
                for i in 0 ..< 2 { edges.append((pair[e.0][k]![i], pair[e.1][k]![i ^ t])) }
            }
            return edges
        }
        let present = Set((cfi(twisted: false, offset: 0) + cfi(twisted: true, offset: 40)).map { [min($0.0, $0.1), max($0.0, $0.1)] })
        var complement: [(Int, Int)] = []
        for a in 0 ..< 80 { for b in a + 1 ..< 80 where !present.contains([a, b]) { complement.append((a, b)) } }
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 52)
        // The twisted half takes the low numbers in H, so that the joint search tries the wrong half
        // first and gives up.
        let permutation = Array(40 ..< 80).shuffled(using: &rng) + Array(0 ..< 40).shuffled(using: &rng)
        let g = Pseudograph<Int>(vertices: Array(0 ..< 80), edges: complement.map { UndirectedEdge($0.0, $0.1) })
        let h = Pseudograph<Int>(vertices: Array(0 ..< 80), edges: complement.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.0], permutation[$0.1]) })
        func isValid(_ images: [Int]) -> Bool {
            guard Set(images).count == 80 else { return false }
            return g.edges.allSatisfy { h.contains(edge: UndirectedEdge(images[$0.u], images[$0.v])) }
        }
        let first = try #require(g.isomorphism(to: h))
        #expect(isValid(Array(first.images)))
        var count = 0
        var seen = Set<[Int]>()
        for mapping in g.isomorphisms(to: h) {
            count += 1
            if count <= 20 {
                #expect(isValid(Array(mapping.images)))
                seen.insert(Array(mapping.images))
            }
        }
        #expect(seen.count == min(count, 20))
        #expect(Double(count) == g.automorphismGroup().order)
        #expect(g.canonicalLabeling().form == h.canonicalLabeling().form)
    }

    @Test("Coloured CFI(K4) beside its twisted form: colours on the other component make the pair non-isomorphic; matching colours keep it isomorphic")
    func colouredComponents() throws {
        func cfi(twisted: Bool, offset: Int) -> [(Int, Int)] {
            let base = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            var incident = [[Int]](repeating: [], count: 4)
            for (k, e) in base.enumerated() { incident[e.0].append(k); incident[e.1].append(k) }
            var next = offset
            var pair = [[Int: [Int]]](repeating: [:], count: 4)
            var edges: [(Int, Int)] = []
            for v in 0 ..< 4 {
                var middles: [(Int, Int)] = []
                for mask in 0 ..< 8 where mask.nonzeroBitCount % 2 == 0 {
                    middles.append((next, mask))
                    next += 1
                }
                for j in 0 ..< 3 {
                    pair[v][incident[v][j]] = [next, next + 1]
                    next += 2
                }
                for (m, mask) in middles {
                    for j in 0 ..< 3 { edges.append((m, pair[v][incident[v][j]]![(mask >> j) & 1])) }
                }
            }
            for (k, e) in base.enumerated() {
                let t = twisted && k == 0 ? 1 : 0
                for i in 0 ..< 2 { edges.append((pair[e.0][k]![i], pair[e.1][k]![i ^ t])) }
            }
            return edges
        }
        // Vertices 0..<40 are the plain graph, 40..<80 the twisted one; edges likewise, 60 each.
        let union = cfi(twisted: false, offset: 0) + cfi(twisted: true, offset: 40)
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 53)
        // The twisted half takes the low numbers in H, so that the joint search tries the wrong half
        // first and gives up.
        let permutation = Array(40 ..< 80).shuffled(using: &rng) + Array(0 ..< 40).shuffled(using: &rng)
        let order = Array(union.indices).shuffled(using: &rng)
        let g = Pseudograph<Int>(vertices: Array(0 ..< 80), edges: union.map { UndirectedEdge($0.0, $0.1) })
        let h = Pseudograph<Int>(vertices: Array(0 ..< 80), edges: order.map { UndirectedEdge(permutation[union[$0].0], permutation[union[$0].1]) })
        var preimage = [Int](repeating: 0, count: 80)
        for v in 0 ..< 80 { preimage[permutation[v]] = v }
        // Vertex colours: the plain component red in G; in H the same (by preimage), or swapped.
        let same = h.isIsomorphic(to: g)
        #expect(same)
        let gColor = { (v: Int) in v < 40 ? "red" : "blue" }
        let hColor = { (v: Int) in preimage[v] < 40 ? "red" : "blue" }
        let hSwapped = { (v: Int) in preimage[v] < 40 ? "blue" : "red" }
        let mapping = try #require(g.isomorphism(to: h, vertexColor: gColor, otherVertexColor: hColor))
        #expect(g.vertices.allSatisfy { gColor($0) == hColor(mapping.image(of: $0)) })
        #expect(g.edges.allSatisfy { h.contains(edge: UndirectedEdge(mapping.image(of: $0.u), mapping.image(of: $0.v))) })
        #expect(!g.isIsomorphic(to: h, vertexColor: gColor, otherVertexColor: hSwapped))
        // Edge colours (one vertex colour): the plain component's edges red in G; in H the same,
        // or swapped.
        let gEdge = { (position: Int) in position < 60 ? "red" : "blue" }
        let hEdge = { (position: Int) in order[position] < 60 ? "red" : "blue" }
        let hEdgeSwapped = { (position: Int) in order[position] < 60 ? "blue" : "red" }
        let colored = try #require(g.isomorphism(to: h, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: gEdge, otherEdgeColor: hEdge))
        #expect(g.edges.allSatisfy { h.contains(edge: UndirectedEdge(colored.image(of: $0.u), colored.image(of: $0.v))) })
        #expect(colored.images.allSatisfy { (preimage[$0] < 40) == (colored.preimage(of: $0)! < 40) })
        #expect(!g.isIsomorphic(to: h, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: gEdge, otherEdgeColor: hEdgeSwapped))
    }

    @Test("Directed: CFI(K4) beside its twisted form with arcs both ways and an arc in from an extra vertex on each side, against a relabelled copy")
    func directedComponents() throws {
        func cfi(twisted: Bool, offset: Int) -> [(Int, Int)] {
            let base = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            var incident = [[Int]](repeating: [], count: 4)
            for (k, e) in base.enumerated() { incident[e.0].append(k); incident[e.1].append(k) }
            var next = offset
            var pair = [[Int: [Int]]](repeating: [:], count: 4)
            var edges: [(Int, Int)] = []
            for v in 0 ..< 4 {
                var middles: [(Int, Int)] = []
                for mask in 0 ..< 8 where mask.nonzeroBitCount % 2 == 0 {
                    middles.append((next, mask))
                    next += 1
                }
                for j in 0 ..< 3 {
                    pair[v][incident[v][j]] = [next, next + 1]
                    next += 2
                }
                for (m, mask) in middles {
                    for j in 0 ..< 3 { edges.append((m, pair[v][incident[v][j]]![(mask >> j) & 1])) }
                }
            }
            for (k, e) in base.enumerated() {
                let t = twisted && k == 0 ? 1 : 0
                for i in 0 ..< 2 { edges.append((pair[e.0][k]![i], pair[e.1][k]![i ^ t])) }
            }
            return edges
        }
        // Each edge as two arcs; vertex 80 has one arc, into vertex 7 of the plain graph, and vertex
        // 81 one into the same vertex of the twisted graph (47), reachable only against the arcs.
        var arcs: [(Int, Int)] = []
        for e in cfi(twisted: false, offset: 0) + cfi(twisted: true, offset: 40) { arcs.append(e); arcs.append((e.1, e.0)) }
        arcs.append((80, 7))
        arcs.append((81, 47))
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 54)
        // The twisted half takes the low numbers in H, and its extra vertex the lower of the two, so
        // that the joint search tries the wrong half first and gives up.
        let permutation = Array(40 ..< 80).shuffled(using: &rng) + Array(0 ..< 40).shuffled(using: &rng) + [81, 80]
        let g = DirectedPseudograph<Int>(vertices: Array(0 ..< 82), edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let h = DirectedPseudograph<Int>(vertices: Array(0 ..< 82), edges: arcs.shuffled(using: &rng).map { DirectedEdge(from: permutation[$0.0], to: permutation[$0.1]) })
        let mapping = try #require(g.isomorphism(to: h))
        #expect(Set(mapping.images).count == 82)
        #expect(g.edges.allSatisfy { h.contains(edge: DirectedEdge(from: mapping.image(of: $0.source), to: mapping.image(of: $0.target))) })
        #expect(mapping.image(of: 80) == 81)
        // Reversing the extra arc: not isomorphic.
        let reversed = DirectedPseudograph<Int>(vertices: Array(0 ..< 82), edges: (arcs.filter { $0 != (80, 7) } + [(7, 80)]).map { DirectedEdge(from: permutation[$0.0], to: permutation[$0.1]) })
        #expect(!g.isIsomorphic(to: reversed))
    }

    @Test("Canonical forms of 20 relabellings each of Paley(13), the Latin-square graph of Z7, and CFI(K4) beside its twisted form are equal; the families' forms differ")
    func canonicalFormsOfRelabellings() {
        func paley13() -> [(Int, Int)] {
            let squares = Set((1 ..< 13).map { $0 * $0 % 13 })
            var edges: [(Int, Int)] = []
            for a in 0 ..< 13 { for b in a + 1 ..< 13 where squares.contains(b - a) { edges.append((a, b)) } }
            return edges
        }
        func latinSquare7() -> [(Int, Int)] {
            var edges: [(Int, Int)] = []
            for a in 0 ..< 49 {
                for b in a + 1 ..< 49 where a / 7 == b / 7 || a % 7 == b % 7 || (a / 7 + a % 7) % 7 == (b / 7 + b % 7) % 7 { edges.append((a, b)) }
            }
            return edges
        }
        func cfiPair() -> [(Int, Int)] {
            func cfi(twisted: Bool, offset: Int) -> [(Int, Int)] {
                let base = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
                var incident = [[Int]](repeating: [], count: 4)
                for (k, e) in base.enumerated() { incident[e.0].append(k); incident[e.1].append(k) }
                var next = offset
                var pair = [[Int: [Int]]](repeating: [:], count: 4)
                var edges: [(Int, Int)] = []
                for v in 0 ..< 4 {
                    var middles: [(Int, Int)] = []
                    for mask in 0 ..< 8 where mask.nonzeroBitCount % 2 == 0 {
                        middles.append((next, mask))
                        next += 1
                    }
                    for j in 0 ..< 3 {
                        pair[v][incident[v][j]] = [next, next + 1]
                        next += 2
                    }
                    for (m, mask) in middles {
                        for j in 0 ..< 3 { edges.append((m, pair[v][incident[v][j]]![(mask >> j) & 1])) }
                    }
                }
                for (k, e) in base.enumerated() {
                    let t = twisted && k == 0 ? 1 : 0
                    for i in 0 ..< 2 { edges.append((pair[e.0][k]![i], pair[e.1][k]![i ^ t])) }
                }
                return edges
            }
            return cfi(twisted: false, offset: 0) + cfi(twisted: true, offset: 40)
        }
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 55)
        var forms: [CanonicalForm] = []
        for (n, edges) in [(13, paley13()), (49, latinSquare7()), (80, cfiPair())] {
            let reference = Pseudograph<Int>(vertices: Array(0 ..< n), edges: edges.map { UndirectedEdge($0.0, $0.1) }).canonicalLabeling().form
            for _ in 0 ..< 20 {
                let permutation = Array(0 ..< n).shuffled(using: &rng)
                let copy = Pseudograph<Int>(vertices: Array(0 ..< n), edges: edges.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.0], permutation[$0.1]) })
                #expect(copy.canonicalLabeling().form == reference)
            }
            forms.append(reference)
        }
        #expect(Set(forms).count == 3)
    }
}

