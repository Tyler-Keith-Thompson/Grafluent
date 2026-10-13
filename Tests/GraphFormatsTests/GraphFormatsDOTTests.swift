// DOT (catalog GF-001 – GF-042 and GF-226 read, GF-186 – GF-192 write): the grammar without subgraphs
// and ports, values read as strings, node and edge defaults applied to later statements, strict
// merging, DOT's quoting; the writer's canonical form, quoting only where an ID needs it.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats DOT")
struct GraphFormatsDOTTests {
    @Test("GF-001 empty digraph")
    func gf001() throws {
        // DirectedPseudograph<String>(dot:) → D:
        let input = "digraph {}"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-002 one edge creates both vertices")
    func gf002() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b; a>b
        let input = "digraph { a -> b }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-003 edge chain: one edge per hop, attributes on each")
    func gf003() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b, c; a>b{w="1"}, b>c{w="1"}
        let input = "digraph { a -> b -> c [w=1] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"], 1: ["w"]])
        #expect(edgeValues == [0: ["w": .string("1")], 1: ["w": .string("1")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-004 node statements merge, later value wins")
    func gf004() throws {
        // DirectedPseudograph<String>(dot:) → D: a{x="3", y="2"}
        let input = "digraph { a [x=1]; a [y=2, x=3] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["x", "y"]])
        #expect(vertexValues == ["a": ["x": .string("3"), "y": .string("2")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-005 node defaults apply to vertices created later, also by edges")
    func gf005() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b{shape="box"}, c{shape="box"}; a>c
        let input = "digraph {\n  a\n  node [shape=box]\n  b\n  a -> c\n}\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["b": ["shape"], "c": ["shape"]])
        #expect(vertexValues == ["b": ["shape": .string("box")], "c": ["shape": .string("box")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-006 edge defaults apply to later edges; explicit overrides")
    func gf006() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b, c, d; a>b{w="1"}, b>c{w="2"}, c>d{w="3"}
        let input = "digraph { edge [w=1]; a -> b; edge [w=2]; b -> c; c -> d [w=3] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c", "d"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["c", "d"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["w"], 1: ["w"], 2: ["w"]])
        #expect(edgeValues == [0: ["w": .string("1")], 1: ["w": .string("2")], 2: ["w": .string("3")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-007 graph attributes: ID = ID and graph [ ]")
    func gf007() throws {
        // DirectedPseudograph<String>(dot:) → D:; graph{rankdir="LR", label="t"}
        let input = "digraph { rankdir=LR; graph [label=\"t\"] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(graphKeys == ["rankdir", "label"])
        #expect(graphValues == ["rankdir": .string("LR"), "label": .string("t")])
    }

    @Test("GF-008 graph name is not reported")
    func gf008() throws {
        // DirectedPseudograph<String>(dot:) → D: a
        let input = "digraph G { a }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-009 quoted IDs; \\\" is the only escape")
    func gf009() throws {
        // DirectedPseudograph<String>(dot:) → D: "a b", "c\"d"; "a b">"c\"d"
        let input = "digraph { \"a b\" -> \"c\\\"d\" }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a b", "c\"d"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["a b", "c\"d"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-010 other backslashes are kept")
    func gf010() throws {
        // DirectedPseudograph<String>(dot:) → D: "a\\nb"
        let input = "digraph { \"a\\nb\" }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a\\nb"])
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

    @Test("GF-011 backslash-newline continues a quoted string")
    func gf011() throws {
        // DirectedPseudograph<String>(dot:) → D: abc
        let input = "digraph { \"ab\\\nc\" }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["abc"])
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

    @Test("GF-012 + concatenates quoted strings")
    func gf012() throws {
        // DirectedPseudograph<String>(dot:) → D: xy, b; xy>b
        let input = "digraph { \"x\" + \"y\" -> b }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["xy", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["xy", "b"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-013 HTML string: the text between the outer brackets")
    func gf013() throws {
        // DirectedPseudograph<String>(dot:) → D: a{label="<b>x</b>"}
        let input = "digraph { a [label=<<b>x</b>>] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["label"]])
        #expect(vertexValues == ["a": ["label": .string("<b>x</b>")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-014 numerals are IDs")
    func gf014() throws {
        // DirectedPseudograph<String>(dot:) → D: "1.5", "-2", ".5", "3."; "1.5">"-2", "-2">".5", ".5">"3."
        let input = "digraph { 1.5 -> -2 -> .5 -> 3. }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["1.5", "-2", ".5", "3."])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["1.5", "-2"], ["-2", ".5"], [".5", "3."]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-015 keywords are case-insensitive")
    func gf015() throws {
        // DirectedPseudograph<String>(dot:) → D: x{k="v"}
        let input = "DiGraph { NODE [k=v]; x }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["x"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == ["x": ["k"]])
        #expect(vertexValues == ["x": ["k": .string("v")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-016 comments: //, /* */, and # lines")
    func gf016() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b; a>b
        let input = "# preprocessor\ndigraph { // one\n a /* two */ -> b\n}\n"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-017 non-ASCII identifiers")
    func gf017() throws {
        // DirectedPseudograph<String>(dot:) → D: "é", "日本"; "é">"日本"
        let input = "digraph { é -> 日本 }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["é", "日本"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["é", "日本"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-018 parallel edges and a loop kept")
    func gf018() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b; a>b, a>b{k="2"}, a>a
        let input = "digraph { a -> b; a -> b [k=2]; a -> a }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [1: ["k"]])
        #expect(edgeValues == [1: ["k": .string("2")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-019 simple target: a parallel edge is the same edge, attributes merge")
    func gf019() throws {
        // AdjacencyList<String>(dot:) → D: a, b; a>b{x="1", y="2"}
        let input = "digraph { a -> b [x=1]; a -> b [y=2] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try AdjacencyList<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["x", "y"]])
        #expect(edgeValues == [0: ["x": .string("1"), "y": .string("2")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-020 strict: parallel edges merge")
    func gf020() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b; a>b{x="3", y="2"}
        let input = "strict digraph { a -> b [x=1]; a -> b [y=2, x=3] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(edgeKeys == [0: ["x", "y"]])
        #expect(edgeValues == [0: ["x": .string("3"), "y": .string("2")]])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-021 strict graph: b -- a is a -- b; loops allowed")
    func gf021() throws {
        // Pseudograph<String>(dot:) → U: a, b; a-b, a-a
        let input = "strict graph { a -- b; b -- a; a -- a }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["a", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-022 undirected")
    func gf022() throws {
        // Pseudograph<String>(dot:) → U: a, b, c; a-b, b-c, c-a
        let input = "graph { a -- b -- c; c -- a }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"], ["b", "c"], ["c", "a"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-023 undirected parallel edges kept")
    func gf023() throws {
        // Pseudograph<String>(dot:) → U: a, b; a-b, b-a
        let input = "graph { a -- b; b -- a }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try Pseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-024 attribute lists: ; and , separators, several lists")
    func gf024() throws {
        // DirectedPseudograph<String>(dot:) → D: a{p="1", q="2", r="3", s="4"}
        let input = "digraph { a [p=1; q=2, r=3][s=4] }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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
        #expect(vertexKeys == ["a": ["p", "q", "r", "s"]])
        #expect(vertexValues == ["a": ["p": .string("1"), "q": .string("2"), "r": .string("3"), "s": .string("4")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-025 a byte-order mark is skipped")
    func gf025() throws {
        // DirectedPseudograph<String>(dot:) → D: a
        let input = "\u{FEFF}digraph { a }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
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

    @Test("GF-026 statements need no separator")
    func gf026() throws {
        // DirectedPseudograph<String>(dot:) → D: a, b, c, d; b>c
        let input = "digraph { a b -> c d }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["a", "b", "c", "d"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["b", "c"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }

    @Test("GF-027 graph into a directed target")
    func gf027() {
        // DirectedPseudograph<String>(dot:) → **kindMismatch** at 1:1
        let input = "graph { a -- b }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-028 digraph into an undirected target")
    func gf028() {
        // Pseudograph<String>(dot:) → **kindMismatch** at 1:1
        let input = "digraph { a -> b }"
        do {
            let graph = try Pseudograph<String>(dot: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-029 -- in a digraph")
    func gf029() {
        // DirectedPseudograph<String>(dot:) → **syntax** at 1:13
        let input = "digraph { a -- b }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 13, 12])
        }
    }

    @Test("GF-030 subgraph (unsupported)")
    func gf030() {
        // DirectedPseudograph<String>(dot:) → **unsupported** at 1:11
        let input = "digraph { subgraph s { a } }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-031 anonymous subgraph as an endpoint (unsupported)")
    func gf031() {
        // DirectedPseudograph<String>(dot:) → **unsupported** at 1:16
        let input = "digraph { a -> { b c } }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 16, 15])
        }
    }

    @Test("GF-032 port (unsupported)")
    func gf032() {
        // DirectedPseudograph<String>(dot:) → **unsupported** at 1:12
        let input = "digraph { a:p -> b }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 12, 11])
        }
    }

    @Test("GF-033 a second graph (unsupported)")
    func gf033() {
        // DirectedPseudograph<String>(dot:) → **unsupported** at 2:1
        let input = "digraph { a }\ndigraph { b }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 14])
        }
    }

    @Test("GF-034 unterminated quoted string")
    func gf034() {
        // DirectedPseudograph<String>(dot:) → **unexpectedEndOfInput** at 1:11
        let input = "digraph { \"a }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-035 unterminated comment")
    func gf035() {
        // DirectedPseudograph<String>(dot:) → **unexpectedEndOfInput** at 1:11
        let input = "digraph { /* a }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-036 missing closing brace")
    func gf036() {
        // DirectedPseudograph<String>(dot:) → **unexpectedEndOfInput** at 1:17
        let input = "digraph { a -> b"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 17, 16])
        }
    }

    @Test("GF-037 numeral followed by a letter")
    func gf037() {
        // DirectedPseudograph<String>(dot:) → **syntax** at 1:12
        let input = "digraph { 1a }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 12, 11])
        }
    }

    @Test("GF-038 attribute without a value")
    func gf038() {
        // DirectedPseudograph<String>(dot:) → **syntax** at 1:15
        let input = "digraph { a [k] }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 15, 14])
        }
    }

    @Test("GF-039 edge operator with no tail")
    func gf039() {
        // DirectedPseudograph<String>(dot:) → **syntax** at 1:11
        let input = "digraph { -> b }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-040 missing graph keyword")
    func gf040() {
        // DirectedPseudograph<String>(dot:) → **syntax** at 1:8
        let input = "strict { a }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 8, 7])
        }
    }

    @Test("GF-041 invalid UTF-8")
    func gf041() {
        // DirectedPseudograph<String>(dot:) → **invalidUTF8** at 2:3
        let input: [UInt8] = [0x64, 0x69, 0x67, 0x72, 0x61, 0x70, 0x68, 0x20, 0x7B, 0x0A, 0x20, 0x20, 0xC3, 0x28, 0x20, 0x7D]
        do {
            let graph = try DirectedPseudograph<String>(dot: input)
            Issue.record("expected invalidUTF8, read \(graph)")
        } catch {
            #expect(error.kind == .invalidUTF8)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 12])
        }
    }

    @Test("GF-042 + before a non-quoted ID")
    func gf042() {
        // DirectedPseudograph<String>(dot:) → **syntax** at 1:17
        let input = "digraph { \"a\" + b }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 17, 16])
        }
    }

    @Test("GF-186 empty digraph")
    func gf186() throws {
        // writeDOT(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeDOT(to: &output)
        #expect(output == "digraph {\n}\n")
    }

    @Test("GF-187 every vertex, then every edge, in order")
    func gf187() throws {
        // writeDOT(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeDOT(to: &output)
        #expect(output == "digraph {\n\ta;\n\tb;\n\tz;\n\ta -> b;\n}\n")
    }

    @Test("GF-188 typed attributes; graph attributes first")
    func gf188() throws {
        // writeDOT(to:) on D: a{label="x y", n=3, x=2.0, ok=true}, b; a>b{weight=2, w2=-0.5}, b>b{weight=1.5}; graph{title="G"}
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
        var output = ""
        try graph.writeDOT(to: &output, vertexAttributes: { v in
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
        #expect(output == "digraph {\n\tgraph [title=G];\n\ta [label=\"x y\", n=3, x=2.0, ok=true];\n\tb;\n\ta -> b [weight=2, w2=-0.5];\n\tb -> b [weight=1.5];\n}\n")
    }

    @Test("GF-189 undirected, a loop, parallel edges")
    func gf189() throws {
        // writeDOT(to:) on U: a, b, c; b-a, a-a, a-b, c-b
        let graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "a"), UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        var output = ""
        try graph.writeDOT(to: &output)
        #expect(output == "graph {\n\ta;\n\tb;\n\tc;\n\tb -- a;\n\ta -- a;\n\ta -- b;\n\tc -- b;\n}\n")
    }

    @Test("GF-190 Int vertices are numerals")
    func gf190() throws {
        // writeDOT(to:) on U: 0, 1, 2; 0-1, 1-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var output = ""
        try graph.writeDOT(to: &output)
        #expect(output == "graph {\n\t0;\n\t1;\n\t2;\n\t0 -- 1;\n\t1 -- 2;\n}\n")
    }

    @Test("GF-191 quoting: keywords, numerals, non-ASCII, quotes, trailing backslash, backslash before newline")
    func gf191() throws {
        // writeDOT(to:) on D: node, "1.5", "-x"{k=1e-05}, "é"{inf=inf}, "a b", "q\"r", "tail\\", "bs\\\nnl", _ok9; node>"1.5"
        let graph = DirectedPseudograph<String>(vertices: ["node", "1.5", "-x", "é", "a b", "q\"r", "tail\\", "bs\\\nnl", "_ok9"], edges: [DirectedEdge(from: "node", to: "1.5")])
        var output = ""
        try graph.writeDOT(to: &output, vertexAttributes: { v in
            switch v {
            case "-x": [("k", .double(1e-05))]
            case "é": [("inf", .double(.infinity))]
            default: []
            }
        })
        #expect(output == "digraph {\n\t\"node\";\n\t1.5;\n\t\"-x\" [k=\"1e-05\"];\n\t\"é\" [inf=\"inf\"];\n\t\"a b\";\n\t\"q\\\"r\";\n\t\"tail\\\\\n\";\n\t\"bs\\\\\n\nnl\";\n\t_ok9;\n\t\"node\" -> 1.5;\n}\n")
    }

    @Test("GF-192 non-finite doubles and booleans")
    func gf192() throws {
        // writeDOT(to:) on D: a{x=inf, y=-inf, z=nan, b=false}
        let graph = DirectedPseudograph<String>(vertices: ["a"])
        var output = ""
        try graph.writeDOT(to: &output, vertexAttributes: { v in
            switch v {
            case "a": [("x", .double(.infinity)), ("y", .double(-.infinity)), ("z", .double(.nan)), ("b", .boolean(false))]
            default: []
            }
        })
        #expect(output == "digraph {\n\ta [x=\"inf\", y=\"-inf\", z=\"nan\", b=false];\n}\n")
    }

    @Test("GF-226 a non-ASCII digit starts an identifier, not a numeral")
    func gf226() throws {
        // DirectedPseudograph<String>(dot:) → D: "٣", x; "٣">x
        let input = "digraph { ٣ -> x }"
        var vertexKeys: [String: [String]] = [:]
        var vertexValues: [String: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        var graphKeys: [String] = []
        var graphValues: [String: AttributeValue] = [:]
        let graph = try DirectedPseudograph<String>(dot: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        }, graphAttribute: { key, value in
            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }
        })
        #expect(Array(graph.vertices) == ["٣", "x"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["٣", "x"]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
        #expect(graphKeys == [])
        #expect(graphValues == [:])
    }
}
