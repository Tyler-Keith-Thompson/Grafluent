// UndirectedIncidenceList and IncidenceList against a written-out model, and IncidenceMatrix and
// OrientedIncidenceMatrix against the lists. The model is the vertices in index order (the listed
// vertices first, then each new member by first appearance, sources before targets) and each
// hyperedge as ascending vertex indices (both sides when directed).
//
// A build step reads listed vertices and hyperedges (repeated members, empty hyperedges and
// repeated hyperedges included), with vertices that are either the identity `0..<n` or labels far
// from their indices, and builds the list in bulk, from the hyperedges alone when nothing is
// listed, and one call at a time. A mutation step runs a random sequence of `insert(_:)`,
// `insert(hyperedge:)` / `insert(sources:targets:)`, the `safe:` spellings (with a non-vertex
// sometimes) and `removeAll`. After each step the whole state is compared: vertices both ways,
// rows by position and by vertex, degrees, sizes, membership of every vertex and of every
// hyperedge (and of near misses), the incidence numbers, and the `safe:` spellings.
//
// Every state then checks the algorithms against direct computations on the model: neighbors,
// rank, uniformity, the histograms, the dual, the clique expansions, the s-line graph,
// components and s-components; for a directed hypergraph the classes, reversal, weak and strong
// components (by reachability on the incidence graph), and B- and F-connection against the
// fixpoint of Gallo et al.'s definition (a hyperedge with at least one source fires once all of
// its sources are reached and reaches its targets; F is the same on the symmetric image). The
// incidence-graph views must equal their copies into an adjacency list (rows, edge positions,
// components). The matrices built from the list must answer the same, cell edits on them must
// track a set of cells, and equality and hashing must ignore vertex and hyperedge order.
//
// Decoding: Foundation's coders are not available to this toolchain against the SDK, so a
// minimal in-memory decoder hands `init(from:)` the stored arrays. A valid payload must decode
// to the same value; a hostile one (a repeated vertex, an index out of range or negative, a row
// not strictly ascending, sides of different lengths, a negative vertex count, a shape over the
// limit or one whose cell count overflows) must throw, never trap.

import AdjacencyListModule
import Connectivity
import FuzzSupport
import GraphProtocols
import Hypergraphs
import IncidenceMatrixModule

/// A decoder over one keyed payload: the generic `decode` hands back the stored value when its
/// type matches, so no nested containers are needed.
struct PayloadDecoder: Decoder {
    let values: [String: Any]
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var codingPath: [any CodingKey] { [] }
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

/// Plain union–find for the model's components.
struct Groups {
    var parent: [Int]
    init(_ n: Int) { parent = Array(0 ..< n) }
    mutating func find(_ x: Int) -> Int {
        var x = x
        while parent[x] != x { x = parent[x] }
        return x
    }
    mutating func union(_ a: Int, _ b: Int) {
        let ra = find(a), rb = find(b)
        if ra != rb { parent[max(ra, rb)] = min(ra, rb) }
    }
    /// The groups, ordered by least element, each ascending.
    mutating func groups() -> [[Int]] {
        var byRoot: [Int: [Int]] = [:]
        for x in 0 ..< parent.count { byRoot[find(x), default: []].append(x) }
        return byRoot.values.sorted { $0[0] < $1[0] }
    }
}

/// Whether the decoding throws (a trap is a crash the fuzzer reports).
func throwsOnDecode<T: Decodable>(_ type: T.Type, _ decoder: PayloadDecoder) -> Bool {
    do {
        _ = try T(from: decoder)
        return false
    } catch {
        return true
    }
}

@main
enum FuzzHypergraphs {
    static func main() { runFuzzer(fuzz) }

    static let outsider = -5

    /// Vertex `k`: `k` itself in identity mode, a label far from `k` otherwise.
    static func vertex(_ k: Int, identity: Bool) -> Int { identity ? k : 1000 + 37 * k }

    static func fuzz(_ input: inout FuzzInput) {
        if input.int(below: 2) == 0 {
            undirected(&input)
        } else {
            directed(&input)
        }
    }

    // MARK: - Undirected

    struct Model {
        var vertices: [Int] = []
        var rows: [[Int]] = []

        func index(of v: Int) -> Int? { vertices.firstIndex(of: v) }
        mutating func insert(_ v: Int) -> Int {
            if let i = index(of: v) { return i }
            vertices.append(v)
            return vertices.count - 1
        }
        mutating func insert(hyperedge members: [Int]) -> Int {
            rows.append(Array(Set(members.map { insert($0) })).sorted())
            return rows.count - 1
        }
        func incident(_ i: Int) -> [Int] { rows.indices.filter { rows[$0].contains(i) } }
    }

    static func readMembers(_ input: inout FuzzInput, identity: Bool, universe: Int = 10) -> [Int] {
        (0 ..< input.int(in: 0 ... 4)).map { _ in vertex(input.int(below: universe), identity: identity) }
    }

    static func undirected(_ input: inout FuzzInput) {
        let identity = input.int(below: 2) == 0
        var model = Model()
        let listed = (0 ..< input.int(in: 0 ... 4)).map { _ in vertex(input.int(below: 10), identity: identity) }
        for v in listed { _ = model.insert(v) }
        var hyperedges: [[Int]] = []
        for _ in 0 ..< input.int(in: 0 ... 6) {
            let members = readMembers(&input, identity: identity)
            hyperedges.append(members)
            _ = model.insert(hyperedge: members)
        }
        var list = UndirectedIncidenceList<Int>(vertices: listed, hyperedges: hyperedges)
        checkUndirected(list, model, "bulk build")
        if listed.isEmpty {
            let fromHyperedges = UndirectedIncidenceList<Int>(hyperedges: hyperedges)
            check(fromHyperedges.vertices.elements == list.vertices.elements && fromHyperedges == list, "init(hyperedges:)")
        }
        var stepwise = UndirectedIncidenceList<Int>(vertices: listed)
        for members in hyperedges { _ = stepwise.insert(hyperedge: members) }
        check(stepwise.vertices.elements == list.vertices.elements && stepwise == list && stepwise.hashValue == list.hashValue, "one call at a time")
        check(UndirectedIncidenceList(list.incidenceGraph.base) == list, "init(_:) of itself")

        for step in 0 ..< input.int(in: 0 ... 8) {
            switch input.int(below: 8) {
            case 0:
                let v = vertex(input.int(below: 12), identity: identity)
                let fresh = model.index(of: v) == nil
                _ = model.insert(v)
                let result = list.insert(v)
                check(result.inserted == fresh && result.memberAfterInsert == v, "insert(\(v))")
            case 1, 2, 3:
                let members = readMembers(&input, identity: identity, universe: 12)
                let expected = model.insert(hyperedge: members)
                check(list.insert(hyperedge: members) == expected, "insert(hyperedge: \(members))")
            case 4, 5:
                var members = readMembers(&input, identity: identity, universe: 12)
                if input.int(below: 3) == 0 { members.append(outsider) }
                let valid = members.allSatisfy { model.index(of: $0) != nil }
                let position = list.insert(safe: members)
                if valid {
                    check(position == model.insert(hyperedge: members), "insert(safe: \(members))")
                } else {
                    check(position == nil, "insert(safe: \(members)) with a non-vertex")
                }
            case 6:
                if input.int(below: 4) == 0 {
                    list.removeAll(keepingCapacity: input.int(below: 2) == 0)
                    model = Model()
                }
            default:
                list.reserveCapacity(vertexCount: input.int(below: 20), hyperedgeCount: input.int(below: 20), incidenceCount: input.int(below: 40))
            }
            checkUndirected(list, model, "after step \(step)")
        }
        undirectedAlgorithms(list, model)
        undirectedViews(list, model)
        incidenceMatrix(list, model, &input)
        undirectedValue(list, model, &input)
    }

