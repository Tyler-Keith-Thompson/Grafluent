// Floyd's and Brent's cycle detection as event sequences on a functional graph
// (`lazy.floydCycleDetection(from:)`, `lazy.brentCycleDetection(from:)`): hand traces of a tail
// into a 3-cycle, a fixed point, and a property test against the closure functions. Case IDs
// (FG-nn) are listed in README.md.

import FunctionalGraphs
import GraphProtocols
import PropertyBased
import Testing

@Suite("FunctionalGraphs cycle detection events")
struct CycleDetectionEventsTests {
    @Test("FG-067 a tail of two into a 3-cycle: every step, the meeting, the root and the length, Floyd and Brent", .tags(.fixture))
    func handTraced() {
        // 0 → 1 → 2 → 3 → 4 → 2.
        let graph = FunctionalGraph(successors: [1, 2, 3, 4, 2])
        let floyd: [FloydCycleDetectionEvent] = [
            .step(tortoise: 1, hare: 2), .step(tortoise: 2, hare: 4), .step(tortoise: 3, hare: 3), .meet(3),
            .step(tortoise: 1, hare: 4), .step(tortoise: 2, hare: 2), .root(2, tailLength: 2),
            .step(tortoise: 2, hare: 3), .step(tortoise: 2, hare: 4), .step(tortoise: 2, hare: 2), .cycle(length: 3),
        ]
        #expect(Array(graph.lazy.floydCycleDetection(from: 0)) == floyd)
        let brent: [BrentCycleDetectionEvent] = [
            .step(tortoise: 0, hare: 1), .teleport(1, power: 2), .step(tortoise: 1, hare: 2), .step(tortoise: 1, hare: 3),
            .teleport(3, power: 4), .step(tortoise: 3, hare: 4), .step(tortoise: 3, hare: 2), .step(tortoise: 3, hare: 3),
            .cycle(length: 3), .step(tortoise: 0, hare: 1), .step(tortoise: 0, hare: 2), .step(tortoise: 0, hare: 3),
            .step(tortoise: 1, hare: 4), .step(tortoise: 2, hare: 2), .root(2, tailLength: 2),
        ]
        #expect(Array(graph.lazy.brentCycleDetection(from: 0)) == brent)
        let search = graph.lazy.brentCycleDetection(from: 0)
        #expect(Array(search) == Array(search))
        #expect(floyd[3].description == "meet(3)" && brent[1].description == "teleport(1, 2)")
    }

    @Test("FG-068 a fixed point at the start")
    func fixedPoint() {
        let graph = FunctionalGraph(successors: [0])
        #expect(Array(graph.lazy.floydCycleDetection(from: 0)) == [
            .step(tortoise: 0, hare: 0), .meet(0), .root(0, tailLength: 0), .step(tortoise: 0, hare: 0), .cycle(length: 1),
        ])
        #expect(Array(graph.lazy.brentCycleDetection(from: 0)) == [
            .step(tortoise: 0, hare: 0), .cycle(length: 1), .step(tortoise: 0, hare: 0), .root(0, tailLength: 0),
        ])
    }

    @Test("FG-069 property (PropertyBased): the root, tail and cycle lengths are floydCycleDetection's and brentCycleDetection's; Floyd's hare moves two steps per tortoise step", .tags(.randomized))
    func property() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 11).array(of: 1 ... 12), Gen.int(in: 0 ... 11)) { raw, rawStart in
            let n = raw.count
            let successors = raw.map { $0 % n }
            let graph = FunctionalGraph(successors: successors)
            let start = rawStart % n
            let f = { (v: Int) in successors[v] }
            let plainFloyd = floydCycleDetection(from: start, successor: f)
            var root = -1, tail = -1, length = -1, met = false
            var tortoise = start, hare = start
            for event in graph.lazy.floydCycleDetection(from: start) {
                switch event {
                case .step(let t, let h):
                    if !met { #expect(t == f(tortoise) && h == f(f(hare))) }
                    (tortoise, hare) = (t, h)
                case .meet(let v):
                    #expect(v == tortoise && v == hare)
                    met = true
                    (tortoise, hare) = (start, v)
                case .root(let v, let mu): (root, tail) = (v, mu)
                case .cycle(let lambda): length = lambda
                }
            }
            #expect(root == plainFloyd.root && tail == plainFloyd.tailLength && length == plainFloyd.cycleLength)
            let plainBrent = brentCycleDetection(from: start, successor: f)
            (root, tail, length) = (-1, -1, -1)
            for event in graph.lazy.brentCycleDetection(from: start) {
                switch event {
                case .root(let v, let mu): (root, tail) = (v, mu)
                case .cycle(let lambda): length = lambda
                case .step, .teleport: break
                }
            }
            #expect(root == plainBrent.root && tail == plainBrent.tailLength && length == plainBrent.cycleLength)
        }
    }
}
