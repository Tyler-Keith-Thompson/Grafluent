// Preconditions (catalog MG-032 – MG-034, MG-039, MG-040, MG-075 – MG-077, MG-080, MG-179 – MG-192):
// each trapping call runs in a child process (exit test). The same setup then runs in this process
// one step short of the precondition, so the trap is the call's and not the setup's.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs preconditions", .tags(.precondition))
struct MultigraphPreconditionTests {
    @Test("MG-032 multigraph insert loop traps")
    func mg032() async {
        // Multigraph V [0]; E []; insert(edge: UndirectedEdge(0, 0)) → trap (self-loop in a Multigraph)
        await #expect(processExitsWith: .failure) {
            var graph = Multigraph<Int>(vertices: [0])
            graph.insert(edge: UndirectedEdge(0, 0))
        }
        // Without the call: the state it would apply to.
        let graph = Multigraph<Int>(vertices: [0])
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-033 multigraph insert loop with new vertex traps")
    func mg033() async {
        // Multigraph V []; E []; insert(edge: UndirectedEdge(5, 5)) → trap (self-loop in a Multigraph)
        await #expect(processExitsWith: .failure) {
            var graph = Multigraph<Int>(vertices: [] as [Int])
            graph.insert(edge: UndirectedEdge(5, 5))
        }
        // Without the call: the state it would apply to.
        let graph = Multigraph<Int>(vertices: [] as [Int])
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-034 directed multigraph insert loop traps")
    func mg034() async {
        // DirectedMultigraph V [0, 1]; E [0→1]; insert(edge: DirectedEdge(from: 1, to: 1)) → trap (self-loop in a DirectedMultigraph)
        await #expect(processExitsWith: .failure) {
            var graph = DirectedMultigraph<Int>(vertices: [0, 1])
            graph.insert(edge: DirectedEdge(from: 0, to: 1))
            graph.insert(edge: DirectedEdge(from: 1, to: 1))
        }
        // Without the call: the state it would apply to.
        var graph = DirectedMultigraph<Int>(vertices: [0, 1])
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
    }

    @Test("MG-039 degree of a non-vertex traps")
    func mg039() async {
        // Pseudograph V [0]; E []; degree(of: 1) → trap (not a vertex)
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [0])
            _ = graph.degree(of: 1)
        }
        // Without the call: the state it would apply to.
        let graph = Pseudograph<Int>(vertices: [0])
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-040 directed degree of a non-vertex traps")
    func mg040() async {
        // DirectedPseudograph V [0]; E []; degrees(1) → trap (not a vertex)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0])
            _ = graph.outDegree(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0])
            _ = graph.inDegree(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: [0])
            _ = graph.degree(of: 1)
        }
        // Without the call: the state it would apply to.
        let graph = DirectedPseudograph<Int>(vertices: [0])
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-075 out of range traps")
    func mg075() async {
        // Pseudograph V []; E [0–1]; remove(edgeAt: 1) → trap (edge position out of range)
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph<Int>(vertices: [] as [Int])
            graph.insert(edge: UndirectedEdge(0, 1))
            graph.remove(edgeAt: 1)
        }
        // Without the call: the state it would apply to.
        var graph = Pseudograph<Int>(vertices: [] as [Int])
        graph.insert(edge: UndirectedEdge(0, 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-076 negative traps")
    func mg076() async {
        // Pseudograph V []; E [0–1]; remove(edgeAt: -1) → trap (edge position out of range)
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph<Int>(vertices: [] as [Int])
            graph.insert(edge: UndirectedEdge(0, 1))
            graph.remove(edgeAt: -1)
        }
        // Without the call: the state it would apply to.
        var graph = Pseudograph<Int>(vertices: [] as [Int])
        graph.insert(edge: UndirectedEdge(0, 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
    }

    @Test("MG-077 empty graph traps")
    func mg077() async {
        // Pseudograph V [0]; E []; remove(edgeAt: 0) → trap (edge position out of range)
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph<Int>(vertices: [0])
            graph.remove(edgeAt: 0)
        }
        // Without the call: the state it would apply to.
        let graph = Pseudograph<Int>(vertices: [0])
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: 0)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 0)) == [] as [Int])
    }

    @Test("MG-080 directed out of range traps")
    func mg080() async {
        // DirectedPseudograph V []; E []; remove(edgeAt: 0) → trap (edge position out of range)
        await #expect(processExitsWith: .failure) {
            var graph = DirectedPseudograph<Int>(vertices: [] as [Int])
            graph.remove(edgeAt: 0)
        }
        // Without the call: the state it would apply to.
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int])
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-179 degree(of:) non-vertex")
    func mg179() async {
        // Pseudograph degree(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
            _ = graph.degree(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
        #expect(graph.degree(of: 1) == 1)
    }

    @Test("MG-180 neighbors(of:) non-vertex")
    func mg180() async {
        // Pseudograph neighbors(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
            _ = graph.neighbors(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.neighbors(of: 1)) == [0])
    }

    @Test("MG-181 incidentEdges(of:) non-vertex")
    func mg181() async {
        // Pseudograph incidentEdges(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
            _ = graph.incidentEdges(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
    }

    @Test("MG-182 vertexIndex(of:) non-vertex")
    func mg182() async {
        // Pseudograph vertexIndex(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
            _ = graph.vertexIndex(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
        #expect(graph.vertexIndex(of: 1) == 1)
    }

    @Test("MG-183 oppositeVertex non-endpoint")
    func mg183() async {
        // Pseudograph oppositeVertex(to: 2, acrossEdgeAt: 0) with E [0–1] → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: [2], edges: [UndirectedEdge(0, 1)])
            _ = graph.oppositeVertex(to: 2, acrossEdgeAt: 0)
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(vertices: [2], edges: [UndirectedEdge(0, 1)])
        #expect(graph.oppositeVertex(to: 1, acrossEdgeAt: 0) == 0)
    }

    @Test("MG-184 oppositeVertex position out of range")
    func mg184() async {
        // Pseudograph oppositeVertex(to: 0, acrossEdgeAt: 1) with E [0–1] → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
            _ = graph.oppositeVertex(to: 0, acrossEdgeAt: 1)
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
        #expect(graph.oppositeVertex(to: 0, acrossEdgeAt: 0) == 1)
    }

    @Test("MG-185 edges[p] out of range")
    func mg185() async {
        // Pseudograph edges[1] with E [0–1] → trap
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
            _ = graph.edges[1]
        }
        // One step short of the precondition: no trap.
        let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])
        #expect([graph.edges[0].u, graph.edges[0].v] == [0, 1])
    }

    @Test("MG-186 source(ofEdgeAt:) out of range")
    func mg186() async {
        // DirectedPseudograph source(ofEdgeAt: 1) with E [0→1] → trap
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.source(ofEdgeAt: 1)
        }
        // One step short of the precondition: no trap.
        let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.source(ofEdgeAt: 0) == 0)
        #expect(graph.target(ofEdgeAt: 0) == 1)
    }

    @Test("MG-187 successors(of:) non-vertex")
    func mg187() async {
        // DirectedPseudograph successors(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.successors(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.successors(of: 0)) == [1])
    }

    @Test("MG-188 predecessors(of:) non-vertex")
    func mg188() async {
        // DirectedPseudograph predecessors(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.predecessors(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.predecessors(of: 1)) == [0])
    }

    @Test("MG-189 inDegree(of:) non-vertex")
    func mg189() async {
        // DirectedPseudograph inDegree(of: 5) → trap
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.inDegree(of: 5)
        }
        // One step short of the precondition: no trap.
        let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.inDegree(of: 1) == 1)
    }

    @Test("MG-190 reserveCapacity negative vertices")
    func mg190() async {
        // Pseudograph reserveCapacity(vertexCount: -1, edgeCount: 0) → trap
        await #expect(processExitsWith: .failure) {
            var graph = Pseudograph<Int>()
            graph.reserveCapacity(vertexCount: -1, edgeCount: 0)
        }
        // One step short of the precondition: no trap.
        var graph = Pseudograph<Int>()
        graph.reserveCapacity(vertexCount: 0, edgeCount: 0)
        #expect(graph.vertexCount == 0)
    }

    @Test("MG-191 reserveCapacity negative edges")
    func mg191() async {
        // DirectedMultigraph reserveCapacity(vertexCount: 0, edgeCount: -1) → trap
        await #expect(processExitsWith: .failure) {
            var graph = DirectedMultigraph<Int>()
            graph.reserveCapacity(vertexCount: 0, edgeCount: -1)
        }
        // One step short of the precondition: no trap.
        var graph = DirectedMultigraph<Int>()
        graph.reserveCapacity(vertexCount: 0, edgeCount: 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("MG-192 DirectedMultigraph remove(edgeAt:) out of range")
    func mg192() async {
        // DirectedMultigraph remove(edgeAt: 2) with E [0→1, 0→1] → trap
        await #expect(processExitsWith: .failure) {
            var graph = DirectedMultigraph<Int>(vertices: [0, 1])
            graph.insert(edge: DirectedEdge(from: 0, to: 1))
            graph.insert(edge: DirectedEdge(from: 0, to: 1))
            graph.remove(edgeAt: 2)
        }
        // One step short of the precondition: no trap.
        var graph = DirectedMultigraph<Int>(vertices: [0, 1])
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph.remove(edgeAt: 1) == DirectedEdge(from: 0, to: 1))
    }
}
