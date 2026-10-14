// The relabelings, binary operations, powers, contractions and closures on every target and over
// every kind of input: the index-space operations agree across CompressedSparseRow, AdjacencyList,
// AdjacencyMatrix and StableDirectedGraph targets, and over CompressedSparseRow, AdjacencyMatrix
// and view inputs with a DirectedPseudograph copy; the label operations agree across AdjacencyList,
// DirectedPseudograph and StableDirectedGraph (UndirectedAdjacencyList and Pseudograph undirected).
// Then the checked spellings of egoGraphView and contraction. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("GraphOperations relabelings, binary operations, powers, contractions and closures on every target", .tags(.conformance))
struct OperationsTargetTests {
    @Test("The index-space operations agree across their construction targets", arguments: [1, 2, 3, 4, 5])
    func indexTargetsAgree(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(400 + seed))
        let n = 4 + seed * 2
        let names = (0 ..< n).map { "x\($0)" }
        var arcs: [DirectedEdge<String>] = []
        for _ in 0 ..< n * 2 { arcs.append(DirectedEdge(from: names.randomElement(using: &rng)!, to: names.randomElement(using: &rng)!)) }
        let g = DirectedPseudograph<String>(vertices: names, edges: arcs)
        let loopless = DirectedPseudograph<String>(vertices: names, edges: arcs.filter { $0.source != $0.target })
        let u = names.randomElement(using: &rng)!, v = names.randomElement(using: &rng)!
        let ordering = names.shuffled(using: &rng)

        let power = CompressedSparseRow.power(of: g, 2)
        #expect(AdjacencyList<Int>.power(of: g, 2).edges.map { $0 } == power.edges.map { $0 })
        #expect(AdjacencyMatrix.power(of: g, 2).edges.map { $0 } == power.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.power(of: g, 2).edges.map { $0 } == power.edges.map { $0 })
        let contraction = CompressedSparseRow.contraction(of: g, u, v)
        #expect(AdjacencyList<Int>.contraction(of: g, u, v).edges.map { $0 } == contraction.edges.map { $0 })
        #expect(AdjacencyMatrix.contraction(of: g, u, v).edges.map { $0 } == contraction.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.contraction(of: g, u, v).edges.map { $0 } == contraction.edges.map { $0 })
        let alongEdge = CompressedSparseRow.contraction(of: g, edgeAt: 0)
        #expect(AdjacencyList<Int>.contraction(of: g, edgeAt: 0).edges.map { $0 } == alongEdge.edges.map { $0 })
        #expect(AdjacencyMatrix.contraction(of: g, edgeAt: 0).edges.map { $0 } == alongEdge.edges.map { $0 })
        let closure = CompressedSparseRow.transitiveClosure(of: g)
        #expect(AdjacencyList<Int>.transitiveClosure(of: g).edges.map { $0 } == closure.edges.map { $0 })
        #expect(AdjacencyMatrix.transitiveClosure(of: g).edges.map { $0 } == closure.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.transitiveClosure(of: g).edges.map { $0 } == closure.edges.map { $0 })
        let reduction = CompressedSparseRow.transitiveReduction(of: g)
        #expect(AdjacencyList<Int>.transitiveReduction(of: g).edges.map { $0 } == reduction.edges.map { $0 })
        #expect(AdjacencyMatrix.transitiveReduction(of: g).edges.map { $0 } == reduction.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.transitiveReduction(of: g).edges.map { $0 } == reduction.edges.map { $0 })
        let relabeled = CompressedSparseRow.relabeled(loopless, ordering: ordering)
        #expect(AdjacencyList<Int>.relabeled(loopless, ordering: ordering).edges.map { $0 } == relabeled.edges.map { $0 })
        #expect(AdjacencyMatrix.relabeled(loopless, ordering: ordering).edges.map { $0 } == relabeled.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.relabeled(loopless, ordering: ordering).edges.map { $0 } == relabeled.edges.map { $0 })
        for result in [power, contraction, alongEdge, closure, reduction, relabeled] {
            #expect(Array(result.vertices) == Array(0 ..< result.vertexCount))
        }

