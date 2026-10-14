// Cytoscape JSON (catalog GF-519 – GF-550 read, GF-586 – GF-590 write): elements as an object or an
// array, data as an object or NetworkX's pairs, ids as text; ref.py checks the write rows byte for
// byte against json.dumps(cytoscape_data).
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats Cytoscape JSON")
struct GraphFormatsCytoscapeJSONTests {
    @Test("GF-519 NetworkX's cytoscape_data(path_graph(3))")
    func gf519() throws {
        // Pseudograph<String>(cytoscapeJSON:) → U: 0{value=0, name="0"}, 1{value=1, name="1"}, 2{value=2, name="2"}; 0-1, 1-2
        let input = "{\"data\": [], \"directed\": false, \"multigraph\": false, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"0\", \"value\": 0, \"name\": \"0\"}}, {\"data\": {\"id\": \"1\", \"value\": 1, \"name\": \"1\"}}, {\"data\": {\"id\": \"2\", \"value\": 2, \"name\": \"2\"}}], \"edges\": [{\"data\": {\"source\": 0, \"target\": 1}}, {\"data\": {\"source\": 1, \"target\": 2}}]}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["0", "1", "2"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["0", "1"], ["1", "2"]])
        #expect(vertexKeys == ["0": ["value", "name"], "1": ["value", "name"], "2": ["value", "name"]])
        #expect(vertexValues == ["0": ["value": .integer(0), "name": .string("0")], "1": ["value": .integer(1), "name": .string("1")], "2": ["value": .integer(2), "name": .string("2")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-520 directed, attributes, NetworkX's graph data pairs")
    func gf520() throws {
        // DirectedPseudograph<String>(cytoscapeJSON:) → D: a{color="red", value="a", name="a"}, b; a>b{w=1.5, id="e1"}; graph{name="g", n=2}
        let input = "{\"data\": [[\"name\", \"g\"], [\"n\", 2]], \"directed\": true, \"multigraph\": false, \"elements\": {\"nodes\": [{\"data\": {\"color\": \"red\", \"id\": \"a\", \"value\": \"a\", \"name\": \"a\"}}, {\"data\": {\"id\": \"b\"}}], \"edges\": [{\"data\": {\"w\": 1.5, \"id\": \"e1\", \"source\": \"a\", \"target\": \"b\"}}]}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["color", "value", "name"]])
        #expect(vertexValues == ["a": ["color": .string("red"), "value": .string("a"), "name": .string("a")]])
        #expect(edgeKeys == [0: ["w", "id"]])
        #expect(edgeValues == [0: ["w": .double(1.5), "id": .string("e1")]])
        #expect(graphKeys == ["name", "n"])
        #expect(graphValues == ["name": .string("g"), "n": .integer(2)])
    }

    @Test("GF-521 Cytoscape.js: an array of elements with group; position and classes ignored; data object")
    func gf521() throws {
        // Pseudograph<String>(cytoscapeJSON:) → U: a, b; a-b{id="e"}; graph{title="t"}
        let input = "{\"data\": {\"title\": \"t\"}, \"elements\": [{\"group\": \"nodes\", \"data\": {\"id\": \"a\"}, \"position\": {\"x\": 1, \"y\": 2}, \"classes\": \"c\", \"selected\": false}, {\"group\": \"edges\", \"data\": {\"id\": \"e\", \"source\": \"a\", \"target\": \"b\"}}, {\"group\": \"nodes\", \"data\": {\"id\": \"b\"}}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["id"]])
        #expect(edgeValues == [0: ["id": .string("e")]])
        #expect(graphKeys == ["title"])
        #expect(graphValues == ["title": .string("t")])
    }

    @Test("GF-522 without group, an element is an edge when its data has source")
    func gf522() throws {
        // Pseudograph<String>(cytoscapeJSON:) → U: x, y; x-y
        let input = "{\"elements\": [{\"data\": {\"source\": \"x\", \"target\": \"y\"}}, {\"data\": {\"id\": \"x\"}}, {\"data\": {\"id\": \"y\"}}]}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["x", "y"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["x", "y"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-523 multigraph true: every edge kept, key not reported")
    func gf523() throws {
        // DirectedPseudograph<String>(cytoscapeJSON:) → D: a; a>a, a>a{w=2}
        let input = "{\"directed\": true, \"multigraph\": true, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}], \"edges\": [{\"data\": {\"source\": \"a\", \"target\": \"a\", \"key\": 0}}, {\"data\": {\"source\": \"a\", \"target\": \"a\", \"key\": 0, \"w\": 2}}]}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "a"], ["a", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [1: ["w"]])
        #expect(edgeValues == [1: ["w": .integer(2)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-524 multigraph false: parallel edges kept, key reported")
    func gf524() throws {
        // DirectedPseudograph<String>(cytoscapeJSON:) → D: a; a>a{key=7}, a>a
        let input = "{\"directed\": true, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}], \"edges\": [{\"data\": {\"source\": \"a\", \"target\": \"a\", \"key\": 7}}, {\"data\": {\"source\": \"a\", \"target\": \"a\"}}]}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "a"], ["a", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["key"]])
        #expect(edgeValues == [0: ["key": .integer(7)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-525 simple target: parallel edges merge, last value wins")
    func gf525() throws {
        // AdjacencyList<String>(cytoscapeJSON:) → D: a, b; a>b{w=2}
        let input = "{\"directed\": true, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}, {\"data\": {\"id\": \"b\"}}], \"edges\": [{\"data\": {\"source\": \"a\", \"target\": \"b\", \"w\": 1}}, {\"data\": {\"source\": \"a\", \"target\": \"b\", \"w\": 2}}]}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try AdjacencyList<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["w"]])
        #expect(edgeValues == [0: ["w": .integer(2)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-526 integer ids and endpoints are their decimal text")
    func gf526() throws {
        // Pseudograph<String>(cytoscapeJSON:) → U: 1, 2; 1-2
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": 1}}, {\"data\": {\"id\": \"2\"}}], \"edges\": [{\"data\": {\"source\": \"1\", \"target\": 2}}]}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["1", "2"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["1", "2"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-527 no nodes or edges members")
    func gf527() throws {
        // Pseudograph<String>(cytoscapeJSON:) → U:
        let input = "{\"elements\": {}}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-528 no elements")
    func gf528() {
        // Pseudograph<String>(cytoscapeJSON:) → **syntax** at 1:1
        let input = "{\"directed\": false}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-529 top level not an object")
    func gf529() {
        // Pseudograph<String>(cytoscapeJSON:) → **syntax** at 1:1
        let input = "[]"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-530 directed into an undirected target")
    func gf530() {
        // Pseudograph<String>(cytoscapeJSON:) → **kindMismatch** at 1:14
        let input = "{\"directed\": true, \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 14, 13])
        }
    }

    @Test("GF-531 no directed into a directed target")
    func gf531() {
        // DirectedPseudograph<String>(cytoscapeJSON:) → **kindMismatch** at 1:1
        let input = "{\"elements\": {}}"
        do {
            let graph = try DirectedPseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-532 directed that is not a boolean")
    func gf532() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:14
        let input = "{\"directed\": 0, \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 14, 13])
        }
    }

    @Test("GF-533 multigraph that is not a boolean")
    func gf533() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:16
        let input = "{\"multigraph\": \"no\", \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 16, 15])
        }
    }

    @Test("GF-534 data that is neither an object nor an array")
    func gf534() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:10
        let input = "{\"data\": 1, \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 10, 9])
        }
    }

