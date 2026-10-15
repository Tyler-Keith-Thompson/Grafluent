// GML (catalog GF-323 – GF-374 read, GF-551 – GF-558 write): Himsolt's key-value lists, nodes named by
// their labels, typed values, lists skipped, edges resolved after the graph; ref.py checks the write
// rows byte for byte against NetworkX's write_gml.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats GML")
struct GraphFormatsGMLTests {
    @Test("GF-323 NetworkX's write_gml output")
    func gf323() throws {
        // DirectedPseudograph<String>(gml:) → D: a{color="red"}, b; a>b{weight=2.5}; graph{name="g"}
        let input = "graph [\n  directed 1\n  name \"g\"\n  node [\n    id 0\n    label \"a\"\n    color \"red\"\n  ]\n  node [\n    id 1\n    label \"b\"\n  ]\n  edge [\n    source 0\n    target 1\n    weight 2.5\n  ]\n]\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["color"]])
        #expect(vertexValues == ["a": ["color": .string("red")]])
        #expect(edgeKeys == [0: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(2.5)]])
        #expect(graphKeys == ["name"])
        #expect(graphValues == ["name": .string("g")])
    }

    @Test("GF-324 undirected by default; nodes named by their labels")
    func gf324() throws {
        // Pseudograph<String>(gml:) → U: x, y; y-x
        let input = "graph [ node [ id 7 label \"x\" ] node [ id 3 label \"y\" ] edge [ source 3 target 7 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["x", "y"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["y", "x"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-325 a node without a label is named by its id")
    func gf325() throws {
        // Pseudograph<String>(gml:) → U: 5, six; 5-six
        let input = "graph [ node [ id 5 ] node [ id 6 label \"six\" ] edge [ source 5 target 6 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["5", "six"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["5", "six"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-326 values: integers, reals, strings, INF, -INF, NAN, 1.E-05")
    func gf326() throws {
        // DirectedPseudograph<String>(gml:) → D: a{i=-3, r=2.0, e=1e-05, s="t", p=inf, m=-inf, q=inf, n=nan, f=0.5}
        let input = "graph [ directed 1 node [ id 0 label \"a\" i -3 r 2.0 e 1.E-05 s \"t\" p +INF m -INF q INF n NAN f .5 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == ["a": ["i", "r", "e", "s", "p", "m", "q", "n", "f"]])
        #expect(vertexValues.count == 1)
        #expect(vertexValues["a"]?["i"] == .integer(-3))
        #expect(vertexValues["a"]?["r"] == .double(2.0))
        #expect(vertexValues["a"]?["e"] == .double(1e-05))
        #expect(vertexValues["a"]?["s"] == .string("t"))
        #expect(vertexValues["a"]?["p"] == .double(.infinity))
        #expect(vertexValues["a"]?["m"] == .double(-.infinity))
        #expect(vertexValues["a"]?["q"] == .double(.infinity))
        #expect({ if case .double(let x)? = vertexValues["a"]?["n"] { x.isNaN } else { false } }())
        #expect(vertexValues["a"]?["f"] == .double(0.5))
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-327 character references and the four named entities are decoded; others are kept")
    func gf327() throws {
        // DirectedPseudograph<String>(gml:) → D: "éA&<>\"&apos;&nbsp;&#xD800;&#1114112;&"
        let input = "graph [ directed 1 node [ id 0 label \"&#233;&#x41;&amp;&lt;&gt;&quot;&apos;&nbsp;&#xD800;&#1114112;&\" ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["éA&<>\"&apos;&nbsp;&#xD800;&#1114112;&"])
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

