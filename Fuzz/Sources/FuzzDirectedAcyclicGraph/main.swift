// DirectedAcyclicGraph over AdjacencyList, DirectedPseudograph and StableDirectedGraph, all three
// driven by the same random sequence of `insert(_:)`, `insert(edge:)`, `insert(checked:)`, removals
// (a vertex, an edge, a position), `removeAllEdges()` and `removeAll()`, against a model of the
// vertex set and the edge multiset (copies collapse on AdjacencyList). A sequence may start from
// `init?(vertices:edges:)`, which must be nil exactly when the edges have a cycle and otherwise
// order by Kahn's algorithm, FIFO with the roots in `vertices` order. A churn step inserts and
// removes over a thousand fresh vertices, with backward edges into the graph, so StableDirectedGraph's
// keys cross a 1024-key page and the dense bases renumber their labels. A sources-last step inserts
// a chain whose every edge arrives with a new source (s1 → t, s2 → s1, …).
//
// After every step: the vertices and edges match the model; `topologicalOrder` is a permutation of
// the vertices in which every edge goes forward (so the graph is acyclic); `topologicalPosition(of:)`,
// `(checked:)` and the order's `firstIndex(of:)` agree with it; an insertion is rejected exactly when
// the model has a path from the target to the source (or it is a self-loop), with the matching
// `AcyclicEdgeError` (`insert(checked:)` throws `.missingEndpoint` first), and then nothing
// changes and `bidirectionalShortestPath(from: target, to: source)` is a genuine shortest path; an
// accepted edge is at the returned position; between two placed vertices, a forward edge moves
// nothing and a backward one moves only vertices between the endpoints' places (where a new endpoint
// goes is left to the order checks); removals keep the relative order.
//
// Every few steps: `transitiveClosure()` (the reachable pairs, existing edges at their positions),
// `transitiveReduction()` (the first copy of each edge with no longer path, in `edges` order),
// `longestPath()` (the documented first-tie rule, and the longest length from the model) and
// `hasPath(from:to:)` for every pair against a breadth-first search of the model; on graphs of at
// most eight vertices, `isDSeparator` against every trail, `minimalDSeparator` (separating, minimal,
// nil exactly when the ancestors of the pair do not separate it) and `moralGraph(of:)`.
//
// Decoding: as in FuzzLabeledGraphs, an in-memory decoder hands `init(from:)` an already built base
// and the order offsets. A valid payload decodes to an equal graph with the same order; a hostile one
// (an order too short or too long, a repeat, a negative or huge offset, the order reversed or an
// edge's ends swapped in it, a base with a cycle) must throw `dataCorrupted` at the documented key,
// never trap. On the StableDirectedGraph lane, a base whose one vertex is at position 2³⁶ (itself
// decoded through the same decoder) must decode, or throw, cheaply.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import FuzzSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Traversal
import Walks

/// A decoder over one keyed payload: the generic `decode` hands back the stored value when its
/// type matches, so the base is stored already built and no nested containers are needed.
struct PayloadDecoder: Decoder {
    let values: [String: Any]
    var codingPath: [any CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(Container<Key>(values: values))
    }
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { throw Self.mismatch }
    func singleValueContainer() throws -> any SingleValueDecodingContainer { throw Self.mismatch }
    static var mismatch: DecodingError { .typeMismatch(Any.self, .init(codingPath: [], debugDescription: "unsupported")) }

    struct Container<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let values: [String: Any]
        var codingPath: [any CodingKey] { [] }
        var allKeys: [Key] { values.keys.compactMap { Key(stringValue: $0) } }
        func contains(_ key: Key) -> Bool { values[key.stringValue] != nil }
        func decodeNil(forKey key: Key) throws -> Bool { false }
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            guard let value = values[key.stringValue] as? T else { throw PayloadDecoder.mismatch }
            return value
        }
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { throw PayloadDecoder.mismatch }
        func decode(_ type: String.Type, forKey key: Key) throws -> String { throw PayloadDecoder.mismatch }
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double { throw PayloadDecoder.mismatch }
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float { throw PayloadDecoder.mismatch }
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            guard let value = values[key.stringValue] as? Int else { throw PayloadDecoder.mismatch }
            return value
        }
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { throw PayloadDecoder.mismatch }
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { throw PayloadDecoder.mismatch }
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { throw PayloadDecoder.mismatch }
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { throw PayloadDecoder.mismatch }
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { throw PayloadDecoder.mismatch }
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { throw PayloadDecoder.mismatch }
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { throw PayloadDecoder.mismatch }
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { throw PayloadDecoder.mismatch }
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { throw PayloadDecoder.mismatch }
        func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            throw PayloadDecoder.mismatch
        }
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer { throw PayloadDecoder.mismatch }
        func superDecoder() throws -> any Decoder { throw PayloadDecoder.mismatch }
        func superDecoder(forKey key: Key) throws -> any Decoder { throw PayloadDecoder.mismatch }
    }
}

