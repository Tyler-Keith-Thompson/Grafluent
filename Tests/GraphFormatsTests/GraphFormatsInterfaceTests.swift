// The reader and writer contracts the catalog rows do not reach: the `vertex` closure (called once
// per new ID, in first-appearance order; nil is invalidVertex at the ID; two IDs onto one vertex make
// one vertex), every kind of target (simple, multigraph, stable, Int overloads), every kind of input
// sequence, the byte-order mark in every format, positions in Unicode scalars and bytes, the writers'
// closure calls (once per element, in order; GraphML twice), the line ends, writers over other
// representations, and AttributeValue's literals. See README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("GraphFormats interface")
struct GraphFormatsInterfaceTests {
    @Test("The vertex closure maps each new ID once, in first-appearance order, in every format")
    func vertexClosureOncePerID() throws {
        var seen: [String] = []
        let dot = try DirectedPseudograph<String>(dot: "digraph { b -> a; a -> b; b; c -> c }".utf8, vertex: { seen.append($0); return $0.uppercased() })
        #expect(seen == ["b", "a", "c"])
        #expect(Array(dot.vertices) == ["B", "A", "C"])
        #expect(dot.edges.map { [$0.source, $0.target] } == [["B", "A"], ["A", "B"], ["C", "C"]])

        seen = []
        let graphML = try DirectedPseudograph<String>(
            graphML: "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><edge source=\"z\" target=\"y\"/><node id=\"y\"/><node id=\"z\"/><edge source=\"y\" target=\"z\"/></graph></graphml>".utf8,
            vertex: { seen.append($0); return "n" + $0 })
        #expect(seen == ["y", "z"])
        #expect(Array(graphML.vertices) == ["ny", "nz"])
        #expect(graphML.edges.map { [$0.source, $0.target] } == [["nz", "ny"], ["ny", "nz"]])

        var ids: [AttributeValue] = []
        let nodeLink = try Pseudograph<Int>(
            nodeLinkJSON: "{\"nodes\": [{\"id\": \"x\"}, {\"id\": 4}], \"edges\": [{\"source\": 4, \"target\": \"x\"}, {\"source\": \"x\", \"target\": \"x\"}]}".utf8,
            vertex: { ids.append($0); return $0 == .string("x") ? 10 : 40 })
        #expect(ids == [.string("x"), .integer(4)])
        #expect(Array(nodeLink.vertices) == [10, 40])
        #expect(nodeLink.edges.map { [$0.u, $0.v] } == [[40, 10], [10, 10]])

        var indices: [Int] = []
        let matrix = try DirectedPseudograph<String>(matrixMarket: "%%MatrixMarket matrix coordinate pattern general\n3 3 2\n3 1\n1 3\n".utf8,
                                                     vertex: { indices.append($0); return "m\($0)" })
        #expect(indices == [0, 1, 2])
        #expect(Array(matrix.vertices) == ["m0", "m1", "m2"])
        #expect(matrix.edges.map { [$0.source, $0.target] } == [["m2", "m0"], ["m0", "m2"]])

        seen = []
        let edgeList = try DirectedPseudograph<Int>(edgeList: "x y\ny x\nz z\n".utf8, vertex: { seen.append($0); return Int($0.unicodeScalars.first!.value) })
        #expect(seen == ["x", "y", "z"])
        #expect(Array(edgeList.vertices) == [120, 121, 122])

        seen = []
        let adjacency = try Pseudograph<String>(adjacencyList: "p q r\nq p\n".utf8, vertex: { seen.append($0); return $0 + $0 })
        #expect(seen == ["p", "q", "r"])
        #expect(adjacency.edges.map { [$0.u, $0.v] } == [["pp", "qq"], ["pp", "rr"], ["qq", "pp"]])

        seen = []
        var labels: [String: String] = [:]
        let mermaid = try DirectedPseudograph<String>(mermaid: "flowchart TD\n  B[two] --> A\n  A --> B\n".utf8, vertex: { seen.append($0); return $0.lowercased() },
                                                      vertexLabel: { labels[$0] = $1 })
        #expect(seen == ["B", "A"])
        #expect(Array(mermaid.vertices) == ["b", "a"])
        #expect(labels == ["b": "two"])
    }