    @Test("GF-328 lists such as graphics are skipped; top-level keys are ignored; # comments")
    func gf328() throws {
        // DirectedPseudograph<String>(gml:) → D: a{w=1}; a>a
        let input = "# made by hand\nCreator \"yFiles\"\nVersion 2.2\ngraph [\n  directed 1 # a comment\n  node [ id 0 label \"a\"\n    graphics [ x 1.0 y 2.0 fill \"#FF0000\" inner [ deep 1 ] ] w 1 ]\n  edge [ source 0 target 0 graphics [ width 2 ] ]\n]\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["w"]])
        #expect(vertexValues == ["a": ["w": .integer(1)]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-329 edges may come before the nodes they name; key is an ordinary attribute")
    func gf329() throws {
        // DirectedPseudograph<String>(gml:) → D: a, b; b>a{key=4}
        let input = "graph [ directed 1 edge [ source 1 target 0 key 4 ] node [ id 0 label \"a\" ] node [ id 1 label \"b\" ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["b", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["key"]])
        #expect(edgeValues == [0: ["key": .integer(4)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-330 multigraph 1: parallel edges kept")
    func gf330() throws {
        // DirectedPseudograph<String>(gml:) → D: a; a>a{key=0}, a>a{key=1}
        let input = "graph [ directed 1 multigraph 1 node [ id 0 label \"a\" ] edge [ source 0 target 0 key 0 ] edge [ source 0 target 0 key 1 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["key"], 1: ["key"]])
        #expect(edgeValues == [0: ["key": .integer(0)], 1: ["key": .integer(1)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-331 simple target: parallel edges merge, last value wins")
    func gf331() throws {
        // AdjacencyList<String>(gml:) → D: a, b; a>b{w=2}
        let input = "graph [ directed 1 node [ id 0 label \"a\" ] node [ id 1 label \"b\" ] edge [ source 0 target 1 w 1 ] edge [ source 0 target 1 w 2 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try AdjacencyList<String>(gml: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-332 simple undirected target: 1-0 is 0-1")
    func gf332() throws {
        // UndirectedAdjacencyList<String>(gml:) → U: 0, 1; 0-1
        let input = "graph [ node [ id 0 ] node [ id 1 ] edge [ source 0 target 1 ] edge [ source 1 target 0 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try UndirectedAdjacencyList<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["0", "1"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["0", "1"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-333 a string may span lines")
    func gf333() throws {
        // DirectedPseudograph<String>(gml:) → D: "two\nlines"
        let input = "graph [ directed 1 node [ id 0 label \"two\nlines\" ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["two\nlines"])
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

    @Test("GF-334 a number as a label is its text")
    func gf334() throws {
        // Pseudograph<String>(gml:) → U: "1.50", "-7"
        let input = "graph [ node [ id 0 label 1.50 ] node [ id 1 label -7 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["1.50", "-7"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-335 graph attributes where they are read; a repeated key is reported again")
    func gf335() throws {
        // Pseudograph<String>(gml:) → U: 0, 1{c=2}; graph{a=2, b="x"}
        let input = "graph [ a 1 node [ id 0 ] b \"x\" a 2 node [ id 1 c 1 c 2 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["0", "1"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
        #expect(vertexKeys == ["1": ["c"]])
        #expect(vertexValues == ["1": ["c": .integer(2)]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == ["a", "b"])
        #expect(graphValues == ["a": .integer(2), "b": .string("x")])
    }

    @Test("GF-336 a byte-order mark, CR LF and tabs")
    func gf336() throws {
        // Pseudograph<String>(gml:) → U: 0
        let input = "\u{FEFF}graph [\r\n\tnode [\r\n\t\tid 0\r\n\t]\r\n]\r\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["0"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-337 empty graph")
    func gf337() throws {
        // Pseudograph<String>(gml:) → U:
        let input = "graph [ ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-338 directed 0")
    func gf338() throws {
        // Pseudograph<String>(gml:) → U: 0
        let input = "graph [ directed 0 node [ id 0 ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["0"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-339 no graph")
    func gf339() {
        // Pseudograph<String>(gml:) → **unexpectedEndOfInput** at 2:1
        let input = "Creator \"x\"\n"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-340 empty input")
    func gf340() {
        // Pseudograph<String>(gml:) → **unexpectedEndOfInput** at 1:1
        let input = ""
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-341 a second graph (unsupported)")
    func gf341() {
        // Pseudograph<String>(gml:) → **unsupported** at 1:11
        let input = "graph [ ] graph [ ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-342 graph whose value is not a list")
    func gf342() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:7
        let input = "graph 1"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 7, 6])
        }
    }

    @Test("GF-343 directed that is not 0 or 1")
    func gf343() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:18
        let input = "graph [ directed 2 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 18, 17])
        }
    }

