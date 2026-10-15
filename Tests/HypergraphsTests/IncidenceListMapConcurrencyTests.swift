// Attached maps on copies mutated at once on two threads: each round copies one directed
// hypergraph that has an edge map and a vertex map, hands the two copies to two threads released
// together by a spin barrier, and has each insert hyperedges with new members and write their
// values. Afterwards each copy's maps hold one value per hyperedge and per vertex, and only the
// values that copy wrote. The race this guards against is timing-dependent, so many rounds run; a
// round that does not interleave passes either way. Each test is self-contained.
// WASI runs one thread, with no `Thread` or Dispatch.
#if !os(WASI)

import Foundation
import GraphProtocols
import Hypergraphs
import Synchronization
import Testing

@Suite("IncidenceList attached maps on copies mutated concurrently")
struct IncidenceListMapConcurrencyTests {
    @Test("Two copies of an IncidenceList, mutated on two threads at once, keep their own maps")
    func directedCopies() {
        // The two copies, which are the only holders of the hypergraph's storage, and the barrier.
        final class Round: Sendable {
            let left: Mutex<IncidenceList<Int>>
            let right: Mutex<IncidenceList<Int>>
            let arrived = Atomic<Int>(0)
            init(left: consuming IncidenceList<Int>, right: consuming IncidenceList<Int>) {
                self.left = Mutex(left)
                self.right = Mutex(right)
            }
        }

        var failures = 0
        var firstFailure = ""
        for round in 0 ..< 2000 {
            var hypergraph = IncidenceList<Int>(hyperedges: (0 ..< 7).map { (sources: [$0], targets: [$0 + 1]) })
            hypergraph.reserveCapacity(vertexCount: 64, hyperedgeCount: 64, sourceCount: 64, targetCount: 64)
            let weights = hypergraph.addEdgeMap(default: 0.0)
            let ranks = hypergraph.addVertexMap(default: 0)
            // A structural mutation after the reserve, so the hypergraph records where its storage
            // is and the copies' next mutations take the fast path.
            _ = hypergraph.insert(sources: [7], targets: [0])
            for p in 0 ..< hypergraph.hyperedgeCount { hypergraph[weights, ofEdgeAt: p] = 0.5 }
            for v in hypergraph.vertices { hypergraph[ranks, of: v] = 7 }

            let shared = Round(left: hypergraph, right: consume hypergraph)
            let done = DispatchSemaphore(value: 0)
            for side in 1 ... 2 {
                Thread {
                    func mutate(_ h: inout IncidenceList<Int>) {
                        for k in 0 ..< 4 {
                            let u = 1000 * side + 2 * k
                            let p = h.insert(sources: [u], targets: [u + 1])
                            h[weights, ofEdgeAt: p] = Double(side)
                            h[ranks, of: u] = side
                            h[ranks, of: u + 1] = side
                        }
                    }
                    shared.arrived.add(1, ordering: .sequentiallyConsistent)
                    while shared.arrived.load(ordering: .sequentiallyConsistent) < 2 {}
                    if side == 1 { shared.left.withLock { mutate(&$0) } } else { shared.right.withLock { mutate(&$0) } }
                    done.signal()
                }.start()
            }
            done.wait()
            done.wait()

            for side in 1 ... 2 {
                let h = side == 1 ? shared.left.withLock { $0 } : shared.right.withLock { $0 }
                var wrong = h.values(of: weights)._storage.dense.count != h.hyperedgeCount
                wrong = wrong || h.values(of: ranks)._storage.dense.count != h.vertexCount
                for p in 0 ..< h.hyperedgeCount {
                    let source = h.sources(ofHyperedgeAt: p)[h.sources(ofHyperedgeAt: p).startIndex]
                    let expected = source >= 1000 ? (source / 1000 == side ? Double(side) : -1) : 0.5
                    wrong = wrong || h[weights, ofEdgeAt: p] != expected
                }
                for v in h.vertices {
                    let expected = v >= 1000 ? (v / 1000 == side ? side : -1) : 7
                    wrong = wrong || h[ranks, of: v] != expected
                }
                wrong = wrong || h.hyperedgeCount != 12 || h.vertexCount != 16
                if wrong {
                    failures += 1
                    if firstFailure.isEmpty { firstFailure = "round \(round), copy \(side)" }
                }
            }
        }
        #expect(failures == 0, "first: \(firstFailure)")
    }
}

#endif