    @Test("A nil from the vertex closure is invalidVertex at the ID, in every format")
    func vertexClosureNil() {
        do {
            let graph = try DirectedPseudograph<String>(dot: "digraph {\n  a -> \"bad\"\n}".utf8, vertex: { $0 == "bad" ? nil : $0 })
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [2, 8, 17])
        }
        do {
            let graph = try DirectedPseudograph<String>(
                graphML: "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/><node id=\"é\"/></graph></graphml>".utf8,
                vertex: { $0 == "é" ? nil : $0 })
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 106, 105])
        }
        do {
            let graph = try DirectedPseudograph<Int>(edgeList: "1 2\n2 x\n".utf8)
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 6])
        }
        do {
            let graph = try Pseudograph<Int>(adjacencyList: "1 2 3\n4 2.5\n".utf8)
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 8])
        }
        do {
            let graph = try DirectedPseudograph<String>(mermaid: "flowchart TD\n  A --> B\n".utf8, vertex: { $0 == "B" ? nil : $0 })
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [2, 9, 21])
        }
        do {
            let graph = try DirectedPseudograph<Int>(nodeLinkJSON: "{\"directed\": true, \"nodes\": [{\"id\": 1}, {\"id\": 2.5}], \"edges\": []}".utf8)
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            // An id must be a string or an integer: anything else is invalidValue, before any mapping.
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 48, 47])
        }
        do {
            let graph = try DirectedPseudograph<Int>(nodeLinkJSON: "{\"directed\": true, \"nodes\": [{\"id\": 1}, {\"id\": 2}], \"edges\": []}".utf8, vertex: {
                if case .integer(2) = $0 { nil } else { 1 }
            })
            Issue.record("expected invalidVertex, read \(graph)")
        } catch {
            #expect(error.kind == .invalidVertex)
            #expect([error.line, error.column, error.byteOffset] == [1, 48, 47])
        }
    }

    @Test("Two IDs mapped to one vertex are one vertex")
    func twoIDsOneVertex() throws {
        let dot = try DirectedPseudograph<String>(dot: "digraph { A -> a; a -> B }".utf8, vertex: { $0.lowercased() })
        #expect(Array(dot.vertices) == ["a", "b"])
        #expect(dot.edges.map { [$0.source, $0.target] } == [["a", "a"], ["a", "b"]])
        let list = try Pseudograph<Int>(edgeList: "1 01\n+1 2\n".utf8, vertex: { Int($0) })
        #expect(Array(list.vertices) == [1, 2])
        #expect(list.edges.map { [$0.u, $0.v] } == [[1, 1], [1, 2]])
    }

    @Test("Every mutable representation is a target: simple ones merge, StableDirectedGraph and the Int overloads read")
    func targets() throws {
        let text = "digraph { a -> b [w=1]; b -> c; a -> b [w=2]; c -> c }"
        var simpleWeights: [Int: AttributeValue] = [:]
        let simple = try AdjacencyList<String>(dot: text.utf8, edgeAttribute: { simpleWeights[$0] = $2 })
        #expect(simple.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "c"], ["c", "c"]])
        #expect(simpleWeights == [0: .string("2")])
        var stableWeights: [Int: AttributeValue] = [:]
        let stable = try StableDirectedGraph<String>(dot: text.utf8, edgeAttribute: { stableWeights[$0] = $2 })
        #expect(Array(stable.vertices) == ["a", "b", "c"])
        #expect(stable.edges.indices.map { [stable.source(ofEdgeAt: $0), stable.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "c"], ["a", "b"], ["c", "c"]])
        #expect(stableWeights == [0: .string("1"), 2: .string("2")])

        let undirected = try UndirectedAdjacencyList<String>(graphML: "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"undirected\"><node id=\"a\"/><node id=\"b\"/><edge source=\"b\" target=\"a\"/><edge source=\"a\" target=\"b\"/><edge source=\"a\" target=\"a\"/></graph></graphml>".utf8)
        #expect(undirected.edges.map { [$0.u, $0.v] } == [["b", "a"], ["a", "a"]])

        let ints = try AdjacencyList<Int>(adjacencyList: "3 1 1 2\n2 3\n".utf8)
        #expect(Array(ints.vertices) == [3, 1, 2])
        #expect(ints.edges.map { [$0.source, $0.target] } == [[3, 1], [3, 2], [2, 3]])
        let mm = try UndirectedAdjacencyList<Int>(matrixMarket: "%%MatrixMarket matrix coordinate pattern symmetric\n2 2 3\n2 1\n1 2\n2 2\n".utf8)
        #expect(mm.edges.map { [$0.u, $0.v] } == [[1, 0], [1, 1]])
        let json = try DirectedPseudograph<Int>(nodeLinkJSON: "{\"directed\": true, \"nodes\": [{\"id\": -5}, {\"id\": 9}], \"edges\": [{\"source\": 9, \"target\": -5}]}".utf8)
        #expect(Array(json.vertices) == [-5, 9])
        #expect(json.edges.map { [$0.source, $0.target] } == [[9, -5]])
    }

    @Test("Any byte sequence is input: String.UTF8View, [UInt8], ArraySlice, and a sequence without contiguous storage")
    func inputSequences() throws {
        let text = "graph {\n  é -- \"b c\" -- é\n}\n"
        let fromView = try Pseudograph<String>(dot: text.utf8)
        let fromArray = try Pseudograph<String>(dot: Array(text.utf8))
        let padded = Array(("xx" + text).utf8)
        let fromSlice = try Pseudograph<String>(dot: padded[2...])
        let fromLazy = try Pseudograph<String>(dot: text.utf8.lazy.map { $0 })
        let fromStride = try Pseudograph<String>(dot: AnySequence(Array(text.utf8)))
        for graph in [fromView, fromArray, fromSlice, fromLazy, fromStride] {
            #expect(Array(graph.vertices) == ["é", "b c"])
            #expect(graph.edges.map { [$0.u, $0.v] } == [["é", "b c"], ["b c", "é"]])
        }
        do {
            let graph = try Pseudograph<String>(dot: text.utf8.lazy.map { $0 == UInt8(ascii: "}") ? UInt8(ascii: ";") : $0 })
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 30])
        }
    }

    @Test("One byte-order mark is skipped in every format; positions are counted after it")
    func byteOrderMark() throws {
        let bom = "\u{FEFF}"
        #expect(try DirectedPseudograph<String>(graphML: (bom + "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"/></graph></graphml>").utf8).vertexCount == 1)
        #expect(try DirectedPseudograph<String>(nodeLinkJSON: (bom + "{\"directed\": true, \"nodes\": [{\"id\": \"a\"}], \"edges\": []}").utf8).vertexCount == 1)
        #expect(try DirectedPseudograph<Int>(matrixMarket: (bom + "%%MatrixMarket matrix coordinate pattern general\n2 2 0\n").utf8).vertexCount == 2)
        #expect(try DirectedPseudograph<String>(edgeList: (bom + "a b\n").utf8).edgeCount == 1)
        #expect(try DirectedPseudograph<String>(adjacencyList: (bom + "a b\n").utf8).edgeCount == 1)
        #expect(try DirectedPseudograph<String>(mermaid: (bom + "flowchart TD\n  A --> B\n").utf8).edgeCount == 1)
        do {
            let graph = try DirectedPseudograph<String>(dot: (bom + "digraph { -> }").utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
        // A second mark is text, not skipped.
        do {
            let graph = try DirectedPseudograph<String>(edgeList: (bom + bom + "a b\n").utf8)
            #expect(Array(graph.vertices) == [bom + "a", "b"])
        }
    }

    @Test("Positions: columns in Unicode scalars, offsets in bytes, LF ends a line, CR LF counts once, a lone CR does not")
    func positions() {
        let cases: [(String, [Int])] = [
            ("digraph {\n  é😀 -> -> }", [2, 9, 22]),
            ("digraph {\r\n  é😀 -> -> }", [2, 9, 23]),
            ("digraph {\r  é😀 -> -> }", [1, 19, 22]),
            ("digraph {\n\n\n\t\"日本\" -- b }", [4, 7, 22]),
        ]
        for (text, position) in cases {
            do {
                let graph = try DirectedPseudograph<String>(dot: text.utf8)
                Issue.record("expected syntax, read \(graph)")
            } catch {
                #expect(error.kind == .syntax, "\(text)")
                #expect([error.line, error.column, error.byteOffset] == position, "\(text)")
            }
        }
    }

    @Test("ParseError and AttributeValue are values: Equatable, Hashable, Sendable; literals give the four cases")
    func valueTypes() {
        let a: AttributeValue = "x", b: AttributeValue = 3, c: AttributeValue = 2.5, d: AttributeValue = true
        #expect(a == .string("x") && b == .integer(3) && c == .double(2.5) && d == .boolean(true))
        #expect(AttributeValue.integer(2) != .double(2) && AttributeValue.string("true") != .boolean(true))
        #expect(Set<AttributeValue>([.integer(1), .integer(1), .double(1), .string("1"), .boolean(true)]).count == 4)
        func sendable<T: Sendable>(_: T.Type) {}
        sendable(ParseError.self)
        sendable(AttributeValue.self)
        var errors: [ParseError] = []
        for text in ["digraph {", "digraph {", "graph {"] {
            do {
                _ = try DirectedPseudograph<String>(dot: text.utf8)
            } catch {
                errors.append(error)
            }
        }
        #expect(errors.count == 3 && errors[0] == errors[1] && errors[0] != errors[2])
        #expect(Set(errors).count == 2 && Set(errors.map(\.kind)) == [.unexpectedEndOfInput, .kindMismatch])
        #expect(!errors[0].description.isEmpty)
    }

    @Test("Writers call each closure once per element, in vertices then position order; GraphML twice")
    func writerClosureCalls() {
        let graph = DirectedPseudograph<String>(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "c")])
        for format in ["dot", "graphML", "nodeLinkJSON", "edgeList", "adjacencyList", "mermaid"] {
            var ids: [String] = [], vertexCalls: [String] = [], edgeCalls: [Int] = []
            var output = ""
            switch format {
            case "dot":
                graph.writeDOT(to: &output, vertexID: { ids.append($0); return $0 }, vertexAttributes: { vertexCalls.append($0); return [] },
                               edgeAttributes: { edgeCalls.append($0); return [] })
            case "graphML":
                graph.writeGraphML(to: &output, vertexAttributes: { vertexCalls.append($0); return [("k", .integer(1))] },
                                   edgeAttributes: { edgeCalls.append($0); return [] })
            case "nodeLinkJSON":
                graph.writeNodeLinkJSON(to: &output, vertexID: { ids.append($0); return .string($0) }, vertexAttributes: { vertexCalls.append($0); return [] },
                                        edgeAttributes: { edgeCalls.append($0); return [] })
            case "edgeList":
                graph.writeEdgeList(to: &output, vertexID: { ids.append($0); return $0 }, edgeAttributes: { edgeCalls.append($0); return [] })
            case "adjacencyList":
                graph.writeAdjacencyList(to: &output, vertexID: { ids.append($0); return $0 })
            default:
                graph.writeMermaid(to: &output, vertexID: { ids.append($0); return $0 }, vertexLabel: { vertexCalls.append($0); return nil },
                                   edgeLabel: { edgeCalls.append($0); return nil })
            }
            switch format {
            case "graphML":
                #expect(vertexCalls == ["c", "a", "b", "c", "a", "b"], "\(format)")
                #expect(edgeCalls == [0, 1, 2, 0, 1, 2], "\(format)")
            case "adjacencyList":
                #expect(ids == ["c", "a", "b"], "\(format)")
            case "edgeList":
                #expect(Set(ids) == ["c", "a", "b"] && ids.count == 3, "\(format): IDs once each")
                #expect(edgeCalls == [0, 1, 2], "\(format)")
            default:
                #expect(ids == ["c", "a", "b"], "\(format)")
                #expect(vertexCalls == ["c", "a", "b"], "\(format)")
                #expect(edgeCalls == [0, 1, 2], "\(format)")
            }
        }
        var output = ""
        graph.writeMatrixMarket(to: &output, weight: { (e: Int) -> Int in e * 10 })
        #expect(output == "%%MatrixMarket matrix coordinate integer general\n%\n3 3 3\n2 3 0\n3 2 10\n1 1 20\n")
    }

    @Test("Every writer but node-link JSON ends with a line feed; no writer emits a carriage return")
    func lineEnds() {
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        var outputs: [String: String] = [:]
        var text = ""
        graph.writeDOT(to: &text, vertexAttributes: { _ in [("s", .string("x\r\ny"))] }); outputs["dot"] = text; text = ""
        graph.writeGraphML(to: &text, vertexAttributes: { _ in [("s", .string("x\r\ny"))] }); outputs["graphML"] = text; text = ""
        graph.writeNodeLinkJSON(to: &text, vertexAttributes: { _ in [("s", .string("x\r\ny"))] }); outputs["nodeLinkJSON"] = text; text = ""
        graph.writeEdgeList(to: &text); outputs["edgeList"] = text; text = ""
        graph.writeAdjacencyList(to: &text); outputs["adjacencyList"] = text; text = ""
        graph.writeMermaid(to: &text, vertexLabel: { _ in "x\r\ny" }); outputs["mermaid"] = text; text = ""
        Pseudograph<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)]).writeMatrixMarket(to: &text); outputs["matrixMarket"] = text
        for (format, output) in outputs {
            #expect(output.hasSuffix("\n") == (format != "nodeLinkJSON"), "\(format)")
            // DOT keeps a carriage return inside a quoted string (scan.l reads it back); it never ends a line.
            #expect(!output.contains("\r\n") || format == "dot", "\(format)")
            #expect(!output.unicodeScalars.contains("\r") || format == "dot", "\(format)")
        }
        #expect(outputs["nodeLinkJSON"] == "{\"directed\": false, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"s\": \"x\\r\\ny\", \"id\": \"a\"}, {\"s\": \"x\\r\\ny\", \"id\": \"b\"}], \"edges\": [{\"source\": \"a\", \"target\": \"b\"}]}")
    }

    @Test("Writers accept any DirectedGraph or Graph: AdjacencyList, StableDirectedGraph with holes, UndirectedAdjacencyList")
    func writersOverOtherRepresentations() {
        var output = ""
        AdjacencyList<String>(vertices: ["x", "y"], edges: [DirectedEdge(from: "y", to: "x")]).writeDOT(to: &output)
        #expect(output == "digraph {\n\tx;\n\ty;\n\ty -> x;\n}\n")
        var stable = StableDirectedGraph<String>(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        _ = stable.remove("b")
        output = ""
        stable.writeDOT(to: &output, edgeAttributes: { [("position", .integer($0))] })
        #expect(output == "digraph {\n\ta;\n\tc;\n\tc -> a [position=2];\n}\n")
        output = ""
        stable.writeMatrixMarket(to: &output)
        #expect(output == "%%MatrixMarket matrix coordinate pattern general\n%\n2 2 1\n2 1\n")
        output = ""
        UndirectedAdjacencyList<String>(vertices: ["p", "q"], edges: [UndirectedEdge("q", "p"), UndirectedEdge("p", "p")]).writeAdjacencyList(to: &output)
        #expect(output == "p q p\nq\n")
    }
}
