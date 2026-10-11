// LabeledGraph over CompressedSparseRow and AdjacencyMatrix against a written-out model: the labels
// in index order (the listed vertices first, then each new endpoint by first appearance, source
// before target) and the set of index pairs. A build step reads listed labels and labeled edges
// (repeats included) and builds both bases through every initializer that fits, the matrix also by
// inserting the same vertices and edges one at a time; a mutation step runs a random sequence of
// matrix insertions (`insert(_:)`, `insert(edge:)`, `insert(safe:)`), removals and resets. After
// each step: the labels both ways, counts, edges in row-major index order with their positions'
// ends, every row by label and by index, degrees, membership of every pair (non-vertices
// included), and the `safe:` spellings (nil exactly for a non-vertex). Every few steps, the
// algorithms agree with the base mapped through the labels: breadth-first layers from every
// vertex, strong and weak components, and Dijkstra with weights by position. Equality: a graph
// equals its rebuild with the labels listed in another order, and not one with an edge more;
// over a `DirectedPseudograph<Int>` base, by edge multiplicity. Decoding: Foundation's coders are
// not available to this toolchain against the SDK, so a minimal in-memory decoder hands
// `init(from:)` the labels and an already built base; a valid payload must decode to the same
// graph, and a hostile one (a label missing, one too many, a repeat, or an `AdjacencyList<Int>`
// base whose vertices are not 0..<n in order) must throw at the documented key, never trap.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import FuzzSupport
import GraphProtocols
import LabeledGraphs
import Multigraphs
import ShortestPaths
import Traversal

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

@main
enum FuzzLabeledGraphs {
    static func main() { runFuzzer(fuzz) }

    /// Labels far from the indices, so mixing a label with an index shows.
    static func label(_ k: Int) -> Int { 1000 + 37 * k }
    static let outsider = -5

    struct Model {
        var labels: [Int] = []
        var edges: Set<[Int]> = []

        func index(of label: Int) -> Int? { labels.firstIndex(of: label) }
        mutating func insert(_ label: Int) -> (inserted: Bool, index: Int) {
            if let i = index(of: label) { return (false, i) }
            labels.append(label)
            return (true, labels.count - 1)
        }
        /// Row-major index order, as both bases list their edges.
        var sortedEdges: [[Int]] { edges.sorted { $0[0] != $1[0] ? $0[0] < $1[0] : $0[1] < $1[1] } }
        func labeled(_ e: [Int]) -> DirectedEdge<Int> { DirectedEdge(from: labels[e[0]], to: labels[e[1]]) }
    }

