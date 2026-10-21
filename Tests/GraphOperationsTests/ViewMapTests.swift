// The views as graph adaptors: each one's generation is its base's, and each reads its base's
// attached maps. Transposed and subgraph views read edge maps at the base's positions; a complement
// reads vertex maps only. A subgraph view's `[map, of:]` and `[map, ofEdgeAt:]` trap for a vertex or
// an edge the view drops, and the `checked:` forms throw. Directed bases are `StableDirectedGraph`
// (which has a dead edge position after a removal); the undirected base is a dense graph with maps,
// local to this file. A property check compares a subgraph view's reads with a dictionary model
// under random insertions and removals. See README.md.

import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import PropertyBased
import StableGraphs
import Testing

/// An undirected graph on 0..<n whose edges are an array, with dense attached maps that follow
/// appended edges and vertices.
private struct DenseGraph: Graph, PropertyGraph {
    typealias Vertex = Int
    typealias EdgePosition = Int

    var vertexTotal: Int
    var links: ContiguousArray<UndirectedEdge<Int>> = []
    var vertexMaps = _AttachedMaps()
    var edgeMaps = _AttachedMaps()
    var stamp = _GenerationStamp()

    init(vertexCount: Int) { vertexTotal = vertexCount }

    var vertices: Range<Int> { 0 ..< vertexTotal }
    var edges: [UndirectedEdge<Int>] { Array(links) }
    var edgeIndexBound: Int? { links.count }
    func edgeIndex(of position: Int) -> Int { position }
    var vertexIndexBound: Int? { vertexTotal }
    func vertexIndex(of vertex: Int) -> Int {
        precondition(contains(vertex))
        return vertex
    }
    func vertex(atIndex index: Int) -> Int { index }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertexTotal }

    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { links[$0].oppositeVertex(to: vertex) } }

    func incidentEdges(of vertex: Int) -> [Int] {
        links.indices.flatMap { p in [links[p].u, links[p].v].filter { $0 == vertex }.map { _ in p } }
    }

    func degree(of vertex: Int) -> Int {
        links.reduce(0) { $0 + ($1.u == vertex ? 1 : 0) + ($1.v == vertex ? 1 : 0) }
    }

    var generation: GraphGeneration { stamp.generation }

    mutating func insert(edge: UndirectedEdge<Int>) -> Int {
        links.append(edge)
        if !edgeMaps.isEmpty { edgeMaps.appendDefaults(count: 1) }
        stamp.advance(writing: links)
        return links.count - 1
    }

    static var _vertexMapLayout: _MapLayout { .dense }
    static var _edgeMapLayout: _MapLayout { .dense }

    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = vertexMaps.add(default: value, layout: .dense, count: vertexTotal)
        return VertexMap(_token: token, hint: hint)
    }

    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = edgeMaps.add(default: value, layout: .dense, count: links.count)
        return EdgeMap(_token: token, hint: hint)
    }

    mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> {
        let (token, hint) = vertexMaps.add(values._storage, layout: .dense, count: vertexTotal)
        return VertexMap(_token: token, hint: hint)
    }

    mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> {
        let (token, hint) = edgeMaps.add(values._storage, layout: .dense, count: links.count)
        return EdgeMap(_token: token, hint: hint)
    }

    var _vertexMapCount: Int { vertexTotal }
    var _edgeMapCount: Int { links.count }

    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { vertexMaps.remove(map._token, hint: map._hint) }
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { edgeMaps.remove(map._token, hint: map._hint) }

    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            precondition(contains(position))
            return vertexMaps.value(Value.self, at: position, in: vertexMaps.index(of: map._token, hint: map._hint), layout: .dense)
        }
        set {
            precondition(contains(position))
            vertexMaps.setValue(newValue, at: position, in: vertexMaps.index(of: map._token, hint: map._hint), layout: .dense)
        }
    }

    subscript<Value>(map: VertexMap<Value>, of vertex: Int) -> Value {
        get { self[map, ofVertexAt: vertex] }
        set { self[map, ofVertexAt: vertex] = newValue }
    }

    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            precondition(links.indices.contains(position))
            return edgeMaps.value(Value.self, at: position, in: edgeMaps.index(of: map._token, hint: map._hint), layout: .dense)
        }
        set {
            precondition(links.indices.contains(position))
            edgeMaps.setValue(newValue, at: position, in: edgeMaps.index(of: map._token, hint: map._hint), layout: .dense)
        }
    }

    subscript<Value>(map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            guard contains(position) else { throw VertexNotFound() }
            return self[map, ofVertexAt: position]
        }
    }

    subscript<Value>(map: VertexMap<Value>, checked vertex: Int) -> Value {
        get throws(VertexNotFound) { try self[map, checkedVertexAt: vertex] }
    }

    subscript<Value>(map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            guard links.indices.contains(position) else { throw EdgeNotFound() }
            return self[map, ofEdgeAt: position]
        }
    }

    func values<Value>(of map: VertexMap<Value>) -> VertexValues<DenseGraph, Value> {
        VertexValues(_storage: vertexMaps.storage(Value.self, in: vertexMaps.index(of: map._token, hint: map._hint)))
    }

    func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<DenseGraph, Value> {
        EdgeValues(_storage: edgeMaps.storage(Value.self, in: edgeMaps.index(of: map._token, hint: map._hint)))
    }
}

