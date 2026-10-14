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

    @Test("RG-177 the counts differ")
    func rg177() async {
        // isDigraphical(inDegrees: [1, 1], outDegrees: [1, 1, 0]) → **trap**: inDegrees.count 2 != outDegrees.count 3
        await #expect(processExitsWith: .failure) {
            _ = isDigraphical(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        // Without the fault: accepted.
        #expect(isDigraphical(inDegrees: [1, 1], outDegrees: [1, 1]) == true)
    }

    @Test("RG-191 not graphical")
    func rg191() async {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 1, 1]) → **trap**: degreeSequence is not graphical
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 1, 1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.havelHakimi(degreeSequence: [3, 3, 1, 1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.havelHakimi(degreeSequence: [3, 3, 1, 1])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 2, 2])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 5)
    }

    @Test("RG-192 not digraphical")
    func rg192() async {
        // CompressedSparseRow.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2]) → **trap**: the degree sequences are not digraphical
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.havelHakimi(inDegrees: [2, 0], outDegrees: [0, 2])
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.havelHakimi(inDegrees: [1, 0], outDegrees: [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
    }

    @Test("RG-193 the counts differ")
    func rg193() async {
        // CompressedSparseRow.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0]) → **trap**: inDegrees.count 2 != outDegrees.count 3
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1, 0])
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.havelHakimi(inDegrees: [1, 1], outDegrees: [1, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
    }

    @Test("RG-204 odd degree sum")
    func rg204() async {
        // Pseudograph<Int>.configurationModel(degreeSequence: [2, 1], using: &Xoshiro256StarStar(seed: 0)) → **trap**: the degree sum 3 is odd
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.configurationModel(degreeSequence: [2, 1], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = Pseudograph<Int>.configurationModel(degreeSequence: [2, 2], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
    }

    @Test("RG-205 negative degree")
    func rg205() async {
        // Pseudograph<Int>.configurationModel(degreeSequence: [2, -2], using: &Xoshiro256StarStar(seed: 0)) → **trap**: degreeSequence has a negative degree -2
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.configurationModel(degreeSequence: [2, -2], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = Pseudograph<Int>.configurationModel(degreeSequence: [2, 2], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
    }

    @Test("RG-206 unequal sums")
    func rg206() async {
        // DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 0], using: &Xoshiro256StarStar(seed: 0)) → **trap**: the in-degree sum 2 != the out-degree sum 1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 0], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 1], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
    }

    @Test("RG-207 the counts differ")
    func rg207() async {
        // DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 1, 0], using: &Xoshiro256StarStar(seed: 0)) → **trap**: inDegrees.count 2 != outDegrees.count 3
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 1, 0], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 1], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
    }

    @Test("RG-215 negative weight")
    func rg215() async {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &Xoshiro256StarStar(seed: 0)) → **trap**: expected degree -1.0 is negative or not finite
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.chungLu(expectedDegrees: [1.0, -1.0], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, 1.0], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
    }

    @Test("RG-216 infinite weight")
    func rg216() async {
        // UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &Xoshiro256StarStar(seed: 0)) → **trap**: expected degree inf is negative or not finite
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.chungLu(expectedDegrees: [1.0, .infinity], using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, 1e+300], using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
    }

    @Test("RG-224 m = 0")
    func rg224() async {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → **trap**: edgesPerVertex 0 is not in 1...5
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 0, triangleProbability: 0.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 1, triangleProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4)
    }

    @Test("RG-225 m > n")
    func rg225() async {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &Xoshiro256StarStar(seed: 0)) → **trap**: edgesPerVertex 4 is not in 1...3
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 4, triangleProbability: 0.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 3, edgesPerVertex: 3, triangleProbability: 0.5, using: &generator)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 0)
    }

    @Test("RG-226 p > 1")
    func rg226() async {
        // UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &Xoshiro256StarStar(seed: 0)) → **trap**: triangleProbability 1.5 is not in 0...1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 5, edgesPerVertex: 2, triangleProbability: 1.0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 6)
    }

    @Test("RG-235 odd k")
    func rg235() async {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → **trap**: nearestNeighborCount 3 is not even
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 3, shortcutProbability: 0.3, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0.3, using: &generator)
        #expect(graph.vertexCount == 10 && graph.edgeCount == 12)
    }

    @Test("RG-236 k > n")
    func rg236() async {
        // UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &Xoshiro256StarStar(seed: 0)) → **trap**: nearestNeighborCount 6 > vertexCount 4
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 6, shortcutProbability: 0.3, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 4, nearestNeighborCount: 4, shortcutProbability: 0.3, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("RG-244 no vertices")
    func rg244() async {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &Xoshiro256StarStar(seed: 0)) → **trap**: a connected graph needs at least 1 vertex, not 0
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 0, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 1, nearestNeighborCount: 0, rewiringProbability: 0.5, tries: 100, using: &generator)
        #expect(graph?.vertexCount == 1 && graph?.edgeCount == 0)
    }

    @Test("RG-245 negative tries")
    func rg245() async {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &Xoshiro256StarStar(seed: 0)) → **trap**: tries -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: -1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        // No tries: nil, with no draws.
        #expect(UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil)
    }

    @Test("RG-246 odd k with no tries")
    func rg246() async {
        // UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &Xoshiro256StarStar(seed: 0)) → **trap**: nearestNeighborCount 3 is not even
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 3, rewiringProbability: 0.5, tries: 0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        // No tries: nil, with no draws.
        #expect(UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 5, nearestNeighborCount: 2, rewiringProbability: 0.5, tries: 0, using: &generator) == nil)
    }

    @Test("RG-255 k = n")
    func rg255() async {
        // CompressedSparseRow.randomKOut(vertexCount: 4, outDegree: 4, using: &Xoshiro256StarStar(seed: 0)) → **trap**: outDegree 4 is not in 0...3
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomKOut(vertexCount: 4, outDegree: 4, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 4, outDegree: 3, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("RG-256 k < 0")
    func rg256() async {
        // CompressedSparseRow.randomKOut(vertexCount: 4, outDegree: -1, using: &Xoshiro256StarStar(seed: 0)) → **trap**: outDegree -1 is not in 0...3
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomKOut(vertexCount: 4, outDegree: -1, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 4, outDegree: 0, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 0)
    }

    @Test("RG-261 n < 3")
    func rg261() async {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 2, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → **trap**: vertexCount 2 < 3, the starting cycle
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.scaleFree(vertexCount: 2, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 3, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("RG-262 alpha = 0")
    func rg262() async {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.0, beta: 0.95, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → **trap**: alpha, beta and gamma must be positive
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.0, beta: 0.95, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.01, beta: 0.94, gamma: 0.05, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 19)
    }

    @Test("RG-263 the probabilities sum to 1.5")
    func rg263() async {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.5, beta: 0.5, gamma: 0.5, deltaIn: 0.2, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → **trap**: alpha + beta + gamma 1.5 is not 1
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.5, beta: 0.5, gamma: 0.5, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.5, beta: 0.25, gamma: 0.25, deltaIn: 0.2, deltaOut: 0.0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 7)
    }

    @Test("RG-264 deltaIn < 0")
    func rg264() async {
        // DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: -0.1, deltaOut: 0.0, using: &Xoshiro256StarStar(seed: 0)) → **trap**: deltaIn -0.1 is negative or not finite
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: -0.1, deltaOut: 0.0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = DirectedPseudograph<Int>.scaleFree(vertexCount: 5, alpha: 0.41, beta: 0.54, gamma: 0.05, deltaIn: 0.0, deltaOut: 0.0, using: &generator)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 9)
    }

    @Test("RG-272 m > ab")
    func rg272() async {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 2, edgeCount: 5, using: &Xoshiro256StarStar(seed: 0)) → **trap**: edgeCount 5 is not in 0...4
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 2, edgeCount: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomBipartite(leftCount: 2, rightCount: 2, edgeCount: 5, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomBipartite(leftCount: 2, rightCount: 2, edgeCount: 5, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 2, rightCount: 2, edgeCount: 4, using: &generator)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
    }

    @Test("RG-273 negative side")
    func rg273() async {
        // UndirectedAdjacencyList<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &Xoshiro256StarStar(seed: 0)) → **trap**: leftCount -1 is negative
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Pseudograph<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = Multigraph<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyMatrix.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = AdjacencyList<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedPseudograph<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = DirectedMultigraph<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = StableDirectedGraph<Int>.randomBipartite(leftCount: -1, rightCount: 2, edgeCount: 0, using: &generator)
        }
        // Without the fault: accepted.
        var generator = Xoshiro256StarStar(seed: 0)
        let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 0, rightCount: 2, edgeCount: 0, using: &generator)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
    }

    @Test("RG-278 a negative degree")
    func rg278() async {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [1, 1, -1]) → **trap**: degreeSequence is not graphical
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [1, 1, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.havelHakimi(degreeSequence: [1, 1, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.havelHakimi(degreeSequence: [1, 1, -1])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [1, 1, 0])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
    }
}
