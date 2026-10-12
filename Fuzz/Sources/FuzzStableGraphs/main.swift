// StableDirectedGraph against a model of positions: random sequences of vertex and edge
// insertions, removals of the newest copy, of a given position, of every copy of a pair, of
// vertices, and the two resets. The model keeps each vertex and edge position (nil at a hole),
// only ever appended to, so positions are never reused. After every step: counts, the live
// positions and elements of `vertices` and `edges` in order (forwards and backwards), the position
// queries, the dense bounds nil exactly while holes exist, and every vertex's out- and in-rows in
// position order with its degrees. Every 16th step, the algorithms agree with a compacted
// `DirectedPseudograph` (weak and strong components, breadth-first layers, Dijkstra with weights
// by position), and the graph equals and hashes like its compacted copy. A churn step inserts an
// edge and removes a vertex several times over, so vertex holes pile up around a small live graph.
// Decoding: Foundation's coders are not available to this toolchain against the SDK, so a minimal
// in-memory decoder feeds `init(from:)` the model's own payload, which must decode to the same
// positions and ends, or the payload with one field made hostile (a huge or negative end, an odd
// edge list, an endpoint out of range, positions not increasing or past the end, a repeated
// vertex), which must throw; a huge end decodes in O(elements) when the pages from the first listed
// position to the end number at most 16 per listed element plus 64, and throws otherwise. Heavy
// churn steps hand out thousands of positions while few stay live, so pages fill and are freed;
// `changeTarget` / `changeSource` (and their `checked:` spellings) re-point edges in place; up to three
// attached edge maps and a vertex map, added, filled and removed at random, must never hold a
// value at a dead position (every removal clears it) and keep the live ones' values, through
// re-pointing too; a copy taken at a snapshot step, maps included, must not change while the
// graph does.

import Connectivity
import FuzzSupport
import GraphProtocols
import Multigraphs
import ShortestPaths
import StableGraphs
import Traversal

/// A decoder over one keyed payload of `Int` and `[Int]` values: the generic `decode` hands back
/// the stored value when its type matches, so no unkeyed containers are needed.
struct PayloadDecoder: Decoder {
    let values: [String: Any]
    var codingPath: [any CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(Container<Key>(values: values))
    }
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { throw Self.mismatch }
    func singleValueContainer() throws -> any SingleValueDecodingContainer { throw Self.mismatch }
    static var mismatch: DecodingError { .dataCorrupted(.init(codingPath: [], debugDescription: "unsupported")) }

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
enum FuzzStableGraphs {
    static func main() { runFuzzer(fuzz) }

    struct Model {
        var vertices: [Int?] = []
        var edges: [(source: Int, target: Int)?] = []

        func position(of v: Int) -> Int? { vertices.firstIndex(where: { $0 == v }) }
        var liveVertices: [Int] { vertices.indices.filter { vertices[$0] != nil } }
        var liveEdges: [Int] { edges.indices.filter { edges[$0] != nil } }
        func copies(_ a: Int, _ b: Int) -> [Int] { liveEdges.filter { edges[$0]!.source == a && edges[$0]!.target == b } }

        mutating func insert(_ v: Int) { if position(of: v) == nil { vertices.append(v) } }
    }

