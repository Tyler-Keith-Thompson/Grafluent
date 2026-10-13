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
