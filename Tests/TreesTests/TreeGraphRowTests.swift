// §I: the four types as graphs. `Tree`, `RootedTree` and `Forest` are `Graph`s whose incidence
// rows are the tree's, in position order, whatever the root (TS-600, TS-601, TS-611);
// `Arborescence` is a `BidirectionalDirectedGraph` whose out-edges are the child edges, in-edges the
// parent edge, and whose arcs point parent → child at the tree's positions (TS-602 – TS-608). Then
// the protocol laws (Sources/GraphProtocols/Graph.swift and DirectedGraph.swift), checked on every
// vertex and edge of several trees: vertices in index order, the index-space rows parallel to the
// vertex ones, `edgeIndex` one-to-one and `edges` in index order, degrees summing to 2m, in- and
// out-rows consistent. Expected values of the §I rows come from the catalog's reference
// (`ref.py`); the laws are computed in each test. Case IDs (TS-nnn) refer to the catalog; see
// README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Trees as graphs: rows and protocol laws")
struct TreeGraphRowTests {
    @Test("TS-600 RootedTree(E1, root: 4).incidentEdges(of: 1) is [0, 2, 3]: the tree's rows whatever the root")
    func rootedRows() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(Array(rooted.incidentEdges(of: 1)) == [0, 2, 3])
        #expect(Array(rooted.neighbors(of: 1)) == [0, 3, 4])
    }

    @Test("TS-601 RootedTree(E1, root: 4).degree(of: 1) is 3")
    func rootedDegree() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(rooted.degree(of: 1) == 3)
    }

    @Test("TS-602 Arborescence(E1).outEdges(of: 1) is [2, 3]: the child edges")
    func arborescenceOutEdges() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.outEdges(of: 1)) == [2, 3])
        #expect(Array(arborescence.successors(of: 1)) == [3, 4])
    }

    @Test("TS-603 Arborescence(E1).inEdges(of: 1) is [0]: the parent edge")
    func arborescenceInEdges() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.inEdges(of: 1)) == [0])
        #expect(Array(arborescence.predecessors(of: 1)) == [0])
    }

    @Test("TS-604 Arborescence(E1).inEdges(of: 0) is empty")
    func arborescenceRootInEdges() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.inEdges(of: 0)).isEmpty)
        #expect(Array(arborescence.predecessors(of: 0)).isEmpty)
    }

    @Test("TS-605 Arborescence(E1).inDegree(of: 0) is 0")
    func arborescenceRootInDegree() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.inDegree(of: 0) == 0)
    }

    @Test("TS-606 Arborescence(E1).outDegree(of: 1) is 2")
    func arborescenceOutDegree() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.outDegree(of: 1) == 2)
    }

    @Test("TS-607 Arborescence(RootedTree(E1, root: 4)).edges is [1>0, 0>2, 1>3, 4>1, 2>5, 4>6]: parent → child at the tree's positions")
    func rootedToArborescenceEdges() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let arborescence = Arborescence(rooted)
        let expected: [(Int, Int)] = [(1, 0), (0, 2), (1, 3), (4, 1), (2, 5), (4, 6)]
        #expect(Array(arborescence.edges) == expected.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(arborescence.root == 4)
        #expect(Array(arborescence.vertices) == Array(rooted.vertices))
    }

    @Test("TS-608 Arborescence(RootedTree(E1, root: 4)).outEdges(of: 1) is [0, 2]")
    func rootedToArborescenceOutEdges() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let arborescence = Arborescence(rooted)
        #expect(Array(arborescence.outEdges(of: 1)) == [0, 2])
    }

    @Test("TS-609 Tree(E1).vertexCount is 7")
    func treeVertexCount() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.vertexCount == 7)
    }

    @Test("TS-610 Tree(E1).edgeCount is 6")
    func treeEdgeCount() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.edgeCount == 6)
    }

    @Test("TS-611 Forest(g).degree(of: 9) is 0")
    func forestIsolatedDegree() throws {
        // U: [9] 0-1, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = ReferencePseudograph(vertices: [9], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.degree(of: 9) == 0)
        #expect(Array(forest.neighbors(of: 9)).isEmpty)
    }

    @Test("Tree satisfies Graph's laws, rows in position order", arguments: [
        [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)],
        [(4, 2), (0, 2), (2, 1), (1, 3)],
        [(3, 4), (0, 1), (2, 3), (4, 0)],
        [(7, 0)],
    ])
    func treeLaws(pairs: [(Int, Int)]) throws {
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let vertices = Array(tree.vertices)
        let edges = Array(tree.edges)
        #expect(tree.vertexCount == vertices.count)
        #expect(Set(vertices).count == vertices.count)
        #expect(tree.edgeCount == edges.count)
        #expect(tree.edgeCount == tree.vertexCount - 1)
        #expect(Array(tree.edges.indices) == Array(0 ..< edges.count))
        #expect(tree.vertexIndexBound == vertices.count)
        #expect(tree.edgeIndexBound == edges.count)
        var degreeSum = 0
        for (i, v) in vertices.enumerated() {
            #expect(tree.contains(v))
            #expect(tree.vertex(atIndex: i) == v)
            #expect(tree.vertexIndex(of: v) == i)
            let row = Array(tree.incidentEdges(of: v))
            let expectedRow = edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == v }.map { _ in k } }
            #expect(row == expectedRow, "row of \(v)")
            #expect(row == row.sorted(), "row of \(v) in position order")
            #expect(Array(tree.neighbors(of: v)) == row.map { edges[$0].oppositeVertex(to: v) })
            #expect(row.allSatisfy { tree.oppositeVertex(to: v, acrossEdgeAt: $0) == edges[$0].oppositeVertex(to: v) })
            #expect(tree.degree(of: v) == row.count)
            #expect(Array(tree.incidentEdges(ofIndex: i)) == row)
            #expect(Array(tree.neighborIndices(ofIndex: i)) == tree.neighbors(of: v).map { tree.vertexIndex(of: $0) })
            #expect(Array(tree.incidentEdgeIndices(ofIndex: i)) == row.map { tree.edgeIndex(of: $0) })
            degreeSum += tree.degree(of: v)
        }
        #expect(degreeSum == 2 * tree.edgeCount)
        #expect(edges.indices.map { tree.edgeIndex(of: $0) } == Array(0 ..< edges.count))
        for edge in edges {
            #expect(tree.contains(edge: edge))
            #expect(tree.contains(edge: UndirectedEdge(edge.v, edge.u)))
            #expect(vertices.contains(edge.u) && vertices.contains(edge.v))
        }
        #expect(!tree.contains(-1))
        #expect(!tree.contains(edge: UndirectedEdge(-1, vertices[0])))
        #expect(!tree.contains(edge: UndirectedEdge(vertices[0], vertices[0])))
        // Asking again gives the same answer.
        #expect(Array(tree.vertices) == vertices)
        #expect(Array(tree.edges) == edges)
    }

    @Test("RootedTree satisfies Graph's laws, at every root", arguments: [
        [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)],
        [(4, 2), (0, 2), (2, 1), (1, 3)],
    ])
    func rootedTreeLaws(pairs: [(Int, Int)]) throws {
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        for root in tree.vertices {
            let rooted = RootedTree(tree, root: root)
            let vertices = Array(rooted.vertices)
            let edges = Array(rooted.edges)
            #expect(vertices == Array(tree.vertices))
            #expect(edges == Array(tree.edges))
            #expect(rooted.vertexCount == vertices.count)
            #expect(rooted.edgeCount == edges.count)
            #expect(rooted.vertexIndexBound == vertices.count)
            #expect(rooted.edgeIndexBound == edges.count)
            var degreeSum = 0
            for (i, v) in vertices.enumerated() {
                #expect(rooted.contains(v))
                #expect(rooted.vertex(atIndex: i) == v)
                #expect(rooted.vertexIndex(of: v) == i)
                let row = Array(rooted.incidentEdges(of: v))
                #expect(row == Array(tree.incidentEdges(of: v)), "root \(root), row of \(v)")
                #expect(Array(rooted.neighbors(of: v)) == row.map { edges[$0].oppositeVertex(to: v) })
                #expect(rooted.degree(of: v) == row.count)
                #expect(Array(rooted.incidentEdges(ofIndex: i)) == row)
                #expect(Array(rooted.neighborIndices(ofIndex: i)) == rooted.neighbors(of: v).map { rooted.vertexIndex(of: $0) })
                #expect(Array(rooted.incidentEdgeIndices(ofIndex: i)) == row.map { rooted.edgeIndex(of: $0) })
                // children(of:) is the row without the parent edge, in row order.
                let childRow = row.filter { $0 != rooted.parentEdge(of: v) }
                #expect(Array(rooted.children(of: v)) == childRow.map { edges[$0].oppositeVertex(to: v) }, "root \(root), children of \(v)")
                degreeSum += rooted.degree(of: v)
            }
            #expect(degreeSum == 2 * rooted.edgeCount)
            #expect(edges.indices.map { rooted.edgeIndex(of: $0) } == Array(0 ..< edges.count))
            for edge in edges { #expect(rooted.contains(edge: edge)) }
            #expect(!rooted.contains(-1))
        }
    }

    @Test("Forest satisfies Graph's laws, isolated vertices included", arguments: [
        (vertices: [9], pairs: [(0, 1), (2, 3), (3, 4)]),
        (vertices: [5, 4, 3], pairs: [(3, 4), (0, 1), (2, 3)]),
        (vertices: [0, 1, 2], pairs: []),
    ])
    func forestLaws(source: (vertices: [Int], pairs: [(Int, Int)])) throws {
        let forest = try #require(Forest(vertices: source.vertices, edges: source.pairs.map { UndirectedEdge($0.0, $0.1) }))
        let vertices = Array(forest.vertices)
        let edges = Array(forest.edges)
        #expect(forest.vertexCount == vertices.count)
        #expect(Set(vertices).count == vertices.count)
        #expect(forest.edgeCount == edges.count)
        #expect(forest.vertexIndexBound == vertices.count)
        #expect(forest.edgeIndexBound == edges.count)
        var degreeSum = 0
        for (i, v) in vertices.enumerated() {
            #expect(forest.contains(v))
            #expect(forest.vertex(atIndex: i) == v)
            #expect(forest.vertexIndex(of: v) == i)
            let row = Array(forest.incidentEdges(of: v))
            let expectedRow = edges.indices.filter { edges[$0].u == v || edges[$0].v == v }
            #expect(row == expectedRow, "row of \(v)")
            #expect(Array(forest.neighbors(of: v)) == row.map { edges[$0].oppositeVertex(to: v) })
            #expect(forest.degree(of: v) == row.count)
            #expect(Array(forest.incidentEdges(ofIndex: i)) == row)
            #expect(Array(forest.neighborIndices(ofIndex: i)) == forest.neighbors(of: v).map { forest.vertexIndex(of: $0) })
            #expect(Array(forest.incidentEdgeIndices(ofIndex: i)) == row.map { forest.edgeIndex(of: $0) })
            degreeSum += forest.degree(of: v)
        }
        #expect(degreeSum == 2 * forest.edgeCount)
        #expect(edges.indices.map { forest.edgeIndex(of: $0) } == Array(0 ..< edges.count))
        for edge in edges { #expect(forest.contains(edge: edge)) }
        #expect(!forest.contains(-1))
        #expect(!forest.contains(edge: UndirectedEdge(-1, -2)))
    }

    @Test("Arborescence satisfies DirectedGraph's and BidirectionalDirectedGraph's laws", arguments: [
        [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)],
        [(2, 3), (2, 0), (0, 1)],
        [(1, 2), (0, 1)],
        [(3, 1), (1, 0), (1, 2)],
    ])
    func arborescenceLaws(pairs: [(Int, Int)]) throws {
        let arborescence = try #require(Arborescence(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }))
        let vertices = Array(arborescence.vertices)
        let edges = Array(arborescence.edges)
        #expect(arborescence.vertexCount == vertices.count)
        #expect(Set(vertices).count == vertices.count)
        #expect(arborescence.edgeCount == edges.count)
        #expect(arborescence.vertexIndexBound == vertices.count)
        #expect(arborescence.edgeIndexBound == edges.count)
        var outSum = 0
        var inSum = 0
        for (i, v) in vertices.enumerated() {
            #expect(arborescence.contains(v))
            #expect(arborescence.vertex(atIndex: i) == v)
            #expect(arborescence.vertexIndex(of: v) == i)
            let out = Array(arborescence.outEdges(of: v))
            #expect(out == edges.indices.filter { edges[$0].source == v }, "out of \(v)")
            #expect(out.allSatisfy { arborescence.source(ofEdgeAt: $0) == v })
            #expect(out.allSatisfy { arborescence.target(ofEdgeAt: $0) == edges[$0].target })
            #expect(Array(arborescence.successors(of: v)) == out.map { edges[$0].target })
            #expect(Array(arborescence.successors(of: v)) == Array(arborescence.children(of: v)))
            #expect(arborescence.outDegree(of: v) == out.count)
            #expect(Array(arborescence.outEdges(ofIndex: i)) == out)
            #expect(Array(arborescence.successorIndices(ofIndex: i)) == arborescence.successors(of: v).map { arborescence.vertexIndex(of: $0) })
            let into = Array(arborescence.inEdges(of: v))
            #expect(into == edges.indices.filter { edges[$0].target == v }, "in of \(v)")
            #expect(Array(arborescence.predecessors(of: v)) == into.map { edges[$0].source })
            #expect(into == (arborescence.parentEdge(of: v).map { [$0] } ?? []))
            #expect(Array(arborescence.predecessors(of: v)) == (arborescence.parent(of: v).map { [$0] } ?? []))
            #expect(arborescence.inDegree(of: v) == into.count)
            #expect(arborescence.degree(of: v) == out.count + into.count)
            #expect(Array(arborescence.inEdges(ofIndex: i)) == into)
            #expect(Array(arborescence.predecessorIndices(ofIndex: i)) == arborescence.predecessors(of: v).map { arborescence.vertexIndex(of: $0) })
            outSum += out.count
            inSum += into.count
        }
        #expect(outSum == arborescence.edgeCount)
        #expect(inSum == arborescence.edgeCount)
        #expect(edges.indices.map { arborescence.edgeIndex(of: $0) } == Array(0 ..< edges.count))
        for edge in edges {
            #expect(arborescence.contains(edge: edge))
            #expect(!arborescence.contains(edge: DirectedEdge(from: edge.target, to: edge.source)))
            // Every arc points parent → child.
            #expect(arborescence.parent(of: edge.target) == edge.source)
        }
        #expect(!arborescence.contains(-1))
        #expect(arborescence.inDegree(of: arborescence.root) == 0)
    }
}
