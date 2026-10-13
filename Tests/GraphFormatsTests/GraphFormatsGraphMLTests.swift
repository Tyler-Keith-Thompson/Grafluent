// GraphML (catalog GF-043 – GF-082 and GF-227 read, GF-193 – GF-199 write): the XML subset (no DTD, no
// entities but the five), typed keys with defaults, edges resolved after the nodes, unsupported
// features rejected precisely; the writer's keys by first appearance, graph keys first.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats GraphML")
struct GraphFormatsGraphMLTests {
    @Test("GF-043 nodes and edges in document order")
    func gf043() throws {
        // DirectedPseudograph<String>(graphML:) → D: a, b; a>b, b>a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><node id=\"b\"/><edge source=\"a\" target=\"b\"/><edge source=\"b\" target=\"a\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-044 undirected")
    func gf044() throws {
        // Pseudograph<String>(graphML:) → U: a, b; b-a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"undirected\"><node id=\"a\"/><node id=\"b\"/><edge source=\"b\" target=\"a\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["b", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-045 typed keys")
    func gf045() throws {
        // DirectedPseudograph<String>(graphML:) → D: a{b=true, i=-7, l=9223372036854775807, f=0.5, d=0.001, s=" x "}, b{b=false, d=inf, i=3}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k0\" for=\"node\" attr.name=\"b\" attr.type=\"boolean\"/><key id=\"k1\" for=\"node\" attr.name=\"i\" attr.type=\"int\"/><key id=\"k2\" for=\"node\" attr.name=\"l\" attr.type=\"long\"/><key id=\"k3\" for=\"node\" attr.name=\"f\" attr.type=\"float\"/><key id=\"k4\" for=\"node\" attr.name=\"d\" attr.type=\"double\"/><key id=\"k5\" for=\"node\" attr.name=\"s\" attr.type=\"string\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k0\">true</data><data key=\"k1\">-7</data><data key=\"k2\">9223372036854775807</data><data key=\"k3\">0.5</data><data key=\"k4\">1e-3</data><data key=\"k5\"> x </data></node><node id=\"b\"><data key=\"k0\">0</data><data key=\"k4\">INF</data><data key=\"k1\"> 3 </data></node></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == ["a": ["b", "i", "l", "f", "d", "s"], "b": ["b", "d", "i"]])
        #expect(vertexValues == ["a": ["b": .boolean(true), "i": .integer(-7), "l": .integer(9223372036854775807), "f": .double(0.5), "d": .double(0.001), "s": .string(" x ")], "b": ["b": .boolean(false), "d": .double(.infinity), "i": .integer(3)]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-046 a key's default applies where no data element gives it")
    func gf046() throws {
        // DirectedPseudograph<String>(graphML:) → D: a{color="red"}, b{color="blue"}; a>b{weight=1.0}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"c\" for=\"node\" attr.name=\"color\" attr.type=\"string\"><default>red</default></key><key id=\"w\" for=\"edge\" attr.name=\"weight\" attr.type=\"double\"><default>1.0</default></key><graph edgedefault=\"directed\"><node id=\"a\"/><node id=\"b\"><data key=\"c\">blue</data></node><edge source=\"a\" target=\"b\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["color"], "b": ["color"]])
        #expect(vertexValues == ["a": ["color": .string("red")], "b": ["color": .string("blue")]])
        #expect(edgeKeys == [0: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(1.0)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-047 missing attr.type is string; missing attr.name is the key id; for=\"all\"")
    func gf047() throws {
        // DirectedPseudograph<String>(graphML:) → D: a{k="1"}; a>a{k="2"}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">1</data></node><edge source=\"a\" target=\"a\"><data key=\"k\">2</data></edge></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["k"]])
        #expect(vertexValues == ["a": ["k": .string("1")]])
        #expect(edgeKeys == [0: ["k"]])
        #expect(edgeValues == [0: ["k": .string("2")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-048 graph data")
    func gf048() throws {
        // DirectedPseudograph<String>(graphML:) → D:; graph{name="G"}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"n\" for=\"graph\" attr.name=\"name\"/><graph edgedefault=\"directed\"><data key=\"n\">G</data></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(graphKeys == ["name"])
        #expect(graphValues == ["name": .string("G")])
    }

    @Test("GF-049 edges may come before the nodes they name")
    func gf049() throws {
        // DirectedPseudograph<String>(graphML:) → D: a, b; b>a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><edge source=\"b\" target=\"a\"/><node id=\"a\"/><node id=\"b\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-050 parallel edges kept")
    func gf050() throws {
        // DirectedPseudograph<String>(graphML:) → D: a, b; a>b, a>b
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><node id=\"b\"/><edge source=\"a\" target=\"b\"/><edge source=\"a\" target=\"b\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-051 simple target: parallel edges merge, last value wins")
    func gf051() throws {
        // AdjacencyList<String>(graphML:) → D: a, b; a>b{w=2}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"w\" for=\"edge\" attr.name=\"w\" attr.type=\"int\"/><graph edgedefault=\"directed\"><node id=\"a\"/><node id=\"b\"/><edge source=\"a\" target=\"b\"><data key=\"w\">1</data></edge><edge source=\"a\" target=\"b\"><data key=\"w\">2</data></edge></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try AdjacencyList<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-052 declaration, comments, processing instructions, CDATA")
    func gf052() throws {
        // DirectedPseudograph<String>(graphML:) → D: a{s="<x> & y"}
        let input = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<!-- c -->\n<?app x?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"s\" for=\"node\" attr.name=\"s\"/><graph edgedefault=\"directed\"><!-- n --><node id=\"a\"><data key=\"s\"><![CDATA[<x> & y]]></data></node></graph></graphml>\n<!-- end -->\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["s"]])
        #expect(vertexValues == ["a": ["s": .string("<x> & y")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-053 predefined entities and character references")
    func gf053() throws {
        // DirectedPseudograph<String>(graphML:) → D: "<&AB"{s="\"'>é"}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"s\" for=\"node\" attr.name=\"s\"/><graph edgedefault=\"directed\"><node id=\"&lt;&amp;&#x41;&#66;\"><data key=\"s\">&quot;&apos;&gt;&#233;</data></node></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["<&AB"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == ["<&AB": ["s"]])
        #expect(vertexValues == ["<&AB": ["s": .string("\"'>é")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-054 attribute values: tab and newline become spaces; text: CR LF becomes LF")
    func gf054() throws {
        // DirectedPseudograph<String>(graphML:) → D: "a b c\nd"{s="x\ny"}
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"s\" for=\"node\" attr.name=\"s\"/><graph edgedefault=\"directed\"><node id=\"a\tb\nc&#10;d\"><data key=\"s\">x\r\ny</data></node></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a b c\nd"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == ["a b c\nd": ["s"]])
        #expect(vertexValues == ["a b c\nd": ["s": .string("x\ny")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-055 data with element content (yEd) is skipped")
    func gf055() throws {
        // DirectedPseudograph<String>(graphML:) → D: a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"g\" for=\"node\" yfiles.type=\"nodegraphics\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"g\"><y:ShapeNode xmlns:y=\"http://www.yworks.com/xml/graphml\"/></data></node></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-056 unknown elements are skipped")
    func gf056() throws {
        // DirectedPseudograph<String>(graphML:) → D: a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><desc>d</desc><graph edgedefault=\"directed\"><desc>x</desc><node id=\"a\"><desc>y</desc></node><foo:bar xmlns:foo=\"urn:x\"><node id=\"z\"/></foo:bar></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-057 single-quoted attributes, whitespace in tags")
    func gf057() throws {
        // DirectedPseudograph<String>(graphML:) → D: a
        let input = "<graphml xmlns='http://graphml.graphdrawing.org/xmlns' ><graph  edgedefault = 'directed' ><node id='a' /></graph ></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-058 a matching edge directed attribute is accepted")
    func gf058() throws {
        // DirectedPseudograph<String>(graphML:) → D: a; a>a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><edge source=\"a\" target=\"a\" directed=\"true\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-059 DOCTYPE (no DTD, so no entity expansion)")
    func gf059() {
        // DirectedPseudograph<String>(graphML:) → **doctypeNotAllowed** at 1:1
        let input = "<!DOCTYPE g [<!ENTITY e \"zz\">]><graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"/></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected doctypeNotAllowed, read \(graph)")
        } catch {
            #expect(error.kind == .doctypeNotAllowed)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-060 an undeclared entity")
    func gf060() {
        // DirectedPseudograph<String>(graphML:) → **entityNotAllowed** at 1:96
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"&e;\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected entityNotAllowed, read \(graph)")
        } catch {
            #expect(error.kind == .entityNotAllowed)
            #expect([error.line, error.column, error.byteOffset] == [1, 96, 95])
        }
    }

    @Test("GF-061 invalid character reference")
    func gf061() {
        // DirectedPseudograph<String>(graphML:) → **invalidValue** at 1:96
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"&#0;\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 96, 95])
        }
    }

    @Test("GF-062 mismatched end tag")
    func gf062() {
        // DirectedPseudograph<String>(graphML:) → **mismatchedTag** at 1:99
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"></edge></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected mismatchedTag, read \(graph)")
        } catch {
            #expect(error.kind == .mismatchedTag)
            #expect([error.line, error.column, error.byteOffset] == [1, 99, 98])
        }
    }

    @Test("GF-063 unclosed element")
    func gf063() {
        // DirectedPseudograph<String>(graphML:) → **unexpectedEndOfInput** at 1:56
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\">"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 56, 55])
        }
    }

    @Test("GF-064 edgedefault is required (graphml.xsd)")
    func gf064() {
        // DirectedPseudograph<String>(graphML:) → **syntax** at 1:56
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph><node id=\"a\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 56, 55])
        }
    }

    @Test("GF-065 undirected into a directed target")
    func gf065() {
        // DirectedPseudograph<String>(graphML:) → **kindMismatch** at 1:56
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"undirected\"/></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 56, 55])
        }
    }

    @Test("GF-066 edge to an undeclared node")
    func gf066() {
        // DirectedPseudograph<String>(graphML:) → **undeclaredVertex** at 1:117
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><edge source=\"a\" target=\"z\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected undeclaredVertex, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 117, 116])
        }
    }

    @Test("GF-067 duplicate node id")
    func gf067() {
        // DirectedPseudograph<String>(graphML:) → **duplicateVertex** at 1:106
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><node id=\"a\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 106, 105])
        }
    }

    @Test("GF-068 data with an undeclared key")
    func gf068() {
        // DirectedPseudograph<String>(graphML:) → **undeclaredKey** at 1:105
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">1</data></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected undeclaredKey, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 105, 104])
        }
    }

