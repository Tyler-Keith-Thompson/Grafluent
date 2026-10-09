// §2: the intrinsic invariant of each type. A trail repeats no edge position, a path repeats no
// vertex, a circuit is a closed trail of positive length and a cycle a circuit that repeats no
// vertex. The randomized cases enumerate every walk of small seeded multigraphs and check them by
// brute force written in each test. Case IDs (WK-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk invariants per type")
struct WalkInvariantTests {
    @Test("WK-201 a trail may repeat vertices: only its positions must be distinct")
    func trailRepeatsVertices() throws {
        let trail = try #require(Trail(vertices: [0, 1, 2, 3, 2, 3, 4], edges: [0, 1, 2, 3, 4, 5]))
        #expect(trail.length == 6)
        #expect(Path(vertices: [0, 1, 2, 3, 2, 3, 4], edges: [0, 1, 2, 3, 4, 5]) == nil)
        #expect(Trail(vertices: [0, 1, 2], edges: [4, 4]) == nil)
    }

    @Test("WK-202 JGraphT's non-simple path on K5 is a walk but neither a trail nor a path")
    func jgraphtNonSimplePath() {
        var pairs: [UndirectedEdge<Int>] = []
        for a in 0 ..< 5 { for b in a + 1 ..< 5 { pairs.append(UndirectedEdge(a, b)) } }
        let k5 = ReferencePseudograph(edges: pairs)
        let vs = [0, 1, 2, 3, 2, 3, 4]
        #expect(Walk(vs, in: k5) != nil)
        #expect(Trail(vs, in: k5) == nil)
        #expect(Path(vs, in: k5) == nil)
    }

    @Test("WK-203 that walk crosses edge {2, 3} three times")
    func k5EdgeRepeats() {
        var pairs: [UndirectedEdge<Int>] = []
        for a in 0 ..< 5 { for b in a + 1 ..< 5 { pairs.append(UndirectedEdge(a, b)) } }
        let k5 = ReferencePseudograph(edges: pairs)
        let walk = Walk([0, 1, 2, 3, 2, 3, 4], in: k5)
        #expect(walk?.edges == [0, 4, 7, 7, 7, 9])
        #expect(walk.flatMap { Trail($0) } == nil)
    }

    @Test("WK-204 a bowtie trail revisits 0, so it is not a path")
    func bowtie() {
        #expect(Trail(vertices: [0, 1, 2, 0, 3], edges: [0, 1, 2, 3]) != nil)
        #expect(Path(vertices: [0, 1, 2, 0, 3], edges: [0, 1, 2, 3]) == nil)
    }

    @Test("WK-205 one vertex and one edge is a 1-cycle (a self-loop)", .tags(.selfLoops))
    func oneCycle() throws {
        let cycle = try #require(Cycle(vertices: [0], edges: [5]))
        let circuit = try #require(Circuit(vertices: [0], edges: [5]))
        #expect(cycle.length == 1 && cycle.count == 1)
        #expect(circuit.length == 1)
    }

    @Test("WK-206 a digon needs two distinct edges")
    func digon() {
        #expect(Cycle(vertices: [0, 1], edges: [0, 1]) != nil)
        #expect(Cycle(vertices: [0, 1], edges: [0, 0]) == nil)
        #expect(Circuit(vertices: [0, 1], edges: [0, 0]) == nil)
    }

