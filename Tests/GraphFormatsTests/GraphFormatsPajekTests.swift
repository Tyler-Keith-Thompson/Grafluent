// Pajek (catalog GF-375 – GF-418 read, GF-559 – GF-563 write): *vertices with labels, coordinates and
// pairs, *arcs and *edges with weights, the list sections, shlex quoting; ref.py checks the write rows
// byte for byte against NetworkX's write_pajek.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats Pajek")
struct GraphFormatsPajekTests {
    @Test("GF-375 NetworkX's write_pajek output")
    func gf375() throws {
        // Pseudograph<String>(pajek:) → U: 0{x=0.0, y=0.0, shape="ellipse"}, 1{x=0.0, y=0.0, shape="ellipse"}, 2{x=0.0, y=0.0, shape="ellipse"}, 3{x=0.0, y=0.0, shape="ellipse"}; 0-1{weight=1.0}, 1-2{weight=1.0}, 2-3{weight=1.0}
        let input = "*vertices 4\n1 0 0.0 0.0 ellipse\n2 1 0.0 0.0 ellipse\n3 2 0.0 0.0 ellipse\n4 3 0.0 0.0 ellipse\n*edges\n1 2 1.0\n2 3 1.0\n3 4 1.0\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["0", "1", "2", "3"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["0", "1"], ["1", "2"], ["2", "3"]])
        #expect(vertexKeys == ["0": ["x", "y", "shape"], "1": ["x", "y", "shape"], "2": ["x", "y", "shape"], "3": ["x", "y", "shape"]])
        #expect(vertexValues == ["0": ["x": .double(0.0), "y": .double(0.0), "shape": .string("ellipse")], "1": ["x": .double(0.0), "y": .double(0.0), "shape": .string("ellipse")], "2": ["x": .double(0.0), "y": .double(0.0), "shape": .string("ellipse")], "3": ["x": .double(0.0), "y": .double(0.0), "shape": .string("ellipse")]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(1.0)], 1: ["weight": .double(1.0)], 2: ["weight": .double(1.0)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-376 arcs with weights and key-value pairs; vertices with coordinates, shape and pairs")
    func gf376() throws {
        // DirectedPseudograph<String>(pajek:) → D: a{x=0.1, y=0.2, shape="box", ic="Red"}, b, c{x=1.0, y=2.0}; a>b{weight=2.5, c="Blue", l="x y"}, b>c, c>c{weight=-1.0}
        let input = "*Vertices 3\n1 \"a\" 0.1 0.2 box ic Red\n2 \"b\"\n3 \"c\" 1 2\n*Arcs\n1 2 2.5 c Blue l \"x y\"\n2 3\n3 3 -1\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "c"]])
        #expect(vertexKeys == ["a": ["x", "y", "shape", "ic"], "c": ["x", "y"]])
        #expect(vertexValues == ["a": ["x": .double(0.1), "y": .double(0.2), "shape": .string("box"), "ic": .string("Red")], "c": ["x": .double(1.0), "y": .double(2.0)]])
        #expect(edgeKeys == [0: ["weight", "c", "l"], 2: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(2.5), "c": .string("Blue"), "l": .string("x y")], 2: ["weight": .double(-1.0)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-377 quoting as shlex: double and single quotes, escapes, joined pieces")
    func gf377() throws {
        // Pseudograph<String>(pajek:) → U: "a b", "c \"d", "x y", "pq rs\"t"; "a b"-"c \"d", "x y"-"pq rs\"t"
        let input = "*vertices 4\n1 \"a b\"\n2 'c \"d'\n3 x\\ y\n4 p\"q r\"s\\\"t\n*edges\n1 2\n3 4\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a b", "c \"d", "x y", "pq rs\"t"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a b", "c \"d"], ["x y", "pq rs\"t"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-378 a vertex without a line is named by its number; lines in any order")
    func gf378() throws {
        // Pseudograph<String>(pajek:) → U: a, 2, c, 4; 2-4, a-c
        let input = "*vertices 4\n3 \"c\"\n1 \"a\"\n*edges\n2 4\n1 3\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "2", "c", "4"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["2", "4"], ["a", "c"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-379 a vertex line with only its number is labelled by it")
    func gf379() throws {
        // Pseudograph<String>(pajek:) → U: a, 2; a-2
        let input = "*vertices 2\n2\n1 a\n*edges\n1 2\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "2"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "2"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-380 *network, % comments, blank lines, keywords in any case, a 2-mode count")
    func gf380() throws {
        // DirectedPseudograph<String>(pajek:) → D: a, b, c; a>c; graph{name="my net"}
        let input = "% made by hand\n*Network my net  \n\n*VERTICES 3 2\n% between\n1 a\n2 b\n3 c\n\n*arcs :1 \"rel\"\n1 3\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "c"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == ["name"])
        #expect(graphValues == ["name": .string("my net")])
    }

    @Test("GF-381 *arcslist: a vertex then its successors")
    func gf381() throws {
        // DirectedPseudograph<String>(pajek:) → D: 1, 2, 3; 1>2, 1>3, 3>1, 3>1
        let input = "*vertices 3\n*arcslist\n1 2 3\n2\n3 1 1\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["1", "2", "3"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["1", "2"], ["1", "3"], ["3", "1"], ["3", "1"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-382 *edgeslist")
    func gf382() throws {
        // Pseudograph<String>(pajek:) → U: 1, 2, 3; 1-2, 1-3
        let input = "*vertices 3\n*edgeslist\n1 2 3\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["1", "2", "3"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["1", "2"], ["1", "3"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-383 labels that map to one vertex are that vertex")
    func gf383() throws {
        // Pseudograph<String>(pajek:) → U: x, 3; x-x, x-3
        let input = "*vertices 3\n1 \"x\"\n2 \"x\"\n*edges\n1 2\n2 3\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["x", "3"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["x", "x"], ["x", "3"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-384 simple target: parallel arcs merge, last weight wins")
    func gf384() throws {
        // AdjacencyList<String>(pajek:) → D: a, b; a>b{weight=2.0}
        let input = "*vertices 2\n1 a\n2 b\n*arcs\n1 2 1\n1 2 2\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try AdjacencyList<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(2.0)]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-385 weights inf, -inf, nan and integers read as doubles")
    func gf385() throws {
        // DirectedPseudograph<String>(pajek:) → D: a, b; a>b{weight=inf}, b>a{weight=-inf}, a>a{weight=nan}, b>b{weight=3.0}
        let input = "*vertices 2\n1 a\n2 b\n*arcs\n1 2 inf\n2 1 -Infinity\n1 1 NaN\n2 2 3\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "a"], ["a", "a"], ["b", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"], 3: ["weight"]])
        #expect(edgeValues.count == 4)
        #expect(edgeValues[0]?["weight"] == .double(.infinity))
        #expect(edgeValues[1]?["weight"] == .double(-.infinity))
        #expect({ if case .double(let x)? = edgeValues[2]?["weight"] { x.isNaN } else { false } }())
        #expect(edgeValues[3]?["weight"] == .double(3.0))
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-386 CR LF")
    func gf386() throws {
        // Pseudograph<String>(pajek:) → U: a, b; a-b
        let input = "*vertices 2\r\n1 a\r\n2 b\r\n*edges\r\n1 2\r\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-387 a byte-order mark")
    func gf387() throws {
        // Pseudograph<String>(pajek:) → U: a
        let input = "\u{FEFF}*vertices 1\n1 a\n*edges\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a"])
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