    @Test("GF-069 an edge key used on a node")
    func gf069() {
        // DirectedPseudograph<String>(graphML:) → **undeclaredKey** at 1:129
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\" for=\"edge\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">1</data></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected undeclaredKey, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 129, 128])
        }
    }

    @Test("GF-070 int value that is not an integer")
    func gf070() {
        // DirectedPseudograph<String>(graphML:) → **invalidValue** at 1:139
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\" for=\"node\" attr.type=\"int\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">1.5</data></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 139, 138])
        }
    }

    @Test("GF-071 long beyond Int64")
    func gf071() {
        // DirectedPseudograph<String>(graphML:) → **numberOutOfRange** at 1:140
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\" for=\"node\" attr.type=\"long\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">9223372036854775808</data></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 140, 139])
        }
    }

    @Test("GF-072 boolean is true, false, 1 or 0")
    func gf072() {
        // DirectedPseudograph<String>(graphML:) → **invalidValue** at 1:143
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\" for=\"node\" attr.type=\"boolean\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">True</data></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 143, 142])
        }
    }

    @Test("GF-073 nested graph (unsupported)")
    func gf073() {
        // DirectedPseudograph<String>(graphML:) → **unsupported** at 1:99
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"><graph edgedefault=\"directed\"/></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 99, 98])
        }
    }

    @Test("GF-074 a second graph (unsupported)")
    func gf074() {
        // DirectedPseudograph<String>(graphML:) → **unsupported** at 1:87
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"/><graph edgedefault=\"directed\"/></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 87, 86])
        }
    }

    @Test("GF-075 hyperedge (unsupported)")
    func gf075() {
        // DirectedPseudograph<String>(graphML:) → **unsupported** at 1:100
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><hyperedge/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 100, 99])
        }
    }

    @Test("GF-076 an edge whose directed differs from edgedefault (unsupported)")
    func gf076() {
        // DirectedPseudograph<String>(graphML:) → **unsupported** at 1:128
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><edge source=\"a\" target=\"a\" directed=\"false\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 128, 127])
        }
    }

    @Test("GF-077 encoding other than UTF-8")
    func gf077() {
        // DirectedPseudograph<String>(graphML:) → **unsupported** at 1:31
        let input = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"/></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 31, 30])
        }
    }

    @Test("GF-078 duplicate attribute")
    func gf078() {
        // DirectedPseudograph<String>(graphML:) → **duplicateKey** at 1:86
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\" edgedefault=\"directed\"/></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 86, 85])
        }
    }

    @Test("GF-079 nesting deeper than 64 elements")
    func gf079() {
        // DirectedPseudograph<String>(graphML:) → **nestingTooDeep** at 1:285
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"><desc><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x><x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></x></desc></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 285, 284])
        }
    }

    @Test("GF-080 text after the root element")
    func gf080() {
        // DirectedPseudograph<String>(graphML:) → **syntax** at 1:97
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"/></graphml>x"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 97, 96])
        }
    }

    @Test("GF-081 root is not graphml")
    func gf081() {
        // DirectedPseudograph<String>(graphML:) → **syntax** at 1:1
        let input = "<graph edgedefault=\"directed\"/>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-082 a control character")
    func gf082() {
        // DirectedPseudograph<String>(graphML:) → **syntax** at 1:97
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\u{1}\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 97, 96])
        }
    }

    @Test("GF-193 empty digraph")
    func gf193() throws {
        // writeGraphML(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeGraphML(to: &output)
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <graph edgedefault=\"directed\">\n  </graph>\n</graphml>\n")
    }

    @Test("GF-194 nodes without data are empty elements")
    func gf194() throws {
        // writeGraphML(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeGraphML(to: &output)
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <graph edgedefault=\"directed\">\n    <node id=\"a\"/>\n    <node id=\"b\"/>\n    <node id=\"z\"/>\n    <edge source=\"a\" target=\"b\"/>\n  </graph>\n</graphml>\n")
    }

    @Test("GF-195 typed keys: graph, then node, then edge keys, by first appearance")
    func gf195() throws {
        // writeGraphML(to:) on D: a{label="x y", n=3, x=2.0, ok=true}, b; a>b{weight=2, w2=-0.5}, b>b{weight=1.5}; graph{title="G"}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        try graph.writeGraphML(to: &output, vertexAttributes: { v in
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
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <key id=\"d0\" for=\"graph\" attr.name=\"title\" attr.type=\"string\"/>\n  <key id=\"d1\" for=\"node\" attr.name=\"label\" attr.type=\"string\"/>\n  <key id=\"d2\" for=\"node\" attr.name=\"n\" attr.type=\"long\"/>\n  <key id=\"d3\" for=\"node\" attr.name=\"x\" attr.type=\"double\"/>\n  <key id=\"d4\" for=\"node\" attr.name=\"ok\" attr.type=\"boolean\"/>\n  <key id=\"d5\" for=\"edge\" attr.name=\"weight\" attr.type=\"double\"/>\n  <key id=\"d6\" for=\"edge\" attr.name=\"w2\" attr.type=\"double\"/>\n  <graph edgedefault=\"directed\">\n    <data key=\"d0\">G</data>\n    <node id=\"a\">\n      <data key=\"d1\">x y</data>\n      <data key=\"d2\">3</data>\n      <data key=\"d3\">2.0</data>\n      <data key=\"d4\">true</data>\n    </node>\n    <node id=\"b\"/>\n    <edge source=\"a\" target=\"b\">\n      <data key=\"d5\">2</data>\n      <data key=\"d6\">-0.5</data>\n    </edge>\n    <edge source=\"b\" target=\"b\">\n      <data key=\"d5\">1.5</data>\n    </edge>\n  </graph>\n</graphml>\n")
    }

    @Test("GF-196 undirected")
    func gf196() throws {
        // writeGraphML(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writeGraphML(to: &output)
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <graph edgedefault=\"undirected\">\n    <node id=\"a\"/>\n    <node id=\"b\"/>\n    <node id=\"c\"/>\n    <edge source=\"b\" target=\"a\"/>\n    <edge source=\"a\" target=\"a\"/>\n    <edge source=\"a\" target=\"b\"/>\n    <edge source=\"c\" target=\"b\"/>\n  </graph>\n</graphml>\n")
    }

    @Test("GF-197 escaping in ids and data")
    func gf197() throws {
        // writeGraphML(to:) on D: "a&<>\""{s="x & <y> \"z\" \r\n"}, "t\tn\nr\r"; "a&<>\"">"t\tn\nr\r"{s="\t"}
        let graph = DirectedPseudograph<String>(vertices: ["a&<>\"", "t\tn\nr\r"], edges: [DirectedEdge(from: "a&<>\"", to: "t\tn\nr\r")])
        var output = ""
        try graph.writeGraphML(to: &output, vertexAttributes: { v in
            switch v {
            case "a&<>\"": [("s", .string("x & <y> \"z\" \r\n"))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("s", .string("\t"))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <key id=\"d0\" for=\"node\" attr.name=\"s\" attr.type=\"string\"/>\n  <key id=\"d1\" for=\"edge\" attr.name=\"s\" attr.type=\"string\"/>\n  <graph edgedefault=\"directed\">\n    <node id=\"a&amp;&lt;&gt;&quot;\">\n      <data key=\"d0\">x &amp; &lt;y&gt; \"z\" &#13;\n</data>\n    </node>\n    <node id=\"t&#9;n&#10;r&#13;\"/>\n    <edge source=\"a&amp;&lt;&gt;&quot;\" target=\"t&#9;n&#10;r&#13;\">\n      <data key=\"d1\">\t</data>\n    </edge>\n  </graph>\n</graphml>\n")
    }

    @Test("GF-198 integer and double values under one key: double")
    func gf198() throws {
        // writeGraphML(to:) on D: a{w=1}, b; a>b{w=1}, b>a{w=2.5}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        var output = ""
        try graph.writeGraphML(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("w", .integer(1))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("w", .integer(1))]
            case 1: [("w", .double(2.5))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <key id=\"d0\" for=\"node\" attr.name=\"w\" attr.type=\"long\"/>\n  <key id=\"d1\" for=\"edge\" attr.name=\"w\" attr.type=\"double\"/>\n  <graph edgedefault=\"directed\">\n    <node id=\"a\">\n      <data key=\"d0\">1</data>\n    </node>\n    <node id=\"b\"/>\n    <edge source=\"a\" target=\"b\">\n      <data key=\"d1\">1</data>\n    </edge>\n    <edge source=\"b\" target=\"a\">\n      <data key=\"d1\">2.5</data>\n    </edge>\n  </graph>\n</graphml>\n")
    }

    @Test("GF-199 INF, -INF, NaN, booleans")
    func gf199() throws {
        // writeGraphML(to:) on D: a{x=inf, y=-inf, z=nan, b=false}
        let graph = DirectedPseudograph<String>(vertices: ["a"])
        var output = ""
        try graph.writeGraphML(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("x", .double(.infinity)), ("y", .double(-.infinity)), ("z", .double(.nan)), ("b", .boolean(false))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n  <key id=\"d0\" for=\"node\" attr.name=\"x\" attr.type=\"double\"/>\n  <key id=\"d1\" for=\"node\" attr.name=\"y\" attr.type=\"double\"/>\n  <key id=\"d2\" for=\"node\" attr.name=\"z\" attr.type=\"double\"/>\n  <key id=\"d3\" for=\"node\" attr.name=\"b\" attr.type=\"boolean\"/>\n  <graph edgedefault=\"directed\">\n    <node id=\"a\">\n      <data key=\"d0\">INF</data>\n      <data key=\"d1\">-INF</data>\n      <data key=\"d2\">NaN</data>\n      <data key=\"d3\">false</data>\n    </node>\n  </graph>\n</graphml>\n")
    }

    @Test("GF-227 an end tag with no open element")
    func gf227() {
        // DirectedPseudograph<String>(graphML:) → **mismatchedTag** at 1:1
        let input = "</graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected mismatchedTag, read \(graph)")
        } catch {
            #expect(error.kind == .mismatchedTag)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-241 xs:boolean: directed=\"1\" on a directed edge")
    func gf241() throws {
        // DirectedPseudograph<String>(graphML:) → D: a; a>a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><edge source=\"a\" target=\"a\" directed=\"1\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-242 xs:boolean: directed=\" 0 \" on an undirected edge")
    func gf242() throws {
        // Pseudograph<String>(graphML:) → U: a; a-a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"undirected\"><node id=\"a\"/><edge source=\"a\" target=\"a\" directed=\" 0 \"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-243 edgedefault with whitespace around it")
    func gf243() throws {
        // DirectedPseudograph<String>(graphML:) → D: a; a>a
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\" directed\n\"><node id=\"a\"/><edge source=\"a\" target=\"a\"/></graph></graphml>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-254 a vertical tab in text (XML forbids C0 controls)")
    func gf254() {
        // DirectedPseudograph<String>(graphML:) → **syntax** at 1:97
        let input = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\u{B}\"/></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 97, 96])
        }
    }
}
