// Feasible flows with lower bounds against Hoffman's and Gale's theorem, with shrinking
// (swift-property-based): random multigraphs with self-loops on 1 … 7 vertices listed in a
// shuffled order, random bounds and balanced supplies, on `DirectedPseudograph`. The oracle is
// brute force over every vertex set: a flow exists exactly when no set S supplies more than the
// capacity out of S less the lower bounds into S. A returned flow is checked for its bounds and
// the supplies; a returned barrier for the violated inequality. See README.md.
// Conditions with a closure are computed into a constant before `#expect` (README.md).

import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("Feasible flows against Hoffman–Gale, with shrinking", .tags(.randomized))
struct CirculationPropertyTests {
    @Test("A flow is returned exactly when no vertex set violates Gale's condition, and the barrier violates it")
    func feasibilityMatchesBruteForce() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: -1 ... 3), Gen.int(in: 0 ... 3)).array(of: 0 ... 14)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let lower = raw.map { $0.2 }
            let upper = raw.map { $0.2 + $0.3 }
            var supply = [Int](repeating: 0, count: n)
            for _ in 0 ..< Int.random(in: 0 ... 2, using: &rng) {
                let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng), q = Int.random(in: 1 ... 3, using: &rng)
                supply[a] += q
                supply[b] -= q
            }
            let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let context = "\(ends) bounds \(lower) \(upper) supply \(supply) on \(listed)"
            let number = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })

            func violated(_ inS: [Bool]) -> Bool {
                var out = 0, into = 0, supplied = 0
                for k in ends.indices {
                    if inS[ends[k].0] && !inS[ends[k].1] { out += upper[k] }
                    if !inS[ends[k].0] && inS[ends[k].1] { into += lower[k] }
                }
                for v in 0 ..< n where inS[v] { supplied += supply[v] }
                return supplied > out - into
            }
            var someViolated = false
            for mask in 0 ..< (1 << n) where violated((0 ..< n).map { mask & (1 << $0) != 0 }) { someViolated = true }

            let result = graph.feasibleCirculation(supply: { supply[number[$0]!] }, lowerBound: { lower[$0] }, capacity: { upper[$0] })
            let barrier = graph.findCirculationBarrier(supply: { supply[number[$0]!] }, lowerBound: { lower[$0] }, capacity: { upper[$0] })
            #expect((result == nil) == someViolated, "\(context)")
            #expect((barrier == nil) != someViolated, "\(context)")
            if let result {
                var balance = [Int](repeating: 0, count: n)
                for k in ends.indices {
                    let f = result.flow(ofEdgeAt: k)
                    #expect(lower[k] <= f && f <= upper[k], "edge \(k) \(context)")
                    if ends[k].0 == ends[k].1 { #expect(f == lower[k], "self-loop \(k) \(context)") }
                    balance[ends[k].0] += f
                    balance[ends[k].1] -= f
                }
                #expect(balance == supply, "\(context)")
            }
            if let barrier {
                #expect(!barrier.isEmpty, "\(context)")
                let inBarrier = (0 ..< n).map { barrier.contains(listed[$0]) }
                #expect(violated(inBarrier), "\(context)")
                // In `vertices` order.
                let ordered = barrier == listed.filter { barrier.contains($0) }
                #expect(ordered, "\(context)")
            }
            // Without supplies, the no-supply spellings agree.
            if supply.allSatisfy({ $0 == 0 }) {
                let plain = graph.feasibleCirculation(lowerBound: { lower[$0] }, capacity: { upper[$0] })
                #expect(plain == result, "\(context)")
                let plainBarrier = graph.findCirculationBarrier(lowerBound: { lower[$0] }, capacity: { upper[$0] })
                #expect(plainBarrier == barrier, "\(context)")
            }
        }
    }

    @Test("Unsigned bounds and capacities: a circulation on UInt8, and its barrier")
    func unsignedBounds() throws {
        let graph = DirectedPseudograph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let lower: [UInt8] = [10, 0, 0], upper: [UInt8] = [200, 250, 255]
        let circulation = try #require(graph.feasibleCirculation(lowerBound: { lower[$0] }, capacity: { upper[$0] }))
        let flows = (0 ..< 3).map { circulation.flow(ofEdgeAt: $0) }
        #expect(flows[0] == flows[1] && flows[1] == flows[2] && flows[0] >= 10)
        let tight: [UInt8] = [10, 0, 0], small: [UInt8] = [200, 5, 255]
        #expect(graph.feasibleCirculation(lowerBound: { tight[$0] }, capacity: { small[$0] }) == nil)
        #expect(graph.findCirculationBarrier(lowerBound: { tight[$0] }, capacity: { small[$0] }) == [1])
        #expect(circulation.description == "flow [\(flows[0]), \(flows[1]), \(flows[2])]")
    }

    @Test("flow(checkedEdgeAt:) throws for a position that is not an edge's")
    func checkedFlow() throws {
        let graph = DirectedPseudograph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let circulation = try #require(graph.feasibleCirculation(lowerBound: { _ in 1 }, capacity: { _ in 2 }))
        for bad in [2, 9, -1] { #expect(throws: EdgeNotFound()) { try circulation.flow(checkedEdgeAt: bad) } }
        #expect(try circulation.flow(checkedEdgeAt: 0) == circulation.flow(ofEdgeAt: 0))
        #expect(circulation.flowMap.count == 2)
    }
}
