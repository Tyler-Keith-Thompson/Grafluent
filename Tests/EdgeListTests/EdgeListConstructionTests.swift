// Construction, vertices implied by endpoints, parallel edges and order. Case IDs (EL-Cnn, EL-Vnn,
// EL-Mnn, EL-Onn) refer to the catalog of cases harvested from Boost.Graph, petgraph, NetworkX,
// igraph, JGraphT, rustworkx, scipy, GAP, neo4j's graph crate, LEMON, gonum and the Swift Algorithm
// Club; see README.md. Expected values come from those suites or were computed independently of
// the code under test.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import EdgeListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("EdgeList construction")
struct EdgeListConstructionTests {
    // MARK: Empty and literal forms

    @Test("EL-C01 the empty list has no edges and no vertices")
    func empty() {
        let list = EdgeList<Int>()
        #expect(list.isEmpty)
        #expect(list.count == 0)
        #expect(list.edgeCount == 0)
        #expect(list.startIndex == 0)
        #expect(list.endIndex == 0)
        #expect(list.vertices == [])
        #expect(list.vertexCount == 0)
        #expect(EdgeList<Int>([]) == list)
    }

    @Test("EL-C02 / EL-C03 an array literal, including the empty one")
    func arrayLiteral() {
        let list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
        #expect(list == EdgeList([DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(Array(list) == DirectedFixture<Int>.directedPath3.edges)
        let none: EdgeList<Int> = []
        #expect(none == EdgeList())
    }

    @Test("EL-C04 a literal keeps repeats and order verbatim")
    func literalKeepsRepeats() {
        let list: EdgeList<Int> = [DirectedEdge(from: 1, to: 3), DirectedEdge(from: 1, to: 3)]
        #expect(list.count == 2)
        #expect(list[0] == list[1])
        #expect(EdgeList(DirectedFixture<Int>.pathWithChord.edges).count == 7)
    }

    // MARK: From sequences

    @Test("EL-C05 / EL-O01 a list holds exactly the edges given, in order, repeats included", .tags(.fixture), arguments: DirectedFixture<Int>.all + DirectedFixture<Int>.realWorld)
    func fromFixture(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        #expect(list.count == fixture.edges.count)
        #expect(list.edgeCount == fixture.edges.count)
        #expect(Array(list) == fixture.edges)
        #expect(list.elementsEqual(fixture.edges))
    }

    @Test("EL-C05 written counts of the fixtures with repeated edges")
    func writtenCounts() {
        #expect(EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges).count == 8)
        #expect(EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges).count == 13)
        #expect(EdgeList(DirectedFixture<Int>.gap4.edges).count == 256)
        #expect(EdgeList(DirectedFixture<Int>.graph500Scale8.edges).count == 4096)
    }

    @Test("EL-C06 a sequence that can be read only once gives the same list", arguments: UnderestimatedCount.all)
    func singlePass(_ underestimatedCount: UnderestimatedCount) {
        let edges = DirectedFixture<Int>.boostCsrUnsorted.edges
        let list = EdgeList(MinimalSequence(elements: edges, underestimatedCount: underestimatedCount))
        #expect(Array(list) == edges)
    }

    @Test("EL-C07 a lazy sequence gives its edges in order")
    func lazySequence() {
        let list = EdgeList((0 ..< 10).lazy.map { DirectedEdge(from: $0, to: ($0 + 1) % 10) })
        #expect(Array(list) == DirectedFixture<Int>.directedCycle10.edges)
    }

