// The document readers' one-pass reads against their general ones. Node-link JSON in the common
// layout is read in one pass; any other layout in two (the document checked first). GraphML's
// first walk reads the nodes and edges ahead while it can tell the second walk would read them the
// same way; a key after the graph sends every document to the second walk. Each document here is
// read both ways (the second by a variant that differs only in what forces the general reader: a
// member the reader ignores, a key nothing uses), and must read the same: the same graph, the same
// calls to every closure in the same order, or the same error at the same place. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats one-pass reads")
struct GraphFormatsOnePassTests {
    @Test("Node-link: NetworkX's layout reads as the two-pass reader reads it, on random documents and errors",
          arguments: 0 ..< 400 as Range<UInt>)
    func nodeLinkOnePass(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        func pick<T>(_ options: [T]) -> T { options[Int.random(in: 0 ..< options.count, using: &rng)] }
        func chance(_ p: Double) -> Bool { Double.random(in: 0 ..< 1, using: &rng) < p }
        let space = chance(0.5) ? " " : ""
        func scalar() -> String {
            pick(["1", "-7", "0", "-0", "0.5", "1e3", "-0.0", "2.5E-3", "true", "false", "\"s\"", "\"\\u00e9\\n\"", "\"\"",
                  "123456789012345678901", "1.7976931348623157e309"] + (chance(0.05) ? ["null", "[1]", "{}", "01", "1.", "\"\\ud800\""] : []))
        }
        let idPool = ["1", "2", "-3", "0", "1000000000000", "9223372036854775807", "\"a\"", "\"b\"", "\"\\u0061\"", "\"1\"", "\"A\"",
                      "\"bad\""]
        let nodeCount = Int.random(in: 0 ... 5, using: &rng)
        var ids: [String] = []
        while ids.count < nodeCount {
            let id = pick(idPool)
            if !ids.contains(id) || chance(0.05) { ids.append(id) }
        }
        if chance(0.03) { ids.append(pick(["1.5", "true", "null"])) }
        var members: [String] = []
        let directed = chance(0.5)
        if chance(0.9) { members.append("\"directed\":\(space)\(chance(0.97) ? "\(directed)" : "1")") }
        if chance(0.8) { members.append("\"multigraph\":\(space)\(chance(0.5))") }
        if chance(0.5) {
            let attributes = (0 ..< Int.random(in: 0 ... 2, using: &rng)).map { "\"g\($0)\":\(space)\(scalar())" }
            members.append("\"graph\":\(space){\(attributes.joined(separator: ",\(space)"))}")
        }
        let nodes = ids.map { id -> String in
            var parts = (0 ..< Int.random(in: 0 ... 2, using: &rng)).map { _ in "\"\(pick(["w", "x", "label", "a_long_attribute", "a_long_attributf", "", "eightchr"]))\":\(space)\(scalar())" }
            if !chance(0.02) { parts.insert("\"id\":\(space)\(id)", at: Int.random(in: 0 ... parts.count, using: &rng)) }
            return "{\(parts.joined(separator: ",\(space)"))}"
        }
        members.append("\"nodes\":\(space)[\(nodes.joined(separator: ",\(space)"))]")
        let edgeCount = ids.isEmpty ? 0 : Int.random(in: 0 ... 7, using: &rng)
        let edges = (0 ..< edgeCount).map { _ -> String in
            var parts = ["\"source\":\(space)\(chance(0.05) ? pick(idPool) : pick(ids))", "\"target\":\(space)\(chance(0.05) ? pick(idPool) : pick(ids))"]
            if chance(0.4) { parts.append("\"key\":\(space)\(pick(["0", "1", "\"k\"", "null", "true", "1.0", "2"]))") }
            for k in 0 ..< Int.random(in: 0 ... 2, using: &rng) {
                parts.append("\"\(pick(["w", "v", "weight_of_edge", "sourcex", ""]))\(k)\":\(space)\(scalar())")
            }
            if chance(0.03) { parts.removeFirst() }
            parts.shuffle(using: &rng)
            return "{\(parts.joined(separator: ",\(space)"))}"
        }
        members.append("\"\(chance(0.8) ? "edges" : "links")\":\(space)[\(edges.joined(separator: ",\(space)"))]")
        let onePass = "{\(members.joined(separator: ",\(space)"))}"
        let twoPass = "{\(members.joined(separator: ",\(space)")),\(space)\"zz\":\(space)0}"

