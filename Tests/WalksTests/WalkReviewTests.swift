// Cases added after planting bugs: a path may not repeat an edge position even when its vertices
// are distinct (so `Trail(path)` can never fail); cycles of different lengths that start alike
// are not equal; cycles that differ only in their edges hash apart; a path's weight counts every
// edge. Case IDs (WK-nn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk review cases")
struct WalkReviewTests {
    @Test("WK-1401 a path with distinct vertices but a repeated edge position is not a path")
    func pathRepeatsAnEdge() {
        #expect(Path(vertices: [0, 1, 2], edges: [5, 5]) == nil)
        #expect(Path(vertices: [0, 1, 2], edges: [5, 6]) != nil)
        // The same values as a trail are refused too, so no conversion could produce one.
        #expect(Trail(vertices: [0, 1, 2], edges: [5, 5]) == nil)
        #expect(Walk(vertices: [0, 1, 2], edges: [5, 5]).length == 2)
        #expect(Path(Walk(vertices: [0, 1, 2], edges: [5, 5])) == nil)
    }

    @Test("WK-1402 cycles of different lengths that start with the same step are not equal")
    func differentLengths() {
        // A self-loop 0→0 by edge 7, and a 2-cycle 0→1→0 whose first edge is also 7.
        let loop = Cycle(vertices: [0], edges: [7])!
        let digon = Cycle(vertices: [0, 1], edges: [7, 8])!
        #expect(loop != digon)
        #expect(digon != loop)
        let circuit = Circuit(vertices: [0], edges: [7])!
        let longer = Circuit(vertices: [0, 1, 0, 2], edges: [7, 8, 9, 10])!
        #expect(circuit != longer)
        #expect(longer != circuit)
    }

    @Test("WK-1403 cycles that differ only in their edge positions hash apart")
    func edgesInTheHash() {
        // 2-cycles 0⇄1 over different pairs of parallel edges: equal vertices, distinct values.
        var hashes = Set<Int>()
        var cycles = Set<Cycle<Int, Int>>()
        for a in 0 ..< 10 {
            for b in 10 ..< 20 {
                let cycle = Cycle(vertices: [0, 1], edges: [a, b])!
                cycles.insert(cycle)
                hashes.insert(cycle.hashValue)
            }
        }
        #expect(cycles.count == 100)
        // Collisions are allowed, but a hash that ignored edges would give one value for all 100.
        #expect(hashes.count > 90)
        var circuitHashes = Set<Int>()
        for a in 0 ..< 10 { circuitHashes.insert(Circuit(vertices: [0, 1], edges: [a, a + 10])!.hashValue) }
        #expect(circuitHashes.count > 8)
    }

    @Test("WK-1404 a path's, trail's, circuit's and cycle's weight is the sum over every edge")
    func weightsOfEveryType() {
        let weights = [3, 5, 7, 11]
        #expect(Path(vertices: [0, 1, 2], edges: [1, 2])!.weight { weights[$0] } == 12)
        #expect(Path(vertex: 4).weight { weights[$0] } == 0)
        #expect(Trail(vertices: [0, 1, 0], edges: [0, 3])!.weight { weights[$0] } == 14)
        #expect(Circuit(vertices: [0, 1], edges: [0, 1])!.weight { weights[$0] } == 8)
        #expect(Cycle(vertices: [0, 1, 2], edges: [0, 1, 2])!.weight { weights[$0] } == 15)
    }
}
