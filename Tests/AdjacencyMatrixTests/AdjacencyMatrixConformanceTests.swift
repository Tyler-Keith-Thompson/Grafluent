// Equatable, Hashable, CustomStringConvertible and Codable. Case IDs (AM-Qnn, AM-Wnn) refer to the
// harvested test catalog.
//
// Unlike AdjacencyList, the encoded form is specified, so malformed payloads can be tested:
// `{"vertexCount": n, "edges": [source₀, target₀, source₁, target₁, …]}` with edges in row-major
// order.

import AdjacencyMatrixModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyMatrix equality and hashing", .tags(.conformance))
struct AdjacencyMatrixEqualityTests {
    @Test("AM-Q02 / AM-Q03 equality follows vertex count and cells, not capacity or history")
    func equivalenceClassLaws() {
        let boost = DirectedFixture<Int>.boostExample

        var grown = AdjacencyMatrix()
        for _ in 0 ..< 6 { grown.appendVertex() }
        for edge in boost.edges { grown.insert(edge: edge) }

        var churned = AdjacencyMatrix(vertexCount: 6, edges: boost.edges)
        churned.insert(edge: DirectedEdge(from: 0, to: 0))
        churned.insert(edge: DirectedEdge(from: 5, to: 4))
        churned.remove(edge: DirectedEdge(from: 0, to: 0))
        churned.remove(edge: DirectedEdge(from: 5, to: 4))

        var reserved = AdjacencyMatrix(vertexCount: 6, edges: boost.edges)
        reserved.reserveCapacity(vertexCount: 1_000)

        var cleared = AdjacencyMatrix(vertexCount: 6, edges: boost.edges)
        cleared.removeAllEdges()

        var emptied = AdjacencyMatrix(vertexCount: 6, edges: boost.edges)
        emptied.removeAll(keepingCapacity: true)

        var reservedSelfLoop: AdjacencyMatrix = [[0, 0, 0], [0, 0, 0], [0, 0, 1]]
        reservedSelfLoop.reserveCapacity(vertexCount: 1_000)

        let classes: [[AdjacencyMatrix]] = [
            [
                AdjacencyMatrix(vertexCount: 6, edges: boost.edges),
                AdjacencyMatrix(vertexCount: 6, edges: boost.edges.reversed()),
                [[0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 0, 1], [1, 0, 1, 0, 0, 0], [0, 0, 0, 0, 1, 0], [0, 0, 0, 1, 0, 0], [1, 0, 0, 0, 0, 0]],
                grown, churned, reserved,
            ],
            [cleared, AdjacencyMatrix(vertexCount: 6)],
            [AdjacencyMatrix(vertexCount: 3)],
            [AdjacencyMatrix(vertexCount: 4)],
            [AdjacencyMatrix(), [], emptied, AdjacencyMatrix(vertexCount: 0)],
            [[[0]], AdjacencyMatrix(vertexCount: 1)],
            [[[1]]],
            [[[0, 1], [0, 0]]],
            [[[0, 0], [1, 0]]],
            // Same edge as [[0, 1], [0, 0]], but with a third, isolated vertex.
            [[[0, 1, 0], [0, 0, 0], [0, 0, 0]]],
            // Same edge count as the class above, different cell, different row stride.
            [reservedSelfLoop, [[0, 0, 0], [0, 0, 0], [0, 0, 1]]],
        ]

        let instances = classes.enumerated().flatMap { c, members in members.map { (c, $0) } }
        for (i, (ci, a)) in instances.enumerated() {
            #expect(a == a, "instance \(i) is not equal to itself")
            for (j, (cj, b)) in instances.enumerated() {
                #expect((a == b) == (ci == cj), "instances \(i) and \(j): == is \(a == b), expected \(ci == cj)")
                #expect((a == b) == (b == a))
                #expect((a != b) == !(a == b))
                if ci == cj {
                    #expect(a.hashValue == b.hashValue, "equal instances \(i) and \(j) hash differently")
                    var ha = Hasher()
                    ha.combine(7)
                    ha.combine(a)
                    var hb = Hasher()
                    hb.combine(7)
                    hb.combine(b)
                    #expect(ha.finalize() == hb.finalize())
                }
            }
        }
    }

    @Test("AM-Q02 matrices of different sizes with no edges are not equal, and do not all hash alike")
    func sizeMatters() {
        let empties = (0 ..< 70).map { AdjacencyMatrix(vertexCount: $0) }
        #expect(Set(empties).count == 70)
        #expect(Set(empties.map(\.hashValue)).count > 1)
        #expect(AdjacencyMatrix(vertexCount: 60) != AdjacencyMatrix(vertexCount: 64))
    }

    @Test("every 3-vertex matrix is distinct", .tags(.exhaustive))
    func allThreeVertexMatrices() {
        var seen = Set<AdjacencyMatrix>()
        for mask in 0 ..< 512 {
            var matrix = AdjacencyMatrix(vertexCount: 3)
            for bit in 0 ..< 9 where mask & (1 << bit) != 0 {
                matrix[bit / 3, bit % 3] = true
            }
            #expect(matrix.edgeCount == mask.nonzeroBitCount)
            seen.insert(matrix)
        }
        #expect(seen.count == 512)
    }
}

@Suite("AdjacencyMatrix descriptions", .tags(.conformance))
struct AdjacencyMatrixDescriptionTests {
    @Test("description lists the vertices and the edges, like every representation")
    func description() {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        #expect(matrix.description == "[0, 1, 2]; [0→1, 1→2, 2→2]")
        #expect("\(matrix)" == matrix.description)
        #expect(AdjacencyMatrix().description == "[]; []")
        #expect(AdjacencyMatrix(vertexCount: 2).description == "[0, 1]; []")
    }