    static func checkCommon<B: DirectedGraph<Int>>(_ graph: LabeledGraph<Int, B>, _ model: Model, _ context: String) {
        let n = model.labels.count
        check(Array(graph.vertices) == model.labels, "labels \(Array(graph.vertices)), expected \(model.labels) \(context)")
        check(graph.vertexCount == n && graph.base.vertexCount == n && graph.vertexIndexBound == n, "vertexCount \(context)")
        check(graph.edgeCount == model.edges.count && graph.base.edgeCount == model.edges.count, "edgeCount \(graph.edgeCount), expected \(model.edges.count) \(context)")
        let expected = model.sortedEdges.map(model.labeled)
        check(Array(graph.edges) == expected, "edges \(Array(graph.edges)), expected \(expected) \(context)")
        check(graph.edges.count == expected.count && graph.edges.isEmpty == expected.isEmpty, "edges.count \(context)")
        var k = 0
        for p in graph.edges.indices {
            check(k < expected.count && graph.edges[p] == expected[k], "edges[\(p)] \(context)")
            check(graph.source(ofEdgeAt: p) == expected[k].source && graph.target(ofEdgeAt: p) == expected[k].target, "ends at \(p) \(context)")
            check(graph.base.source(ofEdgeAt: p) == model.sortedEdges[k][0] && graph.base.target(ofEdgeAt: p) == model.sortedEdges[k][1], "base ends at \(p) \(context)")
            k += 1
        }
        check(k == expected.count, "edge positions \(context)")
        for (i, v) in model.labels.enumerated() {
            check(graph.vertexIndex(of: v) == i && graph.vertexIndex(safe: v) == i && graph.vertex(atIndex: i) == v, "index of \(v) \(context)")
            check(graph.contains(v), "contains(\(v)) \(context)")
            let row = model.sortedEdges.filter { $0[0] == i }.map { $0[1] }
            check(Array(graph.successors(of: v)) == row.map { model.labels[$0] }, "successors(of: \(v)) \(context)")
            check(graph.successors(safe: v).map { Array($0) } == row.map { model.labels[$0] }, "successors(safe: \(v)) \(context)")
            check(Array(graph.successorIndices(ofIndex: i)) == row, "successorIndices(ofIndex: \(i)) \(context)")
            check(graph.outDegree(of: v) == row.count && graph.outDegree(safe: v) == row.count, "outDegree(of: \(v)) \(context)")
            check(graph.outEdges(of: v).map { graph.target(ofEdgeAt: $0) } == row.map { model.labels[$0] }, "outEdges(of: \(v)) \(context)")
            check(graph.outEdges(safe: v).map { $0.map { graph.source(ofEdgeAt: $0) } } == row.map { _ in v }, "outEdges(safe: \(v)) \(context)")
            check(graph.outEdges(ofIndex: i).map { graph.base.target(ofEdgeAt: $0) } == row, "outEdges(ofIndex: \(i)) \(context)")
        }
        let probes = model.labels + [outsider, label(40)]
        for a in probes {
            let ia = model.index(of: a)
            if ia == nil {
                check(!graph.contains(a) && graph.vertexIndex(safe: a) == nil, "non-vertex \(a) \(context)")
                check(graph.successors(safe: a) == nil && graph.outEdges(safe: a) == nil && graph.outDegree(safe: a) == nil, "safe: on \(a) \(context)")
            }
            for b in probes {
                let present = ia != nil && model.index(of: b) != nil && model.edges.contains([ia!, model.index(of: b)!])
                check(graph.contains(edge: DirectedEdge(from: a, to: b)) == present, "contains(edge: \(a)→\(b)) \(context)")
                check(graph.edges.contains(DirectedEdge(from: a, to: b)) == present, "edges.contains(\(a)→\(b)) \(context)")
            }
        }
    }

    static func checkMatrix(_ graph: LabeledGraph<Int, AdjacencyMatrix>, _ model: Model, _ context: String) {
        checkCommon(graph, model, context)
        for (i, v) in model.labels.enumerated() {
            let column = model.sortedEdges.filter { $0[1] == i }.map { $0[0] }.sorted()
            let out = model.edges.filter { $0[0] == i }.count
            check(Array(graph.predecessors(of: v)) == column.map { model.labels[$0] }, "predecessors(of: \(v)) \(context)")
            check(graph.predecessors(safe: v).map { Array($0) } == column.map { model.labels[$0] }, "predecessors(safe: \(v)) \(context)")
            check(Array(graph.predecessorIndices(ofIndex: i)) == column, "predecessorIndices(ofIndex: \(i)) \(context)")
            check(graph.inDegree(of: v) == column.count && graph.inDegree(safe: v) == column.count, "inDegree(of: \(v)) \(context)")
            check(graph.degree(of: v) == column.count + out && graph.degree(safe: v) == column.count + out, "degree(of: \(v)) \(context)")
            check(graph.inEdges(of: v).map { graph.source(ofEdgeAt: $0) } == column.map { model.labels[$0] }, "inEdges(of: \(v)) \(context)")
            check(graph.inEdges(safe: v).map { $0.map { graph.target(ofEdgeAt: $0) } } == column.map { _ in v }, "inEdges(safe: \(v)) \(context)")
            check(graph.inEdges(ofIndex: i).map { graph.base.source(ofEdgeAt: $0) } == column, "inEdges(ofIndex: \(i)) \(context)")
        }
        for a in [outsider, label(41)] where model.index(of: a) == nil {
            check(graph.predecessors(safe: a) == nil && graph.inEdges(safe: a) == nil, "safe: in-rows on \(a) \(context)")
            check(graph.inDegree(safe: a) == nil && graph.degree(safe: a) == nil, "safe: degrees on \(a) \(context)")
        }
    }