    @Test("EL-C08 construction does not reorder")
    func noReordering() {
        // Boost.Graph csr_graph_test.cpp unsorted input; CSR would sort it.
        let list = EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges)
        #expect(Array(list) == [
            DirectedEdge(from: 5, to: 0), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 1),
            DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 5, to: 2),
        ])
    }

    @Test("EL-C09 / EL-M01 construction does not collapse: parallel edges are at distinct positions")
    func noCollapsing() {
        // JGraphT SimpleIdentityDirectedGraphTest gives the three 2→4 edges ids 5, 6 and 7.
        let list = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        let twoFour = DirectedEdge(from: 2, to: 4)
        #expect(list[5] == twoFour)
        #expect(list[6] == twoFour)
        #expect(list[7] == twoFour)
        #expect(list.indices.filter { list[$0] == twoFour } == [5, 6, 7])
    }

    @Test("EL-C10 self-loops are ordinary elements", .tags(.selfLoops))
    func selfLoops() {
        let list = EdgeList(DirectedFixture<Int>.petgraphCsr1.edges)
        #expect(list.indices.filter { list[$0].isSelfLoop } == [0, 2, 5])
    }

    @Test("EL-C11 a list from another graph's edges takes them in that graph's order")
    func fromAnotherGraphsEdges() {
        let edges = DirectedFixture<Int>.house.edges
        let rowMajor = [
            DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 2),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 1),
            DirectedEdge(from: 5, to: 3),
        ]
        #expect(Array(EdgeList(CompressedSparseRow(vertexCount: 6, edges: edges).edges)) == rowMajor)
        #expect(Array(EdgeList(AdjacencyMatrix(vertexCount: 6, edges: edges).edges)) == rowMajor)
        let graph = AdjacencyList(edges: edges)
        let fromList = EdgeList(graph.edges)
        #expect(Array(fromList) == Array(graph.edges))
        #expect(fromList.count == 7)
    }

    @Test("EL-C21 parallel arrays of sources and targets")
    func parallelArrays() {
        let edges = DirectedFixture<Int>.jgraphtSparseDirected.edges
        let list = EdgeList(sources: edges.map(\.source), targets: edges.map(\.target))
        #expect(Array(list) == edges)
        #expect(EdgeList(sources: [String](), targets: []) == EdgeList())
        #expect(Array(EdgeList(sources: ["a", "b"], targets: ["b", "a"])) == [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
    }

    @Test("EL-C22 Array(list) and EdgeList(list) share the storage rather than copying it")
    func sharesStorage() {
        let list = EdgeList(DirectedFixture<Int>.boost24.edges)
        let listAddress = list.withContiguousStorageIfAvailable { $0.baseAddress }
        let array = Array(list)
        #expect(array.withUnsafeBufferPointer { $0.baseAddress } == listAddress)
        let copy = EdgeList(list)
        #expect(copy.withContiguousStorageIfAvailable { $0.baseAddress } == listAddress)
        #expect(copy == list)
    }

    @Test("EL-C12 repeating one edge makes parallel copies")
    func repeating() {
        let edge = DirectedEdge(from: 0, to: 1)
        let list = EdgeList(repeating: edge, count: 3)
        #expect(list.count == 3)
        #expect(list.multiplicity(of: edge) == 3)
        #expect(list.vertices == [0, 1])
        #expect(EdgeList(repeating: edge, count: 0) == EdgeList())
    }

    @Test("EL-C13 reserving capacity does not change the contents")
    func reserveCapacity() {
        var reserved = EdgeList<Int>()
        reserved.reserveCapacity(10_000)
        var plain = EdgeList<Int>()
        for k in 0 ..< 10_000 {
            reserved.append(DirectedEdge(from: k % 97, to: k % 89))
            plain.append(DirectedEdge(from: k % 97, to: k % 89))
        }
        #expect(reserved == plain)
        #expect(reserved.count == 10_000)
    }

    // MARK: Builder

    @Test("EL-C15 the builder gives edges in statement order, repeats included, through for, if and switch")
    func builder() {
        let includeChord = true
        let list = EdgeList<Int> {
            for k in 0 ..< 5 {
                DirectedEdge(from: k, to: k + 1)
            }
            if includeChord {
                DirectedEdge(from: 1, to: 3)
            } else {
                DirectedEdge(from: 0, to: 0)
            }
            switch includeChord {
            case true: DirectedEdge(from: 1, to: 3)
            case false: DirectedEdge(from: 9, to: 9)
            }
        }
        #expect(Array(list) == DirectedFixture<Int>.pathWithChord.edges)
        #expect(list[5] == list[6])
    }

    @Test("EL-C16 an empty builder body gives the empty list")
    func emptyBuilder() {
        let list = EdgeList<Int> {}
        #expect(list == EdgeList())
    }

    // MARK: Vertex types

    @Test("EL-C17 String vertices")
    func stringVertices() {
        let abcd = DirectedFixture<String>.networkXABCD
        let list = EdgeList(abcd.edges)
        #expect(list.count == 5)
        // G, J and K are isolated in the fixture; an edge list cannot hold them.
        #expect(list.vertices == ["A", "B", "C", "D"])
    }

    @Test("EL-C18 vertices that all hash alike are still told apart")
    func colliders() {
        var edges: [DirectedEdge<Collider>] = []
        for k in 0 ..< 20 {
            edges.append(DirectedEdge(from: Collider(k % 10), to: Collider((k * 3) % 10)))
        }
        let list = EdgeList(edges)
        #expect(Array(list) == edges)
        #expect(list.vertexCount == 10)
        for k in 0 ..< 20 {
            #expect(list.contains(edge: DirectedEdge(from: Collider(k % 10), to: Collider((k * 3) % 10))))
        }
        #expect(!list.contains(edge: DirectedEdge(from: Collider(0), to: Collider(1))))
    }

    @Test("EL-C19 equal but distinct instances are stored as given")
    func instancesAsGiven() {
        let a1 = HashableBox(1, label: "first")
        let a2 = HashableBox(1, label: "second")
        let b = HashableBox(2)
        let list = EdgeList([DirectedEdge(from: a1, to: b), DirectedEdge(from: a2, to: b)])
        #expect(list[0].source === a1)
        #expect(list[1].source === a2)
        // vertices lists each value once, as its first appearance.
        #expect(list.vertices.count == 2)
        #expect(list.vertices[0] === a1)
    }

    @Test("EL-C20 extreme Int vertices are ordinary values")
    func extremeInts() {
        let list = EdgeList([DirectedEdge(from: Int.min, to: Int.max), DirectedEdge(from: -1, to: Int.min)])
        #expect(list.vertices == [Int.min, Int.max, -1])
        #expect(list.outDegree(of: Int.min) == 1)
        #expect(list.inDegree(of: Int.min) == 1)
    }
}

