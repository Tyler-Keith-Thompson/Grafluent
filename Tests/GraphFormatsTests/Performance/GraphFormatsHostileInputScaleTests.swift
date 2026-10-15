// Hostile input at scale (GraphFormatsHostileInputTests.swift has the rest): deep nesting, huge
// numbers, DOCTYPE and entity expansion, every prefix of a valid file, and seeded random mutations
// of valid files. Every reader must throw a ParseError (never trap, never hang, never allocate from
// a count in the file) and finish well inside a second per megabyte even in a debug build; each test
// bounds its own time and has a one-minute limit. Positions are pinned where api.md fixes them (the
// values come from ref.py); elsewhere every error's line and column must agree with its byte
// offset. See README.md.

import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats hostile input at scale")
struct GraphFormatsHostileInputScaleTests {
    @Test("Nesting 100 000 deep stops at depth 64 (XML elements, JSON arrays and objects) or at the first bracket", .timeLimit(.minutes(1)))
    func deepNesting() {
        let clock = ContinuousClock()
        let start = clock.now
        let graphML = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\"><node id=\"a\"><desc>"
            + String(repeating: "<x>", count: 100_000)
        do {
            let graph = try DirectedPseudograph<String>(graphML: graphML.utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            // The 65th element: graphml, graph, node, desc, then the 61st <x>.
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 285, 284])
        }
        let arrays = "{\"directed\": true, \"nodes\": [{\"id\": \"a\", \"x\": " + String(repeating: "[", count: 100_000)
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: arrays.utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 108, 107])
        }
        let objects = "{\"directed\": true, \"graph\": " + String(repeating: "{\"a\": ", count: 100_000)
        do {
            let graph = try DirectedPseudograph<String>(nodeLinkJSON: objects.utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 407, 406])
        }
        // DOT: a brace is a subgraph; the 65th nested one is too deep. An HTML string never closes.
        do {
            let graph = try DirectedPseudograph<String>(dot: ("digraph { " + String(repeating: "{ ", count: 100_000)).utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 139, 138])
        }
        do {
            let graph = try DirectedPseudograph<String>(dot: ("digraph { a -> " + String(repeating: "subgraph { ", count: 100_000)).utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            // The 65th `{`: after "digraph { a -> " (15 bytes), 64 times "subgraph { " (11 bytes), then "subgraph ".
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 729, 728])
        }
        // GML: the graph's list is depth 1; the 64th list inside it is the 65th.
        do {
            let graph = try DirectedPseudograph<String>(gml: ("graph [ " + String(repeating: "a [ ", count: 100_000)).utf8)
            Issue.record("expected nestingTooDeep, read \(graph)")
        } catch {
            #expect(error.kind == .nestingTooDeep)
            #expect([error.line, error.column, error.byteOffset] == [1, 263, 262])
        }
        do {
            let graph = try DirectedPseudograph<String>(dot: ("digraph { a [label=<" + String(repeating: "<", count: 100_000) + "> }").utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 20, 19])
        }
        do {
            let graph = try DirectedPseudograph<String>(mermaid: ("flowchart TD\n  A" + String(repeating: "((", count: 50_000) + "\n").utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 100_004, 100_016])
        }
        #expect(clock.now - start < .seconds(20))
    }

    @Test("Huge numbers are numberOutOfRange at their first character; nothing is allocated from a count", .timeLimit(.minutes(1)))
    func hugeNumbers() throws {
        let clock = ContinuousClock()
        let start = clock.now
        let json: [(String, [Int])] = [
            ("{\"directed\": true, \"graph\": {\"x\": " + String(repeating: "9", count: 100_000) + "}, \"nodes\": [], \"edges\": []}", [1, 35, 34]),
            ("{\"directed\": true, \"graph\": {\"x\": 1" + String(repeating: "0", count: 400) + ".5}, \"nodes\": [], \"edges\": []}", [1, 35, 34]),
            ("{\"directed\": true, \"graph\": {\"x\": 1e999999999999999999999}, \"nodes\": [], \"edges\": []}", [1, 35, 34]),
            ("{\"directed\": true, \"graph\": {\"x\": -9223372036854775809}, \"nodes\": [], \"edges\": []}", [1, 35, 34]),
        ]
        for (input, position) in json {
            do {
                let graph = try DirectedPseudograph<String>(nodeLinkJSON: input.utf8)
                Issue.record("expected numberOutOfRange, read \(graph)")
            } catch {
                #expect(error.kind == .numberOutOfRange, "\(input.prefix(60))")
                #expect([error.line, error.column, error.byteOffset] == position, "\(input.prefix(60))")
            }
        }
        // Underflow is not an error: the nearest double, 0.
        var graphValues: [String: AttributeValue] = [:]
        // Int.min itself is in range, at either `Int` width.
        _ = try DirectedPseudograph<String>(nodeLinkJSON: "{\"directed\": true, \"graph\": {\"x\": 1e-999999999999999999999, \"y\": \(Int.min)}, \"nodes\": [], \"edges\": []}".utf8,
                                            graphAttribute: { graphValues[$0] = $1 })
        #expect(graphValues == ["x": .double(0), "y": .integer(Int.min)])

        let graphML = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\" for=\"node\" attr.type=\"long\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">"
            + String(repeating: "9", count: 100_000) + "</data></node></graph></graphml>"
        do {
            let graph = try DirectedPseudograph<String>(graphML: graphML.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 140, 139])
        }
        do {
            let graph = try DirectedPseudograph<String>(graphML: "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"k\" for=\"node\" attr.type=\"double\"/><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"k\">1e400</data></node></graph></graphml>".utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [1, 142, 141])
        }

        var matrixMarket: [(String, ParseError.Kind, [Int])] = [
            ("%%MatrixMarket matrix coordinate pattern general\n99999999999999999999 99999999999999999999 1\n", .numberOutOfRange, [2, 1, 49]),
            ("%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1 99999999999999999999\n", .numberOutOfRange, [3, 3, 57]),
            ("%%MatrixMarket matrix coordinate real general\n2 2 1\n1 2 1e999\n", .numberOutOfRange, [3, 5, 56]),
        ]
        // 10¹⁸ entries claimed by a 73-byte file (10⁹ where `Int` is 32 bits): no reservation from
        // the count, just the mismatch.
        #if _pointerBitWidth(_64)
        matrixMarket.append(("%%MatrixMarket matrix coordinate pattern general\n1 1 1000000000000000000\n", .entryCountMismatch, [3, 1, 73]))
        #else
        matrixMarket.append(("%%MatrixMarket matrix coordinate pattern general\n1 1 1000000000\n", .entryCountMismatch, [3, 1, 64]))
        #endif
        for (input, kind, position) in matrixMarket {
            do {
                let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
                Issue.record("expected \(kind), read \(graph)")
            } catch {
                #expect(error.kind == kind, "\(input)")
                #expect([error.line, error.column, error.byteOffset] == position, "\(input)")
            }
        }

        // An edge-list column is typed by its text: an integer past Int is a double, and a decimal
        // past Double is infinite.
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let huge = String(repeating: "9", count: 100_000), wide = "1" + String(repeating: "0", count: 400)
        _ = try DirectedPseudograph<String>(edgeList: "a b \(huge)\nb c \(wide)\nc a 99999999999999999999\n".utf8, columns: ["w"],
                                            edgeAttribute: { edgeValues[$0, default: [:]][$1] = $2 })
        #expect(edgeValues == [0: ["w": .double(.infinity)], 1: ["w": .double(.infinity)], 2: ["w": .double(1e20)]])
        #expect(clock.now - start < .seconds(20))
    }

    @Test("Any DOCTYPE is refused before anything is expanded: billion laughs, external entities, inside the root", .timeLimit(.minutes(1)))
    func doctype() {
        let root = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">"
        var laughs = "<!DOCTYPE lolz [<!ENTITY lol \"lol\">"
        for k in 1 ... 9 { laughs += "<!ENTITY lol\(k + 1) \"" + String(repeating: "&lol\(k == 1 ? "" : String(k));", count: 10) + "\">" }
        laughs += "]>" + root + "<graph edgedefault=\"directed\"><node id=\"&lol10;\"/></graph></graphml>"
        let cases: [(String, [Int])] = [
            (laughs, [1, 1, 0]),
            ("<?xml version=\"1.0\"?>\n<!DOCTYPE g SYSTEM \"file:///etc/passwd\">\n" + root + "<graph edgedefault=\"directed\"/></graphml>", [2, 1, 22]),
            (root + "<!DOCTYPE g><graph edgedefault=\"directed\"/></graphml>", [1, 56, 55]),
            ("<!-- c --><!DOCTYPE g>" + root + "<graph edgedefault=\"directed\"/></graphml>", [1, 11, 10]),
        ]
        let clock = ContinuousClock()
        let start = clock.now
        for (input, position) in cases {
            var vertexCalls = 0
            do {
                let graph = try DirectedPseudograph<String>(graphML: input.utf8, vertex: { vertexCalls += 1; return $0 })
                Issue.record("expected doctypeNotAllowed, read \(graph)")
            } catch {
                #expect(error.kind == .doctypeNotAllowed, "\(input)")
                #expect([error.line, error.column, error.byteOffset] == position, "\(input)")
            }
            #expect(vertexCalls == 0)
        }
        #expect(clock.now - start < .seconds(5))
    }

    @Test("Every prefix of a valid file returns or throws, a cut scalar is invalidUTF8 at its lead byte, and positions agree", .timeLimit(.minutes(1)))
    func truncated() {
        // A file per format; DOT, GraphML and JSON close at the very end, so every proper prefix is an error.
        let files: [(String, String)] = [
            ("dot", "strict digraph G {\n\tnode [shape=box];\n\t\"é😀\" -> b -> \"c\\\"d\" [w=1, l=<<b>x</b>>];\n\t/* c */ x = y; // e\n}"),
            ("graphML", "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"w\" for=\"edge\" attr.name=\"w\" attr.type=\"double\"><default>1.5</default></key>\n<graph edgedefault=\"directed\"><node id=\"é😀\"/><node id=\"&lt;b&gt;\"><!-- c --></node><edge source=\"é😀\" target=\"&lt;b&gt;\"><data key=\"w\"><![CDATA[2]]></data></edge></graph></graphml>"),
            ("nodeLinkJSON", "{\"directed\": true, \"multigraph\": false, \"graph\": {\"g\": 1}, \"nodes\": [{\"id\": \"é\\ud83d\\ude00\"}, {\"id\": 7, \"x\": -1.5e-3}], \"edges\": [{\"source\": 7, \"target\": \"é😀\", \"ok\": false}]}"),
            ("matrixMarket", "%%MatrixMarket matrix coordinate real symmetric\n% é😀\n3 3 2\n2 1 -1.5e3\n3 3 Infinity\n"),
            ("edgeList", "# é😀\né😀 b 12\nb c -1.5e-3\n"),
            ("adjacencyList", "é😀 b c\nb c # x\nd\n"),
            ("mermaid", "---\ntitle: é\n---\nflowchart LR\n  A[\"é😀 #quot;\"] -->|yes| B((round)) --> C\n  %% c\n  A -.-> C;\n"),
            ("dotSubgraph", "digraph { subgraph s { node [k=v]; a:p:n -> { \"é😀\" c } [w=1] } }"),
            ("gml", "Creator \"é😀\"\ngraph [\n  directed 1\n  node [ id 0 label \"é&#128512;\" x 1.5 graphics [ w 2 ] ]\n  node [ id 1 ]\n  edge [ source 0 target 1 w -INF ]\n]"),
            ("pajek", "*Network é😀\n*Vertices 3\n1 \"é 😀\" 0.5 0.25 box ic Red\n2 b\n*Arcs\n1 2 1.5 c \"x y\"\n*Arcslist\n2 1 3\n"),
            ("graph6", ">>graph6<<Dhc"),
            ("sparse6", ">>sparse6<<:Fa@x^"),
            ("digraph6", ">>digraph6<<&DI?AO?"),
            ("dimacs", "c é😀\np sp 3 2\na 1 2 7\na 2 3 -1\n"),
            ("metis", "% é😀\n3 2 011\n5 2 7\n1 1 7 3 2\n2 2 2\n"),
            ("cytoscapeJSON", "{\"directed\": true, \"data\": [[\"g\", 1]], \"elements\": {\"nodes\": [{\"data\": {\"id\": \"é\\ud83d\\ude00\"}}, {\"data\": {\"id\": 7, \"x\": -1.5e-3}}], \"edges\": [{\"data\": {\"source\": 7, \"target\": \"é😀\", \"ok\": false}}]}}"),
            ("edgeListDict", "é😀,b,{'w': 1.5, 's': 'x,y'} # c\nb,c,{}\n"),
        ]
        let clock = ContinuousClock()
        let start = clock.now
        for (format, file) in files {
            let bytes = Array(file.utf8)
            for cut in 0 ... bytes.count {
                let input = Array(bytes[..<cut])
                var thrown: ParseError?
                do {
                    switch format {
                    case "dot": _ = try DirectedPseudograph<String>(dot: input)
                    case "graphML": _ = try DirectedPseudograph<String>(graphML: input)
                    case "nodeLinkJSON": _ = try DirectedPseudograph<String>(nodeLinkJSON: input)
                    case "matrixMarket": _ = try DirectedPseudograph<Int>(matrixMarket: input)
                    case "edgeList": _ = try DirectedPseudograph<String>(edgeList: input, columns: ["w"])
                    case "adjacencyList": _ = try DirectedPseudograph<String>(adjacencyList: input)
                    case "mermaid": _ = try DirectedPseudograph<String>(mermaid: input)
                    case "dotSubgraph": _ = try DirectedPseudograph<String>(dot: input)
                    case "gml": _ = try DirectedPseudograph<String>(gml: input)
                    case "pajek": _ = try DirectedPseudograph<String>(pajek: input)
                    case "graph6": _ = try Pseudograph<Int>(graph6: input)
                    case "sparse6": _ = try Pseudograph<Int>(sparse6: input)
                    case "digraph6": _ = try DirectedPseudograph<Int>(digraph6: input)
                    case "dimacs": _ = try DirectedPseudograph<Int>(dimacs: input)
                    case "metis": _ = try Pseudograph<Int>(metis: input)
                    case "cytoscapeJSON": _ = try DirectedPseudograph<String>(cytoscapeJSON: input)
                    default: _ = try DirectedPseudograph<String>(edgeList: input, delimiter: ",")
                    }
                } catch {
                    thrown = error
                }
                let complete = cut == bytes.count
                if complete { #expect(thrown == nil, "\(format) whole file: \(String(describing: thrown))") }
                if ["dot", "graphML", "nodeLinkJSON", "dotSubgraph", "gml", "graph6", "digraph6", "cytoscapeJSON"].contains(format) && !complete {
                    #expect(thrown != nil, "\(format) prefix of \(cut) bytes was accepted")
                }
                // A cut inside a scalar: invalidUTF8 at its lead byte.
                var lead = cut
                while lead > 0 && input[lead - 1] & 0xC0 == 0x80 { lead -= 1 }
                if lead > 0 && input[lead - 1] >= 0xC0 {
                    let width = input[lead - 1] >= 0xF0 ? 4 : input[lead - 1] >= 0xE0 ? 3 : 2
                    if cut - (lead - 1) < width {
                        #expect(thrown?.kind == .invalidUTF8 && thrown?.byteOffset == lead - 1, "\(format) cut at \(cut): \(String(describing: thrown))")
                    }
                }
                if let error = thrown {
                    let before = input[..<min(error.byteOffset, input.count)]
                    let lineStart = (before.lastIndex(of: 0x0A).map { $0 + 1 }) ?? 0
                    #expect(error.byteOffset <= input.count)
                    #expect(error.line == before.filter { $0 == 0x0A }.count + 1, "\(format) cut at \(cut): \(error)")
                    #expect(error.column == before[lineStart...].filter { $0 & 0xC0 != 0x80 }.count + 1, "\(format) cut at \(cut): \(error)")
                }
            }
        }
        #expect(clock.now - start < .seconds(20))
    }

    @Test("3 000 seeded random mutations of valid files: every reader returns or throws, with consistent positions", .tags(.randomized), .timeLimit(.minutes(1)))
    func mutatedInputs() {
        let seeds: [(String, String)] = [
            ("dot", "strict digraph { node [k=v]; a -> b -> c [w=1]; \"q\\\"\" [l=<<b>x</b>>]; x = \"y\" + \"z\" }"),
            ("dot", "graph { a -- b; b -- a [w=2] }"),
            ("graphML", "<?xml version=\"1.0\"?><graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><key id=\"d\" for=\"node\" attr.type=\"int\"><default>3</default></key><graph edgedefault=\"directed\"><node id=\"a\"><data key=\"d\">-7</data></node><node id=\"&amp;b\"/><edge source=\"a\" target=\"&amp;b\"/><!-- c --><![CDATA[x]]></graph></graphml>"),
            ("nodeLinkJSON", "{\"directed\": true, \"multigraph\": false, \"graph\": {\"name\": \"g\"}, \"nodes\": [{\"id\": \"a\", \"w\": 1.5e2}, {\"id\": 2, \"ok\": true}], \"edges\": [{\"source\": \"a\", \"target\": 2, \"s\": \"\\u00e9\\n\"}]}"),
            ("matrixMarket", "%%MatrixMarket matrix coordinate real general\n% c\n3 3 3\n1 2 0.5\n3 1 -1e3\n2 2 NaN\n"),
            ("edgeList", "# c\na b 1 x\nb c -2.5 y # z\n"),
            ("adjacencyList", "a b c\nb a # c\nd\n"),
            ("mermaid", "flowchart TD\n  A[box] -->|yes| B(round) -.-> C{d}\n  B == t ==> D;\n  classDef x fill:#f00\n"),
            ("dot", "digraph { subgraph cluster { edge [w=2]; a:p -> {b c} -> d:q:n } e -> subgraph { f } }"),
            ("gml", "graph [ directed 1 node [ id 1 label \"a&amp;\" w 1.5 ] node [ id 2 g [ x 1 ] ] edge [ source 1 target 2 k \"v\" ] ]"),
            ("pajek", "*Vertices 3\n1 \"a b\" 0.1 0.2 box c 'x'\n*Arcs\n1 2 3.5 l \"q\\\"\"\n*Arcslist\n3 1 2\n"),
            ("graph6", "Dhc\n"),
            ("sparse6", ":Fa@x^\n"),
            ("digraph6", "&DI?AO?\n"),
            ("dimacs", "c x\np sp 3 2\na 1 2 5\na 3 1 -2\n"),
            ("metis", "3 2 1\n2 4\n1 4 3 1\n2 1\n"),
            ("cytoscapeJSON", "{\"directed\": true, \"data\": {\"n\": \"g\"}, \"elements\": [{\"data\": {\"id\": \"a\", \"w\": 1}}, {\"group\": \"nodes\", \"data\": {\"id\": 2}}, {\"data\": {\"source\": \"a\", \"target\": 2}}]}"),
            ("edgeListDict", "a b {'w': 1, 's': 'x # y', 'ok': True}\nb c {}\n"),
        ]
        let alphabet = Array("<>{}[]\"&;#-=|\\\n\r\t 0aZ%.:".utf8) + [0xC3, 0xFF]
        var rng = SeededRandomNumberGenerator(seed: 7)
        let clock = ContinuousClock()
        let start = clock.now
        var accepted = 0, rejected = 0
        for _ in 0 ..< 3_000 {
            let (format, seed) = seeds.randomElement(using: &rng)!
            var input = Array(seed.utf8)
            for _ in 0 ..< Int.random(in: 1 ... 4, using: &rng) {
                let position = Int.random(in: 0 ... input.count, using: &rng)
                switch Int.random(in: 0 ..< 3, using: &rng) {
                case 0 where !input.isEmpty: input.remove(at: min(position, input.count - 1))
                case 1: input.insert(alphabet.randomElement(using: &rng)!, at: position)
                default: if !input.isEmpty { input[min(position, input.count - 1)] = UInt8.random(in: 0 ... 255, using: &rng) }
                }
            }
            do {
                switch format {
                case "dot":
                    if seed.hasPrefix("graph") { _ = try Pseudograph<String>(dot: input) } else { _ = try DirectedPseudograph<String>(dot: input) }
                case "graphML": _ = try DirectedPseudograph<String>(graphML: input)
                case "nodeLinkJSON": _ = try DirectedPseudograph<String>(nodeLinkJSON: input)
                case "matrixMarket": _ = try DirectedPseudograph<Int>(matrixMarket: input)
                case "edgeList": _ = try Pseudograph<String>(edgeList: input, columns: ["w", "s"])
                case "adjacencyList": _ = try DirectedPseudograph<String>(adjacencyList: input)
                case "mermaid": _ = try DirectedPseudograph<String>(mermaid: input)
                case "gml": _ = try DirectedPseudograph<String>(gml: input)
                case "pajek": _ = try DirectedPseudograph<String>(pajek: input)
                case "graph6": _ = try Pseudograph<Int>(graph6: input)
                case "sparse6": _ = try Pseudograph<Int>(sparse6: input)
                case "digraph6": _ = try DirectedPseudograph<Int>(digraph6: input)
                case "dimacs": _ = try DirectedPseudograph<Int>(dimacs: input)
                case "metis": _ = try Pseudograph<Int>(metis: input)
                case "cytoscapeJSON": _ = try DirectedPseudograph<String>(cytoscapeJSON: input)
                default: _ = try Pseudograph<String>(edgeList: input)
                }
                accepted += 1
            } catch {
                rejected += 1
                let body = input.starts(with: [0xEF, 0xBB, 0xBF]) ? Array(input.dropFirst(3)) : input
                #expect(error.byteOffset >= 0 && error.byteOffset <= body.count, "\(format) \(input): \(error)")
                let before = body[..<min(max(error.byteOffset, 0), body.count)]
                let lineStart = (before.lastIndex(of: 0x0A).map { $0 + 1 }) ?? 0
                #expect(error.line == before.filter { $0 == 0x0A }.count + 1, "\(format) \(input): \(error)")
                #expect(error.column == before[lineStart...].filter { $0 & 0xC0 != 0x80 }.count + 1, "\(format) \(input): \(error)")
            }
        }
        #expect(accepted > 0 && rejected > 0)
        #expect(clock.now - start < .seconds(30))
    }
}