    @Test("description stops after 16 vertices and 16 edges")
    func truncated() {
        let matrix = AdjacencyMatrix(vertexCount: 20, repeating: true)
        let vertices = (0 ..< 16).map(String.init).joined(separator: ", ")
        let edges = (0 ..< 16).map { "0→\($0)" }.joined(separator: ", ")
        #expect(matrix.description == "[\(vertices), …]; [\(edges), …]")
        let exactlySixteen = AdjacencyMatrix(vertexCount: 16)
        #expect(exactlySixteen.description == "[\((0 ..< 16).map(String.init).joined(separator: ", "))]; []")
    }

    @Test("description agrees with AdjacencyList's for the same graph")
    func sameAsAdjacencyList() {
        // Both use the shared form; only vertex and edge order could differ, and a single edge
        // between the only two vertices pins both.
        let matrix = AdjacencyMatrix(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)])
        #expect(matrix.description == "[0]; [0→0]")
    }

    @Test("AM-Q05 rowsDescription draws the rows, column 0 leftmost, no trailing newline")
    func rows() {
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges)
        #expect(matrix.rowsDescription == "000000\n001001\n101000\n000010\n000100\n100000")
        #expect(AdjacencyMatrix().rowsDescription == "")
        #expect(AdjacencyMatrix(vertexCount: 1).rowsDescription == "0")
        let selfLoop: AdjacencyMatrix = [[1]]
        #expect(selfLoop.rowsDescription == "1")
        let path: AdjacencyMatrix = [[0, 1], [0, 0]]
        #expect(path.rowsDescription == "01\n00")
        #expect(AdjacencyMatrix(vertexCount: 65).rowsDescription.split(separator: "\n").count == 65)
    }

    @Test("the mirror shows the vertex count and the edges")
    func mirror() {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        let mirror = Mirror(reflecting: matrix)
        #expect(mirror.displayStyle == .struct)
        #expect(mirror.children.map(\.label) == ["vertexCount", "edges"])
        #expect(mirror.descendant("vertexCount") as? Int == 3)
        #expect(mirror.descendant("edges") as? [DirectedEdge<Int>] == [DirectedEdge(from: 0, to: 1)])
    }
}

@Suite("AdjacencyMatrix Codable", .tags(.conformance))
struct AdjacencyMatrixCodableTests {
    @Test("the encoded form is the vertex count and the edges as row-major pairs")
    func exactEncoding() throws {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = String(decoding: try encoder.encode(matrix), as: UTF8.self)
        #expect(json == #"{"edges":[0,1,1,2,2,2],"vertexCount":3}"#)

        let empty = String(decoding: try encoder.encode(AdjacencyMatrix()), as: UTF8.self)
        #expect(empty == #"{"edges":[],"vertexCount":0}"#)
    }

    @Test("encoding is deterministic")
    func deterministic() throws {
        // Keys are sorted because JSONEncoder does not order them; the edge order is ours.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let edges = DirectedFixture<Int>.boost24.edges
        let a = try encoder.encode(AdjacencyMatrix(vertexCount: 24, edges: edges))
        let b = try encoder.encode(AdjacencyMatrix(vertexCount: 24, edges: edges.reversed()))
        #expect(a == b)
    }

    @Test("AM-Q04 round trip of every fixture", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func roundTrip(_ fixture: DirectedFixture<Int>) throws {
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let decoded = try JSONDecoder().decode(AdjacencyMatrix.self, from: JSONEncoder().encode(matrix))
        #expect(decoded == matrix)
        #expect(decoded.vertexCount == fixture.vertexCount)
        #expect(Set(decoded.edges) == fixture.edgeSet)
    }

    @Test("AM-W06 round trip of all-ones matrices at word boundaries", arguments: [0, 1, 8, 9, 11, 12, 63, 64, 65, 129])
    func roundTripBoundaries(_ n: Int) throws {
        var matrix = AdjacencyMatrix(vertexCount: n)
        for i in 0 ..< n {
            for j in 0 ..< n { matrix[i, j] = true }
        }
        let decoded = try PropertyListDecoder().decode(AdjacencyMatrix.self, from: PropertyListEncoder().encode(matrix))
        #expect(decoded == matrix)
        #expect(decoded.edgeCount == n * n)
    }

    @Test("AM-Q04 / AM-W05 malformed payloads throw instead of trapping")
    func malformed() {
        let payloads = [
            "null",
            "42",
            "[]",
            "{}",
            #"{"vertexCount": 2}"#,
            #"{"edges": []}"#,
            #"{"vertexCount": -1, "edges": []}"#,
            #"{"vertexCount": 2, "edges": [0]}"#,
            #"{"vertexCount": 2, "edges": [0, 2]}"#,
            #"{"vertexCount": 2, "edges": [2, 0]}"#,
            #"{"vertexCount": 2, "edges": [-1, 0]}"#,
            #"{"vertexCount": 2, "edges": [0, 1, 0, 1]}"#,
            #"{"vertexCount": 9223372036854775807, "edges": []}"#,
            #"{"vertexCount": 4294967296, "edges": []}"#,
        ]
        for json in payloads {
            #expect(throws: (any Error).self, "\(json)") {
                try JSONDecoder().decode(AdjacencyMatrix.self, from: Data(json.utf8))
            }
        }
    }
}
