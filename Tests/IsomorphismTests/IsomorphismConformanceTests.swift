// Conformance: the answers depend on the graphs, not on how they are stored or named. Seeded random
// graphs go through every representation that can hold them (Pseudograph, UndirectedAdjacencyList,
// Multigraph, the undirected views of AdjacencyMatrix, AdjacencyList and LabeledGraph; on the
// directed side DirectedPseudograph, AdjacencyList, CompressedSparseRow, AdjacencyMatrix,
// DirectedMultigraph and LabeledGraph over both bases), alone and mixed, and every problem's set of
// mappings, read back as indices, must equal the one on the reference Pseudograph or
// DirectedPseudograph. Relabelled copies (permuted vertices, shuffled edge positions, String names)
// move every mapping by the relabelling; an undirected graph's `directed` view has the same
// mappings; Weisfeiler–Leman hashes are equal across representations and copies. Then the value
// laws of Isomorphism and Isomorphisms, and how often the colour closures are read; laziness relies
// on speed and is in Performance/IsomorphismLazinessTests.swift. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import LabeledGraphs
import Multigraphs
import Testing

@Suite("Isomorphism conformance across representations and relabellings")
struct IsomorphismConformanceTests {
    @Test("Undirected: every representation, alone and mixed, gives the reference's mappings in all three problems", .tags(.randomized), arguments: 0 ..< 16)
    func undirectedRepresentations(seed: Int) {
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
        // A graph on 0..<7 (self-loops on odd seeds), a relabelled copy, and a pattern on 3 or 4 vertices.
        let n = 7, k = 3 + seed % 2
        var pairs: [[Int]] = []
        for u in 0 ..< n {
            for v in u ..< n where (u != v || seed % 2 == 1) && Int.random(in: 0 ..< 10, using: &rng) < 4 { pairs.append([u, v]) }
        }
        pairs.shuffle(using: &rng)
        let permutation = Array(0 ..< n).shuffled(using: &rng)
        let copyPairs = pairs.map { [permutation[$0[0]], permutation[$0[1]]] }.shuffled(using: &rng)
        var patternPairs: [[Int]] = []
        for u in 0 ..< k {
            for v in u + 1 ..< k where Int.random(in: 0 ..< 2, using: &rng) == 0 { patternPairs.append([u, v]) }
        }
        let context = "seed \(seed): \(pairs), copy \(copyPairs), pattern \(patternPairs)"
        func results<P: Graph, T: Graph>(_ pattern: P, _ target: T, _ index: (T.Vertex) -> Int) -> [Set<[Int]>] {
            let all = [Set(pattern.isomorphisms(to: target).map { $0.images.map(index) }),
                       Set(pattern.subgraphIsomorphisms(to: target).map { $0.images.map(index) }),
                       Set(pattern.monomorphisms(to: target).map { $0.images.map(index) })]
            #expect(pattern.isIsomorphic(to: target) == !all[0].isEmpty, "\(context)")
            #expect(pattern.isSubgraphIsomorphic(to: target) == !all[1].isEmpty, "\(context)")
            #expect(pattern.isMonomorphic(to: target) == !all[2].isEmpty, "\(context)")
            let firsts = [pattern.isomorphism(to: target), pattern.subgraphIsomorphism(to: target), pattern.monomorphism(to: target)]
            for (first, set) in zip(firsts, all) {
                #expect(first.map { set.contains($0.images.map(index)) } ?? set.isEmpty, "\(context)")
            }
            return all
        }
        let int = { (vertex: Int) in vertex }
        let label = { (vertex: String) in Int(vertex.dropFirst())! }
        let names = (0 ..< n).map { "v\($0)" }
        let graph = Pseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
        let copy = Pseudograph(vertices: 0 ..< n, edges: copyPairs.map { UndirectedEdge($0[0], $0[1]) })
        let pattern = Pseudograph(vertices: 0 ..< k, edges: patternPairs.map { UndirectedEdge($0[0], $0[1]) })
        let isomorphic = results(graph, copy, int)
        let embedded = results(pattern, graph, int)
        #expect(isomorphic[0].count >= 1, "\(context)")
        // Each representation of all three graphs.
        let lists = (UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) }),
                     UndirectedAdjacencyList(vertices: 0 ..< n, edges: copyPairs.map { UndirectedEdge($0[0], $0[1]) }),
                     UndirectedAdjacencyList(vertices: 0 ..< k, edges: patternPairs.map { UndirectedEdge($0[0], $0[1]) }))
        #expect(results(lists.0, lists.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(lists.2, lists.0, int) == embedded, "\(context)")
        let matrices = (AdjacencyMatrix(vertexCount: n, edges: pairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected,
                        AdjacencyMatrix(vertexCount: n, edges: copyPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected,
                        AdjacencyMatrix(vertexCount: k, edges: patternPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected)
        #expect(results(matrices.0, matrices.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(matrices.2, matrices.0, int) == embedded, "\(context)")
        let adjacency = (AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected,
                         AdjacencyList(vertices: 0 ..< n, edges: copyPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected,
                         AdjacencyList(vertices: 0 ..< k, edges: patternPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected)
        #expect(results(adjacency.0, adjacency.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(adjacency.2, adjacency.0, int) == embedded, "\(context)")
        let labeled = (LabeledGraph<String, AdjacencyMatrix>(vertices: names, edges: pairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) }).undirected,
                       LabeledGraph<String, AdjacencyMatrix>(vertices: names, edges: copyPairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) }).undirected,
                       LabeledGraph<String, AdjacencyMatrix>(vertices: names.prefix(k), edges: patternPairs.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) }).undirected)
        #expect(results(labeled.0, labeled.1, label)[0] == isomorphic[0], "\(context)")
        #expect(results(labeled.2, labeled.0, label) == embedded, "\(context)")
        if let multigraphs = Multigraph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) }),
           let copyMultigraph = Multigraph(vertices: 0 ..< n, edges: copyPairs.map { UndirectedEdge($0[0], $0[1]) }),
           let patternMultigraph = Multigraph(vertices: 0 ..< k, edges: patternPairs.map { UndirectedEdge($0[0], $0[1]) }) {
            #expect(results(multigraphs, copyMultigraph, int)[0] == isomorphic[0], "\(context)")
            #expect(results(patternMultigraph, multigraphs, int) == embedded, "\(context)")
        } else {
            #expect(seed % 2 == 1, "Multigraph refuses only self-loops: \(context)")
        }
        // Mixed: the pattern in one representation, the target in another.
        #expect(results(graph, matrices.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(lists.0, labeled.1, label)[0] == isomorphic[0], "\(context)")
        #expect(results(matrices.2, lists.0, int) == embedded, "\(context)")
        #expect(results(labeled.2, adjacency.0, int) == embedded, "\(context)")
        #expect(results(pattern, labeled.0, label) == embedded, "\(context)")
    }

    @Test("Directed: every representation, alone and mixed, gives the reference's mappings in all three problems", .tags(.randomized), arguments: 0 ..< 16)
    func directedRepresentations(seed: Int) {
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 6, k = 3
        var arcs: [[Int]] = []
        for u in 0 ..< n {
            for v in 0 ..< n where (u != v || seed % 2 == 1) && Int.random(in: 0 ..< 10, using: &rng) < 3 { arcs.append([u, v]) }
        }
        arcs.shuffle(using: &rng)
        let permutation = Array(0 ..< n).shuffled(using: &rng)
        let copyArcs = arcs.map { [permutation[$0[0]], permutation[$0[1]]] }.shuffled(using: &rng)
        var patternArcs: [[Int]] = []
        for u in 0 ..< k {
            for v in 0 ..< k where u != v && Int.random(in: 0 ..< 3, using: &rng) == 0 { patternArcs.append([u, v]) }
        }
        let context = "seed \(seed): \(arcs), copy \(copyArcs), pattern \(patternArcs)"
        func results<P: DirectedGraph, T: DirectedGraph>(_ pattern: P, _ target: T, _ index: (T.Vertex) -> Int) -> [Set<[Int]>] {
            let all = [Set(pattern.isomorphisms(to: target).map { $0.images.map(index) }),
                       Set(pattern.subgraphIsomorphisms(to: target).map { $0.images.map(index) }),
                       Set(pattern.monomorphisms(to: target).map { $0.images.map(index) })]
            #expect(pattern.isIsomorphic(to: target) == !all[0].isEmpty, "\(context)")
            #expect(pattern.isSubgraphIsomorphic(to: target) == !all[1].isEmpty, "\(context)")
            #expect(pattern.isMonomorphic(to: target) == !all[2].isEmpty, "\(context)")
            let firsts = [pattern.isomorphism(to: target), pattern.subgraphIsomorphism(to: target), pattern.monomorphism(to: target)]
            for (first, set) in zip(firsts, all) {
                #expect(first.map { set.contains($0.images.map(index)) } ?? set.isEmpty, "\(context)")
            }
            return all
        }
        let int = { (vertex: Int) in vertex }
        let label = { (vertex: String) in Int(vertex.dropFirst())! }
        let names = (0 ..< n).map { "v\($0)" }
        let edges = { (list: [[Int]]) in list.map { DirectedEdge(from: $0[0], to: $0[1]) } }
        let named = { (list: [[Int]]) in list.map { DirectedEdge(from: names[$0[0]], to: names[$0[1]]) } }
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: edges(arcs))
        let copy = DirectedPseudograph(vertices: 0 ..< n, edges: edges(copyArcs))
        let pattern = DirectedPseudograph(vertices: 0 ..< k, edges: edges(patternArcs))
        let isomorphic = results(graph, copy, int)
        let embedded = results(pattern, graph, int)
        #expect(isomorphic[0].count >= 1, "\(context)")
        let lists = (AdjacencyList(vertices: 0 ..< n, edges: edges(arcs)), AdjacencyList(vertices: 0 ..< n, edges: edges(copyArcs)), AdjacencyList(vertices: 0 ..< k, edges: edges(patternArcs)))
        #expect(results(lists.0, lists.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(lists.2, lists.0, int) == embedded, "\(context)")
        let rows = (CompressedSparseRow(vertexCount: n, edges: edges(arcs)), CompressedSparseRow(vertexCount: n, edges: edges(copyArcs)), CompressedSparseRow(vertexCount: k, edges: edges(patternArcs)))
        #expect(results(rows.0, rows.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(rows.2, rows.0, int) == embedded, "\(context)")
        let matrices = (AdjacencyMatrix(vertexCount: n, edges: edges(arcs)), AdjacencyMatrix(vertexCount: n, edges: edges(copyArcs)), AdjacencyMatrix(vertexCount: k, edges: edges(patternArcs)))
        #expect(results(matrices.0, matrices.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(matrices.2, matrices.0, int) == embedded, "\(context)")
        let labeledRows = (LabeledGraph<String, CompressedSparseRow>(vertices: names, edges: named(arcs)),
                           LabeledGraph<String, CompressedSparseRow>(vertices: names, edges: named(copyArcs)),
                           LabeledGraph<String, CompressedSparseRow>(vertices: names.prefix(k), edges: named(patternArcs)))
        #expect(results(labeledRows.0, labeledRows.1, label)[0] == isomorphic[0], "\(context)")
        #expect(results(labeledRows.2, labeledRows.0, label) == embedded, "\(context)")
        let labeledMatrices = (LabeledGraph<String, AdjacencyMatrix>(vertices: names, edges: named(arcs)),
                               LabeledGraph<String, AdjacencyMatrix>(vertices: names, edges: named(copyArcs)),
                               LabeledGraph<String, AdjacencyMatrix>(vertices: names.prefix(k), edges: named(patternArcs)))
        #expect(results(labeledMatrices.0, labeledMatrices.1, label)[0] == isomorphic[0], "\(context)")
        #expect(results(labeledMatrices.2, labeledMatrices.0, label) == embedded, "\(context)")
        if let multigraph = DirectedMultigraph(vertices: 0 ..< n, edges: edges(arcs)),
           let copyMultigraph = DirectedMultigraph(vertices: 0 ..< n, edges: edges(copyArcs)),
           let patternMultigraph = DirectedMultigraph(vertices: 0 ..< k, edges: edges(patternArcs)) {
            #expect(results(multigraph, copyMultigraph, int)[0] == isomorphic[0], "\(context)")
            #expect(results(patternMultigraph, multigraph, int) == embedded, "\(context)")
        } else {
            #expect(seed % 2 == 1, "DirectedMultigraph refuses only self-loops: \(context)")
        }
        // Mixed.
        #expect(results(graph, rows.1, int)[0] == isomorphic[0], "\(context)")
        #expect(results(matrices.0, labeledRows.1, label)[0] == isomorphic[0], "\(context)")
        #expect(results(rows.2, lists.0, int) == embedded, "\(context)")
        #expect(results(labeledMatrices.2, rows.0, int) == embedded, "\(context)")
        #expect(results(pattern, labeledMatrices.0, label) == embedded, "\(context)")
    }

    @Test("Multigraphs: Pseudograph, DirectedPseudograph.undirected and Multigraph agree with parallel edges, self-loops and edge colours", .tags(.randomized), arguments: 0 ..< 16)
    func multigraphRepresentations(seed: Int) {
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 5, k = 3
        let loops = seed % 2 == 1
        func randomPairs(_ count: Int, _ size: Int) -> [[Int]] {
            var out: [[Int]] = []
            while out.count < count {
                let u = Int.random(in: 0 ..< size, using: &rng), v = Int.random(in: 0 ..< size, using: &rng)
                if u != v || loops { out.append([u, v]) }
            }
            return out
        }
        let pairs = randomPairs(8, n)
        let permutation = Array(0 ..< n).shuffled(using: &rng)
        let order = Array(0 ..< pairs.count).shuffled(using: &rng)
        let copyPairs = order.map { [permutation[pairs[$0][0]], permutation[pairs[$0][1]]] }
        let patternPairs = randomPairs(3, k)
        let colors = pairs.map { _ in Int.random(in: 0 ..< 2, using: &rng) }
        let copyColors = order.map { colors[$0] }
        let patternColors = patternPairs.map { _ in Int.random(in: 0 ..< 2, using: &rng) }
        let context = "seed \(seed): \(pairs) \(colors), copy \(copyPairs), pattern \(patternPairs) \(patternColors)"
        let graph = Pseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
        let copy = Pseudograph(vertices: 0 ..< n, edges: copyPairs.map { UndirectedEdge($0[0], $0[1]) })
        let pattern = Pseudograph(vertices: 0 ..< k, edges: patternPairs.map { UndirectedEdge($0[0], $0[1]) })
        let views = (DirectedPseudograph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected,
                     DirectedPseudograph(vertices: 0 ..< n, edges: copyPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected,
                     DirectedPseudograph(vertices: 0 ..< k, edges: patternPairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected)
        // Without colours.
        let isomorphic = Set(graph.isomorphisms(to: copy).map { Array($0.images) })
        #expect(!isomorphic.isEmpty, "\(context)")
        #expect(Set(views.0.isomorphisms(to: views.1).map { Array($0.images) }) == isomorphic, "\(context)")
        #expect(Set(graph.isomorphisms(to: views.1).map { Array($0.images) }) == isomorphic, "\(context)")
        let induced = Set(pattern.subgraphIsomorphisms(to: graph).map { Array($0.images) })
        let mono = Set(pattern.monomorphisms(to: graph).map { Array($0.images) })
        #expect(induced.isSubset(of: mono), "\(context)")
        #expect(Set(views.2.subgraphIsomorphisms(to: views.0).map { Array($0.images) }) == induced, "\(context)")
        #expect(Set(views.2.monomorphisms(to: graph).map { Array($0.images) }) == mono, "\(context)")
        if !loops {
            let multigraph = Multigraph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })!
            let copyMultigraph = Multigraph(vertices: 0 ..< n, edges: copyPairs.map { UndirectedEdge($0[0], $0[1]) })!
            let patternMultigraph = Multigraph(vertices: 0 ..< k, edges: patternPairs.map { UndirectedEdge($0[0], $0[1]) })!
            #expect(Set(multigraph.isomorphisms(to: copyMultigraph).map { Array($0.images) }) == isomorphic, "\(context)")
            #expect(Set(patternMultigraph.subgraphIsomorphisms(to: multigraph).map { Array($0.images) }) == induced, "\(context)")
            #expect(Set(patternMultigraph.monomorphisms(to: multigraph).map { Array($0.images) }) == mono, "\(context)")
        }
        // With edge colours by position: the copy's colours moved with its edges, so the coloured
        // mappings are among the uncoloured ones, and the identity's relabelling is one of them.
        let coloured = Set(graph.isomorphisms(to: copy, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { colors[$0] }, otherEdgeColor: { copyColors[$0] }).map { Array($0.images) })
        #expect(coloured.isSubset(of: isomorphic) && coloured.contains(permutation), "\(context)")
        #expect(Set(views.0.isomorphisms(to: views.1, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { colors[$0] }, otherEdgeColor: { copyColors[$0] }).map { Array($0.images) }) == coloured, "\(context)")
        let colouredMono = Set(pattern.monomorphisms(to: graph, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternColors[$0] }, otherEdgeColor: { colors[$0] }).map { Array($0.images) })
        #expect(colouredMono.isSubset(of: mono), "\(context)")
        #expect(Set(views.2.monomorphisms(to: views.0, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternColors[$0] }, otherEdgeColor: { colors[$0] }).map { Array($0.images) }) == colouredMono, "\(context)")
    }

    @Test("An undirected graph's directed view (each edge as two arcs) has the same mappings in all three problems", .tags(.randomized), arguments: 0 ..< 16)
    func directedViewOfUndirected(seed: Int) {
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 5, k = 3
        let edges = (0 ..< 7).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
        let permutation = Array(0 ..< n).shuffled(using: &rng)
        let copyEdges = edges.map { UndirectedEdge(permutation[$0.v], permutation[$0.u]) }.shuffled(using: &rng)
        let patternEdges = (0 ..< 3).map { _ in UndirectedEdge(Int.random(in: 0 ..< k, using: &rng), Int.random(in: 0 ..< k, using: &rng)) }
        let context = "seed \(seed): \(edges), copy \(copyEdges), pattern \(patternEdges)"
        let graph = Pseudograph(vertices: 0 ..< n, edges: edges)
        let copy = Pseudograph(vertices: 0 ..< n, edges: copyEdges)
        let pattern = Pseudograph(vertices: 0 ..< k, edges: patternEdges)
        let isomorphic = Set(graph.isomorphisms(to: copy).map { Array($0.images) })
        #expect(isomorphic.contains(permutation), "\(context)")
        #expect(Set(graph.directed.isomorphisms(to: copy.directed).map { Array($0.images) }) == isomorphic, "\(context)")
        #expect(Set(pattern.directed.subgraphIsomorphisms(to: graph.directed).map { Array($0.images) }) == Set(pattern.subgraphIsomorphisms(to: graph).map { Array($0.images) }), "\(context)")
        #expect(Set(pattern.directed.monomorphisms(to: graph.directed).map { Array($0.images) }) == Set(pattern.monomorphisms(to: graph).map { Array($0.images) }), "\(context)")
    }

    @Test("Relabelled copies: renaming the target's vertices (as Strings) moves every mapping, renaming the pattern's reorders it; colours move along", .tags(.randomized), arguments: 0 ..< 16)
    func relabelledCopies(seed: Int) {
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 6, k = 4
        let edges = (0 ..< 9).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
        let patternEdges = (0 ..< 4).map { _ in UndirectedEdge(Int.random(in: 0 ..< k, using: &rng), Int.random(in: 0 ..< k, using: &rng)) }
        let colors = (0 ..< n).map { _ in Int.random(in: 0 ..< 2, using: &rng) }
        let patternColors = (0 ..< k).map { _ in Int.random(in: 0 ..< 2, using: &rng) }
        // π renames target vertex v as "t\(π[v])", σ renames pattern vertex u as 10 + σ[u]; both
        // list their vertices in a shuffled order and their edges in a shuffled order.
        let pi = Array(0 ..< n).shuffled(using: &rng), sigma = Array(0 ..< k).shuffled(using: &rng)
        let targetOrder = Array(0 ..< n).shuffled(using: &rng), patternOrder = Array(0 ..< k).shuffled(using: &rng)
        let context = "seed \(seed): \(edges) \(colors), pattern \(patternEdges) \(patternColors), π \(pi), σ \(sigma)"
        let graph = Pseudograph(vertices: 0 ..< n, edges: edges)
        let pattern = Pseudograph(vertices: 0 ..< k, edges: patternEdges)
        let renamedGraph = Pseudograph(vertices: targetOrder.map { "t\(pi[$0])" }, edges: edges.shuffled(using: &rng).map { UndirectedEdge("t\(pi[$0.u])", "t\(pi[$0.v])") })
        let renamedPattern = Pseudograph(vertices: patternOrder.map { 10 + sigma[$0] }, edges: patternEdges.shuffled(using: &rng).map { UndirectedEdge(10 + sigma[$0.u], 10 + sigma[$0.v]) })
        let back = Dictionary(uniqueKeysWithValues: (0 ..< n).map { ("t\(pi[$0])", $0) })
        let renamedColor = Dictionary(uniqueKeysWithValues: (0 ..< n).map { ("t\(pi[$0])", colors[$0]) })
        let renamedPatternColor = Dictionary(uniqueKeysWithValues: (0 ..< k).map { (10 + sigma[$0], patternColors[$0]) })
        // A mapping of the renamed pair, read as one of the original pair: pattern vertex u is
        // 10 + σ[u] in the renamed pattern, at position patternOrder.firstIndex(of: u).
        let original = { (images: [String]) in (0 ..< k).map { u in back[images[patternOrder.firstIndex(of: u)!]]! } }
        let self_ = Set(graph.isomorphisms(to: graph).map { Array($0.images) })
        let renamedSelf = Set(graph.isomorphisms(to: renamedGraph).map { $0.images.map { back[$0]! } })
        #expect(renamedSelf == self_, "\(context)")
        for (name, plain, renamed) in [
            ("subgraph", Set(pattern.subgraphIsomorphisms(to: graph).map { Array($0.images) }), Set(renamedPattern.subgraphIsomorphisms(to: renamedGraph).map { original(Array($0.images)) })),
            ("mono", Set(pattern.monomorphisms(to: graph).map { Array($0.images) }), Set(renamedPattern.monomorphisms(to: renamedGraph).map { original(Array($0.images)) })),
            ("subgraph, coloured", Set(pattern.subgraphIsomorphisms(to: graph, vertexColor: { patternColors[$0] }, otherVertexColor: { colors[$0] }).map { Array($0.images) }),
             Set(renamedPattern.subgraphIsomorphisms(to: renamedGraph, vertexColor: { renamedPatternColor[$0]! }, otherVertexColor: { renamedColor[$0]! }).map { original(Array($0.images)) })),
            ("mono, coloured", Set(pattern.monomorphisms(to: graph, vertexColor: { patternColors[$0] }, otherVertexColor: { colors[$0] }).map { Array($0.images) }),
             Set(renamedPattern.monomorphisms(to: renamedGraph, vertexColor: { renamedPatternColor[$0]! }, otherVertexColor: { renamedColor[$0]! }).map { original(Array($0.images)) })),
        ] {
            #expect(plain == renamed, "\(name), \(context)")
        }
        let coloured = Set(graph.isomorphisms(to: graph, vertexColor: { colors[$0] }, otherVertexColor: { colors[$0] }).map { Array($0.images) })
        let renamedColoured = Set(graph.isomorphisms(to: renamedGraph, vertexColor: { colors[$0] }, otherVertexColor: { renamedColor[$0]! }).map { $0.images.map { back[$0]! } })
        #expect(renamedColoured == coloured && coloured.contains(Array(0 ..< n)), "\(context)")
    }

    @Test("Weisfeiler–Leman hashes: equal across representations and relabelled copies, per vertex too", .tags(.randomized), arguments: 0 ..< 16)
    func weisfeilerLehmanAcrossRepresentations(seed: Int) {
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 9
        var pairs: [[Int]] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n where Int.random(in: 0 ..< 10, using: &rng) < 3 { pairs.append([u, v]) }
        }
        let permutation = Array(0 ..< n).shuffled(using: &rng)
        let context = "seed \(seed): \(pairs), π \(permutation)"
        let graph = Pseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
        let copy = Pseudograph(vertices: 0 ..< n, edges: pairs.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[1]], permutation[$0[0]]) })
        let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
        let matrix = AdjacencyMatrix(vertexCount: n, edges: pairs.map { DirectedEdge(from: $0[0], to: $0[1]) }).undirected
        let labeled = LabeledGraph<String, AdjacencyMatrix>(vertices: (0 ..< n).map { "v\($0)" }, edges: pairs.map { DirectedEdge(from: "v\($0[0])", to: "v\($0[1])") }).undirected
        for k in 0 ... 3 {
            let hash = graph.weisfeilerLehmanGraphHash(iterations: k)
            #expect(copy.weisfeilerLehmanGraphHash(iterations: k) == hash, "k \(k), \(context)")
            #expect(list.weisfeilerLehmanGraphHash(iterations: k) == hash, "k \(k), \(context)")
            #expect(matrix.weisfeilerLehmanGraphHash(iterations: k) == hash, "k \(k), \(context)")
            #expect(labeled.weisfeilerLehmanGraphHash(iterations: k) == hash, "k \(k), \(context)")
            let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: k)
            let copyHashes = copy.weisfeilerLehmanSubgraphHashes(iterations: k)
            let matrixHashes = matrix.weisfeilerLehmanSubgraphHashes(iterations: k)
            let labeledHashes = labeled.weisfeilerLehmanSubgraphHashes(iterations: k)
            for v in 0 ..< n {
                #expect(copyHashes.hashes(of: permutation[v]) == hashes.hashes(of: v), "k \(k), \(v), \(context)")
                #expect(matrixHashes.hashes(of: v) == hashes.hashes(of: v), "k \(k), \(v), \(context)")
                #expect(labeledHashes.hashes(of: "v\(v)") == hashes.hashes(of: v), "k \(k), \(v), \(context)")
            }
        }
        // Directed: DirectedPseudograph, CSR and a renamed LabeledGraph.
        let arcs = pairs.map { Int.random(in: 0 ..< 2, using: &rng) == 0 ? $0 : [$0[1], $0[0]] }
        let digraph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let rows = CompressedSparseRow(vertexCount: n, edges: arcs.map { DirectedEdge(from: permutation[$0[0]], to: permutation[$0[1]]) })
        let named = LabeledGraph<String, CompressedSparseRow>(vertices: (0 ..< n).map { "v\($0)" }, edges: arcs.map { DirectedEdge(from: "v\($0[0])", to: "v\($0[1])") })
        #expect(rows.weisfeilerLehmanGraphHash() == digraph.weisfeilerLehmanGraphHash(), "\(context)")
        #expect(named.weisfeilerLehmanGraphHash() == digraph.weisfeilerLehmanGraphHash(), "\(context)")
        let digraphHashes = digraph.weisfeilerLehmanSubgraphHashes(), rowHashes = rows.weisfeilerLehmanSubgraphHashes()
        #expect((0 ..< n).allSatisfy { rowHashes.hashes(of: permutation[$0]) == digraphHashes.hashes(of: $0) }, "\(context)")
    }

    @Test("Isomorphism: equal and hashed by its images alone; Isomorphisms: the same order on every pass", .tags(.conformance))
    func valueLaws() {
        let cycle = Pseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        let other = Pseudograph(vertices: 0 ..< 5, edges: [UndirectedEdge(3, 4), UndirectedEdge(2, 3), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(4, 0)])
        let sequence = cycle.isomorphisms(to: cycle)
        let first = Array(sequence), second = Array(sequence)
        #expect(first.count == 10)
        #expect(first == second)
        #expect(first.map { Array($0.images) } == second.map { Array($0.images) })
        #expect(Set(first).count == 10)
        // The graphs are not compared: the same images over another target (same vertices) are equal.
        let elsewhere = Array(cycle.isomorphisms(to: other))
        #expect(Set(elsewhere) == Set(first))
        for (a, b) in zip(first, first.dropFirst()) {
            #expect(a != b)
            #expect(a == a && a.hashValue == a.hashValue)
        }
        for mapping in first {
            let twin = elsewhere.first { Array($0.images) == Array(mapping.images) }!
            #expect(twin == mapping && twin.hashValue == mapping.hashValue)
            #expect(!mapping.description.isEmpty && twin.description == mapping.description)
        }
        // Two iterators of one sequence are independent.
        var a = sequence.makeIterator(), b = sequence.makeIterator()
        let a0 = a.next(), a1 = a.next(), b0 = b.next()
        #expect(a0 != nil && a0 == b0 && a1 != a0)
        // A directed pair: the same laws.
        let arcs = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let rotations = Array(arcs.isomorphisms(to: arcs))
        #expect(rotations.count == 3 && Set(rotations).count == 3 && rotations == Array(arcs.isomorphisms(to: arcs)))
    }

    @Test("Colour closures are read at most once per vertex and edge, at the call: iterating the sequence reads none")
    func colourClosuresReadOnce() {
        let pattern = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        var reads = [0, 0, 0, 0]
        let sequence = pattern.monomorphisms(
            to: target,
            vertexColor: { _ in reads[0] += 1; return 0 }, otherVertexColor: { _ in reads[1] += 1; return 0 },
            edgeColor: { _ in reads[2] += 1; return 0 }, otherEdgeColor: { _ in reads[3] += 1; return 0 })
        let atCall = reads
        #expect(atCall[0] <= 3 && atCall[1] <= 4 && atCall[2] <= 2 && atCall[3] <= 4)
        #expect(Array(sequence).count == 8)
        #expect(reads == atCall)
        reads = [0, 0, 0, 0]
        _ = pattern.isomorphisms(to: pattern, vertexColor: { _ in reads[0] += 1; return 0 }, otherVertexColor: { _ in reads[1] += 1; return 0 }).map { $0 }
        #expect(reads[0] <= 3 && reads[1] <= 3)
        reads = [0, 0, 0, 0]
        _ = pattern.weisfeilerLehmanSubgraphHashes(iterations: 3, vertexColor: { _ in reads[0] += 1; return 0 }, edgeColor: { _ in reads[2] += 1; return 0 })
        #expect(reads[0] <= 3 && reads[2] <= 2)
    }
}