    /// `vertexEnd` and `edgeEnd` default to the model's; a decoded far end has dead positions
    /// after the model's, which are checked at the ends only.
    static func checkAll(_ graph: StableDirectedGraph<Int>, _ model: Model, _ context: String, vertexEnd: Int? = nil, edgeEnd: Int? = nil) {
        let lv = model.liveVertices, le = model.liveEdges
        let vertexEnd = vertexEnd ?? model.vertices.count, edgeEnd = edgeEnd ?? model.edges.count
        check(graph.vertexCount == lv.count, "vertexCount \(graph.vertexCount), expected \(lv.count) \(context)")
        check(graph.edgeCount == le.count, "edgeCount \(graph.edgeCount), expected \(le.count) \(context)")
        check(graph.vertices.endIndex == vertexEnd && graph.vertexPositionBound == vertexEnd, "vertex end \(context)")
        check(graph.edges.endIndex == edgeEnd && graph.edgePositionBound == edgeEnd, "edge end \(context)")
        check(Array(graph.vertices.indices) == lv, "vertex positions \(Array(graph.vertices.indices)), expected \(lv) \(context)")
        check(Array(graph.vertices) == lv.map { model.vertices[$0]! }, "vertices in order \(context)")
        check(Array(graph.vertices.reversed()) == lv.reversed().map { model.vertices[$0]! }, "vertices reversed \(context)")
        check(Array(graph.edges.indices) == le, "edge positions \(Array(graph.edges.indices)), expected \(le) \(context)")
        check(Array(graph.edges.indices.reversed()) == le.reversed(), "edge positions reversed \(context)")
        for p in le {
            let e = model.edges[p]!
            check(graph.edges[p] == DirectedEdge(from: e.source, to: e.target), "edge at \(p) \(context)")
            check(graph.source(ofEdgeAt: p) == e.source && graph.target(ofEdgeAt: p) == e.target, "ends at \(p) \(context)")
        }
        for p in Array(-1 ... model.vertices.count) + [vertexEnd - 1, vertexEnd, Int.max] {
            let live = p >= 0 && p < model.vertices.count && model.vertices[p] != nil
            check(graph.containsVertex(atPosition: p) == live, "containsVertex(atPosition: \(p)) \(context)")
            check(graph.vertices.indices.contains(p) == live, "vertices.indices.contains(\(p)) \(context)")
        }
        for p in Array(-1 ... model.edges.count) + [edgeEnd - 1, edgeEnd, Int.max] {
            let live = p >= 0 && p < model.edges.count && model.edges[p] != nil
            check(graph.containsEdge(atPosition: p) == live, "containsEdge(atPosition: \(p)) \(context)")
            check(graph.edges.indices.contains(p) == live, "edges.indices.contains(\(p)) \(context)")
            let ends = live ? model.edges[p]! : nil
            check((try? graph.source(checkedEdgeAt: p)) == ends?.source, "source(checkedEdgeAt: \(p)) \(context)")
            check((try? graph.target(checkedEdgeAt: p)) == ends?.target, "target(checkedEdgeAt: \(p)) \(context)")
        }
        let vertexHoles = lv.count != vertexEnd, edgeHoles = le.count != edgeEnd
        check(graph.vertexIndexBound == (vertexHoles ? nil : lv.count), "vertexIndexBound \(String(describing: graph.vertexIndexBound)) \(context)")
        check(graph.edgeIndexBound == (edgeHoles ? nil : le.count), "edgeIndexBound \(String(describing: graph.edgeIndexBound)) \(context)")
        for p in lv {
            let v = model.vertices[p]!
            check(graph.contains(v) && graph.vertexPosition(of: v) == p && graph.vertex(atPosition: p) == v, "position of \(v) \(context)")
            let out = le.filter { model.edges[$0]!.source == v }
            let into = le.filter { model.edges[$0]!.target == v }
            check(Array(graph.outEdges(of: v)) == out, "outEdges(of: \(v)) \(Array(graph.outEdges(of: v))), expected \(out) \(context)")
            check(Array(graph.inEdges(of: v)) == into, "inEdges(of: \(v)) \(Array(graph.inEdges(of: v))), expected \(into) \(context)")
            check(Array(graph.outEdges(of: v).reversed()) == out.reversed(), "outEdges(of: \(v)) reversed \(context)")
            check(Array(graph.inEdges(of: v).reversed()) == into.reversed(), "inEdges(of: \(v)) reversed \(context)")
            check(Array(graph.successors(of: v)) == out.map { model.edges[$0]!.target }, "successors(of: \(v)) \(context)")
            check(Array(graph.predecessors(of: v)) == into.map { model.edges[$0]!.source }, "predecessors(of: \(v)) \(context)")
            check(graph.outDegree(of: v) == out.count && graph.inDegree(of: v) == into.count, "degrees of \(v) \(context)")
            check(graph.degree(of: v) == out.count + into.count, "degree of \(v) \(context)")
            check(graph.outEdges(of: v).count == out.count && graph.inEdges(of: v).count == into.count, "row counts of \(v) \(context)")
            if vertexHoles == false { check(graph.vertexIndex(of: v) == p, "vertexIndex(of: \(v)) \(context)") }
            check((try? graph.degree(checked: v)) == out.count + into.count, "degree(checked: \(v)) \(context)")
            if vertexHoles == false { check((try? graph.vertexIndex(checked: v)) == p, "vertexIndex(checked: \(v)) \(context)") }
        }
        // A vertex never inserted: every checked: lookup throws.
        check((try? graph.degree(checked: -1)) == nil && (try? graph.successors(checked: -1)) == nil, "checked: lookups of -1 \(context)")
        if vertexHoles == false { check((try? graph.vertexIndex(checked: -1)) == nil, "vertexIndex(checked: -1) \(context)") }
    }