    @Test("GF-388 no vertices")
    func gf388() throws {
        // Pseudograph<String>(pajek:) → U:
        let input = "*vertices 0\n*edges\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-389 an empty file is an empty graph")
    func gf389() throws {
        // DirectedPseudograph<String>(pajek:) → D:
        let input = ""
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-390 two *arcs sections")
    func gf390() throws {
        // DirectedPseudograph<String>(pajek:) → D: a, b; a>b, b>a
        let input = "*vertices 2\n1 a\n2 b\n*arcs\n1 2\n*arcs\n2 1\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-391 an empty quoted label")
    func gf391() throws {
        // DirectedPseudograph<String>(pajek:) → D: ""
        let input = "*vertices 1\n1 \"\"\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == [""])
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

    @Test("GF-392 *network after the vertices does not end their section")
    func gf392() throws {
        // DirectedPseudograph<String>(pajek:) → D: a, b; graph{name="n"}
        let input = "*vertices 2\n1 a\n*network n\n2 b\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == ["name"])
        #expect(graphValues == ["name": .string("n")])
    }

    @Test("GF-393 a data line before *vertices")
    func gf393() {
        // Pseudograph<String>(pajek:) → **syntax** at 1:1
        let input = "1 a\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-394 *edges before *vertices")
    func gf394() {
        // Pseudograph<String>(pajek:) → **syntax** at 1:1
        let input = "*edges\n1 2\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-395 *vertices without a count")
    func gf395() {
        // Pseudograph<String>(pajek:) → **syntax** at 1:10
        let input = "*vertices\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 10, 9])
        }
    }

    @Test("GF-396 a count that is not a number")
    func gf396() {
        // Pseudograph<String>(pajek:) → **syntax** at 1:11
        let input = "*vertices x\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-397 a third field on *vertices")
    func gf397() {
        // Pseudograph<String>(pajek:) → **syntax** at 1:15
        let input = "*vertices 2 1 0\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 15, 14])
        }
    }