struct Pair: Hashable {
    let source: Int
    let target: Int
}

/// The vertex set and the edge multiset.
struct Model {
    let simple: Bool
    var vertices: Set<Int> = []
    var edges: [Pair: Int] = [:]

    var edgeCount: Int { edges.values.reduce(0, +) }

    func successors() -> [Int: [Int]] {
        var rows: [Int: [Int]] = [:]
        for pair in edges.keys { rows[pair.source, default: []].append(pair.target) }
        return rows
    }

    /// Breadth-first distances from `start` (0 at `start` itself).
    func distances(from start: Int, _ rows: [Int: [Int]]) -> [Int: Int] {
        var distance = [start: 0]
        var queue = [start], next = 0
        while next < queue.count {
            let v = queue[next]
            next += 1
            for w in rows[v, default: []] where distance[w] == nil {
                distance[w] = distance[v]! + 1
                queue.append(w)
            }
        }
        return distance
    }

    mutating func insert(_ pair: Pair) {
        vertices.insert(pair.source)
        vertices.insert(pair.target)
        edges[pair] = simple ? 1 : edges[pair, default: 0] + 1
    }

    mutating func remove(_ pair: Pair) -> Bool {
        guard let count = edges[pair] else { return false }
        edges[pair] = count == 1 ? nil : count - 1
        return true
    }

    mutating func remove(vertex v: Int) {
        vertices.remove(v)
        edges = edges.filter { $0.key.source != v && $0.key.target != v }
    }
}

enum Op {
    case insertEdge(Int, Int)
    case insertSafe(Int, Int)
    case insertVertex(Int)
    case removeVertex(Int)
    case removeEdge(Int, Int)
    case removeEdgeAt(Int)
    case removeAll
    case removeAllEdges
    case churn(count: Int, edges: Int, reverse: Bool)
    /// A chain whose every edge arrives with a new source: `s1 → t`, `s2 → s1`, …
    case sourcesLast(target: Int, start: Int, length: Int)
    case algorithms
    case decode(Int)
}

struct Lane<Base: MutableDirectedGraph<Int> & Codable & Equatable> {
    let name: String
    var graph = DirectedAcyclicGraph<Base>()
    var model: Model
    let make: ([Int], [DirectedEdge<Int>]) -> Base
}

@main
enum FuzzDirectedAcyclicGraph {
    static func main() { runFuzzer(fuzz) }

    /// Labels far from the keys, so mixing a label with a key shows.
    static func label(_ k: Int) -> Int { 100 + 7 * k }
    static let pool = 10
    static let outsider = -3

    static func fuzz(_ input: inout FuzzInput) {
        var lists = Lane<AdjacencyList<Int>>(name: "AdjacencyList", model: Model(simple: true)) { AdjacencyList(vertices: $0, edges: $1) }
        var pseudo = Lane<DirectedPseudograph<Int>>(name: "DirectedPseudograph", model: Model(simple: false)) { DirectedPseudograph(vertices: $0, edges: $1) }
        var stable = Lane<StableDirectedGraph<Int>>(name: "StableDirectedGraph", model: Model(simple: false)) { StableDirectedGraph(vertices: $0, edges: $1) }

        if input.int(below: 3) == 0 {
            let vertices = (0 ..< input.int(below: 5)).map { _ in label(input.int(below: pool)) }
            let edges = (0 ..< input.int(below: 14)).map { _ in DirectedEdge(from: label(input.int(below: pool)), to: label(input.int(below: pool))) }
            build(&lists, vertices, edges)
            build(&pseudo, vertices, edges)
            build(&stable, vertices, edges)
        }
        var step = 0
        while !input.isEmpty && step < 80 {
            step += 1
            let op = read(&input)
            apply(&lists, op, step)
            apply(&pseudo, op, step)
            apply(&stable, op, step)
            if step % 4 == 0 {
                checkAlgorithms(lists, "step \(step)")
                checkAlgorithms(pseudo, "step \(step)")
                checkAlgorithms(stable, "step \(step)")
            }
        }
    }