    static func checkMaps(
        _ graph: StableDirectedGraph<Int>, _ edgeMaps: [(handle: EdgeMap<Int?>, values: [Int: Int])], _ tags: VertexMap<Int?>?,
        _ tagValues: [Int: Int], _ model: Model, _ context: String
    ) {
        for (m, map) in edgeMaps.enumerated() {
            for p in 0 ..< model.edges.count {
                // A removed edge has no value: the checked read throws, which `try?` makes nil.
                let value = try? graph[map.handle, checkedEdgeAt: p]
                check(value == map.values[p], "edge map \(m) at \(p): \(String(describing: value)), expected \(String(describing: map.values[p])) \(context)")
            }
        }
        if let tags {
            for p in 0 ..< model.vertices.count {
                check((try? graph[tags, checkedVertexAt: p]) == tagValues[p], "vertex map at \(p) \(context)")
            }
        }
    }

    static func checkPair(_ graph: StableDirectedGraph<Int>, _ model: Model, _ a: Int, _ b: Int, _ context: String) {
        let copies = model.copies(a, b)
        check(Array(graph.edges(from: a, to: b)) == copies, "edges(from: \(a), to: \(b)) \(Array(graph.edges(from: a, to: b))), expected \(copies) \(context)")
        check(graph.edgeCount(from: a, to: b) == copies.count, "edgeCount(from: \(a), to: \(b)) \(context)")
        check(graph.contains(edge: DirectedEdge(from: a, to: b)) == !copies.isEmpty, "contains(edge: \(a)→\(b)) \(context)")
    }

    static func checkAlgorithms(_ graph: StableDirectedGraph<Int>, _ context: String) {
        let compacted = DirectedPseudograph<Int>(graph)
        let positions = Array(graph.edges.indices)
        check(Array(compacted.vertices) == Array(graph.vertices), "compacted vertices \(context)")
        check(graph == StableDirectedGraph(compacted) && graph.hashValue == StableDirectedGraph(compacted).hashValue, "equal to the compacted copy \(context)")
        check(graph.weaklyConnectedComponents().map { Array($0) } == compacted.weaklyConnectedComponents().map { Array($0) }, "weak components \(context)")
        check(graph.stronglyConnectedComponents().map { Array($0) } == compacted.stronglyConnectedComponents().map { Array($0) }, "strong components \(context)")
        let weight = (0 ..< graph.edges.endIndex).map { ($0 &* 2_654_435_761) % 7 + 1 }
        for source in graph.vertices {
            check(graph.breadthFirstLayers(from: source) == compacted.breadthFirstLayers(from: source), "layers from \(source) \(context)")
            let tree = graph.dijkstraShortestPaths(from: source) { weight[$0] }
            let copy = compacted.dijkstraShortestPaths(from: source) { weight[positions[$0]] }
            for v in graph.vertices {
                check(tree.distance(to: v) == copy.distance(to: v), "Dijkstra distance \(source)→\(v) \(context)")
                check(tree.parentEdge(of: v) == copy.parentEdge(of: v).map { positions[$0] }, "Dijkstra parent of \(v) from \(source) \(context)")
            }
        }
    }

