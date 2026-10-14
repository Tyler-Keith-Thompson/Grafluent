// METIS (catalog GF-489 – GF-518 read, GF-582 – GF-585 write): the header with its fmt and ncon, one
// line per vertex, every edge listed from both ends, sizes and weights.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats METIS")
struct GraphFormatsMETISTests {
    @Test("GF-489 the METIS manual's graph: unweighted")
    func gf489() throws {
        // Pseudograph<Int>(metis:) → U: 0, 1, 2, 3, 4, 5, 6; 0-4, 0-2, 0-1, 1-2, 1-3, 2-4, 2-3, 3-5, 3-6, 4-5, 5-6
        let input = "7 11\n5 3 2\n1 3 4\n5 4 2 1\n2 3 6 7\n1 3 6\n5 4 7\n6 4\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 11)
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 4], [0, 2], [0, 1], [1, 2], [1, 3], [2, 4], [2, 3], [3, 5], [3, 6], [4, 5], [5, 6]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-490 fmt 1: edge weights")
    func gf490() throws {
        // Pseudograph<Int>(metis:) → U: 0, 1, 2; 0-1{weight=5}, 0-2{weight=1}
        let input = "3 2 1\n2 5 3 1\n1 5\n1 1\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(5)], 1: ["weight": .integer(1)]])
    }

    @Test("GF-491 fmt 011: a vertex weight, then neighbours with edge weights")
    func gf491() throws {
        // Pseudograph<Int>(metis:) → U: 0{weight=4}, 1{weight=2}, 2{weight=0}; 0-1{weight=1}, 1-2{weight=2}
        let input = "3 2 011\n4 2 1\n2 1 1 3 2\n0 2 2\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(vertexKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(vertexValues == [0: ["weight": .integer(4)], 1: ["weight": .integer(2)], 2: ["weight": .integer(0)]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(1)], 1: ["weight": .integer(2)]])
    }