    static func vertex(_ input: inout FuzzInput) -> Int { label(input.int(below: pool)) }

    static func read(_ input: inout FuzzInput) -> Op {
        switch input.int(below: 32) {
        case 0 ..< 12: return .insertEdge(vertex(&input), vertex(&input))
        case 12 ..< 15: return .insertSafe(vertex(&input), vertex(&input))
        case 15 ..< 17: return .insertVertex(vertex(&input))
        case 17 ..< 20: return .removeVertex(vertex(&input))
        case 20 ..< 22: return .removeEdge(vertex(&input), vertex(&input))
        case 22 ..< 24: return .removeEdgeAt(input.byte())
        case 24: return .removeAll
        case 25: return .removeAllEdges
        case 26: return .churn(count: 1030 + input.byte(), edges: input.int(below: 8), reverse: input.int(below: 2) == 0)
        case 27: return .sourcesLast(target: vertex(&input), start: input.byte(), length: 1 + input.int(below: 6))
        case 28: return .algorithms
        default: return .decode(input.byte())
        }
    }

    // MARK: - Steps

    static func build<B>(_ lane: inout Lane<B>, _ vertices: [Int], _ edges: [DirectedEdge<Int>]) {
        var model = Model(simple: lane.model.simple)
        model.vertices = Set(vertices)
        for edge in edges { model.insert(Pair(source: edge.source, target: edge.target)) }
        let rows = model.successors()
        let cyclic = model.edges.keys.contains { $0.source == $0.target || model.distances(from: $0.target, rows)[$0.source] != nil }
        let context = "\(lane.name) init(vertices: \(vertices), edges: \(edges))"
        guard let graph = DirectedAcyclicGraph<B>(vertices: vertices, edges: edges) else {
            check(cyclic, "nil without a cycle: \(context)")
            return
        }
        check(!cyclic, "built with a cycle: \(context)")
        lane.graph = graph
        lane.model = model
        checkState(lane, context)
        // Kahn's algorithm, FIFO, the roots in `vertices` order, the successors in row order.
        var remaining: [Int: Int] = [:]
        for v in graph.vertices { remaining[v] = graph.inDegree(of: v) }
        var kahn = graph.vertices.filter { remaining[$0] == 0 }
        var next = 0
        while next < kahn.count {
            for w in graph.successors(of: kahn[next]) {
                remaining[w]! -= 1
                if remaining[w] == 0 { kahn.append(w) }
            }
            next += 1
        }
        check(Array(graph.topologicalOrder) == kahn, "bulk order \(Array(graph.topologicalOrder)), expected \(kahn): \(context)")
    }

    struct Snapshot<B: MutableDirectedGraph<Int>>: Equatable {
        let vertices: [Int]
        let positions: [B.Edges.Index]
        let edges: [DirectedEdge<Int>]
        let order: [Int]

        init(_ graph: DirectedAcyclicGraph<B>) {
            vertices = Array(graph.vertices)
            positions = Array(graph.edges.indices)
            edges = positions.map { DirectedEdge(from: graph.source(ofEdgeAt: $0), to: graph.target(ofEdgeAt: $0)) }
            order = Array(graph.topologicalOrder)
        }
    }