@Suite("GraphOperations views as adaptors: attached maps and generations")
struct ViewMapTests {
    @Test("A transposed view reads the base's edge and vertex maps at the base's positions; its generation is the base's")
    func transposedViewMaps() throws {
        var graph = StableDirectedGraph<String>(
            vertices: ["a", "b", "c"],
            edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        _ = graph.remove(edgeAt: 2)
        let weights = graph.addEdgeMap(default: 0.0)
        let ranks = graph.addVertexMap(default: 0)
        graph[weights, ofEdgeAt: 0] = 1.5
        graph[weights, ofEdgeAt: 1] = 2.5
        graph[ranks, of: "c"] = 7
        let view = graph.transposedView
        #expect(view.edges.indices.map { view[weights, ofEdgeAt: $0] } == [1.5, 2.5])
        #expect(view.edges.map { [$0.source, $0.target] } == [["b", "a"], ["c", "b"]])
        let w = view.values(of: weights)
        #expect(view.edges.indices.map { w[$0] } == [1.5, 2.5])
        #expect(try view[weights, checkedEdgeAt: 1] == 2.5)
        #expect(throws: EdgeNotFound.self) { try view[weights, checkedEdgeAt: 2] }
        #expect(throws: EdgeNotFound.self) { try view[weights, checkedEdgeAt: 9] }
        #expect(view[ranks, of: "c"] == 7 && view[ranks, of: "a"] == 0 && view.values(of: ranks)[graph.vertexPosition(of: "c")] == 7)
        #expect(try view[ranks, checked: "c"] == 7)
        #expect(throws: VertexNotFound.self) { try view[ranks, checked: "z"] }
        // The generation is the base's: a map write keeps it, a structural mutation of the base ends it.
        #expect(graph.generation.isCurrent(for: view) && view.generation.isCurrent(for: graph))
        let stamp = view.generation
        graph[weights, ofEdgeAt: 0] = 9
        #expect(stamp.isCurrent(for: graph) && view[weights, ofEdgeAt: 0] == 1.5 && w[0] == 1.5)
        _ = graph.insert(edge: DirectedEdge(from: "a", to: "c"))
        #expect(!stamp.isCurrent(for: graph) && stamp.isCurrent(for: view))
    }

    @Test("A directed subgraph view reads the base's maps for its own vertices and edges, and throws outside them")
    func directedSubgraphMaps() throws {
        // Positions: 0 a→b, 1 b→c, 2 c→d, 3 a→c, 4 d→a (removed, a dead position).
        var graph = StableDirectedGraph<String>(
            vertices: ["a", "b", "c", "d"],
            edges: [
                DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "d"),
                DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "d", to: "a"),
            ])
        _ = graph.remove(edgeAt: 4)
        let weights = graph.addEdgeMap(default: 0.0)
        let ranks = graph.addVertexMap(default: 0)
        for (p, w) in [1.5, 2.5, 3.5, 4.5].enumerated() { graph[weights, ofEdgeAt: p] = w }
        for (k, v) in ["a", "b", "c", "d"].enumerated() { graph[ranks, of: v] = k + 1 }