    @Test("GF-344 directed 1 into an undirected target")
    func gf344() {
        // Pseudograph<String>(gml:) → **kindMismatch** at 1:18
        let input = "graph [ directed 1 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 18, 17])
        }
    }

    @Test("GF-345 no directed into a directed target")
    func gf345() {
        // DirectedPseudograph<String>(gml:) → **kindMismatch** at 1:1
        let input = "graph [ node [ id 0 ] ]"
        do {
            let graph = try DirectedPseudograph<String>(gml: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-346 directed 0 into a directed target")
    func gf346() {
        // DirectedPseudograph<String>(gml:) → **kindMismatch** at 1:18
        let input = "graph [ directed 0 ]"
        do {
            let graph = try DirectedPseudograph<String>(gml: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 18, 17])
        }
    }

    @Test("GF-347 directed twice")
    func gf347() {
        // Pseudograph<String>(gml:) → **duplicateKey** at 1:20
        let input = "graph [ directed 0 directed 0 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 20, 19])
        }
    }

    @Test("GF-348 multigraph that is not 0 or 1")
    func gf348() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:20
        let input = "graph [ multigraph \"yes\" ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 20, 19])
        }
    }

    @Test("GF-349 a node without an id")
    func gf349() {
        // Pseudograph<String>(gml:) → **syntax** at 1:9
        let input = "graph [ node [ label \"a\" ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 9, 8])
        }
    }

    @Test("GF-350 an id that is not an integer")
    func gf350() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:19
        let input = "graph [ node [ id \"a\" ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 19, 18])
        }
    }

    @Test("GF-351 two ids in one node")
    func gf351() {
        // Pseudograph<String>(gml:) → **duplicateKey** at 1:21
        let input = "graph [ node [ id 0 id 1 ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 21, 20])
        }
    }

    @Test("GF-352 two labels in one node")
    func gf352() {
        // Pseudograph<String>(gml:) → **duplicateKey** at 1:31
        let input = "graph [ node [ id 0 label \"a\" label \"b\" ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 31, 30])
        }
    }

    @Test("GF-353 a label that is a list")
    func gf353() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:27
        let input = "graph [ node [ id 0 label [ x 1 ] ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 27, 26])
        }
    }

    @Test("GF-354 an id declared twice")
    func gf354() {
        // Pseudograph<String>(gml:) → **duplicateVertex** at 1:33
        let input = "graph [ node [ id 0 ] node [ id 0 ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 33, 32])
        }
    }

    @Test("GF-355 two nodes with one label")
    func gf355() {
        // Pseudograph<String>(gml:) → **duplicateVertex** at 1:51
        let input = "graph [ node [ id 0 label \"a\" ] node [ id 1 label \"a\" ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 51, 50])
        }
    }

    @Test("GF-356 a label equal to another node's id text")
    func gf356() {
        // Pseudograph<String>(gml:) → **duplicateVertex** at 1:41
        let input = "graph [ node [ id 0 ] node [ id 1 label \"0\" ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 41, 40])
        }
    }

    @Test("GF-357 node whose value is not a list")
    func gf357() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:14
        let input = "graph [ node 1 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 14, 13])
        }
    }

    @Test("GF-358 an edge without a target")
    func gf358() {
        // Pseudograph<String>(gml:) → **syntax** at 1:23
        let input = "graph [ node [ id 0 ] edge [ source 0 ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 23, 22])
        }
    }

    @Test("GF-359 a source that is not an integer")
    func gf359() {
        // Pseudograph<String>(gml:) → **invalidValue** at 1:37
        let input = "graph [ node [ id 0 ] edge [ source 0.0 target 0 ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 37, 36])
        }
    }

    @Test("GF-360 two sources in one edge")
    func gf360() {
        // Pseudograph<String>(gml:) → **duplicateKey** at 1:39
        let input = "graph [ node [ id 0 ] edge [ source 0 source 0 target 0 ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 39, 38])
        }
    }

    @Test("GF-361 an edge to an undeclared node")
    func gf361() {
        // Pseudograph<String>(gml:) → **undeclaredVertex** at 1:46
        let input = "graph [ node [ id 0 ] edge [ source 0 target 9 ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected undeclaredVertex, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 46, 45])
        }
    }

    @Test("GF-362 an unterminated string")
    func gf362() {
        // Pseudograph<String>(gml:) → **unexpectedEndOfInput** at 1:27
        let input = "graph [ node [ id 0 label \"a ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 27, 26])
        }
    }

    @Test("GF-363 an unclosed list")
    func gf363() {
        // Pseudograph<String>(gml:) → **unexpectedEndOfInput** at 1:22
        let input = "graph [ node [ id 0 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 22, 21])
        }
    }

    @Test("GF-364 ] at the top level")
    func gf364() {
        // Pseudograph<String>(gml:) → **syntax** at 1:11
        let input = "graph [ ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-365 a number followed by a letter")
    func gf365() {
        // Pseudograph<String>(gml:) → **syntax** at 1:20
        let input = "graph [ node [ id 0x ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 20, 19])
        }
    }

    @Test("GF-366 a string followed by a letter")
    func gf366() {
        // Pseudograph<String>(gml:) → **syntax** at 1:30
        let input = "graph [ node [ id 0 label \"a\"b ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 30, 29])
        }
    }

    @Test("GF-367 a value where a key should be")
    func gf367() {
        // Pseudograph<String>(gml:) → **syntax** at 1:9
        let input = "graph [ 1 2 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 9, 8])
        }
    }

    @Test("GF-368 a key where a value should be")
    func gf368() {
        // Pseudograph<String>(gml:) → **syntax** at 1:19
        let input = "graph [ node [ id label ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 19, 18])
        }
    }

    @Test("GF-369 an integer beyond Int64")
    func gf369() {
        // Pseudograph<String>(gml:) → **numberOutOfRange** at 1:11
        let input = "graph [ x 9223372036854775808 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-370 a real that overflows")
    func gf370() {
        // Pseudograph<String>(gml:) → **numberOutOfRange** at 1:11
        let input = "graph [ x 1e999 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-371 65 nested lists")
    func gf371() {
        // Pseudograph<String>(gml:) → **nestingTooDeep** at 1:263
        let input = "graph [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 263, 262])
        }
    }

    @Test("GF-372 64 nested lists")
    func gf372() throws {
        // Pseudograph<String>(gml:) → U:
        let input = "graph [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ a [ ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ] ]"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gml: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-373 a key starting with an underscore")
    func gf373() {
        // Pseudograph<String>(gml:) → **syntax** at 1:9
        let input = "graph [ _x 1 ]"
        do {
            let graph = try Pseudograph<String>(gml: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 9, 8])
        }
    }

    @Test("GF-374 invalid UTF-8")
    func gf374() {
        // Pseudograph<String>(gml:) → **invalidUTF8** at 1:12
        let input: [UInt8] = [0x67, 0x72, 0x61, 0x70, 0x68, 0x20, 0x5B, 0x20, 0x78, 0x20, 0x22, 0xFF, 0x22, 0x20, 0x5D]
        do {
            let graph = try Pseudograph<String>(gml: input)
            Issue.record("expected invalidUTF8, read \(graph)")
        } catch {
            #expect(error.kind == .invalidUTF8)
            #expect([error.line, error.column, error.byteOffset] == [1, 12, 11])
        }
    }

    @Test("GF-551 empty digraph")
    func gf551() throws {
        // writeGML(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeGML(to: &output)
        #expect(output == "graph [\n  directed 1\n]\n")
    }

    @Test("GF-552 empty undirected graph: no directed line")
    func gf552() throws {
        // writeGML(to:) on U:
        let graph = Pseudograph<String>()
        var output = ""
        try graph.writeGML(to: &output)
        #expect(output == "graph [\n]\n")
    }

    @Test("GF-553 every vertex, then every edge, in order")
    func gf553() throws {
        // writeGML(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeGML(to: &output)
        #expect(output == "graph [\n  directed 1\n  node [\n    id 0\n    label \"a\"\n  ]\n  node [\n    id 1\n    label \"b\"\n  ]\n  node [\n    id 2\n    label \"z\"\n  ]\n  edge [\n    source 0\n    target 1\n  ]\n]\n")
    }

    @Test("GF-554 typed attributes; graph attributes first; booleans as 1 and 0")
    func gf554() throws {
        // writeGML(to:) on D: a{color="x y", n=3, x=2.0, ok=true, no=false}, b; a>b{weight=2, w2=-0.5}, b>b{weight=1.5}; graph{title="G", n=1}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        try graph.writeGML(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("color", .string("x y")), ("n", .integer(3)), ("x", .double(2.0)), ("ok", .boolean(true)), ("no", .boolean(false))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(2)), ("w2", .double(-0.5))]
            case 1: [("weight", .double(1.5))]
            default: []
            }
        }, graphAttributes: [("title", .string("G")), ("n", .integer(1))])
        #expect(output == "graph [\n  directed 1\n  title \"G\"\n  n 1\n  node [\n    id 0\n    label \"a\"\n    color \"x y\"\n    n 3\n    x 2.0\n    ok 1\n    no 0\n  ]\n  node [\n    id 1\n    label \"b\"\n  ]\n  edge [\n    source 0\n    target 1\n    weight 2\n    w2 -0.5\n  ]\n  edge [\n    source 1\n    target 1\n    weight 1.5\n  ]\n]\n")
    }

    @Test("GF-555 undirected, a loop, parallel edges: multigraph 1")
    func gf555() throws {
        // writeGML(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writeGML(to: &output)
        #expect(output == "graph [\n  multigraph 1\n  node [\n    id 0\n    label \"a\"\n  ]\n  node [\n    id 1\n    label \"b\"\n  ]\n  node [\n    id 2\n    label \"c\"\n  ]\n  edge [\n    source 1\n    target 0\n  ]\n  edge [\n    source 0\n    target 0\n  ]\n  edge [\n    source 0\n    target 1\n  ]\n  edge [\n    source 2\n    target 1\n  ]\n]\n")
    }

    #if _pointerBitWidth(_64)
    @Test("GF-556 integers outside 32 bits as strings; reals as NetworkX writes them")
    func gf556() throws {
        // writeGML(to:) on U: a{big=2147483648, low=-2147483648, top=2147483647, e=1e-05, f=1e+16, p=inf, m=-inf, q=nan, z=-0.0}
        let graph = Pseudograph<String>(vertices: ["a"])
        var output = ""
        try graph.writeGML(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("big", .integer(2147483648)), ("low", .integer(-2147483648)), ("top", .integer(2147483647)), ("e", .double(1e-05)), ("f", .double(1e+16)), ("p", .double(.infinity)), ("m", .double(-.infinity)), ("q", .double(.nan)), ("z", .double(-0.0))]
            default: []
            }
        })
        #expect(output == "graph [\n  node [\n    id 0\n    label \"a\"\n    big \"2147483648\"\n    low -2147483648\n    top 2147483647\n    e 1.E-05\n    f 1.E+16\n    p +INF\n    m -INF\n    q NAN\n    z -0.0\n  ]\n]\n")
    }
    #endif

    @Test("GF-557 character references for quotes, ampersands and everything outside ASCII")
    func gf557() throws {
        // writeGML(to:) on D: "a\"&<b>", "é\n😀", "~ "{s="tab\tquote\"amp&"}; "a\"&<b>">"é\n😀"
        let graph = DirectedPseudograph<String>(vertices: ["a\"&<b>", "é\n😀", "~ "], edges: [DirectedEdge(from: "a\"&<b>", to: "é\n😀")])
        var output = ""
        try graph.writeGML(to: &output, vertexAttributes: { v in
            switch v {
            case "~ ": [("s", .string("tab\tquote\"amp&"))]
            default: []
            }
        })
        #expect(output == "graph [\n  directed 1\n  node [\n    id 0\n    label \"a&#34;&#38;<b>\"\n  ]\n  node [\n    id 1\n    label \"&#233;&#10;&#128512;\"\n  ]\n  node [\n    id 2\n    label \"~ \"\n    s \"tab&#9;quote&#34;amp&#38;\"\n  ]\n  edge [\n    source 0\n    target 1\n  ]\n]\n")
    }

    @Test("GF-558 Int vertices: labels are their text")
    func gf558() throws {
        // writeGML(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var output = ""
        try graph.writeGML(to: &output)
        #expect(output == "graph [\n  node [\n    id 0\n    label \"0\"\n  ]\n  node [\n    id 1\n    label \"1\"\n  ]\n  node [\n    id 2\n    label \"2\"\n  ]\n  edge [\n    source 0\n    target 1\n  ]\n  edge [\n    source 1\n    target 2\n  ]\n]\n")
    }
}