    static func apply<B>(_ lane: inout Lane<B>, _ op: Op, _ step: Int) {
        let context = "\(lane.name) step \(step) \(op)"
        let before = Snapshot(lane.graph)
        switch op {
        case .insertEdge(let u, let v):
            insertEdge(&lane, u, v, checked: false, before, context)
        case .insertSafe(let u, let v):
            insertEdge(&lane, u, v, checked: true, before, context)
        case .insertVertex(let v):
            let present = lane.model.vertices.contains(v)
            let result = lane.graph.insert(v)
            check(result.inserted == !present && result.memberAfterInsert == v, "insert(\(v)) returned \(result): \(context)")
            lane.model.vertices.insert(v)
            check(Array(lane.graph.topologicalOrder) == (present ? before.order : before.order + [v]), "a new vertex is placed last: \(context)")
        case .removeVertex(let v):
            let present = lane.model.vertices.contains(v)
            check(lane.graph.remove(v) == (present ? v : nil), "remove(\(v)): \(context)")
            lane.model.remove(vertex: v)
            check(Array(lane.graph.topologicalOrder) == before.order.filter { $0 != v }, "removing a vertex keeps the order: \(context)")
        case .removeEdge(let u, let v):
            let removed = lane.model.remove(Pair(source: u, target: v))
            check(lane.graph.remove(edge: DirectedEdge(from: u, to: v)) == (removed ? DirectedEdge(from: u, to: v) : nil), "remove(edge: \(u)→\(v)): \(context)")
            check(Array(lane.graph.topologicalOrder) == before.order, "removing an edge keeps the order: \(context)")
        case .removeEdgeAt(let k):
            guard !before.positions.isEmpty else { break }
            let position = before.positions[k % before.positions.count]
            let edge = before.edges[k % before.positions.count]
            check(lane.graph.remove(edgeAt: position) == edge, "remove(edgeAt: \(position)): \(context)")
            check(lane.model.remove(Pair(source: edge.source, target: edge.target)), "model edge \(edge): \(context)")
            check(Array(lane.graph.topologicalOrder) == before.order, "removing a position keeps the order: \(context)")
        case .removeAll:
            lane.graph.removeAll(keepingCapacity: step % 2 == 0)
            lane.model.vertices = []
            lane.model.edges = [:]
        case .removeAllEdges:
            lane.graph.removeAllEdges(keepingCapacity: step % 2 == 0)
            lane.model.edges = [:]
            check(Array(lane.graph.topologicalOrder) == before.order, "removeAllEdges keeps the order: \(context)")
        case .sourcesLast(let target, let start, let length):
            // Six labels outside the pool, so the sources are usually new.
            var t = target
            for j in 0 ..< length {
                let u = label(pool + (start + j) % 6)
                insertEdge(&lane, u, t, checked: false, Snapshot(lane.graph), "\(context) link \(j)")
                checkState(lane, "\(context) link \(j)")
                t = u
            }
        case .churn(let count, let edges, let reverse):
            churn(&lane, count: count, edges: edges, reverse: reverse, before, context)
        case .algorithms:
            checkAlgorithms(lane, context)
        case .decode(let corruption):
            checkDecoding(lane, corruption, context)
            if corruption % 16 == 0 && B.self == StableDirectedGraph<Int>.self { checkHugePosition(corruption / 16) }
        }
        checkState(lane, context)
    }

    static func insertEdge<B>(_ lane: inout Lane<B>, _ u: Int, _ v: Int, checked: Bool, _ before: Snapshot<B>, _ context: String) {
        let model = lane.model
        let missing = !model.vertices.contains(u) || !model.vertices.contains(v)
        let closes = u == v || (!missing && model.distances(from: v, model.successors())[u] != nil)
        let edge = DirectedEdge(from: u, to: v)
        let result = Result { () throws(AcyclicEdgeError) in try checked ? lane.graph.insert(checked: edge) : lane.graph.insert(edge: edge) }
        if closes || (checked && missing) {
            let expected: AcyclicEdgeError = checked && missing ? .missingEndpoint : u == v ? .selfLoop : .cycle
            check(result == .failure(expected), "\(u)→\(v), which \(closes ? "closes a cycle" : "has a missing end"), gave \(result), not \(expected): \(context)")
            check(Snapshot(lane.graph) == before, "a rejected insertion changed the graph: \(context)")
            if closes && u != v {
                let distance = model.distances(from: v, model.successors())[u]!
                guard let path = lane.graph.bidirectionalShortestPath(from: v, to: u) else {
                    check(false, "no witness path \(v)→\(u): \(context)")
                    return
                }
                let vertices = path.vertices
                check(vertices.first == v && vertices.last == u && path.edges.count == vertices.count - 1, "witness \(vertices) for \(u)→\(v): \(context)")
                check(path.edges.count == distance, "witness of \(path.edges.count) edges, shortest \(distance): \(context)")
                for (i, e) in path.edges.enumerated() {
                    check(lane.graph.source(ofEdgeAt: e) == vertices[i] && lane.graph.target(ofEdgeAt: e) == vertices[i + 1], "witness edge \(e) is not \(vertices[i])→\(vertices[i + 1]): \(context)")
                }
            }
            return
        }
        guard case .success(let position) = result else {
            check(false, "rejected \(u)→\(v), which closes no cycle: \(context)")
            return
        }
        check(lane.graph.source(ofEdgeAt: position) == u && lane.graph.target(ofEdgeAt: position) == v, "insert returned \(position), not an edge \(u)→\(v): \(context)")
        lane.model.insert(Pair(source: u, target: v))
        // A new source to an existing target is placed first; any other new endpoint last, source
        // first. Either way nothing else moves. With both ends already placed, a forward edge moves
        // nothing and a backward one moves only the places between the endpoints'.
        if missing {
            let after = Array(lane.graph.topologicalOrder)
            if !model.vertices.contains(u) && model.vertices.contains(v) {
                check(after == [u] + before.order, "a new source \(u) to \(v) is placed first: \(before.order) to \(after): \(context)")
            } else {
                let added = [u, v].filter { !model.vertices.contains($0) }
                check(after == before.order + added, "new endpoints \(added) are placed last: \(before.order) to \(after): \(context)")
            }
            return
        }
        let order = before.order
        let after = Array(lane.graph.topologicalOrder)
        let low = order.firstIndex(of: v)!, high = order.firstIndex(of: u)!
        if high < low {
            check(after == order, "a forward edge \(u)→\(v) moved vertices: \(order) to \(after): \(context)")
        } else {
            check(after.count == order.count, "order length: \(context)")
            for i in order.indices where i < low || i > high {
                check(after[i] == order[i], "place \(i) outside \(low)...\(high) moved for \(u)→\(v): \(order) to \(after): \(context)")
            }
        }
    }

