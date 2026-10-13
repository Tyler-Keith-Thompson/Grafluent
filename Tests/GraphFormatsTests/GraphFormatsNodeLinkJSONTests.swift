// Node-link JSON (catalog GF-083 – GF-110, GF-228 and GF-229 read, GF-200 – GF-206 write): the layout over
// strict RFC 8259 JSON, scalar attributes only; ref.py checks the write rows byte for byte against
// json.dumps(node_link_data).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats node-link JSON")
struct GraphFormatsNodeLinkJSONTests {
    @Test("GF-083 NetworkX's node_link_data(path_graph(3))")
    func gf083() throws {
        // Pseudograph<Int>(nodeLinkJSON:) → U: 0, 1, 2; 0-1, 1-2
        let input = "{\"directed\": false, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": 0}, {\"id\": 1}, {\"id\": 2}], \"edges\": [{\"source\": 0, \"target\": 1}, {\"source\": 1, \"target\": 2}]}"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<Int>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-084 string ids, typed attributes")
    func gf084() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: a{color="red"}, b{n=-3, x=0.5, ok=true}; a>b{w=2.0}; graph{name="g"}
        let input = "{\"directed\": true, \"multigraph\": false, \"graph\": {\"name\": \"g\"}, \"nodes\": [{\"color\": \"red\", \"id\": \"a\"}, {\"id\": \"b\", \"n\": -3, \"x\": 0.5, \"ok\": true}], \"edges\": [{\"w\": 2.0, \"source\": \"a\", \"target\": \"b\"}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(vertexKeys == ["a": ["color"], "b": ["n", "x", "ok"]])
        #expect(vertexValues == ["a": ["color": .string("red")], "b": ["n": .integer(-3), "x": .double(0.5), "ok": .boolean(true)]])
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .double(2.0)]])
        #expect(graphKeys == ["name"])
        #expect(graphValues == ["name": .string("g")])
    }

    @Test("GF-085 integer ids into a String target are their decimal text")
    func gf085() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: 10, x; 10>x
        let input = "{\"directed\": true, \"nodes\": [{\"id\": 10}, {\"id\": \"x\"}], \"edges\": [{\"source\": 10, \"target\": \"x\"}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["10", "x"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["10", "x"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-086 multigraph true: parallel edges kept, key ignored")
    func gf086() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: a, b; a>b, a>b{w=2}
        let input = "{\"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"key\": 0}, {\"source\": \"a\", \"target\": \"b\", \"key\": 1, \"w\": 2}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [1: ["w"]])
        #expect(edgeValues == [1: ["w": .integer(2)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-087 multigraph false: parallel edges merge, later attributes win")
    func gf087() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: a, b; a>b{w=2, c="x"}
        let input = "{\"directed\": true, \"multigraph\": false, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"w\": 1}, {\"source\": \"a\", \"target\": \"b\", \"w\": 2, \"c\": \"x\"}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w", "c"]])
        #expect(edgeValues == [0: ["w": .integer(2), "c": .string("x")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-088 defaults as NetworkX: directed false, multigraph true")
    func gf088() throws {
        // Pseudograph<String>(nodeLinkJSON:) → U: a, b; a-b, b-a
        let input = "{\"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\"}, {\"source\": \"b\", \"target\": \"a\"}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-089 \"links\" is read when \"edges\" is absent (NetworkX before 3.4)")
    func gf089() throws {
        // Pseudograph<String>(nodeLinkJSON:) → U: a; a-a
        let input = "{\"nodes\": [{\"id\": \"a\"}], \"links\": [{\"source\": \"a\", \"target\": \"a\"}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-090 string escapes and a surrogate pair")
    func gf090() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: "é\n\"\\/😀"
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"\\u00e9\\n\\\"\\\\\\/\\ud83d\\ude00\"}], \"edges\": []}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["é\n\"\\/😀"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-091 unknown top-level members are ignored")
    func gf091() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D:
        let input = "{\"directed\": true, \"nodes\": [], \"edges\": [], \"extra\": [1, {\"x\": null}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-092 directed into an undirected target")
    func gf092() {
        // Pseudograph<String>(nodeLinkJSON:) → **kindMismatch** at 1:14
        let input = "{\"directed\": true, \"nodes\": [], \"edges\": []}"
        do {
            let graph = try Pseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 14, 13])
        }
    }

    @Test("GF-093 duplicate object key")
    func gf093() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **duplicateKey** at 1:20
        let input = "{\"directed\": true, \"directed\": true, \"nodes\": [], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 20, 19])
        }
    }

    @Test("GF-094 duplicate vertex (1 and \"1\" in a String target)")
    func gf094() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **duplicateVertex** at 1:48
        let input = "{\"directed\": true, \"nodes\": [{\"id\": 1}, {\"id\": \"1\"}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 48, 47])
        }
    }

    @Test("GF-095 string id into an Int target")
    func gf095() {
        // DirectedPseudograph<Int>(nodeLinkJSON:) → **invalidVertex** at 1:37
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a\"}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<Int>(nodeLinkJSON: input.utf8)
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 37, 36])
        }
    }

    @Test("GF-096 edge to an undeclared vertex")
    func gf096() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **undeclaredVertex** at 1:80
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\"}]}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected undeclaredVertex, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 80, 79])
        }
    }

    @Test("GF-097 null attribute (unsupported)")
    func gf097() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **unsupported** at 1:47
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a\", \"x\": null}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 47, 46])
        }
    }

    @Test("GF-098 array attribute (unsupported)")
    func gf098() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **unsupported** at 1:47
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a\", \"x\": [1]}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 47, 46])
        }
    }

    @Test("GF-099 nesting deeper than 64")
    func gf099() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **nestingTooDeep** at 1:108
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a\", \"x\": [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 108, 107])
        }
    }

    @Test("GF-100 number overflows Double")
    func gf100() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **numberOutOfRange** at 1:35
        let input = "{\"directed\": true, \"graph\": {\"x\": 1e400}, \"nodes\": [], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 35, 34])
        }
    }

    @Test("GF-101 integer beyond Int64")
    func gf101() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **numberOutOfRange** at 1:35
        let input = "{\"directed\": true, \"graph\": {\"x\": 9223372036854775808}, \"nodes\": [], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 35, 34])
        }
    }

    @Test("GF-102 lone surrogate")
    func gf102() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **invalidValue** at 1:38
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"\\ud800\"}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 38, 37])
        }
    }

    @Test("GF-103 trailing comma")
    func gf103() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:45
        let input = "{\"directed\": true, \"nodes\": [], \"edges\": [],}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 45, 44])
        }
    }

    @Test("GF-104 NaN is not JSON")
    func gf104() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:35
        let input = "{\"directed\": true, \"graph\": {\"x\": NaN}, \"nodes\": [], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 35, 34])
        }
    }

    @Test("GF-105 leading zero")
    func gf105() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:36
        let input = "{\"directed\": true, \"graph\": {\"x\": 01}, \"nodes\": [], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 36, 35])
        }
    }

    @Test("GF-106 raw control character in a string")
    func gf106() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:39
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a\tb\"}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 39, 38])
        }
    }

    @Test("GF-107 missing nodes")
    func gf107() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:1
        let input = "{\"directed\": true, \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-108 top level is not an object")
    func gf108() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:1
        let input = "[]"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-109 unterminated string")
    func gf109() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **unexpectedEndOfInput** at 1:37
        let input = "{\"directed\": true, \"nodes\": [{\"id\": \"a}]}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 37, 36])
        }
    }

    @Test("GF-110 missing id")
    func gf110() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:30
        let input = "{\"directed\": true, \"nodes\": [{\"x\": 1}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 30, 29])
        }
    }

    @Test("GF-200 empty digraph")
    func gf200() {
        // writeNodeLinkJSON(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        graph.writeNodeLinkJSON(to: &output)
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [], \"edges\": []}")
    }

    @Test("GF-201 path, string ids")
    func gf201() {
        // writeNodeLinkJSON(to:) on D: a, b, c; a>b, b>c
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        var output = ""
        graph.writeNodeLinkJSON(to: &output)
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}, {\"id\": \"c\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\"}, {\"source\": \"b\", \"target\": \"c\"}]}")
    }

    @Test("GF-202 typed attributes")
    func gf202() {
        // writeNodeLinkJSON(to:) on D: a{label="x y", n=3, x=2.0, ok=true}, b; a>b{weight=2, w2=-0.5}, b>b{weight=1.5}; graph{title="G"}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        graph.writeNodeLinkJSON(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("label", .string("x y")), ("n", .integer(3)), ("x", .double(2.0)), ("ok", .boolean(true))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(2)), ("w2", .double(-0.5))]
            case 1: [("weight", .double(1.5))]
            default: []
            }
        }, graphAttributes: [("title", .string("G"))])
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {\"title\": \"G\"}, \"nodes\": [{\"label\": \"x y\", \"n\": 3, \"x\": 2.0, \"ok\": true, \"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"weight\": 2, \"w2\": -0.5, \"source\": \"a\", \"target\": \"b\"}, {\"weight\": 1.5, \"source\": \"b\", \"target\": \"b\"}]}")
    }

    @Test("GF-203 Int vertices are numbers")
    func gf203() {
        // writeNodeLinkJSON(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var output = ""
        graph.writeNodeLinkJSON(to: &output)
        #expect(output == "{\"directed\": false, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": 0}, {\"id\": 1}, {\"id\": 2}], \"edges\": [{\"source\": 0, \"target\": 1}, {\"source\": 1, \"target\": 2}]}")
    }

    @Test("GF-204 parallel edges: multigraph true and NetworkX's keys")
    func gf204() {
        // writeNodeLinkJSON(to:) on D: a, b; a>b, b>a{w=1}, a>b, a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b")])
        var output = ""
        graph.writeNodeLinkJSON(to: &output, edgeAttributes: { e in
            switch e {
            case 1: [("w", .integer(1))]
            default: []
            }
        })
        #expect(output == "{\"directed\": true, \"multigraph\": true, \"graph\": {}, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"key\": 0}, {\"w\": 1, \"source\": \"b\", \"target\": \"a\", \"key\": 0}, {\"source\": \"a\", \"target\": \"b\", \"key\": 1}, {\"source\": \"a\", \"target\": \"b\", \"key\": 2}]}")
    }

    @Test("GF-205 undirected parallel edges: b-a is the second a-b")
    func gf205() {
        // writeNodeLinkJSON(to:) on U: a, b; a-b, b-a
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "a")])
        var output = ""
        graph.writeNodeLinkJSON(to: &output)
        #expect(output == "{\"directed\": false, \"multigraph\": true, \"graph\": {}, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"key\": 0}, {\"source\": \"b\", \"target\": \"a\", \"key\": 1}]}")
    }

    @Test("GF-206 non-ASCII and control characters are escaped")
    func gf206() {
        // writeNodeLinkJSON(to:) on D: "é"{s="\b\f/'"}, "😀", "c\u0001"; "é">"😀"
        let graph = DirectedPseudograph<String>(vertices: ["é", "😀", "c\u{1}"], edges: [DirectedEdge(from: "é", to: "😀")])
        var output = ""
        graph.writeNodeLinkJSON(to: &output, vertexAttributes: { v in
            switch v {
            case "é": [("s", .string("\u{8}\u{C}/'"))]
            default: []
            }
        })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"s\": \"\\b\\f/'\", \"id\": \"\\u00e9\"}, {\"id\": \"\\ud83d\\ude00\"}, {\"id\": \"c\\u0001\"}], \"edges\": [{\"source\": \"\\u00e9\", \"target\": \"\\ud83d\\ude00\"}]}")
    }

    @Test("GF-228 an id that is neither a string nor an integer")
    func gf228() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **invalidValue** at 1:37
        let input = "{\"directed\": true, \"nodes\": [{\"id\": 1.5}], \"edges\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 37, 36])
        }
    }

    @Test("GF-229 neither edges nor links")
    func gf229() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **syntax** at 1:1
        let input = "{\"directed\": true, \"nodes\": []}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-233 multigraph: an edge whose key is taken is that edge; no key gets new_edge_key")
    func gf233() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: a, b; a>b{w=3}, a>b{w=6}, a>b{w=4}, a>b{w=5}
        let input = "{\"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"w\": 1}, {\"source\": \"a\", \"target\": \"b\", \"key\": 1, \"w\": 2}, {\"source\": \"a\", \"target\": \"b\", \"key\": 0, \"w\": 3}, {\"source\": \"a\", \"target\": \"b\", \"w\": 4}, {\"source\": \"a\", \"target\": \"b\", \"key\": \"1\", \"w\": 5}, {\"source\": \"a\", \"target\": \"b\", \"key\": true, \"w\": 6}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "b"], ["a", "b"], ["a", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"], 1: ["w"], 2: ["w"], 3: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(3)], 1: ["w": .integer(6)], 2: ["w": .integer(4)], 3: ["w": .integer(5)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-234 undirected multigraph: b-a under a-b's key is that edge")
    func gf234() throws {
        // Pseudograph<String>(nodeLinkJSON:) → U: a, b; a-b{w=2}
        let input = "{\"multigraph\": true, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"key\": 0, \"w\": 1}, {\"source\": \"b\", \"target\": \"a\", \"key\": 0, \"w\": 2}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(2)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-235 multigraph: a null key is no key")
    func gf235() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: a; a>a{w=2}
        let input = "{\"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": \"a\"}], \"edges\": [{\"source\": \"a\", \"target\": \"a\", \"key\": null, \"w\": 1}, {\"source\": \"a\", \"target\": \"a\", \"key\": 0, \"w\": 2}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(2)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-236 an array as an edge key")
    func gf236() {
        // DirectedPseudograph<String>(nodeLinkJSON:) → **unsupported** at 1:112
        let input = "{\"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": \"a\"}], \"edges\": [{\"source\": \"a\", \"target\": \"a\", \"key\": [1]}]}"
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 112, 111])
        }
    }

    @Test("GF-248 multigraph: a key-less edge skips keys taken; later keys find it")
    func gf248() throws {
        // DirectedPseudograph<String>(nodeLinkJSON:) → D: a, b; a>b{w=1}, a>b{w=4}, a>b{w=3}
        let input = "{\"directed\": true, \"multigraph\": true, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"key\": 1, \"w\": 1}, {\"source\": \"a\", \"target\": \"b\", \"w\": 2}, {\"source\": \"a\", \"target\": \"b\", \"key\": 0, \"w\": 3}, {\"source\": \"a\", \"target\": \"b\", \"key\": 2, \"w\": 4}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "b"], ["a", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"], 1: ["w"], 2: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(1)], 1: ["w": .integer(4)], 2: ["w": .integer(3)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-256 multigraph: a repeated string key is that edge, in either orientation")
    func gf256() throws {
        // Pseudograph<String>(nodeLinkJSON:) → U: a, b; a-b{w=2}, a-b{w=4}
        let input = "{\"multigraph\": true, \"nodes\": [{\"id\": \"a\"}, {\"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\", \"key\": \"x\", \"w\": 1}, {\"source\": \"b\", \"target\": \"a\", \"key\": \"x\", \"w\": 2}, {\"source\": \"a\", \"target\": \"b\", \"key\": 1.5, \"w\": 3}, {\"source\": \"a\", \"target\": \"b\", \"key\": 1.5, \"w\": 4}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(nodeLinkJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["a", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"], 1: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(2)], 1: ["w": .integer(4)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }
}