    /// The model's payload in the documented format, or one field of it made hostile; whether it
    /// must throw (nil: a huge end, which may decode if it does so without trapping).
    static func payload(_ model: Model, corruption: Int) -> (values: [String: Any], mustThrow: Bool?) {
        let lv = model.liveVertices, le = model.liveEdges
        var labels = lv.map { model.vertices[$0]! }
        var positions = lv
        var vertexEnd = model.vertices.count
        var ends = le.flatMap { p in [lv.firstIndex(of: model.position(of: model.edges[p]!.source)!)!, lv.firstIndex(of: model.position(of: model.edges[p]!.target)!)!] }
        var edgePositions = le
        var edgeEnd = model.edges.count
        var mustThrow: Bool? = false
        switch corruption {
        case 0: vertexEnd = Int.max; mustThrow = nil
        case 1: edgeEnd = Int.max; mustThrow = nil
        case 2: vertexEnd = 1 << 40; mustThrow = nil
        case 3: edgeEnd = 1 << 40; mustThrow = nil
        case 4: vertexEnd = -1; mustThrow = true
        case 5: edgeEnd = -1; mustThrow = true
        case 6: ends.append(0); mustThrow = true
        case 7 where !ends.isEmpty: ends[0] = labels.count; mustThrow = true
        case 8 where !ends.isEmpty: ends[ends.count - 1] = -1; mustThrow = true
        case 9 where positions.count >= 2: positions[1] = positions[0]; mustThrow = true
        case 10 where !positions.isEmpty: positions[positions.count - 1] = vertexEnd; mustThrow = true
        case 11 where edgePositions.count >= 2: edgePositions[1] = edgePositions[0]; mustThrow = true
        case 12 where !edgePositions.isEmpty: edgePositions[edgePositions.count - 1] = edgeEnd; mustThrow = true
        case 13 where labels.count >= 2: labels[1] = labels[0]; mustThrow = true
        case 14: positions.append(vertexEnd); mustThrow = true
        case 15: vertexEnd += 3; edgeEnd += 2
        default: break
        }
        let values: [String: Any] = ["vertices": labels, "vertexPositions": positions, "vertexEnd": vertexEnd,
                                     "edges": ends, "edgePositions": edgePositions, "edgeEnd": edgeEnd]
        return (values, mustThrow)
    }

    static func checkDecoding(_ model: Model, corruption: Int, _ context: String) {
        let (values, mustThrow) = payload(model, corruption: corruption)
        let decoded = try? StableDirectedGraph<Int>(from: PayloadDecoder(values: values))
        guard mustThrow != true else {
            check(decoded == nil, "hostile payload \(corruption) decoded \(context)")
            return
        }
        guard let decoded else {
            check(mustThrow == nil, "valid payload \(corruption) did not decode \(context)")
            if mustThrow == nil {
                // A far end throws exactly when it spans too many pages.
                let vertexEnd = values["vertexEnd"] as! Int, edgeEnd = values["edgeEnd"] as! Int
                func span(_ end: Int, _ first: Int?) -> Int { end >> 10 - Swift.max(first ?? end, 0) >> 10 + 1 }
                check(span(vertexEnd, model.liveVertices.first) > 16 * model.liveVertices.count + 64
                    || span(edgeEnd, model.liveEdges.first) > 16 * model.liveEdges.count + 64, "far end within the page bound did not decode \(context)")
            }
            return
        }
        let vertexEnd = values["vertexEnd"] as! Int, edgeEnd = values["edgeEnd"] as! Int
        checkAll(decoded, model, "decoded payload \(corruption) \(context)", vertexEnd: vertexEnd, edgeEnd: edgeEnd)
        // The pages a far end allows: at most 16 per listed element plus 64, from the first one.
        func span(_ end: Int, _ first: Int?) -> Int { end >> 10 - Swift.max(first ?? end, 0) >> 10 + 1 }
        check(span(vertexEnd, model.liveVertices.first) <= 16 * model.liveVertices.count + 64, "vertex span accepted \(context)")
        check(span(edgeEnd, model.liveEdges.first) <= 16 * model.liveEdges.count + 64, "edge span accepted \(context)")
        // The next fresh positions follow the decoded ends.
        var next = decoded
        if vertexEnd < Int.max { check(next.insert(-1).inserted && next.vertexPosition(of: -1) == vertexEnd, "next vertex position \(context)") }
        if edgeEnd < Int.max, vertexEnd < Int.max { check(next.insert(edge: DirectedEdge(from: -1, to: -1)) == edgeEnd, "next edge position \(context)") }
    }