    /// The algorithms on the labeled graph against the base's, mapped through the labels.
    static func checkAlgorithms<B: DirectedGraph<Int>>(_ graph: LabeledGraph<Int, B>, _ context: String) {
        let labels = Array(graph.vertices)
        let base = graph.base
        check(graph.weaklyConnectedComponents().map { Array($0) } == base.weaklyConnectedComponents().map { $0.map { labels[$0] } }, "weak components \(context)")
        check(graph.stronglyConnectedComponents().map { Array($0) } == base.stronglyConnectedComponents().map { $0.map { labels[$0] } }, "strong components \(context)")
        // Weights by the base position's ends, so both runs see the same weight on the same edge.
        func weight(_ s: Int, _ t: Int) -> Int { (s &* 31 &+ t &* 17 &+ 5) % 7 + 1 }
        for (i, v) in labels.enumerated() {
            check(graph.breadthFirstLayers(from: v) == base.breadthFirstLayers(from: i).map { $0.map { labels[$0] } }, "layers from \(v) \(context)")
            let tree = graph.dijkstraShortestPaths(from: v) { weight(base.source(ofEdgeAt: $0), base.target(ofEdgeAt: $0)) }
            let copy = base.dijkstraShortestPaths(from: i) { weight(base.source(ofEdgeAt: $0), base.target(ofEdgeAt: $0)) }
            for (j, w) in labels.enumerated() {
                check(tree.distance(to: w) == copy.distance(to: j), "Dijkstra distance \(v)→\(w) \(context)")
                check(tree.parentEdge(of: w) == copy.parentEdge(of: j), "Dijkstra parent of \(w) from \(v) \(context)")
            }
        }
        if let first = labels.first {
            check(graph.descendants(of: first) == Set(base.descendants(of: 0).map { labels[$0] }), "descendants \(context)")
            check(graph.hasPath(from: first, to: labels[labels.count - 1]) == base.hasPath(from: 0, to: labels.count - 1), "hasPath \(context)")
        }
    }

    // MARK: - Decoding

    static func decode<B: DirectedGraph<Int> & Codable>(_ labels: [Int], _ base: B, _ type: B.Type) -> Result<LabeledGraph<Int, B>, DecodingError> {
        do {
            return .success(try LabeledGraph<Int, B>(from: PayloadDecoder(values: ["labels": labels, "base": base])))
        } catch let error as DecodingError {
            return .failure(error)
        } catch {
            check(false, "decoding threw \(error), not a DecodingError")
            fatalError()
        }
    }

    static func checkThrow<G>(_ result: Result<G, DecodingError>, at key: String, _ context: String) {
        guard case .failure(let error) = result else { check(false, "hostile payload decoded, expected a throw at \(key) \(context)"); return }
        guard case .dataCorrupted(let info) = error else { check(false, "hostile payload threw \(error), not dataCorrupted \(context)"); return }
        check(info.codingPath.map(\.stringValue) == [key], "hostile payload threw at \(info.codingPath.map(\.stringValue)), expected \(key) \(context)")
    }

