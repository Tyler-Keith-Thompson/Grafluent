// sugiyamaLayout (catalog DR-064 – DR-163): Eades–Lin–Smyth (`Cycles.feedbackArcSet()`), minimum-span
// layering, barycenter crossing reduction, Brandes–Köpf. Where the optimal layering is unique,
// each row checks the whole layered drawing: layers, layer count, crossings, positions, the bends
// of every edge, reversed edges, and feedbackArcSet(). Exact.
// Generated from cases.md by swiftgen.py; see README.md.

import Cycles
import DirectedAcyclicGraphModule
import GraphDrawing
import GraphProtocols
import Multigraphs
import Testing

@Suite("sugiyamaLayout")
struct SugiyamaLayoutTests {
    @Test("DR-064 empty graph: layers")
    func dr064() {
        // D: n=0;; sugiyamaLayout() layer(of:) in vertices order → []
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 0, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 0) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 0))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [] as [Int])
        #expect(layered.layerCount == 0)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [] as [SIMD2<Double>])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-065 empty graph: crossings")
    func dr065() {
        // D: n=0;; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 0, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 0) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 0))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [] as [Int])
        #expect(layered.layerCount == 0)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [] as [SIMD2<Double>])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-066 empty graph: positions")
    func dr066() {
        // D: n=0;; sugiyamaLayout().drawing.positions → []
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 0, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 0) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 0))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [] as [Int])
        #expect(layered.layerCount == 0)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [] as [SIMD2<Double>])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-067 one vertex: layers")
    func dr067() {
        // D: n=1;; sugiyamaLayout() layer(of:) in vertices order → [0]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 1, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 1))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0])
        #expect(layered.layerCount == 1)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-068 one vertex: crossings")
    func dr068() {
        // D: n=1;; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 1, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 1))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0])
        #expect(layered.layerCount == 1)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-069 one vertex: positions")
    func dr069() {
        // D: n=1;; sugiyamaLayout().drawing.positions → [(0.0, 0.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 1, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 1))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0])
        #expect(layered.layerCount == 1)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-070 isolated vertices share layer 0, in vertices order: layers")
    func dr070() {
        // D: n=3;; sugiyamaLayout() layer(of:) in vertices order → [0, 0, 0]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0])
        #expect(layered.layerCount == 1)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-071 isolated vertices share layer 0, in vertices order: crossings")
    func dr071() {
        // D: n=3;; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0])
        #expect(layered.layerCount == 1)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-072 isolated vertices share layer 0, in vertices order: positions")
    func dr072() {
        // D: n=3;; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 0)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0])
        #expect(layered.layerCount == 1)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
    }

    @Test("DR-073 one arc: layers")
    func dr073() {
        // D: 0>1; sugiyamaLayout() layer(of:) in vertices order → [0, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 1)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-074 one arc: crossings")
    func dr074() {
        // D: 0>1; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 1)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-075 one arc: positions")
    func dr075() {
        // D: 0>1; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (0.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 1)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-076 path: layers")
    func dr076() {
        // D: P(0,1,2,3); sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-077 path: crossings")
    func dr077() {
        // D: P(0,1,2,3); sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-078 path: positions")
    func dr078() {
        // D: P(0,1,2,3); sugiyamaLayout().drawing.positions → [(0.0, 0.0), (0.0, 1.0), (0.0, 2.0), (0.0, 3.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-079 diamond: layers")
    func dr079() {
        // D: 0>1, 0>2, 1>3, 2>3; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 1, 2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-080 diamond: crossings")
    func dr080() {
        // D: 0>1, 0>2, 1>3, 2>3; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-081 diamond: positions")
    func dr081() {
        // D: 0>1, 0>2, 1>3, 2>3; sugiyamaLayout().drawing.positions → [(0.5, 0.0), (0.0, 1.0), (1.0, 1.0), (0.5, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-082 diamond with a long arc 0>3 (one bend): layers")
    func dr082() {
        // D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 1, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(2.0, 1.0)],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-083 diamond with a long arc 0>3 (one bend): crossings")
    func dr083() {
        // D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(2.0, 1.0)],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-084 diamond with a long arc 0>3 (one bend): positions")
    func dr084() {
        // D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4; sugiyamaLayout().drawing.positions → [(1.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 2.0), (1.0, 3.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(2.0, 1.0)],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-085 diamond with a long arc 0>3 (one bend): bends")
    func dr085() {
        // D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4; sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 4: [(2.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(2.0, 1.0)],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-086 long arc over two layers (two bends): layers")
    func dr086() {
        // D: P(0,1,2,3), 0>3; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0), SIMD2(1.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-087 long arc over two layers (two bends): crossings")
    func dr087() {
        // D: P(0,1,2,3), 0>3; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0), SIMD2(1.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-088 long arc over two layers (two bends): positions")
    func dr088() {
        // D: P(0,1,2,3), 0>3; sugiyamaLayout().drawing.positions → [(0.5, 0.0), (0.0, 1.0), (0.0, 2.0), (0.5, 3.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0), SIMD2(1.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-089 long arc over two layers (two bends): bends")
    func dr089() {
        // D: P(0,1,2,3), 0>3; sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 3: [(1.0, 1.0), (1.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0), SIMD2(1.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-090 two sources, one sink: layers")
    func dr090() {
        // D: 0>2, 1>2; sugiyamaLayout() layer(of:) in vertices order → [0, 0, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.5, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-091 two sources, one sink: crossings")
    func dr091() {
        // D: 0>2, 1>2; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.5, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-092 two sources, one sink: positions")
    func dr092() {
        // D: 0>2, 1>2; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.5, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-093 crossing in the initial order is removed: layers")
    func dr093() {
        // D: 0>3, 1>2; sugiyamaLayout() layer(of:) in vertices order → [0, 0, 1, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-094 crossing in the initial order is removed: crossings")
    func dr094() {
        // D: 0>3, 1>2; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-095 crossing in the initial order is removed: positions")
    func dr095() {
        // D: 0>3, 1>2; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-096 K2,2 between layers: one crossing is unavoidable: layers")
    func dr096() {
        // D: 0>2, 0>3, 1>2, 1>3; sugiyamaLayout() layer(of:) in vertices order → [0, 0, 1, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 1)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-097 K2,2 between layers: one crossing is unavoidable: crossings")
    func dr097() {
        // D: 0>2, 0>3, 1>2, 1>3; sugiyamaLayout().crossingCount → #1
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 1)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-098 K2,2 between layers: one crossing is unavoidable: positions")
    func dr098() {
        // D: 0>2, 0>3, 1>2, 1>3; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 1)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-099 K3,3 between layers: 9 crossings at least: layers")
    func dr099() {
        // D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5; sugiyamaLayout() layer(of:) in vertices order → [0, 0, 0, 1, 1, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 2, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 9)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 1, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 9)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-100 K3,3 between layers: 9 crossings at least: crossings")
    func dr100() {
        // D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5; sugiyamaLayout().crossingCount → #9
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 2, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 9)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 1, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 9)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-101 K3,3 between layers: 9 crossings at least: positions")
    func dr101() {
        // D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (0.0, 1.0), (1.0, 1.0), (2.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4),
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 1, to: 5),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 2, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 9)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 1, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 9)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-102 binary out-tree: layers")
    func dr102() {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 1, 2, 2, 2, 2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 7, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 2, to: 5), DirectedEdge(from: 2, to: 6)])
        #expect(Array(graph.vertices) == Array(0 ..< 7) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 7))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 2, 2, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.5, 1.0), SIMD2(2.5, 1.0), SIMD2(0.0, 2.0), SIMD2(1.0, 2.0), SIMD2(2.0, 2.0),
            SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-103 binary out-tree: crossings")
    func dr103() {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 7, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 2, to: 5), DirectedEdge(from: 2, to: 6)])
        #expect(Array(graph.vertices) == Array(0 ..< 7) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 7))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 2, 2, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.5, 1.0), SIMD2(2.5, 1.0), SIMD2(0.0, 2.0), SIMD2(1.0, 2.0), SIMD2(2.0, 2.0),
            SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-104 binary out-tree: positions")
    func dr104() {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6; sugiyamaLayout().drawing.positions → [(1.5, 0.0), (0.5, 1.0), (2.5, 1.0), (0.0, 2.0), (1.0, 2.0), (2.0, 2.0), (3.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 7, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 2, to: 5), DirectedEdge(from: 2, to: 6)])
        #expect(Array(graph.vertices) == Array(0 ..< 7) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 7))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 1, 2, 2, 2, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.5, 1.0), SIMD2(2.5, 1.0), SIMD2(0.0, 2.0), SIMD2(1.0, 2.0), SIMD2(2.0, 2.0),
            SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-105 three layers, crossings in both gaps: layers")
    func dr105() {
        // D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7; sugiyamaLayout() layer(of:) in vertices order → [0, 0, 0, 1, 1, 1, 2, 2, 2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 9, edges: [DirectedEdge(from: 0, to: 4), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 5), DirectedEdge(from: 3, to: 8), DirectedEdge(from: 4, to: 6), DirectedEdge(from: 5, to: 7)])
        #expect(Array(graph.vertices) == Array(0 ..< 9) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 9))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0), SIMD2(2.0, 1.0),
            SIMD2(0.0, 2.0), SIMD2(2.0, 2.0), SIMD2(1.0, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-106 three layers, crossings in both gaps: crossings")
    func dr106() {
        // D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 9, edges: [DirectedEdge(from: 0, to: 4), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 5), DirectedEdge(from: 3, to: 8), DirectedEdge(from: 4, to: 6), DirectedEdge(from: 5, to: 7)])
        #expect(Array(graph.vertices) == Array(0 ..< 9) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 9))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0), SIMD2(2.0, 1.0),
            SIMD2(0.0, 2.0), SIMD2(2.0, 2.0), SIMD2(1.0, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-107 three layers, crossings in both gaps: positions")
    func dr107() {
        // D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (1.0, 1.0), (0.0, 1.0), (2.0, 1.0), (0.0, 2.0), (2.0, 2.0), (1.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 9, edges: [DirectedEdge(from: 0, to: 4), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 2, to: 5), DirectedEdge(from: 3, to: 8), DirectedEdge(from: 4, to: 6), DirectedEdge(from: 5, to: 7)])
        #expect(Array(graph.vertices) == Array(0 ..< 9) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 9))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 1, 1, 1, 2, 2, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0), SIMD2(2.0, 1.0),
            SIMD2(0.0, 2.0), SIMD2(2.0, 2.0), SIMD2(1.0, 2.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-108 parallel arcs: two edges, no bends: layers")
    func dr108() {
        // D: 0>1, 0>1; sugiyamaLayout() layer(of:) in vertices order → [0, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-109 parallel arcs: two edges, no bends: crossings")
    func dr109() {
        // D: 0>1, 0>1; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-110 parallel arcs: two edges, no bends: positions")
    func dr110() {
        // D: 0>1, 0>1; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (0.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-111 self-loop ignored in layering, no bends: layers")
    func dr111() {
        // D: 0>0, 0>1; sugiyamaLayout() layer(of:) in vertices order → [0, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [0])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-112 self-loop ignored in layering, no bends: crossings")
    func dr112() {
        // D: 0>0, 0>1; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [0])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-113 self-loop ignored in layering, no bends: positions")
    func dr113() {
        // D: 0>0, 0>1; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (0.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [0])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-114 2-cycle: one arc reversed: reversed edges (Eades–Lin–Smyth)")
    func dr114() {
        // D: 0>1, 1>0; sugiyamaLayout().reversedEdges → [1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [1])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [1])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-115 2-cycle: one arc reversed: layers")
    func dr115() {
        // D: 0>1, 1>0; sugiyamaLayout() layer(of:) in vertices order → [0, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [1])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [1])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-116 2-cycle: one arc reversed: crossings")
    func dr116() {
        // D: 0>1, 1>0; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [1])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [1])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-117 2-cycle: one arc reversed: positions")
    func dr117() {
        // D: 0>1, 1>0; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (0.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [1])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 2))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
        #expect(layered.reversedEdges == [1])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-118 3-cycle: one arc reversed: reversed edges (Eades–Lin–Smyth)")
    func dr118() {
        // D: C(0,1,2); sugiyamaLayout().reversedEdges → [2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-119 3-cycle: one arc reversed: layers")
    func dr119() {
        // D: C(0,1,2); sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-120 3-cycle: one arc reversed: crossings")
    func dr120() {
        // D: C(0,1,2); sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-121 3-cycle: one arc reversed: positions")
    func dr121() {
        // D: C(0,1,2); sugiyamaLayout().drawing.positions → [(0.5, 0.0), (0.0, 1.0), (0.5, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-122 3-cycle: one arc reversed: bends")
    func dr122() {
        // D: C(0,1,2); sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 2: [(1.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 3))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-123 cycle with a tail: reversed edges (Eades–Lin–Smyth)")
    func dr123() {
        // D: C(0,1,2,3), 3>4, 4>5; sugiyamaLayout().reversedEdges → [3]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [3])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3, 4, 5])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0), SIMD2(0.5, 4.0), SIMD2(0.5, 5.0)])
        #expect(layered.reversedEdges == [3])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 2.0), SIMD2(1.0, 1.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-124 cycle with a tail: layers")
    func dr124() {
        // D: C(0,1,2,3), 3>4, 4>5; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2, 3, 4, 5]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [3])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3, 4, 5])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0), SIMD2(0.5, 4.0), SIMD2(0.5, 5.0)])
        #expect(layered.reversedEdges == [3])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 2.0), SIMD2(1.0, 1.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-125 cycle with a tail: crossings")
    func dr125() {
        // D: C(0,1,2,3), 3>4, 4>5; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [3])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3, 4, 5])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0), SIMD2(0.5, 4.0), SIMD2(0.5, 5.0)])
        #expect(layered.reversedEdges == [3])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 2.0), SIMD2(1.0, 1.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-126 cycle with a tail: positions")
    func dr126() {
        // D: C(0,1,2,3), 3>4, 4>5; sugiyamaLayout().drawing.positions → [(0.5, 0.0), (0.0, 1.0), (0.0, 2.0), (0.5, 3.0), (0.5, 4.0), (0.5, 5.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [3])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3, 4, 5])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0), SIMD2(0.5, 4.0), SIMD2(0.5, 5.0)])
        #expect(layered.reversedEdges == [3])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 2.0), SIMD2(1.0, 1.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-127 cycle with a tail: bends")
    func dr127() {
        // D: C(0,1,2,3), 3>4, 4>5; sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 3: [(1.0, 2.0), (1.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 6, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [3])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 6))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3, 4, 5])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.5, 3.0), SIMD2(0.5, 4.0), SIMD2(0.5, 5.0)])
        #expect(layered.reversedEdges == [3])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 2.0), SIMD2(1.0, 1.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-128 two 3-cycles sharing a vertex: reversed edges (Eades–Lin–Smyth)")
    func dr128() {
        // D: C(0,1,2), C(0,3,4); sugiyamaLayout().reversedEdges → [2, 5]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2, 5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0), SIMD2(2.0, 1.0), SIMD2(2.5, 2.0)])
        #expect(layered.reversedEdges == [2, 5])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [SIMD2(3.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-129 two 3-cycles sharing a vertex: layers")
    func dr129() {
        // D: C(0,1,2), C(0,3,4); sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2, 1, 2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2, 5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0), SIMD2(2.0, 1.0), SIMD2(2.5, 2.0)])
        #expect(layered.reversedEdges == [2, 5])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [SIMD2(3.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-130 two 3-cycles sharing a vertex: crossings")
    func dr130() {
        // D: C(0,1,2), C(0,3,4); sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2, 5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0), SIMD2(2.0, 1.0), SIMD2(2.5, 2.0)])
        #expect(layered.reversedEdges == [2, 5])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [SIMD2(3.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-131 two 3-cycles sharing a vertex: positions")
    func dr131() {
        // D: C(0,1,2), C(0,3,4); sugiyamaLayout().drawing.positions → [(1.5, 0.0), (0.0, 1.0), (0.5, 2.0), (2.0, 1.0), (2.5, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2, 5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0), SIMD2(2.0, 1.0), SIMD2(2.5, 2.0)])
        #expect(layered.reversedEdges == [2, 5])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [SIMD2(3.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-132 two 3-cycles sharing a vertex: bends")
    func dr132() {
        // D: C(0,1,2), C(0,3,4); sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 2: [(1.0, 1.0)]; 5: [(3.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2, 5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 1, 2])
        #expect(layered.layerCount == 3)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.5, 0.0), SIMD2(0.0, 1.0), SIMD2(0.5, 2.0), SIMD2(2.0, 1.0), SIMD2(2.5, 2.0)])
        #expect(layered.reversedEdges == [2, 5])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [SIMD2(3.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-133 tournament on 4 vertices with one cycle: reversed edges (Eades–Lin–Smyth)")
    func dr133() {
        // D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3; sugiyamaLayout().reversedEdges → [2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-134 tournament on 4 vertices with one cycle: layers")
    func dr134() {
        // D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-135 tournament on 4 vertices with one cycle: crossings")
    func dr135() {
        // D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-136 tournament on 4 vertices with one cycle: positions")
    func dr136() {
        // D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3; sugiyamaLayout().drawing.positions → [(1.0, 0.0), (0.0, 1.0), (1.0, 2.0), (1.0, 3.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-137 tournament on 4 vertices with one cycle: bends")
    func dr137() {
        // D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3; sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 2: [(1.0, 1.0)]; 3: [(2.0, 1.0), (2.0, 2.0)]; 4: [(0.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [2])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [2])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-138 transitive tournament on 4: layers")
    func dr138() {
        // D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)], [] as [SIMD2<Double>],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-139 transitive tournament on 4: crossings")
    func dr139() {
        // D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)], [] as [SIMD2<Double>],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-140 transitive tournament on 4: positions")
    func dr140() {
        // D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3; sugiyamaLayout().drawing.positions → [(1.0, 0.0), (0.0, 1.0), (1.0, 2.0), (1.0, 3.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)], [] as [SIMD2<Double>],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-141 transitive tournament on 4: bends")
    func dr141() {
        // D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3; sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 1: [(1.0, 1.0)]; 2: [(2.0, 1.0), (2.0, 2.0)]; 4: [(0.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 2, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)], [] as [SIMD2<Double>],
            [SIMD2(0.0, 2.0)], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-142 arcs given against vertex order: layers")
    func dr142() {
        // D: n=4; 3>2, 2>1, 1>0; sugiyamaLayout() layer(of:) in vertices order → [3, 2, 1, 0]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [3, 2, 1, 0])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 3.0), SIMD2(0.0, 2.0), SIMD2(0.0, 1.0), SIMD2(0.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-143 arcs given against vertex order: crossings")
    func dr143() {
        // D: n=4; 3>2, 2>1, 1>0; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [3, 2, 1, 0])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 3.0), SIMD2(0.0, 2.0), SIMD2(0.0, 1.0), SIMD2(0.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-144 arcs given against vertex order: positions")
    func dr144() {
        // D: n=4; 3>2, 2>1, 1>0; sugiyamaLayout().drawing.positions → [(0.0, 3.0), (0.0, 2.0), (0.0, 1.0), (0.0, 0.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 1),
            DirectedEdge(from: 1, to: 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [3, 2, 1, 0])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 3.0), SIMD2(0.0, 2.0), SIMD2(0.0, 1.0), SIMD2(0.0, 0.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-145 two components: layers")
    func dr145() {
        // D: 0>1, 2>3, 2>4; sugiyamaLayout() layer(of:) in vertices order → [0, 1, 0, 1, 1]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.5, 0.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-146 two components: crossings")
    func dr146() {
        // D: 0>1, 2>3, 2>4; sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.5, 0.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-147 two components: positions")
    func dr147() {
        // D: 0>1, 2>3, 2>4; sugiyamaLayout().drawing.positions → [(0.0, 0.0), (0.0, 1.0), (1.5, 0.0), (1.0, 1.0), (2.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 5))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 1, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.5, 0.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-148 random DAG, 12 vertices, 18 arcs: layers")
    func dr148() {
        // D: lcgdag(12,18,1); sugiyamaLayout() layer(of:) in vertices order → [0, 0, 0, 2, 1, 1, 1, 1, 1, 2, 3, 4]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 12, edges: [DirectedEdge(from: 2, to: 9), DirectedEdge(from: 0, to: 6),
            DirectedEdge(from: 6, to: 11), DirectedEdge(from: 2, to: 10), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 3, to: 10),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 1, to: 7),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 0, to: 8), DirectedEdge(from: 4, to: 9),
            DirectedEdge(from: 10, to: 11), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 6, to: 10)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 18)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 12))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 2, 1, 1, 1, 1, 1, 2, 3, 4])
        #expect(layered.layerCount == 5)
        #expect(layered.crossingCount == 5)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(4.5, 0.0), SIMD2(1.0, 2.0), SIMD2(4.5, 1.0), SIMD2(0.0, 1.0),
            SIMD2(1.5, 1.0), SIMD2(2.5, 1.0), SIMD2(3.5, 1.0), SIMD2(4.5, 2.0), SIMD2(4.0, 3.0), SIMD2(4.0, 4.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[SIMD2(5.5, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [SIMD2(6.5, 1.0), SIMD2(6.5, 2.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [SIMD2(2.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-149 random DAG, 12 vertices, 18 arcs: crossings")
    func dr149() {
        // D: lcgdag(12,18,1); sugiyamaLayout().crossingCount → #5
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 12, edges: [DirectedEdge(from: 2, to: 9), DirectedEdge(from: 0, to: 6),
            DirectedEdge(from: 6, to: 11), DirectedEdge(from: 2, to: 10), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 3, to: 10),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 1, to: 7),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 0, to: 8), DirectedEdge(from: 4, to: 9),
            DirectedEdge(from: 10, to: 11), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 6, to: 10)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 18)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 12))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 2, 1, 1, 1, 1, 1, 2, 3, 4])
        #expect(layered.layerCount == 5)
        #expect(layered.crossingCount == 5)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(4.5, 0.0), SIMD2(1.0, 2.0), SIMD2(4.5, 1.0), SIMD2(0.0, 1.0),
            SIMD2(1.5, 1.0), SIMD2(2.5, 1.0), SIMD2(3.5, 1.0), SIMD2(4.5, 2.0), SIMD2(4.0, 3.0), SIMD2(4.0, 4.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[SIMD2(5.5, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [SIMD2(6.5, 1.0), SIMD2(6.5, 2.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [SIMD2(2.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-150 random DAG, 12 vertices, 18 arcs: positions")
    func dr150() {
        // D: lcgdag(12,18,1); sugiyamaLayout().drawing.positions → [(1.0, 0.0), (2.0, 0.0), (4.5, 0.0), (1.0, 2.0), (4.5, 1.0), (0.0, 1.0), (1.5, 1.0), (2.5, 1.0), (3.5, 1.0), (4.5, 2.0), (4.0, 3.0), (4.0, 4.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 12, edges: [DirectedEdge(from: 2, to: 9), DirectedEdge(from: 0, to: 6),
            DirectedEdge(from: 6, to: 11), DirectedEdge(from: 2, to: 10), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 3, to: 10),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 1, to: 7),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 0, to: 8), DirectedEdge(from: 4, to: 9),
            DirectedEdge(from: 10, to: 11), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 6, to: 10)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 18)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 12))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 2, 1, 1, 1, 1, 1, 2, 3, 4])
        #expect(layered.layerCount == 5)
        #expect(layered.crossingCount == 5)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(4.5, 0.0), SIMD2(1.0, 2.0), SIMD2(4.5, 1.0), SIMD2(0.0, 1.0),
            SIMD2(1.5, 1.0), SIMD2(2.5, 1.0), SIMD2(3.5, 1.0), SIMD2(4.5, 2.0), SIMD2(4.0, 3.0), SIMD2(4.0, 4.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[SIMD2(5.5, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [SIMD2(6.5, 1.0), SIMD2(6.5, 2.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [SIMD2(2.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-151 random DAG, 12 vertices, 18 arcs: bends")
    func dr151() {
        // D: lcgdag(12,18,1); sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 0: [(5.5, 1.0)]; 2: [(0.0, 2.0), (0.0, 3.0)]; 3: [(6.5, 1.0), (6.5, 2.0)]; 17: [(2.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 12, edges: [DirectedEdge(from: 2, to: 9), DirectedEdge(from: 0, to: 6),
            DirectedEdge(from: 6, to: 11), DirectedEdge(from: 2, to: 10), DirectedEdge(from: 9, to: 10), DirectedEdge(from: 3, to: 10),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 1, to: 7),
            DirectedEdge(from: 2, to: 6), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 0, to: 8), DirectedEdge(from: 4, to: 9),
            DirectedEdge(from: 10, to: 11), DirectedEdge(from: 0, to: 5), DirectedEdge(from: 2, to: 6), DirectedEdge(from: 6, to: 10)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 18)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 12))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 0, 2, 1, 1, 1, 1, 1, 2, 3, 4])
        #expect(layered.layerCount == 5)
        #expect(layered.crossingCount == 5)
        #expect(layered.drawing.positions == [SIMD2(1.0, 0.0), SIMD2(2.0, 0.0), SIMD2(4.5, 0.0), SIMD2(1.0, 2.0), SIMD2(4.5, 1.0), SIMD2(0.0, 1.0),
            SIMD2(1.5, 1.0), SIMD2(2.5, 1.0), SIMD2(3.5, 1.0), SIMD2(4.5, 2.0), SIMD2(4.0, 3.0), SIMD2(4.0, 4.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[SIMD2(5.5, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [SIMD2(6.5, 1.0), SIMD2(6.5, 2.0)],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [SIMD2(2.0, 2.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-152 random DAG, 15 vertices, 25 arcs: total edge span (optimal layering not unique; layers and positions not pinned)")
    func dr152() {
        // D: lcgdag(15,25,2); sugiyamaLayout() Σ span → #44
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 15, edges: [DirectedEdge(from: 10, to: 12), DirectedEdge(from: 6, to: 14),
            DirectedEdge(from: 5, to: 14), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 8), DirectedEdge(from: 6, to: 9),
            DirectedEdge(from: 8, to: 9), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 2, to: 8), DirectedEdge(from: 6, to: 10),
            DirectedEdge(from: 12, to: 14), DirectedEdge(from: 7, to: 8), DirectedEdge(from: 3, to: 7), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 4, to: 9), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 6), DirectedEdge(from: 0, to: 11),
            DirectedEdge(from: 10, to: 13), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 5, to: 11), DirectedEdge(from: 2, to: 10),
            DirectedEdge(from: 7, to: 10), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 5, to: 12)])
        #expect(Array(graph.vertices) == Array(0 ..< 15) && graph.edgeCount == 25)
        let layered = graph.sugiyamaLayout()
        // The optimal layering is not unique: the total span is pinned, and the layered drawing's invariants.
        let spans = graph.edges.indices.map { layered.layer(of: graph.target(ofEdgeAt: $0)) - layered.layer(of: graph.source(ofEdgeAt: $0)) }
        #expect(spans.reduce(0, +) == 44)
        #expect(spans.allSatisfy { $0 >= 1 })
        #expect(layered.reversedEdges == [] as [Int] && graph.feedbackArcSet() == [] as [Int])
        #expect(graph.vertices.map { layered.layer(of: $0) }.min() == 0)
        #expect(layered.layerCount == graph.vertices.map { layered.layer(of: $0) }.max()! + 1)
        for p in graph.edges.indices {
            let bends = Array(layered.bends(ofEdgeAt: p))
            let from = layered.layer(of: graph.source(ofEdgeAt: p))
            #expect(bends.map(\.y) == (0 ..< bends.count).map { Double(from + 1 + $0) })
            #expect(bends.count == spans[p] - 1)
        }
    }

    @Test("DR-153 random digraph with cycles, 10 vertices, 16 arcs: reversed edges (Eades–Lin–Smyth)")
    func dr153() {
        // D: lcggraph(10,16,3); sugiyamaLayout().reversedEdges → [5]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 10, edges: [DirectedEdge(from: 9, to: 3), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 7, to: 6), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 5, to: 4),
            DirectedEdge(from: 9, to: 4), DirectedEdge(from: 1, to: 9), DirectedEdge(from: 5, to: 8), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 8, to: 9), DirectedEdge(from: 5, to: 9)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 16)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 10))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 5, 4, 3, 0, 1, 0, 1, 2])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(3.0, 5.0), SIMD2(3.0, 4.0), SIMD2(5.0, 3.0), SIMD2(3.5, 0.0),
            SIMD2(2.0, 1.0), SIMD2(2.0, 0.0), SIMD2(3.0, 1.0), SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [5])
        let bends: [[SIMD2<Double>]] = [[SIMD2(3.0, 3.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(5.0, 1.0), SIMD2(5.0, 2.0)],
            [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [] as [SIMD2<Double>],
            [SIMD2(4.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-154 random digraph with cycles, 10 vertices, 16 arcs: layers")
    func dr154() {
        // D: lcggraph(10,16,3); sugiyamaLayout() layer(of:) in vertices order → [0, 0, 5, 4, 3, 0, 1, 0, 1, 2]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 10, edges: [DirectedEdge(from: 9, to: 3), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 7, to: 6), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 5, to: 4),
            DirectedEdge(from: 9, to: 4), DirectedEdge(from: 1, to: 9), DirectedEdge(from: 5, to: 8), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 8, to: 9), DirectedEdge(from: 5, to: 9)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 16)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 10))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 5, 4, 3, 0, 1, 0, 1, 2])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(3.0, 5.0), SIMD2(3.0, 4.0), SIMD2(5.0, 3.0), SIMD2(3.5, 0.0),
            SIMD2(2.0, 1.0), SIMD2(2.0, 0.0), SIMD2(3.0, 1.0), SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [5])
        let bends: [[SIMD2<Double>]] = [[SIMD2(3.0, 3.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(5.0, 1.0), SIMD2(5.0, 2.0)],
            [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [] as [SIMD2<Double>],
            [SIMD2(4.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-155 random digraph with cycles, 10 vertices, 16 arcs: crossings")
    func dr155() {
        // D: lcggraph(10,16,3); sugiyamaLayout().crossingCount → #0
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 10, edges: [DirectedEdge(from: 9, to: 3), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 7, to: 6), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 5, to: 4),
            DirectedEdge(from: 9, to: 4), DirectedEdge(from: 1, to: 9), DirectedEdge(from: 5, to: 8), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 8, to: 9), DirectedEdge(from: 5, to: 9)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 16)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 10))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 5, 4, 3, 0, 1, 0, 1, 2])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(3.0, 5.0), SIMD2(3.0, 4.0), SIMD2(5.0, 3.0), SIMD2(3.5, 0.0),
            SIMD2(2.0, 1.0), SIMD2(2.0, 0.0), SIMD2(3.0, 1.0), SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [5])
        let bends: [[SIMD2<Double>]] = [[SIMD2(3.0, 3.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(5.0, 1.0), SIMD2(5.0, 2.0)],
            [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [] as [SIMD2<Double>],
            [SIMD2(4.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-156 random digraph with cycles, 10 vertices, 16 arcs: positions")
    func dr156() {
        // D: lcggraph(10,16,3); sugiyamaLayout().drawing.positions → [(0.0, 0.0), (1.0, 0.0), (3.0, 5.0), (3.0, 4.0), (5.0, 3.0), (3.5, 0.0), (2.0, 1.0), (2.0, 0.0), (3.0, 1.0), (3.0, 2.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 10, edges: [DirectedEdge(from: 9, to: 3), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 7, to: 6), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 5, to: 4),
            DirectedEdge(from: 9, to: 4), DirectedEdge(from: 1, to: 9), DirectedEdge(from: 5, to: 8), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 8, to: 9), DirectedEdge(from: 5, to: 9)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 16)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 10))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 5, 4, 3, 0, 1, 0, 1, 2])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(3.0, 5.0), SIMD2(3.0, 4.0), SIMD2(5.0, 3.0), SIMD2(3.5, 0.0),
            SIMD2(2.0, 1.0), SIMD2(2.0, 0.0), SIMD2(3.0, 1.0), SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [5])
        let bends: [[SIMD2<Double>]] = [[SIMD2(3.0, 3.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(5.0, 1.0), SIMD2(5.0, 2.0)],
            [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [] as [SIMD2<Double>],
            [SIMD2(4.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-157 random digraph with cycles, 10 vertices, 16 arcs: bends")
    func dr157() {
        // D: lcggraph(10,16,3); sugiyamaLayout() bends(ofEdgeAt:) where non-empty → 0: [(3.0, 3.0)]; 9: [(5.0, 1.0), (5.0, 2.0)]; 11: [(1.0, 1.0)]; 13: [(0.0, 1.0), (0.0, 2.0), (0.0, 3.0)]; 15: [(4.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 10, edges: [DirectedEdge(from: 9, to: 3), DirectedEdge(from: 5, to: 8),
            DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 6, to: 9), DirectedEdge(from: 8, to: 5),
            DirectedEdge(from: 7, to: 6), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 1, to: 6), DirectedEdge(from: 5, to: 4),
            DirectedEdge(from: 9, to: 4), DirectedEdge(from: 1, to: 9), DirectedEdge(from: 5, to: 8), DirectedEdge(from: 1, to: 3),
            DirectedEdge(from: 8, to: 9), DirectedEdge(from: 5, to: 9)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 16)
        let layered = graph.sugiyamaLayout()
        #expect(graph.feedbackArcSet() == [5])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 10))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 5, 4, 3, 0, 1, 0, 1, 2])
        #expect(layered.layerCount == 6)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(3.0, 5.0), SIMD2(3.0, 4.0), SIMD2(5.0, 3.0), SIMD2(3.5, 0.0),
            SIMD2(2.0, 1.0), SIMD2(2.0, 0.0), SIMD2(3.0, 1.0), SIMD2(3.0, 2.0)])
        #expect(layered.reversedEdges == [5])
        let bends: [[SIMD2<Double>]] = [[SIMD2(3.0, 3.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>],
            [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>], [SIMD2(5.0, 1.0), SIMD2(5.0, 2.0)],
            [] as [SIMD2<Double>], [SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)], [] as [SIMD2<Double>],
            [SIMD2(4.0, 1.0)]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-158 caller layers: a long arc and its bend")
    func dr158() {
        // D: 0>1, 0>2, 1>3; sugiyamaLayout(layers: [0, 2, 1, 3]) positions → [(0.5, 0.0), (1.0, 2.0), (0.0, 1.0), (1.0, 3.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout(layers: { [0, 2, 1, 3][$0] })
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 2, 1, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(1.0, 2.0), SIMD2(0.0, 1.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-159 caller layers: bends")
    func dr159() {
        // D: 0>1, 0>2, 1>3; sugiyamaLayout(layers: [0, 2, 1, 3]) bends(ofEdgeAt: 0) → [(1.0, 1.0)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout(layers: { [0, 2, 1, 3][$0] })
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 2, 1, 3])
        #expect(layered.layerCount == 4)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.5, 0.0), SIMD2(1.0, 2.0), SIMD2(0.0, 1.0), SIMD2(1.0, 3.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[SIMD2(1.0, 1.0)], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-160 caller layers: an upward arc is reversed, a flat arc has no segment")
    func dr160() {
        // D: 0>1, 0>2, 1>3; sugiyamaLayout(layers: [1, 0, 1, 1]).reversedEdges → [0]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layered = graph.sugiyamaLayout(layers: { [1, 0, 1, 1][$0] })
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [1, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 0)
        #expect(layered.drawing.positions == [SIMD2(0.0, 1.0), SIMD2(1.0, 0.0), SIMD2(1.0, 1.0), SIMD2(2.0, 1.0)])
        #expect(layered.reversedEdges == [0])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-162 maxIterations: 0 keeps the initial order")
    func dr162() {
        // D: 0>3, 1>2; sugiyamaLayout(maxIterations: 0).crossingCount → #1
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 2)
        let layered = graph.sugiyamaLayout(maxIterations: 0)
        #expect(graph.feedbackArcSet() == [] as [Int])
        #expect(Array(layered.drawing.vertices) == Array(0 ..< 4))
        #expect(graph.vertices.map { layered.layer(of: $0) } == [0, 0, 1, 1])
        #expect(layered.layerCount == 2)
        #expect(layered.crossingCount == 1)
        #expect(layered.drawing.positions == [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0)])
        #expect(layered.reversedEdges == [] as [Int])
        let bends: [[SIMD2<Double>]] = [[] as [SIMD2<Double>], [] as [SIMD2<Double>]]
        #expect(graph.edges.indices.map { Array(layered.bends(ofEdgeAt: $0)) } == bends)
    }

    @Test("DR-163 DirectedAcyclicGraph: no edge is reversed")
    func dr163() throws {
        // D: lcgdag(15,25,2)` as `DirectedAcyclicGraph; sugiyamaLayout().reversedEdges → []
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 15, edges: [DirectedEdge(from: 10, to: 12),
            DirectedEdge(from: 6, to: 14), DirectedEdge(from: 5, to: 14), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 8),
            DirectedEdge(from: 6, to: 9), DirectedEdge(from: 8, to: 9), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 2, to: 8),
            DirectedEdge(from: 6, to: 10), DirectedEdge(from: 12, to: 14), DirectedEdge(from: 7, to: 8), DirectedEdge(from: 3, to: 7),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 4, to: 9), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 6),
            DirectedEdge(from: 0, to: 11), DirectedEdge(from: 10, to: 13), DirectedEdge(from: 10, to: 11), DirectedEdge(from: 5, to: 11),
            DirectedEdge(from: 2, to: 10), DirectedEdge(from: 7, to: 10), DirectedEdge(from: 5, to: 6), DirectedEdge(from: 5, to: 12)]))
        #expect(Array(graph.vertices) == Array(0 ..< 15) && graph.edgeCount == 25)
        let layered = graph.sugiyamaLayout()
        #expect(layered.reversedEdges == [] as [Int])
        #expect(graph.feedbackArcSet() == [] as [Int])
        // The same layering as on the plain pseudograph: the total span is the catalog's optimum (DR-152).
        #expect(graph.edges.indices.map { layered.layer(of: graph.target(ofEdgeAt: $0)) - layered.layer(of: graph.source(ofEdgeAt: $0)) }.reduce(0, +) == 44)
        #expect(graph.edges.indices.allSatisfy { layered.layer(of: graph.target(ofEdgeAt: $0)) > layered.layer(of: graph.source(ofEdgeAt: $0)) })
    }
}
