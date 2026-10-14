// Chinese postman tours and the metaheuristics at scale, with answers known in closed form: the
// unit grid, whose odd vertices pair off along its sides; a long directed cycle with one chord,
// whose surplus goes back around the cycle; simulated annealing and threshold accepting on 300
// points with NetworkX's defaults, never longer than their nearest-neighbour start.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Testing
import Tours
import Walks

@Suite("Postman tours and metaheuristics at scale")
struct PostmanAndMetaheuristicScaleTests {
    @Test("The 60 × 60 unit grid: 7,080 edges, 232 odd vertices paired along the sides, weight 7,196", .timeLimit(.minutes(1)))
    func grid() throws {
        let r = 60, c = 60
        var ends: [UndirectedEdge<Int>] = []
        for i in 0 ..< r {
            for j in 0 ..< c {
                if j + 1 < c { ends.append(UndirectedEdge(i * c + j, i * c + j + 1)) }
                if i + 1 < r { ends.append(UndirectedEdge(i * c + j, (i + 1) * c + j)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< r * c, edges: ends)
        let tour = try #require(graph.chinesePostmanTour { _ in 1 })
        // Each side has 58 odd vertices, paired by 29 unit edges.
        #expect(tour.weight == 7080 + 4 * 29)
        #expect(tour.duplicatedEdges.count == 116)
        #expect(tour.walk.length == 7196 && tour.walk.isClosed && tour.walk.source == 0)
        var uses = [Int](repeating: 0, count: ends.count)
        for e in tour.walk.edges { uses[e] += 1 }
        var expected = [Int](repeating: 1, count: ends.count)
        for e in tour.duplicatedEdges { expected[e] += 1 }
        #expect(uses == expected)
        let walk = Walk(vertices: tour.walk.vertices, edges: tour.walk.edges, in: graph)
        #expect(walk != nil)
    }

    @Test("C(10,000) directed with the chord 0 → 5,000: the surplus at 5,000 goes back around, weight 15,001", .timeLimit(.minutes(1)))
    func chordedCycle() throws {
        let n = 10_000
        let arcs = (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) } + [DirectedEdge(from: 0, to: 5_000)]
        let graph = AdjacencyList(vertices: 0 ..< n, edges: arcs)
        let tour = try #require(graph.chinesePostmanTour { _ in 1 })
        #expect(tour.weight == 15_001)
        #expect(tour.duplicatedEdges == Array(5_000 ..< n))
        #expect(tour.walk.length == 15_001 && tour.walk.isClosed && tour.walk.source == 0)
    }

    @Test("300 points: simulated annealing and threshold accepting, both moves, no longer than nearest neighbour", .timeLimit(.minutes(1)))
    func metaheuristics() throws {
        var draw = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 300)
        let points = (0 ..< 300).map { _ in (Double.random(in: 0 ..< 1, using: &draw), Double.random(in: 0 ..< 1, using: &draw)) }
        var ends: [UndirectedEdge<Int>] = [], weights: [Double] = []
        for i in 0 ..< 300 {
            for j in i + 1 ..< 300 {
                ends.append(UndirectedEdge(i, j))
                let dx = points[i].0 - points[j].0, dy = points[i].1 - points[j].1
                weights.append((dx * dx + dy * dy).squareRoot())
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 300, edges: ends)
        let start = try #require(graph.nearestNeighborTour { weights[$0] }).weight { weights[$0] }
        for move in TourMove.allCases {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let annealed = try #require(graph.simulatedAnnealingTour(move: move, weight: { weights[$0] }, using: &generator))
            let accepted = try #require(graph.thresholdAcceptingTour(move: move, threshold: 0.01, weight: { weights[$0] }, using: &generator))
            #expect(annealed.vertices.count == 300 && Set(annealed.vertices).count == 300)
            #expect(annealed.weight { weights[$0] } <= start + 1e-9)
            #expect(accepted.weight { weights[$0] } <= start + 1e-9)
        }
    }
}
