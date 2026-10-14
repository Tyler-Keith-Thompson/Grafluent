// The edit path's accessors and checked spellings on paths with one optimum, costs that make a
// substitution dearer than a deletion and an insertion, floating-point costs, how often each cost
// closure is called, the upper bound and the expansion limit, and every representation. See
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import IsomorphismModule
import LabeledGraphs
import Multigraphs
import Testing

@Suite("Edit paths")
struct EditPathTests {
    @Test("Undirected: one optimal path (10 deleted, 20 ↦ 7, its loop substituted), read through every accessor")
    func undirectedAccessors() throws {
        let pattern = Pseudograph<Int>(vertices: [10, 20], edges: [UndirectedEdge(10, 20), UndirectedEdge(20, 20)])
        let target = Pseudograph<Int>(vertices: [7], edges: [UndirectedEdge(7, 7)])
        // Substituting 10 costs 5, so the only optimum deletes 10 (1) and its edge (1).
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { u, _ in u == 20 ? 0 : 5 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        #expect(path.image(of: 10) == nil)
        #expect(path.image(of: 20) == 7)
        #expect(path.preimage(of: 7) == 20)
        #expect(path.imageIndex(ofIndex: 0) == nil)
        #expect(path.imageIndex(ofIndex: 1) == 0)
        #expect(path.edgeImage(ofEdgeAt: 0) == nil)
        #expect(path.edgeImage(ofEdgeAt: 1) == 0)
        #expect(path.edgePreimage(ofEdgeAt: 0) == 1)
        #expect(path.deletedVertices == [10])
        #expect(path.insertedVertices == [])
        #expect(path.deletedEdges == [0])
        #expect(path.insertedEdges == [])
        // Checked spellings: the same answers, and a typed error for a non-member.
        #expect(try path.image(checked: 20) == 7)
        #expect(try path.image(checked: 10) == nil)
        #expect(throws: VertexNotFound.self) { try path.image(checked: 99) }
        #expect(try path.preimage(checked: 7) == 20)
        #expect(throws: VertexNotFound.self) { try path.preimage(checked: 10) }
        #expect(try path.edgeImage(checkedEdgeAt: 1) == 0)
        #expect(throws: EdgeNotFound.self) { try path.edgeImage(checkedEdgeAt: 2) }
        #expect(try path.edgePreimage(checkedEdgeAt: 0) == 1)
        #expect(throws: EdgeNotFound.self) { try path.edgePreimage(checkedEdgeAt: 1) }
    }

    @Test("Directed: one optimal path (a ↦ y, b deleted, c inserted), read through every accessor")
    func directedAccessors() throws {
        let pattern = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "a")])
        let target = DirectedPseudograph<String>(vertices: ["x", "y", "c"], edges: [DirectedEdge(from: "y", to: "y"), DirectedEdge(from: "c", to: "y")])
        // a may only become y, and b nothing: b and a → b deleted, c and c → y inserted, x
        // inserted, the loop substituted.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { u, x in u == "a" && x == "y" ? 0 : 9 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 5)
        #expect(path.image(of: "a") == "y")
        #expect(path.image(of: "b") == nil)
        #expect(path.preimage(of: "y") == "a")
        #expect(path.preimage(of: "c") == nil)
        #expect(path.imageIndex(ofIndex: 0) == 1)
        #expect(path.edgeImage(ofEdgeAt: 0) == nil)
        #expect(path.edgeImage(ofEdgeAt: 1) == 0)
        #expect(path.edgePreimage(ofEdgeAt: 1) == nil)
        #expect(path.deletedVertices == ["b"])
        #expect(path.insertedVertices == ["x", "c"])
        #expect(path.deletedEdges == [0])
        #expect(path.insertedEdges == [1])
        #expect(throws: VertexNotFound.self) { try path.image(checked: "z") }
        #expect(throws: VertexNotFound.self) { try path.preimage(checked: "a") }
        #expect(throws: EdgeNotFound.self) { try path.edgeImage(checkedEdgeAt: 5) }
        #expect(throws: EdgeNotFound.self) { try path.edgePreimage(checkedEdgeAt: -1) }
        #expect(try path.edgeImage(checkedEdgeAt: 1) == 0)
        #expect(try path.preimage(checked: "x") == nil)
    }

    @Test("A substitution dearer than a deletion and an insertion: the path deletes and inserts")
    func substitutionDearerThanReplacement() throws {
        let pattern = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        // Vertices substitute for free; the edge's substitution costs 5, its deletion and its
        // insertion 1 each.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                                        edgeSubstitutionCost: { _, _ in 5 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 2)
        #expect(path.edgeImage(ofEdgeAt: 0) == nil)
        #expect(path.deletedEdges == [0] && path.insertedEdges == [0])
        // The same for a vertex: substituting costs 3, deleting and inserting 1 each.
        let single = Pseudograph<Int>(vertices: [0])
        let replaced = try #require(single.optimalEditPath(to: single, vertexSubstitutionCost: { _, _ in 3 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                                           edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(replaced.cost == 2)
        #expect(replaced.image(of: 0) == nil)
        #expect(replaced.insertedVertices == [0])
    }

    @Test("Floating-point costs: deleting a pendant vertex and its edge")
    func floatingPointCosts() {
        let pattern = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { _, _ in 0.0 }, vertexDeletionCost: { _ in 0.75 }, vertexInsertionCost: { _ in 0.75 },
                                                 edgeSubstitutionCost: { _, _ in 0.0 }, edgeDeletionCost: { _ in 0.25 }, edgeInsertionCost: { _ in 0.25 })
        #expect(distance == 1.0)
    }

    @Test("Each cost closure is called once per vertex, edge or pair, at the call")
    func closureCalls() {
        let pattern = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        var calls = [0, 0, 0, 0, 0, 0]
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { _, _ in calls[0] += 1; return 0 }, vertexDeletionCost: { _ in calls[1] += 1; return 1 },
                                                 vertexInsertionCost: { _ in calls[2] += 1; return 1 }, edgeSubstitutionCost: { _, _ in calls[3] += 1; return 0 },
                                                 edgeDeletionCost: { _ in calls[4] += 1; return 1 }, edgeInsertionCost: { _ in calls[5] += 1; return 1 })
        #expect(distance == 2)
        #expect(calls == [12, 3, 4, 6, 2, 3])
    }

    @Test("The upper bound: nil below the distance, the optimal path at it; the expansion limit stops early with a path that is not proven optimal")
    func boundAndLimit() throws {
        // C6 against two triangles: both 2-regular on 6 vertices; delete two edges of the
        // hexagon and insert the two that close the triangles.
        let hexagon = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: (0 ..< 6).map { UndirectedEdge($0, ($0 + 1) % 6) })
        let triangles = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        let distance = hexagon.graphEditDistance(to: triangles)
        #expect(distance == 4)
        #expect(hexagon.optimalEditPath(to: triangles, upperBound: distance - 1) == nil)
        let bounded = try #require(hexagon.optimalEditPath(to: triangles, upperBound: distance))
        #expect(bounded.cost == distance && bounded.isOptimal)
        let limited = try #require(hexagon.optimalEditPath(to: triangles, expansionLimit: 0))
        #expect(!limited.isOptimal)
        #expect(limited.cost >= distance)
        #expect(limited.cost == limited.deletedVertices.count + limited.insertedVertices.count + limited.deletedEdges.count + limited.insertedEdges.count)
        // A limit never reached: the search finishes and proves the path optimal.
        let generous = try #require(hexagon.optimalEditPath(to: triangles, expansionLimit: 1_000_000_000))
        #expect(generous.isOptimal && generous.cost == distance)
        // P2 to P2: the root's expansion finds every child pruned by the bipartite bound's path, so
        // limit 1 suffices and limit 0 stops before it.
        let edge = UndirectedAdjacencyList<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let stopped = try #require(edge.optimalEditPath(to: edge, expansionLimit: 0))
        #expect(stopped.cost == 0 && !stopped.isOptimal)
        let finished = try #require(edge.optimalEditPath(to: edge, expansionLimit: 1))
        #expect(finished.cost == 0 && finished.isOptimal)
        // A pattern without vertices needs no expansion: the path is optimal under limit 0.
        let empty = UndirectedAdjacencyList<Int>()
        let inserted = try #require(empty.optimalEditPath(to: triangles, expansionLimit: 0))
        #expect(inserted.isOptimal && inserted.cost == 12)
    }

    @Test("Every representation gives the same distances: undirected and directed, alone and mixed")
    func representations() {
        // G: a 4-cycle with a chord and a pendant; H: a 5-cycle. Arcs i → j for the directed side.
        let gPairs = [[0, 1], [1, 2], [2, 3], [3, 0], [0, 2], [3, 4]], hPairs = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]]
        let names = ["a", "b", "c", "d", "e"]
        let undirected = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: gPairs.map { UndirectedEdge($0[0], $0[1]) })
            .graphEditDistance(to: Pseudograph<Int>(vertices: Array(0 ..< 5), edges: hPairs.map { UndirectedEdge($0[0], $0[1]) }))
        #expect(undirected == 3)
        let lists = (UndirectedAdjacencyList(vertices: 0 ..< 5, edges: gPairs.map { UndirectedEdge($0[0], $0[1]) }),
                     UndirectedAdjacencyList(vertices: 0 ..< 5, edges: hPairs.map { UndirectedEdge($0[0], $0[1]) }))
        let matrices = (AdjacencyMatrix(vertexCount: 5, edges: gPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirectedView,
                        AdjacencyMatrix(vertexCount: 5, edges: hPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirectedView)
        let labeled = (LabeledGraph<String, AdjacencyMatrix>(vertices: names, edges: gPairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) }).undirectedView,
                       LabeledGraph<String, AdjacencyMatrix>(vertices: names, edges: hPairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) }).undirectedView)
        #expect(lists.0.graphEditDistance(to: lists.1) == undirected)
        #expect(matrices.0.graphEditDistance(to: matrices.1) == undirected)
        #expect(labeled.0.graphEditDistance(to: labeled.1) == undirected)
        #expect(lists.0.graphEditDistance(to: matrices.1) == undirected)
        #expect(labeled.0.graphEditDistance(to: lists.1) == undirected)
        let directed = DirectedPseudograph<Int>(vertices: Array(0 ..< 5), edges: gPairs.map { DirectedEdge(from: $0[0], to: $0[1]) })
            .graphEditDistance(to: DirectedPseudograph<Int>(vertices: Array(0 ..< 5), edges: hPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }))
        let arcs = (gPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }, hPairs.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let named = (gPairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) }, hPairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) })
        #expect(AdjacencyList(vertices: 0 ..< 5, edges: arcs.0).graphEditDistance(to: AdjacencyList(vertices: 0 ..< 5, edges: arcs.1)) == directed)
        #expect(CompressedSparseRow(vertexCount: 5, edges: arcs.0).graphEditDistance(to: CompressedSparseRow(vertexCount: 5, edges: arcs.1)) == directed)
        #expect(AdjacencyMatrix(vertexCount: 5, edges: arcs.0).graphEditDistance(to: AdjacencyMatrix(vertexCount: 5, edges: arcs.1)) == directed)
        #expect(LabeledGraph<String, CompressedSparseRow>(vertices: names, edges: named.0).graphEditDistance(to: LabeledGraph<String, CompressedSparseRow>(vertices: names, edges: named.1)) == directed)
        #expect(CompressedSparseRow(vertexCount: 5, edges: arcs.0).graphEditDistance(to: AdjacencyList(vertices: 0 ..< 5, edges: arcs.1)) == directed)
        #expect(DirectedMultigraph<Int>(vertices: Array(0 ..< 5), edges: arcs.0)!.graphEditDistance(to: AdjacencyMatrix(vertexCount: 5, edges: arcs.1)) == directed)
        // The directed distance counts reversed arcs: 0 → 1 → 2 → 3 → 0 keeps its direction in
        // the 5-cycle only partly.
        #expect(directed >= undirected)
    }

    @Test("String vertices: a path names them")
    func stringVertices() throws {
        let pattern = Pseudograph<String>(vertices: ["p", "q", "r"], edges: [UndirectedEdge("p", "q"), UndirectedEdge("q", "r")])
        let target = Pseudograph<String>(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        let images = pattern.vertices.map { path.image(of: $0) }
        #expect(images.compactMap { $0 }.count == 2)
        #expect(path.deletedVertices.count == 1)
        #expect(path.insertedVertices.isEmpty)
    }
}