    @Test("GF-535 a data pair that is not [string, value]")
    func gf535() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:11
        let input = "{\"data\": [[1, 2]], \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-536 a data value that is a list (unsupported)")
    func gf536() {
        // Pseudograph<String>(cytoscapeJSON:) → **unsupported** at 1:16
        let input = "{\"data\": {\"x\": [1]}, \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 16, 15])
        }
    }

    @Test("GF-537 elements that are neither an object nor an array")
    func gf537() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:14
        let input = "{\"elements\": 3}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 14, 13])
        }
    }

    @Test("GF-538 nodes that are not an array")
    func gf538() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:24
        let input = "{\"elements\": {\"nodes\": {}}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 24, 23])
        }
    }

    @Test("GF-539 an element that is not an object")
    func gf539() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:15
        let input = "{\"elements\": [1]}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 15, 14])
        }
    }

    @Test("GF-540 a group other than nodes or edges")
    func gf540() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:25
        let input = "{\"elements\": [{\"group\": \"x\", \"data\": {\"id\": \"a\"}}]}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 25, 24])
        }
    }

    @Test("GF-541 a node without data")
    func gf541() {
        // Pseudograph<String>(cytoscapeJSON:) → **syntax** at 1:25
        let input = "{\"elements\": {\"nodes\": [{\"id\": \"a\"}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 25, 24])
        }
    }

    @Test("GF-542 a node's data that is not an object")
    func gf542() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:34
        let input = "{\"elements\": {\"nodes\": [{\"data\": 1}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 34, 33])
        }
    }

    @Test("GF-543 a node without an id")
    func gf543() {
        // Pseudograph<String>(cytoscapeJSON:) → **syntax** at 1:34
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"name\": \"a\"}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 34, 33])
        }
    }

    @Test("GF-544 an id that is a boolean")
    func gf544() {
        // Pseudograph<String>(cytoscapeJSON:) → **invalidValue** at 1:41
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": true}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 41, 40])
        }
    }

    @Test("GF-545 a node declared twice (1 and \"1\")")
    func gf545() {
        // Pseudograph<String>(cytoscapeJSON:) → **duplicateVertex** at 1:62
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": 1}}, {\"data\": {\"id\": \"1\"}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 62, 61])
        }
    }

    @Test("GF-546 a null attribute (unsupported)")
    func gf546() {
        // Pseudograph<String>(cytoscapeJSON:) → **unsupported** at 1:51
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\", \"x\": null}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 51, 50])
        }
    }

    @Test("GF-547 an edge without a source")
    func gf547() {
        // Pseudograph<String>(cytoscapeJSON:) → **syntax** at 1:68
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}], \"edges\": [{\"data\": {\"target\": \"a\"}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 68, 67])
        }
    }

    @Test("GF-548 an edge to an undeclared node")
    func gf548() {
        // Pseudograph<String>(cytoscapeJSON:) → **undeclaredVertex** at 1:94
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}], \"edges\": [{\"data\": {\"source\": \"a\", \"target\": \"b\"}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected undeclaredVertex, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 94, 93])
        }
    }

    @Test("GF-549 an edge attribute that is an object (unsupported)")
    func gf549() {
        // Pseudograph<String>(cytoscapeJSON:) → **unsupported** at 1:104
        let input = "{\"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}], \"edges\": [{\"data\": {\"source\": \"a\", \"target\": \"a\", \"x\": {}}}]}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 104, 103])
        }
    }

    @Test("GF-550 a duplicate key")
    func gf550() {
        // Pseudograph<String>(cytoscapeJSON:) → **duplicateKey** at 1:18
        let input = "{\"elements\": {}, \"elements\": {}}"
        do {
            let graph = try Pseudograph<String>(cytoscapeJSON: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 18, 17])
        }
    }

    @Test("GF-586 empty digraph")
    func gf586() throws {
        // writeCytoscapeJSON(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeCytoscapeJSON(to: &output)
        #expect(output == "{\"data\": [], \"directed\": true, \"multigraph\": false, \"elements\": {\"nodes\": [], \"edges\": []}}")
    }

    @Test("GF-587 undirected path")
    func gf587() throws {
        // writeCytoscapeJSON(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<String>(vertices: ["0", "1", "2"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("1", "2")])
        var output = ""
        try graph.writeCytoscapeJSON(to: &output)
        #expect(output == "{\"data\": [], \"directed\": false, \"multigraph\": false, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"0\", \"value\": \"0\", \"name\": \"0\"}}, {\"data\": {\"id\": \"1\", \"value\": \"1\", \"name\": \"1\"}}, {\"data\": {\"id\": \"2\", \"value\": \"2\", \"name\": \"2\"}}], \"edges\": [{\"data\": {\"source\": \"0\", \"target\": \"1\"}}, {\"data\": {\"source\": \"1\", \"target\": \"2\"}}]}}")
    }

    @Test("GF-588 typed attributes; a vertex's own name and value stay in place")
    func gf588() throws {
        // writeCytoscapeJSON(to:) on D: a{label="x y", n=3, x=2.0, ok=true}, b{name="B", value=7}; a>b{weight=2, w2=-0.5}, b>b{id="e1"}; graph{title="G", k=1}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        try graph.writeCytoscapeJSON(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("label", .string("x y")), ("n", .integer(3)), ("x", .double(2.0)), ("ok", .boolean(true))]
            case "b": [("name", .string("B")), ("value", .integer(7))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(2)), ("w2", .double(-0.5))]
            case 1: [("id", .string("e1"))]
            default: []
            }
        }, graphAttributes: [("title", .string("G")), ("k", .integer(1))])
        #expect(output == "{\"data\": [[\"title\", \"G\"], [\"k\", 1]], \"directed\": true, \"multigraph\": false, \"elements\": {\"nodes\": [{\"data\": {\"label\": \"x y\", \"n\": 3, \"x\": 2.0, \"ok\": true, \"id\": \"a\", \"value\": \"a\", \"name\": \"a\"}}, {\"data\": {\"name\": \"B\", \"value\": 7, \"id\": \"b\"}}], \"edges\": [{\"data\": {\"weight\": 2, \"w2\": -0.5, \"source\": \"a\", \"target\": \"b\"}}, {\"data\": {\"id\": \"e1\", \"source\": \"b\", \"target\": \"b\"}}]}}")
    }

    @Test("GF-589 parallel edges: multigraph true and NetworkX's keys")
    func gf589() throws {
        // writeCytoscapeJSON(to:) on D: a, b; a>b, b>a{w=1}, a>b, a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeCytoscapeJSON(to: &output, edgeAttributes: { e in
            switch e {
            case 1: [("w", .integer(1))]
            default: []
            }
        })
        #expect(output == "{\"data\": [], \"directed\": true, \"multigraph\": true, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\", \"value\": \"a\", \"name\": \"a\"}}, {\"data\": {\"id\": \"b\", \"value\": \"b\", \"name\": \"b\"}}], \"edges\": [{\"data\": {\"source\": \"a\", \"target\": \"b\", \"key\": 0}}, {\"data\": {\"w\": 1, \"source\": \"b\", \"target\": \"a\", \"key\": 0}}, {\"data\": {\"source\": \"a\", \"target\": \"b\", \"key\": 1}}, {\"data\": {\"source\": \"a\", \"target\": \"b\", \"key\": 2}}]}}")
    }

    @Test("GF-590 non-ASCII and control characters are escaped")
    func gf590() throws {
        // writeCytoscapeJSON(to:) on D: "é"{s="\b\f/'"}, "😀", "c\u0001"; "é">"😀"
        let graph = DirectedPseudograph<String>(vertices: ["é", "😀", "c\u{1}"], edges: [DirectedEdge(from: "é", to: "😀")])
        var output = ""
        try graph.writeCytoscapeJSON(to: &output, vertexAttributes: { v in
            switch v {
            case "é": [("s", .string("\u{8}\u{C}/'"))]
            default: []
            }
        })
        #expect(output == "{\"data\": [], \"directed\": true, \"multigraph\": false, \"elements\": {\"nodes\": [{\"data\": {\"s\": \"\\b\\f/'\", \"id\": \"\\u00e9\", \"value\": \"\\u00e9\", \"name\": \"\\u00e9\"}}, {\"data\": {\"id\": \"\\ud83d\\ude00\", \"value\": \"\\ud83d\\ude00\", \"name\": \"\\ud83d\\ude00\"}}, {\"data\": {\"id\": \"c\\u0001\", \"value\": \"c\\u0001\", \"name\": \"c\\u0001\"}}], \"edges\": [{\"data\": {\"source\": \"\\u00e9\", \"target\": \"\\ud83d\\ude00\"}}]}}")
    }
}
