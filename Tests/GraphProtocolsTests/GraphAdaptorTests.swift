// GraphAdaptor, GraphDelegator, PropertyGraph and GraphGeneration on test-local conformers: a
// dense swap-remove digraph with attached maps (the dense layout of the shared map storage), a
// generic and a concrete delegator over it that declare their conformances and write no read
// forwarding bodies (only the map writes, which change the base), and an adaptor that is not a delegator. They prove that the delegator's
// defaults are the witnesses (generic code calls the base's own member, logged), that a concrete
// delegator whose base keeps the protocols' conditional defaults compiles without ambiguity, that
// an adaptor does not forward, and that maps and generations pass through. The map storage's
// operations are then checked directly. See README.md.

import GraphProtocols
import Testing

/// The calls a fixture graph received, by name.
private final class CallLog {
    var calls: [String] = []
}

/// A digraph on 0..<n whose edges are an array; removing an edge moves the last one into its
/// position (a swap-remove), as `AdjacencyList` does, and its maps follow. Its index sequences
/// are the protocols' `LazyMapSequence` defaults and its rows are `Collection`s, so a delegator
/// over it meets every conditional default.
private struct DenseDigraph: BidirectionalDirectedGraph, PropertyGraph {
    typealias Vertex = Int
    typealias EdgePosition = Int

    var vertexTotal: Int
    var arcs: ContiguousArray<DirectedEdge<Int>> = []
    var vertexMaps = _AttachedMaps()
    var edgeMaps = _AttachedMaps()
    var stamp = _GenerationStamp()
    let log: CallLog

    init(vertexCount: Int, log: CallLog) {
        vertexTotal = vertexCount
        self.log = log
    }

    var vertices: Range<Int> { 0 ..< vertexTotal }
    var edges: [DirectedEdge<Int>] { Array(arcs) }
    var vertexIndexBound: Int? { vertexTotal }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertexTotal }

    func successors(of vertex: Int) -> [Int] {
        log.calls.append("successors")
        return arcs.filter { $0.source == vertex }.map(\.target)
    }

    func outEdges(of vertex: Int) -> [Int] {
        log.calls.append("outEdges")
        return arcs.indices.filter { arcs[$0].source == vertex }
    }

    func predecessors(of vertex: Int) -> [Int] {
        log.calls.append("predecessors")
        return arcs.filter { $0.target == vertex }.map(\.source)
    }

    func inEdges(of vertex: Int) -> [Int] {
        log.calls.append("inEdges")
        return arcs.indices.filter { arcs[$0].target == vertex }
    }

    func outDegree(of vertex: Int) -> Int {
        log.calls.append("outDegree")
        return arcs.lazy.filter { $0.source == vertex }.count
    }

    func inDegree(of vertex: Int) -> Int {
        log.calls.append("inDegree")
        return arcs.lazy.filter { $0.target == vertex }.count
    }

    var generation: GraphGeneration { stamp.generation }

    mutating func insertVertex() -> Int {
        vertexTotal += 1
        if !vertexMaps.isEmpty { vertexMaps.appendDefaults(count: 1) }
        // The arcs are unchanged, so they are made unique to tell a copy apart.
        stamp.advance(owning: &arcs)
        return vertexTotal - 1
    }

    mutating func insert(edge: DirectedEdge<Int>) -> Int {
        precondition(contains(edge.source) && contains(edge.target))
        arcs.append(edge)
        if !edgeMaps.isEmpty { edgeMaps.appendDefaults(count: 1) }
        stamp.advance(writing: arcs)
        return arcs.count - 1
    }

    mutating func remove(edgeAt position: Int) {
        let last = arcs.removeLast()
        if position < arcs.count { arcs[position] = last }
        if !edgeMaps.isEmpty { edgeMaps.swapRemove(at: position) }
        stamp.advance(writing: arcs)
    }

    mutating func reserveCapacity(edgeCount: Int) {
        arcs.reserveCapacity(edgeCount)
        stamp.storageMayHaveMoved(arcs)
        if !edgeMaps.isEmpty { edgeMaps.reserveCapacity(edgeCount) }
    }

    mutating func removeAllEdges() {
        arcs.removeAll()
        if !edgeMaps.isEmpty { edgeMaps.removeAll(keepingCapacity: false) }
        stamp.advance(writing: arcs)
    }

    static var _vertexMapLayout: _MapLayout { .dense }
    static var _edgeMapLayout: _MapLayout { .dense }

    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = vertexMaps.add(default: value, layout: .dense, count: vertexTotal)
        return VertexMap(_token: token, hint: hint)
    }

    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = edgeMaps.add(default: value, layout: .dense, count: arcs.count)
        return EdgeMap(_token: token, hint: hint)
    }

    mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> {
        let (token, hint) = vertexMaps.add(values._storage, layout: .dense, count: vertexTotal)
        return VertexMap(_token: token, hint: hint)
    }

    mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> {
        let (token, hint) = edgeMaps.add(values._storage, layout: .dense, count: arcs.count)
        return EdgeMap(_token: token, hint: hint)
    }

    var _vertexMapCount: Int { vertexTotal }
    var _edgeMapCount: Int { arcs.count }

    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { vertexMaps.remove(map._token, hint: map._hint) }
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { edgeMaps.remove(map._token, hint: map._hint) }

    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = vertexMaps.index(of: map._token, hint: map._hint)
            precondition(contains(position))
            return vertexMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = vertexMaps.index(of: map._token, hint: map._hint)
            precondition(contains(position))
            vertexMaps.setValue(newValue, at: position, in: k, layout: .dense)
        }
    }

    subscript<Value>(map: VertexMap<Value>, of vertex: Int) -> Value {
        get { self[map, ofVertexAt: vertex] }
        set { self[map, ofVertexAt: vertex] = newValue }
    }

    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = edgeMaps.index(of: map._token, hint: map._hint)
            precondition(arcs.indices.contains(position))
            return edgeMaps.value(Value.self, at: position, in: k, layout: .dense)
        }
        set {
            let k = edgeMaps.index(of: map._token, hint: map._hint)
            precondition(arcs.indices.contains(position))
            edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)
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
            guard arcs.indices.contains(position) else { throw EdgeNotFound() }
            return self[map, ofEdgeAt: position]
        }
    }

    func values<Value>(of map: VertexMap<Value>) -> VertexValues<DenseDigraph, Value> {
        VertexValues(_storage: vertexMaps.storage(Value.self, in: vertexMaps.index(of: map._token, hint: map._hint)))
    }

    func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<DenseDigraph, Value> {
        EdgeValues(_storage: edgeMaps.storage(Value.self, in: edgeMaps.index(of: map._token, hint: map._hint)))
    }
}