    static func checkUndirected(_ list: UndirectedIncidenceList<Int>, _ model: Model, _ context: String) {
        let n = model.vertices.count, m = model.rows.count
        check(list.vertices.elements == model.vertices, "vertices \(list.vertices.elements), expected \(model.vertices) \(context)")
        check(list.vertexCount == n && list.vertexIndexBound == n && list.hyperedgeCount == m && list.hyperedgeIndexBound == m, "counts \(context)")
        check(list.hyperedges.count == m, "hyperedges.count \(context)")
        var incidence = 0
        for p in 0 ..< m {
            let row = model.rows[p]
            check(Array(list.memberIndices(ofHyperedgeAt: p)) == row, "memberIndices(ofHyperedgeAt: \(p)) \(Array(list.memberIndices(ofHyperedgeAt: p))), expected \(row) \(context)")
            check(Array(list.members(ofHyperedgeAt: p)) == row.map { model.vertices[$0] }, "members(ofHyperedgeAt: \(p)) \(context)")
            check(Array(list.hyperedges[p]) == row.map { model.vertices[$0] }, "hyperedges[\(p)] \(context)")
            check(list.size(ofHyperedgeAt: p) == row.count && list.hyperedgeIndex(of: p) == p, "size(ofHyperedgeAt: \(p)) \(context)")
            check(list.contains(hyperedge: row.map { model.vertices[$0] }.reversed()), "contains(hyperedge:) of \(p) \(context)")
            incidence += row.count
        }
        check(list.incidenceGraph.edgeCount == incidence, "incidence count \(context)")
        for (i, v) in model.vertices.enumerated() {
            let incident = model.incident(i)
            check(list.vertexIndex(of: v) == i && list.vertexIndex(safe: v) == i && list.vertex(atIndex: i) == v && list.contains(v), "index of \(v) \(context)")
            check(Array(list.incidentHyperedges(of: v)) == incident && Array(list.incidentHyperedges(ofIndex: i)) == incident, "incidentHyperedges(of: \(v)) \(context)")
            check(list.incidentHyperedges(safe: v).map(Array.init) == incident, "incidentHyperedges(safe: \(v)) \(context)")
            check(list.degree(of: v) == incident.count && list.degree(ofIndex: i) == incident.count && list.degree(safe: v) == incident.count, "degree(of: \(v)) \(context)")
        }
        for v in [outsider, vertex(40, identity: false), n] where model.index(of: v) == nil {
            check(!list.contains(v) && list.vertexIndex(safe: v) == nil && list.incidentHyperedges(safe: v) == nil && list.degree(safe: v) == nil, "non-vertex \(v) \(context)")
            check(!list.contains(hyperedge: [v]), "contains(hyperedge: [\(v)]) \(context)")
        }
        check(list.contains(hyperedge: [] as [Int]) == model.rows.contains([]), "contains(hyperedge: []) \(context)")
        // Near misses: each hyperedge with a vertex added or removed.
        for row in model.rows {
            if !row.isEmpty {
                let fewer = Array(row.dropLast())
                check(list.contains(hyperedge: fewer.map { model.vertices[$0] }) == model.rows.contains(fewer), "contains(hyperedge:) one fewer \(context)")
            }
            for extra in 0 ..< n where !row.contains(extra) {
                let more = (row + [extra]).sorted()
                check(list.contains(hyperedge: more.map { model.vertices[$0] }) == model.rows.contains(more), "contains(hyperedge:) one more \(context)")
                break
            }
        }
    }

    static func undirectedAlgorithms(_ list: UndirectedIncidenceList<Int>, _ model: Model) {
        let n = model.vertices.count, m = model.rows.count
        for (i, v) in model.vertices.enumerated() {
            let expected = Set(model.incident(i).flatMap { model.rows[$0] }).subtracting([i]).sorted().map { model.vertices[$0] }
            check(list.neighbors(of: v) == expected, "neighbors(of: \(v))")
        }
        let sizes = model.rows.map(\.count)
        check(list.rank == (sizes.max() ?? 0), "rank")
        for k in 0 ... 5 { check(list.isUniform(size: k) == sizes.allSatisfy { $0 == k }, "isUniform(size: \(k))") }
        func histogram(_ values: [Int]) -> [Int] {
            guard let top = values.max() else { return [] }
            return (0 ... top).map { d in values.filter { $0 == d }.count }
        }
        check(list.degreeHistogram() == histogram((0 ..< n).map { model.incident($0).count }), "degreeHistogram")
        check(list.hyperedgeSizeHistogram() == histogram(sizes), "hyperedgeSizeHistogram")
        // The dual: the transpose, over the positions.
        let dual = list.dual()
        check(dual.vertices.elements == Array(0 ..< m) && dual.hyperedgeCount == n, "dual shape")
        for i in 0 ..< n { check(Array(dual.memberIndices(ofHyperedgeAt: i)) == model.incident(i), "dual hyperedge \(i)") }
        let twice = dual.dual()
        check(twice.vertices.elements == Array(0 ..< n), "dual of the dual: vertices")
        for p in 0 ..< m { check(Array(twice.memberIndices(ofHyperedgeAt: p)) == model.rows[p], "dual of the dual: hyperedge \(p)") }
        // The clique expansion.
        var pairs = Set<[Int]>()
        for row in model.rows { for a in row { for b in row where a < b { pairs.insert([a, b]) } } }
        let expansion = list.cliqueExpansion()
        check(Array(expansion.vertices) == model.vertices, "cliqueExpansion vertices")
        let expansionEdges = expansion.edges.map { [expansion.vertexIndex(of: $0.u), expansion.vertexIndex(of: $0.v)].sorted() }
        check(expansionEdges == pairs.sorted { $0[0] != $1[0] ? $0[0] < $1[0] : $0[1] < $1[1] }, "cliqueExpansion edges \(expansionEdges)")
        for pair in pairs { check(expansion.contains(edge: UndirectedEdge(model.vertices[pair[1]], model.vertices[pair[0]])), "cliqueExpansion contains \(pair)") }
        // The s-line graph and s-components.
        for s in 1 ... 3 {
            var overlaps: [[Int]] = []
            var groups = Groups(m)
            for p in 0 ..< m {
                for q in p + 1 ..< max(m, p + 1) where Set(model.rows[p]).intersection(model.rows[q]).count >= s {
                    overlaps.append([p, q])
                    groups.union(p, q)
                }
            }
            let line = list.lineGraph(s: s)
            check(Array(line.vertices) == Array(0 ..< m), "lineGraph(s: \(s)) vertices")
            check(line.edges.map { [$0.u, $0.v].sorted() } == overlaps, "lineGraph(s: \(s)) edges")
            for pair in overlaps { check(line.contains(edge: UndirectedEdge(pair[1], pair[0])), "lineGraph(s: \(s)) contains \(pair)") }
            check(list.sConnectedComponents(s: s) == groups.groups(), "sConnectedComponents(s: \(s))")
        }
        var groups = Groups(n)
        for row in model.rows { for i in row.dropFirst() { groups.union(row[0], i) } }
        let components = groups.groups()
        check(list.connectedComponents() == components.map { $0.map { model.vertices[$0] } }, "connectedComponents")
        check(list.isConnected == (components.count == 1), "isConnected")
    }

