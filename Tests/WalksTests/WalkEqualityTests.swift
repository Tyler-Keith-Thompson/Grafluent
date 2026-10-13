// §7: equality and hashing. Walk, Trail and Path compare their vertices and edges exactly.
// Circuit compares up to rotation of the (vertex, edge) steps, never reversal; Cycle compares up
// to rotation and reversal. Both hash alike under every rotation and reversal. Edge positions here
// are plain integers; no graph is needed. Expected values come from the catalog's reference
// (ref.py, linear and brute-force equality). Case IDs (WK-nnn) refer to the catalog; see README.md.

import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk equality and hashing", .tags(.conformance))
struct WalkEqualityTests {
    @Test("WK-701 a cycle equals each of its rotations, with the same hash")
    func rotations() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        for k in 0 ..< 3 {
            let vs = Array([0, 1, 2][k...] + [0, 1, 2][..<k])
            let es = Array([10, 11, 12][k...] + [10, 11, 12][..<k])
            let r = try #require(Cycle(vertices: vs, edges: es))
            #expect(r == c, "k = \(k)")
            #expect(c == r, "k = \(k)")
            #expect(r.hashValue == c.hashValue, "k = \(k)")
            #expect(Array(r) == vs)
        }
    }

    @Test("WK-702 a cycle equals its reversal and each of its rotations, with the same hash")
    func reversalEqual() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        let r = try #require(Cycle(vertices: [0, 2, 1], edges: [12, 11, 10]))
        #expect(c == r)
        #expect(r == c)
        #expect(c.hashValue == r.hashValue)
        #expect(c == c.reversed())
        for (vs, es) in [([2, 1, 0], [11, 10, 12]), ([1, 0, 2], [10, 12, 11])] {
            let rotated = try #require(Cycle(vertices: vs, edges: es))
            #expect(c == rotated, "\(vs)")
            #expect(rotated == c, "\(vs)")
            #expect(c.hashValue == rotated.hashValue, "\(vs)")
        }
        // As circuits, the two directions stay apart.
        #expect(Circuit(c) != Circuit(r))
    }

    @Test("WK-703 reversing twice is the identity")
    func reverseTwice() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        #expect(c.reversed().reversed() == c)
        #expect(c.reversed().reversed().vertices == [0, 1, 2])
    }

    @Test("WK-704 reversed() lists the vertices backward, each edge the one that reached it, and twice is the original")
    func reversedShape() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        #expect(c.reversed().vertices == [2, 1, 0])
        #expect(c.reversed().edges == [11, 10, 12])
        #expect(c.reversed().reversed().vertices == c.vertices && c.reversed().reversed().edges == c.edges)
    }

    @Test("WK-705 the same vertices through a different edge are unequal")
    func differentEdge() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        #expect(c != (try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 13]))))
    }

    @Test("WK-706 the same edges with the vertices shifted against them are unequal")
    func shiftedVertices() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        #expect(c != (try #require(Cycle(vertices: [1, 0, 2], edges: [10, 11, 12]))))
    }

    @Test("WK-707 1-cycles are equal when their loop is", .tags(.selfLoops))
    func oneCycles() throws {
        let a = try #require(Cycle(vertices: [5], edges: [9]))
        #expect(a == a)
        #expect(a == (try #require(Cycle(vertices: [5], edges: [9]))))
        #expect(a != (try #require(Cycle(vertices: [5], edges: [8]))))
    }

    @Test("WK-708 a figure-eight circuit equals each of its six rotations, with the same hash")
    func figureEightRotations() throws {
        let vs = [0, 1, 2, 0, 3, 4]
        let es = [0, 1, 2, 3, 4, 5]
        let c = try #require(Circuit(vertices: vs, edges: es))
        for k in 0 ..< 6 {
            let r = try #require(Circuit(vertices: Array(vs[k...] + vs[..<k]), edges: Array(es[k...] + es[..<k])))
            #expect(r == c, "k = \(k)")
            #expect(r.hashValue == c.hashValue, "k = \(k)")
        }
    }

    @Test("WK-709 the rotation starting at the second visit of 0 is equal")
    func secondVisit() throws {
        let c = try #require(Circuit(vertices: [0, 1, 2, 0, 3, 4], edges: [0, 1, 2, 3, 4, 5]))
        let r = try #require(Circuit(vertices: [0, 3, 4, 0, 1, 2], edges: [3, 4, 5, 0, 1, 2]))
        #expect(c == r)
        #expect(c.hashValue == r.hashValue)
    }

    @Test("WK-710 the lobes swapped against their edges are unequal")
    func lobesSwapped() throws {
        let c = try #require(Circuit(vertices: [0, 1, 2, 0, 3, 4], edges: [0, 1, 2, 3, 4, 5]))
        #expect(c != (try #require(Circuit(vertices: [0, 3, 4, 0, 1, 2], edges: [0, 1, 2, 3, 4, 5]))))
    }

    @Test("WK-711 equality agrees with brute force on random circuits (rotation) and cycles (rotation and reversal), and equal values hash alike", .tags(.randomized), arguments: 0 ..< 4)
    func linearEqualsBruteForce(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(711_000 + seed))
        for _ in 0 ..< 500 {
            let n = Int.random(in: 1 ... 6, using: &rng)
            let va = (0 ..< n).map { _ in Int.random(in: 0 ..< 3, using: &rng) }
            let ea = Array(Array(0 ..< 8).shuffled(using: &rng).prefix(n))
            let k = Int.random(in: 0 ..< n, using: &rng)
            var vb = Array(va[k...] + va[..<k])
            var eb = Array(ea[k...] + ea[..<k])
            if Bool.random(using: &rng) {
                let i = Int.random(in: 0 ..< n, using: &rng)
                if Bool.random(using: &rng) {
                    vb[i] = Int.random(in: 0 ..< 3, using: &rng)
                } else if let fresh = (0 ..< 8).first(where: { !eb.contains($0) }) {
                    eb[i] = fresh
                }
            }
            let bruteForce = (0 ..< n).contains { r in
                Array(va[r...] + va[..<r]) == vb && Array(ea[r...] + ea[..<r]) == eb
            }
            let a = try #require(Circuit(vertices: va, edges: ea))
            let b = try #require(Circuit(vertices: vb, edges: eb))
            #expect((a == b) == bruteForce, "\(va) \(ea) vs \(vb) \(eb)")
            #expect((b == a) == bruteForce)
            if bruteForce { #expect(a.hashValue == b.hashValue) }
            if Set(va).count == n {
                // Sometimes the other direction: vb[0], vb[n − 1], …, vb[1], each step through the
                // edge that joins the pair.
                if Bool.random(using: &rng) {
                    let rv = (0 ..< n).map { vb[(n - $0) % n] }
                    let re = (0 ..< n).map { eb[(2 * n - 1 - $0) % n] }
                    vb = rv
                    eb = re
                }
                let cycleBruteForce = (0 ..< n).contains { r in
                    let rotated = (Array(va[r...] + va[..<r]), Array(ea[r...] + ea[..<r]))
                    let back = ((0 ..< n).map { rotated.0[(n - $0) % n] }, (0 ..< n).map { rotated.1[(2 * n - 1 - $0) % n] })
                    return (rotated.0 == vb && rotated.1 == eb) || (back.0 == vb && back.1 == eb)
                }
                let ca = try #require(Cycle(vertices: va, edges: ea))
                if let cb = Cycle(vertices: vb, edges: eb) {
                    #expect((ca == cb) == cycleBruteForce, "\(va) \(ea) vs \(vb) \(eb)")
                    #expect((cb == ca) == cycleBruteForce)
                    if cycleBruteForce { #expect(ca.hashValue == cb.hashValue) }
                }
            }
        }
    }

    @Test("WK-712 open walks compare exactly: a rotated closed walk is a different Walk")
    func openWalksExact() throws {
        let a = Walk(vertices: [0, 1, 2, 0], edges: [10, 11, 12])
        let b = Walk(vertices: [1, 2, 0, 1], edges: [11, 12, 10])
        #expect(a != b)
        #expect(a == (Walk(vertices: [0, 1, 2, 0], edges: [10, 11, 12])))
        #expect(Circuit(a) == Circuit(b))
    }

    @Test("WK-713 a Set of three rotations of a cycle and its reversal has one member")
    func setOfRotations() throws {
        let c0 = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        let c1 = try #require(Cycle(vertices: [1, 2, 0], edges: [11, 12, 10]))
        let c2 = try #require(Cycle(vertices: [2, 0, 1], edges: [12, 10, 11]))
        let set: Set = [c0, c1, c2, c0.reversed()]
        #expect(set.count == 1)
        #expect(set.contains(c1))
        #expect(set.contains(c2.reversed()))
        // The circuits keep the two directions apart.
        #expect(Set([c0, c1, c2, c0.reversed()].map { Circuit($0) }).count == 2)
    }

    @Test("WK-714 paths with the same vertices and different edges are unequal")
    func pathsDifferByEdges() throws {
        let a = try #require(Path(vertices: [0, 1, 2], edges: [0, 1]))
        let b = try #require(Path(vertices: [0, 1, 2], edges: [0, 2]))
        #expect(a != b)
        #expect(Set([a, b]).count == 2)
        #expect(Trail(a) != Trail(b))
        #expect(Walk(a) != Walk(b))
    }

    @Test("WK-715 trivial walks are equal when their vertex is")
    func trivialEquality() {
        #expect(Walk<Int, Int>(vertex: 1) == Walk<Int, Int>(vertex: 1))
        #expect(Walk<Int, Int>(vertex: 1) != Walk<Int, Int>(vertex: 2))
        #expect(Walk<Int, Int>(vertex: 1).hashValue == Walk<Int, Int>(vertex: 1).hashValue)
        #expect(Path<Int, Int>(vertex: 1) == Path<Int, Int>(vertex: 1))
    }

    @Test("WK-716 rotations of one cycle are one Dictionary key")
    func dictionaryKeys() throws {
        var counts: [Cycle<Int, Int>: Int] = [:]
        counts[try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12])), default: 0] += 1
        counts[try #require(Cycle(vertices: [1, 2, 0], edges: [11, 12, 10])), default: 0] += 1
        counts[try #require(Cycle(vertices: [2, 0, 1], edges: [12, 10, 11])), default: 0] += 1
        #expect(counts.count == 1)
        #expect(counts.values.first == 3)
    }
}