/// A rule-adding wrapper over any such graph, generic: no self-loops. Every read, including the
/// map reads, comes from `GraphDelegator`'s defaults; the map writes are its own.
private struct LooplessGraph<Base: BidirectionalDirectedGraph & PropertyGraph>: GraphDelegator, BidirectionalDirectedGraph, PropertyGraph {
    typealias Vertex = Base.Vertex
    typealias Vertices = Base.Vertices
    typealias Edges = Base.Edges
    typealias Successors = Base.Successors
    typealias OutEdges = Base.OutEdges
    typealias SuccessorIndices = Base.SuccessorIndices
    typealias Predecessors = Base.Predecessors
    typealias InEdges = Base.InEdges
    typealias PredecessorIndices = Base.PredecessorIndices
    typealias EdgePosition = Base.EdgePosition

    var _base: Base

    var base: Base { _base }

    // Attaching, detaching and writing maps change the base, so they are the wrapper's own.
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> { _base.addVertexMap(default: value) }
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> { _base.addEdgeMap(default: value) }
    mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> { _base.addVertexMap(values: VertexValues(values)) }
    mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> { _base.addEdgeMap(values: EdgeValues(values)) }
    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { _base.removeVertexMap(map) }
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { _base.removeEdgeMap(map) }
    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }
    subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }
    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }
}

/// The same rule over the concrete fixture: its associated types are the conditional defaults'
/// (`LazyMapSequence`, `Collection` rows), where an ambiguity between two defaults would not
/// compile.
private struct LooplessDenseDigraph: GraphDelegator, BidirectionalDirectedGraph, PropertyGraph {
    typealias Base = DenseDigraph
    typealias Vertex = Int
    typealias Vertices = Range<Int>
    typealias Edges = [DirectedEdge<Int>]
    typealias Successors = [Int]
    typealias OutEdges = [Int]
    typealias SuccessorIndices = DenseDigraph.SuccessorIndices
    typealias Predecessors = [Int]
    typealias InEdges = [Int]
    typealias PredecessorIndices = DenseDigraph.PredecessorIndices
    typealias EdgePosition = Int

    var _base: DenseDigraph

    var base: Base { _base }

    // Attaching, detaching and writing maps change the base, so they are the wrapper's own.
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> { _base.addVertexMap(default: value) }
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> { _base.addEdgeMap(default: value) }
    mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> { _base.addVertexMap(values: VertexValues(values)) }
    mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> { _base.addEdgeMap(values: EdgeValues(values)) }
    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { _base.removeVertexMap(map) }
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { _base.removeEdgeMap(map) }
    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }
    subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }
    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }

    mutating func insert(edge: DirectedEdge<Int>) -> Int? {
        edge.source == edge.target ? nil : _base.insert(edge: edge)
    }
}

