// §1: construction and validation. The intrinsic initializer, the checked initializer against a
// `DirectedGraph` and a `Graph`, the vertices-only initializer that picks edges, and the trivial
// walk. Fixtures are written inline on the ReferenceDirectedMultigraph and ReferencePseudograph,
// whose edge positions are list indices and whose out- and incident orders are position order.
// Expected values come from the catalog's reference (ref.py, NetworkX 3.7). Case IDs (WK-nnn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk construction and validation")
struct WalkConstructionTests {
    @Test("WK-101 a walk along LEMON's a1, a2, a3 is valid in D4")
    func lemonAddBack() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let walk = try  #require(Walk(vertices: [0, 1, 2, 3], edges: [0, 1, 2], in: d4))
        #expect(walk.length == 3)
        #expect(walk.source == 0)
        #expect(walk.target == 3)
        #expect(walk.vertices == [0, 1, 2, 3])
        #expect(walk.edges == [0, 1, 2])
    }

    @Test("WK-102 vertices out of step with their edges are not a walk (JGraphT testInvalidPath4)")
    func verticesOutOfStep() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk(vertices: [0, 1, 3, 2], edges: [0, 1, 2], in: d4) == nil)
        #expect(Trail(vertices: [0, 1, 3, 2], edges: [0, 1, 2], in: d4) == nil)
        #expect(Path(vertices: [0, 1, 3, 2], edges: [0, 1, 2], in: d4) == nil)
    }

    @Test("WK-103 an edge that skips a step is not a walk (JGraphT testInvalidPath5)")
    func skippedStep() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk(vertices: [0, 1, 2], edges: [0, 2], in: d4) == nil)
        #expect(Path(vertices: [0, 1, 2], edges: [0, 2], in: d4) == nil)
    }

    @Test("WK-104 LEMON's inconsistent arcs a4, a2, a1 are no walk for any four vertices")
    func lemonInconsistentPath() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        for a in 0 ..< 4 {
            for b in 0 ..< 4 {
                for c in 0 ..< 4 {
                    for d in 0 ..< 4 {
                        #expect(Walk(vertices: [a, b, c, d], edges: [3, 1, 0], in: d4) == nil, "\([a, b, c, d])")
                    }
                }
            }
        }
    }

    @Test("WK-105 a walk starting at the back of the cycle (LEMON addFront a4) is valid")
    func lemonAddFront() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let walk = try  #require(Walk(vertices: [3, 0, 1, 2], edges: [3, 0, 1], in: d4))
        #expect(walk.source == 3)
        #expect(walk.target == 2)
        #expect(walk.length == 3)
    }

    @Test("WK-106 a trivial walk is valid exactly when its vertex is in the graph")
    func trivialNeedsItsVertex() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let walk = try  #require(Walk(vertices: [2], edges: [], in: d4))
        #expect(walk.isTrivial)
        #expect(walk.source == 2 && walk.target == 2)
        #expect(Walk(vertices: [9], edges: [], in: d4) == nil)
        #expect(Path(vertices: [9], edges: [], in: d4) == nil)
        #expect(Walk([9], in: d4) == nil)
        #expect(Walk([2], in: d4) == Walk<Int, Int>(vertex: 2))
    }

    @Test("WK-107 there is no empty walk: an empty vertex list is nil, with or without edges given")
    func noEmptyWalk() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk([], in: d4) == nil)
        #expect(Walk(vertices: [], edges: [], in: d4) == nil)
        #expect(Trail([], in: d4) == nil)
        #expect(Path([], in: d4) == nil)
        #expect(Circuit([], in: d4) == nil)
        #expect(Cycle([], in: d4) == nil)
        #expect(Circuit(vertices: [], edges: [], in: d4) == nil)
        #expect(Cycle(vertices: [], edges: [], in: d4) == nil)
    }

    @Test("WK-108 with a graph, counts that do not match are nil, not a trap")
    func countMismatchWithGraph() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk(vertices: [0, 1], edges: [0, 1], in: d4) == nil)
        #expect(Walk(vertices: [0, 1, 2], edges: [0], in: d4) == nil)
        #expect(Cycle(vertices: [0, 1, 2, 3], edges: [0, 1, 2], in: d4) == nil)
        #expect(Circuit(vertices: [0, 1], edges: [0, 1, 2], in: d4) == nil)
    }

    @Test("WK-109 Walk(_:in:) picks the edge from each vertex to the next")
    func picksEdges() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let walk = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        #expect(walk.edges == [0, 1, 2, 3, 0])
        #expect(walk.vertices == [0, 1, 2, 3, 0, 1])
    }

    @Test("WK-110 Walk(_:in:) is nil when no edge joins two consecutive vertices")
    func noEdgeBetween() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk([0, 2], in: d4) == nil)
        #expect(Walk([1, 0], in: d4) == nil)
        #expect(Walk([0, 9], in: d4) == nil)
    }

    @Test("WK-111 a repeated vertex needs a loop (JGraphT testInvalidPath3)")
    func repeatNeedsLoop() {
        let g = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        #expect(Walk([0, 0], in: g) == nil)
        #expect(Walk(vertices: [0, 0], edges: [0], in: g) == nil)
    }

    @Test("WK-112 a self-loop walked once is a walk; one vertex too many is nil with a graph and a trap without (JGraphT testInvalidPath1)", .tags(.selfLoops))
    func loopWalkedOnce() async throws {
        let g = ReferencePseudograph(edges: [UndirectedEdge(0, 0)])
        let walk = try  #require(Walk(vertices: [0, 0], edges: [0], in: g))
        #expect(walk.length == 1)
        #expect(walk.edges == [0])
        #expect(walk.isClosed)
        #expect(Walk(vertices: [0, 0], edges: [], in: g) == nil)
        await #expect(processExitsWith: .failure) {
            _ = Walk<Int, Int>(vertices: [0, 0], edges: [])
        }
    }

    @Test("WK-113 Walk(vertex:) is the trivial walk (JGraphT singletonWalk)")
    func trivialWalk() {
        let walk = Walk<Int, Int>(vertex: 7)
        #expect(walk.count == 1)
        #expect(walk.length == 0)
        #expect(walk.isTrivial)
        #expect(walk.isClosed)
        #expect(walk.source == 7)
        #expect(walk.target == 7)
        #expect(walk.edges == [])
        #expect(walk.vertices == [7])
    }

    @Test("WK-114 without a graph only the intrinsic invariant is checked: positions are not looked at")
    func intrinsicOnly() throws {
        let path = try #require(Path(vertices: [0, 1, 2], edges: [5, 6]))
        #expect(path.vertices == [0, 1, 2])
        #expect(path.edges == [5, 6])
        #expect(Walk(vertices: [0, 1, 2], edges: [5, 6]).length == 2)
        #expect(Trail(vertices: [0, 1, 2], edges: [5, 6]) != nil)
    }

    @Test("WK-121 [1, 2, 3, 4] is a walk of NetworkX's test_ispath graph as Graph, DiGraph, MultiGraph and MultiDiGraph")
    func networkXIsPathTrue() {
        // NetworkX's graph is [(1, 2), (2, 3), (1, 2), (3, 4)]; the simple graphs collapse the repeat.
        let multi = [(1, 2), (2, 3), (1, 2), (3, 4)]
        let simple = [(1, 2), (2, 3), (3, 4)]
        let vs = [1, 2, 3, 4]
        #expect(Walk(vs, in: AdjacencyList(edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })) != nil)
        #expect(Walk(vs, in: UndirectedAdjacencyList(edges: simple.map { UndirectedEdge($0.0, $0.1) })) != nil)
        #expect(Walk(vs, in: ReferenceDirectedMultigraph(edges: multi.map { DirectedEdge(from: $0.0, to: $0.1) })) != nil)
        #expect(Walk(vs, in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) })) != nil)
    }

    @Test("WK-122 [1, 2, 4, 3] is no walk of any of the four")
    func networkXIsPathMissingEdge() {
        let multi = [(1, 2), (2, 3), (1, 2), (3, 4)]
        let simple = [(1, 2), (2, 3), (3, 4)]
        let vs = [1, 2, 4, 3]
        #expect(Walk(vs, in: AdjacencyList(edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: UndirectedAdjacencyList(edges: simple.map { UndirectedEdge($0.0, $0.1) })) == nil)
        #expect(Walk(vs, in: ReferenceDirectedMultigraph(edges: multi.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) })) == nil)
    }

    @Test("WK-123 [1, 2, 3, 4, 5] is no walk: 5 is not a vertex")
    func networkXIsPathMissingVertex() {
        let multi = [(1, 2), (2, 3), (1, 2), (3, 4)]
        let simple = [(1, 2), (2, 3), (3, 4)]
        let vs = [1, 2, 3, 4, 5]
        #expect(Walk(vs, in: AdjacencyList(edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: UndirectedAdjacencyList(edges: simple.map { UndirectedEdge($0.0, $0.1) })) == nil)
        #expect(Walk(vs, in: ReferenceDirectedMultigraph(edges: multi.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) })) == nil)
    }

    @Test("WK-124 [3, 2, 1] is a walk of the undirected graphs only")
    func networkXIsPathBackward() {
        let multi = [(1, 2), (2, 3), (1, 2), (3, 4)]
        let simple = [(1, 2), (2, 3), (3, 4)]
        let vs = [3, 2, 1]
        #expect(Walk(vs, in: AdjacencyList(edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: UndirectedAdjacencyList(edges: simple.map { UndirectedEdge($0.0, $0.1) })) != nil)
        #expect(Walk(vs, in: ReferenceDirectedMultigraph(edges: multi.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) }))?.edges == [1, 0])
    }

    @Test("WK-125 [1, 2, 1, 2, 3] repeats vertices and is a walk of the undirected graphs only")
    func networkXIsPathRepeats() {
        let multi = [(1, 2), (2, 3), (1, 2), (3, 4)]
        let simple = [(1, 2), (2, 3), (3, 4)]
        let vs = [1, 2, 1, 2, 3]
        #expect(Walk(vs, in: AdjacencyList(edges: simple.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        #expect(Walk(vs, in: UndirectedAdjacencyList(edges: simple.map { UndirectedEdge($0.0, $0.1) })) != nil)
        #expect(Walk(vs, in: ReferenceDirectedMultigraph(edges: multi.map { DirectedEdge(from: $0.0, to: $0.1) })) == nil)
        // The first edge in incident order every time: position 0 three times, then 1.
        #expect(Walk(vs, in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) }))?.edges == [0, 0, 0, 1])
        // As a trail it needs three copies of 1–2, and there are two.
        #expect(Trail(vs, in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) })) == nil)
        #expect(Trail([1, 2, 1], in: ReferencePseudograph(edges: multi.map { UndirectedEdge($0.0, $0.1) }))?.edges == [0, 2])
    }

    @Test("WK-126 a lone vertex that is not in the graph is nil, where NetworkX's is_path says True")
    func loneMissingVertex() {
        let g = ReferencePseudograph(edges: [UndirectedEdge(1, 2)])
        #expect(Walk([99], in: g) == nil)
        #expect(Walk(vertices: [99], edges: [], in: g) == nil)
        #expect(Walk([1], in: g) == Walk<Int, Int>(vertex: 1))
    }

    @Test("WK-127 an empty vertex list is nil, where NetworkX's is_path says True")
    func emptyList() {
        let g = ReferencePseudograph(edges: [UndirectedEdge(1, 2)])
        #expect(Walk([], in: g) == nil)
        #expect(Walk(vertices: [], edges: [], in: g) == nil)
        #expect(Trail([], in: g) == nil)
        #expect(Path([], in: g) == nil)
        #expect(Circuit([], in: g) == nil)
        #expect(Cycle([], in: g) == nil)
    }

    @Test("WK-128 a walk may cross a self-loop twice", .tags(.selfLoops))
    func loopTwice() {
        let g = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0)])
        #expect(Walk([0, 0, 0], in: g)?.edges == [0, 0])
        #expect(Walk(vertices: [0, 0, 0], edges: [0, 0], in: g) != nil)
    }

    @Test("WK-129 a trail may not cross a self-loop twice", .tags(.selfLoops))
    func trailLoopTwice() {
        let g = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 0)])
        #expect(Trail([0, 0, 0], in: g) == nil)
        #expect(Trail(vertices: [0, 0, 0], edges: [0, 0], in: g) == nil)
        #expect(Trail([0, 0], in: g)?.edges == [0])
    }

    @Test("WK-130 the vertices may be a one-pass sequence: read once, with the same result as an array")
    func onePassSequence() {
        let d = ReferenceDirectedMultigraph(edges: [(1, 2), (2, 3), (3, 1)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let u = ReferencePseudograph(edges: [(1, 2), (2, 3), (3, 1)].map { UndirectedEdge($0.0, $0.1) })
        for count in UnderestimatedCount.all {
            #expect(Walk(MinimalSequence(elements: [1, 2, 3], underestimatedCount: count), in: d) == Walk([1, 2, 3], in: d))
            #expect(Walk(MinimalSequence(elements: [1, 2, 3], underestimatedCount: count), in: d)?.edges == [0, 1])
            #expect(Trail(MinimalSequence(elements: [1, 2, 3, 1], underestimatedCount: count), in: d) == Trail([1, 2, 3, 1], in: d))
            #expect(Path(MinimalSequence(elements: [1, 2, 3], underestimatedCount: count), in: u) == Path([1, 2, 3], in: u))
            #expect(Cycle(MinimalSequence(elements: [1, 2, 3], underestimatedCount: count), in: d) == Cycle([1, 2, 3], in: d))
            #expect(Circuit(MinimalSequence(elements: [3, 2, 1], underestimatedCount: count), in: u)?.edges == [1, 0, 2])
        }
    }
}
