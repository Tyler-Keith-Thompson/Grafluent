// Mermaid (catalog GF-161 – GF-185 and GF-231 read, GF-222 – GF-225 write): flowcharts with every
// supported shape and link, labels kept and styling skipped; the writer quotes every label.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats Mermaid")
struct GraphFormatsMermaidTests {
    @Test("GF-161 flowchart with a direction")
    func gf161() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B; A>B
        let input = "flowchart LR\n    A --> B\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-162 graph keyword, no direction")
    func gf162() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B; A>B
        let input = "graph\nA-->B\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-163 chain")
    func gf163() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B, C; A>B, B>C
        let input = "flowchart TD\n  A --> B --> C\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"], ["B", "C"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-164 & fans out: every source to every target")
    func gf164() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B, C, D; A>C, A>D, B>C, B>D
        let input = "flowchart TD\n  A & B --> C & D\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C", "D"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "C"], ["A", "D"], ["B", "C"], ["B", "D"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-165 shapes give labels; the shape itself is not graph data")
    func gf165() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A{label="box"}, B{label="round"}, C{label="decision"}, D{label="circle"}, E{label="flag"}, F{label="db"}, G{label="sub"}, H{label="hex"}, I{label="para"}, J{label="alt"}, K{label="trap"}, L{label="stadium"}, M{label="double"}; A>B, C>D, E>F, G>H, I>J, K>L, M>A
        let input = "flowchart TD\n  A[box] --> B(round)\n  C{decision} --> D((circle))\n  E>flag] --> F[(db)]\n  G[[sub]] --> H{{hex}}\n  I[/para/] --> J[\\alt\\]\n  K[/trap\\] --> L([stadium])\n  M(((double))) --> A\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M"])
        #expect(graph.vertexCount == 13 && graph.edgeCount == 7)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"], ["C", "D"], ["E", "F"], ["G", "H"], ["I", "J"], ["K", "L"], ["M", "A"]])
        #expect(vertexLabels == ["A": "box", "B": "round", "C": "decision", "D": "circle", "E": "flag", "F": "db", "G": "sub", "H": "hex", "I": "para", "J": "alt", "K": "trap", "L": "stadium", "M": "double"])
        #expect(edgeLabels == [:])
    }

    @Test("GF-166 quoted labels and entity codes")
    func gf166() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A{label="a [b] \"c\" # ♥"}
        let input = "flowchart TD\n  A[\"a [b] #quot;c#quot; #35; #9829;\"]\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A"])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(vertexLabels == ["A": "a [b] \"c\" # ♥"])
        #expect(edgeLabels == [:])
    }

    @Test("GF-167 a later label replaces the earlier one")
    func gf167() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A{label="two"}, B; A>B
        let input = "flowchart TD\n  A[one]\n  A --> B\n  A[two]\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == ["A": "two"])
        #expect(edgeLabels == [:])
    }

    @Test("GF-168 edge labels: |text| and text in the link")
    func gf168() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B, C; A>B{label="yes"}, B>C{label="no"}, C>A{label="q|r"}
        let input = "flowchart TD\n  A -->|yes| B\n  B -- no --> C\n  C -->|\"q|r\"| A\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"], ["B", "C"], ["C", "A"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [0: "yes", 1: "no", 2: "q|r"])
    }

    @Test("GF-169 dotted, thick, circle and cross links are directed")
    func gf169() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B, C, D; A>B, B>C, C>D, D>A, A>C{label="t"}, B>D{label="t"}, A>D
        let input = "flowchart TD\n  A -.-> B\n  B ==> C\n  C --o D\n  D --x A\n  A -. t .-> C\n  B == t ==> D\n  A ---> D\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C", "D"])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 7)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"], ["B", "C"], ["C", "D"], ["D", "A"], ["A", "C"], ["B", "D"], ["A", "D"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [4: "t", 5: "t"])
    }

    @Test("GF-170 open links into an undirected target")
    func gf170() throws {
        // Pseudograph<String>(mermaid:) → U: A, B, C; A-B, B-C, C-A, A-C{label="t"}
        let input = "flowchart TD\n  A --- B\n  B -.- C\n  C === A\n  A -- t --- C\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try Pseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 4)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["A", "B"], ["B", "C"], ["C", "A"], ["A", "C"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [3: "t"])
    }

    @Test("GF-171 styling statements, ::: classes and %% comments are skipped")
    func gf171() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B; A>B
        let input = "%%{init: {}}%%\nflowchart TD\n  %% note\n  A:::hot --> B\n  classDef hot fill:#f00\n  class A hot\n  style B stroke:#333\n  click A callback\n  linkStyle 0 stroke:#0f0\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-172 ; separates statements")
    func gf172() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B, C; A>B, B>C
        let input = "flowchart TD; A --> B; B --> C;"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"], ["B", "C"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-173 front matter is skipped")
    func gf173() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B; A>B
        let input = "---\ntitle: T\n---\nflowchart TD\n  A --> B\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-174 o right after the dashes is a circle head")
    func gf174() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B; A>B
        let input = "flowchart TD\n  A---oB\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-175 open link into a directed target")
    func gf175() {
        // DirectedPseudograph<String>(mermaid:) → **kindMismatch** at 2:5
        let input = "flowchart TD\n  A --- B\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [2, 5, 17])
        }
    }

    @Test("GF-176 arrow into an undirected target")
    func gf176() {
        // Pseudograph<String>(mermaid:) → **kindMismatch** at 2:5
        let input = "flowchart TD\n  A --> B\n"
        do {
            let graph = try Pseudograph<String>(mermaid: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [2, 5, 17])
        }
    }

    @Test("GF-177 subgraph ... end (unsupported)")
    func gf177() {
        // DirectedPseudograph<String>(mermaid:) → **unsupported** at 2:3
        let input = "flowchart TD\n  subgraph one\n    A --> B\n  end\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 15])
        }
    }

    @Test("GF-178 bidirectional link (unsupported)")
    func gf178() {
        // DirectedPseudograph<String>(mermaid:) → **unsupported** at 2:5
        let input = "flowchart TD\n  A <--> B\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 5, 17])
        }
    }

    @Test("GF-179 invisible link (unsupported)")
    func gf179() {
        // DirectedPseudograph<String>(mermaid:) → **unsupported** at 2:5
        let input = "flowchart TD\n  A ~~~ B\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 5, 17])
        }
    }

    @Test("GF-180 @{ } shape syntax (unsupported)")
    func gf180() {
        // DirectedPseudograph<String>(mermaid:) → **unsupported** at 2:4
        let input = "flowchart TD\n  A@{ shape: rect }\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 4, 16])
        }
    }

    @Test("GF-181 another diagram type")
    func gf181() {
        // DirectedPseudograph<String>(mermaid:) → **unsupported** at 1:1
        let input = "sequenceDiagram\n  A->>B: hi\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-182 missing header")
    func gf182() {
        // DirectedPseudograph<String>(mermaid:) → **syntax** at 1:1
        let input = "A --> B\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-183 a label cannot span lines")
    func gf183() {
        // DirectedPseudograph<String>(mermaid:) → **syntax** at 2:8
        let input = "flowchart TD\n  A[box\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 8, 20])
        }
    }

    @Test("GF-184 end is not a vertex id")
    func gf184() {
        // DirectedPseudograph<String>(mermaid:) → **unsupported** at 2:9
        let input = "flowchart TD\n  A --> end\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [2, 9, 21])
        }
    }

    @Test("GF-185 link without a target")
    func gf185() {
        // DirectedPseudograph<String>(mermaid:) → **syntax** at 2:8
        let input = "flowchart TD\n  A -->\n"
        do {
            let graph = try DirectedPseudograph<String>(mermaid: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 8, 20])
        }
    }

    @Test("GF-222 directed, vertex and edge labels with escapes")
    func gf222() throws {
        // writeMermaid(to:) on D: A{label="say \"hi\" #1 <b> & more"}, B{label="two\nlines"}, C; A>B{label="yes|no"}, B>C, C>A
        let graph = DirectedPseudograph<String>(vertices: ["A", "B", "C"], edges: [DirectedEdge(from: "A", to: "B"), DirectedEdge(from: "B", to: "C"), DirectedEdge(from: "C", to: "A")])
        var output = ""
        try graph.writeMermaid(to: &output, vertexLabel: { v in
            switch v {
            case "A": "say \"hi\" #1 <b> & more"
            case "B": "two\nlines"
            default: nil
            }
        }, edgeLabel: { e in
            switch e {
            case 0: "yes|no"
            default: nil
            }
        })
        #expect(output == "flowchart TD\n    A[\"say #quot;hi#quot; #35;1 #lt;b#gt; #amp; more\"]\n    B[\"two#10;lines\"]\n    C\n    A -->|\"yes|no\"| B\n    B --> C\n    C --> A\n")
    }

    @Test("GF-223 undirected")
    func gf223() throws {
        // writeMermaid(to:) on U: A, B; A-B, B-B{label="loop"}
        let graph = Pseudograph<String>(vertices: ["A", "B"], edges: [UndirectedEdge("A", "B"), UndirectedEdge("B", "B")])
        var output = ""
        try graph.writeMermaid(to: &output, edgeLabel: { e in
            switch e {
            case 1: "loop"
            default: nil
            }
        })
        #expect(output == "flowchart TD\n    A\n    B\n    A --- B\n    B ---|\"loop\"| B\n")
    }

    @Test("GF-224 empty")
    func gf224() throws {
        // writeMermaid(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        try graph.writeMermaid(to: &output)
        #expect(output == "flowchart TD\n")
    }

    @Test("GF-225 vertices without labels")
    func gf225() throws {
        // writeMermaid(to:) on D: a, b, z; a>b
        let graph = DirectedPseudograph<String>(vertices: ["a", "b", "z"], edges: [DirectedEdge(from: "a", to: "b")])
        var output = ""
        try graph.writeMermaid(to: &output)
        #expect(output == "flowchart TD\n    a\n    b\n    z\n    a --> b\n")
    }

    @Test("GF-231 a lone CR ends a statement")
    func gf231() throws {
        // DirectedPseudograph<String>(mermaid:) → D: A, B, C; B>C
        let input = "flowchart TD\n  A\rB --> C\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B", "C"])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["B", "C"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-244 a styling keyword followed by a link or & is a vertex")
    func gf244() throws {
        // DirectedPseudograph<String>(mermaid:) → D: style, B, class, A, C; style>B, class>C, A>C
        let input = "flowchart TD\n  style --> B\n  class & A --> C\n  style A fill:#f9f\n  class A foo\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try DirectedPseudograph<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["style", "B", "class", "A", "C"])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["style", "B"], ["class", "C"], ["A", "C"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [:])
    }

    @Test("GF-245 into a simple target a repeated link merges, its last label winning")
    func gf245() throws {
        // AdjacencyList<String>(mermaid:) → D: A, B; A>B{label="y"}
        let input = "flowchart LR\n  A -->|x| B\n  A -->|y| B\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try AdjacencyList<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [0: "y"])
    }

    @Test("GF-246 into a simple undirected target B --- A is A --- B")
    func gf246() throws {
        // UndirectedAdjacencyList<String>(mermaid:) → U: A, B; A-B{label="t"}
        let input = "graph TD\n  A --- B\n  B ---|t| A\n"
        var vertexLabels: [String: String] = [:]
        var edgeLabels: [Int: String] = [:]
        let graph = try UndirectedAdjacencyList<String>(mermaid: input.utf8, vertexLabel: { v, label in vertexLabels[v] = label }, edgeLabel: { e, label in edgeLabels[e] = label })
        #expect(Array(graph.vertices) == ["A", "B"])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["A", "B"]])
        #expect(vertexLabels == [:])
        #expect(edgeLabels == [0: "t"])
    }
}