    static func undirectedViews(_ list: UndirectedIncidenceList<Int>, _ model: Model) {
        let n = model.vertices.count, m = model.rows.count
        let view = list.incidenceGraph
        let copy = UndirectedAdjacencyList<Int>(vertices: view.vertices, edges: view.edges)
        check(view.vertexCount == n + m && view.vertexIndexBound == n + m && view.edgeCount == model.rows.reduce(0) { $0 + $1.count }, "view counts")
        var q = 0
        for p in 0 ..< m {
            for i in model.rows[p] {
                check(view.edges[q] == UndirectedEdge(i, n + p) && view.endpointIndices(ofEdgeAt: q) == (i, n + p), "view edge \(q)")
                check(view.oppositeVertex(to: i, acrossEdgeAt: q) == n + p && view.oppositeVertex(to: n + p, acrossEdgeAt: q) == i, "view opposite \(q)")
                check(view.edgeIndex(of: q) == q, "view edgeIndex \(q)")
                q += 1
            }
        }
        var first = 0
        for p in 0 ..< m {
            check(Array(view.incidentEdges(of: n + p)) == Array(first ..< first + model.rows[p].count), "view incidence numbers of hyperedge \(p)")
            first += model.rows[p].count
        }
        for i in 0 ..< n {
            check(view.incidentEdges(of: i).map { view.endpointIndices(ofEdgeAt: $0).v - n } == model.incident(i), "view incidence numbers of vertex \(i)")
        }
        for x in 0 ..< n + m {
            let expected = x < n ? model.incident(x).map { n + $0 } : model.rows[x - n]
            check(Array(view.neighbors(of: x)) == expected && Array(view.neighborIndices(ofIndex: x)) == expected, "view neighbors(of: \(x))")
            check(Array(view.neighbors(of: x)) == Array(copy.neighbors(of: x)), "view row \(x) against the copy")
            check(Array(view.incidentEdges(of: x)) == Array(copy.incidentEdges(of: x)), "view incidentEdges(of: \(x)) against the copy")
            check(Array(view.incidentEdgeIndices(ofIndex: x)) == Array(copy.incidentEdgeIndices(ofIndex: x)), "view incidentEdgeIndices(ofIndex: \(x))")
            check(view.degree(of: x) == expected.count && view.degree(ofIndex: x) == expected.count, "view degree(of: \(x))")
            check(view.contains(x) && view.vertexIndex(of: x) == x && view.vertex(atIndex: x) == x, "view vertex \(x)")
            for y in 0 ..< n + m {
                check(view.contains(edge: UndirectedEdge(x, y)) == copy.contains(edge: UndirectedEdge(x, y)), "view contains(edge: \(x)–\(y))")
            }
        }
        check(!view.contains(-1) && !view.contains(n + m), "view contains out of range")
        check(view.connectedComponents().map { Array($0) } == copy.connectedComponents().map { Array($0) }, "view components")
        check(view.bridges() == copy.bridges() && view.articulationPoints() == copy.articulationPoints(), "view bridges and cut vertices")
    }

    // MARK: - IncidenceMatrix

    static func incidenceMatrix(_ list: UndirectedIncidenceList<Int>, _ model: Model, _ input: inout FuzzInput) {
        let n = model.vertices.count, m = model.rows.count
        var matrix = IncidenceMatrix(list)
        var cells = Set<[Int]>()
        for (p, row) in model.rows.enumerated() { for i in row { cells.insert([i, p]) } }
        check(matrix == IncidenceMatrix(vertexCount: n, hyperedges: model.rows), "IncidenceMatrix(_:) equals init(vertexCount:hyperedges:)")
        var appended = IncidenceMatrix(vertexCount: n)
        for row in model.rows { _ = appended.insert(hyperedge: row + row) }
        check(appended == matrix && appended.hashValue == matrix.hashValue, "one column at a time")
        checkMatrix(matrix, n, m, cells, "from the list")
        // The algorithms agree with the list's.
        check(matrix.connectedComponents() == list.connectedComponents().map { $0.map { list.vertexIndex(of: $0) } }, "matrix components")
        check(matrix.isConnected == list.isConnected && matrix.rank == list.rank, "matrix isConnected, rank")
        check(matrix.degreeHistogram() == list.degreeHistogram() && matrix.hyperedgeSizeHistogram() == list.hyperedgeSizeHistogram(), "matrix histograms")
        for s in 1 ... 2 {
            check(matrix.lineGraph(s: s).edges.elementsEqual(list.lineGraph(s: s).edges), "matrix lineGraph(s: \(s))")
            check(matrix.sConnectedComponents(s: s) == list.sConnectedComponents(s: s), "matrix sConnectedComponents(s: \(s))")
        }
        check(matrix.cliqueExpansion().edges.map { [$0.u, $0.v] } == list.cliqueExpansion().edges.map { [list.vertexIndex(of: $0.u), list.vertexIndex(of: $0.v)] }, "matrix cliqueExpansion")
        check(UndirectedIncidenceList(matrix.transposed()) == list.dual(), "transposed() is the dual")
        check(matrix.transposed().transposed() == matrix, "transposed() twice")
        // The view over the matrix, through the protocol's computed incidence numbers.
        let view = matrix.incidenceGraph, listView = list.incidenceGraph
        check(Array(view.edges) == Array(listView.edges), "matrix view edges")
        for x in 0 ..< n + m {
            check(Array(view.neighbors(of: x)) == Array(listView.neighbors(of: x)), "matrix view neighbors(of: \(x))")
            check(Array(view.incidentEdges(of: x)) == Array(listView.incidentEdges(of: x)), "matrix view incidentEdges(of: \(x))")
            check(view.degree(of: x) == listView.degree(of: x), "matrix view degree(of: \(x))")
        }
        check(view.connectedComponents().map { Array($0) } == listView.connectedComponents().map { Array($0) }, "matrix view components")
        // Cell edits against the set.
        var columns = m
        var rows = n
        var grown = false
        for _ in 0 ..< input.int(in: 0 ... 10) {
            switch input.int(below: 5) {
            case 0:
                if rows > 0, columns > 0 {
                    let v = input.int(below: rows), p = input.int(below: columns)
                    check(matrix.insert(v, intoHyperedgeAt: p) == cells.insert([v, p]).inserted, "insert(\(v), intoHyperedgeAt: \(p))")
                }
            case 1:
                if rows > 0, columns > 0 {
                    let v = input.int(below: rows), p = input.int(below: columns)
                    check(matrix.remove(v, fromHyperedgeAt: p) == (cells.remove([v, p]) != nil), "remove(\(v), fromHyperedgeAt: \(p))")
                }
            case 2:
                check(matrix.appendVertex() == rows, "appendVertex")
                rows += 1
            case 3:
                let members = rows == 0 ? [] : (0 ..< input.int(in: 0 ... 3)).map { _ in input.int(below: rows) }
                check(matrix.insert(hyperedge: members) == columns, "insert(hyperedge:)")
                for v in members { cells.insert([v, columns]) }
                columns += 1
            default:
                // Grow past a word of columns or rows once, so the strides move.
                guard !grown else { break }
                grown = true
                for _ in 0 ..< input.int(below: 70) { _ = matrix.appendVertex(); rows += 1 }
                for _ in 0 ..< input.int(below: 70) { _ = matrix.insert(hyperedge: [] as [Int]); columns += 1 }
            }
        }
        checkMatrix(matrix, rows, columns, cells, "after cell edits")
        let rebuilt = IncidenceMatrix(vertexCount: rows, hyperedges: (0 ..< columns).map { p in cells.filter { $0[1] == p }.map { $0[0] } })
        check(rebuilt == matrix && rebuilt.hashValue == matrix.hashValue, "equal to a fresh build, whatever the strides")
        // Codable.
        check(decodeMatrix(["vertexCount": rows, "hyperedges": (0 ..< columns).map { Array(matrix.members(ofHyperedgeAt: $0)) }]) == matrix, "matrix decodes")
        hostileMatrix(&input, rows: rows, columns: columns)
    }

