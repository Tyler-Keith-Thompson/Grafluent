// §5: parallel edges and self-loops. A walk in a multigraph is not determined by its vertices, so
// the positions are part of its value. The vertices-only initializers take the first edge in out-
// or incident order (Walk, Path) or the first unused one (Trail, Circuit, Cycle). Fixtures:
// M = 0→1, 0→1, 1→0; DL = two loops at 0; UL = two undirected loops at 0. Expected values come
// from the catalog's reference (ref.py, brute force and NetworkX 3.7). Case IDs (WK-nnn) refer to
// the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walks in multigraphs: parallel edges and self-loops")
struct WalkMultigraphTests {
    @Test("WK-501 Walk(_:in:) takes the first parallel edge in out-edge order")
    func firstParallel() {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk([0, 1], in: m)?.edges == [0])
        #expect(Path([0, 1], in: m)?.edges == [0])
    }

    @Test("WK-502 the second parallel edge gives a different walk over the same vertices")
    func secondParallel() throws {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let second = try  #require(Walk(vertices: [0, 1], edges: [1], in: m))
        let first = try #require(Walk([0, 1], in: m))
        #expect(Array(second) == Array(first))
        #expect(second != first)
    }

    @Test("WK-503 Walk(_:in:) reuses the first copy")
    func walkReusesCopy() {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk([0, 1, 0, 1], in: m)?.edges == [0, 2, 0])
    }

    @Test("WK-504 Trail(_:in:) takes the first unused copy")
    func trailTakesUnused() {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Trail([0, 1, 0, 1], in: m)?.edges == [0, 2, 1])
    }

    @Test("WK-505 Trail(_:in:) is nil when the copies run out")
    func copiesRunOut() {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Trail([0, 1, 0, 1, 0, 1], in: m) == nil)
        #expect(Walk([0, 1, 0, 1, 0, 1], in: m)?.edges == [0, 2, 0, 2, 0])
    }

    @Test("WK-506 a 2-cycle through one parallel copy and the back edge is valid")
    func parallelDigon() throws {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let c = try #require(Cycle(vertices: [0, 1], edges: [0, 2], in: m))
        #expect(c.length == 2)
        #expect(Cycle(vertices: [0, 1], edges: [2, 0], in: m) == nil)
    }

    @Test("WK-507 cycles over the same vertices through different parallel copies are different")
    func parallelCyclesDiffer() throws {
        let a = try #require(Cycle(vertices: [0, 1], edges: [0, 2]))
        let b = try #require(Cycle(vertices: [0, 1], edges: [1, 2]))
        #expect(a != b)
    }

    @Test("WK-508 a trail around two loops takes each once, directed and undirected", .tags(.selfLoops))
    func twoLoopsTrail() {
        let dl = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        let ul = ReferencePseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        #expect(Trail([0, 0, 0], in: dl)?.edges == [0, 1])
        #expect(Trail([0, 0, 0], in: ul)?.edges == [0, 1])
        #expect(Trail([0, 0, 0, 0], in: dl) == nil)
        #expect(Trail([0, 0, 0, 0], in: ul) == nil)
    }

    @Test("WK-509 two loops at one vertex are a circuit, not a cycle", .tags(.selfLoops))
    func twoLoopsCircuit() {
        let dl = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(Circuit([0, 0], in: dl)?.edges == [0, 1])
        #expect(Cycle([0, 0], in: dl) == nil)
        #expect(Cycle([0], in: dl)?.edges == [0])
    }

    @Test("WK-510 Trail(_:in:) succeeds exactly when some choice of parallel edges is a trail", .tags(.randomized), arguments: 0 ..< 4)
    func greedyTrailIsExact(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(510_000 + seed))
        for _ in 0 ..< 100 {
            let n = Int.random(in: 1 ... 3, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 6, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let undirected = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            // Every vertex sequence of 1 to 5 vertices.
            var sequences: [[Int]] = (0 ..< n).map { [$0] }
            var frontier = sequences
            for _ in 0 ..< 4 {
                frontier = frontier.flatMap { s in (0 ..< n).map { s + [$0] } }
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
                    let exists = choices.contains { Set($0).count == $0.count }
                    let trail = isDirected ? Trail(vs, in: directed) : Trail(vs, in: undirected)
                    #expect((trail != nil) == exists, "\(vs) in \(raw), directed: \(isDirected)")
                    if let trail {
                        #expect(trail.vertices == vs)
                        let valid = isDirected
                            ? Trail(vertices: vs, edges: trail.edges, in: directed) != nil
                            : Trail(vertices: vs, edges: trail.edges, in: undirected) != nil
                        #expect(valid, "\(vs) \(trail.edges) in \(raw)")
                    }
                }
            }
        }
    }

    @Test("WK-511 Trail(Walk(vs, in: g)) can fail where Trail(vs, in: g) succeeds")
    func convertingLosesTheChoice() throws {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let walk = try #require(Walk([0, 1, 0, 1], in: m))
        #expect(Trail(walk) == nil)
        #expect(Trail([0, 1, 0, 1], in: m) != nil)
    }

    @Test("WK-512 M has two distinct 2-cycles through 0 and 1, where NetworkX's simple_cycles lists one")
    func twoDigons() throws {
        let m = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        var found: Set<Cycle<Int, Int>> = []
        for first in m.outEdges(of: 0) where m.target(ofEdgeAt: first) == 1 {
            for second in m.outEdges(of: 1) where m.target(ofEdgeAt: second) == 0 {
                found.insert(try #require(Cycle(vertices: [0, 1], edges: [first, second], in: m)))
            }
        }
        #expect(found.count == 2)
        #expect(found == [try #require(Cycle(vertices: [0, 1], edges: [0, 2])), try #require(Cycle(vertices: [0, 1], edges: [1, 2]))])
    }

    @Test("WK-513 an undirected loop is a 1-cycle and a parallel pair a 2-cycle (NetworkX lists [1] and [1, 2])", .tags(.selfLoops))
    func undirectedLoopAndDigon() {
        let g = ReferencePseudograph(edges: [(1, 1), (1, 2), (1, 2)].map { UndirectedEdge($0.0, $0.1) })
        #expect(Cycle([1], in: g)?.edges == [0])
        #expect(Cycle([1, 2], in: g)?.edges == [1, 2])
    }

    @Test("WK-514 the two loops of DL are two different 1-cycles", .tags(.selfLoops))
    func twoOneCycles() throws {
        let dl = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        let a = try #require(Cycle(vertices: [0], edges: [0], in: dl))
        let b = try #require(Cycle(vertices: [0], edges: [1], in: dl))
        #expect(a != b)
    }

    @Test("WK-515 a loop's two incident entries do not make two picks", .tags(.selfLoops))
    func loopEntries() {
        let ul = ReferencePseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        #expect(Walk([0, 0], in: ul)?.edges == [0])
        #expect(Walk([0, 0, 0], in: ul)?.edges == [0, 0])
        #expect(Path([0, 0], in: ul) == nil)
    }
}
