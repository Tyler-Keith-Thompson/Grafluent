// Algorithms see through the views. Traversal, Connectivity and ShortestPaths run on seeded random
// views (reverseView, the three subgraph entry points and complement, over directed and undirected
// pseudographs, and over CompressedSparseRow and AdjacencyMatrix bases), and every result must be
// exactly the same algorithm's result on a materialized copy of the view: `DirectedPseudograph(view)`
// or `Pseudograph(view)`, which keeps the vertices in order and puts the view's k-th edge (in `edges`
// order) at position k. So a view position p maps to its offset in `view.edges`, and the
// subgraph and reverse views' positions are the base's own. Then the materialized operations agree
// across their construction targets, and the condensation DAG's order is a topological order. See
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import Multigraphs
import ShortestPaths
import StableGraphs
import Testing
import Traversal

@Suite("GraphOperations conformances and algorithms", .tags(.conformance))
struct GraphOperationsConformanceTests {
    @Test("Directed views: Traversal, Connectivity and ShortestPaths equal a materialized copy's", arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func directedViewsAgainstCopies(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 4 + seed * 2
        let names = (0 ..< n).map { "v\($0)" }.shuffled(using: &rng)
        var edges: [DirectedEdge<String>] = []
        for _ in 0 ..< n * (seed % 3 + 1) {
            edges.append(DirectedEdge(from: names.randomElement(using: &rng)!, to: names.randomElement(using: &rng)!))
        }
        // Parallel arcs and self-loops on purpose.
        edges += edges.prefix(seed % 4)
        edges.append(DirectedEdge(from: names[0], to: names[0]))
        let base = DirectedPseudograph<String>(vertices: names, edges: edges)
        let keep = names.filter { _ in Int.random(in: 0 ..< 4, using: &rng) != 0 }
        let positions = base.edges.indices.filter { _ in Bool.random(using: &rng) }

        // One check for every view, written once here and called below.
        func check<View: BidirectionalDirectedGraph>(_ view: View, _ what: String) where View.Vertex == String {
            let copy = DirectedPseudograph<String>(view)
            let order = Array(view.edges.indices)
            var ordinal: [View.Edges.Index: Int] = [:]
            for (k, p) in order.enumerated() { ordinal[p] = k }
            let weight = (0 ..< order.count).map { ($0 &* 2_654_435_761 &+ seed) % 9 + 1 }
            #expect(Array(view.vertices) == Array(copy.vertices), "\(what)")
            #expect(view.edges.map { $0 } == copy.edges.map { $0 }, "\(what)")
            #expect(view.edgeCount == copy.edgeCount && view.vertexCount == copy.vertexCount, "\(what)")
            #expect(view.topologicalSort() == copy.topologicalSort(), "\(what)")
            #expect(Array(view.depthFirstSearch()) == Array(copy.depthFirstSearch()), "\(what)")
            #expect(view.findCycle()?.vertices == copy.findCycle()?.vertices, "\(what)")
            #expect(view.findCycle()?.edges.map { ordinal[$0]! } == copy.findCycle()?.edges, "\(what)")
            #expect(view.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) }, "\(what)")
            #expect(view.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) }, "\(what)")
            #expect(view.condensation().components.map { Array($0) } == copy.condensation().components.map { Array($0) }, "\(what)")
            #expect(Array(view.condensation().graph.edges) == Array(copy.condensation().graph.edges), "\(what)")
            #expect(view.attractingComponents().map { Array($0) } == copy.attractingComponents().map { Array($0) }, "\(what)")
            #expect(view.isStronglyConnected == copy.isStronglyConnected, "\(what)")
            for source in view.vertices {
                #expect(Array(view.breadthFirstSearch(from: source)) == Array(copy.breadthFirstSearch(from: source)), "\(what) from \(source)")
                #expect(Array(view.depthFirstSearch(from: source)) == Array(copy.depthFirstSearch(from: source)), "\(what) from \(source)")
                #expect(view.breadthFirstLayers(from: source) == copy.breadthFirstLayers(from: source), "\(what) from \(source)")
                #expect(view.descendants(of: source) == copy.descendants(of: source), "\(what) from \(source)")
                #expect(view.ancestors(of: source) == copy.ancestors(of: source), "\(what) from \(source)")
                let tree = view.dijkstraShortestPaths(from: source) { weight[ordinal[$0]!] }
                let copyTree = copy.dijkstraShortestPaths(from: source) { weight[$0] }
                let bellman = view.bellmanFordShortestPaths(from: source) { weight[ordinal[$0]!] }
                let hops = view.shortestPaths(from: source), copyHops = copy.shortestPaths(from: source)
                for target in view.vertices {
                    #expect(tree.distance(to: target) == copyTree.distance(to: target), "\(what) \(source)→\(target)")
                    #expect(tree.parent(of: target) == copyTree.parent(of: target), "\(what) \(source)→\(target)")
                    #expect(tree.parentEdge(of: target).map { ordinal[$0]! } == copyTree.parentEdge(of: target), "\(what) \(source)→\(target)")
                    #expect(tree.path(to: target)?.vertices == copyTree.path(to: target)?.vertices, "\(what) \(source)→\(target)")
                    #expect(bellman?.distance(to: target) == tree.distance(to: target), "\(what) \(source)→\(target)")
                    #expect(hops.distance(to: target) == copyHops.distance(to: target), "\(what) \(source)→\(target)")
                    #expect(view.hasPath(from: source, to: target) == copy.hasPath(from: source, to: target), "\(what) \(source)→\(target)")
                }
            }
        }

        check(base.reverseView, "reverseView")
        check(base.inducedSubgraph(on: keep), "inducedSubgraph")
        check(base.spanningSubgraph(edges: positions), "spanningSubgraph")
        check(base.subgraph(vertices: keep, edges: positions), "subgraph")
        check(base.complement, "complement")
        check(base.inducedSubgraph(on: keep).reverseView, "inducedSubgraph.reverseView")
        check(base.complement.reverseView, "complement.reverseView")
        check(base.reverseView.inducedSubgraph(on: keep).complement, "reverseView.inducedSubgraph.complement")
        check(base.inducedSubgraph(on: names), "inducedSubgraph on every vertex")
        check(base.inducedSubgraph(on: keep).reverseView.reverseView, "inducedSubgraph.reverseView.reverseView")
        // The subgraph and reverse views' positions are the base's: the weight of base position p is
        // the weight the view sees at p.
        let view = base.subgraph(vertices: keep, edges: positions)
        let baseTree = base.spanningSubgraph(edges: view.edges.indices).dijkstraShortestPaths(from: keep.first ?? names[0]) { $0 % 5 + 1 }
        let viewTree = view.dijkstraShortestPaths(from: keep.first ?? names[0]) { $0 % 5 + 1 }
        for target in view.vertices {
            #expect(viewTree.distance(to: target) == baseTree.distance(to: target))
            #expect(viewTree.parentEdge(of: target) == baseTree.parentEdge(of: target))
        }
        let reversedTree = base.reverseView.dijkstraShortestPaths(from: names[0]) { $0 % 7 + 1 }
        for target in names {
            if let p = reversedTree.parentEdge(of: target) {
                #expect(base.edges[p] == DirectedEdge(from: target, to: reversedTree.parent(of: target)!))
            }
        }
    }

    @Test("Undirected views: Traversal, Connectivity and ShortestPaths equal a materialized copy's", arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func undirectedViewsAgainstCopies(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(50 + seed))
        let n = 4 + seed * 2
        let names = (0 ..< n).map { "u\($0)" }.shuffled(using: &rng)
        var edges: [UndirectedEdge<String>] = []
        for _ in 0 ..< n * (seed % 3 + 1) {
            edges.append(UndirectedEdge(names.randomElement(using: &rng)!, names.randomElement(using: &rng)!))
        }
        edges += edges.prefix(seed % 4)
        edges.append(UndirectedEdge(names[1], names[1]))
        let base = Pseudograph<String>(vertices: names, edges: edges)
        let keep = names.filter { _ in Int.random(in: 0 ..< 4, using: &rng) != 0 }
        let positions = base.edges.indices.filter { _ in Bool.random(using: &rng) }

        func check<View: Graph>(_ view: View, _ what: String) where View.Vertex == String {
            let copy = Pseudograph<String>(view)
            let order = Array(view.edges.indices)
            var ordinal: [View.Edges.Index: Int] = [:]
            for (k, p) in order.enumerated() { ordinal[p] = k }
            let weight = (0 ..< order.count).map { ($0 &* 2_654_435_761 &+ seed) % 9 + 1 }
            #expect(Array(view.vertices) == Array(copy.vertices), "\(what)")
            #expect(view.edges.map { [$0.u, $0.v] } == copy.edges.map { [$0.u, $0.v] }, "\(what)")
            #expect(view.connectedComponents().map { Array($0) } == copy.connectedComponents().map { Array($0) }, "\(what)")
            #expect(view.isConnected == copy.isConnected, "\(what)")
            #expect(view.bridges().map { ordinal[$0]! } == copy.bridges(), "\(what)")
            #expect(view.articulationPoints() == copy.articulationPoints(), "\(what)")
            #expect(view.biEdgeConnectedComponents().map { Array($0) } == copy.biEdgeConnectedComponents().map { Array($0) }, "\(what)")
            for source in view.vertices {
                #expect(Array(view.directed.breadthFirstSearch(from: source)) == Array(copy.directed.breadthFirstSearch(from: source)), "\(what) from \(source)")
                #expect(Array(view.directed.depthFirstSearch(from: source)) == Array(copy.directed.depthFirstSearch(from: source)), "\(what) from \(source)")
                #expect(view.directed.descendants(of: source) == copy.directed.descendants(of: source), "\(what) from \(source)")
                let tree = view.dijkstraShortestPaths(from: source) { weight[ordinal[$0]!] }
                let copyTree = copy.dijkstraShortestPaths(from: source) { weight[$0] }
                let hops = view.shortestPaths(from: source), copyHops = copy.shortestPaths(from: source)
                for target in view.vertices {
                    #expect(tree.distance(to: target) == copyTree.distance(to: target), "\(what) \(source)–\(target)")
                    #expect(tree.parent(of: target) == copyTree.parent(of: target), "\(what) \(source)–\(target)")
                    #expect(tree.parentEdge(of: target).map { [ordinal[$0.position]!, $0.reversed ? 1 : 0] }
                        == copyTree.parentEdge(of: target).map { [$0.position, $0.reversed ? 1 : 0] }, "\(what) \(source)–\(target)")
                    #expect(hops.distance(to: target) == copyHops.distance(to: target), "\(what) \(source)–\(target)")
                }
            }
        }

        check(base.inducedSubgraph(on: keep), "inducedSubgraph")
        check(base.spanningSubgraph(edges: positions), "spanningSubgraph")
        check(base.subgraph(vertices: keep, edges: positions), "subgraph")
        check(base.complement, "complement")
        check(base.inducedSubgraph(on: keep).complement, "inducedSubgraph.complement")
        check(base.spanningSubgraph(edges: positions).inducedSubgraph(on: keep), "spanningSubgraph.inducedSubgraph")
        check(base.inducedSubgraph(on: names), "inducedSubgraph on every vertex")
        // On every vertex the view forwards the base's flat rows and edge indices, which
        // UndirectedAdjacencyList keeps (and Pseudograph does not).
        var pairs = Set<[String]>()
        for e in edges where e.u != e.v { pairs.insert([Swift.min(e.u, e.v), Swift.max(e.u, e.v)]) }
        let simple = UndirectedAdjacencyList<String>(vertices: names, edges: pairs.sorted { $0.lexicographicallyPrecedes($1) }.map { UndirectedEdge($0[0], $0[1]) })
        check(simple.inducedSubgraph(on: names), "UndirectedAdjacencyList.inducedSubgraph on every vertex")
        check(simple.inducedSubgraph(on: keep), "UndirectedAdjacencyList.inducedSubgraph")
        check(simple.spanningSubgraph(edges: simple.edges.indices.filter { _ in Bool.random(using: &rng) }), "UndirectedAdjacencyList.spanningSubgraph")
        let allView = simple.inducedSubgraph(on: names)
        #expect(allView.edgeIndexBound == simple.edgeIndexBound)
        for i in 0 ..< n {
            #expect(Array(allView.incidentEdgeIndices(ofIndex: i)) == Array(simple.incidentEdgeIndices(ofIndex: i)))
        }
        for p in simple.edges.indices { #expect(allView.edgeIndex(of: p) == simple.edgeIndex(of: p)) }
        // The undirected view of a reverse view is the base's own undirected view, edge for edge.
        let directed = DirectedPseudograph<String>(vertices: names, edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) })
        // The undirected view of a directed view walks the out-row, then the in-row, in place: its
        // rows are ordered differently from a copy's, so components and layers are compared.
        let undirectedCopy = Pseudograph<String>(directed.undirected)
        #expect(directed.undirected.connectedComponents().map { Array($0) } == undirectedCopy.connectedComponents().map { Array($0) })
        #expect(directed.reverseView.undirected.connectedComponents().map { Array($0) } == undirectedCopy.connectedComponents().map { Array($0) })
        #expect(directed.undirected.isConnected == undirectedCopy.isConnected)
        for source in names {
            let layers = undirectedCopy.directed.breadthFirstLayers(from: source).map { Set($0) }
            #expect(directed.undirected.directed.breadthFirstLayers(from: source).map { Set($0) } == layers)
            #expect(directed.reverseView.undirected.directed.breadthFirstLayers(from: source).map { Set($0) } == layers)
        }
        let inducedUndirected = directed.inducedSubgraph(on: keep).undirected
        #expect(inducedUndirected.connectedComponents().map { Array($0) } == Pseudograph<String>(inducedUndirected).connectedComponents().map { Array($0) })
        let flipped = Pseudograph<String>(directed.reverseView.undirected)
        #expect(flipped.edges.map { [$0.v, $0.u] } == Pseudograph<String>(directed.undirected).edges.map { [$0.u, $0.v] })
    }

    @Test("A view with an edge set walks the same rows before and after it builds its kept rows")
    func keptRowsMatchFilteredRows() {
        // The row hooks filter the base's rows until n/16 rows have been walked, then build the
        // kept rows once: answers must not change across that point, directed or undirected.
        var rng = SeededRandomNumberGenerator(seed: 23)
        let n = 2000
        var arcs: [DirectedEdge<Int>] = []
        for _ in 0 ..< 6 * n { arcs.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng))) }
        let directed = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
        let kept = directed.edges.indices.filter { _ in Int.random(in: 0 ..< 3, using: &rng) == 0 }
        let keep = (0 ..< n).filter { _ in Int.random(in: 0 ..< 5, using: &rng) != 0 }
        for view in [directed.spanningSubgraph(edges: kept), directed.subgraph(vertices: keep, edges: kept)] {
            let copy = DirectedPseudograph<Int>(view)
            // The first few searches stay below the threshold; the components walk every row.
            for source in 0 ..< 3 {
                let s = view.vertex(atIndex: source)
                #expect(view.breadthFirstLayers(from: s) == copy.breadthFirstLayers(from: s))
                #expect(view.ancestors(of: s) == copy.ancestors(of: s))
            }
            #expect(view.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) })
            #expect(view.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) })
            for source in [0, 7, 99] {
                let s = view.vertex(atIndex: source)
                #expect(view.breadthFirstLayers(from: s) == copy.breadthFirstLayers(from: s))
                #expect(view.ancestors(of: s) == copy.ancestors(of: s))
            }
            // A copy of the view shares the built rows.
            let again = view
            #expect(again.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) })
        }
        let undirected = Pseudograph<Int>(vertices: 0 ..< n, edges: arcs.map { UndirectedEdge($0.source, $0.target) })
        let simple = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: Set(arcs.filter { $0.source != $0.target }.map { [Swift.min($0.source, $0.target), Swift.max($0.source, $0.target)] }).sorted { $0.lexicographicallyPrecedes($1) }.map { UndirectedEdge($0[0], $0[1]) })
        let simpleKept = simple.edges.indices.filter { _ in Int.random(in: 0 ..< 3, using: &rng) == 0 }
        func check<View: Graph>(_ view: View) where View.Vertex == Int {
            let copy = Pseudograph<Int>(view)
            for source in 0 ..< 3 {
                let s = view.vertex(atIndex: source)
                #expect(view.directed.breadthFirstLayers(from: s) == copy.directed.breadthFirstLayers(from: s))
            }
            #expect(view.connectedComponents().map { Array($0) } == copy.connectedComponents().map { Array($0) })
            for source in [0, 7, 99] {
                let s = view.vertex(atIndex: source)
                #expect(view.directed.breadthFirstLayers(from: s) == copy.directed.breadthFirstLayers(from: s))
            }
        }
        check(undirected.spanningSubgraph(edges: undirected.edges.indices.filter { $0 % 3 == 0 }))
        check(undirected.subgraph(vertices: keep, edges: undirected.edges.indices.filter { $0 % 2 == 0 }))
        check(simple.spanningSubgraph(edges: simpleKept))
        check(simple.subgraph(vertices: keep, edges: simpleKept))
    }

    @Test("Walking a complement's edges.indices steps from the current cell: every cell of n = 1500 in time", .timeLimit(.minutes(1)))
    func complementIndicesWalk() {
        // Before, index(after:) rescanned the row from its start, O(n) a step and O(n³) in all:
        // 800× iteration at n = 2000. Now one contains(edge:) per column passed.
        let n = 1500
        var rng = SeededRandomNumberGenerator(seed: 71)
        var arcs = Set<[Int]>()
        while arcs.count < 3 * n { arcs.insert([Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)]) }
        let base = CompressedSparseRow(vertexCount: n, edges: arcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let complement = base.complement
        var count = 0, previous: ComplementView<CompressedSparseRow>.Cell?
        var sources = 0, ascending = true
        for cell in complement.edges.indices {
            if let previous, !(previous < cell) { ascending = false }
            previous = cell
            count += 1
            sources &+= cell.source
        }
        #expect(ascending)
        #expect(count == complement.edgeCount && count == n * (n - 1) - arcs.filter { $0[0] != $0[1] }.count)
        #expect(sources == complement.edges.reduce(0) { $0 &+ $1.source })

        var pairs = Set<[Int]>()
        while pairs.count < 3 * n {
            let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
            if a != b { pairs.insert([Swift.min(a, b), Swift.max(a, b)]) }
        }
        let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
        var cells = 0, upper = true
        var last: ComplementView<UndirectedAdjacencyList<Int>>.Cell?
        for cell in undirected.complement.edges.indices {
            if cell.source >= cell.target { upper = false }
            if let last, !(last < cell) { upper = false }
            last = cell
            cells += 1
        }
        #expect(upper)
        #expect(cells == undirected.complement.edgeCount && cells == n * (n - 1) / 2 - pairs.count)
    }

    @Test("Views over CompressedSparseRow and AdjacencyMatrix bases equal their copies", arguments: [1, 2, 3, 4])
    func viewsOverIntBases(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(90 + seed))
        let n = 5 + seed * 3
        var arcs: [DirectedEdge<Int>] = []
        for _ in 0 ..< n * 2 {
            arcs.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)))
        }
        let csr = CompressedSparseRow(vertexCount: n, edges: arcs)
        let matrix = AdjacencyMatrix(vertexCount: n, edges: arcs)
        let keep = (0 ..< n).filter { _ in Bool.random(using: &rng) }

        func check<View: DirectedGraph>(_ view: View, _ what: String) where View.Vertex == Int {
            let copy = DirectedPseudograph<Int>(view)
            let order = Array(view.edges.indices)
            var ordinal: [View.Edges.Index: Int] = [:]
            for (k, p) in order.enumerated() { ordinal[p] = k }
            #expect(Array(view.vertices) == Array(copy.vertices), "\(what)")
            #expect(view.edges.map { $0 } == copy.edges.map { $0 }, "\(what)")
            #expect(view.topologicalSort() == copy.topologicalSort(), "\(what)")
            #expect(view.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) }, "\(what)")
            #expect(view.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) }, "\(what)")
            for source in view.vertices {
                #expect(Array(view.breadthFirstSearch(from: source)) == Array(copy.breadthFirstSearch(from: source)), "\(what) from \(source)")
                #expect(Array(view.depthFirstSearch(from: source)) == Array(copy.depthFirstSearch(from: source)), "\(what) from \(source)")
                let tree = view.dijkstraShortestPaths(from: source) { ordinal[$0]! % 4 + 1 }
                let copyTree = copy.dijkstraShortestPaths(from: source) { $0 % 4 + 1 }
                for target in view.vertices {
                    #expect(tree.distance(to: target) == copyTree.distance(to: target), "\(what) \(source)→\(target)")
                    #expect(tree.parentEdge(of: target).map { ordinal[$0]! } == copyTree.parentEdge(of: target), "\(what) \(source)→\(target)")
                }
            }
        }

        check(csr.inducedSubgraph(on: keep), "CSR inducedSubgraph")
        check(csr.spanningSubgraph(edges: csr.edges.indices.filter { $0 % 2 == 0 }), "CSR spanningSubgraph")
        check(csr.complement, "CSR complement")
        check(matrix.reverseView, "matrix reverseView")
        check(matrix.inducedSubgraph(on: keep), "matrix inducedSubgraph")
        check(matrix.complement, "matrix complement")
        check(matrix.complement.complement, "matrix complement twice")
        // A view materializes into CompressedSparseRow when its vertices are 0..<n: the reverse and
        // the complement of a CSR are its transpose and its complement relation.
        let reversed = CompressedSparseRow(matrix.reverseView)
        #expect(Set(reversed.edges) == Set(arcs.map { DirectedEdge(from: $0.target, to: $0.source) }))
        let complement = CompressedSparseRow(csr.complement)
        let present = Set(arcs)
        var expected = Set<DirectedEdge<Int>>()
        for s in 0 ..< n { for t in 0 ..< n where s != t && !present.contains(DirectedEdge(from: s, to: t)) { expected.insert(DirectedEdge(from: s, to: t)) } }
        #expect(Set(complement.edges) == expected)
        #expect(complement.edgeCount == csr.complement.edgeCount)
    }

    @Test("An edge set over a base without edge indices keeps its sorted positions: dense edge indices by rank, filtered rows")
    func edgeSetsOverBasesWithoutEdgeIndices() {
        // AdjacencyMatrix positions are cells, and the matrix has no edge indices.
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 3, to: 0), DirectedEdge(from: 0, to: 2),
        ])
        #expect(matrix.edgeIndexBound == nil)
        let cells = Array(matrix.edges.indices)
        #expect(matrix.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 2], [2, 3], [3, 0]])
        // Listed out of order and with a repeat: kept once, in base order, ranked 0, 1, 2.
        let spanning = matrix.spanningSubgraph(edges: [cells[3], cells[0], cells[3], cells[1]])
        #expect(spanning.edgeIndexBound == 3 && spanning.edgeCount == 3)
        #expect(Array(spanning.edges.indices) == [cells[0], cells[1], cells[3]])
        #expect(spanning.edges.indices.map { spanning.edgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(spanning.successorIndices(ofIndex: 0)) == [1, 2] && Array(spanning.successorIndices(ofIndex: 1)) == [])
        #expect(Array(spanning.outEdges(ofIndex: 2)) == [cells[3]] && Array(spanning.inEdges(ofIndex: 2)) == [cells[1]])
        #expect(Array(spanning.predecessorIndices(ofIndex: 2)) == [0] && spanning.inDegree(ofIndex: 2) == 1)
        #expect(spanning.contains(edge: DirectedEdge(from: 0, to: 2)) && !spanning.contains(edge: DirectedEdge(from: 1, to: 2)))
        // Both filters: a listed edge with a dropped end is not kept, and the rest are ranked.
        let both = matrix.subgraph(vertices: [3, 0, 2], edges: cells)
        #expect(Array(both.vertices) == [0, 2, 3] && both.edgeIndexBound == 3)
        #expect(both.edges.map { [$0.source, $0.target] } == [[0, 2], [2, 3], [3, 0]])
        #expect(both.edges.indices.map { both.edgeIndex(of: $0) } == [0, 1, 2])
        #expect(Array(both.successorIndices(ofIndex: 0)) == [1] && Array(both.predecessorIndices(ofIndex: 0)) == [2])
        // An undirected complement has no edge indices either; a spanning subgraph of it does.
        let path = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d")])
        let complement = path.complement
        let pairs = Array(complement.edges.indices)
        #expect(complement.edgeIndexBound == nil && complement.edges.map { [$0.u, $0.v] } == [["a", "c"], ["a", "d"], ["b", "d"]])
        let kept = complement.spanningSubgraph(edges: [pairs[2], pairs[0]])
        #expect(kept.edgeIndexBound == 2 && kept.edges.map { [$0.u, $0.v] } == [["a", "c"], ["b", "d"]])
        #expect(Array(kept.neighborIndices(ofIndex: 0)) == [2] && Array(kept.incidentEdgeIndices(ofIndex: 3)) == [1])
        #expect((0 ..< 4).map { kept.degree(ofIndex: $0) } == [1, 1, 1, 1])
        #expect(kept.contains(edge: UndirectedEdge("d", "b")) && !kept.contains(edge: UndirectedEdge("a", "d")))
    }

    @Test("The condensation DAG of a graph with thousands of components keeps the order n−1, …, 0 across storage pages")
    func largeCondensationDAG() {
        // A path of 5000 vertices: every vertex its own component, Tarjan's order reversed.
        let n = 5000
        let path = AdjacencyList<Int>(vertices: 0 ..< n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
        let condensation = path.condensation()
        #expect(condensation.components.count == n)
        let overList = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        let overStable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(condensation)
        #expect(Array(overList.topologicalOrder) == Array((0 ..< n).reversed()))
        #expect(Array(overStable.topologicalOrder) == Array((0 ..< n).reversed()))
        #expect(overList.topologicalPosition(of: 0) == n - 1 && overList.topologicalPosition(of: n - 1) == 0)
        #expect(overList.edgeCount == n - 1 && overList.edges.allSatisfy { $0.source == $0.target + 1 })
    }

    @Test("The materialized operations agree across their construction targets", arguments: [1, 2, 3, 4, 5])
    func targetsAgree(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(200 + seed))
        let n = 4 + seed * 2
        let names = (0 ..< n).map { "w\($0)" }
        var arcs: [DirectedEdge<String>] = []
        for _ in 0 ..< n * 2 {
            let a = names.randomElement(using: &rng)!, b = names.randomElement(using: &rng)!
            if a != b { arcs.append(DirectedEdge(from: a, to: b)) }
        }
        let g = DirectedPseudograph<String>(vertices: names, edges: arcs)
        let h = AdjacencyList<String>(vertices: ["p", "q", "r"], edges: [DirectedEdge(from: "p", to: "q")])
        var blocks: [[String]] = [[], [], []]
        for name in names { blocks[Int.random(in: 0 ..< 3, using: &rng)].append(name) }

        let lineCSR = CompressedSparseRow.lineGraph(of: g)
        let lineList = AdjacencyList<Int>.lineGraph(of: g)
        let lineMatrix = AdjacencyMatrix.lineGraph(of: g)
        let lineStable = StableDirectedGraph<Int>.lineGraph(of: g)
        #expect(lineList.edges.map { $0 } == lineCSR.edges.map { $0 })
        #expect(lineMatrix.edges.map { $0 } == lineCSR.edges.map { $0 })
        #expect(lineStable.edges.map { $0 } == lineCSR.edges.map { $0 })
        #expect(lineCSR.vertexCount == g.edgeCount && lineList.vertexCount == g.edgeCount && lineMatrix.vertexCount == g.edgeCount && lineStable.vertexCount == g.edgeCount)

        let quotientCSR = CompressedSparseRow.quotient(of: g, by: blocks)
        #expect(AdjacencyList<Int>.quotient(of: g, by: blocks).edges.map { $0 } == quotientCSR.edges.map { $0 })
        #expect(AdjacencyMatrix.quotient(of: g, by: blocks).edges.map { $0 } == quotientCSR.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.quotient(of: g, by: blocks).edges.map { $0 } == quotientCSR.edges.map { $0 })

        let unionCSR = CompressedSparseRow.disjointUnion(g, h)
        #expect(AdjacencyList<Int>.disjointUnion(g, h).edges.map { $0 } == unionCSR.edges.map { $0 })
        #expect(AdjacencyMatrix.disjointUnion(g, h).edges.map { $0 } == unionCSR.edges.map { $0 })
        let joinCSR = CompressedSparseRow.join(g, h)
        #expect(AdjacencyList<Int>.join(g, h).edges.map { $0 } == joinCSR.edges.map { $0 })
        #expect(StableDirectedGraph<Int>.join(g, h).edges.map { $0 } == joinCSR.edges.map { $0 })

        // The condensation as a DAG over two bases: the same edges, and the order n−1, …, 0 is a
        // topological order of both.
        let condensation = g.condensation()
        let overList = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
        let overStable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(condensation)
        let k = condensation.components.count
        #expect(Array(overList.topologicalOrder) == Array((0 ..< k).reversed()))
        #expect(Array(overStable.topologicalOrder) == Array((0 ..< k).reversed()))
        #expect(overList.edges.map { $0 } == condensation.graph.edges.map { $0 })
        #expect(overStable.edges.map { $0 } == condensation.graph.edges.map { $0 })
        #expect(overList.base.topologicalSort() != nil)
        for edge in overList.edges { #expect(edge.source > edge.target) }
    }
}