    static func fuzz(_ input: inout FuzzInput) {
        var graph = StableDirectedGraph<Int>()
        var model = Model()
        var steps = 0
        var log: [String] = []
        var edgeMaps: [(handle: EdgeMap<Int?>, values: [Int: Int])] = []
        let tags = graph.addVertexMap(of: Int.self)
        var tagValues: [Int: Int] = [:]
        var snapshot: (graph: StableDirectedGraph<Int>, model: Model, maps: [(handle: EdgeMap<Int?>, values: [Int: Int])])?
        while !input.isEmpty, steps < 96 {
            steps += 1
            let a = input.int(below: 8), b = input.int(below: 8)
            let op = input.int(below: 24)
            switch op {
            case 0 ..< 2:
                let result = graph.insert(a)
                check(result.inserted == (model.position(of: a) == nil) && result.memberAfterInsert == a, "insert(\(a)) result")
                model.insert(a)
                log.append("insert(\(a))")
            case 2 ..< 7:
                let p = graph.insert(edge: DirectedEdge(from: a, to: b))
                check(p == model.edges.count, "insert(edge:) position \(p), expected \(model.edges.count)")
                model.insert(a)
                model.insert(b)
                model.edges.append((a, b))
                log.append("insert(edge: \(a)→\(b))")
            case 7 ..< 9:
                let copies = model.copies(a, b)
                let removed = graph.remove(edge: DirectedEdge(from: a, to: b))
                check((removed != nil) == !copies.isEmpty, "remove(edge: \(a)→\(b)) result")
                if let newest = copies.last { model.edges[newest] = nil }
                log.append("remove(edge: \(a)→\(b))")
            case 9 ..< 12:
                let live = model.liveEdges
                guard !live.isEmpty else { continue }
                let p = live[(a * 8 + b) % live.count]
                let removed = graph.remove(edgeAt: p)
                check(removed == DirectedEdge(from: model.edges[p]!.source, to: model.edges[p]!.target), "remove(edgeAt: \(p)) result")
                model.edges[p] = nil
                log.append("remove(edgeAt: \(p))")
            case 12 ..< 14:
                let p = model.position(of: a)
                check(graph.remove(a) == (p == nil ? nil : a), "remove(\(a)) result")
                if let p {
                    model.vertices[p] = nil
                    for e in model.liveEdges where model.edges[e]!.source == a || model.edges[e]!.target == a { model.edges[e] = nil }
                }
                log.append("remove(\(a))")
            case 14:
                let copies = model.copies(a, b)
                check(graph.removeAllEdges(from: a, to: b) == copies.count, "removeAllEdges(from: \(a), to: \(b)) count")
                for e in copies { model.edges[e] = nil }
                log.append("removeAllEdges(from: \(a), to: \(b))")
            case 15:
                // Vertex churn: an edge in, a vertex out, several times, so holes pile up.
                for round in 0 ..< 1 + a {
                    let u = (b + round) % 8, w = (b + 3 * round + 1) % 8
                    let p = graph.insert(edge: DirectedEdge(from: u, to: w))
                    check(p == model.edges.count, "churn insert(edge:) position \(p), expected \(model.edges.count)")
                    model.insert(u)
                    model.insert(w)
                    model.edges.append((u, w))
                    let gone = (u + w + round) % 8
                    let at = model.position(of: gone)
                    check(graph.remove(gone) == (at == nil ? nil : gone), "churn remove(\(gone)) result")
                    if let at {
                        model.vertices[at] = nil
                        for e in model.liveEdges where model.edges[e]!.source == gone || model.edges[e]!.target == gone { model.edges[e] = nil }
                    }
                }
                log.append("churn(\(a), \(b))")
            case 16:
                checkDecoding(model, corruption: (a * 8 + b) % 17, "after \(log.suffix(6).joined(separator: "; "))")
                continue
            case 18, 19:
                // Re-point a live edge: the checked: spelling also at dead positions and non-vertices,
                // throwing ElementNotFound.edge for a dead position first, then .vertex.
                let live = model.liveEdges
                let p = live.isEmpty ? a - 1 : live[(a * 8 + b) % live.count]
                let target = op == 18, checked = (a + b) % 3 == 0
                let isEdge = p >= 0 && p < model.edges.count && model.edges[p] != nil
                let ok = isEdge && model.position(of: b) != nil
                if checked {
                    let call = "change\(target ? "Target" : "Source")(ofEdgeAt: \(p), checked: \(b))"
                    do throws(ElementNotFound) {
                        if target { try graph.changeTarget(ofEdgeAt: p, checked: b) } else { try graph.changeSource(ofEdgeAt: p, checked: b) }
                        check(ok, "\(call) did not throw")
                    } catch {
                        switch error {
                        case .edge: check(!isEdge, "\(call) threw ElementNotFound.edge")
                        case .vertex: check(isEdge && !ok, "\(call) threw ElementNotFound.vertex")
                        }
                    }
                } else if ok {
                    if target { graph.changeTarget(ofEdgeAt: p, to: b) } else { graph.changeSource(ofEdgeAt: p, to: b) }
                }
                if ok {
                    if target { model.edges[p]!.target = b } else { model.edges[p]!.source = b }
                }
                log.append("change\(target ? "Target" : "Source")(ofEdgeAt: \(p), \(checked ? "checked" : "to"): \(b))")
            case 20:
                // Heavy edge churn: hundreds of edges in, the oldest out, so whole pages die.
                for round in 0 ..< 300 * (1 + a) {
                    let u = (b + round) % 8, w = (round / 8 + b) % 8
                    let p = graph.insert(edge: DirectedEdge(from: u, to: w))
                    check(p == model.edges.count, "heavy churn insert(edge:) position \(p)")
                    model.insert(u)
                    model.insert(w)
                    model.edges.append((u, w))
                    if let oldest = model.edges.firstIndex(where: { $0 != nil }), round % 4 != 0 {
                        check(graph.remove(edgeAt: oldest) == DirectedEdge(from: model.edges[oldest]!.source, to: model.edges[oldest]!.target), "heavy churn remove(edgeAt: \(oldest))")
                        model.edges[oldest] = nil
                    }
                }
                log.append("heavyChurn(\(a), \(b))")
            case 21:
                // Heavy vertex churn: a vertex removed and re-inserted, each time at a fresh position.
                for round in 0 ..< 200 * (1 + a) {
                    let v = (b + round) % 8
                    if let at = model.position(of: v) {
                        check(graph.remove(v) == v, "heavy vertex churn remove(\(v))")
                        model.vertices[at] = nil
                        for e in model.liveEdges where model.edges[e]!.source == v || model.edges[e]!.target == v { model.edges[e] = nil }
                    }
                    graph.insert(v)
                    model.vertices.append(v)
                    graph[tags, ofVertexAt: model.vertices.count - 1] = v
                    tagValues[model.vertices.count - 1] = v
                    if round % 3 == 0 {
                        let w = (v + 1 + round / 8) % 8
                        model.insert(w)
                        model.edges.append((v, w))
                        _ = graph.insert(edge: DirectedEdge(from: v, to: w))
                    }
                }
                log.append("heavyVertexChurn(\(a), \(b))")
            case 22:
                // Attached edge maps: add one, remove one, or fill some live positions.
                switch a % 4 {
                case 0 where edgeMaps.count < 3:
                    edgeMaps.append((graph.addEdgeMap(of: Int.self), [:]))
                case 1 where !edgeMaps.isEmpty:
                    graph.removeEdgeMap(edgeMaps.remove(at: b % edgeMaps.count).handle)
                default:
                    for m in edgeMaps.indices {
                        for p in model.liveEdges where (p + b + m) % 3 == 0 {
                            graph[edgeMaps[m].handle, ofEdgeAt: p] = p &* 7 &+ m
                            edgeMaps[m].values[p] = p &* 7 &+ m
                        }
                    }
                }
                log.append("maps(\(a), \(b))")
            case 23:
                // A copy now, maps included, must not change while the graph does.
                snapshot = (graph, model, edgeMaps)
                continue
            default:
                // Rare resets: positions start again at 0.
                switch b {
                case 0:
                    graph.removeAll(keepingCapacity: a % 2 == 0)
                    model = Model()
                    log.append("removeAll")
                case 1:
                    graph.removeAllEdges(keepingCapacity: a % 2 == 0)
                    model.edges = []
                    log.append("removeAllEdges")
                default:
                    continue
                }
            }
            let context = "after \(log.suffix(6).joined(separator: "; "))"
            checkAll(graph, model, context)
            checkPair(graph, model, a, b, context)
            // Every removal cleared the removed elements' values; the live ones keep theirs.
            for m in edgeMaps.indices { edgeMaps[m].values = edgeMaps[m].values.filter { p, _ in p < model.edges.count && model.edges[p] != nil } }
            tagValues = tagValues.filter { p, _ in p < model.vertices.count && model.vertices[p] != nil }
            checkMaps(graph, edgeMaps, tags, tagValues, model, context)
            if let snapshot {
                checkAll(snapshot.graph, snapshot.model, "snapshot, " + context)
                checkMaps(snapshot.graph, snapshot.maps, nil, [:], snapshot.model, "snapshot, " + context)
            }
            if steps % 16 == 0 { checkAlgorithms(graph, context) }
        }
        checkAlgorithms(graph, "at the end")
    }
}
