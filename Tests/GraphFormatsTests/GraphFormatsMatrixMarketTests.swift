// Matrix Market (catalog GF-111 – GF-146, GF-230, GF-232, GF-247, GF-249 – GF-251, GF-257 read, GF-207
// – GF-214 write): coordinate matrices into vertices 0..<n, symmetric files into either kind, weights
// under "weight"; ref.py checks the write rows byte for byte against SciPy's mmwrite.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats Matrix Market")
struct GraphFormatsMatrixMarketTests {
    @Test("GF-111 general pattern: an arc per entry, row to column")
    func gf111() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1, 2; 0>1, 2>0
        let input = "%%MatrixMarket matrix coordinate pattern general\n3 3 2\n1 2\n3 1\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [2, 0]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-112 integer weights")
    func gf112() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1; 0>1{weight=-5}, 1>1{weight=7}
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 2\n1 2 -5\n2 2 7\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 1]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(-5)], 1: ["weight": .integer(7)]])
    }

    @Test("GF-113 real weights; comments, blank lines, CR LF, tabs")
    func gf113() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1, 2; 0>1{weight=0.5}, 2>2{weight=-1000.0}
        let input = "%%MatrixMarket matrix coordinate real general\r\n% comment\r\n\r\n3 3 2\r\n1\t2  0.5\r\n\r\n3 3 -1e3\r\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [2, 2]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(0.5)], 1: ["weight": .double(-1000.0)]])
    }

    @Test("GF-114 symmetric into an undirected target: an edge per entry")
    func gf114() throws {
        // Pseudograph<Int>(matrixMarket:) → U: 0, 1, 2; 1-0{weight=4}, 2-2{weight=1}, 2-1{weight=6}
        let input = "%%MatrixMarket matrix coordinate integer symmetric\n3 3 3\n2 1 4\n3 3 1\n3 2 6\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 0], [2, 2], [2, 1]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(4)], 1: ["weight": .integer(1)], 2: ["weight": .integer(6)]])
    }

    @Test("GF-115 symmetric into a directed target: both arcs, a diagonal entry once")
    func gf115() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1, 2; 1>0{weight=4}, 0>1{weight=4}, 2>2{weight=1}
        let input = "%%MatrixMarket matrix coordinate integer symmetric\n3 3 2\n2 1 4\n3 3 1\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 0], [0, 1], [2, 2]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(4)], 1: ["weight": .integer(4)], 2: ["weight": .integer(1)]])
    }

    @Test("GF-116 skew-symmetric: the mirrored arc has the negated weight")
    func gf116() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1; 1>0{weight=1.5}, 0>1{weight=-1.5}
        let input = "%%MatrixMarket matrix coordinate real skew-symmetric\n2 2 1\n2 1 1.5\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 0], [0, 1]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["weight": .double(1.5)], 1: ["weight": .double(-1.5)]])
    }

    @Test("GF-117 vertices 0..<n even without entries")
    func gf117() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1, 2, 3; 0>1
        let input = "%%MatrixMarket matrix coordinate pattern general\n4 4 1\n1 2\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-118 duplicate entries are parallel edges")
    func gf118() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1; 0>1{weight=5}, 0>1{weight=7}
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 2\n1 2 5\n1 2 7\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [0, 1]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(5)], 1: ["weight": .integer(7)]])
    }

    @Test("GF-119 simple target: duplicate entries merge, last weight wins")
    func gf119() throws {
        // AdjacencyList<Int>(matrixMarket:) → D: 0, 1; 0>1{weight=7}
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 2\n1 2 5\n1 2 7\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try AdjacencyList<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(edgeKeys == [0: ["weight"]])
        #expect(edgeValues == [0: ["weight": .integer(7)]])
    }

    @Test("GF-120 Infinity and NaN (SciPy writes them)")
    func gf120() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1; 0>1{weight=inf}, 1>0{weight=-inf}, 0>0{weight=nan}
        let input = "%%MatrixMarket matrix coordinate real general\n2 2 3\n1 2 Infinity\n2 1 -inf\n1 1 NaN\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.edges.indices) == [0, 1, 2])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1], [1, 0], [0, 0]])
        #expect(edgeKeys == [0: ["weight"], 1: ["weight"], 2: ["weight"]])
        #expect(edgeValues.count == 3)
        #expect(edgeValues[0]?["weight"] == .double(.infinity))
        #expect(edgeValues[1]?["weight"] == .double(-.infinity))
        #expect({ if case .double(let x)? = edgeValues[2]?["weight"] { x.isNaN } else { false } }())
    }

    @Test("GF-121 qualifiers are case-insensitive")
    func gf121() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1; 0>1
        let input = "%%MatrixMarket MATRIX Coordinate PATTERN General\n2 2 1\n1 2\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-122 an upper-triangle entry in a symmetric file")
    func gf122() throws {
        // Pseudograph<Int>(matrixMarket:) → U: 0, 1, 2; 0-2
        let input = "%%MatrixMarket matrix coordinate pattern symmetric\n3 3 1\n1 3\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try Pseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-123 empty matrix")
    func gf123() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D:
        let input = "%%MatrixMarket matrix coordinate pattern general\n0 0 0\n"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.edges.indices) == [])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-124 no newline at the end")
    func gf124() throws {
        // DirectedPseudograph<Int>(matrixMarket:) → D: 0, 1; 1>0
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n2 1"
        var edgeKeys: [Int: [String]] = [:]
        var edgeValues: [Int: [String: AttributeValue]] = [:]
        let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8, edgeAttribute: { e, key, value in
            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }
        })
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(edgeKeys == [:])
        #expect(edgeValues == [:])
    }

    @Test("GF-125 missing banner")
    func gf125() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 1:1
        let input = "3 3 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-126 banner is case-sensitive (mmio.c)")
    func gf126() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 1:1
        let input = "%%MATRIXMARKET matrix coordinate pattern general\n1 1 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [1, 1, 0])
        }
    }

    @Test("GF-127 array format (unsupported)")
    func gf127() {
        // DirectedPseudograph<Int>(matrixMarket:) → **unsupported** at 1:23
        let input = "%%MatrixMarket matrix array real general\n2 2\n1\n0\n0\n1\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 23, 22])
        }
    }

    @Test("GF-128 complex (unsupported)")
    func gf128() {
        // DirectedPseudograph<Int>(matrixMarket:) → **unsupported** at 1:34
        let input = "%%MatrixMarket matrix coordinate complex general\n1 1 1\n1 1 1 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 34, 33])
        }
    }

    @Test("GF-129 hermitian (unsupported)")
    func gf129() {
        // DirectedPseudograph<Int>(matrixMarket:) → **unsupported** at 1:39
        let input = "%%MatrixMarket matrix coordinate real hermitian\n1 1 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 39, 38])
        }
    }

    @Test("GF-130 vector (unsupported)")
    func gf130() {
        // DirectedPseudograph<Int>(matrixMarket:) → **unsupported** at 1:16
        let input = "%%MatrixMarket vector coordinate real general\n3 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected unsupported, read \(graph)")
        } catch {
            #expect(error.kind == .unsupported)
            #expect([error.line, error.column, error.byteOffset] == [1, 16, 15])
        }
    }

    @Test("GF-131 general into an undirected target")
    func gf131() {
        // Pseudograph<Int>(matrixMarket:) → **kindMismatch** at 1:42
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 0\n"
        do {
            let graph = try Pseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected kindMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .kindMismatch)
            #expect([error.line, error.column, error.byteOffset] == [1, 42, 41])
        }
    }

    @Test("GF-132 not square")
    func gf132() {
        // DirectedPseudograph<Int>(matrixMarket:) → **notSquare** at 2:3
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 3 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected notSquare, read \(graph)")
        } catch {
            #expect(error.kind == .notSquare)
            #expect([error.line, error.column, error.byteOffset] == [2, 3, 51])
        }
    }

    @Test("GF-133 index 0")
    func gf133() {
        // DirectedPseudograph<Int>(matrixMarket:) → **indexOutOfRange** at 3:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n0 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 55])
        }
    }

    @Test("GF-134 index beyond n")
    func gf134() {
        // DirectedPseudograph<Int>(matrixMarket:) → **indexOutOfRange** at 3:3
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1 3\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected indexOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .indexOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [3, 3, 57])
        }
    }

    @Test("GF-135 fewer entries than declared")
    func gf135() {
        // DirectedPseudograph<Int>(matrixMarket:) → **entryCountMismatch** at 4:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 2\n1 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected entryCountMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .entryCountMismatch)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 59])
        }
    }

    @Test("GF-136 more entries than declared")
    func gf136() {
        // DirectedPseudograph<Int>(matrixMarket:) → **entryCountMismatch** at 4:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1 2\n2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected entryCountMismatch, read \(graph)")
        } catch {
            #expect(error.kind == .entryCountMismatch)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 59])
        }
    }

    @Test("GF-137 an extra column")
    func gf137() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:7
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 1\n1 2 5 6\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 7, 61])
        }
    }

    @Test("GF-138 a missing value")
    func gf138() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:4
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 1\n1 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 4, 58])
        }
    }

    @Test("GF-139 integer field with a fraction")
    func gf139() {
        // DirectedPseudograph<Int>(matrixMarket:) → **invalidValue** at 3:5
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 1\n1 2 3.5\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [3, 5, 59])
        }
    }

    @Test("GF-140 hexadecimal float")
    func gf140() {
        // DirectedPseudograph<Int>(matrixMarket:) → **invalidValue** at 3:5
        let input = "%%MatrixMarket matrix coordinate real general\n2 2 1\n1 2 0x1p3\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [3, 5, 56])
        }
    }

    @Test("GF-141 integer value beyond Int64")
    func gf141() {
        // DirectedPseudograph<Int>(matrixMarket:) → **numberOutOfRange** at 3:5
        let input = "%%MatrixMarket matrix coordinate integer general\n2 2 1\n1 2 99999999999999999999\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [3, 5, 59])
        }
    }

    @Test("GF-142 a comment after the size line")
    func gf142() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 4:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 2\n1 2\n% c\n2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [4, 1, 59])
        }
    }

    @Test("GF-143 skew-symmetric diagonal entry")
    func gf143() {
        // DirectedPseudograph<Int>(matrixMarket:) → **invalidValue** at 3:1
        let input = "%%MatrixMarket matrix coordinate real skew-symmetric\n2 2 1\n2 2 1\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 59])
        }
    }

    @Test("GF-144 pattern skew-symmetric")
    func gf144() {
        // DirectedPseudograph<Int>(matrixMarket:) → **invalidValue** at 1:42
        let input = "%%MatrixMarket matrix coordinate pattern skew-symmetric\n2 2 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected invalidValue, read \(graph)")
        } catch {
            #expect(error.kind == .invalidValue)
            #expect([error.line, error.column, error.byteOffset] == [1, 42, 41])
        }
    }

    @Test("GF-145 no size line")
    func gf145() {
        // DirectedPseudograph<Int>(matrixMarket:) → **unexpectedEndOfInput** at 3:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n% only\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected unexpectedEndOfInput, read \(graph)")
        } catch {
            #expect(error.kind == .unexpectedEndOfInput)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 56])
        }
    }

    @Test("GF-146 signed index")
    func gf146() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n+1 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 55])
        }
    }

    @Test("GF-207 pattern, general, entries in edge order")
    func gf207() {
        // writeMatrixMarket(to:) on D: 0, 1, 2; 1>0, 0>1, 2>0, 2>1, 2>2, 2>0, 0>2
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        var output = ""
        graph.writeMatrixMarket(to: &output)
        #expect(output == "%%MatrixMarket matrix coordinate pattern general\n%\n3 3 7\n2 1\n1 2\n3 1\n3 2\n3 3\n3 1\n1 3\n")
    }

    #if _pointerBitWidth(_64)
    @Test("GF-208 integer weights")
    func gf208() {
        // writeMatrixMarket(to:, weight: [1, -2, 3, 4, 5, 6, 9223372036854775807]) on D: 0, 1, 2; 1>0, 0>1, 2>0, 2>1, 2>2, 2>0, 0>2
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        let weights: [Int] = [1, -2, 3, 4, 5, 6, 9223372036854775807]
        var output = ""
        graph.writeMatrixMarket(to: &output, weight: { weights[$0] })
        #expect(output == "%%MatrixMarket matrix coordinate integer general\n%\n3 3 7\n2 1 1\n1 2 -2\n3 1 3\n3 2 4\n3 3 5\n3 1 6\n1 3 9223372036854775807\n")
    }
    #endif

    @Test("GF-209 real weights: SciPy's number format")
    func gf209() {
        // writeMatrixMarket(to:, weight: [1.0, 0.1, 1234.5, -2.0, 1e-07, 1e+20, 1.152921504606847e+18]) on D: 0, 1, 2; 1>0, 0>1, 2>0, 2>1, 2>2, 2>0, 0>2
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        let weights: [Double] = [1.0, 0.1, 1234.5, -2.0, 1e-07, 1e+20, 1.152921504606847e+18]
        var output = ""
        graph.writeMatrixMarket(to: &output, weight: { weights[$0] })
        #expect(output == "%%MatrixMarket matrix coordinate real general\n%\n3 3 7\n2 1 1\n1 2 1E-1\n3 1 1.2345E3\n3 2 -2\n3 3 1E-7\n3 1 1E20\n1 3 1.152921504606847E18\n")
    }

    @Test("GF-210 non-finite and signed zero")
    func gf210() {
        // writeMatrixMarket(to:, weight: [inf, nan, -0.0, -inf]) on D: 0, 1; 0>1, 1>0, 0>0, 1>1
        let graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1)])
        let weights: [Double] = [.infinity, .nan, -0.0, -.infinity]
        var output = ""
        graph.writeMatrixMarket(to: &output, weight: { weights[$0] })
        #expect(output == "%%MatrixMarket matrix coordinate real general\n%\n2 2 4\n1 2 Infinity\n2 1 NaN\n1 1 -0\n2 2 -Infinity\n")
    }

    @Test("GF-211 undirected: symmetric, lower triangle")
    func gf211() {
        // writeMatrixMarket(to:) on U: 0, 1, 2, 3; 0-1, 2-1, 2-2, 1-0
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1), UndirectedEdge(2, 2), UndirectedEdge(1, 0)])
        var output = ""
        graph.writeMatrixMarket(to: &output)
        #expect(output == "%%MatrixMarket matrix coordinate pattern symmetric\n%\n4 4 4\n2 1\n3 2\n3 3\n2 1\n")
    }

    @Test("GF-212 undirected with weights")
    func gf212() {
        // writeMatrixMarket(to:, weight: [0.5, 2.0, 3.0, 4.0]) on U: 0, 1, 2, 3; 0-1, 2-1, 2-2, 1-0
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 1), UndirectedEdge(2, 2), UndirectedEdge(1, 0)])
        let weights: [Double] = [0.5, 2.0, 3.0, 4.0]
        var output = ""
        graph.writeMatrixMarket(to: &output, weight: { weights[$0] })
        #expect(output == "%%MatrixMarket matrix coordinate real symmetric\n%\n4 4 4\n2 1 5E-1\n3 2 2\n3 3 3\n2 1 4\n")
    }

    @Test("GF-213 empty graph")
    func gf213() {
        // writeMatrixMarket(to:) on D:
        let graph = DirectedPseudograph<String>()
        var output = ""
        graph.writeMatrixMarket(to: &output)
        #expect(output == "%%MatrixMarket matrix coordinate pattern general\n%\n0 0 0\n")
    }

    @Test("GF-214 isolated vertices count in the size line")
    func gf214() {
        // writeMatrixMarket(to:) on D: 0, 1, 2, 3; 3>0
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 3, to: 0)])
        var output = ""
        graph.writeMatrixMarket(to: &output)
        #expect(output == "%%MatrixMarket matrix coordinate pattern general\n%\n4 4 1\n4 1\n")
    }

    @Test("GF-230 skew-symmetric: a mirrored weight outside Int")
    func gf230() {
        // DirectedPseudograph<Int>(matrixMarket:) → **numberOutOfRange** at 3:5
        let input = "%%MatrixMarket matrix coordinate integer skew-symmetric\n2 2 1\n2 1 -9223372036854775808\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected numberOutOfRange, read \(graph)")
        } catch {
            #expect(error.kind == .numberOutOfRange)
            #expect([error.line, error.column, error.byteOffset] == [3, 5, 66])
        }
    }

    @Test("GF-232 a vertex count above the default maximumVertexCount (16 a byte plus 4,096)")
    func gf232() {
        // DirectedPseudograph<Int>(matrixMarket:) → **limitExceeded** at 2:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n16777217 16777217 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 49])
        }
    }

    @Test("GF-247 pattern: a third field on an entry")
    func gf247() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:5
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1 2 3\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 5, 59])
        }
    }

    @Test("GF-249 a lone CR inside a field")
    func gf249() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1\r2 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 55])
        }
    }

    @Test("GF-250 a comment of several words after the size line")
    func gf250() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n% a b\n1 2\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 1, 55])
        }
    }

    @Test("GF-251 an entry cut short before CR LF")
    func gf251() {
        // DirectedPseudograph<Int>(matrixMarket:) → **syntax** at 3:2
        let input = "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1\r\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected syntax, read \(graph)")
        } catch {
            #expect(error.kind == .syntax)
            #expect([error.line, error.column, error.byteOffset] == [3, 2, 56])
        }
    }

    @Test("GF-257 a 69-byte file claiming 2^24 vertices is over the default maximumVertexCount")
    func gf257() {
        // DirectedPseudograph<Int>(matrixMarket:) → **limitExceeded** at 2:1
        let input = "%%MatrixMarket matrix coordinate pattern general\n16777216 16777216 0\n"
        do {
            let graph = try DirectedPseudograph<Int>(matrixMarket: input.utf8)
            Issue.record("expected limitExceeded, read \(graph)")
        } catch {
            #expect(error.kind == .limitExceeded)
            #expect([error.line, error.column, error.byteOffset] == [2, 1, 49])
        }
    }
}