    @Test("GF-398 a count past Int64")
    func gf398() {
        // Pseudograph<String>(pajek:) → **numberOutOfRange** at 1:11
        let input = "*vertices 9223372036854775808\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-399 a count above the default maximumVertexCount")
    func gf399() {
        // Pseudograph<String>(pajek:) → **limitExceeded** at 1:11
        let input = "*vertices 16777216\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-400 a count above maximumVertexCount")
    func gf400() {
        // Pseudograph<String>(pajek:, maximumVertexCount: 2) → **limitExceeded** at 1:11
        let input = "*vertices 3\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8, maximumVertexCount: 2)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-401 a count at maximumVertexCount")
    func gf401() throws {
        // DirectedPseudograph<String>(pajek:, maximumVertexCount: 2) → D: a, b
        let input = "*vertices 2\n1 a\n2 b\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(pajek: input.utf8, maximumVertexCount: 2, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-402 a vertex number 0")
    func gf402() {
        // Pseudograph<String>(pajek:) → **indexOutOfRange** at 2:1
        let input = "*vertices 2\n0 a\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-403 a vertex number beyond n")
    func gf403() {
        // Pseudograph<String>(pajek:) → **indexOutOfRange** at 2:1
        let input = "*vertices 2\n3 a\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-404 a vertex number that is not an integer")
    func gf404() {
        // Pseudograph<String>(pajek:) → **syntax** at 2:1
        let input = "*vertices 2\nx a\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-405 a vertex number given twice")
    func gf405() {
        // Pseudograph<String>(pajek:) → **duplicateVertex** at 3:1
        let input = "*vertices 2\n1 a\n1 b\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            #expect(error.kind == .duplicateVertex)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 16])
        }
    }

    @Test("GF-406 an x that is not a number")
    func gf406() {
        // Pseudograph<String>(pajek:) → **invalidValue** at 2:5
        let input = "*vertices 1\n1 a x 0.0\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [2, 5, 16])
        }
    }

    @Test("GF-407 a key without a value")
    func gf407() {
        // Pseudograph<String>(pajek:) → **syntax** at 2:13
        let input = "*vertices 1\n1 a 0 0 box ic\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 13, 24])
        }
    }

    @Test("GF-408 *arcs into an undirected target")
    func gf408() {
        // Pseudograph<String>(pajek:) → **kindMismatch** at 2:1
        let input = "*vertices 1\n*arcs\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-409 *edges into a directed target")
    func gf409() {
        // DirectedPseudograph<String>(pajek:) → **kindMismatch** at 2:1
        let input = "*vertices 1\n*edges\n"
        do {
            let graph = try DirectedPseudograph<String>(pajek: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-410 an edge line of one field")
    func gf410() {
        // Pseudograph<String>(pajek:) → **syntax** at 3:2
        let input = "*vertices 1\n*edges\n1\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 2, 20])
        }
    }

    @Test("GF-411 an endpoint beyond n")
    func gf411() {
        // Pseudograph<String>(pajek:) → **indexOutOfRange** at 3:3
        let input = "*vertices 1\n*edges\n1 2\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [3, 3, 21])
        }
    }

    @Test("GF-412 an endpoint that is not an integer")
    func gf412() {
        // Pseudograph<String>(pajek:) → **syntax** at 3:3
        let input = "*vertices 1\n*edges\n1 a\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 3, 21])
        }
    }

    @Test("GF-413 a weight that is not a number")
    func gf413() {
        // Pseudograph<String>(pajek:) → **invalidValue** at 3:5
        let input = "*vertices 1\n*edges\n1 1 w\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [3, 5, 23])
        }
    }

    @Test("GF-414 an unclosed quote")
    func gf414() {
        // Pseudograph<String>(pajek:) → **syntax** at 2:3
        let input = "*vertices 1\n1 \"a\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 14])
        }
    }

    @Test("GF-415 a backslash at the end of a line")
    func gf415() {
        // Pseudograph<String>(pajek:) → **syntax** at 2:4
        let input = "*vertices 1\n1 a\\\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 4, 15])
        }
    }

    @Test("GF-416 *matrix (unsupported)")
    func gf416() {
        // Pseudograph<String>(pajek:) → **unsupported** at 2:1
        let input = "*vertices 2\n*matrix\n0 1\n1 0\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-417 a second *vertices (unsupported)")
    func gf417() {
        // Pseudograph<String>(pajek:) → **unsupported** at 2:1
        let input = "*vertices 1\n*vertices 1\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-418 an unknown section (unsupported)")
    func gf418() {
        // Pseudograph<String>(pajek:) → **unsupported** at 2:1
        let input = "*vertices 1\n*partition p\n1\n"
        do {
            let graph = try Pseudograph<String>(pajek: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 12])
        }
    }

    @Test("GF-559 empty digraph")
    func gf559() throws {
        // writePajek(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writePajek(to: &output)
        #expect(output == "*vertices 0\n*arcs\n")
    }

    @Test("GF-560 undirected path: NetworkX's defaults for x, y, shape and weight")
    func gf560() throws {
        // writePajek(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<String>(vertices: ["0", "1", "2"], edges: [UndirectedEdge("0", "1"), UndirectedEdge("1", "2")])
        var output = ""
        try graph.writePajek(to: &output)
        #expect(output == "*vertices 3\n1 0 0.0 0.0 ellipse\n2 1 0.0 0.0 ellipse\n3 2 0.0 0.0 ellipse\n*edges\n1 2 1.0\n2 3 1.0\n")
    }

    @Test("GF-561 coordinates, shape, weights and key-value pairs")
    func gf561() throws {
        // writePajek(to:) on D: a{x=0.5, y=2, shape="box", ic="Red"}, b{ic="Blue", x=-1.0}, c; a>b{weight=2.5, c="Green"}, b>c{weight=3}, c>c{l=1}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "c")])
        var output = ""
        try graph.writePajek(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("x", .double(0.5)), ("y", .integer(2)), ("shape", .string("box")), ("ic", .string("Red"))]
            case "b": [("ic", .string("Blue")), ("x", .double(-1.0))]
            default: []
            }
        }, edgeAttributes: { e in
            switch e {
            case 0: [("weight", .double(2.5)), ("c", .string("Green"))]
            case 1: [("weight", .integer(3))]
            case 2: [("l", .integer(1))]
            default: []
            }
        })
        #expect(output == "*vertices 3\n1 a 0.5 2 box ic Red\n2 b -1.0 0.0 ellipse ic Blue\n3 c 0.0 0.0 ellipse\n*arcs\n1 2 2.5 c Green\n2 3 3\n3 3 1.0 l 1\n")
    }

    @Test("GF-562 quoting: whitespace, quotes, backslashes, apostrophes, empty strings")
    func gf562() throws {
        // writePajek(to:) on U: "a b", "q\"r", "back\\slash", "it's", "", plain{"k y"="v w", e=""}, "nb sp"; "a b"-"q\"r", "it's"-""
        let graph = Pseudograph<String>(vertices: ["a b", "q\"r", "back\\slash", "it's", "", "plain", "nb\u{A0}sp"], edges: [UndirectedEdge("a b", "q\"r"), UndirectedEdge("it's", "")])
        var output = ""
        try graph.writePajek(to: &output, vertexAttributes: { v in
            switch v {
            case "plain": [("k y", .string("v w")), ("e", .string(""))]
            default: []
            }
        })
        #expect(output == "*vertices 7\n1 \"a b\" 0.0 0.0 ellipse\n2 \"q\\\"r\" 0.0 0.0 ellipse\n3 \"back\\\\slash\" 0.0 0.0 ellipse\n4 \"it's\" 0.0 0.0 ellipse\n5 \"\" 0.0 0.0 ellipse\n6 plain 0.0 0.0 ellipse \"k y\" \"v w\" e \"\"\n7 \"nb\u{A0}sp\" 0.0 0.0 ellipse\n*edges\n1 2 1.0\n4 5 1.0\n")
    }

    @Test("GF-563 parallel edges and a loop")
    func gf563() throws {
        // writePajek(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writePajek(to: &output)
        #expect(output == "*vertices 3\n1 a 0.0 0.0 ellipse\n2 b 0.0 0.0 ellipse\n3 c 0.0 0.0 ellipse\n*edges\n2 1 1.0\n1 1 1.0\n1 2 1.0\n3 2 1.0\n")
    }
}
