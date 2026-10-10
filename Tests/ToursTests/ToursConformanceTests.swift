// Conventions the catalog rows do not isolate: generic code over `some Graph` and `some
// DirectedGraph`; string and hash-colliding vertices; other weight types (Int8, UInt8, UInt, Int32,
// Float); the results as `Walks` values (equal on equal inputs, the trail of an Eulerian graph the
// circuit as a closed trail, `Sendable`); an undirected graph against its `directed` view; every
// edgeless graph; `twoOptTour(improving:)` reading only the tour's vertices; tours below three
// vertices nil before any other check; `weight` never asked for a self-loop and asked once per edge
// by every tour. Expected values are catalog rows or worked out in each test's comments. See
// README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("Tours results and conventions", .tags(.conformance))
struct ToursConformanceTests {
    @Test("Generic code over some Graph and some DirectedGraph sees the same answers as the concrete types")
    func genericCode() throws {
        func undirectedFacts(_ graph: some Graph<Int>) -> (Bool, Bool, [Int]?, [Int]?, [Int]?, [Int]?) {
            (graph.isEulerian, graph.hasEulerianTrail, graph.eulerianCircuit()?.vertices, graph.eulerianTrail()?.vertices,
             graph.hamiltonianPath()?.vertices, graph.hamiltonianCycle()?.vertices)
        }
        func directedFacts(_ graph: some DirectedGraph<Int>) -> (Bool, Bool, [Int]?, [Int]?, [Int]?, [Int]?) {
            (graph.isEulerian, graph.hasEulerianTrail, graph.eulerianCircuit()?.vertices, graph.eulerianTrail()?.vertices,
             graph.hamiltonianPath()?.vertices, graph.hamiltonianCycle()?.vertices)
        }
        func shortest<G: Graph<Int>>(_ graph: G, _ weight: (G.Edges.Index) -> Int) -> [Int]? {
            graph.shortestTour(weight: weight)?.vertices
        }
        // The bowtie (TO-069 – TO-072, TO-326, TO-327): Eulerian, circuit [0, 1, 2, 3, 4, 2]; a
        // Hamiltonian path [0, 1, 2, 3, 4], no cycle.
        let bowtie = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 2),
        ])
        let facts = undirectedFacts(bowtie)
        #expect(facts.0 && facts.1)
        #expect(facts.2 == [0, 1, 2, 3, 4, 2] && facts.3 == [0, 1, 2, 3, 4, 2, 0])
        #expect(facts.4 == [0, 1, 2, 3, 4] && facts.5 == nil)
        #expect(facts.2 == bowtie.eulerianCircuit()?.vertices && facts.4 == bowtie.hamiltonianPath()?.vertices)
        // Two directed cycles at a shared vertex (TO-217 – TO-220): circuit [0, 1, 2, 0, 3, 4].
        let twoCycles = AdjacencyList<Int>(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0),
        ])
        let directed = directedFacts(twoCycles)
        #expect(directed.0 && directed.1)
        #expect(directed.2 == [0, 1, 2, 0, 3, 4] && directed.3 == [0, 1, 2, 0, 3, 4, 0])
        // A Hamiltonian path from 1 (none from 0: either cycle strands the other), no cycle.
        #expect(directed.4 == [1, 2, 0, 3, 4] && directed.5 == nil)
        // The square (TO-469): the perimeter.
        let square = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
        ])
        let squareWeights = [1, 2, 1, 1, 2, 1]
        #expect(shortest(square, { squareWeights[$0] }) == [0, 1, 2, 3])
    }

    @Test("String and hash-colliding vertices: the same walks and tours, by vertex order, as on their indices")
    func vertexTypes() throws {
        // TO-104, Königsberg less one bridge: trail [C, A, B, D, A, C, D]; edges [1, 0, 4, 3, 2, 5].
        let names = ["A", "B", "C", "D"]
        let bridges = [(0, 1), (0, 2), (0, 2), (0, 3), (1, 3), (2, 3)]
        let konigsberg = Pseudograph<String>(vertices: names, edges: bridges.map { UndirectedEdge(names[$0.0], names[$0.1]) })
        let trail = try #require(konigsberg.eulerianTrail())
        #expect(trail.vertices == ["C", "A", "B", "D", "A", "C", "D"])
        #expect(trail.edges == [1, 0, 4, 3, 2, 5])
        // The same graph on colliding vertices (every hash equal), listed in the same order.
        let colliders = (0 ..< 4).map { Collider($0, hash: 7) }
        let colliding = Pseudograph<Collider>(vertices: colliders, edges: bridges.map { UndirectedEdge(colliders[$0.0], colliders[$0.1]) })
        let collidingTrail = try #require(colliding.eulerianTrail())
        #expect(collidingTrail.vertices.map(\.value) == [2, 0, 1, 3, 0, 2, 3])
        #expect(collidingTrail.edges == [1, 0, 4, 3, 2, 5])
        // TO-328 / TO-329 on colliders: path [d, b, c, a], cycle [d, b, c, a] (d, a, c, b = 0, 1, 2, 3).
        let order = [Collider(3, hash: 1), Collider(0, hash: 1), Collider(2, hash: 1), Collider(1, hash: 1)]
        let byIndex = [(1, 2), (2, 3), (3, 0), (0, 1), (1, 3)]
        let labelled = UndirectedAdjacencyList<Collider>(vertices: order, edges: byIndex.map { UndirectedEdge(order[$0.0], order[$0.1]) })
        let path = try #require(labelled.hamiltonianPath())
        #expect(path.vertices == [order[0], order[3], order[2], order[1]])
        #expect(path.edges == [2, 1, 0])
        let cycle = try #require(labelled.hamiltonianCycle())
        #expect(cycle.vertices == [order[0], order[3], order[2], order[1]])
        #expect(cycle.edges == [2, 1, 0, 3])
        // TO-414 on strings: nearest neighbour [d, a, c, b], weight 6.
        let letters = ["d", "a", "c", "b"]
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights = [1, 4, 2, 2, 5, 1]
        let complete = UndirectedAdjacencyList<String>(vertices: letters, edges: pairs.map { UndirectedEdge(letters[$0.0], letters[$0.1]) })
        let tour = try #require(complete.nearestNeighborTour(weight: { weights[$0] }))
        #expect(tour.vertices == ["d", "a", "c", "b"])
        #expect(tour.weight({ weights[$0] }) == 6)
    }

    @Test("Other weight types: Int8, UInt8 and UInt (2-opt compares sums, never subtracts), Int32 and Float give the Int row's tours")
    func weightTypes() throws {
        // TO-405, TO-448, TO-474: lcgpts(6,1,10), Manhattan distances; nearest neighbour
        // [0, 2, 5, 3, 1, 4] (34), 2-opt and Held–Karp [0, 2, 4, 1, 3, 5] (30), Christofides
        // [0, 1, 4, 2, 5, 3] (32).
        let pairs = (0 ..< 6).flatMap { i in (i + 1 ..< 6).map { (i, $0) } }
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let points = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2)]
        let manhattan = pairs.map { abs(points[$0.0].0 - points[$0.1].0) + abs(points[$0.0].1 - points[$0.1].1) }
        let check = graph.nearestNeighborTour(weight: { manhattan[$0] })?.weight({ manhattan[$0] })
        try #require(check == 34, "the points are lcgpts(6,1,10)'s")
        let small = manhattan.map { UInt8($0) }
        let signed = manhattan.map { Int8($0) }
        let wide = manhattan.map { UInt($0) }
        let int32 = manhattan.map { Int32($0) }
        let float = manhattan.map { Float($0) }
        #expect(graph.nearestNeighborTour(weight: { small[$0] })?.vertices == [0, 2, 5, 3, 1, 4])
        #expect(graph.twoOptTour(weight: { small[$0] })?.vertices == [0, 2, 4, 1, 3, 5])
        #expect(graph.twoOptTour(weight: { wide[$0] })?.vertices == [0, 2, 4, 1, 3, 5])
        #expect(graph.shortestTour(weight: { wide[$0] })?.vertices == [0, 2, 4, 1, 3, 5])
        #expect(graph.shortestTour(weight: { signed[$0] })?.vertices == [0, 2, 4, 1, 3, 5])
        #expect(graph.twoOptTour(weight: { float[$0] })?.vertices == [0, 2, 4, 1, 3, 5])
        #expect(graph.shortestTour(weight: { float[$0] })?.weight({ float[$0] }) == 30)
        #expect(graph.christofidesTour(weight: { int32[$0] })?.vertices == [0, 1, 4, 2, 5, 3])
        #expect(graph.christofidesTour(weight: { float[$0] })?.vertices == [0, 1, 4, 2, 5, 3])
        #expect(graph.christofidesTour(weight: { manhattan[$0] })?.weight({ manhattan[$0] }) == 32)
    }

    @Test("Results are Walks values: equal on equal inputs; an Eulerian graph's trail is its circuit as a closed trail; Sendable")
    func walksValues() throws {
        // K(5) (TO-095, TO-096).
        let pairs = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let circuit = try #require(graph.eulerianCircuit())
        let trail = try #require(graph.eulerianTrail())
        #expect(graph.eulerianCircuit() == circuit)
        #expect(graph.eulerianCircuit(from: 0) == circuit)
        #expect(Trail(circuit) == trail)
        #expect(trail.isClosed)
        #expect(graph.eulerianTrail(from: 0) == trail)
        let path = try #require(graph.hamiltonianPath())
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(graph.hamiltonianPath(from: 0) == path)
        #expect(graph.hamiltonianPath() == path && graph.hamiltonianCycle() == cycle)
        // The cycle closes the path through its closing edge, (0, 4) at position 3.
        #expect(cycle.vertices == path.vertices && cycle.edges == path.edges + [3])
        let tour = try #require(graph.shortestTour(weight: { _ in 1 }))
        #expect(graph.shortestTour(weight: { _ in 1 }) == tour)
        #expect(tour == cycle)
        let values: [any Sendable] = [circuit, trail, path, cycle, tour]
        #expect(values.count == 5)
    }

    @Test("An undirected graph against its directed view: each edge two opposite arcs, so the view is Eulerian when the edges are connected, and one edge is a two-vertex cycle")
    func directedView() throws {
        // P(4): not Eulerian (two odd ends); its view is balanced and connected.
        let path = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(!path.isEulerian && path.hasEulerianTrail)
        let view = path.directed
        #expect(view.isEulerian)
        let circuit = try #require(view.eulerianCircuit())
        // Every arc once: 0→1, 1→2, 2→3, 3→2, 2→1, 1→0, the view's out-arcs in the base's row order.
        #expect(circuit.vertices == [0, 1, 2, 3, 2, 1])
        #expect(circuit.edges.count == 6 && Set(circuit.edges).count == 6)
        // One edge has no Hamiltonian cycle; its two opposite arcs are one of length 2.
        let edge = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(edge.hamiltonianCycle() == nil)
        let twoArcs = try #require(edge.directed.hamiltonianCycle())
        #expect(twoArcs.vertices == [0, 1])
        #expect(twoArcs.edges.map(\.reversed) == [false, true])
    }

    @Test("Every edgeless graph, 0 to 5 vertices, directed or not: Eulerian with a trail; no circuit; the trivial trail at the first vertex; a Hamiltonian path only with one vertex")
    func edgelessGraphs() throws {
        for n in 0 ... 5 {
            let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: [])
            let directed = AdjacencyList<Int>(vertices: 0 ..< n, edges: [])
            #expect(undirected.isEulerian && undirected.hasEulerianTrail, "\(n)")
            #expect(directed.isEulerian && directed.hasEulerianTrail, "\(n)")
            #expect(undirected.eulerianCircuit() == nil && directed.eulerianCircuit() == nil, "\(n)")
            #expect(undirected.eulerianTrail() == (n == 0 ? nil : Trail<Int, Int>(vertex: 0)), "\(n)")
            #expect(directed.eulerianTrail() == (n == 0 ? nil : Trail<Int, Int>(vertex: 0)), "\(n)")
            #expect(undirected.hamiltonianPath() == (n == 1 ? Path<Int, Int>(vertex: 0) : nil), "\(n)")
            #expect(directed.hamiltonianPath() == (n == 1 ? Path<Int, Int>(vertex: 0) : nil), "\(n)")
            #expect(undirected.hamiltonianCycle() == nil && directed.hamiltonianCycle() == nil, "\(n)")
            for v in 0 ..< n {
                #expect(undirected.eulerianCircuit(from: v) == nil, "\(n) from \(v)")
                #expect(undirected.eulerianTrail(from: v) == Trail<Int, Int>(vertex: v), "\(n) from \(v)")
                #expect(directed.eulerianTrail(from: v) == Trail<Int, Int>(vertex: v), "\(n) from \(v)")
            }
        }
    }

    @Test("twoOptTour(improving:) reads only the tour's vertices: a cycle with other edges gives the same tour")
    func improvingReadsVertices() throws {
        // TO-464: the crossed square [0, 2, 1, 3] improves to the perimeter [0, 1, 2, 3].
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
        ])
        let weights = [1, 2, 1, 1, 2, 1]
        let ofTheGraph = try #require(Cycle([0, 2, 1, 3], in: graph))
        let otherEdges = try #require(Cycle(vertices: [0, 2, 1, 3], edges: [40, 41, 42, 43]))
        let improved = try #require(graph.twoOptTour(improving: ofTheGraph, weight: { weights[$0] }))
        #expect(improved.vertices == [0, 1, 2, 3] && improved.edges == [0, 3, 5, 2])
        #expect(graph.twoOptTour(improving: otherEdges, weight: { weights[$0] }) == improved)
    }

    @Test("Below three vertices every tour is nil before any other check: no pair, a missing pair, a NaN weight, a start that is not a vertex")
    func smallTours() {
        let isolated = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [])
        #expect(isolated.nearestNeighborTour(weight: { _ in 1 }) == nil)
        #expect(isolated.christofidesTour(weight: { _ in 1 }) == nil)
        #expect(isolated.twoOptTour(weight: { _ in 1 }) == nil)
        #expect(isolated.shortestTour(weight: { _ in 1 }) == nil)
        let edge = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(edge.nearestNeighborTour(weight: { _ in Double.nan }) == nil)
        #expect(edge.christofidesTour(weight: { _ in Double.nan }) == nil)
        #expect(edge.shortestTour(weight: { _ in Double.nan }) == nil)
        #expect(edge.nearestNeighborTour(from: 7, weight: { _ in 1 }) == nil)
        let one = UndirectedAdjacencyList<Int>(vertices: [0], edges: [])
        #expect(one.nearestNeighborTour(from: 0, weight: { _ in 1 }) == nil)
    }

    @Test("Every tour asks `weight` once per non-loop edge in position order, a parallel copy included, never a self-loop")
    func weightAskedOnce() throws {
        // TO-413's graph with a second copy of {1, 2}: loops at 0 and 1 (positions 0 and 3).
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [
            UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 1), UndirectedEdge(2, 0), UndirectedEdge(2, 1),
        ])
        let weights = [-9, 1, 2, -9, 3, 7]
        var asked: [[Int]] = []
        for which in 0 ..< 6 {
            var calls: [Int] = []
            let record: (Int) -> Int = { position in
                calls.append(position)
                return weights[position]
            }
            let tour: Cycle<Int, Int>?
            switch which {
            case 0: tour = graph.nearestNeighborTour(weight: record)
            case 1: tour = graph.nearestNeighborTour(from: 2, weight: record)
            case 2: tour = graph.christofidesTour(weight: record)
            case 3: tour = graph.twoOptTour(weight: record)
            case 4: tour = graph.twoOptTour(improving: Cycle([0, 2, 1], in: graph)!, weight: record)
            default: tour = graph.shortestTour(weight: record)
            }
            asked.append(calls)
            // The lightest copies: {0, 1} at 1, {1, 2} at 2, {0, 2} at 4; weight 6 either way round.
            #expect(tour?.weight({ weights[$0] }) == 6, "\(which)")
            #expect(Set(tour?.edges ?? []) == [1, 2, 4], "\(which)")
        }
        #expect(asked == Array(repeating: [1, 2, 4, 5], count: 6))
    }
}
