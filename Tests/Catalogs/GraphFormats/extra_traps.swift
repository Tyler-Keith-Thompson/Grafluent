    @Test("A key given twice for one element traps (every attribute writer)")
    func duplicateKeyInOneElement() async throws {
        // `try?`: a writer that threw instead of trapping would return here and exit cleanly.
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(vertices: ["a"])
            _ = try? graph.writeDOT(to: &output, vertexAttributes: { _ in [("k", .integer(1)), ("k", .integer(2))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = try? graph.writeGraphML(to: &output, edgeAttributes: { _ in [("w", .double(1)), ("w", .double(2))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = Pseudograph<String>(vertices: ["a"])
            _ = try? graph.writeNodeLinkJSON(to: &output, graphAttributes: [("g", .boolean(true)), ("g", .boolean(false))])
        }
        await #expect(processExitsWith: .failure) {
            // Past eight keys, compared through a set.
            var output = ""
            let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = try? graph.writeNodeLinkJSON(to: &output, edgeAttributes: { _ in (0 ..< 10).map { ("k\($0 % 9)", .integer($0)) } })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")])
            _ = try? graph.writeEdgeList(to: &output, columns: ["k"], edgeAttributes: { _ in [("k", .integer(1)), ("k", .integer(2))] })
        }
        // Without the fault: the same keys once each.
        var output = ""
        try DirectedPseudograph<String>(vertices: ["a"]).writeDOT(to: &output, vertexAttributes: { _ in [("k", .integer(1)), ("l", .integer(2))] })
        #expect(output == "digraph {\n\ta [k=1, l=2];\n}\n")
        output = ""
        try Pseudograph<String>(vertices: ["a"]).writeNodeLinkJSON(to: &output, graphAttributes: [("g", .boolean(true)), ("h", .boolean(false))])
        #expect(output == "{\"directed\": false, \"multigraph\": false, \"graph\": {\"g\": true, \"h\": false}, \"nodes\": [{\"id\": \"a\"}], \"edges\": []}")
        output = ""
        try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")])
            .writeEdgeList(to: &output, columns: ["k"], edgeAttributes: { _ in [("k", .integer(1)), ("l", .integer(2))] })
        #expect(output == "a b 1\n")
    }

    @Test("Edge list: a column the edge has no value for traps")
    func edgeListMissingColumn() async throws {
        // It would be written as a short line.
        await #expect(processExitsWith: .failure) {
            var output = ""
            _ = try? DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
                to: &output, columns: ["s", "n"], edgeAttributes: { _ in [("s", .string("x"))] })
        }
        // Without the fault: the same edge with both columns.
        var output = ""
        try DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "c")]).writeEdgeList(
            to: &output, columns: ["s", "n"], edgeAttributes: { _ in [("n", .integer(-3)), ("s", .string("x|y"))] })
        #expect(output == "a c x|y -3\n")
    }

    @Test("Node-link JSON: an id that is neither a string nor an integer traps")
    func nodeLinkIDType() async throws {
        await #expect(processExitsWith: .failure) {
            var output = ""
            _ = try? DirectedPseudograph<Int>(vertices: [1]).writeNodeLinkJSON(to: &output, vertexID: { _ in .double(1.5) })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            _ = try? Pseudograph<Int>(vertices: [1]).writeNodeLinkJSON(to: &output, vertexID: { _ in .boolean(true) })
        }
        // Without the fault: a string id.
        var output = ""
        try DirectedPseudograph<Int>(vertices: [1]).writeNodeLinkJSON(to: &output, vertexID: { _ in .string("1.5") })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"id\": \"1.5\"}], \"edges\": []}")
    }

    @Test("A key given twice for one element traps in the GML, Pajek and Cytoscape JSON writers")
    func duplicateKeyInNewWriters() async throws {
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = DirectedPseudograph<String>(vertices: ["a"])
            _ = try? graph.writeGML(to: &output, vertexAttributes: { _ in [("k", .integer(1)), ("k", .integer(2))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = Pseudograph<String>(edges: [UndirectedEdge("a", "b")])
            _ = try? graph.writePajek(to: &output, edgeAttributes: { _ in [("weight", .double(1)), ("weight", .double(2))] })
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            let graph = Pseudograph<String>(vertices: ["a"])
            _ = try? graph.writeCytoscapeJSON(to: &output, graphAttributes: [("g", .boolean(true)), ("g", .boolean(false))])
        }
        // Without the fault: the same keys once each.
        var output = ""
        try DirectedPseudograph<String>(vertices: ["a"]).writeGML(to: &output, vertexAttributes: { _ in [("k", .integer(1)), ("l", .integer(2))] })
        #expect(output == "graph [\n  directed 1\n  node [\n    id 0\n    label \"a\"\n    k 1\n    l 2\n  ]\n]\n")
        output = ""
        try Pseudograph<String>(edges: [UndirectedEdge("a", "b")]).writePajek(to: &output, edgeAttributes: { _ in [("weight", .double(1)), ("w", .double(2))] })
        #expect(output == "*vertices 2\n1 a 0.0 0.0 ellipse\n2 b 0.0 0.0 ellipse\n*edges\n1 2 1.0 w 2.0\n")
    }

    @Test("An edge-list delimiter that is not ASCII, or is a letter, a digit, '.', '+', '-', '#', LF or CR, traps")
    func edgeListDelimiter() async throws {
        await #expect(processExitsWith: .failure) {
            _ = try? DirectedPseudograph<String>(edgeList: "a\u{E9}b\n".utf8, delimiter: "\u{E9}")
        }
        await #expect(processExitsWith: .failure) {
            _ = try? DirectedPseudograph<String>(edgeList: "1.2\n".utf8, delimiter: ".")
        }
        await #expect(processExitsWith: .failure) {
            _ = try? Pseudograph<Int>(edgeList: "1#2\n".utf8, delimiter: "#")
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            _ = try? DirectedPseudograph<String>(edges: [DirectedEdge(from: "a", to: "b")]).writeEdgeList(to: &output, delimiter: "x")
        }
        await #expect(processExitsWith: .failure) {
            var output = ""
            _ = try? Pseudograph<Int>(edges: [UndirectedEdge(1, 2)]).writeEdgeList(to: &output, delimiter: "\n")
        }
        // Without the fault: the same calls with a comma.
        let graph = try DirectedPseudograph<String>(edgeList: "a,b\n".utf8, delimiter: ",")
        #expect(Array(graph.vertices) == ["a", "b"])
        var output = ""
        try Pseudograph<Int>(edges: [UndirectedEdge(1, 2)]).writeEdgeList(to: &output, delimiter: ",")
        #expect(output == "1,2\n")
    }