    @Test("GF-492 fmt 110 with ncon 1: a size and a weight per vertex")
    func gf492() throws {
        // Pseudograph<Int>(metis:) → U: 0{size=3, weight=4}, 1{size=5, weight=6}; 0-1
        let input = "2 1 110 1\n3 4 2\n5 6 1\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(vertexKeys == [0: ["size", "weight"], 1: ["size", "weight"]])
        #expect(vertexValues == [0: ["size": .integer(3), "weight": .integer(4)], 1: ["size": .integer(5), "weight": .integer(6)]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-493 comments anywhere; a blank line is a vertex without neighbours; trailing blank lines")
    func gf493() throws {
        // Pseudograph<Int>(metis:) → U: 0, 1, 2; 0-1
        let input = "% header next\n\n3 1\n% vertex 1\n2\n1\n\n\n% done\n\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-494 parallel entries on both sides into a simple target")
    func gf494() throws {
        // UndirectedAdjacencyList<Int>(metis:) → U: 0, 1; 0-1
        let input = "2 2\n2 2\n1 1\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try UndirectedAdjacencyList<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-495 no vertices")
    func gf495() throws {
        // Pseudograph<Int>(metis:) → U:
        let input = "0 0\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.map { [$0.u, $0.v] } == [])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-496 CR LF and tabs")
    func gf496() throws {
        // Pseudograph<Int>(metis:) → U: 0, 1; 0-1
        let input = "2 1\r\n2\r\n1\t\r\n"
        var vertexKeys: [Int: [String]] = [:]
        var vertexValues: [Int: [String: AttributeValue]] = [:]
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(metis: input.utf8, vertexAttribute: { v, key, value in
            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }
        }, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(vertexKeys == [:])
        #expect(vertexValues == [:])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-497 an empty file")
    func gf497() {
        // Pseudograph<Int>(metis:) → **unexpectedEndOfInput** at 1:1
        let input = ""
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-498 a header of one field")
    func gf498() {
        // Pseudograph<Int>(metis:) → **syntax** at 1:2
        let input = "3\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 2, 1])
        }
    }

    @Test("GF-499 a header of five fields")
    func gf499() {
        // Pseudograph<Int>(metis:) → **syntax** at 1:11
        let input = "1 0 010 1 9\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 11, 10])
        }
    }

    @Test("GF-500 a fmt that is not 0s and 1s")
    func gf500() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 1:5
        let input = "1 0 2\n\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 5, 4])
        }
    }

    @Test("GF-501 ncon 2 (unsupported)")
    func gf501() {
        // Pseudograph<Int>(metis:) → **unsupported** at 1:9
        let input = "1 0 010 2\n5 6\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 9, 8])
        }
    }

    @Test("GF-502 ncon 0")
    func gf502() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 1:9
        let input = "1 0 010 0\n\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 9, 8])
        }
    }

    @Test("GF-503 ncon without vertex weights")
    func gf503() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 1:7
        let input = "1 0 1 1\n\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 7, 6])
        }
    }

    @Test("GF-504 a vertex count above the default maximumVertexCount")
    func gf504() {
        // Pseudograph<Int>(metis:) → **limitExceeded** at 1:1
        let input = "16777216 0\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-505 a vertex count above maximumVertexCount")
    func gf505() {
        // Pseudograph<Int>(metis:, maximumVertexCount: 2) → **limitExceeded** at 1:1
        let input = "3 0\n\n\n\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8, maximumVertexCount: 2)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-506 a neighbour 0")
    func gf506() {
        // Pseudograph<Int>(metis:) → **indexOutOfRange** at 2:1
        let input = "2 1\n0\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 4])
        }
    }

    @Test("GF-507 a neighbour beyond n")
    func gf507() {
        // Pseudograph<Int>(metis:) → **indexOutOfRange** at 2:1
        let input = "2 1\n3\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 4])
        }
    }

    @Test("GF-508 a neighbour that is not a number")
    func gf508() {
        // Pseudograph<Int>(metis:) → **syntax** at 2:1
        let input = "2 1\nx\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 4])
        }
    }

    @Test("GF-509 a loop")
    func gf509() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 2:1
        let input = "2 1\n1\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 4])
        }
    }

    @Test("GF-510 a missing edge weight")
    func gf510() {
        // Pseudograph<Int>(metis:) → **syntax** at 2:2
        let input = "2 1 1\n2\n1 1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 2, 7])
        }
    }

    @Test("GF-511 an edge weight that is not an integer")
    func gf511() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 2:3
        let input = "2 1 1\n2 x\n1 1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 8])
        }
    }

    @Test("GF-512 a missing vertex weight")
    func gf512() {
        // Pseudograph<Int>(metis:) → **syntax** at 2:1
        let input = "2 1 010\n\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 8])
        }
    }

    @Test("GF-513 fewer vertex lines than n")
    func gf513() {
        // Pseudograph<Int>(metis:) → **unexpectedEndOfInput** at 4:1
        let input = "3 1\n2\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 8])
        }
    }

    @Test("GF-514 a line after the last vertex")
    func gf514() {
        // Pseudograph<Int>(metis:) → **syntax** at 3:1
        let input = "1 0\n\n5\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 5])
        }
    }

    @Test("GF-515 an edge listed on one side only")
    func gf515() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 2:1
        let input = "3 1\n2\n\n\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 4])
        }
    }

    @Test("GF-516 a lower entry with no mirror")
    func gf516() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 3:3
        let input = "3 1\n2\n1 3\n\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [3, 3, 8])
        }
    }

    @Test("GF-517 weights that differ on the two sides")
    func gf517() {
        // Pseudograph<Int>(metis:) → **invalidValue** at 3:1
        let input = "2 1 1\n2 1\n1 2\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 10])
        }
    }

    @Test("GF-518 an edge count that is not m")
    func gf518() {
        // Pseudograph<Int>(metis:) → **entryCountMismatch** at 1:3
        let input = "2 2\n2\n1\n"
        do {
            let graph = try Pseudograph<Int>(metis: input.utf8)
            Issue.record("expected entryCountMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .entryCountMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 3, 2])
        }
    }

    @Test("GF-582 unweighted: neighbours in the order of the incident edges")
    func gf582() throws {
        // writeMETIS(to:) on U: 0, 1, 2, 3; 0-1, 2-0, 1-2
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 0), UndirectedEdge(1, 2)])
        var output = ""
        try graph.writeMETIS(to: &output)
        #expect(output == "4 3\n2 3\n1 3\n1 2\n\n")
    }

    @Test("GF-583 edge weights: fmt 1")
    func gf583() throws {
        // writeMETIS(to:, weight: [5, -3]) on U: 0, 1, 2; 0-1, 2-1
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1)])
        let weights: [Int] = [5, -3]
        var output = ""
        try graph.writeMETIS(to: &output, weight: { weights[$0] })
        #expect(output == "3 2 1\n2 5\n1 5 3 -3\n2 -3\n")
    }

    @Test("GF-584 isolated vertices are empty lines")
    func gf584() throws {
        // writeMETIS(to:) on U: 0, 1, 2; 2-0
        let graph = Pseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(2, 0)])
        var output = ""
        try graph.writeMETIS(to: &output)
        #expect(output == "3 1\n3\n\n1\n")
    }

    @Test("GF-585 no vertices")
    func gf585() throws {
        // writeMETIS(to:) on U:
        let graph = Pseudograph<String>()
        var output = ""
        try graph.writeMETIS(to: &output)
        #expect(output == "0 0\n")
    }
}
