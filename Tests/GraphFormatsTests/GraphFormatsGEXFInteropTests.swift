// GEXF beside the catalog rows: a file as NetworkX writes it (its 1.2draft namespace, a meta
// element, every node labelled, every edge with an id and a networkx_key), a round trip through
// the writer with labels, weights, parallel edges and escaping, the writer's errors on a label that
// is not a string and a weight that is not a number, and the defaults budget.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats GEXF interop")
struct GraphFormatsGEXFInteropTests {
    @Test("A file as NetworkX writes it: labels on every node, ids and keys on every edge, a default, a long")
    func networkx() throws {
        let text = """
        <gexf xmlns="http://www.gexf.net/1.2draft" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd" version="1.2">
          <meta lastmodifieddate="2026-10-21">
            <creator>NetworkX 3.7</creator>
          </meta>
          <graph defaultedgetype="directed" mode="static" name="sample">
            <attributes mode="static" class="edge">
              <attribute id="4" title="count" type="long" />
              <attribute id="5" title="networkx_key" type="long" />
            </attributes>
            <attributes mode="static" class="node">
              <attribute id="0" title="score" type="double">
                <default>9.0</default>
              </attribute>
              <attribute id="1" title="ok" type="boolean" />
              <attribute id="2" title="note" type="string" />
              <attribute id="3" title="big" type="long" />
            </attributes>
            <nodes>
              <node id="p" label="Pee">
                <attvalues>
                  <attvalue for="0" value="1.5" />
                  <attvalue for="1" value="true" />
                  <attvalue for="2" value="x&lt;y" />
                  <attvalue for="3" value="5000000000" />
                </attvalues>
              </node>
              <node id="q" label="q" />
            </nodes>
            <edges>
              <edge source="p" target="q" id="0" label="pq" weight="2.5">
                <attvalues>
                  <attvalue for="4" value="7" />
                  <attvalue for="5" value="0" />
                </attvalues>
              </edge>
              <edge source="p" target="q" id="1" weight="1">
                <attvalues>
                  <attvalue for="5" value="1" />
                </attvalues>
              </edge>
              <edge source="q" target="p" id="2">
                <attvalues>
                  <attvalue for="5" value="0" />
                </attvalues>
              </edge>
            </edges>
          </graph>
        </gexf>
        """
        var vertexAttributes: [(String, String, AttributeValue)] = []
        var edgeAttributes: [(Int, String, AttributeValue)] = []
        var graphAttributes: [(String, AttributeValue)] = []
        let graph = try DirectedPseudograph<String>(gexf: Array(text.utf8),
            vertexAttribute: { vertexAttributes.append(($0, $1, $2)) },
            edgeAttribute: { edgeAttributes.append(($0, $1, $2)) },
            graphAttribute: { graphAttributes.append(($0, $1)) })
        #expect(Array(graph.vertices) == ["p", "q"])
        #expect((0 ..< 3).map { "\(graph.source(ofEdgeAt: $0))>\(graph.target(ofEdgeAt: $0))" } == ["p>q", "p>q", "q>p"])
        let v = vertexAttributes.map { "\($0.0).\($0.1)=\($0.2)" }
        #expect(v == ["p.label=Pee", "p.score=1.5", "p.ok=true", "p.note=x<y", "p.big=5000000000", "q.label=q", "q.score=9.0"], "\(v)")
        let e = edgeAttributes.map { "\($0.0).\($0.1)=\($0.2)" }
        #expect(e == ["0.label=pq", "0.weight=2.5", "0.count=7", "0.networkx_key=0", "1.weight=1.0", "1.networkx_key=1", "2.networkx_key=0"], "\(e)")
        #expect(graphAttributes.map { "\($0.0)=\($0.1)" } == ["name=sample"])
        // The same through `vertex:`, and into a simple target, where the parallel pair merges.
        let mapped = try DirectedPseudograph<String>(gexf: Array(text.utf8), vertex: { "v" + $0 })
        #expect(Array(mapped.vertices) == ["vp", "vq"] && mapped.edgeCount == 3)
        let simple = try AdjacencyList<String>(gexf: Array(text.utf8))
        #expect(simple.edgeCount == 2)
    }