/// An undirected graph on 0..<n whose edges are an array, with dense maps: the base of an
/// undirected delegator and of a directed view.
private struct DenseGraph: Graph, PropertyGraph {
    typealias Vertex = Int
    typealias EdgePosition = Int

    var vertexTotal: Int
    var links: ContiguousArray<UndirectedEdge<Int>> = []
    var vertexMaps = _AttachedMaps()
    var edgeMaps = _AttachedMaps()
    var stamp = _GenerationStamp()
    let log: CallLog

    init(vertexCount: Int, log: CallLog) {
        vertexTotal = vertexCount
        self.log = log
    }

    var vertices: Range<Int> { 0 ..< vertexTotal }
    var edges: [UndirectedEdge<Int>] { Array(links) }
    var edgeIndexBound: Int? { links.count }
    func edgeIndex(of position: Int) -> Int { position }
    var vertexIndexBound: Int? { vertexTotal }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertexTotal }

    func neighbors(of vertex: Int) -> [Int] {
        log.calls.append("neighbors")
        return incidentEdges(of: vertex).map { links[$0].oppositeVertex(to: vertex) }
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        log.calls.append("incidentEdges")
        return links.indices.flatMap { p in [links[p].u, links[p].v].filter { $0 == vertex }.map { _ in p } }
    }

    func degree(of vertex: Int) -> Int {
        log.calls.append("degree")
        return links.reduce(0) { $0 + ($1.u == vertex ? 1 : 0) + ($1.v == vertex ? 1 : 0) }
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

/// A rule-adding wrapper over any undirected such graph, generic: no self-loops.
private struct LooplessUndirectedGraph<Base: Graph & PropertyGraph>: GraphDelegator, Graph, PropertyGraph {
    typealias Vertex = Base.Vertex
    typealias Vertices = Base.Vertices
    typealias Edges = Base.Edges
    typealias Neighbors = Base.Neighbors
    typealias IncidentEdges = Base.IncidentEdges
    typealias NeighborIndices = Base.NeighborIndices
    typealias IncidentEdgeIndices = Base.IncidentEdgeIndices
    typealias EdgePosition = Base.EdgePosition

    var _base: Base

    var base: Base { _base }

    // Attaching, detaching and writing maps change the base, so they are the wrapper's own.
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> { _base.addVertexMap(default: value) }
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> { _base.addEdgeMap(default: value) }
    mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> { _base.addVertexMap(values: VertexValues(values)) }
    mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> { _base.addEdgeMap(values: EdgeValues(values)) }
    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { _base.removeVertexMap(map) }
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { _base.removeEdgeMap(map) }
    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }
    subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }
    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }
}

/// The same over the concrete fixture, where the conditional defaults all apply.
private struct LooplessDenseGraph: GraphDelegator, Graph, PropertyGraph {
    typealias Base = DenseGraph
    typealias Vertex = Int
    typealias Vertices = Range<Int>
    typealias Edges = [UndirectedEdge<Int>]
    typealias Neighbors = [Int]
    typealias IncidentEdges = [Int]
    typealias NeighborIndices = DenseGraph.NeighborIndices
    typealias IncidentEdgeIndices = DenseGraph.IncidentEdgeIndices
    typealias EdgePosition = Int

    var _base: DenseGraph

    var base: Base { _base }

    // Attaching, detaching and writing maps change the base, so they are the wrapper's own.
    mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> { _base.addVertexMap(default: value) }
    mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> { _base.addEdgeMap(default: value) }
    mutating func addVertexMap<Value: Sendable>(values: VertexValues<Self, Value>) -> VertexMap<Value> { _base.addVertexMap(values: VertexValues(values)) }
    mutating func addEdgeMap<Value: Sendable>(values: EdgeValues<Self, Value>) -> EdgeMap<Value> { _base.addEdgeMap(values: EdgeValues(values)) }
    mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { _base.removeVertexMap(map) }
    mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { _base.removeEdgeMap(map) }
    subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }
    subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }
    subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }
}

/// An adaptor that is not a delegator: the graph with every edge reversed. Over `DenseDigraph`,
/// its row types equal the base's, so forwarding the base's `outDegree` would compile and answer
/// for the wrong graph; as an adaptor it gets `DirectedGraph`'s default over its own rows.
private struct ReversedGraph: GraphAdaptor, DirectedGraph {
    let base: DenseDigraph

    var vertices: Range<Int> { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges.map { DirectedEdge(from: $0.target, to: $0.source) } }
    func successors(of vertex: Int) -> [Int] { base.predecessors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.inEdges(of: vertex) }
}

