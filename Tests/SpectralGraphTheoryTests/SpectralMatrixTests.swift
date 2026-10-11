// Matrices (catalog SGT-001 – SGT-046): A with an undirected loop adding 2, L = D − A with loops
// cancelling, N and L_rw with zero rows at degree 0, Q = D + A; parallel edges and weights adding
// up, weight 0 storing nothing, rows in `vertices` order; directed A and L over out-degrees. Each
// matrix is pinned as its exact CSR arrays, its stored values, every entry (n ≤ 8) and `pattern`.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory matrices")
struct SpectralMatrixTests {
    @Test("SGT-001 empty graph")
    func sgt001() {
        // U: · laplacianMatrix() → 0×0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 0)
        #expect(matrix.nonzeroCount == 0)
        #expect(matrix.offsets == [0])
        #expect(matrix.columns == [] as [Int])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = []
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 0)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
    }

    @Test("SGT-002 one vertex: a 1×1 zero matrix, no stored entries")
    func sgt002() {
        // U: [0] · laplacianMatrix() → [[0]] (nnz 0)
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 1)
        #expect(matrix.nonzeroCount == 0)
        #expect(matrix.offsets == [0, 0])
        #expect(matrix.columns == [] as [Int])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = []
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 1)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0],
        ]
        for i in 0 ..< 1 {
            for j in 0 ..< 1 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-003 path on 3 vertices")
    func sgt003() {
        // U: P(0,1,2) · adjacencyMatrix() → [[0, 1, 0], [1, 0, 1], [0, 1, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 1, 3, 4])
        #expect(matrix.columns == [1, 0, 2, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, 1, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, 1, 0],
            [1, 0, 1],
            [0, 1, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-004 path on 3 vertices")
    func sgt004() {
        // U: P(0,1,2) · laplacianMatrix() → [[1, -1, 0], [-1, 2, -1], [0, -1, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -1, 2, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-1, 2, -1],
            [0, -1, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-005 path on 3 vertices")
    func sgt005() {
        // U: P(0,1,2) · normalizedLaplacianMatrix() → [[1, -0.7071067812, 0], [-0.7071067812, 1, -0.7071067812], [0, -0.7071067812, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -0.70710678118655, -0.70710678118655, 1, -0.70710678118655, -0.70710678118655, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -0.70710678118655, 0],
            [-0.70710678118655, 1, -0.70710678118655],
            [0, -0.70710678118655, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-006 path on 3 vertices")
    func sgt006() {
        // U: P(0,1,2) · randomWalkLaplacianMatrix() → [[1, -1, 0], [-1/2 (-0.5), 1, -1/2 (-0.5)], [0, -1, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.randomWalkLaplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -0.5, 1, -0.5, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-0.5, 1, -0.5],
            [0, -1, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-007 path on 3 vertices")
    func sgt007() {
        // U: P(0,1,2) · signlessLaplacianMatrix() → [[1, 1, 0], [1, 2, 1], [0, 1, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.signlessLaplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, 1, 1, 2, 1, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, 1, 0],
            [1, 2, 1],
            [0, 1, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-008 K4 Laplacian")
    func sgt008() {
        // U: K(4) · laplacianMatrix() → [[3, -1, -1, -1], [-1, 3, -1, -1], [-1, -1, 3, -1], [-1, -1, -1, 3]] (nnz 16)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 4)
        #expect(matrix.nonzeroCount == 16)
        #expect(matrix.offsets == [0, 4, 8, 12, 16])
        #expect(matrix.columns == [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            3, -1, -1, -1, -1, 3, -1, -1,
            -1, -1, 3, -1, -1, -1, -1, 3,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 4)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [3, -1, -1, -1],
            [-1, 3, -1, -1],
            [-1, -1, 3, -1],
            [-1, -1, -1, 3],
        ]
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-009 K4 normalized Laplacian")
    func sgt009() {
        // U: K(4) · normalizedLaplacianMatrix() → [[1, -0.3333333333, -0.3333333333, -0.3333333333], [-0.3333333333, 1, -0.3333333333, -0.3333333333], [-0.3333333333, -0.3333333333, 1, -0.3333333333], [-0.33…
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 4)
        #expect(matrix.nonzeroCount == 16)
        #expect(matrix.offsets == [0, 4, 8, 12, 16])
        #expect(matrix.columns == [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            1, -0.33333333333333, -0.33333333333333, -0.33333333333333, -0.33333333333333, 1, -0.33333333333333, -0.33333333333333,
            -0.33333333333333, -0.33333333333333, 1, -0.33333333333333, -0.33333333333333, -0.33333333333333, -0.33333333333333, 1,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 4)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -0.33333333333333, -0.33333333333333, -0.33333333333333],
            [-0.33333333333333, 1, -0.33333333333333, -0.33333333333333],
            [-0.33333333333333, -0.33333333333333, 1, -0.33333333333333],
            [-0.33333333333333, -0.33333333333333, -0.33333333333333, 1],
        ]
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-010 star K1,3 normalized Laplacian")
    func sgt010() {
        // U: S(0;1..3) · normalizedLaplacianMatrix() → [[1, -0.5773502692, -0.5773502692, -0.5773502692], [-0.5773502692, 1, 0, 0], [-0.5773502692, 0, 1, 0], [-0.5773502692, 0, 0, 1]] (nnz 10)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 4)
        #expect(matrix.nonzeroCount == 10)
        #expect(matrix.offsets == [0, 4, 6, 8, 10])
        #expect(matrix.columns == [0, 1, 2, 3, 0, 1, 0, 2, 0, 3])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            1, -0.57735026918963, -0.57735026918963, -0.57735026918963, -0.57735026918963, 1, -0.57735026918963, 1,
            -0.57735026918963, 1,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 4)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -0.57735026918963, -0.57735026918963, -0.57735026918963],
            [-0.57735026918963, 1, 0, 0],
            [-0.57735026918963, 0, 1, 0],
            [-0.57735026918963, 0, 0, 1],
        ]
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-011 rows follow `vertices` order, not vertex values")
    func sgt011() {
        // U: [2,0,1] 2-0, 0-1 · laplacianMatrix() → [[1, -1, 0], [-1, 2, -1], [0, -1, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(2, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: [2, 0, 1], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -1, 2, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-1, 2, -1],
            [0, -1, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-012 rows follow `vertices` order: adjacency")
    func sgt012() {
        // U: [2,0,1] 2-0, 0-1 · adjacencyMatrix() → [[0, 1, 0], [1, 0, 1], [0, 1, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(2, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: [2, 0, 1], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 1, 3, 4])
        #expect(matrix.columns == [1, 0, 2, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, 1, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, 1, 0],
            [1, 0, 1],
            [0, 1, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-013 parallel edges add up")
    func sgt013() {
        // U: 0=1, 1-2 · adjacencyMatrix() → [[0, 2, 0], [2, 0, 1], [0, 1, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 1, 3, 4])
        #expect(matrix.columns == [1, 0, 2, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, 2, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, 2, 0],
            [2, 0, 1],
            [0, 1, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-014 parallel edges add up")
    func sgt014() {
        // U: 0=1, 1-2 · laplacianMatrix() → [[2, -2, 0], [-2, 3, -1], [0, -1, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, -2, -2, 3, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [2, -2, 0],
            [-2, 3, -1],
            [0, -1, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-015 parallel edges add up")
    func sgt015() {
        // U: 0=1, 1-2 · normalizedLaplacianMatrix() → [[1, -0.8164965809, 0], [-0.8164965809, 1, -0.5773502692], [0, -0.5773502692, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -0.81649658092773, -0.81649658092773, 1, -0.57735026918963, -0.57735026918963, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -0.81649658092773, 0],
            [-0.81649658092773, 1, -0.57735026918963],
            [0, -0.57735026918963, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-016 self-loop: 2 on the diagonal of A, cancels in L")
    func sgt016() {
        // U: 0-0, 0-1 · adjacencyMatrix() → [[2, 1], [1, 0]] (nnz 3)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 3)
        #expect(matrix.offsets == [0, 2, 3])
        #expect(matrix.columns == [0, 1, 0])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [2, 1],
            [1, 0],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-017 self-loop: 2 on the diagonal of A, cancels in L")
    func sgt017() {
        // U: 0-0, 0-1 · laplacianMatrix() → [[1, -1], [-1, 1]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1],
            [-1, 1],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-018 self-loop: 2 on the diagonal of A, cancels in L")
    func sgt018() {
        // U: 0-0, 0-1 · normalizedLaplacianMatrix() → [[0.3333333333, -0.5773502692], [-0.5773502692, 1]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [0.33333333333333, -0.57735026918963, -0.57735026918963, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0.33333333333333, -0.57735026918963],
            [-0.57735026918963, 1],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-019 self-loop: 2 on the diagonal of A, cancels in L")
    func sgt019() {
        // U: 0-0, 0-1 · randomWalkLaplacianMatrix() → [[1/3 (0.3333333333), -1/3 (-0.3333333333)], [-1, 1]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.randomWalkLaplacianMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [0.33333333333333, -0.33333333333333, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0.33333333333333, -0.33333333333333],
            [-1, 1],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-020 self-loop: 2 on the diagonal of A, cancels in L")
    func sgt020() {
        // U: 0-0, 0-1 · signlessLaplacianMatrix() → [[5, 1], [1, 1]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.signlessLaplacianMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [5, 1, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [5, 1],
            [1, 1],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-021 bouquet of two loops: A = [[4]], L = 0")
    func sgt021() {
        // U: 0-0, 0-0 · adjacencyMatrix() → [[4]] (nnz 1)
        let edges: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 1)
        #expect(matrix.nonzeroCount == 1)
        #expect(matrix.offsets == [0, 1])
        #expect(matrix.columns == [0])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [4]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 1)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [4],
        ]
        for i in 0 ..< 1 {
            for j in 0 ..< 1 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-022 bouquet of two loops: normalized Laplacian is 0")
    func sgt022() {
        // U: 0-0, 0-0 · normalizedLaplacianMatrix() → [[0]] (nnz 0)
        let edges: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 1)
        #expect(matrix.nonzeroCount == 0)
        #expect(matrix.offsets == [0, 0])
        #expect(matrix.columns == [] as [Int])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = []
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 1)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0],
        ]
        for i in 0 ..< 1 {
            for j in 0 ..< 1 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-023 isolated vertex: zero row in the normalized Laplacian")
    func sgt023() {
        // U: [0,1,2] 0-1 · normalizedLaplacianMatrix() → [[1, -1, 0], [-1, 1, 0], [0, 0, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-1, 1, 0],
            [0, 0, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-024 isolated vertex: zero row in the random-walk Laplacian")
    func sgt024() {
        // U: [0,1,2] 0-1 · randomWalkLaplacianMatrix() → [[1, -1, 0], [-1, 1, 0], [0, 0, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.randomWalkLaplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-1, 1, 0],
            [0, 0, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-025 weighted path")
    func sgt025() {
        // U: P(0,1,2) · adjacencyMatrix(weight:) [2, 0.5] → [[0, 2, 0], [2, 0, 1/2 (0.5)], [0, 1/2 (0.5), 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [2, 0.5]
        let matrix = graph.adjacencyMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 1, 3, 4])
        #expect(matrix.columns == [1, 0, 2, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, 2, 0.5, 0.5]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, 2, 0],
            [2, 0, 0.5],
            [0, 0.5, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-026 weighted path")
    func sgt026() {
        // U: P(0,1,2) · laplacianMatrix(weight:) [2, 0.5] → [[2, -2, 0], [-2, 5/2 (2.5), -1/2 (-0.5)], [0, -1/2 (-0.5), 1/2 (0.5)]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [2, 0.5]
        let matrix = graph.laplacianMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, -2, -2, 2.5, -0.5, -0.5, 0.5]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [2, -2, 0],
            [-2, 2.5, -0.5],
            [0, -0.5, 0.5],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-027 weighted path")
    func sgt027() {
        // U: P(0,1,2) · normalizedLaplacianMatrix(weight:) [2, 0.5] → [[1, -0.894427191, 0], [-0.894427191, 1, -0.4472135955], [0, -0.4472135955, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [2, 0.5]
        let matrix = graph.normalizedLaplacianMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -0.89442719099992, -0.89442719099992, 1, -0.44721359549996, -0.44721359549996, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -0.89442719099992, 0],
            [-0.89442719099992, 1, -0.44721359549996],
            [0, -0.44721359549996, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-028 weighted path")
    func sgt028() {
        // U: P(0,1,2) · randomWalkLaplacianMatrix(weight:) [2, 0.5] → [[1, -1, 0], [-4/5 (-0.8), 1, -1/5 (-0.2)], [0, -1, 1]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [2, 0.5]
        let matrix = graph.randomWalkLaplacianMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 2, 5, 7])
        #expect(matrix.columns == [0, 1, 0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -0.8, 1, -0.2, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-0.8, 1, -0.2],
            [0, -1, 1],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-029 weight 0: no stored entry")
    func sgt029() {
        // U: P(0,1,2) · laplacianMatrix(weight:) [1, 0] → [[1, -1, 0], [-1, 1, 0], [0, 0, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 0]
        let matrix = graph.laplacianMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1, -1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [-1, 1, 0],
            [0, 0, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-030 parallel weights add up")
    func sgt030() {
        // U: 0=1 · laplacianMatrix(weight:) [1.5, 2.5] → [[4, -4], [-4, 4]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [1.5, 2.5]
        let matrix = graph.laplacianMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 2, 4])
        #expect(matrix.columns == [0, 1, 0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [4, -4, -4, 4]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [4, -4],
            [-4, 4],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-031 adjacency allows negative weights")
    func sgt031() {
        // U: P(0,1,2) · adjacencyMatrix(weight:) [-1, 2] → [[0, -1, 0], [-1, 0, 2], [0, 2, 0]] (nnz 4)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [-1, 2]
        let matrix = graph.adjacencyMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 4)
        #expect(matrix.offsets == [0, 1, 3, 4])
        #expect(matrix.columns == [1, 0, 2, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [-1, -1, 2, 2]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, -1, 0],
            [-1, 0, 2],
            [0, 2, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-036 grid 10×10 Laplacian (invariants)")
    func sgt036() {
        // U: grid(10,10) · laplacianMatrix() → 100×100, nnz 460, trace 360, Σ entries 0, Σ entries² 1688
        let edges: [(Int, Int)] = [
            (0, 1), (0, 10), (1, 2), (1, 11), (2, 3), (2, 12), (3, 4), (3, 13), (4, 5), (4, 14), (5, 6), (5, 15),
            (6, 7), (6, 16), (7, 8), (7, 17), (8, 9), (8, 18), (9, 19), (10, 11), (10, 20), (11, 12), (11, 21), (12, 13),
            (12, 22), (13, 14), (13, 23), (14, 15), (14, 24), (15, 16), (15, 25), (16, 17), (16, 26), (17, 18), (17, 27), (18, 19),
            (18, 28), (19, 29), (20, 21), (20, 30), (21, 22), (21, 31), (22, 23), (22, 32), (23, 24), (23, 33), (24, 25), (24, 34),
            (25, 26), (25, 35), (26, 27), (26, 36), (27, 28), (27, 37), (28, 29), (28, 38), (29, 39), (30, 31), (30, 40), (31, 32),
            (31, 41), (32, 33), (32, 42), (33, 34), (33, 43), (34, 35), (34, 44), (35, 36), (35, 45), (36, 37), (36, 46), (37, 38),
            (37, 47), (38, 39), (38, 48), (39, 49), (40, 41), (40, 50), (41, 42), (41, 51), (42, 43), (42, 52), (43, 44), (43, 53),
            (44, 45), (44, 54), (45, 46), (45, 55), (46, 47), (46, 56), (47, 48), (47, 57), (48, 49), (48, 58), (49, 59), (50, 51),
            (50, 60), (51, 52), (51, 61), (52, 53), (52, 62), (53, 54), (53, 63), (54, 55), (54, 64), (55, 56), (55, 65), (56, 57),
            (56, 66), (57, 58), (57, 67), (58, 59), (58, 68), (59, 69), (60, 61), (60, 70), (61, 62), (61, 71), (62, 63), (62, 72),
            (63, 64), (63, 73), (64, 65), (64, 74), (65, 66), (65, 75), (66, 67), (66, 76), (67, 68), (67, 77), (68, 69), (68, 78),
            (69, 79), (70, 71), (70, 80), (71, 72), (71, 81), (72, 73), (72, 82), (73, 74), (73, 83), (74, 75), (74, 84), (75, 76),
            (75, 85), (76, 77), (76, 86), (77, 78), (77, 87), (78, 79), (78, 88), (79, 89), (80, 81), (80, 90), (81, 82), (81, 91),
            (82, 83), (82, 92), (83, 84), (83, 93), (84, 85), (84, 94), (85, 86), (85, 95), (86, 87), (86, 96), (87, 88), (87, 97),
            (88, 89), (88, 98), (89, 99), (90, 91), (91, 92), (92, 93), (93, 94), (94, 95), (95, 96), (96, 97), (97, 98), (98, 99),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 100), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 100)
        #expect(matrix.nonzeroCount == 460)
        #expect(matrix.offsets == [
            0, 3, 7, 11, 15, 19, 23, 27, 31, 35, 38, 42, 47, 52, 57, 62, 67, 72, 77, 82, 86, 90, 95, 100,
            105, 110, 115, 120, 125, 130, 134, 138, 143, 148, 153, 158, 163, 168, 173, 178, 182, 186, 191, 196, 201, 206, 211, 216,
            221, 226, 230, 234, 239, 244, 249, 254, 259, 264, 269, 274, 278, 282, 287, 292, 297, 302, 307, 312, 317, 322, 326, 330,
            335, 340, 345, 350, 355, 360, 365, 370, 374, 378, 383, 388, 393, 398, 403, 408, 413, 418, 422, 425, 429, 433, 437, 441,
            445, 449, 453, 457, 460,
        ])
        #expect(matrix.columns == [
            0, 1, 10, 0, 1, 2, 11, 1, 2, 3, 12, 2, 3, 4, 13, 3, 4, 5, 14, 4, 5, 6, 15, 5,
            6, 7, 16, 6, 7, 8, 17, 7, 8, 9, 18, 8, 9, 19, 0, 10, 11, 20, 1, 10, 11, 12, 21, 2,
            11, 12, 13, 22, 3, 12, 13, 14, 23, 4, 13, 14, 15, 24, 5, 14, 15, 16, 25, 6, 15, 16, 17, 26,
            7, 16, 17, 18, 27, 8, 17, 18, 19, 28, 9, 18, 19, 29, 10, 20, 21, 30, 11, 20, 21, 22, 31, 12,
            21, 22, 23, 32, 13, 22, 23, 24, 33, 14, 23, 24, 25, 34, 15, 24, 25, 26, 35, 16, 25, 26, 27, 36,
            17, 26, 27, 28, 37, 18, 27, 28, 29, 38, 19, 28, 29, 39, 20, 30, 31, 40, 21, 30, 31, 32, 41, 22,
            31, 32, 33, 42, 23, 32, 33, 34, 43, 24, 33, 34, 35, 44, 25, 34, 35, 36, 45, 26, 35, 36, 37, 46,
            27, 36, 37, 38, 47, 28, 37, 38, 39, 48, 29, 38, 39, 49, 30, 40, 41, 50, 31, 40, 41, 42, 51, 32,
            41, 42, 43, 52, 33, 42, 43, 44, 53, 34, 43, 44, 45, 54, 35, 44, 45, 46, 55, 36, 45, 46, 47, 56,
            37, 46, 47, 48, 57, 38, 47, 48, 49, 58, 39, 48, 49, 59, 40, 50, 51, 60, 41, 50, 51, 52, 61, 42,
            51, 52, 53, 62, 43, 52, 53, 54, 63, 44, 53, 54, 55, 64, 45, 54, 55, 56, 65, 46, 55, 56, 57, 66,
            47, 56, 57, 58, 67, 48, 57, 58, 59, 68, 49, 58, 59, 69, 50, 60, 61, 70, 51, 60, 61, 62, 71, 52,
            61, 62, 63, 72, 53, 62, 63, 64, 73, 54, 63, 64, 65, 74, 55, 64, 65, 66, 75, 56, 65, 66, 67, 76,
            57, 66, 67, 68, 77, 58, 67, 68, 69, 78, 59, 68, 69, 79, 60, 70, 71, 80, 61, 70, 71, 72, 81, 62,
            71, 72, 73, 82, 63, 72, 73, 74, 83, 64, 73, 74, 75, 84, 65, 74, 75, 76, 85, 66, 75, 76, 77, 86,
            67, 76, 77, 78, 87, 68, 77, 78, 79, 88, 69, 78, 79, 89, 70, 80, 81, 90, 71, 80, 81, 82, 91, 72,
            81, 82, 83, 92, 73, 82, 83, 84, 93, 74, 83, 84, 85, 94, 75, 84, 85, 86, 95, 76, 85, 86, 87, 96,
            77, 86, 87, 88, 97, 78, 87, 88, 89, 98, 79, 88, 89, 99, 80, 90, 91, 81, 90, 91, 92, 82, 91, 92,
            93, 83, 92, 93, 94, 84, 93, 94, 95, 85, 94, 95, 96, 86, 95, 96, 97, 87, 96, 97, 98, 88, 97, 98,
            99, 89, 98, 99,
        ])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            2, -1, -1, -1, 3, -1, -1, -1,
            3, -1, -1, -1, 3, -1, -1, -1,
            3, -1, -1, -1, 3, -1, -1, -1,
            3, -1, -1, -1, 3, -1, -1, -1,
            3, -1, -1, -1, 2, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 3,
            -1, -1, -1, -1, 4, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, 4, -1,
            -1, -1, -1, 4, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, 4, -1, -1, -1, -1, 4,
            -1, -1, -1, -1, 3, -1, -1, 2,
            -1, -1, -1, 3, -1, -1, -1, 3,
            -1, -1, -1, 3, -1, -1, -1, 3,
            -1, -1, -1, 3, -1, -1, -1, 3,
            -1, -1, -1, 3, -1, -1, -1, 3,
            -1, -1, -1, 2,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 100)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // The catalog's invariants: trace, Σ entries, Σ entries².
        let trace = (0 ..< 100).reduce(0.0) { $0 + matrix[$1, $1] }
        #expect(abs(trace - 360) <= 1e-9 * max(1, 360))
        #expect(abs(matrix.values.reduce(0, +) - 0) <= 1e-9 * max(1, 1688))
        #expect(abs(matrix.values.reduce(0) { $0 + $1 * $1 } - 1688) <= 1e-9 * max(1, 1688))
    }

    @Test("SGT-037 hypercube Q4 normalized Laplacian (invariants)")
    func sgt037() {
        // U: Q(4) · normalizedLaplacianMatrix() → 16×16, nnz 80, trace 16, Σ entries 0, Σ entries² 20
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 4), (0, 8), (1, 3), (1, 5), (1, 9), (2, 3), (2, 6), (2, 10), (3, 7), (3, 11),
            (4, 5), (4, 6), (4, 12), (5, 7), (5, 13), (6, 7), (6, 14), (7, 15), (8, 9), (8, 10), (8, 12), (9, 11),
            (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (12, 14), (13, 15), (14, 15),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 16), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.normalizedLaplacianMatrix()
        #expect(matrix.rowCount == 16)
        #expect(matrix.nonzeroCount == 80)
        #expect(matrix.offsets == [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80])
        #expect(matrix.columns == [
            0, 1, 2, 4, 8, 0, 1, 3, 5, 9, 0, 2, 3, 6, 10, 1, 2, 3, 7, 11, 0, 4, 5, 6,
            12, 1, 4, 5, 7, 13, 2, 4, 6, 7, 14, 3, 5, 6, 7, 15, 0, 8, 9, 10, 12, 1, 8, 9,
            11, 13, 2, 8, 10, 11, 14, 3, 9, 10, 11, 15, 4, 8, 12, 13, 14, 5, 9, 12, 13, 15, 6, 10,
            12, 14, 15, 7, 11, 13, 14, 15,
        ])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            1, -0.25, -0.25, -0.25, -0.25, -0.25, 1, -0.25,
            -0.25, -0.25, -0.25, 1, -0.25, -0.25, -0.25, -0.25,
            -0.25, 1, -0.25, -0.25, -0.25, 1, -0.25, -0.25,
            -0.25, -0.25, -0.25, 1, -0.25, -0.25, -0.25, -0.25,
            1, -0.25, -0.25, -0.25, -0.25, -0.25, 1, -0.25,
            -0.25, 1, -0.25, -0.25, -0.25, -0.25, -0.25, 1,
            -0.25, -0.25, -0.25, -0.25, 1, -0.25, -0.25, -0.25,
            -0.25, -0.25, 1, -0.25, -0.25, -0.25, 1, -0.25,
            -0.25, -0.25, -0.25, -0.25, 1, -0.25, -0.25, -0.25,
            -0.25, 1, -0.25, -0.25, -0.25, -0.25, -0.25, 1,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 16)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // The catalog's invariants: trace, Σ entries, Σ entries².
        let trace = (0 ..< 16).reduce(0.0) { $0 + matrix[$1, $1] }
        #expect(abs(trace - 16) <= 1e-9 * max(1, 16))
        #expect(abs(matrix.values.reduce(0, +) - 0) <= 1e-9 * max(1, 20))
        #expect(abs(matrix.values.reduce(0) { $0 + $1 * $1 } - 20) <= 1e-9 * max(1, 20))
    }

    @Test("SGT-038 Petersen adjacency (invariants)")
    func sgt038() {
        // U: nx(petersen) · adjacencyMatrix() → 10×10, nnz 30, trace 0, Σ entries 30, Σ entries² 30
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 10)
        #expect(matrix.nonzeroCount == 30)
        #expect(matrix.offsets == [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30])
        #expect(matrix.columns == [
            1, 4, 5, 0, 2, 6, 1, 3, 7, 2, 4, 8, 0, 3, 9, 0, 7, 8, 1, 8, 9, 2, 5, 9,
            3, 5, 6, 4, 6, 7,
        ])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 10)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // The catalog's invariants: trace, Σ entries, Σ entries².
        let trace = (0 ..< 10).reduce(0.0) { $0 + matrix[$1, $1] }
        #expect(abs(trace - 0) <= 1e-9 * max(1, 0))
        #expect(abs(matrix.values.reduce(0, +) - 30) <= 1e-9 * max(1, 30))
        #expect(abs(matrix.values.reduce(0) { $0 + $1 * $1 } - 30) <= 1e-9 * max(1, 30))
    }

    @Test("SGT-039 karate club Laplacian (invariants)")
    func sgt039() {
        // U: nx(karate_club) · laplacianMatrix() → 34×34, nnz 190, trace 156, Σ entries 0, Σ entries² 1368
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13),
            (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30),
            (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6),
            (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33),
            (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29),
            (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32),
            (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 34), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 34)
        #expect(matrix.nonzeroCount == 190)
        #expect(matrix.offsets == [
            0, 17, 27, 38, 45, 49, 54, 59, 64, 70, 73, 77, 79, 82, 88, 91, 94, 97, 100, 103, 107, 110, 113, 116,
            122, 126, 130, 133, 138, 142, 147, 152, 159, 172, 190,
        ])
        #expect(matrix.columns == [
            0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 17, 19, 21, 31, 0, 1, 2, 3, 7, 13, 17,
            19, 21, 30, 0, 1, 2, 3, 7, 8, 9, 13, 27, 28, 32, 0, 1, 2, 3, 7, 12, 13, 0, 4, 6,
            10, 0, 5, 6, 10, 16, 0, 4, 5, 6, 16, 0, 1, 2, 3, 7, 0, 2, 8, 30, 32, 33, 2, 9,
            33, 0, 4, 5, 10, 0, 11, 0, 3, 12, 0, 1, 2, 3, 13, 33, 14, 32, 33, 15, 32, 33, 5, 6,
            16, 0, 1, 17, 18, 32, 33, 0, 1, 19, 33, 20, 32, 33, 0, 1, 21, 22, 32, 33, 23, 25, 27, 29,
            32, 33, 24, 25, 27, 31, 23, 24, 25, 31, 26, 29, 33, 2, 23, 24, 27, 33, 2, 28, 31, 33, 23, 26,
            29, 32, 33, 1, 8, 30, 32, 33, 0, 24, 25, 28, 31, 32, 33, 2, 8, 14, 15, 18, 20, 22, 23, 29,
            30, 31, 32, 33, 8, 9, 13, 14, 15, 18, 19, 20, 22, 23, 26, 27, 28, 29, 30, 31, 32, 33,
        ])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [
            16, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, 9, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, 10, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1,
            -1, 6, -1, -1, -1, -1, 3, -1,
            -1, -1, 4, -1, -1, -1, -1, -1,
            -1, 4, -1, -1, -1, -1, -1, 4,
            -1, -1, 5, -1, -1, -1, -1, 2,
            -1, -1, -1, -1, 3, -1, 1, -1,
            -1, 2, -1, -1, -1, -1, 5, -1,
            2, -1, -1, 2, -1, -1, -1, -1,
            2, -1, -1, 2, 2, -1, -1, -1,
            -1, 3, -1, 2, -1, -1, -1, -1,
            2, 2, -1, -1, 5, -1, -1, -1,
            -1, -1, 3, -1, -1, -1, -1, -1,
            3, -1, 2, -1, -1, -1, -1, -1,
            4, -1, -1, 3, -1, -1, -1, -1,
            4, -1, -1, -1, -1, 4, -1, -1,
            -1, -1, -1, -1, 6, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, 12, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, 17,
        ]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 34)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // The catalog's invariants: trace, Σ entries, Σ entries².
        let trace = (0 ..< 34).reduce(0.0) { $0 + matrix[$1, $1] }
        #expect(abs(trace - 156) <= 1e-9 * max(1, 156))
        #expect(abs(matrix.values.reduce(0, +) - 0) <= 1e-9 * max(1, 1368))
        #expect(abs(matrix.values.reduce(0) { $0 + $1 * $1 } - 1368) <= 1e-9 * max(1, 1368))
    }

    @Test("SGT-040 directed 3-cycle adjacency")
    func sgt040() {
        // D: C(0,1,2) · adjacencyMatrix() → [[0, 1, 0], [0, 0, 1], [1, 0, 0]] (nnz 3)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 3)
        #expect(matrix.offsets == [0, 1, 2, 3])
        #expect(matrix.columns == [1, 2, 0])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, 1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, 1, 0],
            [0, 0, 1],
            [1, 0, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-041 directed Laplacian: out-degrees")
    func sgt041() {
        // D: 0>1, 0>2, 1>2 · laplacianMatrix() → [[2, -1, -1], [0, 1, -1], [0, 0, 0]] (nnz 5)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 5)
        #expect(matrix.offsets == [0, 3, 5, 5])
        #expect(matrix.columns == [0, 1, 2, 1, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, -1, -1, 1, -1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [2, -1, -1],
            [0, 1, -1],
            [0, 0, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-042 directed self-loop: 1 on the diagonal, cancels in L")
    func sgt042() {
        // D: 0>0, 0>1 · adjacencyMatrix() → [[1, 1], [0, 0]] (nnz 2)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 2), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 2)
        #expect(matrix.offsets == [0, 2, 2])
        #expect(matrix.columns == [0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, 1],
            [0, 0],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-043 directed self-loop cancels in the Laplacian")
    func sgt043() {
        // D: 0>0, 0>1 · laplacianMatrix() → [[1, -1], [0, 0]] (nnz 2)
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 2), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 2)
        #expect(matrix.offsets == [0, 2, 2])
        #expect(matrix.columns == [0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1],
            [0, 0],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-044 directed parallel arcs add up")
    func sgt044() {
        // D: 0>1, 0>1, 1>0 · adjacencyMatrix() → [[0, 2], [1, 0]] (nnz 2)
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 2), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.adjacencyMatrix()
        #expect(matrix.rowCount == 2)
        #expect(matrix.nonzeroCount == 2)
        #expect(matrix.offsets == [0, 1, 2])
        #expect(matrix.columns == [1, 0])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [2, 1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 2)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [0, 2],
            [1, 0],
        ]
        for i in 0 ..< 2 {
            for j in 0 ..< 2 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-045 directed weighted Laplacian")
    func sgt045() {
        // D: 0>1, 1>2, 2>0, 0>2 · laplacianMatrix(weight:) [1, 2, 3, 4] → [[5, -1, -4], [0, 2, -2], [-3, 0, 3]] (nnz 7)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let weights: [Int] = [1, 2, 3, 4]
        let matrix = graph.laplacianMatrix(weight: { weights[$0] })
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 7)
        #expect(matrix.offsets == [0, 3, 5, 7])
        #expect(matrix.columns == [0, 1, 2, 1, 2, 0, 2])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [5, -1, -4, 2, -2, -3, 3]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [5, -1, -4],
            [0, 2, -2],
            [-3, 0, 3],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }

    @Test("SGT-046 directed isolated vertex")
    func sgt046() {
        // D: [0,1,2] 0>1 · laplacianMatrix() → [[1, -1, 0], [0, 0, 0], [0, 0, 0]] (nnz 2)
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 3), edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = graph.laplacianMatrix()
        #expect(matrix.rowCount == 3)
        #expect(matrix.nonzeroCount == 2)
        #expect(matrix.offsets == [0, 2, 2, 2])
        #expect(matrix.columns == [0, 1])
        // The stored values, row by row (relative 1e-12: exact up to rounding).
        let stored: [Double] = [1, -1]
        #expect(matrix.values.count == stored.count)
        for (k, value) in zip(matrix.values, stored).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), "stored entry \(k)")
        }
        #expect(!matrix.values.contains(0))
        #expect(matrix.pattern.vertexCount == 3)
        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)
        // Every entry through the subscript, 0 where nothing is stored.
        let rows: [[Double]] = [
            [1, -1, 0],
            [0, 0, 0],
            [0, 0, 0],
        ]
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), "entry (\(i), \(j))")
            }
        }
    }
}