@Suite("EdgeList vertices")
struct EdgeListVertexTests {
    @Test("EL-V01 vertices are the endpoints, each once, in first-appearance order")
    func firstAppearance() {
        #expect(EdgeList(DirectedFixture<Int>.house.edges).vertices == [5, 3, 4, 2, 0, 1])
        #expect(EdgeList(DirectedFixture<Int>.boostCsrUnsorted.edges).vertices == [5, 0, 3, 2, 4, 1])
        #expect(EdgeList(DirectedFixture<Int>.scc9.edges).vertices == [6, 0, 3, 8, 2, 5, 7, 1, 4])
    }

    @Test("EL-V02 / EL-V03 vertexCount and contains agree with the endpoints", .tags(.fixture), arguments: DirectedFixture<Int>.all + DirectedFixture<Int>.realWorld)
    func endpoints(_ fixture: DirectedFixture<Int>) {
        let list = EdgeList(fixture.edges)
        let endpoints = Set(fixture.edges.flatMap { [$0.source, $0.target] })
        #expect(Set(list.vertices) == endpoints)
        #expect(list.vertices.count == endpoints.count)
        #expect(list.vertexCount == endpoints.count)
        for v in fixture.vertexSet {
            #expect(list.contains(v) == endpoints.contains(v), "contains(\(v))")
        }
        #expect(!list.contains(-1))
    }

    @Test("EL-V03 a listed isolated vertex is not a vertex of the edge list")
    func listedIsolatedVertex() {
        let list = EdgeList(DirectedFixture<Int>.petgraphCsrFrom.edges)
        #expect(!list.contains(3))
        #expect(list.contains(4))
    }

    @Test("EL-V04 a self-loop's vertex appears once", .tags(.selfLoops))
    func selfLoopVertex() {
        #expect(EdgeList(DirectedFixture<Int>.singleSelfLoop.edges).vertices == [0])
    }

