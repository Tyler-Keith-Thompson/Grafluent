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
}