    static func checkMatrix(_ matrix: IncidenceMatrix, _ n: Int, _ m: Int, _ cells: Set<[Int]>, _ context: String) {
        check(matrix.vertexCount == n && matrix.hyperedgeCount == m && matrix.vertices == 0 ..< n && matrix.hyperedges.count == m, "matrix shape \(context)")
        check(matrix.incidenceGraph.edgeCount == cells.count, "matrix cell count \(context)")
        for p in 0 ..< m {
            let column = (0 ..< n).filter { cells.contains([$0, p]) }
            check(Array(matrix.members(ofHyperedgeAt: p)) == column && Array(matrix.memberIndices(ofHyperedgeAt: p)) == column, "matrix column \(p) \(context)")
            check(Array(matrix.hyperedges[p]) == column && matrix.size(ofHyperedgeAt: p) == column.count, "matrix hyperedges[\(p)] \(context)")
            check(matrix.contains(hyperedge: column.reversed()), "matrix contains column \(p) \(context)")
        }
        for v in 0 ..< n {
            let row = (0 ..< m).filter { cells.contains([v, $0]) }
            check(Array(matrix.incidentHyperedges(of: v)) == row && Array(matrix.incidentHyperedges(ofIndex: v)) == row, "matrix row \(v) \(context)")
            check(matrix.degree(of: v) == row.count && matrix.degree(ofIndex: v) == row.count, "matrix degree(of: \(v)) \(context)")
            check(matrix.contains(v) && matrix.vertexIndex(of: v) == v && matrix.vertex(atIndex: v) == v, "matrix vertex \(v) \(context)")
            for p in 0 ..< m { check(matrix[vertex: v, hyperedge: p] == cells.contains([v, p]), "matrix cell (\(v), \(p)) \(context)") }
        }
        check(!matrix.contains(-1) && !matrix.contains(n) && !matrix.contains(hyperedge: [n]) && !matrix.contains(hyperedge: [-1]), "matrix out of range \(context)")
        let hasEmpty = (0 ..< m).contains { p in !cells.contains { $0[1] == p } }
        check(matrix.contains(hyperedge: [] as [Int]) == hasEmpty, "matrix contains the empty column \(context)")
    }

    static func decodeMatrix(_ values: [String: Any], limit: Int? = nil) -> IncidenceMatrix? {
        var decoder = PayloadDecoder(values: values)
        if let limit { decoder.userInfo[IncidenceMatrix.maximumDecodedCellCountKey] = limit }
        return try? IncidenceMatrix(from: decoder)
    }

    static func hostileMatrix(_ input: inout FuzzInput, rows n: Int, columns m: Int) {
        let k = input.int(below: 6)
        let members = (0 ..< input.int(in: 0 ... 3)).map { _ in input.int(in: -2 ... 9) }
        var hyperedges = (0 ..< m).map { _ in [Int]() }
        hyperedges.append(members)
        let ascendingInRange = zip(members, members.dropFirst()).allSatisfy { $0 < $1 } && members.allSatisfy { $0 >= 0 && $0 < n }
        switch k {
        case 0:
            let decoded = decodeMatrix(["vertexCount": n, "hyperedges": hyperedges])
            check((decoded != nil) == ascendingInRange, "matrix decoding of \(members) over \(n) vertices")
            let oriented = decodeOriented(["vertexCount": n, "sources": hyperedges, "targets": hyperedges.reversed() as [[Int]]])
            check((oriented != nil) == ascendingInRange, "oriented decoding of \(members) over \(n) vertices")
        case 1:
            check(decodeMatrix(["vertexCount": -1 - input.int(below: 4), "hyperedges": [[Int]]()]) == nil, "negative vertex count")
            check(decodeOriented(["vertexCount": -1, "sources": [[Int]](), "targets": [[Int]]()]) == nil, "oriented negative vertex count")
        case 2:
            let limit = input.int(below: 12)
            let shapeN = input.int(below: 5), shapeM = input.int(below: 5)
            let payload: [String: Any] = ["vertexCount": shapeN, "hyperedges": Array(repeating: [Int](), count: shapeM)]
            check((decodeMatrix(payload, limit: limit) != nil) == (shapeN * shapeM <= limit), "limit \(limit) for \(shapeN) × \(shapeM)")
            var decoder = PayloadDecoder(values: ["vertexCount": shapeN, "sources": Array(repeating: [Int](), count: shapeM), "targets": Array(repeating: [Int](), count: shapeM)])
            decoder.userInfo[IncidenceMatrix.maximumDecodedCellCountKey] = limit
            check(throwsOnDecode(OrientedIncidenceMatrix.self, decoder) == (shapeN * shapeM > limit), "oriented limit \(limit) for \(shapeN) × \(shapeM)")
        case 3:
            check(decodeMatrix(["vertexCount": Int.max / (1 + input.int(below: 3)), "hyperedges": [[Int]](repeating: [], count: 2 + input.int(below: 3))]) == nil, "overflowing shape")
            check(decodeMatrix(["vertexCount": 1 << 20, "hyperedges": [[Int]](repeating: [], count: 1 << 9)]) == nil, "shape over the default limit")
        case 4:
            check(decodeOriented(["vertexCount": n, "sources": hyperedges, "targets": Array(hyperedges.dropLast())]) == nil, "oriented sides of different lengths")
        default:
            check(decodeMatrix(["vertexCount": n]) == nil && decodeMatrix(["hyperedges": hyperedges]) == nil, "missing keys")
        }
    }

    static func decodeOriented(_ values: [String: Any]) -> OrientedIncidenceMatrix? {
        try? OrientedIncidenceMatrix(from: PayloadDecoder(values: values))
    }

    // MARK: - Undirected equality, hashing, Codable

    static func undirectedValue(_ list: UndirectedIncidenceList<Int>, _ model: Model, _ input: inout FuzzInput) {
        let n = model.vertices.count, m = model.rows.count
        // Another vertex order and another hyperedge order.
        var order = Array(0 ..< n)
        var hyperedgeOrder = Array(0 ..< m)
        for k in 0 ..< n { order.swapAt(k, k + input.int(below: n - k)) }
        for k in 0 ..< m { hyperedgeOrder.swapAt(k, k + input.int(below: m - k)) }
        let shuffled = UndirectedIncidenceList(vertices: order.map { model.vertices[$0] }, hyperedges: hyperedgeOrder.map { model.rows[$0].map { model.vertices[$0] } })
        check(shuffled == list && list == shuffled && shuffled.hashValue == list.hashValue, "equality under reordering")
        var more = list
        _ = more.insert(hyperedge: model.rows.first.map { $0.map { model.vertices[$0] } } ?? [])
        check(more != list, "one hyperedge more")
        if let row = model.rows.first(where: { !$0.isEmpty }), n > 1 {
            let other = (0 ..< n).first { !row.contains($0) } ?? row[0]
            var rows = model.rows
            rows[rows.firstIndex(of: row)!] = Array(Set(row.dropLast() + [other])).sorted()
            let changed = UndirectedIncidenceList(vertices: model.vertices, hyperedges: rows.map { $0.map { model.vertices[$0] } })
            check((changed == list) == (rows.sorted { $0.lexicographicallyPrecedes($1) } == model.rows.sorted { $0.lexicographicallyPrecedes($1) }), "one member changed")
        }
        // Codable.
        let decoder = PayloadDecoder(values: ["vertices": model.vertices, "hyperedges": model.rows])
        let decoded = try? UndirectedIncidenceList<Int>(from: decoder)
        check(decoded.map { $0.vertices.elements == model.vertices && $0 == list } == true, "decodes")
        var rows = model.rows
        let hostile = input.int(below: 5)
        var vertices = model.vertices
        switch hostile {
        case 0:
            guard let first = vertices.first else { return }
            vertices.append(first)
        case 1:
            rows.append([n + input.int(below: 3)])
        case 2:
            rows.append([-1 - input.int(below: 3)])
        case 3:
            guard n > 0 else { return }
            let i = input.int(below: n)
            rows.append([i, i])
        default:
            guard n > 1 else { return }
            rows.append([1, 0])
        }
        check(throwsOnDecode(UndirectedIncidenceList<Int>.self, PayloadDecoder(values: ["vertices": vertices, "hyperedges": rows])), "hostile payload \(hostile) decoded")
    }

