// LEDA (catalog GF-661 – GF-696 read, GF-697 – GF-701 write): the header, the two information types,
// the direction, the counted node and edge lines, information between |{ and }| typed by the declared
// type, blank and comment lines; the writer's types from the labels; NetworkX's parse_leda reads every
// row by the names it gives nodes.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats LEDA")
struct GraphFormatsLEDATests {
    @Test("GF-661 the header, string nodes, int edges, comments and blank lines")
    func gf661() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0{label="Alpha"}, 1{label="B C"}, 2{label=""}; 0>1{label=7}, 2>2{label=-1}
        let input = "LEDA.GRAPH\nstring\nint\n-1\n# nodes\n3\n|{Alpha}|\n|{B C}|\n|{}|\n\n# edges\n2\n1 2 0 |{7}|\n3 3 0 |{-1}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [2, 2]])
        #expect(vertexKeys == [0: ["label"], 1: ["label"], 2: ["label"]])
        #expect(vertexValues == [0: ["label": .string("Alpha")], 1: ["label": .string("B C")], 2: ["label": .string("")]])
        #expect(edgeKeys == [0: ["label"], 1: ["label"]])
        #expect(edgeValues == [0: ["label": .integer(7)], 1: ["label": .integer(-1)]])
    }

    @Test("GF-662 undirected (-2), void information on both sides")
    func gf662() throws {
        // Pseudograph<Int>(leda:) → U: 0, 1; 1-0
        let input = "LEDA.GRAPH\nvoid\nvoid\n-2\n2\n|{}|\n|{}|\n1\n2 1 0 |{}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 0]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-663 every information type: int, double, bool, string; whitespace around numbers; INF")
    func gf663() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0{label=1.5}, 1{label=2.0}, 2{label=inf}; 0>1{label=true}, 1>2{label=false}
        let input = "LEDA.GRAPH\ndouble\nbool\n-1\n3\n|{ 1.5 }|\n|{2}|\n|{INF}|\n2\n1 2 0 |{true}|\n2 3 0 |{ 0 }|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 2]])
        #expect(vertexKeys == [0: ["label"], 1: ["label"], 2: ["label"]])
        #expect(vertexValues == [0: ["label": .double(1.5)], 1: ["label": .double(2.0)], 2: ["label": .double(.infinity)]])
        #expect(edgeKeys == [0: ["label"], 1: ["label"]])
        #expect(edgeValues == [0: ["label": .boolean(true)], 1: ["label": .boolean(false)]])
    }

    #if _pointerBitWidth(_64)
    @Test("GF-664 long and float are int and double; an unknown type is string")
    func gf664() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0{label=-9223372036854775808}; 0>0{label=0.25}
        let input = "LEDA.GRAPH\nlong\nfloat\n-1\n1\n|{-9223372036854775808}|\n1\n1 1 0 |{0.25}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(vertexKeys == [0: ["label"]])
        #expect(vertexValues == [0: ["label": .integer(-9223372036854775808)]])
        #expect(edgeKeys == [0: ["label"]])
        #expect(edgeValues == [0: ["label": .double(0.25)]])
    }
    #endif

    @Test("GF-665 a type the format does not list reads as string")
    func gf665() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0{label="(1,2)"}
        let input = "LEDA.GRAPH\npoint\nvoid\n-1\n1\n|{(1,2)}|\n0\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == [0: ["label"]])
        #expect(vertexValues == [0: ["label": .string("(1,2)")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-666 information with |{ and }| inside: the last }| closes it")
    func gf666() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0{label="a}|b"}; 0>0{label="|{c}|"}
        let input = "LEDA.GRAPH\nstring\nstring\n-1\n1\n|{a}|b}|\n1\n1 1 0 |{|{c}|}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(vertexKeys == [0: ["label"]])
        #expect(vertexValues == [0: ["label": .string("a}|b")]])
        #expect(edgeKeys == [0: ["label"]])
        #expect(edgeValues == [0: ["label": .string("|{c}|")]])
    }

    @Test("GF-667 blanks around the information and the reversal index; CR LF; tabs")
    func gf667() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0{label="a"}, 1{label="b"}; 0>1, 1>0
        let input = "LEDA.GRAPH\nstring\r\nvoid\r\n-1\r\n2\r\n  |{a}|  \r\n|{b}|\r\n2\r\n1\t2\t2 |{}|\r\n2 1 1 |{}|\r\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 0]])
        #expect(vertexKeys == [0: ["label"], 1: ["label"]])
        #expect(vertexValues == [0: ["label": .string("a")], 1: ["label": .string("b")]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-668 parallel edges and loops kept")
    func gf668() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0, 1; 0>1, 0>1, 1>1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n2\n|{}|\n|{}|\n3\n1 2 0 |{}|\n1 2 0 |{}|\n2 2 0 |{}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [0, 1], [1, 1]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-669 simple target: a repeated edge merges, last information wins")
    func gf669() throws {
        // AdjacencyList<Int>(leda:) → D: 0, 1; 0>1{label=2}
        let input = "LEDA.GRAPH\nvoid\nint\n-1\n2\n|{}|\n|{}|\n2\n1 2 0 |{1}|\n1 2 0 |{2}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try AdjacencyList<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["label"]])
        #expect(edgeValues == [0: ["label": .integer(2)]])
    }

    @Test("GF-670 simple undirected target: 2 1 is 1 2")
    func gf670() throws {
        // UndirectedAdjacencyList<Int>(leda:) → U: 0, 1; 0-1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-2\n2\n|{}|\n|{}|\n2\n1 2 0 |{}|\n2 1 0 |{}|\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try UndirectedAdjacencyList<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-671 no nodes, no edges")
    func gf671() throws {
        // DirectedPseudograph<Int>(leda:) → D:
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n0\n0\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-672 a comment line between the edges and after them")
    func gf672() throws {
        // DirectedPseudograph<Int>(leda:) → D: 0; 0>0
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n# e\n1 1 0 |{}|\n# end\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(leda: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-673 a first line that is not LEDA.GRAPH")
    func gf673() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 1:1
        let input = "GRAPH\nvoid\nvoid\n-1\n0\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-674 two words on a type line")
    func gf674() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 2:6
        let input = "LEDA.GRAPH\nvoid x\nvoid\n-1\n0\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 6, 16])
        }
    }

    @Test("GF-675 a direction that is neither -1 nor -2")
    func gf675() {
        // DirectedPseudograph<Int>(leda:) → **invalidValue** at 4:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-3\n0\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 21])
        }
    }

    @Test("GF-676 -1 into an undirected target")
    func gf676() {
        // Pseudograph<Int>(leda:) → **kindMismatch** at 4:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n0\n0\n"
        do {
            let graph = try Pseudograph<Int>(leda: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 21])
        }
    }

    @Test("GF-677 -2 into a directed target")
    func gf677() {
        // DirectedPseudograph<Int>(leda:) → **kindMismatch** at 4:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-2\n0\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 21])
        }
    }

    @Test("GF-678 a node count that is not a number")
    func gf678() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 5:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\nx\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [5, 1, 24])
        }
    }

    @Test("GF-679 a node count beyond Int")
    func gf679() {
        // DirectedPseudograph<Int>(leda:) → **numberOutOfRange** at 5:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n99999999999999999999\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [5, 1, 24])
        }
    }

    @Test("GF-680 a node count over maximumVertexCount")
    func gf680() {
        // DirectedPseudograph<Int>(leda:, maximumVertexCount: 4) → **limitExceeded** at 5:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n5\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8, maximumVertexCount: 4)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [5, 1, 24])
        }
    }

    @Test("GF-681 a node line without the brackets")
    func gf681() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 6:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n{}\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [6, 1, 26])
        }
    }

    @Test("GF-682 int information that is not an integer")
    func gf682() {
        // DirectedPseudograph<Int>(leda:) → **invalidValue** at 6:3
        let input = "LEDA.GRAPH\nint\nvoid\n-1\n1\n|{x}|\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [6, 3, 27])
        }
    }

    @Test("GF-683 int information beyond Int")
    func gf683() {
        // DirectedPseudograph<Int>(leda:) → **numberOutOfRange** at 6:3
        let input = "LEDA.GRAPH\nint\nvoid\n-1\n1\n|{9223372036854775808}|\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [6, 3, 27])
        }
    }

    @Test("GF-684 bool information that is not a boolean")
    func gf684() {
        // DirectedPseudograph<Int>(leda:) → **invalidValue** at 6:3
        let input = "LEDA.GRAPH\nbool\nvoid\n-1\n1\n|{yes}|\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [6, 3, 28])
        }
    }

    @Test("GF-685 double information that is not a number")
    func gf685() {
        // DirectedPseudograph<Int>(leda:) → **invalidValue** at 6:3
        let input = "LEDA.GRAPH\ndouble\nvoid\n-1\n1\n|{1,5}|\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [6, 3, 30])
        }
    }

    @Test("GF-686 fewer node lines than the count")
    func gf686() {
        // DirectedPseudograph<Int>(leda:) → **unexpectedEndOfInput** at 7:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n2\n|{}|\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [7, 1, 31])
        }
    }

    @Test("GF-687 an edge line with three fields")
    func gf687() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 8:6
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n1 1 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [8, 6, 38])
        }
    }

    @Test("GF-688 an endpoint outside 1...n")
    func gf688() {
        // DirectedPseudograph<Int>(leda:) → **indexOutOfRange** at 8:3
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n1 2 0 |{}|\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [8, 3, 35])
        }
    }

    @Test("GF-689 an endpoint that is not a number")
    func gf689() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 8:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\na 1 0 |{}|\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [8, 1, 33])
        }
    }

    @Test("GF-690 a reversal index above m")
    func gf690() {
        // DirectedPseudograph<Int>(leda:) → **indexOutOfRange** at 8:5
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n1\n1 1 2 |{}|\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [8, 5, 37])
        }
    }

    @Test("GF-691 an edge information without the brackets")
    func gf691() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 8:7
        let input = "LEDA.GRAPH\nvoid\nstring\n-1\n1\n|{}|\n1\n1 1 0 x\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [8, 7, 41])
        }
    }

    @Test("GF-692 fewer edge lines than the count")
    func gf692() {
        // DirectedPseudograph<Int>(leda:) → **unexpectedEndOfInput** at 9:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n2\n1 1 0 |{}|\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [9, 1, 44])
        }
    }

    @Test("GF-693 a line after the last edge")
    func gf693() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 10:1
        let input = "LEDA.GRAPH\nvoid\nvoid\n-1\n1\n|{}|\n0\n\n# c\nx\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [10, 1, 38])
        }
    }

    @Test("GF-694 empty input")
    func gf694() {
        // DirectedPseudograph<Int>(leda:) → **unexpectedEndOfInput** at 1:1
        let input = ""
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-695 invalid UTF-8")
    func gf695() {
        // DirectedPseudograph<Int>(leda:) → **invalidUTF8** at 6:3
        let input: [UInt8] = [0x4C, 0x45, 0x44, 0x41, 0x2E, 0x47, 0x52, 0x41, 0x50, 0x48, 0x0A, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x0A, 0x76, 0x6F, 0x69, 0x64, 0x0A, 0x2D, 0x31, 0x0A, 0x31, 0x0A, 0x7C, 0x7B, 0xC3, 0x28, 0x7D, 0x7C, 0x0A, 0x30, 0x0A]
        do {
            let graph = try DirectedPseudograph<Int>(leda: input)
            Issue.record("expected invalidUTF8, read \(graph)")
        } catch {
            #expect(error.kind == .invalidUTF8)
            #expect([error.line, error.column, error.byteOffset] == [6, 3, 30])
        }
    }

    @Test("GF-696 information closed by | alone")
    func gf696() {
        // DirectedPseudograph<Int>(leda:) → **syntax** at 6:1
        let input = "LEDA.GRAPH\nstring\nvoid\n-1\n1\n|{a|\n0\n"
        do {
            let graph = try DirectedPseudograph<Int>(leda: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [6, 1, 28])
        }
    }

    @Test("GF-697 void information on both sides; edges with reversal 0")
    func gf697() throws {
        // writeLEDA(to:) on D: 0, 1, 2; 0>1, 1>1, 0>1
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1)])
        var output = ""
        try graph.writeLEDA(to: &output)
        #expect(output == "LEDA.GRAPH\nvoid\nvoid\n-1\n3\n|{}|\n|{}|\n|{}|\n3\n1 2 0 |{}|\n2 2 0 |{}|\n1 2 0 |{}|\n")
    }

    @Test("GF-698 string nodes and int edges")
    func gf698() throws {
        // writeLEDA(to:) on D: 0, 1, 2; 0>1, 1>1, 0>1
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1)])
        let vertexLabels: [AttributeValue?] = [.string("a"), .string("b c"), .string("|{d}|")]
        let edgeLabels: [AttributeValue?] = [.integer(1), .integer(-2), .integer(3)]
        var output = ""
        try graph.writeLEDA(to: &output, vertexLabel: { vertexLabels[$0] }, edgeLabel: { edgeLabels[$0] })
        #expect(output == "LEDA.GRAPH\nstring\nint\n-1\n3\n|{a}|\n|{b c}|\n|{|{d}|}|\n3\n1 2 0 |{1}|\n2 2 0 |{-2}|\n1 2 0 |{3}|\n")
    }

    @Test("GF-699 a nil string is empty; doubles with an integer among them are double; booleans")
    func gf699() throws {
        // writeLEDA(to:) on D: 0, 1, 2; 0>1, 1>2
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let vertexLabels: [AttributeValue?] = [.string("x"), nil, .string("z")]
        let edgeLabels: [AttributeValue?] = [.double(1.5), .integer(2)]
        var output = ""
        try graph.writeLEDA(to: &output, vertexLabel: { vertexLabels[$0] }, edgeLabel: { edgeLabels[$0] })
        #expect(output == "LEDA.GRAPH\nstring\ndouble\n-1\n3\n|{x}|\n|{}|\n|{z}|\n2\n1 2 0 |{1.5}|\n2 3 0 |{2.0}|\n")
    }

    @Test("GF-700 undirected, booleans, INF and NaN")
    func gf700() throws {
        // writeLEDA(to:) on U: 0, 1; 1-0, 0-0
        let graph = Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 0)])
        let vertexLabels: [AttributeValue?] = [.boolean(true), .boolean(false)]
        let edgeLabels: [AttributeValue?] = [.double(.infinity), .double(.nan)]
        var output = ""
        try graph.writeLEDA(to: &output, vertexLabel: { vertexLabels[$0] }, edgeLabel: { edgeLabels[$0] })
        #expect(output == "LEDA.GRAPH\nbool\ndouble\n-2\n2\n|{true}|\n|{false}|\n2\n2 1 0 |{INF}|\n1 1 0 |{NaN}|\n")
    }

    @Test("GF-701 empty graph")
    func gf701() throws {
        // writeLEDA(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeLEDA(to: &output)
        #expect(output == "LEDA.GRAPH\nvoid\nvoid\n-1\n0\n0\n")
    }
}
