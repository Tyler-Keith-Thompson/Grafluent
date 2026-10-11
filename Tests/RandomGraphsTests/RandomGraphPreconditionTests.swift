// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test), on every
// conformer the rule covers. A valid neighbour of the call then runs in this process.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing
import Trees

@Suite("RandomGraphs preconditions", .tags(.precondition))
struct RandomGraphPreconditionTests {
    @Test("RG-002 the all-zero state never leaves zero")
    func rg002() async {
        // Xoshiro256StarStar(state: (0, 0, 0, 0)) → **trap**: the state must not be all zero
        await #expect(processExitsWith: .failure) {
            _ = Xoshiro256StarStar(state: (0, 0, 0, 0))
        }
        // Without the fault: any one nonzero word is a valid state.
        var generator = Xoshiro256StarStar(state: (0, 0, 0, 1))
        #expect(generator.next() == 0 && generator.next() == 0 && generator.next() != 0)
    }

    @Test("RG-022 negative vertex count")
    func rg022() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(…) → **trap**: vertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: -1, edgeProbability: 0.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 0, edgeProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("RG-023 p > 1")
    func rg023() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(…) → **trap**: edgeProbability 1.5 is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: 1.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 1.0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
    }

    @Test("RG-024 p < 0")
    func rg024() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(…) → **trap**: edgeProbability -0.1 is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: -0.1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 0.0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 0)
    }

    @Test("RG-025 p NaN")
    func rg025() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(…) → **trap**: edgeProbability nan is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 5, edgeProbability: .nan, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 5)
    }

    @Test("RG-040 m > N")
    func rg040() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount:edgeCount:using:) → **trap**: edgeCount 7 is not in 0...6
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: 6, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("RG-041 m > N directed")
    func rg041() async {
        // CompressedSparseRow.erdosRenyi(vertexCount:edgeCount:using:) → **trap**: edgeCount 7 is not in 0...6
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: 3, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: 3, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: 3, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 3, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 3, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 3, edgeCount: 7, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = CompressedSparseRow.erdosRenyi(vertexCount: 3, edgeCount: 6, using: &generator)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 6)
    }

    @Test("RG-042 negative m")
    func rg042() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount:edgeCount:using:) → **trap**: edgeCount -1 is not in 0...6
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 4, edgeCount: -1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: 0, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 0)
    }

    @Test("RG-043 n = 1, m = 1")
    func rg043() async {
        // UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount:edgeCount:using:) → **trap**: edgeCount 1 is not in 0...0
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 1, edgeCount: 1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 1, edgeCount: 0, using: &generator)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("RG-055 m = 0")
    func rg055() async {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(…) → **trap**: edgesPerVertex 0 is not in 1..<5
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 1, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4)
    }

    @Test("RG-056 m = n")
    func rg056() async {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(…) → **trap**: edgesPerVertex 5 is not in 1..<5
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 5, edgesPerVertex: 4, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4)
    }

    @Test("RG-057 n = 1")
    func rg057() async {
        // UndirectedAdjacencyList<Int>.barabasiAlbert(…) → **trap**: edgesPerVertex 1 is not in 1..<1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 1, edgesPerVertex: 1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
    }

    @Test("RG-069 odd k (NetworkX floors it)")
    func rg069() async {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(…) → **trap**: nearestNeighborCount 3 is not even
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, rewiringProbability: 0.1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, rewiringProbability: 0.1, using: &generator)
        #expect(graph.vertexCount == 10 && graph.edgeCount == 10)
    }

    @Test("RG-070 k > n")
    func rg070() async {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(…) → **trap**: nearestNeighborCount 6 > vertexCount 4
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, rewiringProbability: 0.1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, rewiringProbability: 0.1, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("RG-071 p > 1")
    func rg071() async {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(…) → **trap**: rewiringProbability 1.5 is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &generator)
        #expect(graph.vertexCount == 10 && graph.edgeCount == 20)
    }

    @Test("RG-080 negative radius")
    func rg080() async {
        // UndirectedAdjacencyList<Int>.randomGeometric(…) → **trap**: radius -0.1 is negative or NaN
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomGeometric(vertexCount: 5, radius: -0.1, dimension: 2, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.0, dimension: 2, using: &generator).graph
        #expect(graph.vertexCount == 5 && graph.edgeCount == 0)
    }

    @Test("RG-081 NaN radius")
    func rg081() async {
        // UndirectedAdjacencyList<Int>.randomGeometric(…) → **trap**: radius nan is negative or NaN
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomGeometric(vertexCount: 5, radius: .nan, dimension: 2, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 2, using: &generator).graph
        #expect(graph.vertexCount == 5 && graph.edgeCount == 0)
    }

    @Test("RG-082 dimension 0")
    func rg082() async {
        // UndirectedAdjacencyList<Int>.randomGeometric(…) → **trap**: dimension 0 < 1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 1, using: &generator).graph
        #expect(graph.vertexCount == 5 && graph.edgeCount == 1)
    }

    @Test("RG-089 asymmetric undirected")
    func rg089() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: edgeProbabilities is not symmetric
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.2, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.2, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.2, 0.5]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
    }

    @Test("RG-090 not square")
    func rg090() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: edgeProbabilities is not blockSizes.count square
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
    }

    @Test("RG-091 probability > 1")
    func rg091() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: edge probability 1.5 is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.5]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2], edgeProbabilities: [[1.0]], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
    }

    @Test("RG-092 negative block size")
    func rg092() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: block size -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [2, -1], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 0], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
    }

    @Test("RG-101 n = 0: a tree is never empty")
    func rg101() async {
        // Tree<Int>.random(vertexCount: 0, using: &…) → **trap**: a Tree has at least one vertex
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Tree<Int>.random(vertexCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Tree<Int>.random(vertexCount: -1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = Tree<Int>.random(vertexCount: 1, using: &generator)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("RG-107 m > C(n, 2)")
    func rg107() async {
        // DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &…) → **trap**: edgeCount 7 is not in 0...6
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 6, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("RG-121 d = n")
    func rg121() async {
        // UndirectedAdjacencyList<Int>.randomRegular(…) → **trap**: degree 5 is not in 0..<5
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomRegular(vertexCount: 5, degree: 5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 4, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
    }

    @Test("RG-122 negative d")
    func rg122() async {
        // UndirectedAdjacencyList<Int>.randomRegular(…) → **trap**: degree -1 is not in 0..<5
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomRegular(vertexCount: 5, degree: -1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 0)
    }

    @Test("RG-123 n·d odd")
    func rg123() async {
        // UndirectedAdjacencyList<Int>.randomRegular(…) → **trap**: vertexCount × degree 15 is odd
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomRegular(vertexCount: 5, degree: 3, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 5, degree: 2, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 5)
    }

    @Test("RG-124 negative vertex count")
    func rg124() async {
        // UndirectedAdjacencyList<Int>.randomRegular(…) → **trap**: vertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomRegular(vertexCount: -1, degree: 0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 1, degree: 0, using: &generator)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("RG-136 negative left count")
    func rg136() async {
        // UndirectedAdjacencyList<Int>.randomBipartite(…) → **trap**: leftCount -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = BipartiteGraph<Int>.randomBipartite(leftCount: -1, rightCount: 3, edgeProbability: 0.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 3, edgeProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 0)
    }

    @Test("RG-137 negative right count")
    func rg137() async {
        // UndirectedAdjacencyList<Int>.randomBipartite(…) → **trap**: rightCount -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: -1, edgeProbability: 0.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 0, edgeProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 0)
    }

    @Test("RG-138 p > 1")
    func rg138() async {
        // UndirectedAdjacencyList<Int>.randomBipartite(…) → **trap**: edgeProbability 1.5 is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 1.0, using: &generator)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
    }

    @Test("RG-139 p NaN")
    func rg139() async {
        // UndirectedAdjacencyList<Int>.randomBipartite(…) → **trap**: edgeProbability nan is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: .nan, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 5)
    }

    @Test("RG-146 k > n = 0")
    func rg146() async {
        // UndirectedAdjacencyList<Int>.wattsStrogatz(…) → **trap**: nearestNeighborCount 2 > vertexCount 0
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("RG-147 dimension 0 with radius ≥ 1/2 (every pair checked)")
    func rg147() async {
        // UndirectedAdjacencyList<Int>.randomGeometric(…) → **trap**: dimension 0 < 1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 3, radius: 0.6, dimension: 1, using: &generator).graph
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
    }

    @Test("RG-148 d = n with n·d even")
    func rg148() async {
        // UndirectedAdjacencyList<Int>.randomRegular(…) → **trap**: degree 4 is not in 0..<4
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomRegular(vertexCount: 4, degree: 4, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 4, degree: 3, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("RG-149 negative block size after a block of 1")
    func rg149() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: block size -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [1, -1], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [1, 0], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &generator)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("RG-150 more rows than blocks")
    func rg150() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: edgeProbabilities is not blockSizes.count square
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
    }

    @Test("RG-151 longer rows than blocks")
    func rg151() async {
        // UndirectedAdjacencyList<Int>.stochasticBlockModel(…) → **trap**: edgeProbabilities is not blockSizes.count square
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 2], edgeProbabilities: [[0.5, 0.1], [0.1, 0.5]], using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
    }
}