        // (view, kept vertices, kept positions)
        let cases: [(SubgraphView<StableDirectedGraph<String>>, [String], [Int])] = [
            (graph.inducedSubgraphView(on: ["c", "a", "b"]), ["a", "b", "c"], [0, 1, 3]),
            (graph.inducedSubgraphView(on: ["a", "b", "c", "d"]), ["a", "b", "c", "d"], [0, 1, 2, 3]),
            (graph.spanningSubgraphView(edges: [3, 0]), ["a", "b", "c", "d"], [0, 3]),
            (graph.subgraphView(vertices: ["a", "b", "d"], edges: [0, 1, 2]), ["a", "b", "d"], [0]),
        ]
        let expectedWeights = [1.5, 2.5, 3.5, 4.5]
        for (view, kept, positions) in cases {
            let context = "\(kept) \(positions)"
            #expect(Array(view.edges.indices) == positions, "\(context)")
            #expect(positions.map { view[weights, ofEdgeAt: $0] } == positions.map { expectedWeights[$0] }, "\(context)")
            #expect(try positions.map { try view[weights, checkedEdgeAt: $0] } == positions.map { expectedWeights[$0] }, "\(context)")
            for p in [-1, 0, 1, 2, 3, 4, 5, 9] where !positions.contains(p) {
                #expect(throws: EdgeNotFound.self, "\(context) \(p)") { try view[weights, checkedEdgeAt: p] }
            }
            let w = view.values(of: weights)
            #expect(view.edges.indices.map { w[$0] } == positions.map { expectedWeights[$0] }, "\(context)")
            for (k, v) in ["a", "b", "c", "d"].enumerated() {
                if kept.contains(v) {
                    #expect(try view[ranks, of: v] == k + 1 && view[ranks, checked: v] == k + 1, "\(context) \(v)")
                } else {
                    #expect(throws: VertexNotFound.self, "\(context) \(v)") { try view[ranks, checked: v] }
                }
                // values(of:) is the base's, by the base's positions, kept or not.
                #expect(view.values(of: ranks)[graph.vertexPosition(of: v)] == k + 1, "\(context) \(v)")
            }
            #expect(throws: VertexNotFound.self, "\(context)") { try view[ranks, checked: "z"] }
            #expect(graph.generation.isCurrent(for: view), "\(context)")
        }

