// Parallel edges and self-loops, on the Multigraph test conformer (written order, repeats kept):
// they never change a partition, never become condensation edges, never stop a component being
// attracting, and are harmless repeated predecessors for dominators. Case IDs (CN-nn) refer to
// the catalog; see README.md.

import AdjacencyMatrixModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Parallel edges and self-loops", .tags(.selfLoops))
struct SelfLoopAndParallelEdgeTests {
    @Test("CN-73 parallel edges plus a 2-cycle and a self-loop")
    func parallelTwoCycleAndLoop() {
        let graph = Multigraph(edges: [(0, 1), (0, 1), (1, 0), (1, 1)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.stronglyConnectedComponents().map(Array.init) == [[0, 1]])
        let condensation = graph.condensation()
        #expect(condensation.graph.vertexCount == 1)
        #expect(condensation.graph.edgeCount == 0)
        #expect(graph.attractingComponents() == [[0, 1]])
        let tree = graph.dominatorTree(root: 0)
        #expect(tree.immediateDominator(of: 1) == 0)
        #expect(tree.immediateDominator(of: 0) == nil)
        let frontiers = graph.dominanceFrontiers(root: 0)
        #expect(frontiers[0].map { Array($0) } == [0])
        #expect(frontiers[1].map { Array($0) } == [0, 1])
    }

    @Test("CN-74 parallel edges only")
    func parallelOnly() {
        let graph = Multigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(graph.stronglyConnectedComponents().map(Array.init) == [[1], [0]])
        #expect(Array(graph.condensation().graph.edges) == [DirectedEdge(from: 1, to: 0)])
        #expect(graph.weaklyConnectedComponents().map(Array.init) == [[0, 1]])
        #expect(graph.attractingComponents() == [[1]])
        let frontiers = graph.dominanceFrontiers(root: 0)
        #expect(frontiers[0].map { Array($0) } == [])
        #expect(frontiers[1].map { Array($0) } == [])
        #expect(graph.dominatorTree(root: 0).immediateDominator(of: 1) == 0)
    }

    @Test("CN-75 repeated self-loops")
    func repeatedSelfLoops() {
        let graph = Multigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(graph.stronglyConnectedComponents().map(Array.init) == [[0], [1]])
        #expect(graph.weaklyConnectedComponents().map(Array.init) == [[0], [1]])
        #expect(graph.attractingComponents() == [[0], [1]])
        let frontiers = graph.dominanceFrontiers(root: 0)
        #expect(frontiers[0].map { Array($0) } == [0])
        #expect(frontiers[1] == nil)
    }

    @Test("CN-76 removing self-loops never changes the partition", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func withoutSelfLoops(_ fixture: DirectedFixture<Int>) {
        let loopless = fixture.edges.filter { !$0.isSelfLoop }
        let with = Multigraph(vertices: fixture.vertices, edges: fixture.edges)
        // Listing every vertex keeps the ones that only had self-loops, in the same order.
        let without = Multigraph(vertices: with.vertices, edges: loopless)
        #expect(without.vertices == with.vertices)
        #expect(with.stronglyConnectedComponents().map(Array.init) == without.stronglyConnectedComponents().map(Array.init))
        #expect(with.weaklyConnectedComponents().map(Array.init) == without.weaklyConnectedComponents().map(Array.init))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let looplessMatrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: loopless)
            #expect(matrix.stronglyConnectedComponents() == looplessMatrix.stronglyConnectedComponents())
        }
    }

    @Test("CN-76 but acyclicity does change: petgraphCsr1")
    func acyclicityDiffers() {
        let fixture = DirectedFixture<Int>.petgraphCsr1
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: fixture.edges)
        let loopless = AdjacencyMatrix(vertexCount: 3, edges: fixture.edges.filter { !$0.isSelfLoop })
        #expect(matrix.stronglyConnectedComponents() == loopless.stronglyConnectedComponents())
        #expect(!matrix.isAcyclic)
        #expect(loopless.isAcyclic)
    }
}
