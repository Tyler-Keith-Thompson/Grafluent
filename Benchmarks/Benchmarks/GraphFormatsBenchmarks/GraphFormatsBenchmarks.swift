import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import CompressedSparseRowModule
import GraphFormats
import GraphProtocols
import Multigraphs

// Targets and baselines: Tests/Catalogs/GraphFormats/api.md, Performance (ref.py --bench: NetworkX
// 3.7, SciPy 1.18.1 and pydot 4.0.1 on a random directed graph of 10⁵ vertices and 10⁶ edges with
// a double weight per edge; DOT on 10⁴ vertices and 10⁵ edges without attributes). Inputs, in
// bytes: edge list 31,046,379, adjacency list 6,477,453, GraphML 102,335,652, node-link 77,535,342,
// Matrix Market 32,935,902, DOT 1,546,734, Mermaid 22,866,796.
//
// Parse-only rows read the same text with one bad line appended (an entry too many, a one-field
// line, trailing text after the document): the line formats collect the whole file before
// building, node-link JSON reads it in one pass that checks it as it goes, and GraphML's first walk
// checks it while noting its nodes and edges (the work its second walk did), so each throws after
// parsing all of it and before building anything. Throughput is input bytes over that time.

/// A `TextOutputStream` that keeps only the byte count, so a write measures the writer.
struct ByteCounter: TextOutputStream {
    var count = 0
    mutating func write(_ string: String) { count += string.utf8.count }
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(3)
    Benchmark.defaultConfiguration.maxIterations = 10

    let n = 100_000
    let edges = Inputs.randomEdges(vertexCount: n, edgeCount: 1_000_000, seed: 1)
    let graph = DirectedPseudograph(vertices: 0 ..< n, edges: edges)
    var rng = SeededRandomNumberGenerator(seed: 2)
    let weights = (0 ..< edges.count).map { _ in Double.random(in: 0 ..< 1, using: &rng) }
    let small = DirectedPseudograph(vertices: 0 ..< 10_000, edges: Inputs.randomEdges(vertexCount: 10_000, edgeCount: 100_000, seed: 3))

    var edgeList = ""
    graph.writeEdgeList(to: &edgeList, columns: ["weight"], edgeAttributes: { [("weight", .double(weights[$0]))] })
    var adjacencyList = ""
    graph.writeAdjacencyList(to: &adjacencyList)
    var graphML = ""
    graph.writeGraphML(to: &graphML, edgeAttributes: { [("weight", .double(weights[$0]))] })
    var nodeLink = ""
    graph.writeNodeLinkJSON(to: &nodeLink, edgeAttributes: { [("weight", .double(weights[$0]))] })
    var matrixMarket = ""
    graph.writeMatrixMarket(to: &matrixMarket, weight: { weights[$0] })
    var dot = ""
    small.writeDOT(to: &dot)
    var mermaid = ""
    graph.writeMermaid(to: &mermaid, vertexID: { "v\($0)" })

    // MARK: Edge list (NetworkX: write 1,455 ms, read 3,588 ms; targets 20× and 30×)

