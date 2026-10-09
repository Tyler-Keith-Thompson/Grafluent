// Preconditions, as exit tests. A vertex argument that is not a vertex traps: `triangleCount(of:)`
// (CQ-068) and `clusteringCoefficient(of:)` (CQ-466) on the graph, and every `of:` member of the
// `CoreNumbers` and `ClusteringCoefficients` values. An index out of range traps on every `ofIndex:`
// member (api.md: "Precondition: in range"), at n and at -1. A negative k traps on `kCore(_:)`
// (CQ-069) and `kShell(_:)`. Each exit test builds its inputs inside the closure. Case IDs (CQ-nnn)
// refer to the catalog; see README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Cliques preconditions", .tags(.precondition))
struct CliquePreconditionTests {
    @Test("CQ-068 U([0]).triangleCount(of: 1) traps: not a vertex")
    func triangleCountOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: [0]
            let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
            _ = graph.triangleCount(of: 1)
        }
    }

    @Test("CQ-069 U([0]).coreNumbers().kCore(-1) traps: k >= 0")
    func kCoreNegative() async {
        await #expect(processExitsWith: .failure) {
            // U: [0]
            let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
            _ = graph.coreNumbers().kCore(-1)
        }
    }

    @Test("CQ-069 also kShell(-1) traps, on a graph with edges")
    func kShellNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.coreNumbers().kShell(-1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            _ = graph.coreNumbers().kCore(-1)
        }
    }

    @Test("CQ-466 U(K(0..2), 2-3).clusteringCoefficient(of: 9) traps: not a vertex")
    func clusteringCoefficientOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: K(0..2), 2-3
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.clusteringCoefficient(of: 9)
        }
    }

    @Test("CQ-068 CQ-466 also on the values: coreNumber(of:), triangleCount(of:) and clusteringCoefficient(of:) trap on a non-vertex")
    func valueMembersOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.coreNumbers().coreNumber(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.clusteringCoefficients().triangleCount(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.clusteringCoefficients().clusteringCoefficient(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            // The empty graph: nothing is a vertex.
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            _ = graph.coreNumbers().coreNumber(of: 0)
        }
    }

    @Test("CQ-068 also through a view: digraph.undirected.triangleCount(of:) and clusteringCoefficient(of:) trap on a non-vertex")
    func viewOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let digraph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = digraph.undirected.triangleCount(of: 5)
        }
        await #expect(processExitsWith: .failure) {
            let digraph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = digraph.undirected.clusteringCoefficient(of: 5)
        }
    }

    @Test("coreNumber(ofIndex:) traps out of range: n and -1")
    func coreNumberOfIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.coreNumbers().coreNumber(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.coreNumbers().coreNumber(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            _ = graph.coreNumbers().coreNumber(ofIndex: 0)
        }
    }

    @Test("triangleCount(ofIndex:) and clusteringCoefficient(ofIndex:) trap out of range: n and -1")
    func clusteringOfIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.clusteringCoefficients().triangleCount(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.clusteringCoefficients().triangleCount(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.clusteringCoefficients().clusteringCoefficient(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.clusteringCoefficients().clusteringCoefficient(ofIndex: -1)
        }
    }
}