    // MARK: - Directed

    struct DirectedModel {
        var vertices: [Int] = []
        var sources: [[Int]] = []
        var targets: [[Int]] = []

        func index(of v: Int) -> Int? { vertices.firstIndex(of: v) }
        mutating func insert(_ v: Int) -> Int {
            if let i = index(of: v) { return i }
            vertices.append(v)
            return vertices.count - 1
        }
        mutating func insert(sources s: [Int], targets t: [Int]) -> Int {
            let si = s.map { insert($0) }, ti = t.map { insert($0) }
            sources.append(Array(Set(si)).sorted())
            targets.append(Array(Set(ti)).sorted())
            return sources.count - 1
        }
        func outStar(_ i: Int) -> [Int] { sources.indices.filter { sources[$0].contains(i) } }
        func inStar(_ i: Int) -> [Int] { targets.indices.filter { targets[$0].contains(i) } }

        /// Gallo et al.'s B-connection as a fixpoint: from `start`, every hyperedge with at least
        /// one source, all reached, reaches its targets; `backward` reads the symmetric image.
        func fixpoint(from start: Int, backward: Bool) -> Set<Int> {
            var reached: Set<Int> = [start]
            var changed = true
            while changed {
                changed = false
                for p in sources.indices {
                    let tail = backward ? targets[p] : sources[p], head = backward ? sources[p] : targets[p]
                    if !tail.isEmpty, tail.allSatisfy(reached.contains), !head.allSatisfy(reached.contains) {
                        reached.formUnion(head)
                        changed = true
                    }
                }
            }
            return reached
        }
    }

    static func directed(_ input: inout FuzzInput) {
        let identity = input.int(below: 2) == 0
        var model = DirectedModel()
        let listed = (0 ..< input.int(in: 0 ... 4)).map { _ in vertex(input.int(below: 10), identity: identity) }
        for v in listed { _ = model.insert(v) }
        var hyperedges: [(sources: [Int], targets: [Int])] = []
        for _ in 0 ..< input.int(in: 0 ... 6) {
            let s = readMembers(&input, identity: identity), t = readMembers(&input, identity: identity)
            hyperedges.append((s, t))
            _ = model.insert(sources: s, targets: t)
        }
        var list = IncidenceList<Int>(vertices: listed, hyperedges: hyperedges)
        checkDirected(list, model, "bulk build")
        if listed.isEmpty {
            check(IncidenceList<Int>(hyperedges: hyperedges).vertices.elements == model.vertices, "init(hyperedges:)")
        }
        var stepwise = IncidenceList<Int>(vertices: listed)
        for h in hyperedges { _ = stepwise.insert(sources: h.sources, targets: h.targets) }
        check(stepwise.vertices.elements == list.vertices.elements && stepwise == list && stepwise.hashValue == list.hashValue, "one call at a time")

        for step in 0 ..< input.int(in: 0 ... 8) {
            switch input.int(below: 8) {
            case 0:
                let v = vertex(input.int(below: 12), identity: identity)
                let fresh = model.index(of: v) == nil
                _ = model.insert(v)
                let result = list.insert(v)
                check(result.inserted == fresh && result.memberAfterInsert == v, "insert(\(v))")
            case 1, 2, 3:
                let s = readMembers(&input, identity: identity, universe: 12), t = readMembers(&input, identity: identity, universe: 12)
                let expected = model.insert(sources: s, targets: t)
                check(list.insert(sources: s, targets: t) == expected, "insert(sources: \(s), targets: \(t))")
            case 4, 5:
                var s = readMembers(&input, identity: identity, universe: 12), t = readMembers(&input, identity: identity, universe: 12)
                switch input.int(below: 4) {
                case 0: s.append(outsider)
                case 1: t.append(outsider)
                default: break
                }
                let valid = (s + t).allSatisfy { model.index(of: $0) != nil }
                let position = list.insert(safe: s, targets: t)
                if valid {
                    check(position == model.insert(sources: s, targets: t), "insert(safe: \(s), targets: \(t))")
                } else {
                    check(position == nil, "insert(safe: \(s), targets: \(t)) with a non-vertex")
                }
            case 6:
                if input.int(below: 4) == 0 {
                    list.removeAll(keepingCapacity: input.int(below: 2) == 0)
                    model = DirectedModel()
                }
            default:
                list.reserveCapacity(vertexCount: input.int(below: 20), hyperedgeCount: input.int(below: 20), sourceCount: input.int(below: 40), targetCount: input.int(below: 40))
            }
            checkDirected(list, model, "after step \(step)")
        }
        directedAlgorithms(list, model)
        directedView(list, model)
        orientedMatrix(list, model, &input)
        directedValue(list, model, &input)
    }