        func read<G>(_ text: String, _ make: (String, inout [String]) throws(ParseError) -> G, _ render: (G) -> String) -> String {
            var log: [String] = []
            do throws(ParseError) {
                let graph = try make(text, &log)
                return "\(render(graph)) \(log)"
            } catch {
                return "\(error) \(log)"
            }
        }
        func value(_ v: AttributeValue) -> String {
            if case .double(let d) = v { return d.isNaN ? "nan" : "d\(d.bitPattern)" }
            return "\(v)"
        }
        do {
            let text = onePass, general = twoPass
            #expect(read(text, { (text, log) throws(ParseError) in
                try DirectedPseudograph<String>(nodeLinkJSON: text.utf8, vertexAttribute: { log.append("v \($0) \($1) \(value($2))") },
                                                edgeAttribute: { log.append("e \($0) \($1) \(value($2))") },
                                                graphAttribute: { log.append("g \($0) \(value($1))") })
            }, { "\(Array($0.vertices)) \($0.edges.map { "\($0.source)>\($0.target)" })" })
                == read(general, { (text, log) throws(ParseError) in
                    try DirectedPseudograph<String>(nodeLinkJSON: text.utf8, vertexAttribute: { log.append("v \($0) \($1) \(value($2))") },
                                                    edgeAttribute: { log.append("e \($0) \($1) \(value($2))") },
                                                    graphAttribute: { log.append("g \($0) \(value($1))") })
                }, { "\(Array($0.vertices)) \($0.edges.map { "\($0.source)>\($0.target)" })" }), "\(seed): \(text)")
            #expect(read(text, { (text, log) throws(ParseError) in
                try Pseudograph<Int>(nodeLinkJSON: text.utf8, edgeAttribute: { log.append("e \($0) \($1) \(value($2))") })
            }, { "\(Array($0.vertices)) \($0.edges.map { "\($0.u)-\($0.v)" })" })
                == read(general, { (text, log) throws(ParseError) in
                    try Pseudograph<Int>(nodeLinkJSON: text.utf8, edgeAttribute: { log.append("e \($0) \($1) \(value($2))") })
                }, { "\(Array($0.vertices)) \($0.edges.map { "\($0.u)-\($0.v)" })" }), "\(seed): \(text)")
            // A simple target, and a mapping that merges ids and refuses one, its calls logged.
            for undirected in [false, true] {
                let a = read(text, { (text, log) throws(ParseError) -> String in
                    var calls: [String] = []
                    defer { log += calls }
                    if undirected {
                        let g = try UndirectedAdjacencyList<String>(nodeLinkJSON: text.utf8, vertex: { calls.append("map \($0)"); return Self.merge($0) },
                                                                     vertexAttribute: { calls.append("v \($0) \($1) \(value($2))") },
                                                                     edgeAttribute: { calls.append("e \($0) \($1) \(value($2))") },
                                                                     graphAttribute: { calls.append("g \($0) \(value($1))") })
                        return "\(Array(g.vertices)) \(g.edges.map { "\($0.u)-\($0.v)" })"
                    }
                    let g = try AdjacencyList<String>(nodeLinkJSON: text.utf8, vertex: { calls.append("map \($0)"); return Self.merge($0) },
                                                      vertexAttribute: { calls.append("v \($0) \($1) \(value($2))") },
                                                      edgeAttribute: { calls.append("e \($0) \($1) \(value($2))") },
                                                      graphAttribute: { calls.append("g \($0) \(value($1))") })
                    return "\(Array(g.vertices)) \(g.edges.map { "\($0.source)>\($0.target)" })"
                }, { $0 })
                let b = read(general, { (text, log) throws(ParseError) -> String in
                    var calls: [String] = []
                    defer { log += calls }
                    if undirected {
                        let g = try UndirectedAdjacencyList<String>(nodeLinkJSON: text.utf8, vertex: { calls.append("map \($0)"); return Self.merge($0) },
                                                                     vertexAttribute: { calls.append("v \($0) \($1) \(value($2))") },
                                                                     edgeAttribute: { calls.append("e \($0) \($1) \(value($2))") },
                                                                     graphAttribute: { calls.append("g \($0) \(value($1))") })
                        return "\(Array(g.vertices)) \(g.edges.map { "\($0.u)-\($0.v)" })"
                    }
                    let g = try AdjacencyList<String>(nodeLinkJSON: text.utf8, vertex: { calls.append("map \($0)"); return Self.merge($0) },
                                                      vertexAttribute: { calls.append("v \($0) \($1) \(value($2))") },
                                                      edgeAttribute: { calls.append("e \($0) \($1) \(value($2))") },
                                                      graphAttribute: { calls.append("g \($0) \(value($1))") })
                    return "\(Array(g.vertices)) \(g.edges.map { "\($0.source)>\($0.target)" })"
                }, { $0 })
                #expect(a == b, "\(seed) \(undirected): \(text)")
            }
        }
    }

    /// The mapping of the merging tests: strings lowercased (so "A" and "a" are one vertex), "bad"
    /// refused, integers folded modulo 5.
    static func merge(_ id: AttributeValue) -> String? {
        switch id {
        case .string("bad"): nil
        case .string(let s): s.lowercased()
        case .integer(let i): "#\(i % 5)"
        default: nil
        }
    }

    @Test("Node-link: the documents NetworkX writes, with attributes everywhere, read the same both ways")
    func nodeLinkNetworkXLayout() throws {
        let text = "{\"directed\": true, \"multigraph\": true, \"graph\": {\"name\": \"g\", \"n\": 2}, \"nodes\": [{\"color\": \"red\", \"id\": 0}, {\"id\": 1, \"w\": 0.5}, {\"id\": \"x\"}], \"edges\": [{\"weight\": 0.25, \"source\": 0, \"target\": 1, \"key\": 0}, {\"weight\": 1.5, \"source\": 0, \"target\": 1, \"key\": 1}, {\"source\": 1, \"target\": \"x\", \"key\": 0, \"label\": \"e\"}, {\"weight\": 3, \"source\": 0, \"target\": 1, \"key\": 0}]}"
        let general = String(text.dropLast()) + ", \"other\": [1, {\"a\": null}]}"
        func show(_ v: AttributeValue) -> String {
            switch v {
            case .string(let s): "s:\(s)"
            case .integer(let i): "i:\(i)"
            case .double(let d): "d:\(d)"
            case .boolean(let b): "b:\(b)"
            }
        }
        for input in [text, general] {
            var log: [String] = []
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { log.append("v \($0) \($1) \(show($2))") },
                                                        edgeAttribute: { log.append("e \($0) \($1) \(show($2))") },
                                                        graphAttribute: { log.append("g \($0) \(show($1))") })
            #expect(Array(graph.vertices) == ["0", "1", "x"])
            #expect(graph.edges.map { "\($0.source)>\($0.target)" } == ["0>1", "0>1", "1>x"])
            #expect(log == ["g name s:g", "g n i:2", "v 0 color s:red", "v 1 w d:0.5", "e 0 weight d:0.25", "e 1 weight d:1.5", "e 2 label s:e",
                            "e 0 weight i:3"])
        }
    }

    @Test("Node-link: documents just outside NetworkX's layout read as the two-pass reader reads them")
    func nodeLinkNearLayout() {
        let nodes = "\"nodes\": [{\"id\": 1}, {\"id\": 2}]"
        let edges = "\"edges\": [{\"source\": 1, \"target\": 2}]"
        let documents = [
            "{\"directed\": true, \"directed\": true, \(nodes), \(edges)}",
            "{\"directed\": true, \(nodes), \(edges), \"links\": []}",
            "{\"directed\": true, \(edges), \(nodes)}",
            "{\"directed\": true, \(nodes)}",
            "{\"directed\": true, \(nodes), \(edges)} x",
            "{\"directed\": true, \(nodes), \(edges)}  \n",
            "{\"directed\": true, \"graph\": {\"a\": null}, \(nodes), \(edges)}",
            "{\"directed\": true, \"graph\": {\"a\": 1, \"a\": 2}, \(nodes), \(edges)}",
            "{\"directed\": true, \"graph\": [], \(nodes), \(edges)}",
            "{\"directed\": true, \"multigraph\": \"no\", \(nodes), \(edges)}",
            "{\"directed\": true, \"nod\\u0065s\": [{\"id\": 1}], \(edges)}",
            "{\"directed\": true, \"nodes\": [{\"id\": 1, \"a_long_attribute\": 1, \"a_long_attribute\": 2}], \(edges)}",
            "{\"directed\": true, \"nodes\": [{\"i\\u0064\": 1}], \(edges)}",
            "{\"directed\": true, \"nodes\": [{\"id\": 1, \"x\": -9223372036854775808}, {\"id\": 2, \"x\": 9223372036854775808}], \(edges)}",
            "{\"directed\": true, \"nodes\": [{\"id\": 1}, {\"id\": 2}, {\"id\": 3, " + (0 ..< 20).map { "\"k\($0)\": \($0)" }.joined(separator: ", ") + "}], \(edges)}",
            "{\"directed\": true, \(nodes), \"edges\": [{\"source\": 1, \"target\": 2, \"key\": [0]}]}",
            "{\"directed\": true, \"multigraph\": false, \(nodes), \"edges\": [{\"source\": 1, \"target\": 2, \"key\": [0]}]}",
            "{\"directed\": true, \(nodes), \"edges\": [{\"source\": 1, \"target\": 2, \"w\": 1e400}]}",
            "{\"directed\": true, \(nodes), \"edges\": [{\"source\": 1, \"target\": 2, \"w\": 1.5e3, \"v\": -0.0, \"u\": 0e0}]}",
            "{\"directed\": true, \(nodes), \"edges\": [{\"source\": 1, \"target\": 3}]}",
            "{\"directed\": true, \"nodes\": [{\"id\": \"1\"}, {\"id\": 1}], \"edges\": [{\"source\": \"1\", \"target\": 1}]}",
            "{\"directed\": true, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"a\"}], \"edges\": []}",
            "{\"directed\": true, \"nodes\": [{\"id\": 5}, {\"id\": 5}], \"edges\": []}",
            "{\"directed\": true, \"nodes\": [{\"id\": 50000000000}, {\"id\": 50000000000}], \"edges\": []}",
            "{\"directed\": true, \"nodes\": [], \"edges\": []}",
            "{ \"directed\" : true , \"nodes\" : [ { \"id\" : 1 } ] , \"edges\" : [ ] }",
        ]
        func read(_ text: String) -> (String, ParseError?) {
            var log: [String] = []
            do throws(ParseError) {
                let g = try DirectedPseudograph<String>(nodeLinkJSON: text.utf8, vertex: { log.append("map \($0)"); return "\($0)" },
                                                        vertexAttribute: { log.append("v \($0) \($1) \($2)") },
                                                        edgeAttribute: { log.append("e \($0) \($1) \($2)") },
                                                        graphAttribute: { log.append("g \($0) \($1)") })
                return ("\(Array(g.vertices)) \(g.edges.map { "\($0.source)>\($0.target)" }) \(log)", nil)
            } catch {
                return ("\(error.kind) \(log)", error)
            }
        }
        for text in documents {
            // An ignored member first sends the document to the two-pass reader, and moves every
            // position after the brace by its length.
            let general = "{\"zz\": 0, " + text.dropFirst()
            let (a, errorA) = read(text), (b, errorB) = read(general)
            #expect(a == b, "\(text)")
            if let errorA, let errorB {
                #expect(errorB.byteOffset == errorA.byteOffset || errorB.byteOffset == errorA.byteOffset + 9, "\(text)")
            }
        }
    }

    @Test("GraphML: a key after the graph stops the lookahead, so its default reaches the nodes; -0 keeps its sign")
    func graphMLLateKeyAndNegativeZero() throws {
        let text = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"d\" for=\"node\" attr.name=\"d\" attr.type=\"double\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"d\">-0</data></node><node id=\"b\"><data key=\"d\">0</data></node><edge source=\"a\" target=\"b\"/><edge source=\"b\" target=\"a\"><data key=\"e\">2</data></edge></graph><key id=\"e\" for=\"edge\" attr.name=\"w\" attr.type=\"int\"/><key id=\"late\" for=\"node\" attr.name=\"late\" attr.type=\"string\"><default>x</default></key></graphml>"
        var log: [String] = []
        let graph = try DirectedPseudograph<String>(graphML: text.utf8, vertexAttribute: { v, k, value in
            if case .double(let d) = value { log.append("v \(v) \(k) \(d.sign == .minus ? "-" : "+")\(d.magnitude)") } else { log.append("v \(v) \(k) \(value)") }
        }, edgeAttribute: { log.append("e \($0) \($1) \($2)") })
        #expect(graph.edgeCount == 2)
        #expect(log == ["v a d -0.0", "v a late x", "v b d +0.0", "v b late x", "e 1 w 2"])
        // A late key nothing names: only its default tells.
        let quiet = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"undirected\"><node id=\"a\"/><node id=\"b\"/><edge source=\"a\" target=\"b\"/></graph><key id=\"late\" for=\"all\" attr.name=\"late\" attr.type=\"int\"><default>3</default></key></graphml>"
        log = []
        _ = try Pseudograph<String>(graphML: quiet.utf8, vertexAttribute: { log.append("v \($0) \($1) \($2)") },
                                    edgeAttribute: { log.append("e \($0) \($1) \($2)") }, graphAttribute: { log.append("g \($0) \($1)") })
        #expect(log == ["g late 3", "v a late 3", "v b late 3", "e 0 late 3"])
    }

    @Test("GraphML: a value written in pieces (around a comment, a CDATA section, a processing instruction, a reference) is the pieces joined")
    func graphMLValuePieces() throws {
        let values = ["a<!--x-->b", "<![CDATA[x]]>y", "x<![CDATA[y]]>", "p&amp;q", "1<?pi?>2", "&lt;b<!---->c"]
        let nodes = values.enumerated().map { "<node id=\"n\($0)\"><data key=\"s\">\($1)</data></node>" }.joined()
        let edges = values.indices.map { "<edge source=\"n\($0)\" target=\"n0\"><data key=\"t\">\(values[$0])</data></edge>" }.joined()
        let text = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"s\" for=\"node\" attr.name=\"s\"/><key id=\"t\" for=\"edge\" attr.name=\"t\"/><graph edgedefault=\"directed\">\(nodes)\(edges)</graph></graphml>"
        var vertexLog: [String] = [], edgeLog: [String] = []
        _ = try DirectedPseudograph<String>(graphML: text.utf8, vertexAttribute: { vertexLog.append("\($0) \($2)") }, edgeAttribute: { edgeLog.append("\($0) \($2)") })
        let joined = ["ab", "xy", "xy", "p&q", "12", "<bc"]
        #expect(vertexLog == joined.enumerated().map { "n\($0) \($1)" })
        #expect(edgeLog == joined.enumerated().map { "\($0) \($1)" })
    }

    @Test("GraphML: an edge's port attributes are unsupported, at the attribute")
    func graphMLEdgePorts() {
        for attribute in ["sourceport", "targetport"] {
            let text = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><edge source=\"a\" target=\"a\" \(attribute)=\"p\"/></graph></graphml>"
            let offset = text.utf8.distance(from: text.startIndex, to: text.firstRange(of: attribute)!.lowerBound)
            #expect(throws: ParseError(kind: .unsupported, line: 1, column: offset + 1, byteOffset: offset)) {
                try DirectedPseudograph<String>(graphML: text.utf8)
            }
        }
    }

    @Test("GraphML: defaults for every domain cross the budget at the element they reach, the graph's spent first")
    func graphMLBudgetCrossing() throws {
        // Each key applies to the graph and every node; the budget is 16 calls per byte plus
        // 4,096, and the graph's defaults are spent before any node's. With the node count where
        // the graph's share decides, the last node crosses it.
        let k = 600
        let keys = (0 ..< k).map { "<key id=\"k\($0)\" for=\"all\"><default>1</default></key>" }.joined()
        func document(_ nodes: Int) -> String {
            "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">\(keys)<graph edgedefault=\"directed\">"
                + (0 ..< nodes).map { "<node id=\"n\($0)\"/>" }.joined() + "</graph></graphml>"
        }
        var nodes = 1
        while k * (nodes + 1) <= 16 * document(nodes).utf8.count + 4096 { nodes += 1 }
        let text = document(nodes)
        #expect(k * nodes <= 16 * text.utf8.count + 4096)
        func read(_ input: String) -> String {
            var calls = 0
            do throws(ParseError) {
                let g = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { _, _, _ in calls += 1 }, graphAttribute: { _, _ in calls += 1 })
                return "\(g.vertexCount) \(calls)"
            } catch {
                return "\(error.kind) \(error.byteOffset) \(calls)"
            }
        }
        let offset = text.utf8.distance(from: text.startIndex, to: text.range(of: "<node id=\"n\(nodes - 1)\"/>")!.lowerBound)
        #expect(read(text) == "limitExceeded \(offset) \(k)")
    }

    @Test("GraphML: the lookahead reads as the second walk reads, on random documents and errors", arguments: 0 ..< 400 as Range<UInt>)
    func graphMLLookahead(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        func pick<T>(_ options: [T]) -> T { options[Int.random(in: 0 ..< options.count, using: &rng)] }
        func chance(_ p: Double) -> Bool { Double.random(in: 0 ..< 1, using: &rng) < p }
        let types = ["int", "long", "double", "float", "boolean", "string"]
        func value(_ type: String) -> String {
            let good: [String] = switch type {
            case "int", "long": ["1", " -7 ", "0", "9223372036854775807"]
            case "double", "float": ["0.5", "1e3", "-0", "-0.0", "INF", "NaN", " 2.5 ", "7", "1.7976931348623157e309"]
            case "boolean": ["true", "0", " false "]
            default: ["x", "", "a&amp;b"]
            }
            return chance(0.04) ? pick(["1.5", "yes", "x", "99999999999999999999"]) : pick(good)
        }
        var keys: [(id: String, domain: String, type: String)] = []
        var header: [String] = []
        for k in 0 ..< Int.random(in: 0 ... 4, using: &rng) {
            let domain = pick(["node", "edge", "all", "graph"])
            let type = pick(types)
            let id = chance(0.03) && k > 0 ? "k0" : "k\(k)"
            keys.append((id, domain, type))
            let name = pick(["w", "label", "w", "x\(k)"])
            if chance(0.15) {
                header.append("<key id=\"\(id)\" for=\"\(domain)\" attr.name=\"\(name)\" attr.type=\"\(type)\"><default>\(value(type))</default></key>")
            } else {
                header.append("<key id=\"\(id)\" for=\"\(domain)\" attr.name=\"\(name)\" attr.type=\"\(chance(0.02) ? "decimal" : type)\"/>")
            }
        }
        func data(_ domain: String) -> String {
            let fitting = keys.filter { $0.domain == domain || $0.domain == "all" }
            var parts: [String] = []
            for _ in 0 ..< Int.random(in: 0 ... 2, using: &rng) {
                if chance(0.05) || fitting.isEmpty {
                    if chance(0.3) { parts.append("<data key=\"nope\">1</data>") }
                    continue
                }
                let key = pick(fitting)
                parts.append("<data key=\"\(key.id)\">\(value(key.type))</data>")
            }
            return parts.joined()
        }
        let directed = chance(0.5)
        let ids = ["a", "b", "c", "d", "\u{E9}", "e\u{301}", "B", "bad", "x&amp;y"]
        let nodeIDs = Array(ids.shuffled(using: &rng).prefix(Int.random(in: 0 ... 5, using: &rng)))
        var body: [String] = []
        var declared: [String] = []
        for id in nodeIDs {
            let extra = chance(0.03) ? "<port name=\"p\"/>" : ""
            body.append(chance(0.02) ? "<node>\(data("node"))</node>" : "<node id=\"\(id)\">\(data("node"))\(extra)</node>")
            declared.append(id)
            if chance(0.04) { body.append("<node id=\"\(id)\"/>") }
            for _ in 0 ..< Int.random(in: 0 ... 2, using: &rng) where !declared.isEmpty {
                let source = chance(0.9) ? pick(declared) : pick(ids), target = chance(0.85) ? pick(declared) : pick(ids)
                let flag = chance(0.05) ? " directed=\"\(pick(["true", "false", "1", "maybe"]))\"" : ""
                let port = chance(0.02) ? " sourceport=\"p\"" : ""
                body.append(chance(0.02) ? "<edge target=\"\(target)\"/>" : "<edge source=\"\(source)\" target=\"\(target)\"\(flag)\(port)>\(data("edge"))</edge>")
            }
        }
        if chance(0.2), let first = nodeIDs.first {
            // An edge before a node it names: it waits, with every later edge.
            body.insert("<edge source=\"\(first)\" target=\"\(nodeIDs.last!)\">\(data("edge"))</edge>", at: 0)
        }
        if chance(0.02) { body.append("<hyperedge/>") }
        let graphData = chance(0.3) ? data("graph") : ""
        let graph = "<graph edgedefault=\"\(chance(0.97) ? (directed ? "directed" : "undirected") : "both")\">\(graphData)\(body.joined())</graph>"
        let lookahead = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">\(header.joined())\(graph)</graphml>"
        let secondWalk = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">\(header.joined())\(graph)<key id=\"unused\" for=\"node\" attr.name=\"unused\"/></graphml>"

        func render(_ text: String, simple: Bool) -> String {
            var log: [String] = []
            func show(_ v: AttributeValue) -> String {
                if case .double(let d) = v { return d.isNaN ? "nan" : "d\(d.bitPattern)" }
                return "\(v)"
            }
            do throws(ParseError) {
                switch (directed, simple) {
                case (true, false):
                    let g = try DirectedPseudograph<String>(graphML: text.utf8, vertex: { log.append("map \($0)"); return $0 == "bad" ? nil : $0.lowercased() },
                                                            vertexAttribute: { log.append("v \($0) \($1) \(show($2))") },
                                                            edgeAttribute: { log.append("e \($0) \($1) \(show($2))") },
                                                            graphAttribute: { log.append("g \($0) \(show($1))") })
                    return "\(Array(g.vertices)) \(g.edges.map { "\($0.source)>\($0.target)" }) \(log)"
                case (true, true):
                    let g = try AdjacencyList<String>(graphML: text.utf8, vertexAttribute: { log.append("v \($0) \($1) \(show($2))") },
                                                      edgeAttribute: { log.append("e \($0) \($1) \(show($2))") },
                                                      graphAttribute: { log.append("g \($0) \(show($1))") })
                    return "\(Array(g.vertices)) \(g.edges.map { "\($0.source)>\($0.target)" }) \(log)"
                case (false, false):
                    let g = try Pseudograph<String>(graphML: text.utf8, vertexAttribute: { log.append("v \($0) \($1) \(show($2))") },
                                                    edgeAttribute: { log.append("e \($0) \($1) \(show($2))") },
                                                    graphAttribute: { log.append("g \($0) \(show($1))") })
                    return "\(Array(g.vertices)) \(g.edges.map { "\($0.u)-\($0.v)" }) \(log)"
                case (false, true):
                    let g = try UndirectedAdjacencyList<String>(graphML: text.utf8, vertex: { log.append("map \($0)"); return $0 == "bad" ? nil : $0.lowercased() },
                                                                vertexAttribute: { log.append("v \($0) \($1) \(show($2))") },
                                                                edgeAttribute: { log.append("e \($0) \($1) \(show($2))") },
                                                                graphAttribute: { log.append("g \($0) \(show($1))") })
                    return "\(Array(g.vertices)) \(g.edges.map { "\($0.u)-\($0.v)" }) \(log)"
                }
            } catch {
                return "\(error) \(log)"
            }
        }
        for simple in [false, true] {
            #expect(render(lookahead, simple: simple) == render(secondWalk, simple: simple), "\(seed) \(simple): \(lookahead)")
        }
    }

    @Test("GraphML: vertex and edge attributes are reported in document order, interleaved, after the build")
    func graphMLAttributeOrder() throws {
        let text = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"w\" for=\"all\" attr.name=\"w\" attr.type=\"double\"/><graph edgedefault=\"directed\"><data key=\"w\">9</data><node id=\"a\"><data key=\"w\">1</data></node><node id=\"b\"><data key=\"w\">2</data></node><edge source=\"a\" target=\"b\"><data key=\"w\">3</data></edge><node id=\"c\"><data key=\"w\">4</data></node><edge source=\"b\" target=\"c\"><data key=\"w\">5</data></edge><edge source=\"c\" target=\"a\"/><edge source=\"c\" target=\"b\"><data key=\"w\">6</data></edge></graph></graphml>"
        let later = text.replacingOccurrences(of: "</graph>", with: "</graph><key id=\"u\" for=\"node\" attr.name=\"u\"/>")
        for input in [text, later] {
            var log: [String] = []
            let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { log.append("v \($0) \($1) \($2)") },
                                                        edgeAttribute: { log.append("e \($0) \($1) \($2)") },
                                                        graphAttribute: { log.append("g \($0) \($1)") })
            #expect(graph.edgeCount == 4)
            #expect(log == ["g w 9.0", "v a w 1.0", "v b w 2.0", "e 0 w 3.0", "v c w 4.0", "e 1 w 5.0", "e 3 w 6.0"])
        }
        // A run of one double per edge in order, broken by an edge without one.
        for input in ["<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"w\" for=\"edge\" attr.name=\"w\" attr.type=\"double\"/><graph edgedefault=\"directed\"><node id=\"a\"/><edge source=\"a\" target=\"a\"/><edge source=\"a\" target=\"a\"><data key=\"w\">1</data></edge></graph></graphml>"] {
            var log: [String] = []
            _ = try DirectedPseudograph<String>(graphML: input.utf8, edgeAttribute: { log.append("e \($0) \($1) \($2)") })
            #expect(log == ["e 1 w 1.0"])
        }
    }

    @Test("Mermaid: vertex and edge labels are reported in document order, after the build, and not at all on an error")
    func mermaidLabelOrder() throws {
        var log: [String] = []
        let graph = try DirectedPseudograph<String>(mermaid: "flowchart LR\nA[x] -->|e1| B[y] --> C\nB -->|e2| A[z]\n".utf8,
                                                    vertexLabel: { log.append("v \($0) \($1)") }, edgeLabel: { log.append("e \($0) \($1)") })
        #expect(graph.edgeCount == 3)
        #expect(log == ["v A x", "v B y", "e 0 e1", "v A z", "e 2 e2"])
        log = []
        #expect(throws: ParseError.self) {
            try DirectedPseudograph<String>(mermaid: "flowchart LR\nA[x] -->|e1| B\nC ---\n".utf8,
                                            vertexLabel: { log.append("v \($0) \($1)") }, edgeLabel: { log.append("e \($0) \($1)") })
        }
        #expect(log == [])
    }
}
