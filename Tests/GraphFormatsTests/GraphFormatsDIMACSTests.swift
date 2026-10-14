// DIMACS (catalog GF-459 – GF-488 read, GF-579 – GF-581 write): shortest-path files (p sp, weighted
// arcs) and clique and colouring files (p edge, p col) on vertices 0..<n, the declared edge count
// checked.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats DIMACS")
struct GraphFormatsDIMACSTests {
    @Test("GF-459 shortest path (.gr): comments, the problem line, weighted arcs")
    func gf459() throws {
        // DirectedPseudograph<Int>(dimacs:) → D: 0, 1, 2; 0>1{weight=7}, 1>2{weight=-1}, 2>0{weight=0}
        let input = "c 9th DIMACS challenge\np sp 3 3\nc arcs\na 1 2 7\na 2 3 -1\na 3 1 0\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(dimacs: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 2], [2, 0]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(7)], 1: ["weight": .integer(-1)], 2: ["weight": .integer(0)]])
    }

    @Test("GF-460 clique (p edge): edges, isolated vertices")
    func gf460() throws {
        // Pseudograph<Int>(dimacs:) → U: 0, 1, 2, 3; 0-1, 3-1
        let input = "c\np edge 4 2\ne 1 2\ne 4 2\n"
        let graph = try Pseudograph<Int>(dimacs: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [3, 1]])
    }

    @Test("GF-461 colouring (p col), tabs, CR LF, blank lines")
    func gf461() throws {
        // Pseudograph<Int>(dimacs:) → U: 0, 1; 0-1
        let input = "p col 2 1\r\n\r\ne\t1\t2\r\n"
        let graph = try Pseudograph<Int>(dimacs: input.utf8)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
    }

    @Test("GF-462 simple target: a repeated arc merges, last weight wins")
    func gf462() throws {
        // AdjacencyList<Int>(dimacs:) → D: 0, 1; 0>1{weight=5}
        let input = "p sp 2 2\na 1 2 1\na 1 2 5\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try AdjacencyList<Int>(dimacs: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(edgeKeys == [0: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(5)]])
    }

    @Test("GF-463 parallel arcs and loops kept")
    func gf463() throws {
        // DirectedPseudograph<Int>(dimacs:) → D: 0, 1; 0>1{weight=1}, 0>1{weight=2}, 1>1{weight=3}
        let input = "p sp 2 3\na 1 2 1\na 1 2 2\na 2 2 3\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(dimacs: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [0, 1], [1, 1]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(1)], 1: ["weight": .integer(2)], 2: ["weight": .integer(3)]])
    }

    @Test("GF-464 no edges")
    func gf464() throws {
        // Pseudograph<Int>(dimacs:) → U: 0, 1, 2
        let input = "p edge 3 0\n"
        let graph = try Pseudograph<Int>(dimacs: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
    }

    @Test("GF-465 no problem line")
    func gf465() {
        // DirectedPseudograph<Int>(dimacs:) → **unexpectedEndOfInput** at 2:1
        let input = "c only\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 7])
        }
    }

    @Test("GF-466 an arc before the problem line")
    func gf466() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 1:1
        let input = "a 1 2 3\np sp 2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-467 a second problem line")
    func gf467() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 2:1
        let input = "p sp 1 0\np sp 1 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 9])
        }
    }

    @Test("GF-468 a flow problem (unsupported)")
    func gf468() {
        // DirectedPseudograph<Int>(dimacs:) → **unsupported** at 1:3
        let input = "p max 2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-469 an unknown problem")
    func gf469() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 1:3
        let input = "p foo 2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-470 p sp into an undirected target")
    func gf470() {
        // Pseudograph<Int>(dimacs:) → **kindMismatch** at 1:3
        let input = "p sp 2 0\n"
        do {
            let graph = try Pseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-471 p edge into a directed target")
    func gf471() {
        // DirectedPseudograph<Int>(dimacs:) → **kindMismatch** at 1:3
        let input = "p edge 2 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-472 a problem line of three fields")
    func gf472() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 1:7
        let input = "p sp 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 7, 6])
        }
    }

    @Test("GF-473 a problem line of five fields")
    func gf473() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 1:10
        let input = "p sp 2 0 x\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 10, 9])
        }
    }

    @Test("GF-474 a vertex count that is not a number")
    func gf474() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 1:6
        let input = "p sp x 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 6, 5])
        }
    }

    @Test("GF-475 a vertex count above the default maximumVertexCount")
    func gf475() {
        // DirectedPseudograph<Int>(dimacs:) → **limitExceeded** at 1:6
        let input = "p sp 16777216 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 6, 5])
        }
    }

    @Test("GF-476 a vertex count above maximumVertexCount")
    func gf476() {
        // DirectedPseudograph<Int>(dimacs:, maximumVertexCount: 2) → **limitExceeded** at 1:6
        let input = "p sp 3 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8, maximumVertexCount: 2)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 6, 5])
        }
    }

    @Test("GF-477 an index 0")
    func gf477() {
        // DirectedPseudograph<Int>(dimacs:) → **indexOutOfRange** at 2:3
        let input = "p sp 2 1\na 0 1 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 11])
        }
    }

    @Test("GF-478 an index beyond n")
    func gf478() {
        // DirectedPseudograph<Int>(dimacs:) → **indexOutOfRange** at 2:5
        let input = "p sp 2 1\na 1 3 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 5, 13])
        }
    }

    @Test("GF-479 a signed index")
    func gf479() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 2:3
        let input = "p sp 2 1\na +1 2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 11])
        }
    }

    @Test("GF-480 a weight that is not an integer")
    func gf480() {
        // DirectedPseudograph<Int>(dimacs:) → **invalidValue** at 2:7
        let input = "p sp 2 1\na 1 2 1.5\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [2, 7, 15])
        }
    }

    @Test("GF-481 a weight beyond Int64")
    func gf481() {
        // DirectedPseudograph<Int>(dimacs:) → **numberOutOfRange** at 2:7
        let input = "p sp 2 1\na 1 2 9223372036854775808\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 7, 15])
        }
    }

    @Test("GF-482 a missing weight")
    func gf482() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 2:6
        let input = "p sp 2 1\na 1 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 6, 14])
        }
    }

    @Test("GF-483 an extra field on an edge")
    func gf483() {
        // Pseudograph<Int>(dimacs:) → **syntax** at 2:7
        let input = "p edge 2 1\ne 1 2 3\n"
        do {
            let graph = try Pseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 7, 17])
        }
    }

    @Test("GF-484 more arcs than declared")
    func gf484() {
        // DirectedPseudograph<Int>(dimacs:) → **entryCountMismatch** at 3:1
        let input = "p sp 2 1\na 1 2 1\na 2 1 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected entryCountMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .entryCountMismatch)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 17])
        }
    }

    @Test("GF-485 fewer arcs than declared")
    func gf485() {
        // DirectedPseudograph<Int>(dimacs:) → **entryCountMismatch** at 3:1
        let input = "p sp 2 2\na 1 2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected entryCountMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .entryCountMismatch)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 17])
        }
    }

    @Test("GF-486 an e line in a shortest-path file")
    func gf486() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 2:1
        let input = "p sp 2 1\ne 1 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 9])
        }
    }

    @Test("GF-487 a node descriptor line (unsupported)")
    func gf487() {
        // Pseudograph<Int>(dimacs:) → **unsupported** at 2:1
        let input = "p edge 2 0\nn 1 5\n"
        do {
            let graph = try Pseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 11])
        }
    }

    @Test("GF-488 an unknown line")
    func gf488() {
        // DirectedPseudograph<Int>(dimacs:) → **syntax** at 2:1
        let input = "p sp 2 0\nx 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(dimacs: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 9])
        }
    }

    @Test("GF-579 shortest path: p sp and weighted arcs in position order")
    func gf579() {
        // writeDIMACS(to:, weight: [7, -2, 0]) on D: 0, 1, 2; 0>1, 2>0, 1>1
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 1)])
        let weights: [Int] = [7, -2, 0]
        var output = ""
        graph.writeDIMACS(to: &output, weight: { weights[$0] })
        #expect(output == "p sp 3 3\na 1 2 7\na 3 1 -2\na 2 2 0\n")
    }

    @Test("GF-580 clique: p edge and edges as stored")
    func gf580() {
        // writeDIMACS(to:) on U: 0, 1, 2, 3; 1-0, 2-3
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(1, 0), UndirectedEdge(2, 3)])
        var output = ""
        graph.writeDIMACS(to: &output)
        #expect(output == "p edge 4 2\ne 2 1\ne 3 4\n")
    }

    @Test("GF-581 empty digraph")
    func gf581() {
        // writeDIMACS(to:, weight: []) on D:
        let graph = DirectedPseudograph<String>()
        let weights: [Int] = []
        var output = ""
        graph.writeDIMACS(to: &output, weight: { weights[$0] })
        #expect(output == "p sp 0 0\n")
    }
}