        // Undirected: the one construction target, over a Pseudograph and an UndirectedAdjacencyList.
        let ug = Pseudograph<String>(vertices: names, edges: arcs.map { UndirectedEdge($0.source, $0.target) })
        let simple = UndirectedAdjacencyList<String>(vertices: names, edges: arcs.filter { $0.source != $0.target }.map { UndirectedEdge($0.source, $0.target) })
        let ugLoopless = Pseudograph<String>(vertices: names, edges: arcs.filter { $0.source != $0.target }.map { UndirectedEdge($0.source, $0.target) })
        #expect(UndirectedAdjacencyList<Int>.power(of: ug, 2).edges.map { $0 } == UndirectedAdjacencyList<Int>.power(of: simple, 2).edges.map { $0 })
        #expect(UndirectedAdjacencyList<Int>.contraction(of: ug, u, v).edges.map { $0 } == UndirectedAdjacencyList<Int>.contraction(of: simple, u, v).edges.map { $0 })
        #expect(UndirectedAdjacencyList<Int>.relabeled(ugLoopless, ordering: ordering).edges.map { $0 } == UndirectedAdjacencyList<Int>.relabeled(simple, ordering: ordering).edges.map { $0 })
    }

    @Test("The index-space operations read CompressedSparseRow, AdjacencyMatrix and view inputs as their copies", arguments: [1, 2, 3])
    func indexInputsAgree(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(500 + seed))
        let n = 5 + seed * 2
        var arcs: [DirectedEdge<Int>] = []
        for _ in 0 ..< n * 2 {
            let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
            if a != b { arcs.append(DirectedEdge(from: a, to: b)) }
        }
        let csr = CompressedSparseRow(vertexCount: n, edges: arcs)
        var matrix = AdjacencyMatrix(vertexCount: n)
        for arc in arcs { matrix.insert(edge: arc) }
        let pseudo = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
        let keep = (0 ..< n).filter { _ in Int.random(in: 0 ..< 4, using: &rng) != 0 }
        let induced = pseudo.inducedSubgraphView(on: keep)
        let inducedCopy = DirectedPseudograph<Int>(vertices: induced.vertices, edges: induced.edges)
        let reversed = pseudo.transposedView
        let reversedCopy = DirectedPseudograph<Int>(vertices: reversed.vertices, edges: reversed.edges)

        func same(_ a: CompressedSparseRow, _ b: CompressedSparseRow, _ what: String) {
            #expect(a.vertexCount == b.vertexCount && a.edges.map { $0 } == b.edges.map { $0 }, "\(what)")
        }
        for (k, what) in [(1, "k = 1"), (3, "k = 3")] {
            same(CompressedSparseRow.power(of: csr, k), CompressedSparseRow.power(of: pseudo, k), "power csr \(what)")
            same(CompressedSparseRow.power(of: matrix, k), CompressedSparseRow.power(of: pseudo, k), "power matrix \(what)")
            same(CompressedSparseRow.power(of: induced, k), CompressedSparseRow.power(of: inducedCopy, k), "power induced \(what)")
            same(CompressedSparseRow.power(of: reversed, k), CompressedSparseRow.power(of: reversedCopy, k), "power reversed \(what)")
        }
        same(CompressedSparseRow.transitiveClosure(of: csr), CompressedSparseRow.transitiveClosure(of: pseudo), "closure csr")
        same(CompressedSparseRow.transitiveClosure(of: matrix), CompressedSparseRow.transitiveClosure(of: pseudo), "closure matrix")
        same(CompressedSparseRow.transitiveClosure(of: induced), CompressedSparseRow.transitiveClosure(of: inducedCopy), "closure induced")
        same(CompressedSparseRow.transitiveReduction(of: reversed), CompressedSparseRow.transitiveReduction(of: reversedCopy), "reduction reversed")
        same(CompressedSparseRow.transitiveReduction(of: matrix), CompressedSparseRow.transitiveReduction(of: pseudo), "reduction matrix")
        same(CompressedSparseRow.contraction(of: csr, 0, n - 1), CompressedSparseRow.contraction(of: pseudo, 0, n - 1), "contraction csr")
        same(CompressedSparseRow.contraction(of: matrix, 1, 2), CompressedSparseRow.contraction(of: pseudo, 1, 2), "contraction matrix")
        if let first = keep.first, let last = keep.last {
            same(CompressedSparseRow.contraction(of: induced, first, last), CompressedSparseRow.contraction(of: inducedCopy, first, last), "contraction induced")
        }
        let order = Array((0 ..< n).reversed())
        same(CompressedSparseRow.relabeled(csr, ordering: order), CompressedSparseRow.relabeled(pseudo, ordering: order), "relabeled csr")
        same(CompressedSparseRow.relabeled(matrix, ordering: order), CompressedSparseRow.relabeled(pseudo, ordering: order), "relabeled matrix")

        // The ego graph over a CompressedSparseRow base and over a view.
        let ego = csr.egoGraphView(of: 0, radius: 2)
        let egoCopy = pseudo.egoGraphView(of: 0, radius: 2)
        #expect(Array(ego.vertices) == Array(egoCopy.vertices))
        // The base keeps arcs in row-major order with repeats merged; the copy in insertion order.
        #expect(Set(ego.edges.map { [$0.source, $0.target] }) == Set(egoCopy.edges.map { [$0.source, $0.target] }))
        if let center = keep.first {
            let nested = induced.egoGraphView(of: center, radius: 1, undirected: true)
            let nestedCopy = inducedCopy.egoGraphView(of: center, radius: 1, undirected: true)
            #expect(Array(nested.vertices) == Array(nestedCopy.vertices))
            #expect(nested.edges.map { $0 } == nestedCopy.edges.map { $0 })
        }
    }

    @Test("The label operations agree across their mutable targets", arguments: [1, 2, 3, 4])
    func labelTargetsAgree(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(600 + seed))
        let pool = (0 ..< 8).map { "y\($0)" }
        let gNames = pool.filter { _ in Int.random(in: 0 ..< 4, using: &rng) != 0 }
        let hNames = pool.filter { _ in Int.random(in: 0 ..< 4, using: &rng) != 0 }.shuffled(using: &rng)
        var gArcs: [DirectedEdge<String>] = [], hArcs: [DirectedEdge<String>] = []
        if !gNames.isEmpty { for _ in 0 ..< 12 { gArcs.append(DirectedEdge(from: gNames.randomElement(using: &rng)!, to: gNames.randomElement(using: &rng)!)) } }
        if !hNames.isEmpty { for _ in 0 ..< 12 { hArcs.append(DirectedEdge(from: hNames.randomElement(using: &rng)!, to: hNames.randomElement(using: &rng)!)) } }
        let g = DirectedPseudograph<String>(vertices: gNames, edges: gArcs)
        let h = AdjacencyList<String>(vertices: hNames, edges: hArcs)
        let stableH = StableDirectedGraph<String>(vertices: hNames, edges: hArcs)

        for (list, pseudo, stable, what) in [
            (AdjacencyList<String>.union(g, h), DirectedPseudograph<String>.union(g, h), StableDirectedGraph<String>.union(g, stableH), "union"),
            (AdjacencyList<String>.intersection(g, h), DirectedPseudograph<String>.intersection(g, h), StableDirectedGraph<String>.intersection(g, stableH), "intersection"),
            (AdjacencyList<String>.difference(g, h), DirectedPseudograph<String>.difference(g, h), StableDirectedGraph<String>.difference(g, stableH), "difference"),
            (AdjacencyList<String>.symmetricDifference(g, h), DirectedPseudograph<String>.symmetricDifference(g, h), StableDirectedGraph<String>.symmetricDifference(g, stableH), "symmetricDifference"),
        ] {
            #expect(Array(list.vertices) == Array(pseudo.vertices) && Array(list.vertices) == Array(stable.vertices), "\(what)")
            #expect(list.edges.map { $0 } == pseudo.edges.map { $0 } && list.edges.map { $0 } == stable.edges.map { $0 }, "\(what)")
        }
        // A one-to-one relabeling keeps every edge on each target that keeps parallel edges.
        let rename: (String) -> String = { $0.uppercased() }
        let relabeled = DirectedPseudograph<String>.relabeled(g, by: rename)
        #expect(StableDirectedGraph<String>.relabeled(g, by: rename).edges.map { $0 } == relabeled.edges.map { $0 })
        #expect(relabeled.edges.map { $0 } == gArcs.map { DirectedEdge(from: rename($0.source), to: rename($0.target)) })
        #expect(AdjacencyList<String>.relabeled(g, by: rename) == AdjacencyList<String>(vertices: gNames.map(rename), edges: gArcs.map { DirectedEdge(from: rename($0.source), to: rename($0.target)) }))

        // Undirected.
        let ug = Pseudograph<String>(vertices: gNames, edges: gArcs.map { UndirectedEdge($0.source, $0.target) })
        let uh = UndirectedAdjacencyList<String>(vertices: hNames, edges: hArcs.map { UndirectedEdge($0.source, $0.target) })
        for (list, pseudo, what) in [
            (UndirectedAdjacencyList<String>.union(ug, uh), Pseudograph<String>.union(ug, uh), "union"),
            (UndirectedAdjacencyList<String>.intersection(ug, uh), Pseudograph<String>.intersection(ug, uh), "intersection"),
            (UndirectedAdjacencyList<String>.difference(ug, uh), Pseudograph<String>.difference(ug, uh), "difference"),
            (UndirectedAdjacencyList<String>.symmetricDifference(ug, uh), Pseudograph<String>.symmetricDifference(ug, uh), "symmetricDifference"),
        ] {
            #expect(Array(list.vertices) == Array(pseudo.vertices), "\(what)")
            #expect(list.edges.map { [$0.u, $0.v] } == pseudo.edges.map { [$0.u, $0.v] }, "\(what)")
        }
        #expect(Pseudograph<String>.relabeled(ug, by: rename).edges.map { [$0.u, $0.v] } == gArcs.map { [rename($0.source), rename($0.target)] })
    }

    @Test("Closure and reduction past one 64-bit word of components: a long path, and a long cycle with a tail")
    func manyComponents() {
        let n = 150
        let path = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
        let closure = CompressedSparseRow.transitiveClosure(of: path)
        #expect(closure.edgeCount == n * (n - 1) / 2)
        #expect(Array(closure.successors(of: 3)) == Array(4 ..< n))
        // Every shortcut added back is dropped again.
        let closed = CompressedSparseRow(vertexCount: n, edges: closure.edges)
        let reduction = CompressedSparseRow.transitiveReduction(of: closed)
        #expect(reduction.edges.map { [$0.source, $0.target] } == (0 ..< n - 1).map { [$0, $0 + 1] })
        // Vertices 0..<100 on a cycle traversed backwards, then a tail of 50 hanging off vertex 99.
        var arcs = (1 ..< 100).map { DirectedEdge(from: $0, to: $0 - 1) } + [DirectedEdge(from: 0, to: 99)]
        arcs += (99 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) }
        arcs.append(DirectedEdge(from: 5, to: n - 1))
        let mixed = CompressedSparseRow(vertexCount: n, edges: arcs)
        let mixedClosure = CompressedSparseRow.transitiveClosure(of: mixed)
        #expect(mixedClosure.edgeCount == 100 * (n - 1) + (n - 100) * (n - 101) / 2)
        let mixedReduction = CompressedSparseRow.transitiveReduction(of: mixed)
        let expected = (0 ..< 99).map { [$0, $0 + 1] } + [[0, 100]] + [[99, 0]] + (100 ..< n - 1).map { [$0, $0 + 1] }
        #expect(mixedReduction.edges.map { [$0.source, $0.target] } == expected.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) })
    }

    @Test("egoGraphView(checkedOf:) throws VertexNotFound for a missing center and otherwise is the plain view")
    func checkedEgoGraph() throws {
        let directed = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "a")])
        #expect(throws: VertexNotFound.self) { _ = try directed.egoGraphView(checkedOf: "z") }
        #expect(throws: VertexNotFound.self) { _ = try directed.egoGraphView(checkedOf: "z", radius: 2, undirected: true) }
        let view = try directed.egoGraphView(checkedOf: "a")
        #expect(Array(view.vertices) == ["a", "b"] && Array(view.edges.indices) == [0])
        let both = try directed.egoGraphView(checkedOf: "a", radius: 1, undirected: true)
        #expect(Array(both.vertices) == ["a", "b", "c"] && Array(both.edges.indices) == [0, 1])
        let csr = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(throws: VertexNotFound.self) { _ = try csr.egoGraphView(checkedOf: 3) }
        #expect(throws: VertexNotFound.self) { _ = try csr.egoGraphView(checkedOf: -1) }
        #expect(Array(try csr.egoGraphView(checkedOf: 1).vertices) == [1])
        let undirected = UndirectedAdjacencyList<String>(vertices: ["p", "q", "r"], edges: [UndirectedEdge("p", "q")])
        #expect(throws: VertexNotFound.self) { _ = try undirected.egoGraphView(checkedOf: "z", radius: 3) }
        let ego = try undirected.egoGraphView(checkedOf: "q")
        #expect(Array(ego.vertices) == ["p", "q"] && Array(ego.edges.indices) == [0])
    }

    @Test("contraction(of:checked:_:) throws VertexNotFound for either missing vertex and otherwise is the plain contraction")
    func checkedContraction() throws {
        let directed = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        #expect(throws: VertexNotFound.self) { _ = try CompressedSparseRow.contraction(of: directed, checked: "z", "a") }
        #expect(throws: VertexNotFound.self) { _ = try CompressedSparseRow.contraction(of: directed, checked: "a", "z") }
        let merged = try CompressedSparseRow.contraction(of: directed, checked: "c", "a")
        #expect(merged.vertexCount == 2 && merged.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        let undirected = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        #expect(throws: VertexNotFound.self) { _ = try UndirectedAdjacencyList<Int>.contraction(of: undirected, checked: "z", "a") }
        #expect(throws: VertexNotFound.self) { _ = try UndirectedAdjacencyList<Int>.contraction(of: undirected, checked: "a", "z") }
        let joined = try UndirectedAdjacencyList<Int>.contraction(of: undirected, checked: "a", "c")
        #expect(joined.vertexCount == 2 && joined.edges.map { [$0.u, $0.v] } == [[0, 1]])
    }
}