@Suite("GraphProtocols: GraphAdaptor, GraphDelegator and PropertyGraph", .tags(.conformance))
struct GraphAdaptorTests {
    @Test("A generic delegator's defaults are the witnesses: generic code calls the base's own members")
    func genericDelegatorForwards() {
        let log = CallLog()
        var base = DenseDigraph(vertexCount: 4, log: log)
        _ = base.insert(edge: DirectedEdge(from: 0, to: 1))
        _ = base.insert(edge: DirectedEdge(from: 0, to: 2))
        _ = base.insert(edge: DirectedEdge(from: 3, to: 0))
        let graph = LooplessGraph(_base: base)

        func outDegree<G: DirectedGraph>(_ g: G, _ v: G.Vertex) -> Int { g.outDegree(of: v) }
        func inDegree<G: BidirectionalDirectedGraph>(_ g: G, _ v: G.Vertex) -> Int { g.inDegree(of: v) }
        log.calls = []
        #expect(outDegree(graph, 0) == 2)
        #expect(log.calls == ["outDegree"])
        log.calls = []
        #expect(inDegree(graph, 0) == 1)
        #expect(log.calls == ["inDegree"])
        log.calls = []
        #expect(Array(graph.successors(of: 0)) == [1, 2] && Array(graph.predecessors(of: 0)) == [3])
        #expect(Array(graph.outEdges(of: 0)) == [0, 1] && Array(graph.inEdges(of: 0)) == [2])
        #expect(log.calls == ["successors", "predecessors", "outEdges", "inEdges"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.vertexIndexBound == 4)
        #expect(graph.contains(3) && !graph.contains(4) && graph.contains(edge: DirectedEdge(from: 3, to: 0)))
        #expect(graph.source(ofEdgeAt: 2) == 3 && graph.target(ofEdgeAt: 2) == 0)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1, 2] && Array(graph.predecessorIndices(ofIndex: 0)) == [3])
        #expect(graph.base.edges == base.edges)
    }