    @Test("WK-207 an empty circuit or cycle is the wrong shape and traps", .tags(.precondition))
    func emptyCircuitTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Circuit<Int, Int>(vertices: [], edges: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Cycle<Int, Int>(vertices: [], edges: [])
        }
    }

    @Test("WK-208 a figure eight is a circuit, not a cycle")
    func figureEight() {
        #expect(Circuit(vertices: [0, 1, 2, 0, 3, 4], edges: [0, 1, 2, 3, 4, 5]) != nil)
        #expect(Cycle(vertices: [0, 1, 2, 0, 3, 4], edges: [0, 1, 2, 3, 4, 5]) == nil)
    }

    @Test("WK-209 every path of a random multigraph has distinct edges, so Trail(path) never fails", .tags(.randomized), arguments: 0 ..< 4)
    func pathsHaveDistinctEdges(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(209_000 + seed))
        for _ in 0 ..< 60 {
            let n = Int.random(in: 1 ... 4, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 7, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let undirected = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            // Every sequence of distinct vertices up to length 3, and every choice of joining edges.
            var sequences: [[Int]] = (0 ..< n).map { [$0] }
            var frontier = sequences
            for _ in 0 ..< 3 {
                frontier = frontier.flatMap { s in (0 ..< n).filter { !s.contains($0) }.map { s + [$0] } }
                sequences += frontier
            }
            for vs in sequences {
                for isDirected in [true, false] {
                    var choices: [[Int]] = [[]]
                    for i in 0 ..< vs.count - 1 {
                        let (a, b) = (vs[i], vs[i + 1])
                        let joining = raw.indices.filter { k in
                            isDirected ? raw[k] == (a, b) : (raw[k] == (a, b) || raw[k] == (b, a))
                        }
                        choices = choices.flatMap { c in joining.map { c + [$0] } }
                    }
                    for es in choices {
                        let path = isDirected ? Path(vertices: vs, edges: es, in: directed) : Path(vertices: vs, edges: es, in: undirected)
                        guard let path else {
                            Issue.record("not a path: \(vs) \(es) in \(raw), directed: \(isDirected)")
                            continue
                        }
                        #expect(Set(path.edges).count == path.edges.count, "\(vs) \(es) in \(raw)")
                        let trail = Trail(path)
                        #expect(trail.vertices == vs && trail.edges == es)
                    }
                }
            }
        }
    }

    @Test("WK-210 a closed walk with distinct vertices repeats an edge only as an undirected 2-cycle, and Cycle rejects it", .tags(.randomized), arguments: 0 ..< 4)
    func cycleChecksEdgesToo(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(210_000 + seed))
        var repeatsFound = 0
        for _ in 0 ..< 60 {
            let n = Int.random(in: 1 ... 4, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 7, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let undirected = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var sequences: [[Int]] = (0 ..< n).map { [$0] }
            var frontier = sequences
            for _ in 0 ..< 3 {
                frontier = frontier.flatMap { s in (0 ..< n).filter { !s.contains($0) }.map { s + [$0] } }
                sequences += frontier
            }
            for vs in sequences {
                for isDirected in [true, false] {
                    var choices: [[Int]] = [[]]
                    for i in 0 ..< vs.count {
                        let (a, b) = (vs[i], vs[(i + 1) % vs.count])
                        let joining = raw.indices.filter { k in
                            isDirected ? raw[k] == (a, b) : (raw[k] == (a, b) || raw[k] == (b, a))
                        }
                        choices = choices.flatMap { c in joining.map { c + [$0] } }
                    }
                    for es in choices {
                        let distinct = Set(es).count == es.count
                        if !distinct {
                            #expect(vs.count == 2 && !isDirected, "\(vs) \(es) in \(raw)")
                            repeatsFound += 1
                        }
                        let cycle = isDirected ? Cycle(vertices: vs, edges: es, in: directed) : Cycle(vertices: vs, edges: es, in: undirected)
                        #expect((cycle != nil) == distinct, "\(vs) \(es) in \(raw), directed: \(isDirected)")
                        #expect((Cycle(vertices: vs, edges: es) != nil) == distinct)
                    }
                }
            }
        }
        #expect(repeatsFound > 0)
    }

    @Test("WK-211 a path may not come back to a vertex")
    func pathNoReturn() {
        #expect(Path(vertices: [0, 1, 0], edges: [0, 1]) == nil)
        #expect(Trail(vertices: [0, 1, 0], edges: [0, 1]) != nil)
    }

    @Test("WK-212 the trivial path and trivial trail exist")
    func trivialPathAndTrail() {
        let path = Path<Int, Int>(vertex: 3)
        #expect(path.isTrivial)
        #expect(path.vertices == [3] && path.edges == [])
        #expect(path.source == 3 && path.target == 3)
        let trail = Trail<Int, Int>(vertex: 3)
        #expect(trail.isTrivial)
        #expect(trail.isClosed)
        #expect(trail.vertices == [3] && trail.edges == [])
    }

    @Test("WK-213 the trivial walk is closed (West) but no circuit or cycle (Bondy & Murty)")
    func trivialIsNoCycle() {
        #expect(Walk<Int, Int>(vertex: 0).isClosed)
        #expect(Cycle(Walk<Int, Int>(vertex: 0)) == nil)
        #expect(Circuit(Walk<Int, Int>(vertex: 0)) == nil)
        #expect(Cycle(Trail<Int, Int>(vertex: 0)) == nil)
        #expect(Circuit(Trail<Int, Int>(vertex: 0)) == nil)
    }

    @Test("WK-214 Cycle(_:in:) takes the cyclic list without a repeated start")
    func cycleFromVertices() {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let cycle = Cycle([0, 1, 2], in: u)
        #expect(cycle?.edges == [0, 1, 2])
        #expect(cycle?.vertices == [0, 1, 2])
    }

    @Test("WK-215 a single undirected edge is not a 2-cycle")
    func simpleEdgeIsNoDigon() {
        let g = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        #expect(Cycle([0, 1], in: g) == nil)
        #expect(Circuit([0, 1], in: g) == nil)
        #expect(Cycle(vertices: [0, 1], edges: [0, 0], in: g) == nil)
    }
}
