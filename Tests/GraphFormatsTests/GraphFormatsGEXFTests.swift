// GEXF (catalog GF-593 – GF-652 read, GF-653 – GF-660 write): one static graph over the XML subset,
// declared attributes with defaults, nodes (nested ones too) before the edges that name them, label
// and weight as attributes, dynamic data rejected; the writer's node class then edge class, label and
// weight as XML attributes; ref.py has NetworkX read every write row back.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats GEXF")
struct GraphFormatsGEXFTests {
    @Test("GF-593 nodes and edges in document order")
    func gf593() throws {
        // DirectedPseudograph<String>(gexf:) → D: a, b; a>b, b>a
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/><node id=\"b\"/></nodes><edges><edge id=\"0\" source=\"a\" target=\"b\"/><edge id=\"1\" source=\"b\" target=\"a\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-594 undirected; a missing defaultedgetype is undirected; b-a kept as written")
    func gf594() throws {
        // Pseudograph<String>(gexf:) → U: a, b; b-a
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph><nodes><node id=\"a\"/><node id=\"b\"/></nodes><edges><edge source=\"b\" target=\"a\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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

    #if _pointerBitWidth(_64)
    @Test("GF-595 declared attributes: every type, surrounding whitespace in numbers, INF, 1 and 0 as booleans")
    func gf595() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{i=-7, l=9223372036854775807, f=0.5, d=inf, b=true, s=" x ", ls="p|q", u="http://x"}, b{b=false, d=0.001, i=3}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" title=\"i\" type=\"integer\"/><attribute id=\"1\" title=\"l\" type=\"long\"/><attribute id=\"2\" title=\"f\" type=\"float\"/><attribute id=\"3\" title=\"d\" type=\"double\"/><attribute id=\"4\" title=\"b\" type=\"boolean\"/><attribute id=\"5\" title=\"s\" type=\"string\"/><attribute id=\"6\" title=\"ls\" type=\"liststring\"/><attribute id=\"7\" title=\"u\" type=\"anyURI\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"0\" value=\" -7 \"/><attvalue for=\"1\" value=\"9223372036854775807\"/><attvalue for=\"2\" value=\"0.5\"/><attvalue for=\"3\" value=\"INF\"/><attvalue for=\"4\" value=\"true\"/><attvalue for=\"5\" value=\" x \"/><attvalue for=\"6\" value=\"p|q\"/><attvalue for=\"7\" value=\"http://x\"/></attvalues></node><node id=\"b\"><attvalues><attvalue for=\"4\" value=\"0\"/><attvalue for=\"3\" value=\"1e-3\"/><attvalue for=\"0\" value=\"3\"/></attvalues></node></nodes></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["i", "l", "f", "d", "b", "s", "ls", "u"], "b": ["b", "d", "i"]])
        #expect(vertexValues == ["a": ["i": .integer(-7), "l": .integer(9223372036854775807), "f": .double(0.5), "d": .double(.infinity), "b": .boolean(true), "s": .string(" x "), "ls": .string("p|q"), "u": .string("http://x")], "b": ["b": .boolean(false), "d": .double(0.001), "i": .integer(3)]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }
    #endif

    @Test("GF-596 a default applies where no attvalue gives it")
    func gf596() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{color="red"}, b{color="blue"}; a>b{w=1.0}, b>a{w=2.0}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"c\" title=\"color\" type=\"string\"><default>red</default></attribute></attributes><attributes class=\"edge\"><attribute id=\"w\" title=\"w\" type=\"double\"><default>1.0</default></attribute></attributes><nodes><node id=\"a\"/><node id=\"b\"><attvalues><attvalue for=\"c\" value=\"blue\"/></attvalues></node></nodes><edges><edge source=\"a\" target=\"b\"/><edge source=\"b\" target=\"a\"><attvalues><attvalue for=\"w\" value=\"2\"/></attvalues></edge></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["color"], "b": ["color"]])
        #expect(vertexValues == ["a": ["color": .string("red")], "b": ["color": .string("blue")]])
        #expect(edgeKeys == [0: ["w"], 1: ["w"]])
        #expect(edgeValues == [0: ["w": .double(1.0)], 1: ["w": .double(2.0)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-597 label and weight are attributes: a node's label, an edge's label and weight (a double)")
    func gf597() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{label="Alpha"}, b; a>b{label="ab", weight=2.5}, b>a{weight=3.0}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\" label=\"Alpha\"/><node id=\"b\"/></nodes><edges><edge id=\"e\" source=\"a\" target=\"b\" label=\"ab\" weight=\"2.5\"/><edge source=\"b\" target=\"a\" weight=\"3\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["label"]])
        #expect(vertexValues == ["a": ["label": .string("Alpha")]])
        #expect(edgeKeys == [0: ["label", "weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["label": .string("ab"), "weight": .double(2.5)], 1: ["weight": .double(3.0)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-598 attribute values are reported after the label and weight, then the defaults")
    func gf598() throws {
        // DirectedPseudograph<String>(gexf:) → D: a; a>a{label="l", weight=1.0, m="x", k=9}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"edge\"><attribute id=\"0\" title=\"k\" type=\"integer\"><default>9</default></attribute><attribute id=\"1\" title=\"m\" type=\"string\"/></attributes><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"a\" weight=\"1\" label=\"l\"><attvalues><attvalue for=\"1\" value=\"x\"/></attvalues></edge></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["label", "weight", "m", "k"]])
        #expect(edgeValues == [0: ["label": .string("l"), "weight": .double(1.0), "m": .string("x"), "k": .integer(9)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-599 nested nodes (a hierarchy) are the graph's, in document order of their start tags")
    func gf599() throws {
        // DirectedPseudograph<String>(gexf:) → D: a, b, c, d; c>d
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"><nodes><node id=\"b\"><nodes><node id=\"c\"/></nodes></node></nodes></node><node id=\"d\" pid=\"a\"/></nodes><edges><edge source=\"c\" target=\"d\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c", "d"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["c", "d"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-600 meta, viz, parents, spells, options and unknown elements are skipped")
    func gf600() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{t="a"}, b; a>b
        let input = "<gexf xmlns=\"http://gexf.net/1.3\" xmlns:viz=\"http://gexf.net/1.3/viz\" version=\"1.3\"><meta lastmodifieddate=\"2009-03-20\"><creator>Gephi</creator><description>d</description></meta><graph defaultedgetype=\"directed\" idtype=\"string\"><attributes class=\"node\"><attribute id=\"0\" title=\"t\" type=\"string\"><options>a|b</options></attribute></attributes><nodes><node id=\"a\"><viz:color r=\"1\" g=\"2\" b=\"3\"/><viz:position x=\"1\" y=\"2\"/><parents><parent for=\"b\"/></parents><spells><spell start=\"1\"/></spells><attvalues><attvalue for=\"0\" value=\"a\"/></attvalues></node><node id=\"b\"/></nodes><edges><edge source=\"a\" target=\"b\"><viz:thickness value=\"2\"/></edge></edges><extra/></graph><trailing/></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["t"]])
        #expect(vertexValues == ["a": ["t": .string("a")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-601 a non-empty graph name is a graph attribute")
    func gf601() throws {
        // DirectedPseudograph<String>(gexf:) → D: a; graph{name="net"}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\" mode=\"static\" name=\"net\" timeformat=\"date\"><nodes><node id=\"a\"/></nodes></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(graphKeys == ["name"])
        #expect(graphValues == ["name": .string("net")])
    }

    @Test("GF-602 an empty graph name is not reported")
    func gf602() throws {
        // DirectedPseudograph<String>(gexf:) → D:
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\" name=\"\"><nodes/><edges/></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-603 parallel edges and loops kept; edge ids are not attributes")
    func gf603() throws {
        // DirectedPseudograph<String>(gexf:) → D: a, b; a>b, a>b, a>a
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/><node id=\"b\"/></nodes><edges><edge id=\"x\" source=\"a\" target=\"b\"/><edge id=\"y\" source=\"a\" target=\"b\"/><edge id=\"z\" source=\"a\" target=\"a\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["a", "b"], ["a", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-604 simple target: parallel edges merge, last value wins")
    func gf604() throws {
        // AdjacencyList<String>(gexf:) → D: a, b; a>b{weight=2.0, k=1}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"edge\"><attribute id=\"0\" title=\"k\" type=\"integer\"/></attributes><nodes><node id=\"a\"/><node id=\"b\"/></nodes><edges><edge source=\"a\" target=\"b\" weight=\"1\"><attvalues><attvalue for=\"0\" value=\"1\"/></attvalues></edge><edge source=\"a\" target=\"b\" weight=\"2\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try AdjacencyList<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["weight", "k"]])
        #expect(edgeValues == [0: ["weight": .double(2.0), "k": .integer(1)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-605 simple undirected target: b-a is a-b")
    func gf605() throws {
        // UndirectedAdjacencyList<String>(gexf:) → U: a, b; a-b{label="l"}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"undirected\"><nodes><node id=\"a\"/><node id=\"b\"/></nodes><edges><edge source=\"a\" target=\"b\"/><edge source=\"b\" target=\"a\" label=\"l\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try UndirectedAdjacencyList<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["label"]])
        #expect(edgeValues == [0: ["label": .string("l")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-606 an edge type equal to the graph's kind")
    func gf606() throws {
        // Pseudograph<String>(gexf:) → U: a; a-a
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"undirected\"><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"a\" type=\"undirected\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-607 declaration, comments, processing instructions, CDATA and references in a default")
    func gf607() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{t="a<b&c"}
        let input = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!-- c -->\n<gexf xmlns=\"http://www.gexf.net/1.2draft\"><?pi x?><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" title=\"t\"><default><![CDATA[a<b]]>&amp;&#99;</default></attribute></attributes><nodes><node id=\"a\"/></nodes></graph></gexf>\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["t"]])
        #expect(vertexValues == ["a": ["t": .string("a<b&c")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-608 predefined entities and character references in ids and values; attribute values are normalized")
    func gf608() throws {
        // DirectedPseudograph<String>(gexf:) → D: "a&b"{label="x\ny", s="p q\tr"}; "a&b">"a&b"
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" title=\"s\"/></attributes><nodes><node id=\"a&amp;b\" label=\"x&#10;y\"><attvalues><attvalue for=\"0\" value=\"p\tq&#9;r\"/></attvalues></node></nodes><edges><edge source=\"a&amp;b\" target=\"a&amp;b\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a&b"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a&b", "a&b"]])
        #expect(vertexKeys == ["a&b": ["label", "s"]])
        #expect(vertexValues == ["a&b": ["label": .string("x\ny"), "s": .string("p q\tr")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-609 attributes declared after the nodes do not reach them")
    func gf609() throws {
        // DirectedPseudograph<String>(gexf:) → D: a, b{t="x"}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><attributes class=\"node\"><attribute id=\"0\" title=\"t\"><default>x</default></attribute></attributes><nodes><node id=\"b\"/></nodes></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["b": ["t"]])
        #expect(vertexValues == ["b": ["t": .string("x")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-610 a missing title is the id; a missing type is string; the same id in both classes")
    func gf610() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{k="1"}; a>a{kk="2"}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"k\"/></attributes><attributes class=\"edge\"><attribute id=\"k\" title=\"kk\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"k\" value=\"1\"/></attvalues></node></nodes><edges><edge source=\"a\" target=\"a\"><attvalues><attvalue for=\"k\" value=\"2\"/></attvalues></edge></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["kk"]])
        #expect(edgeValues == [0: ["kk": .string("2")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-611 an attvalue given twice: the last value; a title shared by two ids")
    func gf611() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{t="s"}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" title=\"t\" type=\"integer\"/><attribute id=\"1\" title=\"t\" type=\"string\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"0\" value=\"1\"/><attvalue for=\"0\" value=\"2\"/><attvalue for=\"1\" value=\"s\"/></attvalues></node></nodes></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["t"]])
        #expect(vertexValues == ["a": ["t": .string("s")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-612 mode static on the graph and its declarations; node and edge counts are ignored")
    func gf612() throws {
        // DirectedPseudograph<String>(gexf:) → D: a; a>a
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\" mode=\"static\"><attributes class=\"node\" mode=\"static\"/><nodes count=\"9\"><node id=\"a\"/></nodes><edges count=\"0\"><edge source=\"a\" target=\"a\"/></edges></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-613 a second default replaces the first, reported once")
    func gf613() throws {
        // DirectedPseudograph<String>(gexf:) → D: a{t=2}
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" title=\"t\" type=\"integer\"><default>1</default><default>2</default></attribute></attributes><nodes><node id=\"a\"/></nodes></graph></gexf>"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(gexf: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["t"]])
        #expect(vertexValues == ["a": ["t": .integer(2)]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-614 the root is not gexf")
    func gf614() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:1
        let input = "<graphml><graph defaultedgetype=\"directed\"/></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-615 no graph")
    func gf615() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:1
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><meta/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-616 a second graph (unsupported)")
    func gf616() {
        // DirectedPseudograph<String>(gexf:) → **unsupported** at 1:100
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"></graph><graph defaultedgetype=\"directed\"/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 100, 99])
        }
    }

    @Test("GF-617 defaultedgetype mutual (unsupported)")
    func gf617() {
        // DirectedPseudograph<String>(gexf:) → **unsupported** at 1:65
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"mutual\"/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 65, 64])
        }
    }

    @Test("GF-618 defaultedgetype that is not a kind")
    func gf618() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:65
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"both\"/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 65, 64])
        }
    }

    @Test("GF-619 directed into an undirected target")
    func gf619() {
        // Pseudograph<String>(gexf:) → **kindMismatch** at 1:58
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"></graph></gexf>"
        do {
            let graph = try Pseudograph<String>(gexf: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 58, 57])
        }
    }

    @Test("GF-620 undirected (by default) into a directed target")
    func gf620() {
        // DirectedPseudograph<String>(gexf:) → **kindMismatch** at 1:58
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 58, 57])
        }
    }

    @Test("GF-621 mode dynamic (unsupported)")
    func gf621() {
        // DirectedPseudograph<String>(gexf:) → **unsupported** at 1:92
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\" mode=\"dynamic\"/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 92, 91])
        }
    }

    @Test("GF-622 a mode that is neither")
    func gf622() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:92
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\" mode=\"slow\"/></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 92, 91])
        }
    }

    @Test("GF-623 attributes without a class")
    func gf623() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:92
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes><attribute id=\"0\"/></attributes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 92, 91])
        }
    }

    @Test("GF-624 an attribute class that is neither node nor edge")
    func gf624() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:104
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"graph\"/></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 104, 103])
        }
    }

    @Test("GF-625 dynamic attributes (unsupported)")
    func gf625() {
        // DirectedPseudograph<String>(gexf:) → **unsupported** at 1:117
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\" mode=\"dynamic\"/></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 117, 116])
        }
    }

    @Test("GF-626 an attribute without an id")
    func gf626() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:117
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute title=\"t\"/></attributes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 117, 116])
        }
    }

    @Test("GF-627 an attribute id declared twice in a class")
    func gf627() {
        // DirectedPseudograph<String>(gexf:) → **duplicateKey** at 1:147
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\"/><attribute id=\"0\"/></attributes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 147, 146])
        }
    }

    @Test("GF-628 an attribute type that is not one of GEXF's")
    func gf628() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:135
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" type=\"date\"/></attributes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 135, 134])
        }
    }

    @Test("GF-629 a default with element content")
    func gf629() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:135
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\"><default><b>x</b></default></attribute></attributes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 135, 134])
        }
    }

    @Test("GF-630 a default that is not of its type")
    func gf630() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:150
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" type=\"integer\"><default>x</default></attribute></attributes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 150, 149])
        }
    }

    @Test("GF-631 a node without an id")
    func gf631() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:99
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node label=\"a\"/></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 99, 98])
        }
    }

    @Test("GF-632 duplicate node id")
    func gf632() {
        // DirectedPseudograph<String>(gexf:) → **duplicateVertex** at 1:119
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/><node id=\"a\"/></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 119, 118])
        }
    }

    @Test("GF-633 a node id declared again inside a nested nodes element")
    func gf633() {
        // DirectedPseudograph<String>(gexf:) → **duplicateVertex** at 1:125
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"><nodes><node id=\"a\"/></nodes></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 125, 124])
        }
    }

    @Test("GF-634 an attvalue without for")
    func gf634() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:123
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"><attvalues><attvalue value=\"1\"/></attvalues></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 123, 122])
        }
    }

    @Test("GF-635 an attvalue for an undeclared attribute")
    func gf635() {
        // DirectedPseudograph<String>(gexf:) → **undeclaredKey** at 1:133
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"><attvalues><attvalue for=\"0\" value=\"1\"/></attvalues></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected undeclaredKey, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 133, 132])
        }
    }

    @Test("GF-636 an attvalue for an attribute of the other class")
    func gf636() {
        // DirectedPseudograph<String>(gexf:) → **undeclaredKey** at 1:190
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"edge\"><attribute id=\"0\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"0\" value=\"1\"/></attvalues></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected undeclaredKey, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 190, 189])
        }
    }

    @Test("GF-637 an attvalue without a value")
    func gf637() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:180
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"0\"/></attvalues></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 180, 179])
        }
    }

    @Test("GF-638 an attvalue that is not of its type")
    func gf638() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:195
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" type=\"boolean\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"0\" value=\"True\"/></attvalues></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 195, 194])
        }
    }

    @Test("GF-639 an integer beyond Int")
    func gf639() {
        // DirectedPseudograph<String>(gexf:) → **numberOutOfRange** at 1:192
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><attributes class=\"node\"><attribute id=\"0\" type=\"long\"/></attributes><nodes><node id=\"a\"><attvalues><attvalue for=\"0\" value=\"9223372036854775808\"/></attvalues></node></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 192, 191])
        }
    }

    @Test("GF-640 an edge without a source")
    func gf640() {
        // DirectedPseudograph<String>(gexf:) → **syntax** at 1:128
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><edges><edge target=\"a\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 128, 127])
        }
    }

    @Test("GF-641 an edge to an undeclared node")
    func gf641() {
        // DirectedPseudograph<String>(gexf:) → **undeclaredVertex** at 1:145
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"b\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected undeclaredVertex, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 145, 144])
        }
    }

    @Test("GF-642 edges before the nodes they name")
    func gf642() {
        // DirectedPseudograph<String>(gexf:) → **undeclaredVertex** at 1:105
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><edges><edge source=\"a\" target=\"a\"/></edges><nodes><node id=\"a\"/></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected undeclaredVertex, read \(graph)")
        } catch {
            #expect(error.kind == .undeclaredVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 105, 104])
        }
    }

    @Test("GF-643 an edge whose type differs from the graph's (unsupported)")
    func gf643() {
        // DirectedPseudograph<String>(gexf:) → **unsupported** at 1:156
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"a\" type=\"undirected\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 156, 155])
        }
    }

    @Test("GF-644 a mutual edge (unsupported)")
    func gf644() {
        // DirectedPseudograph<String>(gexf:) → **unsupported** at 1:156
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"a\" type=\"mutual\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 156, 155])
        }
    }

    @Test("GF-645 an edge type that is not a kind")
    func gf645() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:156
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"a\" type=\"loop\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 156, 155])
        }
    }

    @Test("GF-646 a weight that is not a number")
    func gf646() {
        // DirectedPseudograph<String>(gexf:) → **invalidValue** at 1:156
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></nodes><edges><edge source=\"a\" target=\"a\" weight=\"heavy\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 156, 155])
        }
    }

    @Test("GF-647 DOCTYPE (no DTD)")
    func gf647() {
        // DirectedPseudograph<String>(gexf:) → **doctypeNotAllowed** at 1:1
        let input = "<!DOCTYPE gexf [<!ENTITY e \"x\">]><gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"&e;\"/></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected doctypeNotAllowed, read \(graph)")
        } catch {
            #expect(error.kind == .doctypeNotAllowed)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-648 an entity that is not predefined")
    func gf648() {
        // DirectedPseudograph<String>(gexf:) → **entityNotAllowed** at 1:109
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"&nbsp;\"/></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected entityNotAllowed, read \(graph)")
        } catch {
            #expect(error.kind == .entityNotAllowed)
            #expect([error.line, error.column, error.byteOffset] == [1, 109, 108])
        }
    }

    @Test("GF-649 mismatched tags")
    func gf649() {
        // DirectedPseudograph<String>(gexf:) → **mismatchedTag** at 1:113
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/></edges></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected mismatchedTag, read \(graph)")
        } catch {
            #expect(error.kind == .mismatchedTag)
            #expect([error.line, error.column, error.byteOffset] == [1, 113, 112])
        }
    }

    @Test("GF-650 cut short")
    func gf650() {
        // DirectedPseudograph<String>(gexf:) → **unexpectedEndOfInput** at 1:92
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\"/>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 92, 91])
        }
    }

    @Test("GF-651 a repeated XML attribute")
    func gf651() {
        // DirectedPseudograph<String>(gexf:) → **duplicateKey** at 1:112
        let input = "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\"><graph defaultedgetype=\"directed\"><nodes><node id=\"a\" id=\"b\"/></nodes></graph></gexf>"
        do {
            let graph = try DirectedPseudograph<String>(gexf: input.utf8)
            Issue.record("expected duplicateKey, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateKey)
            #expect([error.line, error.column, error.byteOffset] == [1, 112, 111])
        }
    }

    @Test("GF-652 invalid UTF-8")
    func gf652() {
        // DirectedPseudograph<String>(gexf:) → **invalidUTF8** at 1:109
        let input: [UInt8] = [0x3C, 0x67, 0x65, 0x78, 0x66, 0x20, 0x78, 0x6D, 0x6C, 0x6E, 0x73, 0x3D, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x77, 0x77, 0x77, 0x2E, 0x67, 0x65, 0x78, 0x66, 0x2E, 0x6E, 0x65, 0x74, 0x2F, 0x31, 0x2E, 0x32, 0x64, 0x72, 0x61, 0x66, 0x74, 0x22, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x31, 0x2E, 0x32, 0x22, 0x3E, 0x3C, 0x67, 0x72, 0x61, 0x70, 0x68, 0x20, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74, 0x65, 0x64, 0x67, 0x65, 0x74, 0x79, 0x70, 0x65, 0x3D, 0x22, 0x64, 0x69, 0x72, 0x65, 0x63, 0x74, 0x65, 0x64, 0x22, 0x3E, 0x3C, 0x6E, 0x6F, 0x64, 0x65, 0x73, 0x3E, 0x3C, 0x6E, 0x6F, 0x64, 0x65, 0x20, 0x69, 0x64, 0x3D, 0x22, 0xC3, 0x28, 0x22, 0x2F, 0x3E, 0x3C, 0x2F, 0x6E, 0x6F, 0x64, 0x65, 0x73, 0x3E, 0x3C, 0x2F, 0x67, 0x72, 0x61, 0x70, 0x68, 0x3E, 0x3C, 0x2F, 0x67, 0x65, 0x78, 0x66, 0x3E]
        do {
            let graph = try DirectedPseudograph<String>(gexf: input)
            Issue.record("expected invalidUTF8, read \(graph)")
        } catch {
            #expect(error.kind == .invalidUTF8)
            #expect([error.line, error.column, error.byteOffset] == [1, 109, 108])
        }
    }

    @Test("GF-653 empty digraph")
    func gf653() throws {
        // writeGEXF(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeGEXF(to: &output)
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <nodes/>\n    <edges/>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-654 nodes without attributes are empty elements; edge ids are positions")
    func gf654() throws {
        // writeGEXF(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeGEXF(to: &output)
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <nodes>\n      <node id=\"a\"/>\n      <node id=\"b\"/>\n      <node id=\"z\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"a\" target=\"b\"/>\n    </edges>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-655 typed attributes: the node class then the edge class, ids by first appearance; label and weight as XML attributes")
    func gf655() throws {
        // writeGEXF(to:) on D: a{label="x y", n=3, x=2.0, ok=true}, b; a>b{weight=2, w2=-0.5}, b>b{label="l", weight=1.5}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        try graph.writeGEXF(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("label", .string("x y")), ("n", .integer(3)), ("x", .double(2.0)), ("ok", .boolean(true))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(2)), ("w2", .double(-0.5))]
            case 1: [("label", .string("l")), ("weight", .double(1.5))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <attributes class=\"node\" mode=\"static\">\n      <attribute id=\"0\" title=\"n\" type=\"long\"/>\n      <attribute id=\"1\" title=\"x\" type=\"double\"/>\n      <attribute id=\"2\" title=\"ok\" type=\"boolean\"/>\n    </attributes>\n    <attributes class=\"edge\" mode=\"static\">\n      <attribute id=\"3\" title=\"w2\" type=\"double\"/>\n    </attributes>\n    <nodes>\n      <node id=\"a\" label=\"x y\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"3\"/>\n          <attvalue for=\"1\" value=\"2.0\"/>\n          <attvalue for=\"2\" value=\"true\"/>\n        </attvalues>\n      </node>\n      <node id=\"b\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"a\" target=\"b\" weight=\"2\">\n        <attvalues>\n          <attvalue for=\"3\" value=\"-0.5\"/>\n        </attvalues>\n      </edge>\n      <edge id=\"1\" source=\"b\" target=\"b\" label=\"l\" weight=\"1.5\"/>\n    </edges>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-656 undirected, a loop, parallel edges")
    func gf656() throws {
        // writeGEXF(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writeGEXF(to: &output)
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"undirected\" mode=\"static\">\n    <nodes>\n      <node id=\"a\"/>\n      <node id=\"b\"/>\n      <node id=\"c\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"b\" target=\"a\"/>\n      <edge id=\"1\" source=\"a\" target=\"a\"/>\n      <edge id=\"2\" source=\"a\" target=\"b\"/>\n      <edge id=\"3\" source=\"c\" target=\"b\"/>\n    </edges>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-657 escaping in ids, labels and values")
    func gf657() throws {
        // writeGEXF(to:) on D: "a&<>\""{label="x & <y> \"z\" \r\n", s="<&>"}, "t\tn\nr\r"; "a&<>\"">"t\tn\nr\r"{label="\t", s="\""}
        let graph = DirectedPseudograph<String>(vertices: ["a&<>\"", "t\tn\nr\r"], edges: [DirectedEdge(from: "a&<>\"", to: "t\tn\nr\r")])
        var output = ""
        try graph.writeGEXF(to: &output, vertexAttributes: { v in
            switch v {
            case "a&<>\"": [("label", .string("x & <y> \"z\" \r\n")), ("s", .string("<&>"))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("label", .string("\t")), ("s", .string("\""))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <attributes class=\"node\" mode=\"static\">\n      <attribute id=\"0\" title=\"s\" type=\"string\"/>\n    </attributes>\n    <attributes class=\"edge\" mode=\"static\">\n      <attribute id=\"1\" title=\"s\" type=\"string\"/>\n    </attributes>\n    <nodes>\n      <node id=\"a&amp;&lt;&gt;&quot;\" label=\"x &amp; &lt;y&gt; &quot;z&quot; &#13;&#10;\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"&lt;&amp;&gt;\"/>\n        </attvalues>\n      </node>\n      <node id=\"t&#9;n&#10;r&#13;\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"a&amp;&lt;&gt;&quot;\" target=\"t&#9;n&#10;r&#13;\" label=\"&#9;\">\n        <attvalues>\n          <attvalue for=\"1\" value=\"&quot;\"/>\n        </attvalues>\n      </edge>\n    </edges>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-658 integer and double values under one key: double")
    func gf658() throws {
        // writeGEXF(to:) on D: a{w=1}, b; a>b{w=1}, b>a{w=2.5}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        var output = ""
        try graph.writeGEXF(to: &output, vertexAttributes: { v in
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
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <attributes class=\"node\" mode=\"static\">\n      <attribute id=\"0\" title=\"w\" type=\"long\"/>\n    </attributes>\n    <attributes class=\"edge\" mode=\"static\">\n      <attribute id=\"1\" title=\"w\" type=\"double\"/>\n    </attributes>\n    <nodes>\n      <node id=\"a\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"1\"/>\n        </attvalues>\n      </node>\n      <node id=\"b\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"a\" target=\"b\">\n        <attvalues>\n          <attvalue for=\"1\" value=\"1\"/>\n        </attvalues>\n      </edge>\n      <edge id=\"1\" source=\"b\" target=\"a\">\n        <attvalues>\n          <attvalue for=\"1\" value=\"2.5\"/>\n        </attvalues>\n      </edge>\n    </edges>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-659 INF, -INF, NaN, booleans")
    func gf659() throws {
        // writeGEXF(to:) on D: a{x=inf, y=-inf, z=nan, b=false}
        let graph = DirectedPseudograph<String>(vertices: ["a"])
        var output = ""
        try graph.writeGEXF(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("x", .double(.infinity)), ("y", .double(-.infinity)), ("z", .double(.nan)), ("b", .boolean(false))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <attributes class=\"node\" mode=\"static\">\n      <attribute id=\"0\" title=\"x\" type=\"double\"/>\n      <attribute id=\"1\" title=\"y\" type=\"double\"/>\n      <attribute id=\"2\" title=\"z\" type=\"double\"/>\n      <attribute id=\"3\" title=\"b\" type=\"boolean\"/>\n    </attributes>\n    <nodes>\n      <node id=\"a\">\n        <attvalues>\n          <attvalue for=\"0\" value=\"INF\"/>\n          <attvalue for=\"1\" value=\"-INF\"/>\n          <attvalue for=\"2\" value=\"NaN\"/>\n          <attvalue for=\"3\" value=\"false\"/>\n        </attvalues>\n      </node>\n    </nodes>\n    <edges/>\n  </graph>\n</gexf>\n")
    }

    @Test("GF-660 a weight written as its integer or double text, in the pairs' order with the label")
    func gf660() throws {
        // writeGEXF(to:) on D: a, b; a>b{weight=7, label="w first"}, b>a{label="l first", weight=0.25}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        var output = ""
        try graph.writeGEXF(to: &output, edgeAttributes: { e in
            switch e {
            case 0: [("weight", .integer(7)), ("label", .string("w first"))]
            case 1: [("label", .string("l first")), ("weight", .double(0.25))]
            default: []
            }
        })
        #expect(output == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd\" version=\"1.2\">\n  <graph defaultedgetype=\"directed\" mode=\"static\">\n    <nodes>\n      <node id=\"a\"/>\n      <node id=\"b\"/>\n    </nodes>\n    <edges>\n      <edge id=\"0\" source=\"a\" target=\"b\" weight=\"7\" label=\"w first\"/>\n      <edge id=\"1\" source=\"b\" target=\"a\" label=\"l first\" weight=\"0.25\"/>\n    </edges>\n  </graph>\n</gexf>\n")
    }
}
