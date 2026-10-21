// ParallelCentrality against Centrality: on random multigraphs of at most 9 vertices with
// self-loops, directed and undirected, the parallel betweenness (unweighted and with weights
// 1 … 9, normalized or not, with endpoints or not), closeness (both corrections) and harmonic
// centrality at 1 to 5 tasks, and at the default, agree with the sequential measures: closeness and
// harmonic exactly, betweenness to 1e-9 relative. The same input twice gives the same scores.

import AdjacencyListModule
import Centrality
import FuzzSupport
import GraphProtocols
import ParallelCentrality
import Synchronization

/// A flag a task raises when it is done.
final class Done: Sendable {
    let flag = Atomic<Bool>(false)
}

/// A result slot a task fills.
final class Slot<T: Sendable>: @unchecked Sendable {
    var value: T?
}

/// Runs an async computation to completion: the fuzzing thread spins while the task runs on the
/// cooperative pool (the fuzzer has no run loop to wait on, and the computations are short).
func blocking<T: Sendable>(_ body: @Sendable @escaping () async -> T) -> T {
    let done = Done()
    let slot = Slot<T>()
    Task {
        slot.value = await body()
        done.flag.store(true, ordering: .releasing)
    }
    while !done.flag.load(ordering: .acquiring) {}
    return slot.value!
}

@main
enum FuzzParallelCentrality {
    static func main() { runFuzzer(fuzz) }

    static func near(_ a: [Double], _ b: [Double]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) <= 1e-9 * max(1, abs($1)) }
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 9)
        let m = input.int(in: 0 ... 20)
        var arcs: [(Int, Int, Int)] = []
        for _ in 0 ..< m where n > 0 { arcs.append((input.int(below: n), input.int(below: n), input.int(in: 1 ... 9))) }
        let tasks = input.int(in: 0 ... 5)
        let parallelism: Int? = tasks == 0 ? nil : tasks
        let normalized = input.byte() % 2 == 0, endpoints = input.byte() % 2 == 0, wfImproved = input.byte() % 2 == 0

        let directed = AdjacencyList<Int>(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let dw = directed.edges.indices.map { p in arcs.first { DirectedEdge(from: $0.0, to: $0.1) == directed.edges[p] }!.2 }
        let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: arcs.map { UndirectedEdge($0.0, $0.1) })
        let uw = undirected.edges.indices.map { p in arcs.first { UndirectedEdge($0.0, $0.1) == undirected.edges[p] }!.2 }

        let b1 = blocking { await directed.betweennessCentrality(parallelism: parallelism, normalized: normalized, endpoints: endpoints).scores }
        check(near(b1, directed.betweennessCentrality(normalized: normalized, endpoints: endpoints).scores), "directed betweenness \(arcs) \(String(describing: parallelism))")
        let b2 = blocking { await directed.betweennessCentrality(weight: { dw[$0] }, parallelism: parallelism, normalized: normalized, endpoints: endpoints).scores }
        check(near(b2, directed.betweennessCentrality(weight: { dw[$0] }, normalized: normalized, endpoints: endpoints).scores), "directed weighted betweenness \(arcs)")
        let c1 = blocking { await directed.closenessCentrality(parallelism: parallelism, wfImproved: wfImproved).scores }
        check(c1 == directed.closenessCentrality(wfImproved: wfImproved).scores, "directed closeness \(arcs)")
        let h1 = blocking { await directed.harmonicCentrality(parallelism: parallelism).scores }
        check(h1 == directed.harmonicCentrality().scores, "directed harmonic \(arcs)")

        let b3 = blocking { await undirected.betweennessCentrality(parallelism: parallelism, normalized: normalized, endpoints: endpoints).scores }
        check(near(b3, undirected.betweennessCentrality(normalized: normalized, endpoints: endpoints).scores), "undirected betweenness \(arcs)")
        let b4 = blocking { await undirected.betweennessCentrality(weight: { uw[$0] }, parallelism: parallelism, normalized: normalized, endpoints: endpoints).scores }
        check(near(b4, undirected.betweennessCentrality(weight: { uw[$0] }, normalized: normalized, endpoints: endpoints).scores), "undirected weighted betweenness \(arcs)")
        let c2 = blocking { await undirected.closenessCentrality(parallelism: parallelism, wfImproved: wfImproved).scores }
        check(c2 == undirected.closenessCentrality(wfImproved: wfImproved).scores, "undirected closeness \(arcs)")
        let h2 = blocking { await undirected.harmonicCentrality(parallelism: parallelism).scores }
        check(h2 == undirected.harmonicCentrality().scores, "undirected harmonic \(arcs)")

        let again = blocking { await undirected.betweennessCentrality(parallelism: parallelism, normalized: normalized, endpoints: endpoints).scores }
        check(again == b3, "not deterministic \(arcs) \(String(describing: parallelism))")
    }
}
