// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test), on every
// conformer the rule covers. A valid neighbour of the call then runs in this process.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing
import Trees

@Suite("NamedGraphs preconditions", .tags(.precondition))
struct NamedGraphPreconditionTests {
    @Test("NG-010 negative count")
    func ng010() async {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: -1) → **trap**: vertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.complete(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.complete(vertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.complete(vertexCount: 0)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-011 n(n − 1) overflows Int")
    func ng011() async {
        // CompressedSparseRow.complete(vertexCount: 1 << 32) → **trap**: edge count overflows Int
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.complete(vertexCount: 1 << 32)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.complete(vertexCount: 1 << 32)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.complete(vertexCount: 1 << 32)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.complete(vertexCount: 1 << 32)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.complete(vertexCount: 1 << 32)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.complete(vertexCount: 1 << 32)
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.complete(vertexCount: 3)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 6)
    }

    @Test("NG-020 negative side")
    func ng020() async {
        // UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: -1) → **trap**: rightCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.completeBipartite(leftCount: -1, rightCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 0)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
    }

    @Test("NG-028 Tree.path(0): a tree is never empty")
    func ng028() async {
        // Tree<Int>.path(vertexCount: 0) → **trap**: a Tree has at least one vertex
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.path(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.path(vertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = Tree<Int>.path(vertexCount: 1)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-029 negative count")
    func ng029() async {
        // UndirectedAdjacencyList<Int>.path(vertexCount: -2) → **trap**: vertexCount -2 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.path(vertexCount: -2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.path(vertexCount: -2)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.path(vertexCount: 0)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-034 C0 is not a simple cycle")
    func ng034() async {
        // UndirectedAdjacencyList<Int>.cycle(vertexCount: 0) → **trap**: a cycle needs at least 3 vertices, not 0
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.cycle(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.cycle(vertexCount: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("NG-035 C1 is not a simple cycle")
    func ng035() async {
        // UndirectedAdjacencyList<Int>.cycle(vertexCount: 1) → **trap**: a cycle needs at least 3 vertices, not 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.cycle(vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.cycle(vertexCount: 1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("NG-036 C2 is not a simple cycle")
    func ng036() async {
        // UndirectedAdjacencyList<Int>.cycle(vertexCount: 2) → **trap**: a cycle needs at least 3 vertices, not 2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.cycle(vertexCount: 2)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("NG-037 C2 directed is trapped too (one rule for every type)")
    func ng037() async {
        // CompressedSparseRow.cycle(vertexCount: 2) → **trap**: a cycle needs at least 3 vertices, not 2
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.cycle(vertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.cycle(vertexCount: 2)
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.cycle(vertexCount: 3)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("NG-043 no hub")
    func ng043() async {
        // UndirectedAdjacencyList<Int>.star(vertexCount: 0) → **trap**: a star needs its hub: vertexCount 0 < 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.star(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.star(vertexCount: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.star(vertexCount: 1)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-050 W0: rim shorter than 3")
    func ng050() async {
        // UndirectedAdjacencyList<Int>.wheel(vertexCount: 0) → **trap**: a wheel needs a hub and a rim of at least 3: vertexCount 0 < 4
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.wheel(vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.wheel(vertexCount: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.wheel(vertexCount: 4)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("NG-051 W3: rim shorter than 3")
    func ng051() async {
        // UndirectedAdjacencyList<Int>.wheel(vertexCount: 3) → **trap**: a wheel needs a hub and a rim of at least 3: vertexCount 3 < 4
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.wheel(vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.wheel(vertexCount: 3)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.wheel(vertexCount: 4)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("NG-066 no dimensions")
    func ng066() async {
        // UndirectedAdjacencyList<Int>.grid(dimensions: []) → **trap**: grid needs at least one dimension
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.grid(dimensions: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.grid(dimensions: [], periodic: true)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.grid(dimensions: [], periodic: true)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.grid(dimensions: [], periodic: true)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.grid(dimensions: [1])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-067 negative dimension")
    func ng067() async {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [3, -1]) → **trap**: dimension -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.grid(dimensions: [3, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.grid(dimensions: [3, -1])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.grid(dimensions: [3, 0])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-068 vertex count overflows Int")
    func ng068() async {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [1 << 32, 1 << 32]) → **trap**: vertex count overflows Int
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.grid(dimensions: [1 << 32, 1 << 32])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.grid(dimensions: [1 << 32, 0])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-075 negative dimension")
    func ng075() async {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: -1) → **trap**: dimension -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.hypercube(dimension: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.hypercube(dimension: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.hypercube(dimension: 0)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-076 2^63 vertices overflow Int")
    func ng076() async {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: 63) → **trap**: 2^63 vertices overflow Int
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.hypercube(dimension: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.hypercube(dimension: 63)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.hypercube(dimension: 4)
        #expect(graph.vertexCount == 16 && graph.edgeCount == 32)
    }

    @Test("NG-083 negative count")
    func ng083() async {
        // UndirectedAdjacencyList<Int>.empty(vertexCount: -1) → **trap**: vertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.empty(vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.empty(vertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.empty(vertexCount: 0)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-095 negative count")
    func ng095() async {
        // UndirectedAdjacencyList<Int>.ladder(rungCount: -1) → **trap**: rungCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.ladder(rungCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.ladder(rungCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.ladder(rungCount: 0)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-099 CL2: the rails are not cycles (NetworkX returns C4)")
    func ng099() async {
        // UndirectedAdjacencyList<Int>.circularLadder(rungCount: 2) → **trap**: a circular ladder needs at least 3 rungs, not 2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.circularLadder(rungCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.circularLadder(rungCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.circularLadder(rungCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.circularLadder(rungCount: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.circularLadder(rungCount: 3)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
    }

    @Test("NG-104 clique of 1")
    func ng104() async {
        // UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2) → **trap**: a barbell needs a clique of at least 2 vertices, not 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 2)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 5)
    }

    @Test("NG-105 negative path")
    func ng105() async {
        // UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1) → **trap**: pathVertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 0)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 7)
    }

    @Test("NG-110 clique of 1")
    func ng110() async {
        // UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2) → **trap**: a lollipop needs a clique of at least 2 vertices, not 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 2)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
    }

    @Test("NG-111 negative path")
    func ng111() async {
        // UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1) → **trap**: pathVertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 0)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("NG-117 negative part size")
    func ng117() async {
        // UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, -1]) → **trap**: part size -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.completeMultipartite(partSizes: [2, -1])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.completeMultipartite(partSizes: [2, -1])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, 0])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
    }

    @Test("NG-118 edge count overflows Int")
    func ng118() async {
        // UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32]) → **trap**: edge count overflows Int
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1 << 4, 1 << 4])
        #expect(graph.vertexCount == 32 && graph.edgeCount == 256)
    }

    @Test("NG-124 no parts")
    func ng124() async {
        // UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 0) → **trap**: a Turán graph needs 1 ≤ partCount ≤ vertexCount, not 0 and 5
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.turan(vertexCount: 5, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.turan(vertexCount: 5, partCount: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 1)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 0)
    }

    @Test("NG-125 more parts than vertices")
    func ng125() async {
        // UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 6) → **trap**: a Turán graph needs 1 ≤ partCount ≤ vertexCount, not 6 and 5
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.turan(vertexCount: 5, partCount: 6)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.turan(vertexCount: 0, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.turan(vertexCount: 0, partCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.turan(vertexCount: 0, partCount: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 5)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
    }

    @Test("NG-133 negative height")
    func ng133() async {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: -1) → **trap**: height -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.balancedTree(branchingFactor: 2, height: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 0)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-134 negative branching factor")
    func ng134() async {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: -1, height: 2) → **trap**: branchingFactor -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.balancedTree(branchingFactor: -1, height: 2)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 0, height: 2)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-135 vertex count overflows Int")
    func ng135() async {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 63) → **trap**: vertex count overflows Int
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.balancedTree(branchingFactor: 2, height: 63)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 1, height: 63)
        #expect(graph.vertexCount == 64 && graph.edgeCount == 63)
    }
}
