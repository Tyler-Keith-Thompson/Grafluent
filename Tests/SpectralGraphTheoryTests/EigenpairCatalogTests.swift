// Eigenpairs and the spectral embedding (catalog SGT-231 – SGT-255): the k extreme eigenpairs of
// A, L, N and Q with every eigenvalue, the vectors the contract pins (simple eigenvalues, the
// null vectors per component), and every vector unit, orthogonal and an eigenvector; the
// embedding's eigenvalues and coordinates.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory eigenpairs and embedding")
struct EigenpairCatalogTests {
    @Test("SGT-231 P3: L's 0, 1, 3 with their vectors")
    func sgt231() throws {
        // U: P(0..2) · laplacianEigenpairs(smallest: 3) → λ 0, 1, 3; [0.5773502692, 0.5773502692, 0.5773502692]; [0.7071067812, 0, -0.7071067812]; [0.4082482905, -0.8164965809, 0.4082482905]
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 3)
        #expect(pairs.count == 3)
        let values: [Double] = [0, 1, 3]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 3, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.57735026918963, 0.57735026918963, 0.57735026918963]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.70710678118655, -1e-17, -0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        let vector2: [Double] = [0.40824829046386, -0.81649658092773, 0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 2), vector2).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 2, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 3, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-232 P3: L's largest first")
    func sgt232() throws {
        // U: P(0..2) · laplacianEigenpairs(largest: 2) → λ 3, 1; [0.4082482905, -0.8164965809, 0.4082482905]; [0.7071067812, 0, -0.7071067812]
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(largest: 2)
        #expect(pairs.count == 2)
        let values: [Double] = [3, 1]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 3, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.40824829046386, -0.81649658092773, 0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.70710678118655, -1e-17, -0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 3, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-233 count 0: no pair")
    func sgt233() throws {
        // U: P(0..2) · laplacianEigenpairs(smallest: 0) → no pair
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 0)
        #expect(pairs.count == 0)
        #expect(pairs.eigenvalues.isEmpty)
    }

    @Test("SGT-234 empty graph, count 0")
    func sgt234() throws {
        // U: · adjacencyEigenpairs(largest: 0) → no pair
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.adjacencyEigenpairs(largest: 0)
        #expect(pairs.count == 0)
        #expect(pairs.eigenvalues.isEmpty)
    }

    @Test("SGT-235 K4: A's 3 then −1 (multiple)")
    func sgt235() throws {
        // U: K(4) · adjacencyEigenpairs(largest: 2) → λ 3, -1; [0.5, 0.5, 0.5, 0.5]; (multiple eigenvalue: some unit vector)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.adjacencyEigenpairs(largest: 2)
        #expect(pairs.count == 2)
        let values: [Double] = [3, -1]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 3, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.5, 0.5, 0.5, 0.5]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.adjacencyMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 3, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-236 star K1,3: A's ±√3")
    func sgt236() throws {
        // U: S(0;1..3) · adjacencyEigenpairs(smallest: 1) → λ -1.732050808; [0.7071067812, -0.4082482905, -0.4082482905, -0.4082482905]
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.adjacencyEigenpairs(smallest: 1)
        #expect(pairs.count == 1)
        let values: [Double] = [-1.73205080756888]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 1.73205080756888, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.70710678118655, -0.40824829046386, -0.40824829046386, -0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.adjacencyMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 1.73205080756888, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-237 star K1,3: A's largest")
    func sgt237() throws {
        // U: S(0;1..3) · adjacencyEigenpairs(largest: 1) → λ 1.732050808; [0.7071067812, 0.4082482905, 0.4082482905, 0.4082482905]
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.adjacencyEigenpairs(largest: 1)
        #expect(pairs.count == 1)
        let values: [Double] = [1.73205080756888]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 1.73205080756888, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.70710678118655, 0.40824829046386, 0.40824829046386, 0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.adjacencyMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 1.73205080756888, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-238 two triangles: L's null vectors per component, then 3 (multiple)")
    func sgt238() throws {
        // U: C(0,1,2), C(3,4,5) · laplacianEigenpairs(smallest: 3) → λ 0, 0, 3; [0.5773502692, 0.5773502692, 0.5773502692, 0, 0, 0]; [0, 0, 0, 0.5773502692, 0.5773502692, 0.5773502692]; (multiple eigenvalue: some unit vector)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 3)
        #expect(pairs.count == 3)
        let values: [Double] = [0, 0, 3]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 3, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.57735026918963, 0.57735026918963, 0.57735026918963, 0, 0, 0]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0, 0, 0, 0.57735026918963, 0.57735026918963, 0.57735026918963]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 3, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-239 isolated vertex: e_v, its own component")
    func sgt239() throws {
        // U: [0, 1, 2] 1-2 · laplacianEigenpairs(smallest: 3) → λ 0, 0, 2; [1, 0, 0]; [0, 0.7071067812, 0.7071067812]; [0, 0.7071067812, -0.7071067812]
        let edges: [(Int, Int)] = [(1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 3)
        #expect(pairs.count == 3)
        let values: [Double] = [0, 0, 2]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 2, "eigenvalue \(k)")
        }
        let vector0: [Double] = [1, 0, 0]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0, 0.70710678118655, 0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        let vector2: [Double] = [0, 0.70710678118655, -0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 2), vector2).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 2, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 2, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-240 isolated vertex in N: e_v")
    func sgt240() throws {
        // U: [0, 1, 2] 1-2 · normalizedLaplacianEigenpairs(smallest: 2) → λ 0, 0; [1, 0, 0]; [0, 0.7071067812, 0.7071067812]
        let edges: [(Int, Int)] = [(1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.normalizedLaplacianEigenpairs(smallest: 2)
        #expect(pairs.count == 2)
        let values: [Double] = [0, 0]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 2, "eigenvalue \(k)")
        }
        let vector0: [Double] = [1, 0, 0]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0, 0.70710678118655, 0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.normalizedLaplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 2, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-241 N of P4")
    func sgt241() throws {
        // U: P(0..3) · normalizedLaplacianEigenpairs(smallest: 4) → λ 0, 0.5, 1.5, 2; [0.4082482905, 0.5773502692, 0.5773502692, 0.4082482905]; [0.5773502692, 0.4082482905, -0.4082482905, -0.5773502692]; [0.5773502692, -0.408…
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.normalizedLaplacianEigenpairs(smallest: 4)
        #expect(pairs.count == 4)
        let values: [Double] = [0, 0.5, 1.5, 2]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 2, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.40824829046386, 0.57735026918963, 0.57735026918963, 0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.57735026918963, 0.40824829046386, -0.40824829046386, -0.57735026918963]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        let vector2: [Double] = [0.57735026918963, -0.40824829046386, -0.40824829046386, 0.57735026918963]
        for (v, entry) in zip(pairs.eigenvector(at: 2), vector2).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 2, entry \(v)")
        }
        let vector3: [Double] = [0.40824829046386, -0.57735026918963, 0.57735026918963, -0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 3), vector3).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 3, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.normalizedLaplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 2, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-242 N's largest of K1,3: 2")
    func sgt242() throws {
        // U: S(0;1..3) · normalizedLaplacianEigenpairs(largest: 1) → λ 2; [0.7071067812, -0.4082482905, -0.4082482905, -0.4082482905]
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.normalizedLaplacianEigenpairs(largest: 1)
        #expect(pairs.count == 1)
        let values: [Double] = [2]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 2, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.70710678118655, -0.40824829046386, -0.40824829046386, -0.40824829046386]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.normalizedLaplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 2, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-243 loop: L ignores it")
    func sgt243() throws {
        // U: 0-0, 0-1 · laplacianEigenpairs(smallest: 2) → λ 0, 2; [0.7071067812, 0.7071067812]; [0.7071067812, -0.7071067812]
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 2)
        #expect(pairs.count == 2)
        let values: [Double] = [0, 2]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 2, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.70710678118655, 0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.70710678118655, -0.70710678118655]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 2, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-244 loop: Q[v][v] gains 4, 3 ± √5")
    func sgt244() throws {
        // U: 0-0, 0-1 · signlessLaplacianEigenpairs(smallest: 2) → λ 0.7639320225, 5.236067977; [0.2297529205, -0.9732489895]; [0.9732489895, 0.2297529205]
        let edges: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.signlessLaplacianEigenpairs(smallest: 2)
        #expect(pairs.count == 2)
        let values: [Double] = [0.76393202250021, 5.2360679774998]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 5.2360679774998, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.22975292054736, -0.97324898946773]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.97324898946773, 0.22975292054736]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.signlessLaplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 5.2360679774998, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-245 Q of a bipartite path: 0 first")
    func sgt245() throws {
        // U: P(0..3) · signlessLaplacianEigenpairs(smallest: 1) → λ 0; [0.5, -0.5, 0.5, -0.5]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.signlessLaplacianEigenpairs(smallest: 1)
        #expect(pairs.count == 1)
        let values: [Double] = [2e-16]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 3.4142135623731, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.5, -0.5, 0.5, -0.5]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.signlessLaplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 3.4142135623731, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-246 parallel edges add up")
    func sgt246() throws {
        // U: 0=1, 1-2 · laplacianEigenpairs(smallest: 3) → λ 0, 1.267949192, 4.732050808; [0.5773502692, 0.5773502692, 0.5773502692]; [0.5773502692, 0.2113248654, -0.7886751346]; [0.5773502692, -0.7886751346, 0.21132…
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 3)
        #expect(pairs.count == 3)
        let values: [Double] = [0, 1.26794919243112, 4.7320508075689]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 4.7320508075689, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.57735026918963, 0.57735026918963, 0.57735026918963]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.57735026918963, 0.21132486540519, -0.78867513459481]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        let vector2: [Double] = [0.57735026918963, -0.78867513459481, 0.21132486540519]
        for (v, entry) in zip(pairs.eigenvector(at: 2), vector2).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 2, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 4.7320508075689, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-247 weighted path")
    func sgt247() throws {
        // U: P(0..3) · laplacianEigenpairs(smallest: 2) weight: [1, 2, 3] → λ 0, 0.9358222275; [0.5, 0.5, 0.5, 0.5]; [0.7931284139, 0.05090121489, -0.3440296287, -0.5]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let pairs = try graph.laplacianEigenpairs(smallest: 2, weight: { weights[$0] })
        #expect(pairs.count == 2)
        let values: [Double] = [0, 0.93582222752409]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 7.7587704831436, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.5, 0.5, 0.5, 0.5]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.79312841385727, 0.05090121488871, -0.34402962874599, -0.5]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix(weight: { weights[$0] })
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 7.7587704831436, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-248 weighted adjacency, a negative weight")
    func sgt248() throws {
        // U: C(0,1,2) · adjacencyEigenpairs(largest: 3) weight: [1, -2, 3] → λ 3.201911777, 0.9111788076, -4.113090584; [0.6108341623, -0.2733689273, 0.743068675]; [0.5247942056, 0.8425210807, -0.1214465741]; [0.5928513034, -0.4641418…
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, -2, 3]
        let pairs = try graph.adjacencyEigenpairs(largest: 3, weight: { weights[$0] })
        #expect(pairs.count == 3)
        let values: [Double] = [3.2019117766787, 0.91117880764624, -4.11309058432495]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 4.11309058432495, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.61083416225726, -0.27336892732458, 0.74306867501792]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0.52479420561331, 0.84252108068909, -0.1214465740529]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        let vector2: [Double] = [0.59285130342622, -0.46414185134278, -0.65810308756146]
        for (v, entry) in zip(pairs.eigenvector(at: 2), vector2).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 2, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.adjacencyMatrix(weight: { weights[$0] })
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 4.11309058432495, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-249 Petersen: L's 2 (multiplicity 5) after 0")
    func sgt249() throws {
        // U: nx(petersen) · laplacianEigenpairs(smallest: 2) → λ 0, 2; [0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766]; (multiple eigenva…
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 2)
        #expect(pairs.count == 2)
        let values: [Double] = [0, 2]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 5, "eigenvalue \(k)")
        }
        let vector0: [Double] = [
            0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684,
            0.31622776601684, 0.31622776601684,
        ]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.laplacianMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 5, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-250 Petersen: A's 3")
    func sgt250() throws {
        // U: nx(petersen) · adjacencyEigenpairs(largest: 1) → λ 3; [0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766, 0.316227766]
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let pairs = try graph.adjacencyEigenpairs(largest: 1)
        #expect(pairs.count == 1)
        let values: [Double] = [3]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 3, "eigenvalue \(k)")
        }
        let vector0: [Double] = [
            0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684, 0.31622776601684,
            0.31622776601684, 0.31622776601684,
        ]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.adjacencyMatrix()
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 3, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-251 weight 0 disconnects")
    func sgt251() throws {
        // U: P(0..2) · normalizedLaplacianEigenpairs(smallest: 2) weight: [1, 0] → λ 0, 0; [0.7071067812, 0.7071067812, 0]; [0, 0, 1]
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 0]
        let pairs = try graph.normalizedLaplacianEigenpairs(smallest: 2, weight: { weights[$0] })
        #expect(pairs.count == 2)
        let values: [Double] = [0, 0]
        for (k, value) in zip(pairs.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9 * 2, "eigenvalue \(k)")
        }
        let vector0: [Double] = [0.70710678118655, 0.70710678118655, 0]
        for (v, entry) in zip(pairs.eigenvector(at: 0), vector0).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 0, entry \(v)")
        }
        let vector1: [Double] = [0, 0, 1]
        for (v, entry) in zip(pairs.eigenvector(at: 1), vector1).enumerated() {
            #expect(abs(entry.0 - entry.1) <= 1e-9, "vector 1, entry \(v)")
        }
        // Every vector: unit, orthogonal to the others, and an eigenvector of the matrix.
        let matrix = graph.normalizedLaplacianMatrix(weight: { weights[$0] })
        for i in 0 ..< pairs.count {
            let x = pairs.eigenvector(at: i)
            let mx = matrix * x
            var residual = 0.0
            for v in 0 ..< x.count { residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-9 * 2, "residual \(i)")
            for j in 0 ... i {
                var dot = 0.0
                for (a, b) in zip(x, pairs.eigenvector(at: j)) { dot += a * b }
                #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "x\(i) · x\(j)")
            }
        }
    }

    @Test("SGT-252 P3: x₂/√d")
    func sgt252() throws {
        // U: P(0..2) · spectralEmbedding(dimensions: 1) → λ 1; [[0.7071067812], [0], [-0.7071067812]]
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let embedding = try graph.spectralEmbedding(dimensions: 1)
        #expect(embedding.dimensions == 1)
        let values: [Double] = [1]
        for (k, value) in zip(embedding.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "eigenvalue \(k)")
        }
        let coordinates: [[Double]] = [
            [0.70710678118655],
            [4e-17],
            [-0.70710678118655],
        ]
        for (i, vertex) in graph.vertices.enumerated() {
            for (j, value) in zip(embedding.coordinates(of: vertex), coordinates[i]).enumerated() {
                #expect(abs(value.0 - value.1) <= 1e-9, "vertex \(vertex), coordinate \(j)")
            }
        }
    }

    @Test("SGT-253 P5 in two dimensions")
    func sgt253() throws {
        // U: P(0..4) · spectralEmbedding(dimensions: 2) → λ 0.2928932188, 1; [[0.5, 0.5], [0.3535533906, 0], [0, -0.5], [-0.3535533906, 0], [-0.5, 0.5]]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let embedding = try graph.spectralEmbedding(dimensions: 2)
        #expect(embedding.dimensions == 2)
        let values: [Double] = [0.29289321881345, 1]
        for (k, value) in zip(embedding.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "eigenvalue \(k)")
        }
        let coordinates: [[Double]] = [
            [0.5, 0.5],
            [0.35355339059327, 4e-16],
            [1e-16, -0.5],
            [-0.35355339059327, 3e-17],
            [-0.5, 0.5],
        ]
        for (i, vertex) in graph.vertices.enumerated() {
            for (j, value) in zip(embedding.coordinates(of: vertex), coordinates[i]).enumerated() {
                #expect(abs(value.0 - value.1) <= 1e-9, "vertex \(vertex), coordinate \(j)")
            }
        }
    }

    @Test("SGT-254 weighted triangle")
    func sgt254() throws {
        // U: C(0,1,2) · spectralEmbedding(dimensions: 2) weight: [1, 2, 4] → λ 1.231258075, 1.768741925; [[0.225823556, 0.2785231591], [-0.4916275823, 0.142151617], [0.0576274945, -0.303178441]]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 4]
        let embedding = try graph.spectralEmbedding(dimensions: 2, weight: { weights[$0] })
        #expect(embedding.dimensions == 2)
        let values: [Double] = [1.23125807505672, 1.7687419249433]
        for (k, value) in zip(embedding.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "eigenvalue \(k)")
        }
        let coordinates: [[Double]] = [
            [0.22582355598314, 0.27852315906322],
            [-0.49162758231485, 0.142151616987],
            [0.0576274945048, -0.30317844104618],
        ]
        for (i, vertex) in graph.vertices.enumerated() {
            for (j, value) in zip(embedding.coordinates(of: vertex), coordinates[i]).enumerated() {
                #expect(abs(value.0 - value.1) <= 1e-9, "vertex \(vertex), coordinate \(j)")
            }
        }
    }

    @Test("SGT-255 C5: λ₂ double, not pinned")
    func sgt255() throws {
        // U: C(0..4) · spectralEmbedding(dimensions: 1) → λ 0.6909830056; (a multiple eigenvalue: coordinates not pinned)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let embedding = try graph.spectralEmbedding(dimensions: 1)
        #expect(embedding.dimensions == 1)
        let values: [Double] = [0.69098300562505]
        for (k, value) in zip(embedding.eigenvalues, values).enumerated() {
            #expect(abs(value.0 - value.1) <= 1e-9, "eigenvalue \(k)")
        }
        // A multiple eigenvalue: the coordinates are not pinned, only finite.
        for v in graph.vertices { for x in embedding.coordinates(of: v) { #expect(x.isFinite) } }
    }
}