    @Test("EL-V05 isolated vertices of a fixture are not present")
    func isolatedLost() {
        let cases: [(DirectedFixture<Int>, Int)] = [
            (.trivial, 0), (.isolatedVertices, 0), (.networkXFunctionGraph, 4), (.scipyConstructor2, 2),
            (.gap4, 13), (.graph500Scale8, 241), (.ligraRMat, 125),
        ]
        for (fixture, endpoints) in cases {
            #expect(EdgeList(fixture.edges).vertexCount == endpoints, "\(fixture.name)")
        }
        #expect(!EdgeList(DirectedFixture<Int>.gap4.edges).contains(5))
        #expect(EdgeList(DirectedFixture<String>.networkXABCD.edges).vertexCount == 4)
    }

    @Test("EL-V06 removing the last edge at a vertex removes the vertex")
    func vertexDisappears() {
        var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
        list.remove(at: 0)
        #expect(list.vertices == [1, 2])
        #expect(!list.contains(0))
    }

    @Test("EL-V07 removing the edges at one vertex can remove other vertices too")
    func otherVerticesDisappear() {
        var list = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(list.removeEdges(incidentTo: 2) == 5)
        #expect(Array(list) == [DirectedEdge(from: 4, to: 4), DirectedEdge(from: 5, to: 5), DirectedEdge(from: 5, to: 5)])
        #expect(list.vertices == [4, 5])
    }

    @Test("EL-V08 the vertices array is a value")
    func verticesAreValues() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        let vertices = list.vertices
        list.removeAll()
        #expect(vertices == [5, 3, 4, 2, 0, 1])
        #expect(list.vertices == [])
    }

    @Test("EL-V10 vertices of a large random list", .tags(.randomized))
    func largeRandom() {
        var generator = SeededRandomNumberGenerator(seed: 10)
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< 100_000 {
            edges.append(DirectedEdge(from: Int.random(in: 0 ..< 1000, using: &generator), to: Int.random(in: 0 ..< 1000, using: &generator)))
        }
        let list = EdgeList(edges)
        var seen = Set<Int>()
        var expected: [Int] = []
        for edge in edges {
            if seen.insert(edge.source).inserted { expected.append(edge.source) }
            if seen.insert(edge.target).inserted { expected.append(edge.target) }
        }
        #expect(list.vertices == expected)
        #expect(list.vertexCount == expected.count)
    }
}

@Suite("EdgeList parallel edges and self-loops")
struct EdgeListParallelEdgeTests {
    @Test("EL-M02 / EL-M03 multiplicities and distinct counts of real data")
    func multiplicities() {
        let gap = EdgeList(DirectedFixture<Int>.gap4.edges)
        #expect(gap.multiplicity(of: DirectedEdge(from: 0, to: 0)) == 27)
        #expect(gap.multiplicity(of: DirectedEdge(from: 0, to: 8)) == 21)
        #expect(gap.multiplicity(of: DirectedEdge(from: 0, to: 7)) == 21)
        #expect(Set(gap).count == 58)
        let graph500 = EdgeList(DirectedFixture<Int>.graph500Scale8.edges)
        #expect(graph500.multiplicity(of: DirectedEdge(from: 82, to: 82)) == 42)
        #expect(graph500.multiplicity(of: DirectedEdge(from: 82, to: 231)) == 39)
        #expect(Set(graph500).count == 2171)
        let sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(sparse.multiplicity(of: DirectedEdge(from: 2, to: 4)) == 3)
        #expect(Set(sparse).count == 11)
        #expect(Set(EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)).count == 6)
        #expect(Set(EdgeList(DirectedFixture<Int>.pathWithChord.edges)).count == 6)
    }

    @Test("EL-M04 degrees count every parallel edge")
    func multigraphDegrees() {
        // JGraphT SimpleIdentityDirectedGraphTest's multigraph assertions.
        let list = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        let out = [0: 1, 1: 4, 2: 3, 3: 1, 4: 1, 5: 1, 6: 0, 7: 2]
        let into = [0: 1, 1: 1, 2: 0, 3: 0, 4: 5, 5: 2, 6: 3, 7: 1]
        for v in 0 ..< 8 {
            #expect(list.outDegree(of: v) == out[v], "outDegree(of: \(v))")
            #expect(list.inDegree(of: v) == into[v], "inDegree(of: \(v))")
        }
    }

