// Cases of the newer readers the catalog rows do not reach: indices mapped to one vertex, size
// boundaries, the order of mirror errors, references that overflow, quoting details, NetworkX keys,
// a vertex mapping that differs per call, delimiters with CR LF and Int columns, subgraph members and
// the budget of a hop between groups. Each pins one behavior api.md states.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats edge cases of the newer readers")
struct GraphFormatsEdgeCaseTests {
    @Test("Indices mapped to one vertex are one vertex (DIMACS, METIS, graph6)")
    func indicesMappedToOneVertex() throws {
        let directed = try DirectedPseudograph<Int>(dimacs: "p sp 3 1\na 1 3 5\n".utf8, vertex: { $0 % 2 })
        #expect(Array(directed.vertices) == [0, 1])
        #expect(directed.edges.map { [$0.source, $0.target] } == [[0, 0]])
        let metis = try Pseudograph<String>(metis: "3 1\n3\n\n1\n".utf8, vertex: { $0 == 2 ? "a" : "\($0 % 2)" })
        #expect(Array(metis.vertices) == ["0", "1", "a"])
        let graph6 = try Pseudograph<Int>(graph6: "A_\n".utf8, vertex: { _ in 7 })
        #expect(Array(graph6.vertices) == [7] && graph6.edgeCount == 1)
    }

    @Test("N(n) takes eight bytes from 258,048 vertices on, and four up to 258,047")
    func nautySizeBoundary() throws {
        var output = ""
        Pseudograph<Int>(vertices: 0 ..< 258_048).writeSparse6(to: &output)
        #expect(output.hasPrefix(":~~??") && output.utf8.count == 1 + 8 + 1)
        #expect(try Pseudograph<Int>(sparse6: output.utf8, maximumVertexCount: 300_000).vertexCount == 258_048)
        output = ""
        Pseudograph<Int>(vertices: 0 ..< 258_047).writeSparse6(to: &output)
        #expect(output.hasPrefix(":~") && output.utf8.count == 1 + 4 + 1)
        #expect(try Pseudograph<Int>(sparse6: output.utf8, maximumVertexCount: 300_000).vertexCount == 258_047)
    }

    @Test("METIS: of two entries without a mirror, the first in the file is reported")
    func metisFirstUnmirrored() {
        do {
            let graph = try Pseudograph<Int>(metis: "3 2\n2 3\n\n\n".utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue && [error.line, error.column] == [2, 1])
        }
    }

    @Test("GML: an id declared twice is duplicateVertex even under another label")
    func gmlRepeatedID() {
        let input = "graph [ directed 1 node [ id 1 label \"a\" ] node [ id 1 label \"b\" ] ]"
        do {
            let graph = try DirectedPseudograph<String>(gml: input.utf8)
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            // At the second node's id value.
            let bytes = Array(input.utf8), id = Array("id 1".utf8)
            let second = (0 ... bytes.count - id.count).last { Array(bytes[$0 ..< $0 + id.count]) == id }! + 3
            #expect(error.kind == .duplicateVertex && error.byteOffset == second)
        }
    }

    @Test("GML: a character reference past U+10FFFF, however long, is kept as written")
    func gmlHugeReference() throws {
        let graph = try Pseudograph<String>(gml: "graph [ node [ id 0 label \"&#4294967361;&#x100000041;\" ] ]".utf8)
        #expect(Array(graph.vertices) == ["&#4294967361;&#x100000041;"])
    }

    @Test("Pajek: inside double quotes a backslash before another character is kept")
    func pajekBackslash() throws {
        let graph = try Pseudograph<String>(pajek: "*vertices 2\n1 \"a\\b\"\n2 'c\\d'\n".utf8)
        #expect(Array(graph.vertices) == ["a\\b", "c\\d"])
    }

    @Test("Cytoscape JSON: an edge's key is an attribute unless the document is a multigraph")
    func cytoscapeKey() throws {
        for multigraph in [false, true] {
            var keys: [String] = []
            _ = try Pseudograph<String>(cytoscapeJSON: """
                {"multigraph": \(multigraph), "elements": {"nodes": [{"data": {"id": "a"}}], "edges": [{"data": {"source": "a", "target": "a", "key": 0, "w": 1}}]}}
                """.utf8, edgeAttribute: { _, key, _ in keys.append(key) })
            #expect(keys == (multigraph ? ["w"] : ["key", "w"]))
        }
    }