    static func churn<B>(_ lane: inout Lane<B>, count: Int, edges: Int, reverse: Bool, _ before: Snapshot<B>, _ context: String) {
        let targets = before.vertices
        var fresh: [Int] = []
        for i in 0 ..< count {
            let v = 1_000_000 + i
            check(lane.graph.insert(v).inserted, "churn insert \(v): \(context)")
            fresh.append(v)
            // An edge from a fresh vertex, which has no in-edges, closes no cycle; it goes backward
            // in the order, so Pearce–Kelly runs.
            if !targets.isEmpty && i % 97 < edges {
                let w = targets[(i * 31) % targets.count]
                check((try? lane.graph.insert(edge: DirectedEdge(from: v, to: w))) != nil, "churn edge \(v)→\(w): \(context)")
                check(lane.graph.topologicalPosition(of: v) < lane.graph.topologicalPosition(of: w), "churn order \(v)→\(w): \(context)")
            }
        }
        check(lane.graph.vertexCount == before.vertices.count + count, "churn count: \(context)")
        for v in reverse ? fresh.reversed() : fresh {
            check(lane.graph.remove(v) == v, "churn remove \(v): \(context)")
        }
        // A backward edge moves its target's descendants after the fresh vertex, so only a churn
        // without edges is sure to leave the order as it was.
        if edges == 0 || targets.isEmpty {
            check(Array(lane.graph.topologicalOrder) == before.order, "churn changed the order: \(Array(lane.graph.topologicalOrder)), expected \(before.order): \(context)")
        }
    }

    // MARK: - State

    static func checkState<B>(_ lane: Lane<B>, _ context: String) {
        let graph = lane.graph, model = lane.model
        check(graph.vertexCount == model.vertices.count && Set(graph.vertices) == model.vertices, "vertices \(Array(graph.vertices)), expected \(model.vertices): \(context)")
        var counts: [Pair: Int] = [:]
        for p in graph.edges.indices { counts[Pair(source: graph.source(ofEdgeAt: p), target: graph.target(ofEdgeAt: p)), default: 0] += 1 }
        check(counts == model.edges && graph.edgeCount == model.edgeCount, "edges \(Array(graph.edges)), expected \(model.edges): \(context)")
        checkOrder(graph, context)
    }

    /// The order is a permutation in which every edge goes forward, and the lookups agree with it.
    static func checkOrder<B: MutableDirectedGraph<Int>>(_ graph: DirectedAcyclicGraph<B>, _ context: String) {
        let order = Array(graph.topologicalOrder)
        check(order.count == graph.vertexCount && Set(order) == Set(graph.vertices), "order \(order) is not a permutation of \(Array(graph.vertices)): \(context)")
        for (i, v) in order.enumerated() {
            check(graph.topologicalPosition(of: v) == i && (try? graph.topologicalPosition(checked: v)) == i, "position of \(v) is not \(i): \(context)")
            check(graph.topologicalOrder.firstIndex(of: v) == i && graph.topologicalOrder.contains(v), "order lookup of \(v): \(context)")
        }
        for p in graph.edges.indices {
            let s = graph.source(ofEdgeAt: p), t = graph.target(ofEdgeAt: p)
            check(graph.topologicalPosition(of: s) < graph.topologicalPosition(of: t), "edge \(s)→\(t) goes backward in \(order): \(context)")
        }
        check((try? graph.topologicalPosition(checked: outsider)) == nil && graph.topologicalOrder.firstIndex(of: outsider) == nil && !graph.topologicalOrder.contains(outsider), "outsider in the order: \(context)")
    }