    Benchmark("GraphFormats: writeEdgeList, 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var out = ByteCounter()
            graph.writeEdgeList(to: &out, columns: ["weight"], edgeAttributes: { [("weight", .double(weights[$0]))] })
            blackHole(out)
        }
    }
    Benchmark("GraphFormats: DirectedPseudograph<Int>(edgeList:columns:), 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var read = [Double](repeating: 0, count: edges.count)
            let g = try DirectedPseudograph<Int>(edgeList: edgeList.utf8, columns: ["weight"], edgeAttribute: { e, _, value in
                if case .double(let w) = value { read[e] = w }
            })
            blackHole((g, read))
        }
    }

    Benchmark("GraphFormats: parse only, edge list with Int vertices and a weight column, 10⁶ lines") { benchmark in
        let text = edgeList + "x\n"
        for _ in benchmark.scaledIterations {
            blackHole(try? DirectedPseudograph<Int>(edgeList: text.utf8, columns: ["weight"], edgeAttribute: { _, _, _ in }))
        }
    }
    Benchmark("GraphFormats: Pseudograph<Int>(edgeList:columns:), 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var read = [Double](repeating: 0, count: edges.count)
            let g = try Pseudograph<Int>(edgeList: edgeList.utf8, columns: ["weight"], edgeAttribute: { e, _, value in
                if case .double(let w) = value { read[e] = w }
            })
            blackHole((g, read))
        }
    }

    // MARK: Adjacency list (NetworkX: write 211 ms, read 1,789 ms)

    Benchmark("GraphFormats: writeAdjacencyList, 10⁶ edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var out = ByteCounter()
            graph.writeAdjacencyList(to: &out)
            blackHole(out)
        }
    }
    Benchmark("GraphFormats: DirectedPseudograph<Int>(adjacencyList:), 10⁶ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try DirectedPseudograph<Int>(adjacencyList: adjacencyList.utf8)) }
    }

    Benchmark("GraphFormats: parse only, adjacency list, 10⁶ edges") { benchmark in
        let text = adjacencyList + "x\n"
        for _ in benchmark.scaledIterations { blackHole(try? DirectedPseudograph<Int>(adjacencyList: text.utf8)) }
    }

    // MARK: GraphML (NetworkX: write 9,279 ms, read 11,097 ms; target 20×)

    Benchmark("GraphFormats: writeGraphML, 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var out = ByteCounter()
            graph.writeGraphML(to: &out, edgeAttributes: { [("weight", .double(weights[$0]))] })
            blackHole(out)
        }
    }
    Benchmark("GraphFormats: DirectedPseudograph<String>(graphML:), 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var read = [Double](repeating: 0, count: edges.count)
            let g = try DirectedPseudograph<String>(graphML: graphML.utf8, edgeAttribute: { e, _, value in
                if case .double(let w) = value { read[e] = w }
            })
            blackHole((g, read))
        }
    }

    Benchmark("GraphFormats: parse only, GraphML (the well-formedness walk), 10⁶ weighted edges") { benchmark in
        let text = graphML + "x"
        for _ in benchmark.scaledIterations { blackHole(try? DirectedPseudograph<String>(graphML: text.utf8)) }
    }

    // MARK: Node-link JSON (NetworkX + json: write 1,036 ms, read 2,494 ms; target 10×)

    Benchmark("GraphFormats: writeNodeLinkJSON, 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var out = ByteCounter()
            graph.writeNodeLinkJSON(to: &out, edgeAttributes: { [("weight", .double(weights[$0]))] })
            blackHole(out)
        }
    }
    Benchmark("GraphFormats: DirectedPseudograph<Int>(nodeLinkJSON:), 10⁶ weighted edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var read = [Double](repeating: 0, count: edges.count)
            let g = try DirectedPseudograph<Int>(nodeLinkJSON: nodeLink.utf8, edgeAttribute: { e, _, value in
                if case .double(let w) = value { read[e] = w }
            })
            blackHole((g, read))
        }
    }

    Benchmark("GraphFormats: parse only, node-link JSON (the document check), 10⁶ weighted edges") { benchmark in
        let text = nodeLink + "x"
        for _ in benchmark.scaledIterations { blackHole(try? DirectedPseudograph<Int>(nodeLinkJSON: text.utf8)) }
    }

    // MARK: Matrix Market (SciPy, one thread: mmwrite 127 ms, mmread 68 ms; target within 1.5×)

    Benchmark("GraphFormats: writeMatrixMarket(weight:), 10⁶ real entries") { benchmark in
        for _ in benchmark.scaledIterations {
            var out = ByteCounter()
            graph.writeMatrixMarket(to: &out, weight: { weights[$0] })
            blackHole(out)
        }
    }
    Benchmark("GraphFormats: DirectedPseudograph<Int>(matrixMarket:), 10⁶ real entries") { benchmark in
        for _ in benchmark.scaledIterations {
            var read = [Double](repeating: 0, count: edges.count)
            let g = try DirectedPseudograph<Int>(matrixMarket: matrixMarket.utf8, edgeAttribute: { e, _, value in
                if case .double(let w) = value { read[e] = w }
            })
            blackHole((g, read))
        }
    }
    Benchmark("GraphFormats: AdjacencyList<Int>(matrixMarket:), 10⁶ real entries") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try AdjacencyList<Int>(matrixMarket: matrixMarket.utf8)) }
    }
    Benchmark("GraphFormats: parse only, Matrix Market, 10⁶ real entries") { benchmark in
        let text = matrixMarket + "1 1 0.5\n"
        for _ in benchmark.scaledIterations {
            blackHole(try? DirectedPseudograph<Int>(matrixMarket: text.utf8, edgeAttribute: { _, _, _ in }))
        }
    }
    Benchmark("GraphFormats: parse + build, CompressedSparseRow(AdjacencyList<Int>(matrixMarket:)), 10⁶ real entries") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(try AdjacencyList<Int>(matrixMarket: matrixMarket.utf8)))
        }
    }
    Benchmark("GraphFormats: parse + build, CompressedSparseRow(AdjacencyList<Int>(matrixMarket:)), pattern, 10⁶ entries") { benchmark in
        var pattern = ""
        graph.writeMatrixMarket(to: &pattern)
        for _ in benchmark.scaledIterations {
            blackHole(CompressedSparseRow(try AdjacencyList<Int>(matrixMarket: pattern.utf8)))
        }
    }

    // MARK: DOT (pydot: write 568 ms, read 51,335 ms on 10⁵ edges; target 50×)

    Benchmark("GraphFormats: writeDOT, 10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var out = ByteCounter()
            small.writeDOT(to: &out)
            blackHole(out)
        }
    }
    Benchmark("GraphFormats: DirectedPseudograph<String>(dot:), 10⁵ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try DirectedPseudograph<String>(dot: dot.utf8)) }
    }

    // MARK: Mermaid (no baseline; target ≥ 100 MB/s read)

    Benchmark("GraphFormats: DirectedPseudograph<String>(mermaid:), 10⁶ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(try DirectedPseudograph<String>(mermaid: mermaid.utf8)) }
    }
}
