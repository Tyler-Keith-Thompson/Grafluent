    @Test("A key given twice for one element traps (every attribute writer)")
    func duplicateKeyInOneElement() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(vertices: ["a"])
            graph.writeDOT(to: &output, vertexAttributes: { _ in [("k", .integer(1)), ("k", .integer(2))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")])
            graph.writeGraphML(to: &output, edgeAttributes: { _ in [("w", .double(1)), ("w", .double(2))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = Pseudograph<String>(vertices: ["a"])
            graph.writeNodeLinkJSON(to: &output, graphAttributes: [("g", .boolean(true)), ("g", .boolean(false))])
        }
        await #expect(processExitsWith: .failure) {
            // Past eight keys, compared through a set.
            var output = ""
            let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")])
            graph.writeNodeLinkJSON(to: &output, edgeAttributes: { _ in (0 ..< 10).map { ("k\($0 % 9)", .integer($0)) } })
        }
        // Without the fault: the same keys once each.
        var output = ""
        DirectedPseudograph<String>(vertices: ["a"]).writeDOT(to: &output, vertexAttributes: { _ in [("k", .integer(1)), ("l", .integer(2))] })
        #expect(output == "digraph {\n\ta [k=1, l=2];\n}\n")
        output = ""
        Pseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, graphAttributes: [("g", .boolean(true)), ("h", .boolean(false))])
        #expect(output == "{\"directed\": false, \"multigraph\": false, \"graph\": {\"g\": true, \"h\": false}, \"nodes\": [{\"id\": \"a\"}], \"edges\": []}")
    }

    @Test("GraphML: one key holding a string and a boolean traps; integers and doubles share a double key")
    func graphMLMixedKeyTypes() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(vertices: ["a", "b"])
            graph.writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .string("x"))] : [("k", .boolean(true))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(vertices: ["a", "b"])
            graph.writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .integer(1))] : [("k", .string("1"))] })
        }
        // Without the fault: an integer and a double under one key, and the same name in two domains.
        var output = ""
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"])
        graph.writeGraphML(to: &output, vertexAttributes: { v in v == "a" ? [("k", .integer(1))] : [("k", .double(0.5))] },
                           graphAttributes: [("k", .string("x"))])
        #expect(output.contains("<key id=\"d0\" for=\"graph\" attr.name=\"k\" attr.type=\"string\"/>\n"))
        #expect(output.contains("<key id=\"d1\" for=\"node\" attr.name=\"k\" attr.type=\"double\"/>\n"))
        #expect(output.contains("<data key=\"d1\">1</data>") && output.contains("<data key=\"d1\">0.5</data>"))
    }

    @Test("GraphML: a string XML 1.0 cannot hold traps (C0 controls, U+FFFE, U+FFFF), in ids, keys and values")
    func graphMLUnrepresentableStrings() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a\u{1}"]).writeGraphML(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a"]).writeGraphML(to: &output, vertexAttributes: { _ in [("s", .string("\u{FFFE}"))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a"]).writeGraphML(to: &output, graphAttributes: [("\u{0}", .integer(1))])
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writeGraphML(to: &output, edgeAttributes: { _ in [("s", .string("x\u{FFFF}"))] })
        }
        // Without the fault: tab, line feed and carriage return are representable (as references in attributes).
        var output = ""
        DirectedPseudograph<String>(vertices: ["a\t\n\r"]).writeGraphML(to: &output, vertexAttributes: { _ in [("s", .string("\t\n\r"))] })
        #expect(output.contains("<node id=\"a&#9;&#10;&#13;\">"))
        #expect(output.contains("<data key=\"d0\">\t\n&#13;</data>"))
    }

    @Test("Node-link JSON: a non-finite double traps, as does an attribute named id, source, target or key")
    func nodeLinkUnrepresentable() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, vertexAttributes: { _ in [("x", .double(.infinity))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, graphAttributes: [("x", .double(.nan))])
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, vertexAttributes: { _ in [("id", .string("b"))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("source", .string("b"))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("target", .integer(1))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("key", .integer(0))] })
        }
        await #expect(processExitsWith: .failure) {
            // An edge attribute named as the nodes' last one was: still checked as an edge's.
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(
                to: &output, vertexAttributes: { _ in [("source", .integer(1))] }, edgeAttributes: { _ in [("source", .integer(2))] })
        }
        // Without the fault: the same names are fine on the other element kind, and finite doubles.
        var output = ""
        DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeNodeLinkJSON(
            to: &output, vertexAttributes: { _ in [("source", .double(1e300))] }, edgeAttributes: { _ in [("id", .double(-0.0))] })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"source\": 1e+300, \"id\": \"a\"}, {\"source\": 1e+300, \"id\": \"b\"}], \"edges\": [{\"id\": -0.0, \"source\": \"a\", \"target\": \"b\"}]}")
    }

    @Test("Edge list: an ID or string value with whitespace or #, an empty one, a boolean column, or a missing column traps")
    func edgeListUnrepresentable() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a b", to: "c")]).writeEdgeList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<String>(edges: [UndirectedEdge("a", "#c")]).writeEdgeList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "", to: "c")]).writeEdgeList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["ok"], edgeAttributes: { _ in [("ok", .boolean(true))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["s"], edgeAttributes: { _ in [("s", .string("x\ty"))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, vertexID: { $0 == "a" ? "a\nb" : $0 })
        }
        // A column the edge has no value for (it would be written as a short line).
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["s", "n"], edgeAttributes: { _ in [("s", .string("x"))] })
        }
        // Without the fault: the same edge with token-safe text.
        var output = ""
        DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
            to: &output, columns: ["s", "n"], edgeAttributes: { _ in [("n", .integer(-3)), ("s", .string("x|y"))] })
        #expect(output == "a c x|y -3\n")
    }

    @Test("Adjacency list: an ID with whitespace or #, or an empty one, traps")
    func adjacencyListUnrepresentable() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a b"]).writeAdjacencyList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<String>(edges: [UndirectedEdge("a", "b#")]).writeAdjacencyList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: [""]).writeAdjacencyList(to: &output)
        }
        // Without the fault: an isolated vertex alone on its line.
        var output = ""
        DirectedPseudograph<String>(vertices: ["a-b"]).writeAdjacencyList(to: &output)
        #expect(output == "a-b\n")
    }

    @Test("Mermaid: an ID outside [A-Za-z0-9_]+ or a reserved word traps")
    func mermaidUnrepresentable() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a-b"]).writeMermaid(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["end"]).writeMermaid(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<String>(edges: [UndirectedEdge("a", "subgraph")]).writeMermaid(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["é"]).writeMermaid(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a"]).writeMermaid(to: &output, vertexID: { _ in "" })
        }
        // Without the fault: arbitrary names go through vertexID (indices) and vertexLabel (the names).
        var output = ""
        let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "end", to: "a-b")])
        graph.writeMermaid(to: &output, vertexID: { $0 == "end" ? "v0" : "v1" }, vertexLabel: { $0 })
        #expect(output == "flowchart TD\n    v0[\"end\"]\n    v1[\"a-b\"]\n    v0 --> v1\n")
    }

    @Test("Two vertices with one ID trap in every writer that names vertices; IDs compare by Unicode scalars")
    func repeatedVertexID() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(vertices: [1, 2]).writeDOT(to: &output, vertexID: { _ in "x" })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<Int>(vertices: [1, 2]).writeGraphML(to: &output, vertexID: { _ in "x" })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(vertices: [1, 2]).writeNodeLinkJSON(to: &output, vertexID: { _ in .integer(7) })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(edges: [DirectedEdge(from: 1, to: 2)]).writeEdgeList(to: &output, vertexID: { _ in "x" })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<Int>(vertices: [1, 2]).writeAdjacencyList(to: &output, vertexID: { _ in "x" })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(vertices: [1, 2]).writeMermaid(to: &output, vertexID: { _ in "x" })
        }
        // Without the fault: distinct IDs, including the string "7" beside the integer 7, and "é"
        // precomposed beside "é" decomposed (canonically equivalent, different scalars).
        var output = ""
        DirectedPseudograph<Int>(vertices: [1, 2]).writeNodeLinkJSON(to: &output, vertexID: { $0 == 1 ? .integer(7) : .string("7") })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": 7}, {\"id\": \"7\"}], \"edges\": []}")
        output = ""
        DirectedPseudograph<Int>(vertices: [1, 2]).writeDOT(to: &output, vertexID: { $0 == 1 ? "\u{E9}" : "e\u{301}" })
        // Compared by scalars: `==` on String would also accept both written precomposed.
        #expect(Array(output.unicodeScalars) == Array("digraph {\n\t\"\u{E9}\";\n\t\"e\u{301}\";\n}\n".unicodeScalars))
    }

    @Test("A repeated decimal ID traps, small or past the vertex count, in every writer; 7 and 07 are two IDs")
    func repeatedDecimalID() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<Int>(vertices: [1, 2]).writeAdjacencyList(to: &output, vertexID: { _ in "7" })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(vertices: [1, 2]).writeAdjacencyList(to: &output, vertexID: { _ in "99999999999" })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(vertices: [1, 2, 3]).writeNodeLinkJSON(to: &output, vertexID: { .integer($0 == 3 ? 1 : $0) })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(edges: [DirectedEdge(from: 1, to: 2)]).writeEdgeList(to: &output, vertexID: { _ in "0" })
        }
        // Without the fault: a decimal, its spelling with a leading zero or a sign, and one past
        // the vertex count are four IDs.
        var output = ""
        DirectedPseudograph<Int>(vertices: [1, 2, 3, 4]).writeAdjacencyList(to: &output, vertexID: { ["7", "07", "+7", "99999999999"][$0 - 1] })
        #expect(output == "7\n07\n+7\n99999999999\n")
    }

    @Test("Node-link JSON: an id that is neither a string nor an integer traps")
    func nodeLinkIDType() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<Int>(vertices: [1]).writeNodeLinkJSON(to: &output, vertexID: { _ in .double(1.5) })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<Int>(vertices: [1]).writeNodeLinkJSON(to: &output, vertexID: { _ in .boolean(true) })
        }
        // Without the fault: a string id.
        var output = ""
        DirectedPseudograph<Int>(vertices: [1]).writeNodeLinkJSON(to: &output, vertexID: { _ in .string("1.5") })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": \"1.5\"}], \"edges\": []}")
    }

    @Test("Edge and adjacency lists: an ID holding whitespace the readers split on (VT, FF, NBSP, U+3000) traps")
    func listTokenWhitespace() async {
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a\u{B}b", to: "c")]).writeEdgeList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(vertices: ["a\u{C}"]).writeAdjacencyList(to: &output)
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")])
                .writeEdgeList(to: &output, columns: ["s"], edgeAttributes: { _ in [("s", .string("x\u{A0}y"))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            Pseudograph<String>(vertices: ["\u{3000}"]).writeAdjacencyList(to: &output)
        }
        // Without the fault: other non-ASCII characters are fine, and read back as written.
        var output = ""
        DirectedPseudograph<String>(edges: [DirectedEdge(from: "a\u{200B}b", to: "日本")]).writeEdgeList(to: &output)
        #expect(output == "a\u{200B}b 日本\n")
        let reread = try? DirectedPseudograph<String>(edgeList: output.utf8)
        #expect(reread.map { Array($0.vertices) } == ["a\u{200B}b", "日本"])
    }
