// graph6, sparse6 and digraph6 (catalog GF-419 – GF-458 read, GF-564 – GF-578 write): nauty's formats
// on vertices 0..<n, with and without headers; ref.py checks the graph6 and sparse6 write rows byte
// for byte against NetworkX, except where nauty's padding rule differs.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats graph6, sparse6, digraph6")
struct GraphFormatsNautyTests {
    @Test("GF-419 graph6: five vertices, edges 0-1, 1-2, 3-4")
    func gf419() throws {
        // Pseudograph<Int>(graph6:) → U: 0, 1, 2, 3, 4; 0-1, 1-2, 3-4
        let input = "DgC\n"
        let graph = try Pseudograph<Int>(graph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [3, 4]])
    }

    @Test("GF-420 graph6: no vertices")
    func gf420() throws {
        // Pseudograph<Int>(graph6:) → U:
        let input = "?\n"
        let graph = try Pseudograph<Int>(graph6: input.utf8)
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
    }

    @Test("GF-421 graph6: one vertex, no data")
    func gf421() throws {
        // Pseudograph<Int>(graph6:) → U: 0
        let input = "@\n"
        let graph = try Pseudograph<Int>(graph6: input.utf8)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
    }

    @Test("GF-422 graph6: the header, no final newline")
    func gf422() throws {
        // Pseudograph<Int>(graph6:) → U: 0, 1, 2; 0-1, 0-2, 1-2
        let input = ">>graph6<<Bw"
        let graph = try Pseudograph<Int>(graph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]])
    }

    @Test("GF-423 graph6: CR LF")
    func gf423() throws {
        // Pseudograph<Int>(graph6:) → U: 0, 1, 2, 3; 0-1, 0-2, 1-2, 0-3, 1-3, 2-3
        let input = "C~\r\n"
        let graph = try Pseudograph<Int>(graph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [0, 3], [1, 3], [2, 3]])
    }

    @Test("GF-424 graph6 into a simple target")
    func gf424() throws {
        // UndirectedAdjacencyList<Int>(graph6:) → U: 0, 1, 2, 3; 0-1, 1-2, 2-3
        let input = "Ch\n"
        let graph = try UndirectedAdjacencyList<Int>(graph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [2, 3]])
    }

    @Test("GF-425 graph6: 63 vertices take the four-byte size")
    func gf425() {
        // Pseudograph<Int>(graph6:) → **syntax** at 1:331
        let input = "~??~??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????@\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 331, 330])
        }
    }

    @Test("GF-426 graph6: empty input")
    func gf426() {
        // Pseudograph<Int>(graph6:) → **unexpectedEndOfInput** at 1:1
        let input = ""
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-427 graph6: a size byte below 63")
    func gf427() {
        // Pseudograph<Int>(graph6:) → **syntax** at 1:1
        let input = "!\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-428 graph6: a data byte above 126")
    func gf428() {
        // Pseudograph<Int>(graph6:) → **syntax** at 1:2
        let input = "C\u{7F}\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 2, 1])
        }
    }

    @Test("GF-429 graph6: too few data bytes")
    func gf429() {
        // Pseudograph<Int>(graph6:) → **unexpectedEndOfInput** at 1:3
        let input = "D?\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-430 graph6: too many data bytes")
    func gf430() {
        // Pseudograph<Int>(graph6:) → **syntax** at 1:3
        let input = "Bw?\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-431 graph6: padding bits that are not 0")
    func gf431() {
        // Pseudograph<Int>(graph6:) → **invalidValue** at 1:2
        let input = "Bx\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 2, 1])
        }
    }

    @Test("GF-432 graph6: text after the line feed")
    func gf432() {
        // Pseudograph<Int>(graph6:) → **syntax** at 2:1
        let input = "Bw\nBw\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 3])
        }
    }

    @Test("GF-433 graph6: a four-byte size cut short")
    func gf433() {
        // Pseudograph<Int>(graph6:) → **unexpectedEndOfInput** at 1:3
        let input = "~?\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-434 graph6: a sparse6 line")
    func gf434() {
        // Pseudograph<Int>(graph6:) → **syntax** at 1:1
        let input = ":Bw\n"
        do {
            let graph = try Pseudograph<Int>(graph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-435 graph6: invalid UTF-8")
    func gf435() {
        // Pseudograph<Int>(graph6:) → **invalidUTF8** at 1:2
        let input: [UInt8] = [0x42, 0xC3, 0x0A]
        do {
            let graph = try Pseudograph<Int>(graph6: input)
            Issue.record("expected invalidUTF8, read \(graph)")
        } catch {
            #expect(error.kind == .invalidUTF8)
            #expect([error.line, error.column, error.byteOffset] == [1, 2, 1])
        }
    }

    @Test("GF-436 digraph6: arcs and a loop, row by row")
    func gf436() throws {
        // DirectedPseudograph<Int>(digraph6:) → D: 0, 1, 2; 0>1, 1>1, 2>0
        let input = "&BQ_\n"
        let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 1], [2, 0]])
    }

    @Test("GF-437 digraph6: the header")
    func gf437() throws {
        // DirectedPseudograph<Int>(digraph6:) → D: 0, 1, 2, 3; 0>3, 1>2, 3>0
        let input = ">>digraph6<<&CC__\n"
        let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 3], [1, 2], [3, 0]])
    }

    @Test("GF-438 digraph6: no vertices")
    func gf438() throws {
        // DirectedPseudograph<Int>(digraph6:) → D:
        let input = "&?\n"
        let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
    }

    @Test("GF-439 digraph6 into a simple target")
    func gf439() throws {
        // AdjacencyList<Int>(digraph6:) → D: 0, 1; 0>1, 1>0
        let input = "&AW\n"
        let graph = try AdjacencyList<Int>(digraph6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 0]])
    }

    @Test("GF-440 digraph6: no &")
    func gf440() {
        // DirectedPseudograph<Int>(digraph6:) → **syntax** at 1:1
        let input = "BQ_\n"
        do {
            let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-441 digraph6: empty input")
    func gf441() {
        // DirectedPseudograph<Int>(digraph6:) → **unexpectedEndOfInput** at 1:1
        let input = ""
        do {
            let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-442 digraph6: too few data bytes")
    func gf442() {
        // DirectedPseudograph<Int>(digraph6:) → **unexpectedEndOfInput** at 1:3
        let input = "&C\n"
        do {
            let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-443 digraph6: padding bits that are not 0")
    func gf443() {
        // DirectedPseudograph<Int>(digraph6:) → **invalidValue** at 1:3
        let input = "&AX\n"
        do {
            let graph = try DirectedPseudograph<Int>(digraph6: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-444 sparse6: nauty's example, seven vertices")
    func gf444() throws {
        // Pseudograph<Int>(sparse6:) → U: 0, 1, 2, 3, 4, 5, 6; 0-1, 0-2, 1-2, 5-6
        let input = ":Fa@x^\n"
        let graph = try Pseudograph<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [5, 6]])
    }

    @Test("GF-445 sparse6: loops and parallel edges")
    func gf445() throws {
        // Pseudograph<Int>(sparse6:) → U: 0, 1, 2; 0-1, 0-1, 1-1, 2-2
        let input = ":B_M\n"
        let graph = try Pseudograph<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 1], [2, 2]])
    }

    @Test("GF-446 sparse6 into a simple target: parallel edges merge")
    func gf446() throws {
        // UndirectedAdjacencyList<Int>(sparse6:) → U: 0, 1, 2; 0-1, 1-1, 2-2
        let input = ":B_M\n"
        let graph = try UndirectedAdjacencyList<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 1], [2, 2]])
    }

    @Test("GF-447 sparse6: the header, a jump over vertices")
    func gf447() throws {
        // Pseudograph<Int>(sparse6:) → U: 0, 1, 2, 3, 4, 5, 6, 7; 1-6, 2-7, 2-7
        let input = ">>sparse6<<:GwYJ\n"
        let graph = try Pseudograph<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 6], [2, 7], [2, 7]])
    }

    @Test("GF-448 sparse6: one vertex with a loop (k = 0)")
    func gf448() throws {
        // Pseudograph<Int>(sparse6:) → U: 0; 0-0
        let input = ":@^\n"
        let graph = try Pseudograph<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 0]])
    }

    @Test("GF-449 sparse6: no vertices")
    func gf449() throws {
        // Pseudograph<Int>(sparse6:) → U:
        let input = ":?\n"
        let graph = try Pseudograph<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
    }

    @Test("GF-450 sparse6: the padding special case (n = 4, last edge at vertex 2)")
    func gf450() throws {
        // Pseudograph<Int>(sparse6:) → U: 0, 1, 2, 3; 0-1, 1-1, 0-2
        let input = ":C`b\n"
        let graph = try Pseudograph<Int>(sparse6: input.utf8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 1], [0, 2]])
    }

    @Test("GF-451 sparse6: incremental sparse6 (unsupported)")
    func gf451() {
        // Pseudograph<Int>(sparse6:) → **unsupported** at 1:1
        let input = ";Bc\n"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-452 sparse6: no colon")
    func gf452() {
        // Pseudograph<Int>(sparse6:) → **syntax** at 1:1
        let input = "Bc\n"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-453 sparse6: empty input")
    func gf453() {
        // Pseudograph<Int>(sparse6:) → **unexpectedEndOfInput** at 1:1
        let input = ""
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-454 sparse6: a data byte below 63")
    func gf454() {
        // Pseudograph<Int>(sparse6:) → **syntax** at 1:4
        let input = ":Bc \n"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 4, 3])
        }
    }

    @Test("GF-455 sparse6: a size above the default maximumVertexCount")
    func gf455() {
        // Pseudograph<Int>(sparse6:) → **limitExceeded** at 1:2
        let input = ":~~??F???\n"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 2, 1])
        }
    }

    @Test("GF-456 sparse6: a size above maximumVertexCount")
    func gf456() {
        // Pseudograph<Int>(sparse6:, maximumVertexCount: 3) → **limitExceeded** at 1:2
        let input = ":C\n"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8, maximumVertexCount: 3)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 2, 1])
        }
    }

    @Test("GF-457 sparse6: a size cut short")
    func gf457() {
        // Pseudograph<Int>(sparse6:) → **unexpectedEndOfInput** at 1:6
        let input = ":~~??\n"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 6, 5])
        }
    }

    @Test("GF-458 sparse6: text after the line feed")
    func gf458() {
        // Pseudograph<Int>(sparse6:) → **syntax** at 2:1
        let input = ":?\nx"
        do {
            let graph = try Pseudograph<Int>(sparse6: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 3])
        }
    }

    @Test("GF-564 graph6: a path and an edge")
    func gf564() throws {
        // writeGraph6(to:) on U: 0, 1, 2, 3, 4; 0-1, 1-2, 3-4
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 4)])
        var output = ""
        try graph.writeGraph6(to: &output)
        #expect(output == "DgC\n")
    }

    @Test("GF-565 graph6: with the header")
    func gf565() throws {
        // writeGraph6(to:, header: true) on U: 0, 1, 2, 3, 4; 0-1, 1-2, 3-4
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 4)])
        var output = ""
        try graph.writeGraph6(to: &output, header: true)
        #expect(output == ">>graph6<<DgC\n")
    }

    @Test("GF-566 graph6: no vertices")
    func gf566() throws {
        // writeGraph6(to:) on U:
        let graph = Pseudograph<String>()
        var output = ""
        try graph.writeGraph6(to: &output)
        #expect(output == "?\n")
    }

    @Test("GF-567 graph6: K4, edges in any orientation")
    func gf567() throws {
        // writeGraph6(to:) on U: 0, 1, 2, 3; 1-0, 0-2, 3-0, 1-2, 3-1, 2-3
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 2), UndirectedEdge(3, 0), UndirectedEdge(1, 2), UndirectedEdge(3, 1), UndirectedEdge(2, 3)])
        var output = ""
        try graph.writeGraph6(to: &output)
        #expect(output == "C~\n")
    }

    @Test("GF-568 graph6: 63 vertices take the four-byte size")
    func gf568() throws {
        // writeGraph6(to:) on U: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62; 61-62
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62], edges: [UndirectedEdge(61, 62)])
        var output = ""
        try graph.writeGraph6(to: &output)
        #expect(output == "~??~?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????G\n")
    }

    @Test("GF-569 digraph6: arcs and a loop")
    func gf569() throws {
        // writeDigraph6(to:) on D: 0, 1, 2; 0>1, 1>1, 2>0
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 0)])
        var output = ""
        try graph.writeDigraph6(to: &output)
        #expect(output == "&BQ_\n")
    }

    @Test("GF-570 digraph6: with the header")
    func gf570() throws {
        // writeDigraph6(to:, header: true) on D: 0, 1, 2, 3; 0>3, 3>0
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 0)])
        var output = ""
        try graph.writeDigraph6(to: &output, header: true)
        #expect(output == ">>digraph6<<&CC?_\n")
    }

    @Test("GF-571 digraph6: no vertices")
    func gf571() throws {
        // writeDigraph6(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeDigraph6(to: &output)
        #expect(output == "&?\n")
    }

    @Test("GF-572 sparse6: nauty's example")
    func gf572() {
        // writeSparse6(to:) on U: 0, 1, 2, 3, 4, 5, 6; 0-1, 0-2, 1-2, 5-6
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(5, 6)])
        var output = ""
        graph.writeSparse6(to: &output)
        #expect(output == ":Fa@x^\n")
    }

    @Test("GF-573 sparse6: loops and parallel edges")
    func gf573() {
        // writeSparse6(to:) on U: 0, 1, 2; 0-1, 1-0, 1-1, 2-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 1), UndirectedEdge(2, 2)])
        var output = ""
        graph.writeSparse6(to: &output)
        #expect(output == ":B_M\n")
    }

    @Test("GF-574 sparse6: with the header, a jump over vertices")
    func gf574() {
        // writeSparse6(to:, header: true) on U: 0, 1, 2, 3, 4, 5, 6, 7; 6-1, 7-2, 7-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7], edges: [UndirectedEdge(6, 1), UndirectedEdge(7, 2), UndirectedEdge(7, 2)])
        var output = ""
        graph.writeSparse6(to: &output, header: true)
        #expect(output == ">>sparse6<<:GwYJ\n")
    }

    @Test("GF-575 sparse6: the padding special case")
    func gf575() {
        // writeSparse6(to:) on U: 0, 1, 2, 3; 0-1, 1-1, 0-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(0, 2)])
        var output = ""
        graph.writeSparse6(to: &output)
        #expect(output == ":C`b\n")
    }

    @Test("GF-576 sparse6: a loop at vertex 0 of four (nauty's padding)")
    func gf576() {
        // writeSparse6(to:) on U: 0, 1, 2, 3; 0-0
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 0)])
        var output = ""
        graph.writeSparse6(to: &output)
        #expect(output == ":CF\n")
    }

    @Test("GF-577 sparse6: one vertex with a loop (k = 0)")
    func gf577() {
        // writeSparse6(to:) on U: 0; 0-0
        let graph = Pseudograph<Int>(vertices: [0], edges: [UndirectedEdge(0, 0)])
        var output = ""
        graph.writeSparse6(to: &output)
        #expect(output == ":@^\n")
    }

    @Test("GF-578 sparse6: no vertices")
    func gf578() {
        // writeSparse6(to:) on U:
        let graph = Pseudograph<String>()
        var output = ""
        graph.writeSparse6(to: &output)
        #expect(output == ":?\n")
    }
}