    static func checkDecoding(_ model: Model, corruption: Int, _ context: String) {
        let numbered = model.sortedEdges.map { DirectedEdge(from: $0[0], to: $0[1]) }
        let n = model.labels.count
        let csr = CompressedSparseRow(vertexCount: n, edges: numbered)
        let matrix = AdjacencyMatrix(vertexCount: n, edges: numbered)
        var labels = model.labels
        var key: String? = nil
        switch corruption {
        case 0 where !labels.isEmpty: labels.removeLast(); key = "labels"
        case 1: labels.append(label(50)); key = "labels"
        case 2 where labels.count >= 2: labels[labels.count - 1] = labels[0]; key = "labels"
        case 3: labels.append(labels.first ?? label(51)); key = "labels"
        default: break
        }
        let fromCSR = decode(labels, csr, CompressedSparseRow.self)
        let fromMatrix = decode(labels, matrix, AdjacencyMatrix.self)
        if let key {
            checkThrow(fromCSR, at: key, "csr \(corruption) \(context)")
            checkThrow(fromMatrix, at: key, "matrix \(corruption) \(context)")
        } else {
            guard case .success(let g) = fromCSR, case .success(let h) = fromMatrix else {
                check(false, "valid payload did not decode \(context)")
                return
            }
            checkCommon(g, model, "decoded csr \(context)")
            checkMatrix(h, model, "decoded matrix \(context)")
            check(g == LabeledGraph<Int, CompressedSparseRow>(vertices: model.labels, edges: model.sortedEdges.map(model.labeled)), "decoded csr equality \(context)")
        }
        // An AdjacencyList<Int> base: valid exactly when its vertices are 0..<n in insertion order.
        if n >= 2 {
            let shuffled = corruption % 2 == 0
            let order = shuffled ? Array((0 ..< n).reversed()) : Array(0 ..< n)
            let list = AdjacencyList<Int>(vertices: order, edges: numbered)
            let result = decode(model.labels, list, AdjacencyList<Int>.self)
            if shuffled {
                checkThrow(result, at: "base", "adjacency list base \(context)")
            } else {
                guard case .success(let g) = result else { check(false, "valid adjacency list base did not decode \(context)"); return }
                check(Array(g.vertices) == model.labels && g.edgeCount == model.edges.count, "decoded adjacency list \(context)")
            }
            // A list base of n vertices with n in place of n − 1.
            let skipped = AdjacencyList<Int>(vertices: Array(0 ..< n - 1) + [n])
            checkThrow(decode(model.labels, skipped, AdjacencyList<Int>.self), at: "base", "skipped vertex \(context)")
        }
    }

    // MARK: - Equality

    static func checkEquality(_ model: Model, _ input: inout FuzzInput, _ context: String) {
        let edges = model.sortedEdges.map(model.labeled)
        let graph = LabeledGraph<Int, CompressedSparseRow>(vertices: model.labels, edges: edges)
        let matrix = LabeledGraph<Int, AdjacencyMatrix>(vertices: model.labels, edges: edges)
        // The labels in another order: equal, though the bases differ.
        var order = model.labels
        for i in order.indices.reversed() where i > 0 { order.swapAt(i, input.int(below: i + 1)) }
        let reordered = LabeledGraph<Int, CompressedSparseRow>(vertices: order, edges: edges.reversed())
        let reorderedMatrix = LabeledGraph<Int, AdjacencyMatrix>(vertices: order, edges: edges.reversed())
        check(graph == reordered && reordered == graph, "reordered csr not equal \(context)")
        check(matrix == reorderedMatrix && reorderedMatrix == matrix, "reordered matrix not equal \(context)")
        guard model.labels.count >= 1 else { return }
        // One edge more, one edge fewer, an edge reversed, or one vertex more: not equal.
        let a = model.labels[input.int(below: model.labels.count)], b = model.labels[input.int(below: model.labels.count)]
        let kind = input.int(below: 4)
        var other = edges
        var vertices = order
        switch kind {
        case 0: other.append(DirectedEdge(from: a, to: b))
        case 1: other.removeAll { $0 == DirectedEdge(from: a, to: b) }; other.append(DirectedEdge(from: b, to: a))
        case 2: other.removeAll { $0.source == a }
        default: vertices.append(label(60))
        }
        let changedSet = Set(other.map { [$0.source, $0.target] }) != Set(edges.map { [$0.source, $0.target] }) || vertices.count != order.count
        let changed = LabeledGraph<Int, CompressedSparseRow>(vertices: vertices, edges: other)
        let changedMatrix = LabeledGraph<Int, AdjacencyMatrix>(vertices: vertices, edges: other)
        check((graph == changed) == !changedSet && (changed == graph) == !changedSet, "changed csr equality, kind \(kind) \(context)")
        check((matrix == changedMatrix) == !changedSet && (changedMatrix == matrix) == !changedSet, "changed matrix equality, kind \(kind) \(context)")
        // Over a pseudograph base, by multiplicity: a parallel copy makes a difference.
        let n = model.labels.count
        var counts = model.sortedEdges.map { _ in 1 + input.int(below: 2) }
        func pseudograph(_ labels: [Int], _ counts: [Int]) -> LabeledGraph<Int, DirectedPseudograph<Int>> {
            var base = DirectedPseudograph<Int>(vertices: 0 ..< n)
            for (e, c) in zip(model.sortedEdges, counts) {
                let s = labels.firstIndex(of: model.labels[e[0]])!, t = labels.firstIndex(of: model.labels[e[1]])!
                for _ in 0 ..< c { base.insert(edge: DirectedEdge(from: s, to: t)) }
            }
            return LabeledGraph(base, labels: labels)
        }
        let left = pseudograph(model.labels, counts), right = pseudograph(order, counts)
        check(left == right && right == left, "pseudograph reordered not equal \(context)")
        if !counts.isEmpty {
            let k = input.int(below: counts.count)
            counts[k] = 3 - counts[k]
            let moved = pseudograph(order, counts)
            check(left != moved && moved != left, "pseudograph multiplicity ignored \(context)")
        }
    }