    @Test("EL-M05 / EL-M07 degrees with repeated self-loops", .tags(.selfLoops))
    func selfLoopDegrees() {
        // JGraphT IncomingOutgoingEdgesTest, DirectedPseudograph.
        let list = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        let out = [1: 1, 2: 3, 3: 0, 4: 1, 5: 3]
        let into = [1: 0, 2: 2, 3: 2, 4: 2, 5: 2]
        for v in 1 ... 5 {
            #expect(list.outDegree(of: v) == out[v], "outDegree(of: \(v))")
            #expect(list.inDegree(of: v) == into[v], "inDegree(of: \(v))")
            #expect(list.degree(of: v) == out[v]! + into[v]!, "degree(of: \(v))")
        }
        #expect(list.degree(of: 5) == 5)
    }

    @Test("EL-M06 degrees with a repeated chord")
    func chordDegrees() {
        // NetworkX TestOutMultiDegreeView / TestInMultiDegreeView.
        let list = EdgeList(DirectedFixture<Int>.pathWithChord.edges)
        #expect(list.outDegree(of: 1) == 3)
        #expect(list.inDegree(of: 3) == 3)
    }

    @Test("EL-M08 successors list a target once per parallel edge, in edge order")
    func successorsWithMultiplicity() {
        let loops = EdgeList(DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        #expect(Array(loops.successors(of: 5)) == [5, 2, 5])
        let sparse = EdgeList(DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(Array(sparse.successors(of: 2)) == [4, 4, 4])
    }

    @Test("EL-M09 collapsing is a conversion; the list keeps its repeats")
    func collapsingIsAConversion() {
        let list = EdgeList(DirectedFixture<Int>.gap4.edges)
        #expect(Set(list).count == 58)
        #expect(list.count == 256)
    }
}

@Suite("EdgeList order and identity")
struct EdgeListOrderTests {
    @Test("EL-O02 append puts the edge last and moves nothing")
    func appendAtEnd() {
        var list = EdgeList(DirectedFixture<Int>.house.edges)
        let before = Array(list)
        list.append(DirectedEdge(from: 0, to: 5))
        #expect(list.count == 8)
        #expect(list[7] == DirectedEdge(from: 0, to: 5))
        #expect(Array(list.prefix(7)) == before)
    }

    @Test("EL-O03 remove(at:) shifts later edges down, keeping their order")
    func removeShifts() {
        // petgraph's remove_edge swaps the last edge into the hole instead.
        var list: EdgeList<Int> = [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 4, to: 0),
        ]
        list.remove(at: 0)
        #expect(Array(list) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 4, to: 0)])
    }

    @Test("EL-O04 removeAll(where:) keeps the survivors in order")
    func removeAllKeepsOrder() {
        // petgraph's retain_edges returns the survivors reversed.
        var list: EdgeList<Int> = [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 5),
        ]
        list.removeAll { $0.source % 2 == 0 }
        #expect(Array(list) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 4)])
    }

    @Test("EL-O05 an append after a removal goes to the end, never into the freed position")
    func noSlotReuse() {
        // rustworkx reuses the freed slot: [(3, 0), (1, 2), (2, 3)].
        var list: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]
        list.remove(at: 0)
        list.append(DirectedEdge(from: 3, to: 0))
        #expect(Array(list) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
    }

    @Test("EL-O06 order is part of the value")
    func orderMatters() {
        let a: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]
        let b: EdgeList<Int> = [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)]
        #expect(a != b)
        #expect(Set(a) == Set(b))
    }

    @Test("EL-O08 order does not depend on hashing")
    func orderIndependentOfHashing() {
        let edges = DirectedFixture<Int>.boost24.edges
        let ints = EdgeList(edges)
        let colliders = EdgeList(edges.map { DirectedEdge(from: Collider($0.source), to: Collider($0.target)) })
        #expect(ints.map(\.source) == colliders.map(\.source.value))
        #expect(ints.map(\.target) == colliders.map(\.target.value))
        #expect(ints.vertices == colliders.vertices.map(\.value))
    }
}
