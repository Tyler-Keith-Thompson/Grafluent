// How IDs and attribute names compare: by Unicode scalars, as NetworkX compares Python strings and
// Graphviz and XML compare names, not by canonical equivalence as `String`'s `==` does. A reader
// keeps "é" (U+00E9) and "e" + U+0301 apart, and maps each through the `vertex` closure; a
// `String` vertex then merges them, since the two are one `String`, while a type that compares
// scalars keeps them apart. Attribute names and the writers' IDs and keys compare by scalars
// throughout. See README.md.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats identifiers")
struct GraphFormatsIdentifierTests {
    @Test("Canonically equivalent IDs are two IDs; a String target merges them, a scalar target does not")
    func canonicalEquivalence() throws {
        let composed = "\u{E9}", decomposed = "e\u{301}"
        let dot = "digraph { \"\(composed)\" -> \"\(decomposed)\" }"
        let strings = try DirectedPseudograph<String>(dot: dot.utf8)
        #expect(strings.vertexCount == 1)
        #expect(Array(strings.vertices[strings.vertices.startIndex].unicodeScalars) == Array(composed.unicodeScalars))
        #expect(strings.edgeCount == 1)
        let scalars = try DirectedPseudograph<[Unicode.Scalar]>(dot: dot.utf8, vertex: { Array($0.unicodeScalars) })
        #expect(Array(scalars.vertices) == [Array(composed.unicodeScalars), Array(decomposed.unicodeScalars)])
        #expect(scalars.edges.map { $0 } == [DirectedEdge(from: Array(composed.unicodeScalars), to: Array(decomposed.unicodeScalars))])
        // The edge list the same way.
        #expect(try Pseudograph<String>(edgeList: "\(composed) \(decomposed)\n".utf8).vertexCount == 1)
        #expect(try Pseudograph<[Unicode.Scalar]>(edgeList: "\(composed) \(decomposed)\n".utf8, vertex: { Array($0.unicodeScalars) }).vertexCount == 2)

        // GraphML declares nodes: two declarations of one String vertex are duplicateVertex.
        let graphML = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"><graph edgedefault=\"directed\">"
            + "<node id=\"\(composed)\"/><node id=\"\(decomposed)\"/><edge source=\"\(composed)\" target=\"\(decomposed)\"/></graph></graphml>"
        // The second declaration's id attribute, found by bytes (as Characters, "e" + U+0301 is one).
        let bytes = Array(graphML.utf8), needle = Array("id=\"e".utf8)
        let second = (0 ... bytes.count - needle.count).last { Array(bytes[$0 ..< $0 + needle.count]) == needle } ?? -1
        #expect(throws: ParseError(kind: .duplicateVertex, line: 1, column: second, byteOffset: second)) {
            try DirectedPseudograph<String>(graphML: graphML.utf8)
        }
        let declared = try DirectedPseudograph<[Unicode.Scalar]>(graphML: graphML.utf8, vertex: { Array($0.unicodeScalars) })
        #expect(declared.vertexCount == 2 && declared.edgeCount == 1)
    }

    @Test("Attribute names compare by scalars: DOT defaults, GraphML key names and the writers' keys")
    func attributeNames() throws {
        let composed = "\u{E9}", decomposed = "e\u{301}"
        var keys: [[Unicode.Scalar]] = []
        _ = try DirectedPseudograph<String>(dot: "digraph { node [\"\(composed)\"=1, \"\(decomposed)\"=2] x }".utf8,
                                            vertexAttribute: { _, key, _ in keys.append(Array(key.unicodeScalars)) })
        #expect(keys == [Array(composed.unicodeScalars), Array(decomposed.unicodeScalars)])
        var edgeKeys: [[Unicode.Scalar]] = []
        _ = try DirectedPseudograph<String>(dot: "digraph { edge [\"\(composed)\"=1, \"\(decomposed)\"=2] a -> b }".utf8,
                                            edgeAttribute: { _, key, _ in edgeKeys.append(Array(key.unicodeScalars)) })
        #expect(edgeKeys == [Array(composed.unicodeScalars), Array(decomposed.unicodeScalars)])

        // Data under one name leaves the other name's default in place.
        let graphML = "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">"
            + "<key id=\"a\" for=\"node\" attr.name=\"\(composed)\" attr.type=\"int\"><default>1</default></key>"
            + "<key id=\"b\" for=\"node\" attr.name=\"\(decomposed)\" attr.type=\"int\"><default>2</default></key>"
            + "<graph edgedefault=\"directed\"><node id=\"n\"><data key=\"a\">5</data></node></graph></graphml>"
        var attributes: [([Unicode.Scalar], AttributeValue)] = []
        _ = try DirectedPseudograph<String>(graphML: graphML.utf8, vertexAttribute: { _, key, value in
            attributes.append((Array(key.unicodeScalars), value))
        })
        #expect(attributes.map(\.0) == [Array(composed.unicodeScalars), Array(decomposed.unicodeScalars)])
        #expect(attributes.map(\.1) == [.integer(5), .integer(2)])

        // Writers: two keys, not one key given twice.
        var output = ""
        DirectedPseudograph<String>(vertices: ["n"]).writeGraphML(to: &output, vertexAttributes: { _ in
            [(composed, .integer(1)), (decomposed, .integer(2))]
        })
        #expect(output.ranges(of: "<key ").count == 2)
        output = ""
        DirectedPseudograph<String>(vertices: ["n"]).writeNodeLinkJSON(to: &output, vertexAttributes: { _ in
            [(composed, .integer(1)), (decomposed, .integer(2))]
        })
        #expect(output == "{\"directed\": true, \"multigraph\": false, \"graph\": {}, \"nodes\": [{\"\\u00e9\": 1, \"e\\u0301\": 2, \"id\": \"n\"}], \"edges\": []}")
    }
}
