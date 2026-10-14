// Round trips with shrinking (swift-property-based) for the formats that number their vertices
// (graph6, sparse6, digraph6, DIMACS, METIS): random graphs on the vertices 0..<n are written,
// compared with an encoder written here from the format's definition (nauty's formats.txt for the
// nauty formats), and read back; the reread graph must have the vertices 0..<n and the edges in the
// order the format lists them. See README.md.

import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("GraphFormats round trips of indexed formats, with shrinking", .tags(.randomized))
struct GraphFormatsIndexedRoundTripTests {
    @Test("graph6: the writer matches a bit-by-bit encoder, and the reader gives the edges by column")
    func graph6() async {
        let input = zip(Gen.int(in: 0 ... 70), zip(Gen.int(in: 0 ... 69), Gen.int(in: 0 ... 69)).array(of: 0 ... 40), Gen.bool)
        await propertyCheck(count: 200, input: input) { input in
            let (n, raw, header) = input
            // A simple graph: no loops, each pair once.
            var pairs: [(Int, Int)] = []
            var seen = Set<[Int]>()
            for (a, b) in raw where n > 0 {
                let (u, v) = (a % n, b % n)
                if u != v && seen.insert([min(u, v), max(u, v)]).inserted { pairs.append((u, v)) }
            }
            let graph = Pseudograph<Int>(vertices: Array(0 ..< n), edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // The encoding: N(n), then bit (i, j) for j = 1..<n, i = 0..<j, six to a byte.
            var bits: [Bool] = []
            for j in 0 ..< n {
                for i in 0 ..< j { bits.append(seen.contains([i, j])) }
            }
            while bits.count % 6 != 0 { bits.append(false) }
            var expected = header ? ">>graph6<<" : ""
            if n <= 62 {
                expected.append(Character(Unicode.Scalar(UInt8(n + 63))))
            } else {
                expected += "~" + [12, 6, 0].map { String(Character(Unicode.Scalar(UInt8((n >> $0) & 63 + 63)))) }.joined()
            }
            for k in stride(from: 0, to: bits.count, by: 6) {
                var value = 0
                for b in bits[k ..< k + 6] { value = value << 1 | (b ? 1 : 0) }
                expected.append(Character(Unicode.Scalar(UInt8(value + 63))))
            }
            expected += "\n"
            var output = ""
            try graph.writeGraph6(to: &output, header: header)
            #expect(output == expected)
            let reread = try Pseudograph<Int>(graph6: output.utf8)
            #expect(Array(reread.vertices) == Array(0 ..< n))
            let byColumn = seen.sorted { ($0[1], $0[0]) < ($1[1], $1[0]) }
            #expect(reread.edges.map { [$0.u, $0.v] } == byColumn)
        }
    }

    @Test("digraph6: the writer matches a row-by-row encoder, and the reader gives the arcs by row")
    func digraph6() async {
        let input = zip(Gen.int(in: 0 ... 30), zip(Gen.int(in: 0 ... 29), Gen.int(in: 0 ... 29)).array(of: 0 ... 40), Gen.bool)
        await propertyCheck(count: 200, input: input) { input in
            let (n, raw, header) = input
            var arcs: [(Int, Int)] = []
            var seen = Set<[Int]>()
            for (a, b) in raw where n > 0 && seen.insert([a % n, b % n]).inserted { arcs.append((a % n, b % n)) }
            let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< n), edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            var bits: [Bool] = []
            for i in 0 ..< n {
                for j in 0 ..< n { bits.append(seen.contains([i, j])) }
            }
            while bits.count % 6 != 0 { bits.append(false) }
            var expected = (header ? ">>digraph6<<" : "") + "&" + String(Character(Unicode.Scalar(UInt8(n + 63))))
            for k in stride(from: 0, to: bits.count, by: 6) {
                var value = 0
                for b in bits[k ..< k + 6] { value = value << 1 | (b ? 1 : 0) }
                expected.append(Character(Unicode.Scalar(UInt8(value + 63))))
            }
            expected += "\n"
            var output = ""
            try graph.writeDigraph6(to: &output, header: header)
            #expect(output == expected)
            let reread = try DirectedPseudograph<Int>(digraph6: output.utf8)
            #expect(Array(reread.vertices) == Array(0 ..< n))
            #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] } == seen.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) })
        }
    }