    @Test("Write, then read back: labels, weights, parallel edges, a loop, escaping; the undirected form")
    func roundTrip() throws {
        var graph = DirectedPseudograph<String>()
        for v in ["a", "b", "c & d"] { graph.insert(v) }
        _ = graph.insert(edge: DirectedEdge(from: "a", to: "b"))
        _ = graph.insert(edge: DirectedEdge(from: "b", to: "c & d"))
        _ = graph.insert(edge: DirectedEdge(from: "a", to: "b"))
        _ = graph.insert(edge: DirectedEdge(from: "c & d", to: "c & d"))
        let vertexValues: [String: [(key: String, value: AttributeValue)]] = [
            "a": [("label", "Al\"pha"), ("score", 1.5), ("ok", true)], "b": [("score", 2), ("note", "x < y\n")], "c & d": []]
        let edgeValues: [[(key: String, value: AttributeValue)]] = [[("weight", 2.5), ("count", 7)], [("label", "bc"), ("weight", 3)], [], [("count", -1)]]
        var out = ""
        try graph.writeGEXF(to: &out, vertexAttributes: { vertexValues[$0]! }, edgeAttributes: { edgeValues[$0] })
        #expect(out.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gexf xmlns=\"http://www.gexf.net/1.2draft\""))
        #expect(out.contains("<node id=\"a\" label=\"Al&quot;pha\">") && out.contains("<node id=\"c &amp; d\"/>"))
        #expect(out.contains("<edge id=\"1\" source=\"b\" target=\"c &amp; d\" label=\"bc\" weight=\"3\"/>"))
        var vertexAttributes: [(String, String, AttributeValue)] = []
        var edgeAttributes: [(Int, String, AttributeValue)] = []
        let back = try DirectedPseudograph<String>(gexf: Array(out.utf8),
            vertexAttribute: { vertexAttributes.append(($0, $1, $2)) },
            edgeAttribute: { edgeAttributes.append(($0, $1, $2)) })
        #expect(back == graph)
        let v = vertexAttributes.map { "\($0.0).\($0.1)=\($0.2)" }
        #expect(v == ["a.label=Al\"pha", "a.score=1.5", "a.ok=true", "b.score=2.0", "b.note=x < y\n"], "\(v)")
        let e = edgeAttributes.map { "\($0.0).\($0.1)=\($0.2)" }
        #expect(e == ["0.weight=2.5", "0.count=7", "1.label=bc", "1.weight=3.0", "3.count=-1"], "\(e)")

        let undirected = Pseudograph<String>(vertices: ["x", "y"], edges: [UndirectedEdge("y", "x"), UndirectedEdge("x", "x")])
        var text = ""
        try undirected.writeGEXF(to: &text, edgeAttributes: { $0 == 0 ? [("weight", 4)] : [] })
        #expect(text.contains("defaultedgetype=\"undirected\"") && text.contains("<edge id=\"0\" source=\"y\" target=\"x\" weight=\"4\"/>"))
        var weights: [Int: Double] = [:]
        let again = try Pseudograph<String>(gexf: Array(text.utf8), edgeAttribute: { p, _, value in
            if case .double(let w) = value { weights[p] = w }
        })
        #expect(again == undirected && weights == [0: 4])
    }

