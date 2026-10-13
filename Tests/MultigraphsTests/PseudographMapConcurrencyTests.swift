// Attached maps on copies mutated at once on two threads: each round copies one pseudograph that
// has an edge map and a vertex map, hands the two copies to two threads released together by a
// spin barrier, and has each insert edges with new endpoints, write their values and remove an
// edge. Afterwards each copy's maps hold one value per edge and per vertex, and only the values
// that copy wrote. The race this guards against is timing-dependent, so many rounds run; a round
// that does not interleave passes either way. Each test is self-contained.

import Foundation
import GraphProtocols
import Multigraphs
import Synchronization
import Testing

@Suite("Pseudograph attached maps on copies mutated concurrently")
struct PseudographMapConcurrencyTests {
    @Test("Two copies of a Pseudograph, mutated on two threads at once, keep their own maps")
    func undirectedCopies() {
        // The two copies, which are the only holders of the graph's storage, and the barrier.
        final class Round: Sendable {
            let left: Mutex<Pseudograph<Int>>
            let right: Mutex<Pseudograph<Int>>
            let arrived = Atomic<Int>(0)
            init(left: consuming Pseudograph<Int>, right: consuming Pseudograph<Int>) {
                self.left = Mutex(left)
                self.right = Mutex(right)
            }
        }

        var failures = 0
        var firstFailure = ""
        for round in 0 ..< 2000 {
            var graph = Pseudograph<Int>(edges: (0 ..< 7).map { UndirectedEdge($0, $0 + 1) })
            graph.reserveCapacity(vertexCount: 64, edgeCount: 64)
            let weights = graph.addEdgeMap(default: 0.0)
            let ranks = graph.addVertexMap(default: 0)
            // A structural mutation after the reserve, so the graph records where its storage is
            // and the copies' next mutations take the fast path.
            _ = graph.insert(edge: UndirectedEdge(7, 0))
            for p in 0 ..< graph.edgeCount { graph[weights, ofEdgeAt: p] = 0.5 }
            for v in graph.vertices { graph[ranks, of: v] = 7 }

            let shared = Round(left: graph, right: consume graph)
            let done = DispatchSemaphore(value: 0)
            for side in 1 ... 2 {
                Thread {
                    func mutate(_ g: inout Pseudograph<Int>) {
                        for k in 0 ..< 4 {
                            let u = 1000 * side + 2 * k
                            let p = g.insert(edge: UndirectedEdge(u, u + 1))
                            g[weights, ofEdgeAt: p] = Double(side)
                            g[ranks, of: u] = side
                            g[ranks, of: u + 1] = side
                        }
                        _ = g.remove(edge: UndirectedEdge(side, side + 1))
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
                let g = side == 1 ? shared.left.withLock { $0 } : shared.right.withLock { $0 }
                var wrong = g.values(of: weights)._storage.dense.count != g.edgeCount
                wrong = wrong || g.values(of: ranks)._storage.dense.count != g.vertexCount
                for p in g.edges.indices {
                    let endpoint = max(g.edges[p].u, g.edges[p].v)
                    let expected = endpoint >= 1000 ? (endpoint / 1000 == side ? Double(side) : -1) : 0.5
                    wrong = wrong || g[weights, ofEdgeAt: p] != expected
                }
                for v in g.vertices {
                    let expected = v >= 1000 ? (v / 1000 == side ? side : -1) : 7
                    wrong = wrong || g[ranks, of: v] != expected
                }
                wrong = wrong || g.edgeCount != 11 || g.vertexCount != 16
                if wrong {
                    failures += 1
                    if firstFailure.isEmpty { firstFailure = "round \(round), copy \(side)" }
                }
            }
        }
        #expect(failures == 0, "first: \(firstFailure)")
    }
}
