// Large files, each inside a Task with a one-minute limit and an explicit bound on its own time,
// meant to finish in a few seconds in a debug build; the benchmarks take timings. Every expected
// value is known by construction: 10⁵-edge graphs with a weight per edge written and read back in
// every format, a megabyte-long string in one ID and one label, and a 2 MB output checked against
// the 64 KiB buffer contract of the writers. See README.md.

import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats at scale")
struct GraphFormatsStressTests {
    @Test("10⁵ weighted arcs through the edge list, Matrix Market and node-link JSON", .timeLimit(.minutes(1)))
    func weightedArcs() async throws {
        try await Task {
            let clock = ContinuousClock()
            let start = clock.now
            let n = 20_000, m = 100_000
            var edges: [DirectedEdge<Int>] = []
            edges.reserveCapacity(m)
            for k in 0 ..< m { edges.append(DirectedEdge(from: k % n, to: (k * 7_919 + 13) % n)) }
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: edges)
            let weights = (0 ..< m).map { Double($0 % 1_000) / 8 - 60 }

            var edgeList = ""
            try graph.writeEdgeList(to: &edgeList, columns: ["weight"], edgeAttributes: { [("weight", .double(weights[$0]))] })
            var listWeights = [Double](repeating: .nan, count: m)
            do {
                let reread = try DirectedPseudograph<Int>(edgeList: edgeList.utf8, columns: ["weight"], edgeAttribute: { e, _, value in
                    if case .double(let w) = value { listWeights[e] = w }
                })
                #expect(reread.vertexCount == n && reread.edgeCount == m)
                #expect(reread.edges.indices.allSatisfy { reread.edges[$0] == edges[$0] })
                #expect(listWeights == weights)
            } catch {
                Issue.record("edge list: \(error)")
            }

            var matrix = ""
            graph.writeMatrixMarket(to: &matrix, weight: { weights[$0] })
            #expect(matrix.hasPrefix("%%MatrixMarket matrix coordinate real general\n%\n20000 20000 100000\n"))
            var matrixWeights = [Double](repeating: .nan, count: m)
            do {
                let reread = try DirectedPseudograph<Int>(matrixMarket: matrix.utf8, edgeAttribute: { e, _, value in
                    if case .double(let w) = value { matrixWeights[e] = w }
                })
                #expect(Array(reread.vertices) == Array(0 ..< n) && reread.edgeCount == m)
                #expect(reread.edges.indices.allSatisfy { reread.edges[$0] == edges[$0] })
                #expect(matrixWeights == weights)
            } catch {
                Issue.record("Matrix Market: \(error)")
            }

            var json = ""
            try graph.writeNodeLinkJSON(to: &json, edgeAttributes: { [("w", .double(weights[$0]))] })
            var jsonWeights = [Double](repeating: .nan, count: m)
            do {
                let reread = try DirectedPseudograph<Int>(nodeLinkJSON: json.utf8, edgeAttribute: { e, _, value in
                    if case .double(let w) = value { jsonWeights[e] = w }
                })
                #expect(Array(reread.vertices) == Array(0 ..< n) && reread.edgeCount == m)
                #expect(reread.edges.indices.allSatisfy { reread.edges[$0] == edges[$0] })
                #expect(jsonWeights == weights)
            } catch {
                Issue.record("node-link JSON: \(error)")
            }
            #expect(clock.now - start < .seconds(45))
        }.value
    }

    @Test("10⁵ labelled arcs through DOT, GraphML, the adjacency list and Mermaid", .timeLimit(.minutes(1)))
    func labelledArcs() async throws {
        try await Task {
            let clock = ContinuousClock()
            let start = clock.now
            let n = 10_000, m = 100_000
            let names = (0 ..< n).map { "v\($0)" }
            var edges: [DirectedEdge<String>] = []
            edges.reserveCapacity(m)
            for k in 0 ..< m { edges.append(DirectedEdge(from: names[k % n], to: names[(k * 7_919 + 13) % n])) }
            let graph = DirectedPseudograph<String>(vertices: names, edges: edges)

            var dot = ""
            try graph.writeDOT(to: &dot, edgeAttributes: { [("label", .string("e \($0)"))] })
            var dotLabels = [String](repeating: "", count: m)
            do {
                let reread = try DirectedPseudograph<String>(dot: dot.utf8, edgeAttribute: { e, _, value in
                    if case .string(let s) = value { dotLabels[e] = s }
                })
                #expect(Array(reread.vertices) == names && reread.edgeCount == m)
                #expect(reread.edges.indices.allSatisfy { reread.edges[$0] == edges[$0] })
                #expect(dotLabels == (0 ..< m).map { "e \($0)" })
            } catch {
                Issue.record("DOT: \(error)")
            }

            var graphML = ""
            try graph.writeGraphML(to: &graphML, edgeAttributes: { [("n", .integer($0))] })
            var graphMLValues = [Int](repeating: -1, count: m)
            do {
                let reread = try DirectedPseudograph<String>(graphML: graphML.utf8, edgeAttribute: { e, _, value in
                    if case .integer(let x) = value { graphMLValues[e] = x }
                })
                #expect(Array(reread.vertices) == names && reread.edgeCount == m)
                #expect(reread.edges.indices.allSatisfy { reread.edges[$0] == edges[$0] })
                #expect(graphMLValues == Array(0 ..< m))
            } catch {
                Issue.record("GraphML: \(error)")
            }

            var adjacency = ""
            try graph.writeAdjacencyList(to: &adjacency)
            do {
                let reread = try DirectedPseudograph<String>(adjacencyList: adjacency.utf8)
                #expect(reread.vertexCount == n && reread.edgeCount == m)
                #expect(Set(names.map { reread.outDegree(of: $0) }) == [10])
            } catch {
                Issue.record("adjacency list: \(error)")
            }

            var mermaid = ""
            try graph.writeMermaid(to: &mermaid, edgeLabel: { $0.isMultiple(of: 2) ? "#\($0)" : nil })
            var mermaidLabels: [Int: String] = [:]
            do {
                let reread = try DirectedPseudograph<String>(mermaid: mermaid.utf8, edgeLabel: { mermaidLabels[$0] = $1 })
                #expect(Array(reread.vertices) == names && reread.edgeCount == m)
                #expect(reread.edges.indices.allSatisfy { reread.edges[$0] == edges[$0] })
                #expect(mermaidLabels.count == m / 2 && mermaidLabels[99_998] == "#99998")
            } catch {
                Issue.record("Mermaid: \(error)")
            }
            #expect(clock.now - start < .seconds(45))
        }.value
    }

    @Test("A megabyte in one ID and one label, in every format that carries strings", .timeLimit(.minutes(1)))
    func longStrings() async throws {
        try await Task {
            let clock = ContinuousClock()
            let start = clock.now
            let long = String(repeating: "ab\"\\é<&>#\n", count: 100_000)
            let token = String(repeating: "é", count: 500_000)
            let graph = DirectedPseudograph<String>(vertices: [long, "b"], edges: [DirectedEdge(from: long, to: "b")])
            for format in ["dot", "graphML", "nodeLinkJSON"] {
                var output = ""
                var labels: [String] = []
                do {
                    let reread: DirectedPseudograph<String>
                    switch format {
                    case "dot":
                        try graph.writeDOT(to: &output, edgeAttributes: { _ in [("label", .string(long))] })
                        reread = try DirectedPseudograph<String>(dot: output.utf8, edgeAttribute: { if case .string(let s) = $2 { labels.append(s) } })
                    case "graphML":
                        try graph.writeGraphML(to: &output, edgeAttributes: { _ in [("label", .string(long))] })
                        reread = try DirectedPseudograph<String>(graphML: output.utf8, edgeAttribute: { if case .string(let s) = $2 { labels.append(s) } })
                    default:
                        try graph.writeNodeLinkJSON(to: &output, edgeAttributes: { _ in [("label", .string(long))] })
                        reread = try DirectedPseudograph<String>(nodeLinkJSON: output.utf8, edgeAttribute: { if case .string(let s) = $2 { labels.append(s) } })
                    }
                    #expect(Array(reread.vertices) == [long, "b"], "\(format)")
                    #expect(labels == [long], "\(format)")
                } catch {
                    Issue.record("\(format): \(error)")
                }
            }
            var list = ""
            try DirectedPseudograph<String>(edges: [DirectedEdge(from: token, to: "b")]).writeEdgeList(to: &list)
            #expect(list.utf8.count == 1_000_003)
            do {
                let reread = try DirectedPseudograph<String>(edgeList: list.utf8)
                #expect(Array(reread.vertices) == [token, "b"])
            } catch {
                Issue.record("edge list: \(error)")
            }
            var mermaid = ""
            try DirectedPseudograph<String>(vertices: ["A"]).writeMermaid(to: &mermaid, vertexLabel: { _ in long })
            var label: String?
            do {
                _ = try DirectedPseudograph<String>(mermaid: mermaid.utf8, vertexLabel: { label = $1 })
                #expect(label == long)
            } catch {
                Issue.record("Mermaid: \(error)")
            }
            #expect(clock.now - start < .seconds(45))
        }.value
    }

    @Test("A 2 MB output reaches the stream in pieces of at most 64 KiB, mostly full, and in order", .timeLimit(.minutes(1)))
    func bufferedOutput() async throws {
        try await Task {
            struct Recorder: TextOutputStream {
                var pieces: [String] = []
                mutating func write(_ string: String) { pieces.append(string) }
            }
            let n = 100_000
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
            var recorder = Recorder()
            var whole = ""
            try graph.writeDOT(to: &recorder, vertexAttributes: { [("é", .integer($0))] })
            try graph.writeDOT(to: &whole, vertexAttributes: { [("é", .integer($0))] })
            let size = whole.utf8.count
            #expect(size > 2_000_000)
            #expect(recorder.pieces.joined() == whole)
            #expect(recorder.pieces.allSatisfy { !$0.isEmpty && $0.utf8.count <= 65_536 })
            #expect(recorder.pieces.count <= size / 32_768 + 1)
            #expect(recorder.pieces.count >= size / 65_536)
        }.value
    }
}
