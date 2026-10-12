// Conformance: the same layout on every representation that can hold the graph. A layout reads the
// graph's `vertices` order and its edges, nothing else, so circular, stress and Fruchterman–Reingold
// drawings agree across undirected representations and views with the same vertex order, and
// Sugiyama drawings agree across directed representations whose edge positions come in the same
// order. Reingold–Tilford agrees across the ways of building one rooted tree, and every layout agrees
// through a relabeling of the vertices. Then the `Drawing` value's own laws: Equatable, Hashable,
// RandomAccessCollection, Sendable, CustomStringConvertible. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing
import Trees

@Suite("GraphDrawing conformance", .tags(.conformance))
struct GraphDrawingConformanceTests {
    @Test("Circular, stress and Fruchterman–Reingold layouts agree across undirected representations and views", arguments: 1 ... 12)
    func undirectedRepresentations(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 14, using: &rng)
        // Simple edges, each pair once with u < v, so every representation keeps them all.
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n where Int.random(in: 0 ..< 100, using: &rng) < 30 { pairs.append((u, v)) }
        }
        let pseudograph = Pseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let list = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let directedPseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
        let adjacencyList = AdjacencyList<Int>(vertices: 0 ..< n, edges: arcs)
        let matrix = AdjacencyMatrix(vertexCount: n, edges: arcs)
        let stable = StableDirectedGraph<Int>(vertices: 0 ..< n, edges: arcs)
        let context = "n = \(n), edges \(pairs)"
        #expect(Array(list.vertices) == Array(0 ..< n) && Array(matrix.vertices) == Array(0 ..< n) && Array(stable.vertices) == Array(0 ..< n), "\(context)")

        let circular = pseudograph.circularLayout(radius: 2, center: SIMD2(1, -1))
        #expect(list.circularLayout(radius: 2, center: SIMD2(1, -1)) == circular, "\(context)")
        #expect(directedPseudograph.undirected.circularLayout(radius: 2, center: SIMD2(1, -1)) == circular, "\(context)")
        #expect(adjacencyList.undirected.circularLayout(radius: 2, center: SIMD2(1, -1)) == circular, "\(context)")
        #expect(matrix.undirected.circularLayout(radius: 2, center: SIMD2(1, -1)) == circular, "\(context)")
        #expect(stable.undirected.circularLayout(radius: 2, center: SIMD2(1, -1)) == circular, "\(context)")

        let stress = pseudograph.stressMajorizationLayout()
        for other in [list.stressMajorizationLayout(), directedPseudograph.undirected.stressMajorizationLayout(),
                      adjacencyList.undirected.stressMajorizationLayout(), matrix.undirected.stressMajorizationLayout(),
                      stable.undirected.stressMajorizationLayout()] {
            #expect(other.vertices == stress.vertices, "\(context)")
            for (a, b) in zip(other.positions, stress.positions) {
                #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(context): \(a) vs \(b)")
            }
        }

        var g0 = Xoshiro256StarStar(seed: UInt64(seed))
        let force = pseudograph.fruchtermanReingoldLayout(using: &g0)
        var others: [Drawing<Int>] = []
        var g1 = Xoshiro256StarStar(seed: UInt64(seed))
        others.append(list.fruchtermanReingoldLayout(using: &g1))
        var g2 = Xoshiro256StarStar(seed: UInt64(seed))
        others.append(directedPseudograph.undirected.fruchtermanReingoldLayout(using: &g2))
        var g3 = Xoshiro256StarStar(seed: UInt64(seed))
        others.append(adjacencyList.undirected.fruchtermanReingoldLayout(using: &g3))
        var g4 = Xoshiro256StarStar(seed: UInt64(seed))
        others.append(matrix.undirected.fruchtermanReingoldLayout(using: &g4))
        var g5 = Xoshiro256StarStar(seed: UInt64(seed))
        others.append(stable.undirected.fruchtermanReingoldLayout(using: &g5))
        #expect([g1, g2, g3, g4, g5].allSatisfy { $0 == g0 }, "\(context)")
        for other in others {
            #expect(other.vertices == force.vertices, "\(context)")
            for (a, b) in zip(other.positions, force.positions) {
                #expect(abs(a.x - b.x) <= 1e-6 && abs(a.y - b.y) <= 1e-6, "\(context): \(a) vs \(b)")
            }
        }
    }

    @Test("Sugiyama drawings agree across directed representations with edges in row-major order", arguments: 1 ... 12)
    func directedRepresentations(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed) &+ 100)
        let n = Int.random(in: 1 ... 12, using: &rng)
        let acyclic = seed % 2 == 0
        // Each arc once, sorted by (source, target): CSR and the matrix list positions in that order.
        var arcs: [DirectedEdge<Int>] = []
        for u in 0 ..< n {
            for v in 0 ..< n where u != v && (!acyclic || u < v) && Int.random(in: 0 ..< 100, using: &rng) < 25 {
                arcs.append(DirectedEdge(from: u, to: v))
            }
        }
        let context = "n = \(n), arcs \(arcs.map { [$0.source, $0.target] })"
        let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
        let list = AdjacencyList<Int>(vertices: 0 ..< n, edges: arcs)
        let csr = CompressedSparseRow(vertexCount: n, edges: arcs)
        let matrix = AdjacencyMatrix(vertexCount: n, edges: arcs)
        let stable = StableDirectedGraph<Int>(vertices: 0 ..< n, edges: arcs)
        #expect(Array(csr.edges) == arcs && Array(matrix.edges) == arcs && Array(list.edges) == arcs, "\(context)")

        let reference = pseudograph.sugiyamaLayout()
        let referenceBends = Dictionary(uniqueKeysWithValues: pseudograph.edges.indices.map { (pseudograph.edges[$0], Array(reference.bends(ofEdgeAt: $0))) })
        let referenceReversed = reference.reversedEdges.map { pseudograph.edges[$0] }
        // reversedEdges is feedbackArcSet() without its self-loops.
        let referenceFeedback = pseudograph.feedbackArcSet().map { pseudograph.edges[$0] }
        #expect(referenceFeedback.filter { $0.source != $0.target } == referenceReversed, "\(context)")

        func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String) {
            let layered = graph.sugiyamaLayout()
            #expect(layered.drawing == reference.drawing, "\(name): \(context)")
            #expect(graph.vertices.map { layered.layer(of: $0) } == pseudograph.vertices.map { reference.layer(of: $0) }, "\(name): \(context)")
            #expect(layered.layerCount == reference.layerCount && layered.crossingCount == reference.crossingCount, "\(name): \(context)")
            #expect(layered.reversedEdges.map { graph.edges[$0] } == referenceReversed, "\(name): \(context)")
            #expect(graph.feedbackArcSet().map { graph.edges[$0] } == referenceFeedback, "\(name): \(context)")
            for p in graph.edges.indices {
                #expect(Array(layered.bends(ofEdgeAt: p)) == referenceBends[graph.edges[p]], "\(name): \(context)")
            }
        }
        check(list, "AdjacencyList")
        check(csr, "CompressedSparseRow")
        check(matrix, "AdjacencyMatrix")
        check(stable, "StableDirectedGraph")
        if acyclic {
            let dag = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n, edges: arcs))
            check(dag, "DirectedAcyclicGraph")
            #expect(reference.reversedEdges.isEmpty, "\(context)")
        }
    }

    @Test("Reingold–Tilford agrees across the ways of building one rooted tree, and through labels", arguments: 1 ... 20)
    func rootedTreeConstructions(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed) &+ 200)
        let n = Int.random(in: 1 ... 30, using: &rng)
        let parents: [Int?] = (0 ..< n).map { $0 == 0 ? nil : Int.random(in: 0 ..< $0, using: &rng) }
        let fromParents = try #require(RootedTree(parents: parents))
        let edges = (1 ..< max(n, 1)).compactMap { v in parents[v].map { UndirectedEdge($0, v) } }
        let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
        let fromGraph = try #require(RootedTree(graph, root: 0))
        let fromTree = RootedTree(try #require(Tree(graph)), root: 0)
        let viaClosure = try #require(RootedTree(vertices: 0 ..< n, parent: { parents[$0] }))
        let reference = fromParents.reingoldTilfordLayout()
        let referenceCircular = fromParents.reingoldTilfordCircularLayout()
        for (name, tree) in [("RootedTree(_:root:) from a graph", fromGraph), ("from a Tree", fromTree), ("vertices:parent:", viaClosure)] {
            // The layout reads children(of:) in order: compare only trees that list children alike.
            guard (0 ..< n).allSatisfy({ Array(tree.children(of: $0)) == Array(fromParents.children(of: $0)) }) else { continue }
            let layout = tree.reingoldTilfordLayout()
            let circular = tree.reingoldTilfordCircularLayout()
            for v in 0 ..< n {
                #expect(try layout.position(checked: v) == reference.position(checked: v), "\(name), parents \(parents)")
                let a = try circular.position(checked: v), b = try referenceCircular.position(checked: v)
                #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(name), parents \(parents)")
            }
        }
        // Labels: the same tree over String vertices draws the same points.
        let labeled = try #require(RootedTree(vertices: (0 ..< n).map { "v\($0)" }, parent: { label in
            parents[Int(label.dropFirst())!].map { "v\($0)" }
        }))
        let labeledLayout = labeled.reingoldTilfordLayout()
        #expect(labeledLayout.vertices.map { Int($0.dropFirst())! } == Array(reference.vertices))
        #expect(labeledLayout.positions == reference.positions, "parents \(parents)")
    }

    @Test("Every layout draws the same points through a relabeling of the vertices")
    func relabeledVertices() {
        let undirected = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 3),
                                                                      UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 3)])
        let names = ["a", "b", "c", "d", "e", "f", "g"]
        let named = Pseudograph<String>(vertices: names, edges: undirected.edges.map { UndirectedEdge(names[$0.u], names[$0.v]) })
        #expect(Array(named.vertices) == names)
        #expect(named.circularLayout().positions == undirected.circularLayout().positions)
        #expect(named.stressMajorizationLayout().positions == undirected.stressMajorizationLayout().positions)
        var g1 = Xoshiro256StarStar(seed: 4), g2 = Xoshiro256StarStar(seed: 4)
        #expect(named.fruchtermanReingoldLayout(using: &g1).positions == undirected.fruchtermanReingoldLayout(using: &g2).positions)
        #expect(Array(named.circularLayout().vertices) == names)

        let directed = DirectedPseudograph<Int>(vertices: 0 ..< 7, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0),
                                                                          DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 4), DirectedEdge(from: 4, to: 5),
                                                                          DirectedEdge(from: 5, to: 6), DirectedEdge(from: 6, to: 4), DirectedEdge(from: 3, to: 6)])
        let namedDirected = DirectedPseudograph<String>(vertices: names, edges: directed.edges.map { DirectedEdge(from: names[$0.source], to: names[$0.target]) })
        let a = directed.sugiyamaLayout(), b = namedDirected.sugiyamaLayout()
        #expect(a.drawing.positions == b.drawing.positions && b.drawing.vertices.elementsEqual(names))
        #expect(a.reversedEdges == b.reversedEdges && a.crossingCount == b.crossingCount && a.layerCount == b.layerCount)
        #expect(directed.edges.indices.allSatisfy { Array(a.bends(ofEdgeAt: $0)) == Array(b.bends(ofEdgeAt: $0)) })
        #expect(names.indices.allSatisfy { a.layer(of: $0) == b.layer(of: names[$0]) })
    }

    @Test("Drawing: Equatable and Hashable in order, RandomAccessCollection, Sendable, description")
    func drawingLaws() {
        let names = ["x", "y", "z"]
        let points = [SIMD2(0.0, 1.0), SIMD2(-2.0, 0.5), SIMD2(3.0, 3.0)]
        let drawing = Drawing(vertices: names, positions: points)
        let same = Drawing(vertices: names, positions: points)
        #expect(drawing == same && drawing.hashValue == same.hashValue)
        #expect(Set([drawing, same]).count == 1)
        // Order matters; a moved point matters.
        #expect(drawing != Drawing(vertices: names.reversed(), positions: points.reversed()))
        var moved = drawing
        moved.setPosition(SIMD2(-2.0, 0.25), of: "y")
        #expect(moved != drawing && drawing.position(of: "y") == SIMD2(-2.0, 0.5))
        // Copies are independent.
        var copy = drawing
        copy.positions[0] = SIMD2(9, 9)
        #expect(drawing.positions == points && copy.position(of: "x") == SIMD2(9.0, 9.0))
        // The collection: elements in order, indices from startIndex, random access.
        #expect(drawing.count == 3 && !drawing.isEmpty)
        #expect(drawing.indices.map { drawing[$0].vertex } == names)
        #expect(drawing.indices.map { drawing[$0].position } == points)
        #expect(drawing.map(\.vertex) == names && drawing.map(\.position) == points)
        #expect(drawing.index(drawing.startIndex, offsetBy: 3) == drawing.endIndex)
        #expect(drawing[drawing.index(before: drawing.endIndex)].vertex == "z")
        #expect(drawing.reversed().map(\.vertex) == names.reversed())
        let box = drawing.boundingBox
        #expect(box?.min == SIMD2(-2.0, 0.5) && box?.max == SIMD2(3.0, 3.0))
        let sendable: any Sendable = drawing
        #expect(sendable is Drawing<String>)
        #expect(!drawing.description.isEmpty && drawing.description.contains("x"))
        #expect(Drawing<String>() == Drawing<String>() && Drawing<String>().boundingBox == nil)
    }
}
