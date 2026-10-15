// Kruskal's and Prim's algorithms as event sequences (`kruskalEvents`, `primEvents`): Wikipedia's
// graph and a multigraph traced by hand on several representations, the trivial cases, early
// stopping and value semantics, the preconditions, and property tests replaying the events
// against `kruskalMinimumSpanningTree` and `primMinimumSpanningTree`. Case IDs (ST-nn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import SpanningTrees
import Testing

/// An undirected pseudograph with no vertex or edge indices, so the algorithms number the vertices
/// through a dictionary. A self-loop is listed twice at its vertex.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// Vertex indices (the positions in `vertices`) but no edge indices.
private struct VertexIndexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Vertex { vertices[index] }
}

@Suite("Kruskal and Prim events")
struct SpanningTreeEventTests {
    @Test("ST-250 Kruskal on Wikipedia's graph: every event in order, on every representation", .tags(.fixture))
    func kruskalWiki() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        // Tests/Catalogs/SpanningTrees/cases_events.out, ST-250.
        let expected: [KruskalEvent<Int, Int, Int>] = [
            .examineEdge(1, weight: 5), .treeEdge(1, merging: 3, into: 0),
            .examineEdge(5, weight: 5), .treeEdge(5, merging: 4, into: 2),
            .examineEdge(7, weight: 6), .treeEdge(7, merging: 5, into: 0),
            .examineEdge(0, weight: 7), .treeEdge(0, merging: 1, into: 0),
            .examineEdge(4, weight: 7), .treeEdge(4, merging: 2, into: 0),
            .examineEdge(2, weight: 8), .nonTreeEdge(2, root: 0),
            .examineEdge(8, weight: 8), .nonTreeEdge(8, root: 0),
            .examineEdge(3, weight: 9), .nonTreeEdge(3, root: 0),
            .examineEdge(9, weight: 9), .treeEdge(9, merging: 6, into: 0),
        ]
        let edges = wiki.map { UndirectedEdge($0.0, $0.1) }
        let list = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: edges)
        #expect(Array(list.kruskalEvents { wiki[$0].2 }) == expected)
        #expect(Array(ReferencePseudograph(vertices: 0 ..< 7, edges: edges).kruskalEvents { wiki[$0].2 }) == expected)
        #expect(Array(PlainGraph(vertices: Array(0 ..< 7), edges: edges).kruskalEvents { wiki[$0].2 }) == expected)
        #expect(Array(VertexIndexedGraph(vertices: Array(0 ..< 7), edges: edges).kruskalEvents { wiki[$0].2 }) == expected)
        // String vertices without indices: roots are named by their vertices.
        let names = ["a", "b", "c", "d", "e", "f", "g"]
        let named = PlainGraph(vertices: names, edges: wiki.map { UndirectedEdge(names[$0.0], names[$0.1]) })
        let renamed: [KruskalEvent<String, Int, Int>] = expected.map { event in
            switch event {
            case .examineEdge(let e, let w): .examineEdge(e, weight: w)
            case .treeEdge(let e, let a, let b): .treeEdge(e, merging: names[a], into: names[b])
            case .nonTreeEdge(let e, let r): .nonTreeEdge(e, root: names[r])
            }
        }
        #expect(Array(named.kruskalEvents { wiki[$0].2 }) == renamed)
        let treeEdges = expected.compactMap { event -> Int? in if case .treeEdge(let e, _, _) = event { e } else { nil } }
        #expect(treeEdges == list.kruskalMinimumSpanningTree { wiki[$0].2 }.edges)
        #expect(expected.map(\.description).prefix(4) == ["examineEdge(1, 5)", "treeEdge(1, 3 → 0)", "examineEdge(5, 5)", "treeEdge(5, 4 → 2)"])
        #expect(expected[11].description == "nonTreeEdge(2, 0)")
    }

    @Test("ST-251 Kruskal on a multigraph: a self-loop never examined, parallel copies told apart, two components", .tags(.fixture, .selfLoops))
    func kruskalMultigraph() {
        let raw: [(Int, Int, Int)] = [(0, 0, 1), (0, 1, 4), (1, 0, 2), (0, 1, 2), (1, 2, 3), (2, 3, 1), (3, 1, 3), (5, 6, 7)]
        let expected: [KruskalEvent<Int, Int, Int>] = [
            .examineEdge(5, weight: 1), .treeEdge(5, merging: 3, into: 2),
            .examineEdge(2, weight: 2), .treeEdge(2, merging: 1, into: 0),
            .examineEdge(3, weight: 2), .nonTreeEdge(3, root: 0),
            .examineEdge(4, weight: 3), .treeEdge(4, merging: 2, into: 0),
            .examineEdge(6, weight: 3), .nonTreeEdge(6, root: 0),
            .examineEdge(1, weight: 4), .nonTreeEdge(1, root: 0),
            .examineEdge(7, weight: 7), .treeEdge(7, merging: 6, into: 5),
        ]
        let edges = raw.map { UndirectedEdge($0.0, $0.1) }
        var weighed: [Int] = []
        let events = Array(ReferencePseudograph(vertices: 0 ..< 7, edges: edges).kruskalEvents { weighed.append($0); return raw[$0].2 })
        #expect(events == expected)
        #expect(weighed.sorted() == [1, 2, 3, 4, 5, 6, 7], "the self-loop is never weighed")
        #expect(Array(PlainGraph(vertices: Array(0 ..< 7), edges: edges).kruskalEvents { raw[$0].2 }) == expected)
    }

    @Test("ST-252 Kruskal, trivial: no vertices, one vertex with a loop, a tree whose last edge ends the run")
    func kruskalTrivial() {
        let empty = UndirectedAdjacencyList<Int>(vertices: [])
        #expect(Array(empty.kruskalEvents { _ in 1 }).isEmpty)
        let loop = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        #expect(Array(loop.kruskalEvents { _ in 1 }).isEmpty)
        let isolated = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [])
        #expect(Array(isolated.kruskalEvents { _ in 1 }).isEmpty)
        // A path 0–1 (weight 1) plus a heavier 1–0 copy: after n − 1 = 1 tree edge nothing more is examined.
        let pair = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)])
        #expect(Array(pair.kruskalEvents { [1, 5][$0] }) == [.examineEdge(0, weight: 1), .treeEdge(0, merging: 1, into: 0)])
        // Equal weights: position order; the tie in set sizes keeps the smaller root.
        let triangle = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(0, 2)])
        #expect(Array(triangle.kruskalEvents { _ in 0.5 }) == [
            .examineEdge(0, weight: 0.5), .treeEdge(0, merging: 2, into: 1),
            .examineEdge(1, weight: 0.5), .treeEdge(1, merging: 0, into: 1),
        ])
    }

    @Test("ST-253 Kruskal, value semantics: a later insertion changes nothing; each iterator starts over; stopping early")
    func kruskalValueSemantics() {
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weights = [2, 1, 0]
        let events = graph.kruskalEvents { weights[$0] }
        _ = graph.insert(edge: UndirectedEdge(0, 2))
        let first = Array(events)
        #expect(first == [.examineEdge(1, weight: 1), .treeEdge(1, merging: 2, into: 1), .examineEdge(0, weight: 2), .treeEdge(0, merging: 0, into: 1)])
        #expect(Array(events) == first)
        var iterator = events.makeIterator()
        #expect(iterator.next() == .examineEdge(1, weight: 1))
        #expect(Array(events.prefix(1)) == [.examineEdge(1, weight: 1)])
    }

    @Test("ST-254 Kruskal: a NaN weight traps")
    func kruskalPreconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.kruskalEvents { _ in Double.nan }
        }
    }

    @Test("ST-255 property: the tree edges replay kruskalMinimumSpanningTree, in sorted order, with the components' roots", .tags(.randomized))
    func kruskalProperty() async {
        // Up to 30 edges on vertices 0..<8 with weights -3...6; repeats and self-loops allowed.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: -3 ... 6)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges) { raw in
            let graph = ReferencePseudograph(vertices: 0 ..< 8, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let events = Array(graph.kruskalEvents { raw[$0].2 })
            let forest = graph.kruskalMinimumSpanningTree { raw[$0].2 }
            // The components of the edges taken so far, by a union–find with no ranks.
            var parent = Array(0 ..< 8)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            var tree: [Int] = []
            var total = 0
            var examined: [(Int, Int)] = []
            var last = -1
            for event in events {
                switch event {
                case .examineEdge(let e, let w):
                    #expect(last == -1 && w == raw[e].2 && raw[e].0 != raw[e].1)
                    examined.append((w, e))
                    last = e
                case .treeEdge(let e, let merging, let into):
                    #expect(e == last)
                    let (a, b) = (find(raw[e].0), find(raw[e].1))
                    #expect(a != b)
                    #expect(Set([find(merging), find(into)]) == Set([a, b]))
                    parent[a] = b
                    tree.append(e)
                    total += raw[e].2
                    last = -1
                case .nonTreeEdge(let e, let root):
                    #expect(e == last)
                    #expect(find(raw[e].0) == find(raw[e].1) && find(root) == find(raw[e].0))
                    last = -1
                }
            }
            #expect(last == -1)
            #expect(tree == forest.edges && total == forest.weight)
            #expect(examined.map(\.0) == examined.map(\.0).sorted())
            for k in examined.indices.dropFirst() where examined[k - 1].0 == examined[k].0 {
                #expect(examined[k - 1].1 < examined[k].1)
            }
        }
    }

    @Test("ST-260 Prim on Wikipedia's graph: every event in order, on every representation", .tags(.fixture))
    func primWiki() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        // Tests/Catalogs/SpanningTrees/cases_events.out, ST-260.
        let expected: [PrimEvent<Int, Int, Int>] = [
            .startVertex(0), .examine(0, edge: nil, weight: 0),
            .examineEdge(0, weight: 7), .edgeRelaxed(0, weight: 7), .examineEdge(1, weight: 5), .edgeRelaxed(1, weight: 5), .finish(0),
            .examine(3, edge: 1, weight: 5),
            .examineEdge(3, weight: 9), .edgeNotRelaxed(3, weight: 7), .examineEdge(6, weight: 15), .edgeRelaxed(6, weight: 15),
            .examineEdge(7, weight: 6), .edgeRelaxed(7, weight: 6), .finish(3),
            .examine(5, edge: 7, weight: 6),
            .examineEdge(8, weight: 8), .edgeRelaxed(8, weight: 8), .examineEdge(10, weight: 11), .edgeRelaxed(10, weight: 11), .finish(5),
            .examine(1, edge: 0, weight: 7),
            .examineEdge(2, weight: 8), .edgeRelaxed(2, weight: 8), .examineEdge(4, weight: 7), .edgeRelaxed(4, weight: 7), .finish(1),
            .examine(4, edge: 4, weight: 7),
            .examineEdge(5, weight: 5), .edgeRelaxed(5, weight: 5), .examineEdge(9, weight: 9), .edgeRelaxed(9, weight: 9), .finish(4),
            .examine(2, edge: 5, weight: 5), .finish(2),
            .examine(6, edge: 9, weight: 9), .finish(6),
        ]
        let edges = wiki.map { UndirectedEdge($0.0, $0.1) }
        let list = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: edges)
        #expect(Array(list.primEvents { wiki[$0].2 }) == expected)
        #expect(Array(ReferencePseudograph(vertices: 0 ..< 7, edges: edges).primEvents { wiki[$0].2 }) == expected)
        #expect(Array(PlainGraph(vertices: Array(0 ..< 7), edges: edges).primEvents { wiki[$0].2 }) == expected)
        #expect(Array(VertexIndexedGraph(vertices: Array(0 ..< 7), edges: edges).primEvents { wiki[$0].2 }) == expected)
        #expect(Array(list.primEvents(from: 0) { wiki[$0].2 }) == expected)
        let joined = expected.compactMap { event -> Int? in if case .examine(_, let e?, _) = event { e } else { nil } }
        #expect(joined == list.primMinimumSpanningTree { wiki[$0].2 }.edges)
        #expect(expected.prefix(3).map(\.description) == ["startVertex(0)", "examine(0)", "examineEdge(0, 7)"])
        #expect(expected[7].description == "examine(3, 1, 5)")
        #expect(expected[9].description == "edgeNotRelaxed(3, 7)")
        #expect(expected[3].description == "edgeRelaxed(0, 7)")
        #expect(expected[6].description == "finish(0)")
    }

    @Test("ST-261 Prim on a multigraph: loops skipped unweighed, parallel copies told apart, a start per component", .tags(.fixture, .selfLoops))
    func primMultigraph() {
        let raw: [(Int, Int, Int)] = [(0, 0, 1), (0, 1, 4), (1, 0, 2), (0, 1, 2), (1, 2, 3), (2, 3, 1), (3, 1, 3), (5, 6, 7)]
        let expected: [PrimEvent<Int, Int, Int>] = [
            .startVertex(0), .examine(0, edge: nil, weight: 0),
            .examineEdge(1, weight: 4), .edgeRelaxed(1, weight: 4), .examineEdge(2, weight: 2), .edgeRelaxed(2, weight: 2),
            .examineEdge(3, weight: 2), .edgeNotRelaxed(3, weight: 2), .finish(0),
            .examine(1, edge: 2, weight: 2),
            .examineEdge(4, weight: 3), .edgeRelaxed(4, weight: 3), .examineEdge(6, weight: 3), .edgeRelaxed(6, weight: 3), .finish(1),
            .examine(2, edge: 4, weight: 3), .examineEdge(5, weight: 1), .edgeRelaxed(5, weight: 1), .finish(2),
            .examine(3, edge: 5, weight: 1), .finish(3),
            .startVertex(4), .examine(4, edge: nil, weight: 0), .finish(4),
            .startVertex(5), .examine(5, edge: nil, weight: 0), .examineEdge(7, weight: 7), .edgeRelaxed(7, weight: 7), .finish(5),
            .examine(6, edge: 7, weight: 7), .finish(6),
        ]
        let edges = raw.map { UndirectedEdge($0.0, $0.1) }
        var weighed: [Int] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: edges)
        #expect(Array(graph.primEvents { weighed.append($0); return raw[$0].2 }) == expected)
        #expect(weighed.sorted() == [1, 2, 3, 4, 5, 6, 7], "the self-loop is never weighed")
        #expect(Array(PlainGraph(vertices: Array(0 ..< 7), edges: edges).primEvents { raw[$0].2 }) == expected)
        // From 5: that component only.
        #expect(Array(graph.primEvents(from: 5) { raw[$0].2 }) == Array(expected.suffix(7)))
        #expect(Array(PlainGraph(vertices: Array(0 ..< 7), edges: edges).primEvents(from: 4) { raw[$0].2 }) == [.startVertex(4), .examine(4, edge: nil, weight: 0), .finish(4)])
    }

    @Test("ST-262 Prim, trivial and value semantics: no vertices; a later insertion changes nothing; each iterator starts over; stopping early")
    func primTrivial() {
        #expect(Array(UndirectedAdjacencyList<Int>(vertices: []).primEvents { _ in 1 }).isEmpty)
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let events = graph.primEvents { _ in 3.5 }
        _ = graph.insert(edge: UndirectedEdge(1, 1))
        let first = Array(events)
        #expect(first == [
            .startVertex(0), .examine(0, edge: nil, weight: 0), .examineEdge(0, weight: 3.5), .edgeRelaxed(0, weight: 3.5), .finish(0),
            .examine(1, edge: 0, weight: 3.5), .finish(1),
        ])
        #expect(Array(events) == first)
        #expect(Array(events.prefix(2)) == Array(first.prefix(2)))
    }

    @Test("ST-263 Prim: a NaN examined weight and a missing root trap")
    func primPreconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            for _ in graph.primEvents(weight: { _ in Double.nan }) {}
        }
        // The edge traps as it is examined, before it reaches the queue.
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            var events = graph.primEvents(weight: { _ in Double.nan }).makeIterator()
            for _ in 0 ..< 3 { _ = events.next() }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.primEvents(from: 7) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = PlainGraph(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.primEvents(from: 7) { _ in 1 }
        }
    }

    @Test("ST-264 property: the examined vertices' edges replay primMinimumSpanningTree, from every vertex and from one root", .tags(.randomized))
    func primProperty() async {
        // Up to 30 edges on vertices 0..<8 with weights -3...6; repeats and self-loops allowed.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: -3 ... 6)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 7)) { raw, root in
            let edgeList = raw.map { UndirectedEdge($0.0, $0.1) }
            func check<G: Graph<Int>>(_ graph: G, _ name: String) where G.Edges.Index == Int {
                for from in [nil, root] {
                    let events = from.map { Array(graph.primEvents(from: $0) { raw[$0].2 }) } ?? Array(graph.primEvents { raw[$0].2 })
                    let forest = from.map { graph.primMinimumSpanningTree(from: $0) { raw[$0].2 } } ?? graph.primMinimumSpanningTree { raw[$0].2 }
                    var spanned = Set<Int>()
                    var key: [Int: (edge: Int, weight: Int)] = [:]
                    var joined: [Int] = []
                    var total = 0
                    var current = -1
                    var pending = -1
                    for event in events {
                        switch event {
                        case .startVertex(let v):
                            #expect(current == -1 && !spanned.contains(v) && key[v] == nil, "\(name)")
                        case .examine(let v, let e, let w):
                            #expect(spanned.insert(v).inserted, "\(name)")
                            #expect(e == key[v]?.edge && w == key[v]?.weight ?? 0, "\(name)")
                            if let e { joined.append(e); total += w }
                            current = v
                        case .examineEdge(let e, let w):
                            #expect(pending == -1 && w == raw[e].2, "\(name)")
                            #expect(raw[e].0 == current || raw[e].1 == current, "\(name)")
                            #expect(!spanned.contains(raw[e].0 == current ? raw[e].1 : raw[e].0), "\(name)")
                            pending = e
                        case .edgeRelaxed(let e, let w):
                            let far = raw[e].0 == current ? raw[e].1 : raw[e].0
                            #expect(e == pending && w == raw[e].2 && (key[far].map { w < $0.weight } ?? true), "\(name)")
                            key[far] = (e, w)
                            pending = -1
                        case .edgeNotRelaxed(let e, let w):
                            let far = raw[e].0 == current ? raw[e].1 : raw[e].0
                            #expect(e == pending && w == key[far]?.weight && raw[e].2 >= w, "\(name)")
                            pending = -1
                        case .finish(let v):
                            #expect(v == current && pending == -1, "\(name)")
                            current = -1
                        }
                    }
                    #expect(joined == forest.edges && total == forest.weight, "\(name)")
                    #expect(spanned.count == (from == nil ? 8 : forest.edges.count + 1), "\(name)")
                }
            }
            check(ReferencePseudograph(vertices: 0 ..< 8, edges: edgeList), "pseudograph")
            check(PlainGraph(vertices: Array(0 ..< 8), edges: edgeList), "unindexed")
        }
    }
}