    // MARK: - Algorithms

    static func checkAlgorithms<B>(_ lane: Lane<B>, _ context: String) {
        let graph = lane.graph, model = lane.model
        let rows = model.successors()
        var reach: [Int: [Int: Int]] = [:]
        for v in model.vertices { reach[v] = model.distances(from: v, rows) }

        for a in model.vertices {
            for b in model.vertices {
                check(graph.hasPath(from: a, to: b) == (reach[a]![b] != nil), "hasPath(from: \(a), to: \(b)): \(context)")
            }
        }

        // The closure: the reachable pairs, one new edge each where there was none.
        let closure = graph.transitiveClosure()
        var expected = model.edges
        for (a, row) in reach {
            for b in row.keys where a != b && expected[Pair(source: a, target: b)] == nil { expected[Pair(source: a, target: b)] = 1 }
        }
        var counts: [Pair: Int] = [:]
        for p in closure.edges.indices { counts[Pair(source: closure.source(ofEdgeAt: p), target: closure.target(ofEdgeAt: p)), default: 0] += 1 }
        check(counts == expected, "closure edges \(Array(closure.edges)), expected \(expected): \(context)")
        check(Array(closure.vertices) == Array(graph.vertices) && Array(closure.topologicalOrder) == Array(graph.topologicalOrder), "closure vertices or order: \(context)")
        for p in graph.edges.indices {
            check(closure.source(ofEdgeAt: p) == graph.source(ofEdgeAt: p) && closure.target(ofEdgeAt: p) == graph.target(ofEdgeAt: p), "closure moved the edge at \(p): \(context)")
        }
        checkOrder(closure, "closure \(context)")

        // The reduction: the first copy of each edge with no path of two or more edges.
        let reduction = graph.transitiveReduction()
        var kept: [DirectedEdge<Int>] = []
        var seen: Set<Pair> = []
        for p in graph.edges.indices {
            let s = graph.source(ofEdgeAt: p), t = graph.target(ofEdgeAt: p)
            let pair = Pair(source: s, target: t)
            let longer = rows[s, default: []].contains { $0 != t && reach[$0]![t] != nil }
            if !longer && seen.insert(pair).inserted { kept.append(DirectedEdge(from: s, to: t)) }
        }
        check(Array(reduction.edges) == kept, "reduction \(Array(reduction.edges)), expected \(kept): \(context)")
        check(Array(reduction.vertices) == Array(graph.vertices) && Array(reduction.topologicalOrder) == Array(graph.topologicalOrder), "reduction vertices or order: \(context)")
        checkOrder(reduction, "reduction \(context)")

        checkDSeparation(graph, model, rows, reach, context)

        // The longest path: per vertex in order, the first in-edge achieving the maximum; the first
        // vertex in order with the greatest distance.
        guard let path = graph.longestPath() else {
            check(model.vertices.isEmpty, "longestPath nil on a nonempty graph: \(context)")
            return
        }
        var distance: [Int: Int] = [:]
        var parent: [Int: (Int, B.Edges.Index)] = [:]
        var best: Int? = nil
        for v in graph.topologicalOrder {
            var d = 0
            for e in graph.inEdges(of: v) {
                let u = graph.source(ofEdgeAt: e)
                if distance[u]! + 1 > d {
                    d = distance[u]! + 1
                    parent[v] = (u, e)
                }
            }
            distance[v] = d
            if best == nil || d > distance[best!]! { best = v }
        }
        var vertices = [best!], edges: [B.Edges.Index] = []
        while let (u, e) = parent[vertices.last!] {
            vertices.append(u)
            edges.append(e)
        }
        check(path.vertices == vertices.reversed() && path.edges == edges.reversed(), "longestPath \(path.vertices) \(path.edges), expected \(Array(vertices.reversed())): \(context)")
        // The longest length by the model alone: memoized over successors.
        var memo: [Int: Int] = [:]
        func longest(_ v: Int) -> Int {
            if let known = memo[v] { return known }
            let value = rows[v, default: []].map { longest($0) + 1 }.max() ?? 0
            memo[v] = value
            return value
        }
        check(path.edges.count == model.vertices.map(longest).max()!, "longestPath length \(path.edges.count): \(context)")
    }