    // MARK: - The fuzz loop

    static func fuzz(_ input: inout FuzzInput) {
        if input.int(below: 2) == 0 { fuzzBuild(&input) } else { fuzzMutation(&input) }
    }

    /// Builds from listed labels and labeled edges, both bases, every initializer.
    static func fuzzBuild(_ input: inout FuzzInput) {
        let listedCount = input.int(below: 6), edgeCount = input.int(below: 24), alphabet = 1 + input.int(below: 10)
        let listed = (0 ..< listedCount).map { _ in label(input.int(below: alphabet)) }
        let pairs = (0 ..< edgeCount).map { _ in DirectedEdge(from: label(input.int(below: alphabet)), to: label(input.int(below: alphabet))) }
        var model = Model()
        for v in listed { _ = model.insert(v) }
        for e in pairs {
            let s = model.insert(e.source).index, t = model.insert(e.target).index
            model.edges.insert([s, t])
        }
        let context = "listed \(listed), edges \(pairs.map { "\($0.source)→\($0.target)" })"
        let csr = LabeledGraph<Int, CompressedSparseRow>(vertices: listed, edges: pairs)
        let matrix = LabeledGraph<Int, AdjacencyMatrix>(vertices: listed, edges: pairs)
        checkCommon(csr, model, "csr \(context)")
        checkMatrix(matrix, model, "matrix \(context)")
        if listed.isEmpty {
            checkCommon(LabeledGraph<Int, CompressedSparseRow>(edges: pairs), model, "csr init(edges:) \(context)")
            checkMatrix(LabeledGraph<Int, AdjacencyMatrix>(edges: pairs), model, "matrix init(edges:) \(context)")
        }
        if pairs.isEmpty {
            checkCommon(LabeledGraph<Int, CompressedSparseRow>(vertices: listed), model, "csr init(vertices:) \(context)")
            checkMatrix(LabeledGraph<Int, AdjacencyMatrix>(vertices: listed), model, "matrix init(vertices:) \(context)")
        }
        // init(_ graph:) from each other (indexed) and from an AdjacencyList of the same labels.
        checkCommon(LabeledGraph<Int, CompressedSparseRow>(matrix), model, "csr from matrix \(context)")
        checkMatrix(LabeledGraph<Int, AdjacencyMatrix>(csr), model, "matrix from csr \(context)")
        let list = AdjacencyList<Int>(vertices: listed, edges: pairs)
        checkCommon(LabeledGraph<Int, CompressedSparseRow>(list), model, "csr from list \(context)")
        checkMatrix(LabeledGraph<Int, AdjacencyMatrix>(list), model, "matrix from list \(context)")
        checkCommon(LabeledGraph(csr.base, labels: csr.vertices), model, "init(_:labels:) \(context)")
        // The same graph by insertion, one call at a time.
        var inserted = LabeledGraph<Int, AdjacencyMatrix>()
        for v in listed { inserted.insert(v) }
        for e in pairs { inserted.insert(edge: e) }
        checkMatrix(inserted, model, "inserted \(context)")
        check(inserted == matrix && inserted.base == matrix.base, "inserted equals built \(context)")
        checkAlgorithms(csr, "csr \(context)")
        checkAlgorithms(matrix, "matrix \(context)")
        checkEquality(model, &input, context)
        checkDecoding(model, corruption: input.int(below: 6), context)
    }