    @Test("A concrete delegator over a base with the conditional defaults compiles and forwards")
    func concreteDelegatorForwards() throws {
        let log = CallLog()
        var graph = LooplessDenseDigraph(_base: DenseDigraph(vertexCount: 3, log: log))
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 1)) == nil)
        #expect(graph.insert(edge: DirectedEdge(from: 1, to: 2)) == 0)
        log.calls = []
        #expect(graph.outDegree(of: 1) == 1 && graph.inDegree(of: 2) == 1)
        #expect(log.calls == ["outDegree", "inDegree"])
        log.calls = []
        #expect(Array(graph.successorIndices(ofIndex: 1)) == [2])
        #expect(log.calls == ["successors"])
        #expect(graph.degree(of: 1) == 1 && graph.edges == [DirectedEdge(from: 1, to: 2)])
        // Maps on the concrete delegator, whose positions are its base's: read and written.
        let weights = graph.addEdgeMap(default: 2)
        graph[weights, ofEdgeAt: 0] = 5
        #expect(graph[weights, ofEdgeAt: 0] == 5 && graph.values(of: weights)[0] == 5)
        #expect(try graph[weights, checkedEdgeAt: 0] == 5)
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 1] }
        #expect(LooplessDenseDigraph._edgeMapOffset(of: 3) == 3)
    }

    @Test("An undirected delegator forwards Graph's members and maps, generic and concrete")
    func undirectedDelegatorForwards() throws {
        let log = CallLog()
        var base = DenseGraph(vertexCount: 3, log: log)
        _ = base.insert(edge: UndirectedEdge(0, 1))
        _ = base.insert(edge: UndirectedEdge(1, 1))
        var graph = LooplessUndirectedGraph(_base: base)
        func degree<G: Graph>(_ g: G, _ v: G.Vertex) -> Int { g.degree(of: v) }
        log.calls = []
        #expect(degree(graph, 1) == 3)
        #expect(log.calls == ["degree"])
        log.calls = []
        #expect(Array(graph.neighbors(of: 0)) == [1] && Array(graph.incidentEdges(of: 1)) == [0, 1, 1])
        #expect(log.calls == ["neighbors", "incidentEdges", "incidentEdges"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2 && graph.vertexIndexBound == 3 && graph.contains(2) && !graph.contains(3))
        #expect(graph.contains(edge: UndirectedEdge(1, 0)) && graph.oppositeVertex(to: 1, acrossEdgeAt: 0) == 0)
        #expect(Array(graph.neighborIndices(ofIndex: 1)) == [0, 1, 1] && Array(graph.incidentEdgeIndices(ofIndex: 0)) == [0])
        #expect(graph.endpointIndices(ofEdgeAt: 0) == (0, 1) && graph.degree(ofIndex: 2) == 0)
        let weights = graph.addEdgeMap(default: 0.5)
        graph[weights, ofEdgeAt: 1] = 2
        #expect(graph.base[weights, ofEdgeAt: 1] == 2 && graph.values(of: weights)[0] == 0.5)
        let tags = graph.addVertexMap(default: 1)
        graph[tags, of: 2] = 3
        #expect(graph[tags, ofVertexAt: 2] == 3 && graph.values(of: tags)[2] == 3)
        // Attaching and writing maps are not structural: the copy is still in the base's generation.
        #expect(base.generation.isCurrent(for: graph) && graph.base.generation.isCurrent(for: graph))

        var concrete = LooplessDenseGraph(_base: base)
        log.calls = []
        #expect(concrete.degree(of: 1) == 3 && Array(concrete.neighborIndices(ofIndex: 0)) == [1] && Array(concrete.incidentEdgeIndices(ofIndex: 0)) == [0])
        #expect(log.calls == ["degree", "neighbors", "incidentEdges", "incidentEdges"])
        let labels = concrete.addEdgeMap(default: "")
        concrete[labels, ofEdgeAt: 0] = "a"
        #expect(concrete[labels, ofEdgeAt: 0] == "a" && concrete.values(of: labels)[0] == "a" && concrete.base[labels, ofEdgeAt: 1] == "")
        #expect(try concrete[labels, checkedEdgeAt: 1] == "")
    }

    @Test("An adaptor that is not a delegator keeps its own members: the reversed out-degree is the base's in-degree")
    func adaptorDoesNotForward() {
        let log = CallLog()
        var base = DenseDigraph(vertexCount: 3, log: log)
        _ = base.insert(edge: DirectedEdge(from: 0, to: 1))
        _ = base.insert(edge: DirectedEdge(from: 2, to: 1))
        let reversed = ReversedGraph(base: base)
        log.calls = []
        #expect(reversed.outDegree(of: 1) == 2 && reversed.outDegree(of: 0) == 0)
        #expect(!log.calls.contains("outDegree"))
        // The generation is the base's.
        #expect(base.generation.isCurrent(for: reversed))
    }

    @Test("Maps through a delegator: attached, read and written through it, kept in step by the base's mutations")
    func delegatorMaps() throws {
        var graph = LooplessGraph(_base: DenseDigraph(vertexCount: 3, log: CallLog()))
        _ = graph._base.insert(edge: DirectedEdge(from: 0, to: 1))
        _ = graph._base.insert(edge: DirectedEdge(from: 1, to: 2))
        let weights = graph.addEdgeMap(default: 1.5)
        let names = graph.addVertexMap(of: String.self)
        #expect(graph[weights, ofEdgeAt: 0] == 1.5 && graph[weights, ofEdgeAt: 1] == 1.5)
        graph[weights, ofEdgeAt: 1] = 4
        graph[names, of: 2] = "two"
        graph[names, ofVertexAt: 0] = "zero"
        #expect(graph[weights, ofEdgeAt: 1] == 4 && graph.base[weights, ofEdgeAt: 1] == 4)
        #expect(graph[names, of: 2] == "two" && graph[names, ofVertexAt: 0] == "zero" && graph[names, of: 1] == nil)
        #expect(try graph[weights, checkedEdgeAt: 1] == 4 && graph[names, checked: 2] == "two" && graph[names, checkedVertexAt: 0] == "zero")
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 2] }
        #expect(throws: VertexNotFound.self) { try graph[names, checked: 3] }
        #expect(throws: VertexNotFound.self) { try graph[names, checkedVertexAt: -1] }
        let w = graph.values(of: weights)
        #expect(w[0] == 1.5 && w[1] == 4 && w.defaultValue == 1.5)
        let n = graph.values(of: names)
        #expect(n[2] == "two" && n[1] == nil && n.defaultValue == nil)
        // The base's swap-remove moves edge 1 into position 0, values included.
        graph._base.remove(edgeAt: 0)
        #expect(graph.edges == [DirectedEdge(from: 1, to: 2)] && graph[weights, ofEdgeAt: 0] == 4)
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 1] }
        // The snapshot is a value: it still reads the old values.
        #expect(w[0] == 1.5 && w[1] == 4)
        graph.removeEdgeMap(weights)
        graph.removeVertexMap(names)
        #expect(graph._base.edgeMaps.isEmpty && graph._base.vertexMaps.isEmpty)
        #expect(LooplessGraph<DenseDigraph>._edgeMapLayout == .dense && LooplessGraph<DenseDigraph>._vertexMapLayout == .dense)
        #expect(LooplessGraph<DenseDigraph>._edgeMapOffset(of: 7) == 7)
    }

    @Test("Maps through a view: the undirected and directed views read the base's maps; the generation is the base's")
    func viewMaps() throws {
        var undirectedBase = DenseGraph(vertexCount: 3, log: CallLog())
        _ = undirectedBase.insert(edge: UndirectedEdge(0, 1))
        _ = undirectedBase.insert(edge: UndirectedEdge(1, 2))
        let costs = undirectedBase.addEdgeMap(default: 1)
        let ranks = undirectedBase.addVertexMap(default: 0)
        undirectedBase[costs, ofEdgeAt: 1] = 9
        undirectedBase[ranks, of: 1] = 4
        let arcs = undirectedBase.directedView
        let w = arcs.values(of: costs)
        // Arcs carry their edge's position.
        #expect(arcs.edges.indices.map { w[$0.position] } == [1, 1, 9, 9])
        #expect(arcs[ranks, of: 1] == 4 && arcs.values(of: ranks)[1] == 4 && arcs.base.edges == undirectedBase.edges)
        #expect(try arcs[ranks, checked: 1] == 4)
        #expect(throws: VertexNotFound.self) { try arcs[ranks, checked: 3] }
        #expect(undirectedBase.generation.isCurrent(for: arcs))
        undirectedBase[costs, ofEdgeAt: 0] = 5
        #expect(undirectedBase.generation.isCurrent(for: arcs) && w[0] == 1)
        _ = undirectedBase.insert(edge: UndirectedEdge(2, 0))
        #expect(!undirectedBase.generation.isCurrent(for: arcs))

        var base = DenseDigraph(vertexCount: 3, log: CallLog())
        _ = base.insert(edge: DirectedEdge(from: 0, to: 1))
        _ = base.insert(edge: DirectedEdge(from: 2, to: 1))
        let labels = base.addEdgeMap(default: "")
        let tags = base.addVertexMap(default: 0)
        base[labels, ofEdgeAt: 1] = "b"
        base[tags, of: 2] = 7
        let undirected = base.undirectedView
        #expect(undirected.base.edges == base.edges)
        #expect(undirected[labels, ofEdgeAt: 1] == "b" && undirected[labels, ofEdgeAt: 0] == "")
        #expect(try undirected[labels, checkedEdgeAt: 1] == "b")
        #expect(throws: EdgeNotFound.self) { try undirected[labels, checkedEdgeAt: 2] }
        #expect(undirected[tags, of: 2] == 7 && undirected[tags, of: 0] == 0)
        #expect(try undirected[tags, checked: 2] == 7)
        #expect(throws: VertexNotFound.self) { try undirected[tags, checked: 5] }
        let byPosition = undirected.values(of: labels)
        #expect(undirected.edges.indices.map { byPosition[$0] } == ["", "b"])
        #expect(undirected.values(of: tags)[2] == 7)
        #expect(base.generation.isCurrent(for: undirected))
        base[labels, ofEdgeAt: 0] = "a"
        #expect(base.generation.isCurrent(for: undirected) && undirected[labels, ofEdgeAt: 0] == "")
    }

    @Test("Generations: a structural mutation starts one, a map write or capacity does not, copies share one until mutated")
    func generations() {
        var graph = DenseDigraph(vertexCount: 2, log: CallLog())
        // Never mutated: untracked, current for nothing.
        #expect(!graph.generation.isCurrent(for: graph) && !GraphGeneration.untracked.isCurrent(for: graph))
        _ = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let first = graph.generation
        #expect(first.isCurrent(for: graph) && graph.generation.isCurrent(for: first))
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: 0] = 3
        graph.reserveCapacity(edgeCount: 10)
        #expect(first.isCurrent(for: graph))
        var copy = graph
        #expect(first.isCurrent(for: copy))
        _ = copy.insert(edge: DirectedEdge(from: 1, to: 0))
        #expect(!first.isCurrent(for: copy) && first.isCurrent(for: graph))
        graph.remove(edgeAt: 0)
        #expect(!first.isCurrent(for: graph))
        let second = graph.generation
        #expect(!second.isCurrent(for: copy) && !copy.generation.isCurrent(for: second))
        // Mutating again with no one holding the generation keeps no stale state.
        _ = graph.insertVertex()
        #expect(!second.isCurrent(for: graph) && graph.generation.isCurrent(for: graph))
        let third = graph.generation
        graph.removeAllEdges()
        #expect(!third.isCurrent(for: graph))
        // An undirected graph, read through the view: the base's generation.
        #expect(graph.generation.isCurrent(for: graph.undirectedView) && !third.isCurrent(for: graph.undirectedView))
    }

    @Test("Dense maps on a swap-remove graph follow appends and removals, copy on write and empty with removeAll")
    func denseMaps() {
        var graph = DenseDigraph(vertexCount: 3, log: CallLog())
        for k in 0 ..< 5 { _ = graph.insert(edge: DirectedEdge(from: k % 3, to: (k + 1) % 3)) }
        let ids = graph.addEdgeMap(default: -1)
        let marks = graph.addEdgeMap(of: [Int].self)
        for p in graph.edges.indices { graph[ids, ofEdgeAt: p] = p * 10 }
        graph[marks, ofEdgeAt: 4] = [4]
        _ = graph.insert(edge: DirectedEdge(from: 2, to: 2))
        #expect(graph.edges.indices.map { graph[ids, ofEdgeAt: $0] } == [0, 10, 20, 30, 40, -1])
        let snapshot = graph
        graph.remove(edgeAt: 1)
        graph.remove(edgeAt: 2)
        // 1 took the last (5), then 2 took the new last (the old 4).
        #expect(graph.edges.indices.map { graph[ids, ofEdgeAt: $0] } == [0, -1, 40, 30])
        #expect(graph.edges.indices.map { graph[marks, ofEdgeAt: $0] } == [nil, nil, [4], nil])
        graph.remove(edgeAt: 3)
        #expect(graph.edges.indices.map { graph[ids, ofEdgeAt: $0] } == [0, -1, 40])
        #expect(snapshot.edges.indices.map { snapshot[ids, ofEdgeAt: $0] } == [0, 10, 20, 30, 40, -1])
        var copy = graph
        copy[ids, ofEdgeAt: 0] = 99
        #expect(graph[ids, ofEdgeAt: 0] == 0 && copy[ids, ofEdgeAt: 0] == 99)
        // A vertex map attached with vertices present has one default each, and new vertices
        // append one.
        let names = graph.addVertexMap(default: "?")
        #expect(graph.insertVertex() == 3)
        graph[names, of: 3] = "new"
        #expect(graph.vertices.map { graph[names, of: $0] } == ["?", "?", "?", "new"])
        graph.reserveCapacity(edgeCount: 64)
        graph.removeAllEdges()
        _ = graph.insert(edge: DirectedEdge(from: 0, to: 3))
        #expect(graph[ids, ofEdgeAt: 0] == -1 && graph[marks, ofEdgeAt: 0] == nil && graph[names, of: 3] == "new")
        #expect(graph.edgeMaps._entries.count == 2 && graph.vertexMaps._entries.count == 1)
    }

    @Test("Handles: equal by identity, hashable, valid on copies, and found again after an earlier map is removed")
    func handles() {
        var graph = DenseDigraph(vertexCount: 2, log: CallLog())
        _ = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let a = graph.addEdgeMap(default: 1), b = graph.addEdgeMap(default: 2), c = graph.addEdgeMap(default: 3)
        #expect(a != b && a == a && Set([a, b, c, a]).count == 3)
        let u = graph.addVertexMap(default: 0), v = graph.addVertexMap(default: 0)
        #expect(u != v && Set([u, v, u]).count == 2)
        graph.removeEdgeMap(a)
        // c's hint (2) is past the end now: found by search.
        #expect(graph[c, ofEdgeAt: 0] == 3 && graph[b, ofEdgeAt: 0] == 2)
        let copy = graph
        #expect(copy[c, ofEdgeAt: 0] == 3)
    }

    @Test("A handle on another graph, a removed handle, and a dead position trap")
    func handleMisuse() async {
        await #expect(processExitsWith: .failure) {
            var graph = DenseDigraph(vertexCount: 2, log: CallLog())
            _ = graph.insert(edge: DirectedEdge(from: 0, to: 1))
            let weights = graph.addEdgeMap(default: 0)
            var other = DenseDigraph(vertexCount: 2, log: CallLog())
            _ = other.insert(edge: DirectedEdge(from: 0, to: 1))
            _ = other[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = DenseDigraph(vertexCount: 2, log: CallLog())
            let tags = graph.addVertexMap(default: 0)
            graph.removeVertexMap(tags)
            _ = graph[tags, of: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = LooplessGraph(_base: DenseDigraph(vertexCount: 2, log: CallLog()))
            let weights = graph.addEdgeMap(default: 0)
            graph[weights, ofEdgeAt: 0] = 1
        }
    }

    @Test("The shared map storage: dense and paged reads, writes, resets, releases, page frees and removals")
    func storage() {
        var dense = _AttachedMaps()
        let (token, hint) = dense.add(default: 5, layout: .dense, count: 3)
        let (other, _) = dense.add(default: "x", layout: .dense, count: 3)
        #expect(dense.index(of: token, hint: hint) == 0 && dense.index(of: other, hint: 0) == 1)
        dense.setValue(7, at: 1, in: 0, layout: .dense)
        dense.setValue("y", at: 2, in: 1, layout: .dense)
        #expect((0 ..< 3).map { dense.value(Int.self, at: $0, in: 0, layout: .dense) } == [5, 7, 5])
        dense.appendDefaults(count: 2)
        #expect(Array(dense.storage(Int.self, in: 0).dense) == [5, 7, 5, 5, 5] && Array(dense.storage(String.self, in: 1).dense) == ["x", "x", "y", "x", "x"])
        // Releasing leaves trivial values alone and resets the others.
        dense.setValue(6, at: 2, in: 0, layout: .dense)
        dense.release(at: 2)
        #expect(dense.storage(Int.self, in: 0).dense[2] == 6 && dense.storage(String.self, in: 1).dense[2] == "x")
        dense.setValue(9, at: 4, in: 0, layout: .dense)
        dense.swapRemove(at: 1)
        #expect(Array(dense.storage(Int.self, in: 0).dense) == [5, 9, 6, 5])
        dense.setValue(8, at: 0, in: 0, layout: .dense)
        let copy = dense
        dense.reset(at: 0)
        #expect(dense.storage(Int.self, in: 0).dense[0] == 5 && copy.storage(Int.self, in: 0).dense[0] == 8)
        dense.reserveCapacity(100)
        #expect(unsafeDowncast(dense._entries[0].buffer, to: _DenseMapBuffer.self).capacity >= 100 && copy.storage(Int.self, in: 0).dense.count == 4)
        dense.removeAll(keepingCapacity: true)
        #expect(dense.storage(Int.self, in: 0).dense.isEmpty && unsafeDowncast(dense._entries[0].buffer, to: _DenseMapBuffer.self).capacity >= 100)
        dense.remove(token, hint: hint)
        #expect(dense._entries.count == 1 && dense.index(of: other, hint: 1) == 0)

        var paged = _AttachedMaps()
        let (pagedToken, _) = paged.add(default: 0, layout: .paged, count: 0)
        #expect(paged.storage(Int.self, in: 0).pages.isEmpty && paged.value(Int.self, at: 5000, in: 0, layout: .paged) == 0)
        paged.setValue(3, at: 5000, in: 0, layout: .paged)
        paged.setValue(1, at: 10, in: 0, layout: .paged)
        paged.setValue(2, at: 2100, in: 0, layout: .paged)
        paged.setValue(6, at: 7300, in: 0, layout: .paged)
        var storage = paged.storage(Int.self, in: 0)
        #expect(storage.firstPage == 0 && storage.pages.count == 8 && storage.pages.map(\.count) == [1024, 0, 1024, 0, 1024, 0, 0, 1024])
        #expect([10, 2100, 5000, 7300, 11, 1500, 9000, -1].map { paged.value(Int.self, at: $0, in: 0, layout: .paged) } == [1, 2, 3, 6, 0, 0, 0, 0])
        paged.reset(at: 2100)
        paged.release(at: 5000)
        #expect(paged.value(Int.self, at: 2100, in: 0, layout: .paged) == 0 && paged.value(Int.self, at: 5000, in: 0, layout: .paged) == 3)
        paged.reset(at: 3000)
        let pagedCopy = paged
        // Freeing the last page drops it and the unallocated pages before it.
        paged.freePage(7)
        storage = paged.storage(Int.self, in: 0)
        #expect(storage.pages.count == 5 && storage.firstPage == 0)
        // Freeing the front pages drops them once they are at least half the table.
        paged.freePage(0)
        storage = paged.storage(Int.self, in: 0)
        #expect(storage.pages.count == 5 && storage.firstPage == 0)
        paged.freePage(2)
        storage = paged.storage(Int.self, in: 0)
        #expect(storage.pages.count == 1 && storage.firstPage == 4 && paged.value(Int.self, at: 5000, in: 0, layout: .paged) == 3)
        paged.freePage(9)
        paged.freePage(1)
        // A write before the first page grows the table at the front.
        paged.setValue(4, at: 1030, in: 0, layout: .paged)
        storage = paged.storage(Int.self, in: 0)
        #expect(storage.firstPage == 1 && storage.pages.count == 4 && paged.value(Int.self, at: 1030, in: 0, layout: .paged) == 4)
        #expect(pagedCopy.value(Int.self, at: 7300, in: 0, layout: .paged) == 6 && pagedCopy.value(Int.self, at: 1030, in: 0, layout: .paged) == 0)
        paged.freePage(1)
        paged.freePage(4)
        storage = paged.storage(Int.self, in: 0)
        #expect(storage.pages.isEmpty && storage.firstPage == 0)
        // Exactly half the table freed at the front: dropped.
        for page in 0 ..< 4 { paged.setValue(page, at: page * 1024, in: 0, layout: .paged) }
        paged.freePage(0)
        paged.freePage(1)
        storage = paged.storage(Int.self, in: 0)
        #expect(storage.pages.count == 2 && storage.firstPage == 2)
        paged.setValue(1, at: 3, in: 0, layout: .paged)
        paged.removeAll(keepingCapacity: false)
        #expect(paged.storage(Int.self, in: 0).pages.isEmpty && paged.value(Int.self, at: 3, in: 0, layout: .paged) == 0)
        paged.remove(pagedToken, hint: 0)
        #expect(paged.isEmpty)
    }
}