    @Test("sparse6: loops and parallel edges survive, in (larger, smaller) order; the writer matches nauty's encoding")
    func sparse6() async {
        let input = zip(Gen.int(in: 0 ... 70), zip(Gen.int(in: 0 ... 69), Gen.int(in: 0 ... 69)).array(of: 0 ... 30), Gen.bool)
        await propertyCheck(count: 300, input: input) { input in
            let (n, raw, header) = input
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = Pseudograph<Int>(vertices: Array(0 ..< n), edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // nauty's encoding: k bits per number (those of n - 1), the edges by (larger, smaller).
            var k = 0
            while n > 1 && (1 << k) < n { k += 1 }
            let sorted = pairs.map { [max($0.0, $0.1), min($0.0, $0.1)] }.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            var bits: [Bool] = []
            func number(_ x: Int) { for s in stride(from: k - 1, through: 0, by: -1) { bits.append((x >> s) & 1 == 1) } }
            var current = 0
            for edge in sorted {
                let (j, i) = (edge[0], edge[1])
                if j == current {
                    bits.append(false)
                } else if j == current + 1 {
                    bits.append(true)
                    current = j
                } else {
                    bits.append(true)
                    number(j)
                    bits.append(false)
                    current = j
                }
                number(i)
            }
            let pad = (6 - bits.count % 6) % 6
            if pad > 0 && k < 6 && n == 1 << k && sorted.last?[0] == n - 2 && pad >= k + 1 {
                bits.append(false)
                bits += Array(repeating: true, count: pad - 1)
            } else {
                bits += Array(repeating: true, count: pad)
            }
            var expected = (header ? ">>sparse6<<" : "") + ":"
            if n <= 62 {
                expected.append(Character(Unicode.Scalar(UInt8(n + 63))))
            } else {
                expected += "~" + [12, 6, 0].map { String(Character(Unicode.Scalar(UInt8((n >> $0) & 63 + 63)))) }.joined()
            }
            for p in stride(from: 0, to: bits.count, by: 6) {
                var value = 0
                for b in bits[p ..< p + 6] { value = value << 1 | (b ? 1 : 0) }
                expected.append(Character(Unicode.Scalar(UInt8(value + 63))))
            }
            expected += "\n"
            var output = ""
            graph.writeSparse6(to: &output, header: header)
            #expect(output == expected)
            let reread = try Pseudograph<Int>(sparse6: output.utf8)
            #expect(Array(reread.vertices) == Array(0 ..< n))
            #expect(reread.edges.map { [$0.u, $0.v] } == sorted.map { [$0[1], $0[0]] })
        }
    }

    @Test("DIMACS: arcs with their weights, and edges, come back in position order")
    func dimacs() async {
        let input = zip(Gen.int(in: 0 ... 30), zip(Gen.int(in: 0 ... 29), Gen.int(in: 0 ... 29)).array(of: 0 ... 40),
                        Gen.int(in: -1_000 ... 1_000).array(of: 1 ... 5))
        await propertyCheck(count: 200, input: input) { input in
            let (n, raw, weights) = input
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let directed = DirectedPseudograph<Int>(vertices: Array(0 ..< n), edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let weight = { (p: Int) in p == 3 ? Int.min : p == 4 ? Int.max : weights[p % weights.count] }
            var output = ""
            directed.writeDIMACS(to: &output, weight: weight)
            var read: [Int: AttributeValue] = [:]
            let reread = try DirectedPseudograph<Int>(dimacs: output.utf8, edgeAttribute: { p, key, value in
                #expect(key == "weight")
                read[p] = value
            })
            #expect(Array(reread.vertices) == Array(0 ..< n))
            #expect(reread.edges.indices.map { [reread.source(ofEdgeAt: $0), reread.target(ofEdgeAt: $0)] } == pairs.map { [$0.0, $0.1] })
            #expect(read == Dictionary(uniqueKeysWithValues: pairs.indices.map { ($0, AttributeValue.integer(weight($0))) }))
            let undirected = Pseudograph<Int>(vertices: Array(0 ..< n), edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            output = ""
            undirected.writeDIMACS(to: &output)
            let rereadUndirected = try Pseudograph<Int>(dimacs: output.utf8)
            #expect(Array(rereadUndirected.vertices) == Array(0 ..< n))
            #expect(rereadUndirected.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        }
    }

    @Test("METIS: each edge comes back from its smaller end's line, its weight with it")
    func metis() async {
        let input = zip(Gen.int(in: 0 ... 30), zip(Gen.int(in: 0 ... 29), Gen.int(in: 0 ... 29)).array(of: 0 ... 40),
                        Gen.int(in: -1_000 ... 1_000).array(of: 1 ... 5), Gen.bool)
        await propertyCheck(count: 200, input: input) { input in
            let (n, raw, weights, weighted) = input
            var pairs: [(Int, Int)] = []
            var seen = Set<[Int]>()
            for (a, b) in raw where n > 0 {
                let (u, v) = (a % n, b % n)
                if u != v && seen.insert([min(u, v), max(u, v)]).inserted { pairs.append((u, v)) }
            }
            let graph = Pseudograph<Int>(vertices: Array(0 ..< n), edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let weight = { (p: Int) in weights[p % weights.count] }
            var output = ""
            if weighted { try graph.writeMETIS(to: &output, weight: weight) } else { try graph.writeMETIS(to: &output) }
            // The reference: a line per vertex, the far end of each incident edge in position order.
            var expected = "\(n) \(pairs.count)" + (weighted ? " 1" : "") + "\n"
            for u in 0 ..< n {
                var fields: [String] = []
                for (p, (a, b)) in pairs.enumerated() where a == u || b == u {
                    fields.append(String((a == u ? b : a) + 1))
                    if weighted { fields.append(String(weight(p))) }
                }
                expected += fields.joined(separator: " ") + "\n"
            }
            #expect(output == expected)
            var read: [Int: AttributeValue] = [:]
            let reread = try Pseudograph<Int>(metis: output.utf8, edgeAttribute: { p, _, value in read[p] = value })
            #expect(Array(reread.vertices) == Array(0 ..< n))
            let order = pairs.indices.sorted { (min(pairs[$0].0, pairs[$0].1), $0) < (min(pairs[$1].0, pairs[$1].1), $1) }
            #expect(reread.edges.map { [$0.u, $0.v] } == order.map { [min(pairs[$0].0, pairs[$0].1), max(pairs[$0].0, pairs[$0].1)] })
            #expect(read == (weighted ? Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0, AttributeValue.integer(weight($1))) }) : [:]))
        }
    }
}