    /// d-separation against every trail of the model, for each pair of its first vertices and a
    /// conditioning set drawn from the rest; minimal separators separate, are minimal and exist
    /// exactly when the full candidate set does; the moral graph's edges. Only on graphs of at most
    /// eight vertices, where every trail can be listed.
    static func checkDSeparation<B: MutableDirectedGraph<Int>>(_ graph: DirectedAcyclicGraph<B>, _ model: Model, _ rows: [Int: [Int]], _ reach: [Int: [Int: Int]], _ context: String) {
        let vertices = Array(graph.vertices)
        guard vertices.count >= 2, vertices.count <= 8 else { return }
        var adjacent: [Int: Set<Int>] = [:]
        for (a, row) in rows { for b in row where a != b { adjacent[a, default: []].insert(b); adjacent[b, default: []].insert(a) } }
        func arc(_ a: Int, _ b: Int) -> Bool { rows[a, default: []].contains(b) }
        func connected(_ u: Int, _ v: Int, _ z: Set<Int>) -> Bool {
            var stack: [[Int]] = [[u]]
            while let trail = stack.popLast() {
                let last = trail[trail.count - 1]
                if last == v {
                    var active = true
                    for i in 1 ..< trail.count - 1 {
                        let a = trail[i - 1], m = trail[i], b = trail[i + 1]
                        if arc(a, m) && arc(b, m) {
                            if !z.contains(where: { $0 == m || reach[m]![$0] != nil }) { active = false }
                        } else if z.contains(m) {
                            active = false
                        }
                    }
                    if active { return true }
                    continue
                }
                for w in adjacent[last, default: []] where !trail.contains(w) { stack.append(trail + [w]) }
            }
            return false
        }
        for i in 0 ..< min(3, vertices.count / 2) {
            let x = vertices[i], y = vertices[vertices.count - 1 - i]
            let others = vertices.filter { $0 != x && $0 != y }
            for pick in 0 ..< 3 {
                let z = others.enumerated().filter { ($0.offset + pick) % 3 == 0 }.map(\.element)
                let separated = !connected(x, y, Set(z))
                check(graph.isDSeparator(z, between: [x], and: [y]) == separated, "isDSeparator(\(z), between: \(x), and: \(y)): \(context)")
            }
            let anyExists = !connected(x, y, Set(others.filter { reach[$0]![x] != nil || reach[$0]![y] != nil }))
            let found = graph.minimalDSeparator(between: [x], and: [y])
            check((found != nil) == anyExists, "minimalDSeparator(between: \(x), and: \(y)) \(String(describing: found)): \(context)")
            if let found {
                check(!connected(x, y, Set(found)), "minimalDSeparator \(found) does not separate \(x) and \(y): \(context)")
                for drop in found {
                    check(connected(x, y, Set(found.filter { $0 != drop })), "minimalDSeparator \(found) is not minimal for \(x), \(y): \(context)")
                }
            }
        }
        var expected = Set<UndirectedEdge<Int>>()
        for (a, row) in rows { for b in row { expected.insert(UndirectedEdge(a, b)) } }
        for v in vertices {
            let parents = Set(rows.filter { $0.value.contains(v) }.map(\.key)).sorted()
            for (k, a) in parents.enumerated() { for b in parents[(k + 1)...] { expected.insert(UndirectedEdge(a, b)) } }
        }
        let moral = UndirectedAdjacencyList<Int>.moralGraph(of: graph)
        let mapped = Set(moral.edges.map { UndirectedEdge(vertices[$0.u], vertices[$0.v]) })
        check(mapped == expected && moral.edgeCount == expected.count, "moralGraph: \(context)")
    }

    // MARK: - Decoding

    static func decode<B: MutableDirectedGraph<Int> & Codable>(_ base: B, _ order: [Int]) -> Result<DirectedAcyclicGraph<B>, DecodingError> {
        do {
            return .success(try DirectedAcyclicGraph<B>(from: PayloadDecoder(values: ["base": base, "order": order])))
        } catch let error as DecodingError {
            return .failure(error)
        } catch {
            check(false, "decoding threw \(error), not a DecodingError")
            fatalError()
        }
    }

    static func checkThrow<G>(_ result: Result<G, DecodingError>, at key: String, _ context: String) {
        guard case .failure(let error) = result else { check(false, "hostile payload decoded, expected a throw at \(key): \(context)"); return }
        guard case .dataCorrupted(let info) = error else { check(false, "hostile payload threw \(error), not dataCorrupted: \(context)"); return }
        check(info.codingPath.map(\.stringValue) == [key], "hostile payload threw at \(info.codingPath.map(\.stringValue)), expected \(key): \(context)")
    }

