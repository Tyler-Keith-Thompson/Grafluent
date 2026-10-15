// `simulatedAnnealingTour` and `thresholdAcceptingTour` on `Graph` and `DirectedGraph`: the
// search written out here as NetworkX's `simulated_annealing_tsp` / `threshold_accepting_tsp`
// procedure (each candidate tour weighed in full, moves applied to a copy of the list), driven by
// the same seeded generator, must give the same tour; then the shapes of the result (a Hamiltonian
// cycle through the lightest copies, from the starting tour's first vertex, never longer than the
// starting tour), nil below three vertices, and representations.

import AdjacencyListModule
import AdjacencyMatrixModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing
import Tours
import Walks

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif

@Suite("simulatedAnnealingTour and thresholdAcceptingTour")
struct MetaheuristicTourTests {
    @Test("Undirected, integer weights: the procedure written out, for both moves and both rules", .tags(.randomized))
    func undirectedAgainstProcedure() async {
        await propertyCheck(count: 120, input: Gen.int(in: 3 ... 9), Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 3)) { n, seed, variant in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var ends: [UndirectedEdge<Int>] = []
            var weights: [Int] = []
            for u in 0 ..< n {
                for v in u + 1 ..< n {
                    ends.append(UndirectedEdge(u, v))
                    weights.append(Int.random(in: 1 ... 20, using: &draw))
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: ends)
            var d = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for (k, e) in ends.enumerated() {
                d[e.u][e.v] = weights[k]
                d[e.v][e.u] = weights[k]
            }
            let move: TourMove = variant % 2 == 0 ? .swap : .relocate
            let annealing = variant < 2
            // The starting tour: nearest neighbour from vertex 0, the first on ties.
            var start = [0]
            var left = Array(1 ..< n)
            while !left.isEmpty {
                var best = 0
                for k in 1 ..< left.count where d[start.last!][left[k]] < d[start.last!][left[best]] { best = k }
                start.append(left.remove(at: best))
            }
            // The procedure, every candidate weighed in full.
            func length(_ t: [Int]) -> Int { (0 ..< n).reduce(0) { $0 + d[t[$1]][t[($1 + 1) % n]] } }
            var reference = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed) &+ 1)
            var cycle = start, cost = length(start)
            var best = cycle, bestCost = cost
            var temperature = 100.0, threshold = 1.0
            var count = 0
            while count <= 10 && (!annealing || temperature > 0) {
                count += 1
                var accepted = false
                for _ in 0 ..< 100 {
                    let a = 1 + Int(reference.next(upperBound: UInt64(n - 1)))
                    var b = 1 + Int(reference.next(upperBound: UInt64(n - 2)))
                    if b >= a { b += 1 }
                    var candidate = cycle
                    if move == .swap {
                        candidate.swapAt(a, b)
                    } else {
                        candidate.insert(candidate.remove(at: a), at: b)
                    }
                    let candidateCost = length(candidate)
                    var take = candidateCost <= cost
                    if !take {
                        let delta = Double(candidateCost - cost)
                        take = annealing ? Double.random(in: 0 ..< 1, using: &reference) <= exp(-delta / temperature) : delta <= threshold
                    }
                    if take {
                        accepted = true
                        cycle = candidate
                        cost = candidateCost
                        if cost < bestCost {
                            best = cycle
                            bestCost = cost
                            count = 0
                        }
                    }
                }
                if annealing { temperature -= temperature * 0.01 } else if accepted { threshold -= threshold * 0.1 }
            }
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed) &+ 1)
            let found = annealing
                ? graph.simulatedAnnealingTour(move: move, weight: { weights[$0] }, using: &generator)
                : graph.thresholdAcceptingTour(move: move, weight: { weights[$0] }, using: &generator)
            guard let found else {
                Issue.record("nil on \(n) vertices, seed \(seed)")
                return
            }
            let edgesMatch = (0 ..< n).allSatisfy { i in
                let e = graph.edges[found.edges[i]]
                return Set([e.u, e.v]) == Set([found.vertices[i], found.vertices[(i + 1) % n]])
            }
            let foundCost = found.weight({ weights[$0] })
            let same = found.vertices == best && edgesMatch && foundCost == bestCost && bestCost <= length(start)
            #expect(same, "n \(n), seed \(seed), variant \(variant)")
        }
    }

    @Test("Directed, integer weights: the procedure written out, weighed along the arcs", .tags(.randomized))
    func directedAgainstProcedure() async {
        await propertyCheck(count: 120, input: Gen.int(in: 3 ... 8), Gen.int(in: 0 ... 1_000_000), Gen.int(in: 0 ... 3)) { n, seed, variant in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var arcs: [DirectedEdge<Int>] = []
            var weights: [Int] = []
            var d = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for u in 0 ..< n {
                for v in 0 ..< n where u != v {
                    arcs.append(DirectedEdge(from: u, to: v))
                    let w = Int.random(in: 1 ... 30, using: &draw)
                    weights.append(w)
                    d[u][v] = w
                }
            }
            let graph = AdjacencyList(vertices: 0 ..< n, edges: arcs)
            let move: TourMove = variant % 2 == 0 ? .swap : .relocate
            let annealing = variant < 2
            // The starting tour, given: 0, then the rest descending.
            let start = [0] + (1 ..< n).reversed()
            let startCycle = Cycle(start, in: graph)!
            func length(_ t: [Int]) -> Int { (0 ..< n).reduce(0) { $0 + d[t[$1]][t[($1 + 1) % n]] } }
            var reference = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var cycle = start, cost = length(start)
            var best = cycle, bestCost = cost
            var temperature = 5.0, threshold = 3.0
            var count = 0
            while count <= 3 && (!annealing || temperature > 0) {
                count += 1
                var accepted = false
                for _ in 0 ..< 20 {
                    let a = 1 + Int(reference.next(upperBound: UInt64(n - 1)))
                    var b = 1 + Int(reference.next(upperBound: UInt64(n - 2)))
                    if b >= a { b += 1 }
                    var candidate = cycle
                    if move == .swap {
                        candidate.swapAt(a, b)
                    } else {
                        candidate.insert(candidate.remove(at: a), at: b)
                    }
                    let candidateCost = length(candidate)
                    var take = candidateCost <= cost
                    if !take {
                        let delta = Double(candidateCost - cost)
                        take = annealing ? Double.random(in: 0 ..< 1, using: &reference) <= exp(-delta / temperature) : delta <= threshold
                    }
                    if take {
                        accepted = true
                        cycle = candidate
                        cost = candidateCost
                        if cost < bestCost {
                            best = cycle
                            bestCost = cost
                            count = 0
                        }
                    }
                }
                if annealing { temperature -= temperature * 0.2 } else if accepted { threshold -= threshold * 0.5 }
            }
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let found = annealing
                ? graph.simulatedAnnealingTour(improving: startCycle, move: move, temperature: 5, alpha: 0.2, maximumIterations: 3, innerIterations: 20,
                                               weight: { weights[$0] }, using: &generator)
                : graph.thresholdAcceptingTour(improving: startCycle, move: move, threshold: 3, alpha: 0.5, maximumIterations: 3, innerIterations: 20,
                                               weight: { weights[$0] }, using: &generator)
            guard let found else {
                Issue.record("nil on \(n) vertices, seed \(seed)")
                return
            }
            let arcsMatch = (0 ..< n).allSatisfy { i in
                arcs[found.edges[i]] == DirectedEdge(from: found.vertices[i], to: found.vertices[(i + 1) % n])
            }
            let foundCost = found.weight({ weights[$0] })
            let same = found.vertices == best && arcsMatch && foundCost == bestCost
            #expect(same, "n \(n), seed \(seed), variant \(variant)")
        }
    }

    @Test("Threshold accepting with one move per round: the threshold falls only after a round that took a move", .tags(.randomized))
    func thresholdRounds() async {
        await propertyCheck(count: 150, input: Gen.int(in: 4 ... 8), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var ends: [UndirectedEdge<Int>] = []
            var weights: [Int] = []
            var d = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for u in 0 ..< n {
                for v in u + 1 ..< n {
                    ends.append(UndirectedEdge(u, v))
                    let w = Int.random(in: 1 ... 12, using: &draw)
                    weights.append(w)
                    d[u][v] = w
                    d[v][u] = w
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: ends)
            let start = Array(0 ..< n)
            func length(_ t: [Int]) -> Int { (0 ..< n).reduce(0) { $0 + d[t[$1]][t[($1 + 1) % n]] } }
            var reference = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            var cycle = start, cost = length(start)
            var best = cycle, bestCost = cost
            var threshold = 4.0
            var count = 0
            while count <= 8 {
                count += 1
                let a = 1 + Int(reference.next(upperBound: UInt64(n - 1)))
                var b = 1 + Int(reference.next(upperBound: UInt64(n - 2)))
                if b >= a { b += 1 }
                var candidate = cycle
                candidate.swapAt(a, b)
                let candidateCost = length(candidate)
                if candidateCost <= cost || Double(candidateCost - cost) <= threshold {
                    cycle = candidate
                    cost = candidateCost
                    if cost < bestCost {
                        best = cycle
                        bestCost = cost
                        count = 0
                    }
                    threshold -= threshold * 0.5
                }
            }
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let found = graph.thresholdAcceptingTour(improving: Cycle(start, in: graph)!, threshold: 4, alpha: 0.5, maximumIterations: 8, innerIterations: 1,
                                                     weight: { weights[$0] }, using: &generator)
            let same = found?.vertices == best
            #expect(same, "n \(n), seed \(seed)")
        }
    }

    @Test("A square: the perimeter is found from a crossing tour; the first vertex stays first")
    func square() throws {
        // Points (0,0), (0,1), (1,1), (1,0), Manhattan distance; pairs i < j lexicographic.
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights = [1, 2, 1, 1, 2, 1]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let crossing = try #require(Cycle([2, 0, 1, 3], in: graph))
        #expect(crossing.weight({ weights[$0] }) == 6)
        for move in TourMove.allCases {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 7)
            let annealed = try #require(graph.simulatedAnnealingTour(improving: crossing, move: move, weight: { weights[$0] }, using: &generator))
            #expect(annealed.vertices.first == 2)
            #expect(annealed.weight({ weights[$0] }) == 4)
            #expect(Cycle(vertices: annealed.vertices, edges: annealed.edges, in: graph) != nil)
            let accepted = try #require(graph.thresholdAcceptingTour(improving: crossing, move: move, weight: { weights[$0] }, using: &generator))
            #expect(accepted.vertices.first == 2)
            #expect(accepted.weight({ weights[$0] }) == 4)
        }
    }

    @Test("Floating-point and unsigned weights")
    func weightTypes() throws {
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let doubles = [0.5, 1.0, 0.5, 0.5, 1.0, 0.5]
        let unsigned: [UInt8] = [1, 2, 1, 1, 2, 1]
        var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 3)
        let a = try #require(graph.simulatedAnnealingTour(weight: { doubles[$0] }, using: &generator))
        #expect(a.weight({ doubles[$0] }) == 2)
        let b = try #require(graph.thresholdAcceptingTour(move: .relocate, weight: { unsigned[$0] }, using: &generator))
        #expect(b.weight({ unsigned[$0] }) == 4)
        let c = try #require(graph.simulatedAnnealingTour(move: .relocate, weight: { unsigned[$0] }, using: &generator))
        #expect(c.weight({ unsigned[$0] }) == 4)
        let d = try #require(graph.thresholdAcceptingTour(weight: { doubles[$0] }, using: &generator))
        #expect(d.weight({ doubles[$0] }) == 2)
    }

    @Test("The same seed gives the same tour; zero rounds of zero steps return the starting tour")
    func determinism() throws {
        var ends: [UndirectedEdge<Int>] = []
        var weights: [Int] = []
        var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 11)
        for u in 0 ..< 12 { for v in u + 1 ..< 12 { ends.append(UndirectedEdge(u, v)); weights.append(Int.random(in: 1 ... 99, using: &draw)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: ends)
        var first = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 5)
        var second = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 5)
        let x = graph.simulatedAnnealingTour(weight: { weights[$0] }, using: &first)
        let y = graph.simulatedAnnealingTour(weight: { weights[$0] }, using: &second)
        #expect(x?.vertices == y?.vertices && x?.edges == y?.edges)
        var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 5)
        let start = try #require(graph.nearestNeighborTour { weights[$0] })
        let none = try #require(graph.simulatedAnnealingTour(maximumIterations: 0, innerIterations: 0, weight: { weights[$0] }, using: &generator))
        #expect(none.vertices == start.vertices && none.edges == start.edges)
        let cold = try #require(graph.simulatedAnnealingTour(temperature: 0, weight: { weights[$0] }, using: &generator))
        #expect(cold.vertices == start.vertices)
        let still = try #require(graph.thresholdAcceptingTour(maximumIterations: 0, innerIterations: 0, weight: { weights[$0] }, using: &generator))
        #expect(still.vertices == start.vertices)
    }

    @Test("nil below three vertices; three vertices: the only tour")
    func small() throws {
        var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
        #expect(UndirectedAdjacencyList<Int>().simulatedAnnealingTour(weight: { _ in 1 }, using: &generator) == nil)
        let pair = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(pair.thresholdAcceptingTour(weight: { _ in 1 }, using: &generator) == nil)
        #expect(AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]).simulatedAnnealingTour(weight: { _ in 1 }, using: &generator) == nil)
        let triangle = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let tour = try #require(triangle.simulatedAnnealingTour(move: .relocate, weight: { [1, 2, 3][$0] }, using: &generator))
        #expect(tour.weight({ [1, 2, 3][$0] }) == 6 && tour.vertices.first == 0)
    }

    @Test("Directed: the cheaper orientation of a triangle, on every representation")
    func directedRepresentations() throws {
        // 0→1 (1), 1→2 (1), 2→0 (1), and the reverse arcs at 10.
        let arcs = [(0, 1), (1, 2), (2, 0), (1, 0), (2, 1), (0, 2)]
        let weights = [1, 1, 1, 10, 10, 10]
        let weightOf = { (s: Int, t: Int) in weights[arcs.firstIndex { $0 == (s, t) }!] }
        var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 2)
        let list = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let backward = try #require(Cycle([0, 2, 1], in: list))
        let a = try #require(list.simulatedAnnealingTour(improving: backward, weight: { weights[$0] }, using: &generator))
        #expect(a.vertices == [0, 1, 2] && a.edges == [0, 1, 2])
        let multi = DirectedPseudograph(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) } + [DirectedEdge(from: 1, to: 1)])
        let b = try #require(multi.thresholdAcceptingTour(weight: { $0 < 6 ? weights[$0] : 0 }, using: &generator))
        #expect(b.vertices == [0, 1, 2] && b.edges == [0, 1, 2])
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let c = try #require(matrix.simulatedAnnealingTour(move: .relocate, weight: { weightOf(matrix.edges[$0].source, matrix.edges[$0].target) }, using: &generator))
        #expect(c.vertices == [0, 1, 2])
        #expect(c.edges.map { matrix.edges[$0] } == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let reference = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let d = try #require(reference.thresholdAcceptingTour(move: .relocate, weight: { Double(weights[$0]) }, using: &generator))
        #expect(d.vertices == [0, 1, 2] && d.edges == [0, 1, 2])
        let e = try #require(reference.simulatedAnnealingTour(weight: { Double(weights[$0]) }, using: &generator))
        #expect(e.vertices == [0, 1, 2])
    }

    @Test("Undirected: parallel edges and self-loops read as the simple graph; a pseudograph and the reference conformer")
    func undirectedRepresentations() throws {
        // A square with its diagonals, a heavier parallel copy of 0-1, and a loop.
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (0, 1), (2, 2)]
        let weights = [1, 2, 1, 1, 2, 1, 9, 0]
        var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 4)
        let pseudo = Pseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let a = try #require(pseudo.simulatedAnnealingTour(weight: { weights[$0] }, using: &generator))
        #expect(a.weight({ weights[$0] }) == 4 && !a.edges.contains(6) && !a.edges.contains(7))
        let reference = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let b = try #require(reference.thresholdAcceptingTour(move: .relocate, weight: { weights[$0] }, using: &generator))
        #expect(b.weight({ weights[$0] }) == 4 && !b.edges.contains(6))
    }
}