    static func checkDirected(_ list: IncidenceList<Int>, _ model: DirectedModel, _ context: String) {
        let n = model.vertices.count, m = model.sources.count
        check(list.vertices.elements == model.vertices, "vertices \(list.vertices.elements), expected \(model.vertices) \(context)")
        check(list.vertexCount == n && list.vertexIndexBound == n && list.hyperedgeCount == m && list.hyperedgeIndexBound == m && list.hyperedges.count == m, "counts \(context)")
        var offsets = (0, 0)
        for p in 0 ..< m {
            let s = model.sources[p], t = model.targets[p]
            check(Array(list.sourceIndices(ofHyperedgeAt: p)) == s && Array(list.targetIndices(ofHyperedgeAt: p)) == t, "sides of \(p) \(context)")
            check(Array(list.sources(ofHyperedgeAt: p)) == s.map { model.vertices[$0] } && Array(list.targets(ofHyperedgeAt: p)) == t.map { model.vertices[$0] }, "sides of \(p) by vertex \(context)")
            check(Array(list.hyperedges[p].sources) == s.map { model.vertices[$0] } && Array(list.hyperedges[p].targets) == t.map { model.vertices[$0] }, "hyperedges[\(p)] \(context)")
            check(list.hyperedgeIndex(of: p) == p, "hyperedgeIndex(of: \(p)) \(context)")
            check(list.contains(sources: s.map { model.vertices[$0] }.reversed(), targets: t.map { model.vertices[$0] }), "contains \(p) \(context)")
            let swapped = list.contains(sources: t.map { model.vertices[$0] }, targets: s.map { model.vertices[$0] })
            check(swapped == model.sources.indices.contains { model.sources[$0] == t && model.targets[$0] == s }, "contains \(p) swapped \(context)")
            offsets.0 += s.count
            offsets.1 += t.count
        }
        check(list.incidenceGraph.edgeCount == offsets.0 + offsets.1, "incidence counts \(context)")
        for (i, v) in model.vertices.enumerated() {
            let out = model.outStar(i), into = model.inStar(i)
            check(list.vertexIndex(of: v) == i && list.vertexIndex(safe: v) == i && list.vertex(atIndex: i) == v && list.contains(v), "index of \(v) \(context)")
            check(Array(list.outHyperedges(of: v)) == out && Array(list.outHyperedges(ofIndex: i)) == out && list.outHyperedges(safe: v).map(Array.init) == out, "outHyperedges(of: \(v)) \(context)")
            check(Array(list.inHyperedges(of: v)) == into && Array(list.inHyperedges(ofIndex: i)) == into && list.inHyperedges(safe: v).map(Array.init) == into, "inHyperedges(of: \(v)) \(context)")
            check(list.outDegree(of: v) == out.count && list.outDegree(ofIndex: i) == out.count && list.outDegree(safe: v) == out.count, "outDegree(of: \(v)) \(context)")
            check(list.inDegree(of: v) == into.count && list.inDegree(ofIndex: i) == into.count && list.inDegree(safe: v) == into.count, "inDegree(of: \(v)) \(context)")
            check(list.degree(of: v) == out.count + into.count, "degree(of: \(v)) \(context)")
        }
        for v in [outsider, vertex(40, identity: false), n] where model.index(of: v) == nil {
            check(!list.contains(v) && list.vertexIndex(safe: v) == nil && list.outHyperedges(safe: v) == nil && list.inHyperedges(safe: v) == nil, "non-vertex \(v) \(context)")
            check(list.outDegree(safe: v) == nil && list.inDegree(safe: v) == nil && !list.contains(sources: [v], targets: [] as [Int]), "non-vertex \(v) degrees \(context)")
        }
        let hasEmpty = model.sources.indices.contains { model.sources[$0].isEmpty && model.targets[$0].isEmpty }
        check(list.contains(sources: [] as [Int], targets: [] as [Int]) == hasEmpty, "contains the empty hyperedge \(context)")
    }

    static func directedAlgorithms(_ list: IncidenceList<Int>, _ model: DirectedModel) {
        let n = model.vertices.count, m = model.sources.count
        // B- and F-connection against the fixpoint.
        for (i, v) in model.vertices.enumerated() {
            let b = model.fixpoint(from: i, backward: false), f = model.fixpoint(from: i, backward: true)
            check(list.bConnectedVertices(from: v) == b.sorted().map { model.vertices[$0] }, "bConnectedVertices(from: \(v))")
            check(list.fConnectedVertices(to: v) == f.sorted().map { model.vertices[$0] }, "fConnectedVertices(to: \(v))")
            check(list.reversed.bConnectedVertices(from: v) == list.fConnectedVertices(to: v), "F-Visit is B-Visit on the reversal, at \(v)")
            for (j, w) in model.vertices.enumerated() {
                check(list.isBConnected(from: v, to: w) == b.contains(j), "isBConnected(from: \(v), to: \(w))")
                check(list.isFConnected(from: w, to: v) == f.contains(j), "isFConnected(from: \(w), to: \(v))")
            }
        }
        // Reversal, the dual and the classes.
        let reversed = list.reversed
        check(reversed.reversed == list && reversed.vertices.elements == model.vertices, "reversed twice")
        for p in 0 ..< m {
            check(Array(reversed.sourceIndices(ofHyperedgeAt: p)) == model.targets[p] && Array(reversed.targetIndices(ofHyperedgeAt: p)) == model.sources[p], "reversed hyperedge \(p)")
        }
        let dual = list.dual()
        check(dual.vertices.elements == Array(0 ..< m) && dual.hyperedgeCount == n, "dual shape")
        for i in 0 ..< n {
            check(Array(dual.sourceIndices(ofHyperedgeAt: i)) == model.outStar(i) && Array(dual.targetIndices(ofHyperedgeAt: i)) == model.inStar(i), "dual hyperedge \(i)")
        }
        check(dual.dual() == IncidenceList(vertices: Array(0 ..< n), hyperedges: (0 ..< m).map { (sources: model.sources[$0], targets: model.targets[$0]) }), "dual of the dual")
        check(list.reversed.dual() == list.dual().reversed, "reversal commutes with the dual")
        check(list.isBHypergraph == model.targets.allSatisfy { $0.count == 1 }, "isBHypergraph")
        check(list.isFHypergraph == model.sources.allSatisfy { $0.count == 1 }, "isFHypergraph")
        check(list.isBFHypergraph == model.sources.indices.allSatisfy { model.targets[$0].count == 1 || model.sources[$0].count == 1 }, "isBFHypergraph")
        func histogram(_ values: [Int]) -> [Int] {
            guard let top = values.max() else { return [] }
            return (0 ... top).map { d in values.filter { $0 == d }.count }
        }
        check(list.outDegreeHistogram() == histogram((0 ..< n).map { model.outStar($0).count }), "outDegreeHistogram")
        check(list.inDegreeHistogram() == histogram((0 ..< n).map { model.inStar($0).count }), "inDegreeHistogram")
        check(list.sourceSizeHistogram() == histogram(model.sources.map(\.count)) && list.targetSizeHistogram() == histogram(model.targets.map(\.count)), "size histograms")
        // The directed clique expansion.
        var arcs = Set<[Int]>()
        for p in 0 ..< m { for u in model.sources[p] { for w in model.targets[p] where u != w { arcs.insert([u, w]) } } }
        let expansion = list.cliqueExpansion()
        check(Array(expansion.vertices) == model.vertices, "cliqueExpansion vertices")
        check(expansion.edges.map { [expansion.vertexIndex(of: $0.source), expansion.vertexIndex(of: $0.target)] } == arcs.sorted { $0[0] != $1[0] ? $0[0] < $1[0] : $0[1] < $1[1] }, "cliqueExpansion arcs")
        for arc in arcs {
            check(expansion.contains(edge: DirectedEdge(from: model.vertices[arc[0]], to: model.vertices[arc[1]])), "cliqueExpansion contains \(arc)")
            check(expansion.predecessors(of: model.vertices[arc[1]]).contains(model.vertices[arc[0]]), "cliqueExpansion predecessors \(arc)")
        }
        // Weak components, and strong components by reachability on the incidence graph.
        var groups = Groups(n)
        for p in 0 ..< m {
            let all = model.sources[p] + model.targets[p]
            for i in all.dropFirst() { groups.union(all[0], i) }
        }
        let weak = groups.groups()
        check(list.weaklyConnectedComponents() == weak.map { $0.map { model.vertices[$0] } }, "weaklyConnectedComponents")
        check(list.isWeaklyConnected == (weak.count == 1), "isWeaklyConnected")
        var successors = [[Int]](repeating: [], count: n + m)
        for p in 0 ..< m {
            for i in model.sources[p] { successors[i].append(n + p) }
            successors[n + p] = model.targets[p]
        }
        func reach(_ x: Int) -> Set<Int> {
            var seen: Set<Int> = [x], stack = [x]
            while let y = stack.popLast() { for z in successors[y] where seen.insert(z).inserted { stack.append(z) } }
            return seen
        }
        let reachable = (0 ..< n).map(reach)
        var strong: [[Int]] = []
        var placed = Set<Int>()
        for i in 0 ..< n where !placed.contains(i) {
            let group = (i ..< n).filter { reachable[i].contains($0) && reachable[$0].contains(i) }
            placed.formUnion(group)
            strong.append(group)
        }
        check(list.stronglyConnectedComponents() == strong.map { $0.map { model.vertices[$0] } }, "stronglyConnectedComponents \(strong)")
        check(list.isStronglyConnected == (strong.count == 1), "isStronglyConnected")
    }