    static func checkDecoding<B>(_ lane: Lane<B>, _ corruption: Int, _ context: String) {
        let graph = lane.graph
        let vertices = Array(graph.base.vertices)
        let n = vertices.count
        let valid = graph.topologicalOrder.map { vertices.firstIndex(of: $0)! }
        guard case .success(let decoded) = decode(graph.base, valid) else {
            check(false, "a valid payload did not decode: \(context)")
            return
        }
        check(decoded == graph && Array(decoded.topologicalOrder) == Array(graph.topologicalOrder), "decoded graph or order: \(context)")
        checkOrder(decoded, "decoded \(context)")

        var order = valid
        var key = "order"
        var base = graph.base
        switch corruption % 9 {
        case 0 where n >= 1: order.removeLast()
        case 1: order.append(n)
        case 2 where n >= 2: order[n - 1] = order[0]
        case 3 where n >= 1: order[corruption % n] = -1 - corruption / 9
        case 4 where n >= 1: order[corruption % n] = corruption % 2 == 0 ? Int.max : Int.min
        case 5 where graph.edgeCount >= 1: order.reverse()
        case 6 where graph.edgeCount >= 1:
            // Swap one edge's ends in the order.
            let positions = Array(graph.edges.indices)
            let p = positions[corruption % positions.count]
            let s = order.firstIndex(of: vertices.firstIndex(of: graph.source(ofEdgeAt: p))!)!
            let t = order.firstIndex(of: vertices.firstIndex(of: graph.target(ofEdgeAt: p))!)!
            order.swapAt(s, t)
        case 7 where n >= 1:
            // A base with a cycle: an edge's reverse, or a self-loop.
            let edges = Array(graph.edges)
            let extra = edges.isEmpty ? DirectedEdge(from: vertices[corruption % n], to: vertices[corruption % n]) : DirectedEdge(from: edges[corruption % edges.count].target, to: edges[corruption % edges.count].source)
            base = lane.make(vertices, edges + [extra])
            order = Array(0 ..< n)
            key = "base"
        case 8: order = order.map { $0 + 1 }
            if n == 0 { return }
        default: return
        }
        checkThrow(decode(base, order), at: key, "corruption \(corruption % 9) order \(order): \(context)")
    }

    /// A StableDirectedGraph base whose one vertex sits at a huge position (2³⁶): decoding the DAG
    /// over it must stay cheap, valid or not. Its base is decoded through the same in-memory decoder.
    static func checkHugePosition(_ corruption: Int) {
        let position = 1 << 36
        let fields: [String: Any] = ["vertices": [label(0)], "vertexPositions": [position], "vertexEnd": position + 1, "edges": [Int](), "edgePositions": [Int](), "edgeEnd": 0]
        guard let base = try? StableDirectedGraph<Int>(from: PayloadDecoder(values: fields)) else {
            check(false, "the huge-position StableDirectedGraph base did not decode")
            return
        }
        let context = "huge position, corruption \(corruption % 4)"
        switch corruption % 4 {
        case 0:
            guard case .success(var graph) = decode(base, [0]) else { check(false, "a valid payload did not decode: \(context)"); return }
            check(Array(graph.topologicalOrder) == [label(0)] && graph.topologicalPosition(of: label(0)) == 0, "decoded order: \(context)")
            // Sources arriving last, at keys past the huge one.
            check((try? graph.insert(edge: DirectedEdge(from: label(1), to: label(0)))) != nil && (try? graph.insert(edge: DirectedEdge(from: label(2), to: label(1)))) != nil, "inserts: \(context)")
            do throws(AcyclicEdgeError) {
                _ = try graph.insert(edge: DirectedEdge(from: label(0), to: label(2)))
                check(false, "a cycle was accepted: \(context)")
            } catch {
                check(error == .cycle, "\(error), not .cycle: \(context)")
            }
            checkOrder(graph, context)
            check(Array(graph.topologicalOrder) == [label(2), label(1), label(0)], "order \(Array(graph.topologicalOrder)): \(context)")
        case 1: checkThrow(decode(base, []), at: "order", context)
        case 2: checkThrow(decode(base, [1]), at: "order", context)
        default: checkThrow(decode(base, [0, 0]), at: "order", context)
        }
    }
}
