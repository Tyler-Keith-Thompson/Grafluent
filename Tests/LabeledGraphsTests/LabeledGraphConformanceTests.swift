// Algorithms see through the labels. Traversal, Connectivity and ShortestPaths run on seeded random
// labeled graphs over both bases, and every result must be exactly the same algorithm's result on
// `graph.base`, mapped through the labels (base vertex i is `graph.vertices[i]`; edge positions are
// the base's, unchanged). Then the undirected view against the base's view, Codable as
// `{labels, base}` with its corrupt payloads, the collections, copy-on-write, the resets and
// capacity, and Sendable. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import Foundation
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import Multigraphs
import ShortestPaths
import Testing
import Traversal

@Suite("LabeledGraphs conformances and algorithms", .tags(.conformance))
struct LabeledGraphConformanceTests {
    @Test("Traversal, Connectivity and ShortestPaths over CSR equal the base's results through the labels", arguments: [1, 2, 3, 4, 5, 6])
    func algorithmsOverCSR(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 6 + seed * 4
        let names = (0 ..< n).map { "v\(($0 * 7 + seed) % n)-\($0)" }.shuffled(using: &rng)
        var edges: [DirectedEdge<String>] = []
        for _ in 0 ..< n * (seed % 3 + 1) {
            edges.append(DirectedEdge(from: names.randomElement(using: &rng)!, to: names.randomElement(using: &rng)!))
        }
        // Listed labels in a shuffled order, then the edges: indices follow `vertices`, not names.
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: names.shuffled(using: &rng), edges: edges)
        let base = graph.base
        let labels = Array(graph.vertices)
        func bfs(_ event: BreadthFirstSearchEvent<Int>) -> BreadthFirstSearchEvent<String> {
            switch event {
            case .discover(let v): .discover(labels[v])
            case .treeEdge(let e): .treeEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .nonTreeEdge(let e): .nonTreeEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .finish(let v): .finish(labels[v])
            }
        }
        func dfs(_ event: DepthFirstSearchEvent<Int>) -> DepthFirstSearchEvent<String> {
            switch event {
            case .discover(let v): .discover(labels[v])
            case .treeEdge(let e): .treeEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .backEdge(let e): .backEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .forwardEdge(let e): .forwardEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .crossEdge(let e): .crossEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .finish(let v): .finish(labels[v])
            }
        }
        #expect(graph.edges.map { $0 } == base.edges.map { DirectedEdge(from: labels[$0.source], to: labels[$0.target]) })
        #expect(graph.topologicalSort() == base.topologicalSort()?.map { labels[$0] })
        #expect(graph.topologicalGenerations() == base.topologicalGenerations()?.map { $0.map { labels[$0] } })
        #expect(Array(graph.lazy.depthFirstSearch()) == base.lazy.depthFirstSearch().map(dfs))
        #expect(graph.weaklyConnectedComponents().map { Array($0) } == base.weaklyConnectedComponents().map { $0.map { labels[$0] } })
        #expect(graph.stronglyConnectedComponents().map { Array($0) } == base.stronglyConnectedComponents().map { $0.map { labels[$0] } })
        #expect(graph.condensation().components.map { Array($0) } == base.condensation().components.map { $0.map { labels[$0] } })
        #expect(Array(graph.condensation().graph.edges) == Array(base.condensation().graph.edges))
        #expect(graph.attractingComponents().map { Array($0) } == base.attractingComponents().map { $0.map { labels[$0] } })
        #expect(graph.isStronglyConnected == base.isStronglyConnected)
        #expect(graph.findCycle()?.vertices == base.findCycle()?.vertices.map { labels[$0] })
        #expect(graph.findCycle()?.edges == base.findCycle()?.edges)
        let weight = (0 ..< graph.edgeCount).map { Int(UInt64($0) &* 2_654_435_761 % 9) + 1 }
        for (i, source) in labels.enumerated() {
            #expect(Array(graph.lazy.breadthFirstSearch(from: source)) == base.lazy.breadthFirstSearch(from: i).map(bfs))
            #expect(Array(graph.lazy.depthFirstSearch(from: source)) == base.lazy.depthFirstSearch(from: i).map(dfs))
            #expect(graph.breadthFirstLayers(from: source) == base.breadthFirstLayers(from: i).map { $0.map { labels[$0] } })
            #expect(graph.descendants(of: source) == Set(base.descendants(of: i).map { labels[$0] }))
            let tree = graph.dijkstraShortestPaths(from: source) { weight[$0] }
            let baseTree = base.dijkstraShortestPaths(from: i) { weight[$0] }
            let bellman = graph.bellmanFordShortestPaths(from: source) { weight[$0] }
            let hops = graph.shortestPaths(from: source), baseHops = base.shortestPaths(from: i)
            for (j, target) in labels.enumerated() {
                #expect(tree.distance(to: target) == baseTree.distance(to: j))
                #expect(tree.parentEdge(of: target) == baseTree.parentEdge(of: j))
                #expect(tree.parent(of: target) == baseTree.parent(of: j).map { labels[$0] })
                #expect(tree.path(to: target)?.vertices == baseTree.path(to: j)?.vertices.map { labels[$0] })
                #expect(tree.path(to: target)?.edges == baseTree.path(to: j)?.edges)
                #expect(bellman?.distance(to: target) == tree.distance(to: target))
                #expect(hops.distance(to: target) == baseHops.distance(to: j))
                #expect(graph.hasPath(from: source, to: target) == base.hasPath(from: i, to: j))
            }
        }
    }

    @Test("Traversal, Connectivity and ShortestPaths over the matrix equal the base's results through the labels", arguments: [1, 2, 3, 4, 5, 6])
    func algorithmsOverMatrix(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(100 + seed))
        let n = 5 + seed * 3
        var graph = LabeledGraph<String, AdjacencyMatrix>()
        // Built by mutation: labels arrive in a random order, and some edges are removed again.
        for _ in 0 ..< n * 3 {
            let a = "n\(Int.random(in: 0 ..< n, using: &rng))", b = "n\(Int.random(in: 0 ..< n, using: &rng))"
            graph.insert(edge: DirectedEdge(from: a, to: b))
            if Bool.random(using: &rng), Bool.random(using: &rng) { graph.remove(edge: DirectedEdge(from: b, to: a)) }
        }
        graph.insert("isolated")
        let base = graph.base
        let labels = Array(graph.vertices)
        func bfs(_ event: BreadthFirstSearchEvent<Int>) -> BreadthFirstSearchEvent<String> {
            switch event {
            case .discover(let v): .discover(labels[v])
            case .treeEdge(let e): .treeEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .nonTreeEdge(let e): .nonTreeEdge(DirectedEdge(from: labels[e.source], to: labels[e.target]))
            case .finish(let v): .finish(labels[v])
            }
        }
        #expect(graph.edges.map { $0 } == base.edges.map { DirectedEdge(from: labels[$0.source], to: labels[$0.target]) })
        #expect(graph.topologicalSort() == base.topologicalSort()?.map { labels[$0] })
        #expect(graph.weaklyConnectedComponents().map { Array($0) } == base.weaklyConnectedComponents().map { $0.map { labels[$0] } })
        #expect(graph.stronglyConnectedComponents().map { Array($0) } == base.stronglyConnectedComponents().map { $0.map { labels[$0] } })
        #expect(graph.condensation().components.map { Array($0) } == base.condensation().components.map { $0.map { labels[$0] } })
        let weight: (AdjacencyMatrix.Edges.Index) -> Int = { ($0.source * 7 + $0.target * 3) % 5 + 1 }
        for (i, source) in labels.enumerated() {
            #expect(Array(graph.lazy.breadthFirstSearch(from: source)) == base.lazy.breadthFirstSearch(from: i).map(bfs))
            #expect(graph.descendants(of: source) == Set(base.descendants(of: i).map { labels[$0] }))
            #expect(graph.ancestors(of: source) == Set(base.ancestors(of: i).map { labels[$0] }))
            let tree = graph.dijkstraShortestPaths(from: source, weight: weight)
            let baseTree = base.dijkstraShortestPaths(from: i, weight: weight)
            let dominators = graph.dominatorTree(root: source), baseDominators = base.dominatorTree(root: i)
            for (j, target) in labels.enumerated() {
                #expect(tree.distance(to: target) == baseTree.distance(to: j))
                #expect(tree.parentEdge(of: target) == baseTree.parentEdge(of: j))
                #expect(dominators.immediateDominator(of: target) == baseDominators.immediateDominator(of: j).map { labels[$0] })
                let path = graph.bidirectionalShortestPath(from: source, to: target)
                let basePath = base.bidirectionalShortestPath(from: i, to: j)
                #expect(path?.vertices == basePath?.vertices.map { labels[$0] })
                #expect(path?.edges == basePath?.edges)
            }
        }
        // The undirected view: components and neighbourhoods are the base's view, through the labels.
        let view = graph.undirectedView, baseView = base.undirectedView
        #expect(view.connectedComponents().map { Array($0) } == baseView.connectedComponents().map { $0.map { labels[$0] } })
        for (i, v) in labels.enumerated() {
            #expect(Array(view.neighbors(of: v)) == baseView.neighbors(of: i).map { labels[$0] })
            #expect(Array(view.incidentEdges(of: v)) == Array(baseView.incidentEdges(of: i)))
            #expect(view.degree(of: v) == baseView.degree(of: i))
        }
    }

    @Test("Codable is {labels, base}; decoding gives back the same graph and index assignment")
    func codableRoundTrip() throws {
        let graph = LabeledGraph<String, CompressedSparseRow>(vertices: ["z"], edges: [DirectedEdge(from: "x", to: "z"), DirectedEdge(from: "z", to: "y")])
        let data = try JSONEncoder().encode(graph)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["labels", "base"])
        #expect(object["labels"] as? [String] == ["z", "x", "y"])
        let decoded = try JSONDecoder().decode(LabeledGraph<String, CompressedSparseRow>.self, from: data)
        #expect(decoded == graph)
        #expect(Array(decoded.vertices) == ["z", "x", "y"])
        #expect(decoded.base == graph.base)
        // The base in its own form.
        let base = try JSONDecoder().decode(CompressedSparseRow.self, from: JSONSerialization.data(withJSONObject: object["base"]!))
        #expect(base == graph.base)

        var matrix = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "a")])
        matrix.insert("c")
        let again = try JSONDecoder().decode(LabeledGraph<String, AdjacencyMatrix>.self, from: JSONEncoder().encode(matrix))
        #expect(again == matrix && Array(again.vertices) == ["b", "a", "c"] && again.base == matrix.base)
    }

    @Test("Decoding re-checks the labels against the base, as dataCorrupted")
    func codableCorruptPayloads() throws {
        let base = String(decoding: try JSONEncoder().encode(CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])), as: UTF8.self)
        for labels in [#"["a"]"#, #"["a", "b", "c"]"#, #"["a", "a"]"#] {
            let payload = Data(#"{"labels": \#(labels), "base": \#(base)}"#.utf8)
            do {
                let decoded = try JSONDecoder().decode(LabeledGraph<String, CompressedSparseRow>.self, from: payload)
                Issue.record("decoded \(decoded) from \(labels)")
            } catch DecodingError.dataCorrupted {
            } catch {
                Issue.record("unexpected error \(error) for \(labels)")
            }
        }
        let good = Data(#"{"labels": ["a", "b"], "base": \#(base)}"#.utf8)
        let decoded = try JSONDecoder().decode(LabeledGraph<String, CompressedSparseRow>.self, from: good)
        #expect(Array(decoded.edges) == [DirectedEdge(from: "a", to: "b")])
    }

    @Test("Decoding errors name the part at fault in codingPath: the base, or the labels")
    func codableCodingPaths() throws {
        // A base whose vertices are not 0..<n: the base is at fault, whatever the labels.
        let unordered = String(decoding: try JSONEncoder().encode(AdjacencyList<Int>(vertices: [5, 6])), as: UTF8.self)
        do {
            let decoded = try JSONDecoder().decode(LabeledGraph<String, AdjacencyList<Int>>.self, from: Data(#"{"labels": ["a", "b"], "base": \#(unordered)}"#.utf8))
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["base"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // A base that is fine with the wrong labels: the labels are at fault.
        let dense = String(decoding: try JSONEncoder().encode(AdjacencyList<Int>(vertices: [0, 1])), as: UTF8.self)
        do {
            let decoded = try JSONDecoder().decode(LabeledGraph<String, AdjacencyList<Int>>.self, from: Data(#"{"labels": ["a", "a"], "base": \#(dense)}"#.utf8))
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["labels"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The base's own decoding error passes through, at its own path inside "base".
        do {
            let decoded = try JSONDecoder().decode(LabeledGraph<String, AdjacencyList<Int>>.self, from: Data(#"{"labels": ["a"], "base": {"vertices": [0], "edges": [0]}}"#.utf8))
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.first?.stringValue == "base")
        } catch {
            Issue.record("unexpected error \(error)")
        }
        let accepted = try JSONDecoder().decode(LabeledGraph<String, AdjacencyList<Int>>.self, from: Data(#"{"labels": ["a", "b"], "base": \#(dense)}"#.utf8))
        #expect(Array(accepted.vertices) == ["a", "b"] && accepted.edgeCount == 0)
    }

    @Test("Over a base with parallel edges, equality and hashing count each labeled edge's copies")
    func parallelEdgeBaseEquality() throws {
        // a→b twice and b→c once, numbered a, b, c on the left and c, a, b on the right.
        let lhs = try LabeledGraph(DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]), labels: ["a", "b", "c"])
        let rhs = try LabeledGraph(DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 2)]), labels: ["c", "a", "b"])
        #expect(lhs == rhs && rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(Set([lhs, rhs]).count == 1)
        // The same edge set and edge count, other multiplicities: a→b once, b→c twice.
        let other = try LabeledGraph(DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 2)]), labels: ["c", "a", "b"])
        #expect(Set(other.edges) == Set(lhs.edges) && other.edgeCount == lhs.edgeCount)
        #expect(lhs != other && other != lhs)
        // An edge the left graph lacks.
        let missing = try LabeledGraph(DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1)]), labels: ["c", "a", "b"])
        #expect(lhs != missing && missing != lhs)
    }

    @Test("Mutation returns the labels stored in the graph, not the equal ones passed in")
    func storedLabelInstances() throws {
        // Equal by id, told apart by tag.
        struct Tagged: Hashable {
            let id: Int
            let tag: String
            static func == (lhs: Tagged, rhs: Tagged) -> Bool { lhs.id == rhs.id }
            func hash(into hasher: inout Hasher) { hasher.combine(id) }
        }
        var graph = LabeledGraph<Tagged, AdjacencyMatrix>(vertices: [Tagged(id: 1, tag: "stored"), Tagged(id: 2, tag: "stored")])
        let inserted = graph.insert(edge: DirectedEdge(from: Tagged(id: 1, tag: "probe"), to: Tagged(id: 2, tag: "probe")))
        #expect(inserted.inserted)
        #expect(inserted.memberAfterInsert.source.tag == "stored" && inserted.memberAfterInsert.target.tag == "stored")
        let again = try graph.insert(checked: DirectedEdge(from: Tagged(id: 1, tag: "probe"), to: Tagged(id: 2, tag: "probe")))
        #expect(!again.inserted && again.memberAfterInsert.source.tag == "stored")
        #expect(graph.insert(Tagged(id: 2, tag: "probe")).memberAfterInsert.tag == "stored")
        let removed = graph.remove(edge: DirectedEdge(from: Tagged(id: 1, tag: "probe"), to: Tagged(id: 2, tag: "probe")))
        #expect(removed?.source.tag == "stored" && removed?.target.tag == "stored")
        #expect(graph.edgeCount == 0)
        #expect(graph.vertices.map(\.tag) == ["stored", "stored"])
    }

    @Test("Edges: RandomAccessCollection over CSR, BidirectionalCollection over the matrix, positions the base's")
    func edgeCollections() {
        let csr = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "c")])
        #expect(Array(csr.edges.indices) == Array(csr.base.edges.indices))
        #expect(csr.edges.last == DirectedEdge(from: "b", to: "c"))
        #expect(csr.edges.reversed().map { $0.source } == ["b", "a", "a"])
        #expect(csr.edges.distance(from: 0, to: 3) == 3 && csr.edges.index(0, offsetBy: 2) == 2)
        #expect(csr.edges.contains(DirectedEdge(from: "a", to: "c")) && !csr.edges.contains(DirectedEdge(from: "c", to: "a")))
        #expect(csr.edges.firstIndex(of: DirectedEdge(from: "b", to: "c")) == 2)
        let matrix = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "c")])
        #expect(Array(matrix.edges.indices) == Array(matrix.base.edges.indices))
        #expect(matrix.edges.last == DirectedEdge(from: "b", to: "c"))
        #expect(matrix.edges.reversed().map { $0.target } == ["c", "c", "b"])
        #expect(matrix.edges.contains(DirectedEdge(from: "a", to: "c")) && !matrix.edges.contains(DirectedEdge(from: "c", to: "a")))
        #expect(matrix.edges.isEmpty == false && LabeledGraph<String, AdjacencyMatrix>(vertices: ["a"]).edges.isEmpty)
        // vertices is the OrderedSet itself.
        #expect(matrix.vertices.firstIndex(of: "c") == 2 && matrix.vertices[1] == "b")
    }

    @Test("Copies are values: mutating one leaves the other unchanged", .tags(.copyOnWrite))
    func copyOnWrite() {
        var graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b")])
        let copy = graph
        graph.insert(edge: DirectedEdge(from: "b", to: "c"))
        graph.remove(edge: DirectedEdge(from: "a", to: "b"))
        #expect(Array(copy.vertices) == ["a", "b"] && Array(copy.edges) == [DirectedEdge(from: "a", to: "b")])
        #expect(copy.base.vertexCount == 2 && copy.base.edgeCount == 1)
        #expect(Array(graph.vertices) == ["a", "b", "c"] && Array(graph.edges) == [DirectedEdge(from: "b", to: "c")])
        var other = copy
        other.removeAll()
        #expect(copy.vertexCount == 2 && other.vertexCount == 0 && other.base.vertexCount == 0)
    }

    @Test("Resets with and without capacity, and reserveCapacity, change only what they say")
    func resetsAndCapacity() {
        var graph = LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        graph.reserveCapacity(vertexCount: 100)
        #expect(graph == LabeledGraph<String, AdjacencyMatrix>(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")]))
        graph.removeAllEdges(keepingCapacity: true)
        #expect(Array(graph.vertices) == ["a", "b"] && graph.edgeCount == 0 && graph.base.vertexCount == 2)
        graph.insert(edge: DirectedEdge(from: "b", to: "c"))
        #expect(graph.vertexIndex(of: "c") == 2)
        graph.removeAll(keepingCapacity: true)
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.base == AdjacencyMatrix())
        #expect(graph.insert("z") == (true, "z") && graph.vertexIndex(of: "z") == 0)
        #expect(graph == LabeledGraph<String, AdjacencyMatrix>(vertices: ["z"]))
    }

    @Test("init(_ graph:) copies another directed graph, including a labeled one over the other base")
    func initFromGraph() {
        let matrix = LabeledGraph<String, AdjacencyMatrix>(vertices: ["s"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "s")])
        let csr = LabeledGraph<String, CompressedSparseRow>(matrix)
        #expect(Array(csr.vertices) == Array(matrix.vertices))
        #expect(Array(csr.edges) == Array(matrix.edges))
        let back = LabeledGraph<String, AdjacencyMatrix>(csr)
        #expect(back == matrix && back.base == matrix.base)
    }

    @Test("Sendable where the label and base are; usable across tasks")
    func sendable() async {
        let graph = LabeledGraph<String, CompressedSparseRow>(edges: [DirectedEdge(from: "a", to: "b")])
        let count = await Task.detached { graph.successors(of: "a").count }.value
        #expect(count == 1)
        let sendable: any Sendable = graph
        #expect(sendable is LabeledGraph<String, CompressedSparseRow>)
    }

    @Test("init(_:labels:) accepts any dense DirectedGraph<Int> base whose vertices are 0..<n in order")
    func otherBases() throws {
        let csr = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1)])
        let graph = try LabeledGraph(csr, labels: ["x", "y", "z"])
        #expect(Array(graph.successors(of: "z")) == ["x"])
        #expect(graph.topologicalSort() == ["z", "x", "y"])
        #expect(graph.base == csr)
        // Equal labeled graphs from bases with a different numbering.
        let renumbered = try LabeledGraph(CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]), labels: ["y", "z", "x"])
        #expect(renumbered == graph && renumbered.base != graph.base)
    }

    /// A dense base that lists `order` as its vertices and reports `bound`, its indices reversed
    /// when `reversedIndex` is set: each field breaks one precondition of `init(_:labels:)`.
    struct ListedBase: DirectedGraph, Codable {
        var order: [Int]
        var bound: Int?
        var reversedIndex = false
        var vertices: [Int] { order }
        var edges: [DirectedEdge<Int>] { [] }
        func successors(of vertex: Int) -> [Int] { [] }
        func outEdges(of vertex: Int) -> [Int] { [] }
        var vertexIndexBound: Int? { bound }
        func vertexIndex(of vertex: Int) -> Int { reversedIndex ? order.count - 1 - vertex : vertex }
        func vertex(atIndex index: Int) -> Int { reversedIndex ? order.count - 1 - index : index }
    }

    @Test("Decoding checks every precondition of init(_:labels:) and names the part at fault")
    func codableChecksEachPrecondition() throws {
        // No dense indices: the base.
        let unbounded = String(decoding: try JSONEncoder().encode(ListedBase(order: [0, 1], bound: nil)), as: UTF8.self)
        let noBound = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LabeledGraph<String, ListedBase>.self, from: Data(#"{"labels": ["a", "b"], "base": \#(unbounded)}"#.utf8))
        }
        if case .dataCorrupted(let context) = noBound { #expect(context.codingPath.map(\.stringValue) == ["base"]) } else { Issue.record("\(String(describing: noBound))") }
        // Vertices 0, 1 in order, but vertexIndex(of: 0) is 1: the base.
        let reversed = String(decoding: try JSONEncoder().encode(ListedBase(order: [0, 1], bound: 2, reversedIndex: true)), as: UTF8.self)
        let badIndex = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LabeledGraph<String, ListedBase>.self, from: Data(#"{"labels": ["a", "b"], "base": \#(reversed)}"#.utf8))
        }
        if case .dataCorrupted(let context) = badIndex { #expect(context.codingPath.map(\.stringValue) == ["base"]) } else { Issue.record("\(String(describing: badIndex))") }
        // One vertex listed under a bound of two: the base, though two labels match the bound.
        let short = String(decoding: try JSONEncoder().encode(ListedBase(order: [0], bound: 2)), as: UTF8.self)
        let shortList = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LabeledGraph<String, ListedBase>.self, from: Data(#"{"labels": ["a", "b"], "base": \#(short)}"#.utf8))
        }
        if case .dataCorrupted(let context) = shortList { #expect(context.codingPath.map(\.stringValue) == ["base"]) } else { Issue.record("\(String(describing: shortList))") }
        // A good base with one label too few: the labels.
        let good = String(decoding: try JSONEncoder().encode(ListedBase(order: [0, 1], bound: 2)), as: UTF8.self)
        let fewLabels = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LabeledGraph<String, ListedBase>.self, from: Data(#"{"labels": ["a"], "base": \#(good)}"#.utf8))
        }
        if case .dataCorrupted(let context) = fewLabels { #expect(context.codingPath.map(\.stringValue) == ["labels"]) } else { Issue.record("\(String(describing: fewLabels))") }
        // The same bases through init(_:labels:): the first requirement broken, as its LabelingError.
        #expect(throws: LabelingError.baseNotDenselyIndexed) { try LabeledGraph(ListedBase(order: [0, 1], bound: nil), labels: ["a", "b"]) }
        #expect(throws: LabelingError.baseVerticesNotInIndexOrder) { try LabeledGraph(ListedBase(order: [0, 1], bound: 2, reversedIndex: true), labels: ["a", "b"]) }
        #expect(throws: LabelingError.baseVerticesNotInIndexOrder) { try LabeledGraph(ListedBase(order: [0], bound: 2), labels: ["a", "b"]) }
        #expect(throws: LabelingError.labelCountMismatch(labelCount: 1, vertexCount: 2)) { try LabeledGraph(ListedBase(order: [0, 1], bound: 2), labels: ["a"]) }
        let accepted = try JSONDecoder().decode(LabeledGraph<String, ListedBase>.self, from: Data(#"{"labels": ["a", "b"], "base": \#(good)}"#.utf8))
        #expect(Array(accepted.vertices) == ["a", "b"] && accepted.vertexIndex(of: "b") == 1)
    }

    @Test("The checked: spellings and the index-space degrees answer for the vertex asked about")
    func checkedSpellingsMatchTheTrappingOnes() throws {
        // a→b, a→c, a→d, c→b: no two vertices have the same row, column or degree pattern.
        let edges = [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "a", to: "d"), DirectedEdge(from: "c", to: "b")]
        let matrix = LabeledGraph<String, AdjacencyMatrix>(edges: edges)
        let csr = LabeledGraph<String, CompressedSparseRow>(edges: edges)
        #expect(Array(matrix.vertices) == ["a", "b", "c", "d"])
        for (i, v) in ["a", "b", "c", "d"].enumerated() {
            #expect(try Array(matrix.outEdges(checked: v)) == Array(matrix.outEdges(of: v)))
            #expect(try Array(matrix.inEdges(checked: v)) == Array(matrix.inEdges(of: v)))
            #expect(try matrix.degree(checked: v) == matrix.degree(of: v))
            #expect(try Array(csr.outEdges(checked: v)) == Array(csr.outEdges(of: v)))
            #expect(matrix.outDegree(ofIndex: i) == matrix.outDegree(of: v) && csr.outDegree(ofIndex: i) == csr.outDegree(of: v))
            #expect(matrix.inDegree(ofIndex: i) == matrix.inDegree(of: v))
        }
        #expect(try matrix.degree(checked: "a") == 3 && matrix.degree(checked: "d") == 1)
        #expect(try matrix.outEdges(checked: "a").count == 3 && matrix.inEdges(checked: "b").count == 2)
        #expect(matrix.outDegree(ofIndex: 0) == 3 && matrix.inDegree(ofIndex: 1) == 2 && csr.outDegree(ofIndex: 3) == 0)
    }

    @Test("Successors and predecessors read by position as collections")
    func rowsByPosition() {
        let edges = [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "a", to: "d"), DirectedEdge(from: "c", to: "b")]
        let csr = LabeledGraph<String, CompressedSparseRow>(edges: edges)
        let row = csr.successors(of: "a")
        #expect(row.first == "b" && row.last == "d" && row[row.index(after: row.startIndex)] == "c")
        let matrix = LabeledGraph<String, AdjacencyMatrix>(edges: edges)
        let column = matrix.predecessors(of: "b")
        #expect(column.first == "a" && column.last == "c" && column.count == 2)
        let out = matrix.successors(of: "a")
        #expect(out.first == "b" && out.last == "d")
    }

    @Test("Equality over other index assignments: fewer labels or a subset of the edges is not equal")
    func equalityOtherAssignments() {
        let abc = LabeledGraph<String, CompressedSparseRow>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
        // Two of the three labels, in another order, with the same edge.
        let ba = LabeledGraph<String, CompressedSparseRow>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(abc != ba && ba != abc)
        // The same labels in another order, with one edge of the two.
        let both = LabeledGraph<String, AdjacencyMatrix>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        let one = LabeledGraph<String, AdjacencyMatrix>(vertices: ["b", "a"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(both != one && one != both)
        let reordered = LabeledGraph<String, AdjacencyMatrix>(vertices: ["b", "a"], edges: [DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "b")])
        #expect(both == reordered && reordered == both)
    }
}