    static func directedView(_ list: IncidenceList<Int>, _ model: DirectedModel) {
        let n = model.vertices.count, m = model.sources.count
        let view = list.incidenceGraph
        let copy = AdjacencyList<Int>(vertices: view.vertices, edges: view.edges)
        let sourceCount = model.sources.reduce(0) { $0 + $1.count }
        check(view.vertexCount == n + m && view.edgeCount == sourceCount + model.targets.reduce(0) { $0 + $1.count }, "view counts")
        var q = 0
        for p in 0 ..< m {
            for i in model.sources[p] {
                check(view.edges[q] == DirectedEdge(from: i, to: n + p) && view.sourceIndex(ofEdgeAt: q) == i && view.targetIndex(ofEdgeAt: q) == n + p, "view source arc \(q)")
                q += 1
            }
        }
        for p in 0 ..< m {
            for j in model.targets[p] {
                check(view.edges[q] == DirectedEdge(from: n + p, to: j) && view.source(ofEdgeAt: q) == n + p && view.target(ofEdgeAt: q) == j, "view target arc \(q)")
                q += 1
            }
        }
        for i in 0 ..< n {
            check(view.outEdges(of: i).map { view.target(ofEdgeAt: $0) - n } == model.outStar(i), "view source incidences of \(i)")
            check(view.inEdges(of: i).map { view.source(ofEdgeAt: $0) - n } == model.inStar(i), "view target incidences of \(i)")
        }
        for x in 0 ..< n + m {
            let out = x < n ? model.outStar(x).map { n + $0 } : model.targets[x - n]
            let into = x < n ? model.inStar(x).map { n + $0 } : model.sources[x - n]
            check(Array(view.successors(of: x)) == out && Array(view.successorIndices(ofIndex: x)) == out, "view successors(of: \(x))")
            check(Array(view.predecessors(of: x)) == into && Array(view.predecessorIndices(ofIndex: x)) == into, "view predecessors(of: \(x))")
            check(Array(view.outEdges(of: x)) == Array(copy.outEdges(of: x)) && Array(view.inEdges(of: x)) == Array(copy.inEdges(of: x)), "view edges at \(x) against the copy")
            check(Array(view.outEdges(ofIndex: x)) == Array(copy.outEdges(ofIndex: x)) && Array(view.inEdges(ofIndex: x)) == Array(copy.inEdges(ofIndex: x)), "view edge indices at \(x)")
            check(view.outDegree(of: x) == out.count && view.inDegree(of: x) == into.count && view.degree(of: x) == out.count + into.count, "view degrees at \(x)")
            check(view.outDegree(ofIndex: x) == out.count && view.inDegree(ofIndex: x) == into.count, "view index degrees at \(x)")
            for y in 0 ..< n + m {
                check(view.contains(edge: DirectedEdge(from: x, to: y)) == copy.contains(edge: DirectedEdge(from: x, to: y)), "view contains(edge: \(x)→\(y))")
            }
        }
        check(view.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) }, "view strong components")
        check(view.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) }, "view weak components")
    }

    // MARK: - OrientedIncidenceMatrix

    static func orientedMatrix(_ list: IncidenceList<Int>, _ model: DirectedModel, _ input: inout FuzzInput) {
        let n = model.vertices.count, m = model.sources.count
        var matrix = OrientedIncidenceMatrix(list)
        var sourceCells = Set<[Int]>(), targetCells = Set<[Int]>()
        for p in 0 ..< m {
            for i in model.sources[p] { sourceCells.insert([i, p]) }
            for i in model.targets[p] { targetCells.insert([i, p]) }
        }
        check(matrix == OrientedIncidenceMatrix(vertexCount: n, hyperedges: (0 ..< m).map { (sources: model.sources[$0], targets: model.targets[$0]) }), "OrientedIncidenceMatrix(_:) equals the bulk build")
        var appended = OrientedIncidenceMatrix(vertexCount: n)
        for p in 0 ..< m { _ = appended.insert(sources: model.sources[p], targets: model.targets[p]) }
        check(appended == matrix && appended.hashValue == matrix.hashValue, "one column at a time")
        checkOriented(matrix, n, m, sourceCells, targetCells, "from the list")
        // The algorithms agree with the list's.
        func indices(_ groups: [[Int]]) -> [[Int]] { groups.map { $0.map { list.vertexIndex(of: $0) } } }
        check(matrix.weaklyConnectedComponents() == indices(list.weaklyConnectedComponents()), "matrix weak components")
        check(matrix.stronglyConnectedComponents() == indices(list.stronglyConnectedComponents()), "matrix strong components")
        for i in 0 ..< n {
            check(matrix.bConnectedVertices(from: i) == list.bConnectedVertices(from: model.vertices[i]).map { list.vertexIndex(of: $0) }, "matrix B-Visit from \(i)")
            check(matrix.fConnectedVertices(to: i) == list.fConnectedVertices(to: model.vertices[i]).map { list.vertexIndex(of: $0) }, "matrix F-Visit to \(i)")
        }
        check(IncidenceList(matrix.transposed()) == list.dual(), "transposed() is the dual")
        check(matrix.reversed == OrientedIncidenceMatrix(list.reversed) && matrix.reversed.reversed == matrix, "reversed")
        check(IncidenceMatrix(matrix) == IncidenceMatrix(list), "the unoriented union")
        let view = matrix.incidenceGraph, listView = list.incidenceGraph
        check(Array(view.edges) == Array(listView.edges), "matrix view edges")
        for x in 0 ..< n + m {
            check(Array(view.successors(of: x)) == Array(listView.successors(of: x)) && Array(view.predecessors(of: x)) == Array(listView.predecessors(of: x)), "matrix view rows at \(x)")
            check(Array(view.outEdges(of: x)) == Array(listView.outEdges(of: x)) && Array(view.inEdges(of: x)) == Array(listView.inEdges(of: x)), "matrix view edges at \(x)")
            check(view.outDegree(of: x) == listView.outDegree(of: x) && view.inDegree(of: x) == listView.inDegree(of: x), "matrix view degrees at \(x)")
        }
        // Cell edits against the sets.
        var rows = n, columns = m
        var grown = false
        for _ in 0 ..< input.int(in: 0 ... 10) {
            let target = input.int(below: 2) == 0
            switch input.int(below: 4) {
            case 0:
                if rows > 0, columns > 0 {
                    let v = input.int(below: rows), p = input.int(below: columns)
                    let changed = target ? matrix.insert(v, intoTargetsOfHyperedgeAt: p) : matrix.insert(v, intoSourcesOfHyperedgeAt: p)
                    check(changed == (target ? targetCells.insert([v, p]).inserted : sourceCells.insert([v, p]).inserted), "insert (\(v), \(p)) target: \(target)")
                }
            case 1:
                if rows > 0, columns > 0 {
                    let v = input.int(below: rows), p = input.int(below: columns)
                    let changed = target ? matrix.remove(v, fromTargetsOfHyperedgeAt: p) : matrix.remove(v, fromSourcesOfHyperedgeAt: p)
                    check(changed == ((target ? targetCells.remove([v, p]) : sourceCells.remove([v, p])) != nil), "remove (\(v), \(p)) target: \(target)")
                }
            case 2:
                for _ in 0 ..< 1 + (grown ? 0 : input.int(below: 70)) {
                    grown = true
                    check(matrix.appendVertex() == rows, "appendVertex")
                    rows += 1
                }
            default:
                if rows > 0 {
                    let edge = DirectedEdge(from: input.int(below: rows), to: input.int(below: rows))
                    check(matrix.insert(edge: edge) == columns, "insert(edge:)")
                    sourceCells.insert([edge.source, columns])
                    targetCells.insert([edge.target, columns])
                    columns += 1
                }
            }
        }
        checkOriented(matrix, rows, columns, sourceCells, targetCells, "after cell edits")
        let payload: [String: Any] = [
            "vertexCount": rows,
            "sources": (0 ..< columns).map { Array(matrix.sources(ofHyperedgeAt: $0)) },
            "targets": (0 ..< columns).map { Array(matrix.targets(ofHyperedgeAt: $0)) },
        ]
        check(decodeOriented(payload) == matrix, "oriented decodes")
    }

    static func checkOriented(_ matrix: OrientedIncidenceMatrix, _ n: Int, _ m: Int, _ sourceCells: Set<[Int]>, _ targetCells: Set<[Int]>, _ context: String) {
        check(matrix.vertexCount == n && matrix.hyperedgeCount == m && matrix.vertices == 0 ..< n && matrix.hyperedges.count == m, "oriented shape \(context)")
        check(matrix.incidenceGraph.edgeCount == sourceCells.count + targetCells.count, "oriented cell counts \(context)")
        for p in 0 ..< m {
            let s = (0 ..< n).filter { sourceCells.contains([$0, p]) }, t = (0 ..< n).filter { targetCells.contains([$0, p]) }
            check(Array(matrix.sources(ofHyperedgeAt: p)) == s && Array(matrix.sourceIndices(ofHyperedgeAt: p)) == s, "oriented sources of \(p) \(context)")
            check(Array(matrix.targets(ofHyperedgeAt: p)) == t && Array(matrix.targetIndices(ofHyperedgeAt: p)) == t, "oriented targets of \(p) \(context)")
            check(Array(matrix.hyperedges[p].sources) == s && Array(matrix.hyperedges[p].targets) == t, "oriented hyperedges[\(p)] \(context)")
            check(matrix.contains(sources: s.reversed(), targets: t), "oriented contains \(p) \(context)")
            let swapped = (0 ..< m).contains { q in (0 ..< n).filter { sourceCells.contains([$0, q]) } == t && (0 ..< n).filter { targetCells.contains([$0, q]) } == s }
            check(matrix.contains(sources: t, targets: s) == swapped, "oriented contains \(p) swapped \(context)")
        }
        for v in 0 ..< n {
            let out = (0 ..< m).filter { sourceCells.contains([v, $0]) }, into = (0 ..< m).filter { targetCells.contains([v, $0]) }
            check(Array(matrix.outHyperedges(of: v)) == out && Array(matrix.outHyperedges(ofIndex: v)) == out, "oriented out row \(v) \(context)")
            check(Array(matrix.inHyperedges(of: v)) == into && Array(matrix.inHyperedges(ofIndex: v)) == into, "oriented in row \(v) \(context)")
            check(matrix.outDegree(of: v) == out.count && matrix.inDegree(of: v) == into.count && matrix.degree(of: v) == out.count + into.count, "oriented degrees of \(v) \(context)")
            check(matrix.outDegree(ofIndex: v) == out.count && matrix.inDegree(ofIndex: v) == into.count, "oriented index degrees of \(v) \(context)")
            for p in 0 ..< m {
                let entry = (targetCells.contains([v, p]) ? 1 : 0) - (sourceCells.contains([v, p]) ? 1 : 0)
                check(matrix[vertex: v, hyperedge: p] == entry, "oriented entry (\(v), \(p)) \(context)")
            }
        }
        check(!matrix.contains(-1) && !matrix.contains(n) && !matrix.contains(sources: [n], targets: [] as [Int]), "oriented out of range \(context)")
        let hasEmpty = (0 ..< m).contains { p in !sourceCells.contains { $0[1] == p } && !targetCells.contains { $0[1] == p } }
        check(matrix.contains(sources: [] as [Int], targets: [] as [Int]) == hasEmpty, "oriented empty column \(context)")
    }

    // MARK: - Directed equality, hashing, Codable

    static func directedValue(_ list: IncidenceList<Int>, _ model: DirectedModel, _ input: inout FuzzInput) {
        let n = model.vertices.count, m = model.sources.count
        var order = Array(0 ..< n), hyperedgeOrder = Array(0 ..< m)
        for k in 0 ..< n { order.swapAt(k, k + input.int(below: n - k)) }
        for k in 0 ..< m { hyperedgeOrder.swapAt(k, k + input.int(below: m - k)) }
        let shuffled = IncidenceList(vertices: order.map { model.vertices[$0] }, hyperedges: hyperedgeOrder.map {
            (sources: model.sources[$0].map { model.vertices[$0] }, targets: model.targets[$0].map { model.vertices[$0] })
        })
        check(shuffled == list && shuffled.hashValue == list.hashValue, "equality under reordering")
        let pairs = (0 ..< m).map { [model.sources[$0], model.targets[$0]] }
        let reversedPairs = (0 ..< m).map { [model.targets[$0], model.sources[$0]] }
        func sortedPairs(_ x: [[[Int]]]) -> [[[Int]]] { x.sorted { "\($0)" < "\($1)" } }
        check((list.reversed == list) == (sortedPairs(pairs) == sortedPairs(reversedPairs)), "equal to the reversal exactly when symmetric")
        // Moving the boundary between the sides of one hyperedge changes the hypergraph.
        if let p = (0 ..< m).first(where: { !model.sources[$0].isEmpty }) {
            var sources = model.sources, targets = model.targets
            let moved = sources[p].removeLast()
            targets[p] = Array(Set(targets[p] + [moved])).sorted()
            let changed = IncidenceList(vertices: model.vertices, hyperedges: (0 ..< m).map { (sources: sources[$0].map { model.vertices[$0] }, targets: targets[$0].map { model.vertices[$0] }) })
            let same = sortedPairs((0 ..< m).map { [sources[$0], targets[$0]] }) == sortedPairs(pairs)
            check((changed == list) == same, "a source moved to the targets")
        }
        let decoded = try? IncidenceList<Int>(from: PayloadDecoder(values: ["vertices": model.vertices, "sources": model.sources, "targets": model.targets]))
        check(decoded.map { $0.vertices.elements == model.vertices && $0 == list } == true, "decodes")
        var vertices = model.vertices, sources = model.sources, targets = model.targets
        let hostile = input.int(below: 6)
        switch hostile {
        case 0:
            guard let first = vertices.first else { return }
            vertices.append(first)
        case 1:
            sources.append([n + input.int(below: 3)])
            targets.append([])
        case 2:
            sources.append([])
            targets.append([-1 - input.int(below: 3)])
        case 3:
            guard n > 0 else { return }
            sources.append([])
            targets.append([n - 1, 0])
        case 4:
            targets.append([])
        default:
            sources.append([])
        }
        check(throwsOnDecode(IncidenceList<Int>.self, PayloadDecoder(values: ["vertices": vertices, "sources": sources, "targets": targets])), "hostile payload \(hostile) decoded")
    }
}