        let view = graph.inducedSubgraphView(on: ["a", "b"])
        let stamp = view.generation
        graph[ranks, of: "a"] = 10
        #expect(stamp.isCurrent(for: graph) && view[ranks, of: "a"] == 1)
        _ = graph.remove(edgeAt: 0)
        #expect(!stamp.isCurrent(for: graph) && stamp.isCurrent(for: view))
        // A view of a view keeps the innermost base's generation.
        let nested = graph.transposedView.inducedSubgraphView(on: ["b", "c"])
        #expect(graph.generation.isCurrent(for: nested))
    }

    @Test("A directed subgraph view traps on a dropped vertex, a dropped edge and a dead position")
    func directedSubgraphTraps() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
            let ranks = graph.addVertexMap(default: 0)
            _ = graph.inducedSubgraphView(on: ["a", "b"])[ranks, of: "c"]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<String>(
                vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
            let weights = graph.addEdgeMap(default: 0.0)
            _ = graph.inducedSubgraphView(on: ["a", "b"])[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<String>(
                vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
            let weights = graph.addEdgeMap(default: 0.0)
            _ = graph.spanningSubgraphView(edges: [0])[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<String>(
                vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
            let weights = graph.addEdgeMap(default: 0.0)
            _ = graph.remove(edgeAt: 1)
            _ = graph.inducedSubgraphView(on: ["a", "b", "c"])[weights, ofEdgeAt: 1]
        }
        // The same setups without the fault read the base's values.
        var graph = StableDirectedGraph<String>(
            vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let ranks = graph.addVertexMap(default: 4)
        let weights = graph.addEdgeMap(default: 2.0)
        #expect(graph.inducedSubgraphView(on: ["a", "b"])[ranks, of: "b"] == 4)
        #expect(graph.inducedSubgraphView(on: ["a", "b"])[weights, ofEdgeAt: 0] == 2)
        #expect(graph.spanningSubgraphView(edges: [0])[weights, ofEdgeAt: 0] == 2)
        #expect(graph.inducedSubgraphView(on: ["a", "b", "c"])[weights, ofEdgeAt: 1] == 2)
    }

    @Test("An undirected subgraph view reads the base's maps for its own vertices and edges, and throws outside them")
    func undirectedSubgraphMaps() throws {
        var graph = DenseGraph(vertexCount: 4)
        // Positions: 0 {0,1}, 1 {1,2}, 2 {2,3}, 3 {3,3}, 4 {0,2}.
        for (u, v) in [(0, 1), (1, 2), (2, 3), (3, 3), (0, 2)] { _ = graph.insert(edge: UndirectedEdge(u, v)) }
        let weights = graph.addEdgeMap(default: 0)
        let ranks = graph.addVertexMap(default: "")
        for p in 0 ..< 5 { graph[weights, ofEdgeAt: p] = 10 * (p + 1) }
        for v in 0 ..< 4 { graph[ranks, of: v] = "r\(v)" }

        let cases: [(SubgraphView<DenseGraph>, [Int], [Int])] = [
            (graph.inducedSubgraphView(on: [2, 0, 1]), [0, 1, 2], [0, 1, 4]),
            (graph.inducedSubgraphView(on: [0, 1, 2, 3]), [0, 1, 2, 3], [0, 1, 2, 3, 4]),
            (graph.spanningSubgraphView(edges: [3, 1]), [0, 1, 2, 3], [1, 3]),
            (graph.subgraphView(vertices: [2, 3], edges: [1, 2, 3]), [2, 3], [2, 3]),
        ]
        for (view, kept, positions) in cases {
            let context = "\(kept) \(positions)"
            #expect(Array(view.edges.indices) == positions, "\(context)")
            #expect(positions.map { view[weights, ofEdgeAt: $0] } == positions.map { 10 * ($0 + 1) }, "\(context)")
            #expect(try positions.map { try view[weights, checkedEdgeAt: $0] } == positions.map { 10 * ($0 + 1) }, "\(context)")
            for p in -1 ... 6 where !positions.contains(p) {
                #expect(throws: EdgeNotFound.self, "\(context) \(p)") { try view[weights, checkedEdgeAt: p] }
            }
            let w = view.values(of: weights)
            #expect(view.edges.indices.map { w[$0] } == positions.map { 10 * ($0 + 1) }, "\(context)")
            for v in -1 ... 4 {
                if kept.contains(v) {
                    #expect(try view[ranks, of: v] == "r\(v)" && view[ranks, checked: v] == "r\(v)", "\(context) \(v)")
                } else {
                    #expect(throws: VertexNotFound.self, "\(context) \(v)") { try view[ranks, checked: v] }
                }
            }
            #expect(view.values(of: ranks)[3] == "r3", "\(context)")
            #expect(graph.generation.isCurrent(for: view), "\(context)")
        }
        let view = graph.inducedSubgraphView(on: [0, 1])
        _ = graph.insert(edge: UndirectedEdge(0, 1))
        #expect(!graph.generation.isCurrent(for: view))
    }

    @Test("An undirected subgraph view traps on a dropped vertex and a dropped edge")
    func undirectedSubgraphTraps() async {
        await #expect(processExitsWith: .failure) {
            var graph = DenseGraph(vertexCount: 3)
            _ = graph.insert(edge: UndirectedEdge(0, 1))
            let ranks = graph.addVertexMap(default: 0)
            _ = graph.inducedSubgraphView(on: [0, 1])[ranks, of: 2]
        }
        await #expect(processExitsWith: .failure) {
            var graph = DenseGraph(vertexCount: 3)
            _ = graph.insert(edge: UndirectedEdge(0, 1))
            _ = graph.insert(edge: UndirectedEdge(1, 2))
            let weights = graph.addEdgeMap(default: 0)
            _ = graph.inducedSubgraphView(on: [0, 1])[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = DenseGraph(vertexCount: 3)
            _ = graph.insert(edge: UndirectedEdge(0, 1))
            _ = graph.insert(edge: UndirectedEdge(1, 2))
            let weights = graph.addEdgeMap(default: 0)
            _ = graph.spanningSubgraphView(edges: [1])[weights, ofEdgeAt: 0]
        }
        var graph = DenseGraph(vertexCount: 3)
        _ = graph.insert(edge: UndirectedEdge(0, 1))
        _ = graph.insert(edge: UndirectedEdge(1, 2))
        let ranks = graph.addVertexMap(default: 5)
        let weights = graph.addEdgeMap(default: 6)
        #expect(graph.inducedSubgraphView(on: [0, 1])[ranks, of: 1] == 5)
        #expect(graph.inducedSubgraphView(on: [0, 1])[weights, ofEdgeAt: 0] == 6)
        #expect(graph.spanningSubgraphView(edges: [1])[weights, ofEdgeAt: 1] == 6)
    }

    @Test("A complement view reads the base's vertex maps; its generation is the base's")
    func complementViewMaps() throws {
        var directed = StableDirectedGraph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b")])
        let ranks = directed.addVertexMap(default: 0)
        directed[ranks, of: "b"] = 3
        let complement = directed.complementView
        #expect(complement[ranks, of: "b"] == 3 && complement[ranks, of: "c"] == 0)
        #expect(try complement[ranks, checked: "b"] == 3)
        #expect(throws: VertexNotFound.self) { try complement[ranks, checked: "z"] }
        #expect(complement.values(of: ranks)[directed.vertexPosition(of: "b")] == 3)
        #expect(directed.generation.isCurrent(for: complement))
        _ = directed.insert(edge: DirectedEdge(from: "b", to: "c"))
        #expect(!directed.generation.isCurrent(for: complement))

        var undirected = DenseGraph(vertexCount: 3)
        _ = undirected.insert(edge: UndirectedEdge(0, 1))
        let labels = undirected.addVertexMap(default: "")
        undirected[labels, of: 2] = "c"
        let undirectedComplement = undirected.complementView
        #expect(undirectedComplement[labels, of: 2] == "c" && undirectedComplement.values(of: labels)[2] == "c")
        #expect(throws: VertexNotFound.self) { try undirectedComplement[labels, checked: 3] }
        #expect(undirected.generation.isCurrent(for: undirectedComplement))
        _ = undirected.insert(edge: UndirectedEdge(1, 2))
        #expect(!undirected.generation.isCurrent(for: undirectedComplement))
    }
}

@Suite("Subgraph view maps against a dictionary model", .tags(.randomized))
struct SubgraphViewMapPropertyTests {
    @Test("Under random insertions and edge removals, a subgraph view reads exactly the model's values of its kept elements")
    func subgraphMapsMatchModel() async {
        // Each step: (kind, a, b). Kind 0 inserts a→b, 1 removes the live edge at the a-th live position.
        let steps = zip(Gen.int(in: 0 ... 1), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 30)
        await propertyCheck(count: 200, input: steps, Gen.int(in: 0 ... 1).array(of: 6 ... 6), Gen.int(in: 0 ... 40).array(of: 0 ... 10)) { steps, keepBits, listed in
            let names = (0 ..< 6).map { "v\($0)" }
            var graph = StableDirectedGraph<String>(vertices: names)
            let weights = graph.addEdgeMap(default: -1)
            let ranks = graph.addVertexMap(default: -1)
            var edgeModel: [Int: Int] = [:]   // live position → weight
            var ends: [Int: (String, String)] = [:]
            for (k, v) in names.enumerated() { graph[ranks, of: v] = 100 + k }
            for (i, step) in steps.enumerated() {
                if step.0 == 0 {
                    let p = graph.insert(edge: DirectedEdge(from: names[step.1], to: names[step.2]))
                    graph[weights, ofEdgeAt: p] = i
                    edgeModel[p] = i
                    ends[p] = (names[step.1], names[step.2])
                } else if !edgeModel.isEmpty {
                    let live = edgeModel.keys.sorted()
                    let p = live[step.1 % live.count]
                    _ = graph.remove(edgeAt: p)
                    edgeModel[p] = nil
                    ends[p] = nil
                }
            }
            let keep = Set(names.indices.filter { keepBits[$0] == 1 }.map { names[$0] })
            let listedLive = Set(listed.filter { edgeModel[$0] != nil })
            let context = "steps \(steps), keep \(keep.sorted()), listed \(listedLive.sorted())"
            // (view, kept vertices, whether a position is kept)
            let views: [(SubgraphView<StableDirectedGraph<String>>, Set<String>, (Int) -> Bool)] = [
                (graph.inducedSubgraphView(on: keep), keep, { keep.contains(ends[$0]!.0) && keep.contains(ends[$0]!.1) }),
                (graph.spanningSubgraphView(edges: listedLive), Set(names), { listedLive.contains($0) }),
                (graph.subgraphView(vertices: keep, edges: listedLive), keep, { listedLive.contains($0) && keep.contains(ends[$0]!.0) && keep.contains(ends[$0]!.1) }),
            ]
            for (view, kept, keeps) in views {
                for p in -1 ... graph.edgePositionBound {
                    let expected: Int? = edgeModel[p].flatMap { keeps(p) ? $0 : nil }
                    #expect((try? view[weights, checkedEdgeAt: p]) == expected, "\(context) position \(p)")
                    if let expected { #expect(view[weights, ofEdgeAt: p] == expected, "\(context) position \(p)") }
                }
                #expect(Array(view.edges.indices) == edgeModel.keys.sorted().filter(keeps), "\(context)")
                for (k, v) in names.enumerated() {
                    let expected: Int? = kept.contains(v) ? 100 + k : nil
                    #expect((try? view[ranks, checked: v]) == expected, "\(context) \(v)")
                    if let expected { #expect(view[ranks, of: v] == expected, "\(context) \(v)") }
                }
                #expect(graph.generation.isCurrent(for: view), "\(context)")
            }
        }
    }
}