    @Test("Cytoscape JSON: an id declared twice is duplicateVertex even when the mapping gives two vertices")
    func cytoscapeRepeatedID() {
        var calls = 0
        let input = "{\"directed\": true, \"elements\": {\"nodes\": [{\"data\": {\"id\": \"a\"}}, {\"data\": {\"id\": \"a\"}}]}}"
        do {
            let graph = try DirectedPseudograph<String>(cytoscapeJSON: input.utf8, vertex: { calls += 1; return "\($0)\(calls)" })
            Issue.record("expected duplicateVertex, read \(graph)")
        } catch {
            // At the second node's id value.
            let bytes = Array(input.utf8), id = Array("\"a\"".utf8)
            let second = (0 ... bytes.count - id.count).last { Array(bytes[$0 ..< $0 + id.count]) == id }!
            #expect(error.kind == .duplicateVertex && error.byteOffset == second)
        }
    }

    @Test("Edge list: dict data into an Int target; CR LF and integer columns with a delimiter")
    func edgeListDictAndDelimiter() throws {
        var values: [Int: [String: AttributeValue]] = [:]
        _ = try Pseudograph<Int>(edgeList: "1 2 {'w': 3}\n".utf8, edgeAttribute: { values[$0, default: [:]][$1] = $2 })
        #expect(values == [0: ["w": .integer(3)]])
        values = [:]
        _ = try DirectedPseudograph<String>(edgeList: "a,b,x\r\n".utf8, columns: ["c"], delimiter: ",", edgeAttribute: { values[$0, default: [:]][$1] = $2 })
        #expect(values == [0: ["c": .string("x")]])
        values = [:]
        _ = try DirectedPseudograph<Int>(edgeList: "1;2;3\n".utf8, columns: ["c"], delimiter: ";", edgeAttribute: { values[$0, default: [:]][$1] = $2 })
        #expect(values == [0: ["c": .integer(3)]])
    }

    @Test("Dict data after Unicode whitespace, which the integer fast path leaves to the general scanner")
    func dictAfterUnicodeSpace() throws {
        var values: [Int: AttributeValue] = [:]
        _ = try Pseudograph<Int>(edgeList: "1 2\u{3000}{'w': 1}\n".utf8, edgeAttribute: { values[$0] = $2 })
        #expect(values == [0: .integer(1)])
    }

    @Test("Python dict data: \\U past U+10FFFF is invalidValue at its backslash")
    func dictScalarPastRange() {
        do {
            let graph = try DirectedPseudograph<String>(edgeList: "a b {'k': '\\U00110000'}\n".utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue && error.byteOffset == 11)
        }
    }

    @Test("DOT: a nested subgraph's vertices belong to the operand around it; a port on a subgraph is syntax")
    func dotSubgraphMembers() throws {
        let graph = try DirectedPseudograph<String>(dot: "digraph { a -> { { b } c } }".utf8)
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"], ["a", "c"]])
        for input in ["digraph { { a }:p -> b }", "digraph { a -> { b }:p }"] {
            do {
                let graph = try DirectedPseudograph<String>(dot: input.utf8)
                Issue.record("expected syntax, read \(graph)")
            } catch {
                #expect(error.kind == .syntax && error.byteOffset == Array(input.utf8).firstIndex(of: UInt8(ascii: ":"))!, "\(input)")
            }
        }
    }

    @Test("DOT: each edge of a hop between groups is spent from the budget")
    func dotGroupBudget() {
        let group = (0 ..< 200).map { "a\($0)" }.joined(separator: " ")
        let input = "digraph { { \(group) } -> { \(group.replacingOccurrences(of: "a", with: "b")) } }"
        do {
            let graph = try DirectedPseudograph<String>(dot: input.utf8)
            Issue.record("expected limitExceeded, read \(graph.edgeCount) edges")
        } catch {
            #expect(error.kind == .limitExceeded && error.byteOffset == 10)
        }
    }
}