    /// A random sequence of matrix mutations against the model.
    static func fuzzMutation(_ input: inout FuzzInput) {
        var graph = LabeledGraph<Int, AdjacencyMatrix>()
        var model = Model()
        var log: [String] = []
        var steps = 0
        while !input.isEmpty, steps < 64 {
            steps += 1
            let a = label(input.int(below: 10)), b = label(input.int(below: 10))
            switch input.int(below: 16) {
            case 0 ..< 3:
                let result = graph.insert(a)
                let expected = model.insert(a)
                check(result.inserted == expected.inserted && result.memberAfterInsert == a, "insert(\(a)) result")
                log.append("insert(\(a))")
            case 3 ..< 8:
                let result = graph.insert(edge: DirectedEdge(from: a, to: b))
                let s = model.insert(a).index, t = model.insert(b).index
                let new = model.edges.insert([s, t]).inserted
                check(result.inserted == new && result.memberAfterInsert == DirectedEdge(from: a, to: b), "insert(edge: \(a)→\(b)) result")
                log.append("insert(edge: \(a)→\(b))")
            case 8 ..< 10:
                let result = graph.insert(safe: DirectedEdge(from: a, to: b))
                if let s = model.index(of: a), let t = model.index(of: b) {
                    let new = model.edges.insert([s, t]).inserted
                    check(result?.inserted == new && result?.memberAfterInsert == DirectedEdge(from: a, to: b), "insert(safe: \(a)→\(b)) result")
                } else {
                    check(result == nil, "insert(safe: \(a)→\(b)) with a non-vertex did not return nil")
                }
                log.append("insert(safe: \(a)→\(b))")
            case 10 ..< 13:
                let result = graph.remove(edge: DirectedEdge(from: a, to: b))
                var removed = false
                if let s = model.index(of: a), let t = model.index(of: b) { removed = model.edges.remove([s, t]) != nil }
                check((result != nil) == removed && (result == nil || result == DirectedEdge(from: a, to: b)), "remove(edge: \(a)→\(b)) result")
                log.append("remove(edge: \(a)→\(b))")
            case 13:
                graph.removeAllEdges(keepingCapacity: a % 2 == 0)
                model.edges = []
                log.append("removeAllEdges")
            case 14:
                if b % 3 == 0 {
                    graph.removeAll(keepingCapacity: a % 2 == 0)
                    model = Model()
                    log.append("removeAll")
                } else {
                    graph.reserveCapacity(vertexCount: model.labels.count + (a - 1000) / 37)
                    log.append("reserveCapacity")
                }
            default:
                // A copy must not change while the graph does.
                let copy = graph, copyModel = model
                graph.insert(edge: DirectedEdge(from: b, to: a))
                let s = model.insert(b).index, t = model.insert(a).index
                model.edges.insert([s, t])
                checkMatrix(copy, copyModel, "snapshot after \(log.suffix(6).joined(separator: "; "))")
                log.append("snapshot, insert(edge: \(b)→\(a))")
            }
            let context = "after \(log.suffix(8).joined(separator: "; "))"
            checkMatrix(graph, model, context)
            if steps % 8 == 0 {
                checkAlgorithms(graph, context)
                checkEquality(model, &input, context)
                checkDecoding(model, corruption: input.int(below: 6), context)
            }
        }
    }
}
