// §8: conversions between the types, as initializers. Upward conversions (Path → Trail → Walk,
// Cycle → Circuit, and a circuit or cycle to a closed Walk or Trail, which repeats the start) never
// fail; downward ones check the target type's invariant and are failable, and Circuit and Cycle
// need a closed walk of positive length and drop its closing vertex. Case IDs (WK-nnn) refer to the
// catalog; see README.md.

import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk conversions")
struct WalkConversionTests {
    @Test("WK-801 a cycle as a Walk repeats its start at the end")
    func cycleToWalk() throws {
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))
        let w = Walk(c)
        #expect(w.vertices == [0, 1, 2, 0])
        #expect(w.edges == [10, 11, 12])
        #expect(w.isClosed)
        let t = Trail(c)
        #expect(t.vertices == [0, 1, 2, 0] && t.edges == [10, 11, 12])
        let circuit = Circuit(c)
        #expect(Walk(circuit) == w)
        #expect(Trail(circuit) == t)
    }

    @Test("WK-802 a closed walk as a Cycle drops its closing vertex")
    func closedWalkToCycle() throws {
        let w = Walk(vertices: [0, 1, 2, 0], edges: [10, 11, 12])
        let c = try #require(Cycle(w))
        #expect(c.vertices == [0, 1, 2])
        #expect(c.edges == [10, 11, 12])
        #expect(Circuit(w)?.vertices == [0, 1, 2])
        let t = try #require(Trail(w))
        #expect(Cycle(t) == c)
        #expect(Circuit(t) == Circuit(c))
    }

    @Test("WK-803 a 1-cycle as a Walk crosses its loop once", .tags(.selfLoops))
    func loopToWalk() throws {
        let c = try #require(Cycle(vertices: [4], edges: [7]))
        let w = Walk(c)
        #expect(w.vertices == [4, 4])
        #expect(w.edges == [7])
        #expect(Cycle(w) == c)
    }

    @Test("WK-804 a closed walk through 0 twice is a circuit but not a cycle")
    func doubleVisit() throws {
        let w = Walk(vertices: [0, 1, 2, 0, 3, 0], edges: [0, 1, 2, 3, 4])
        let circuit = try #require(Circuit(w))
        #expect(circuit.vertices == [0, 1, 2, 0, 3])
        #expect(circuit.edges == [0, 1, 2, 3, 4])
        #expect(Cycle(w) == nil)
    }

    @Test("WK-805 upward conversions keep the vertices and edges")
    func upward() throws {
        let p = try #require(Path(vertices: [0, 1, 2], edges: [5, 6]))
        let t = Trail(p)
        #expect(t.vertices == [0, 1, 2] && t.edges == [5, 6])
        let w = Walk(p)
        #expect(w.vertices == [0, 1, 2] && w.edges == [5, 6])
        let tw = Walk(t)
        #expect(tw == w)
        let c = try #require(Cycle(vertices: [0, 1, 2], edges: [3, 4, 5]))
        let circuit = Circuit(c)
        #expect(circuit.vertices == [0, 1, 2] && circuit.edges == [3, 4, 5])
        // The trivial ones too.
        #expect(Walk(Path<Int, Int>(vertex: 1)) == Walk<Int, Int>(vertex: 1))
        #expect(Trail(Path<Int, Int>(vertex: 1)) == Trail<Int, Int>(vertex: 1))
    }

    @Test("WK-806 downward conversions fail when the invariant does not hold")
    func downwardFails() throws {
        let back = Walk(vertices: [0, 1, 0], edges: [0, 1])
        #expect(Path(back) == nil)
        #expect(Trail(back) != nil)
        #expect(Path(try #require(Trail(back))) == nil)
        let repeated = Walk(vertices: [0, 1, 0, 1], edges: [0, 1, 0])
        #expect(Trail(repeated) == nil)
        #expect(Path(repeated) == nil)
        #expect(Circuit(repeated) == nil)
        let straight = Walk(vertices: [0, 1, 2], edges: [0, 1])
        #expect(Path(straight)?.vertices == [0, 1, 2])
        #expect(Trail(straight)?.edges == [0, 1])
    }

    @Test("WK-807 an open walk is no cycle or circuit")
    func openIsNoCycle() throws {
        let w = Walk(vertices: [0, 1, 2], edges: [0, 1])
        #expect(Cycle(w) == nil)
        #expect(Circuit(w) == nil)
        #expect(Cycle(try #require(Trail(w))) == nil)
    }

    @Test("WK-808 Cycle(circuit) fails for a figure eight and succeeds for a triangle")
    func circuitToCycle() throws {
        let eight = try #require(Circuit(vertices: [0, 1, 2, 0, 3, 4], edges: [0, 1, 2, 3, 4, 5]))
        #expect(Cycle(eight) == nil)
        let triangle = try #require(Circuit(vertices: [0, 1, 2], edges: [0, 1, 2]))
        let cycle = try #require(Cycle(triangle))
        #expect(cycle.vertices == [0, 1, 2] && cycle.edges == [0, 1, 2])
        #expect(Circuit(cycle) == triangle)
    }

    @Test("WK-809 Cycle(Walk(c)) == c for random cycles, and through Trail and Circuit too", .tags(.randomized), arguments: 0 ..< 4)
    func roundTrip(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(809_000 + seed))
        for _ in 0 ..< 200 {
            let n = Int.random(in: 1 ... 8, using: &rng)
            let vs = Array(Array(0 ..< 12).shuffled(using: &rng).prefix(n))
            let es = Array(Array(0 ..< 20).shuffled(using: &rng).prefix(n))
            let c = try #require(Cycle(vertices: vs, edges: es))
            #expect(Cycle(Walk(c)) == c)
            #expect(Cycle(Walk(c))?.vertices == vs)
            #expect(Cycle(Trail(c)) == c)
            #expect(Cycle(Circuit(c)) == c)
            #expect(Circuit(Walk(c)) == Circuit(c))
        }
    }

    @Test("WK-810 Path(Trail(p)) == p and Path(Walk(p)) == p")
    func pathRoundTrip() throws {
        let p = try #require(Path(vertices: [3, 1, 4], edges: [1, 5]))
        #expect(Path(Trail(p)) == p)
        #expect(Path(Walk(p)) == p)
        #expect(Trail(Walk(Trail(p))) == Trail(p))
    }
}
