// A regression, split from ToursRegressionTests.swift because it relies on speed: without the
// reachability test the Hamiltonian search tries every ordering of K(14) (13!) and still answers
// nil, so only the one-minute limit tells the two apart. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("Tours regressions at scale")
struct ToursRegressionScaleTests {
    @Test("Hamiltonian cycle through a cut vertex: K(5) and K(14) joined only through one vertex have none, found without walking K(14) once K(5) is left unfinished; undirected and directed", .timeLimit(.minutes(1)))
    func cutVertexNeedsReachability() async {
        await Task {
            // A = 0 ..< 5, c = 5, B = 6 ..< 20, c joined to every vertex of A and of B. A cycle would
            // pass c twice, so there is none. Each vertex keeps two neighbours (a predecessor and a
            // successor) inside its own clique however far the search has gone, so the degree
            // rules never cut; only reachability does, on the step from c into B while A has
            // vertices left. Without it every ordering of B (13!) is tried.
            var pairs: [(Int, Int)] = []
            for u in 0 ..< 6 { for v in u + 1 ..< 6 { pairs.append((u, v)) } }
            for u in 5 ..< 20 { for v in u + 1 ..< 20 { pairs.append((u, v)) } }
            let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(undirected.hamiltonianCycle() == nil)
            let directed = AdjacencyList<Int>(vertices: 0 ..< 20, edges: pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] })
            #expect(directed.hamiltonianCycle() == nil)
        }.value
    }
}
