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

    @Test("NG-143 an offset that is a multiple of n is a self-loop")
    func ng143() async {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 6]) → **trap**: offset 6 is a multiple of vertexCount 6: a self-loop
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.circulant(vertexCount: 6, offsets: [1, 6])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 5])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 6)
    }

    @Test("NG-144 no vertices")
    func ng144() async {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 0, offsets: []) → **trap**: a circulant graph needs at least 1 vertex, not 0
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.circulant(vertexCount: 0, offsets: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.circulant(vertexCount: 0, offsets: [])
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.circulant(vertexCount: 1, offsets: [])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-150 step 0")
    func ng150() async {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 0) → **trap**: step 0 is not in 1 ..< 5/2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 1)
        #expect(graph.vertexCount == 10 && graph.edgeCount == 15)
    }

    @Test("NG-151 step n/2 repeats the inner edges")
    func ng151() async {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 6, step: 3) → **trap**: step 3 is not in 1 ..< 6/2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 6, step: 2)
        #expect(graph.vertexCount == 12 && graph.edgeCount == 18)
    }

    @Test("NG-152 outer cycle of 2")
    func ng152() async {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 2, step: 1) → **trap**: a generalized Petersen graph needs an outer cycle of at least 3, not 2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 3, step: 1)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
    }

    @Test("NG-159 subsets of 0")
    func ng159() async {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 0) → **trap**: subsetSize 0 is not in 1...4
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.kneser(setSize: 4, subsetSize: 0)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 1)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
    }

    @Test("NG-160 subsets larger than the set")
    func ng160() async {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 3, subsetSize: 4) → **trap**: subsetSize 4 is not in 1...3
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.kneser(setSize: 3, subsetSize: 4)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.kneser(setSize: 3, subsetSize: 3)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-166 one clique")
    func ng166() async {
        // UndirectedAdjacencyList<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3) → **trap**: a windmill needs at least 2 cliques, not 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 6)
    }

    @Test("NG-167 cliques of 1")
    func ng167() async {
        // UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1) → **trap**: a windmill's cliques need at least 2 vertices, not 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
    }

    @Test("NG-174 negative order")
    func ng174() async {
        // UndirectedAdjacencyList<Int>.binomialTree(order: -1) → **trap**: order -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.binomialTree(order: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.binomialTree(order: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.binomialTree(order: 0)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-175 2^63 vertices overflow Int")
    func ng175() async {
        // UndirectedAdjacencyList<Int>.binomialTree(order: 63) → **trap**: 2^63 vertices overflow Int
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.binomialTree(order: 63)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.binomialTree(order: 63)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.binomialTree(order: 4)
        #expect(graph.vertexCount == 16 && graph.edgeCount == 15)
    }

    @Test("NG-183 branching factor 0")
    func ng183() async {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3) → **trap**: branchingFactor 0 < 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 3)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
    }

    @Test("NG-184 negative count")
    func ng184() async {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1) → **trap**: vertexCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-185 Tree.fullRaryTree(0): a tree is never empty")
    func ng185() async {
        // Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0) → **trap**: a Tree has at least one vertex
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)
        }
        // Without the fault: accepted.
        let graph = Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
    }

    @Test("NG-191 empty alphabet")
    func ng191() async {
        // AdjacencyList<Int>.deBruijn(alphabetSize: 0, wordLength: 2) → **trap**: alphabetSize 0 < 1
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.deBruijn(alphabetSize: 0, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.deBruijn(alphabetSize: 0, wordLength: 2)
        }
        // Without the fault: accepted.
        let graph = AdjacencyList<Int>.deBruijn(alphabetSize: 1, wordLength: 2)
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
    }

    @Test("NG-192 empty words")
    func ng192() async {
        // AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 0) → **trap**: wordLength 0 < 1
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.deBruijn(alphabetSize: 1, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.deBruijn(alphabetSize: 1, wordLength: 0)
        }
        // Without the fault: accepted.
        let graph = AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 1)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 4)
    }

    @Test("NG-197 one letter")
    func ng197() async {
        // CompressedSparseRow.kautz(alphabetSize: 1, wordLength: 2) → **trap**: alphabetSize 1 < 2
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.kautz(alphabetSize: 1, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.kautz(alphabetSize: 1, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.kautz(alphabetSize: 1, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.kautz(alphabetSize: 1, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.kautz(alphabetSize: 1, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.kautz(alphabetSize: 1, wordLength: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.kautz(alphabetSize: 1, wordLength: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.kautz(alphabetSize: 1, wordLength: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.kautz(alphabetSize: 1, wordLength: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.kautz(alphabetSize: 1, wordLength: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.kautz(alphabetSize: 1, wordLength: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.kautz(alphabetSize: 1, wordLength: 1)
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.kautz(alphabetSize: 2, wordLength: 2)
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
    }

    @Test("NG-198 empty words")
    func ng198() async {
        // CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 0) → **trap**: wordLength 0 < 1
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.kautz(alphabetSize: 3, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.kautz(alphabetSize: 3, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.kautz(alphabetSize: 3, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.kautz(alphabetSize: 3, wordLength: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.kautz(alphabetSize: 3, wordLength: 0)
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 1)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 6)
    }

    @Test("NG-206 negative rows")
    func ng206() async {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: -1, columnCount: 2) → **trap**: rowCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.triangularLattice(rowCount: -1, columnCount: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.triangularLattice(rowCount: 2, columnCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 0, columnCount: 2)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-214 negative columns")
    func ng214() async {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: -1) → **trap**: columnCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.hexagonalLattice(rowCount: -1, columnCount: 1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 0)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
    }

    @Test("NG-221 a cycle of 2")
    func ng221() async {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1) → **trap**: an LCF graph needs a cycle of at least 3 vertices, not 2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.lcf(vertexCount: 3, shifts: [1], repeatCount: 1)
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
    }

    @Test("NG-222 a shift that is a multiple of n is a self-loop")
    func ng222() async {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3) → **trap**: shift 6 is a multiple of vertexCount 6: a self-loop
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
    }

    @Test("NG-223 negative repeat count")
    func ng223() async {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1) → **trap**: repeatCount -1 is negative
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: 0)
        #expect(graph.vertexCount == 6 && graph.edgeCount == 6)
    }

    @Test("NG-236 C(70, 35) vertices overflow Int")
    func ng236() async {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 70, subsetSize: 35) → **trap**: vertex count overflows Int
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.kneser(setSize: 70, subsetSize: 35)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.kneser(setSize: 70, subsetSize: 69)
        #expect(graph.vertexCount == 70 && graph.edgeCount == 0)
    }

    @Test("NG-244 side 0")
    func ng244() async {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 0) → **trap**: a Margulis–Gabber–Galil graph needs a side of at least 1, not 0
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.margulisGabberGalil(side: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.margulisGabberGalil(side: -3)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.margulisGabberGalil(side: -3)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 2)
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
    }

    @Test("NG-252 1 is not prime")
    func ng252() async {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 1) → **trap**: a chordal cycle graph needs a prime, not 1
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.chordalCycle(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.chordalCycle(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.chordalCycle(prime: -7)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.chordalCycle(prime: -7)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.chordalCycle(prime: 5)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 5)
    }

    @Test("NG-253 9 is not prime")
    func ng253() async {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 9) → **trap**: a chordal cycle graph needs a prime, not 9
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.chordalCycle(prime: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.chordalCycle(prime: 91)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.chordalCycle(prime: 91)
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.chordalCycle(prime: 5)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
    }

    @Test("NG-262 undirected needs p ≡ 1 (mod 4): 7")
    func ng262() async {
        // UndirectedAdjacencyList<Int>.paley(prime: 7) → **trap**: the Paley graph is undirected only for a prime ≡ 1 (mod 4), not 7
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: 7)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: 7)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: 7)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: 3)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.paley(prime: 5)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 5)
    }

    @Test("NG-263 undirected needs p ≡ 1 (mod 4): 2")
    func ng263() async {
        // UndirectedAdjacencyList<Int>.paley(prime: 2) → **trap**: the Paley graph is undirected only for a prime ≡ 1 (mod 4), not 2
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: 2)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: 2)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.paley(prime: 13)
        #expect(graph.vertexCount == 13 && graph.edgeCount == 39)
    }

    @Test("NG-264 0 is not prime")
    func ng264() async {
        // UndirectedAdjacencyList<Int>.paley(prime: 0) → **trap**: a Paley graph needs a prime, not 0
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.paley(prime: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.paley(prime: -5)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.paley(prime: -5)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.paley(prime: 5)
        #expect(graph.vertexCount == 5 && graph.edgeCount == 5)
    }

    @Test("NG-265 15 is not prime")
    func ng265() async {
        // UndirectedAdjacencyList<Int>.paley(prime: 15) → **trap**: a Paley graph needs a prime, not 15
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.paley(prime: 15)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph<Int>.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = Multigraph<Int>.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.paley(prime: 25)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.paley(prime: 25)
        }
        // Without the fault: accepted.
        let graph = UndirectedAdjacencyList<Int>.paley(prime: 17)
        #expect(graph.vertexCount == 17 && graph.edgeCount == 68)
    }

    @Test("NG-266 directed: 1 is not prime")
    func ng266() async {
        // CompressedSparseRow.paley(prime: 1) → **trap**: a Paley graph needs a prime, not 1
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.paley(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.paley(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.paley(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.paley(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.paley(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.paley(prime: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow.paley(prime: 49)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyMatrix.paley(prime: 49)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList<Int>.paley(prime: 49)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedPseudograph<Int>.paley(prime: 49)
        }
        await #expect(processExitsWith: .failure) {
            _ = DirectedMultigraph<Int>.paley(prime: 49)
        }
        await #expect(processExitsWith: .failure) {
            _ = StableDirectedGraph<Int>.paley(prime: 49)
        }
        // Without the fault: accepted.
        let graph = CompressedSparseRow.paley(prime: 7)
        #expect(graph.vertexCount == 7 && graph.edgeCount == 21)
    }
}