    @Test("The writer throws invalidValue on a label that is not a string or a weight that is not a number, writing nothing")
    func writerErrors() throws {
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        var out = ""
        #expect(throws: WriteError.invalidValue) { try graph.writeGEXF(to: &out, edgeAttributes: { _ in [("weight", "heavy")] }) }
        #expect(throws: WriteError.invalidValue) { try graph.writeGEXF(to: &out, edgeAttributes: { _ in [("weight", true)] }) }
        #expect(throws: WriteError.invalidValue) { try graph.writeGEXF(to: &out, vertexAttributes: { _ in [("label", 7)] }) }
        #expect(throws: WriteError.invalidValue) { try graph.writeGEXF(to: &out, edgeAttributes: { _ in [("label", 1.5)] }) }
        #expect(throws: WriteError.typeMismatch) { try graph.writeGEXF(to: &out, vertexAttributes: { $0 == "a" ? [("k", 1)] : [("k", "s")] }) }
        #expect(throws: WriteError.duplicateID) { try graph.writeGEXF(to: &out, vertexID: { _ in "same" }) }
        #expect(throws: WriteError.invalidID) { try graph.writeGEXF(to: &out, vertexID: { _ in "\u{1}" }) }
        #expect(throws: WriteError.invalidKey) { try graph.writeGEXF(to: &out, vertexAttributes: { _ in [("\u{2}", 1)] }) }
        #expect(out.isEmpty)
        // A node's weight is an ordinary attribute, and a label that is a string on an edge is fine.
        try graph.writeGEXF(to: &out, vertexAttributes: { _ in [("weight", "w")] }, edgeAttributes: { _ in [("label", "l")] })
        #expect(out.contains("<attribute id=\"0\" title=\"weight\" type=\"string\"/>") && out.contains("label=\"l\""))
    }

    @Test("A default is reported once per element, also when the declaration gives two")
    func defaultOnce() throws {
        let text = "<gexf><graph defaultedgetype=\"directed\"><attributes class=\"node\">"
            + "<attribute id=\"0\" title=\"t\" type=\"integer\"><default>1</default><default>2</default></attribute>"
            + "<attribute id=\"1\" title=\"u\"><default>x</default></attribute></attributes>"
            + "<nodes><node id=\"a\"/><node id=\"b\"><attvalues><attvalue for=\"0\" value=\"7\"/></attvalues></node></nodes></graph></gexf>"
        var calls: [String] = []
        let graph = try DirectedPseudograph<String>(gexf: Array(text.utf8), vertexAttribute: { calls.append("\($0).\($1)=\($2)") })
        #expect(graph.vertexCount == 2)
        #expect(calls == ["a.t=2", "a.u=x", "b.t=7", "b.u=x"])
    }

    @Test("Defaults are bounded by the input: 16 calls a byte (plus 4,096), then limitExceeded at the node", .timeLimit(.minutes(1)))
    func defaultAmplification() throws {
        var text = "<gexf><graph defaultedgetype=\"directed\"><attributes class=\"node\">"
        for k in 0 ..< 2_000 { text += "<attribute id=\"\(k)\" title=\"k\(k)\"><default>x</default></attribute>" }
        text += "</attributes><nodes>"
        var nodeOffsets: [Int] = []
        for i in 0 ..< 50_000 {
            nodeOffsets.append(text.utf8.count)
            text += "<node id=\"n\(i)\"/>"
        }
        text += "</nodes></graph></gexf>"
        let budget = 16 * text.utf8.count + 4_096
        do {
            let graph = try DirectedPseudograph<String>(gexf: text.utf8)
            Issue.record("expected limitExceeded, read \(graph.vertexCount) vertices")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect(error.byteOffset == nodeOffsets[budget / 2_000])
        }
        var count = 0
        var ordinary = "<gexf><graph defaultedgetype=\"directed\"><attributes class=\"node\">"
        for k in 0 ..< 20 { ordinary += "<attribute id=\"\(k)\" title=\"k\(k)\"><default>x</default></attribute>" }
        ordinary += "</attributes><nodes>" + (0 ..< 1_000).map { "<node id=\"n\($0)\"/>" }.joined() + "</nodes></graph></gexf>"
        #expect(try DirectedPseudograph<String>(gexf: ordinary.utf8, vertexAttribute: { _, _, _ in count += 1 }).vertexCount == 1_000)
        #expect(count == 20_000)
    }
}
