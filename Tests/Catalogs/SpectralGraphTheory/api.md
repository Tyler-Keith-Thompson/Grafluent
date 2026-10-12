# SpectralGraphTheory: proposed API (phase 1, with phase 2 pinned)

Graph matrices (adjacency, Laplacian, normalized, random-walk and signless Laplacians) as a
square `SparseMatrix`; full spectra of small graphs; the algebraic connectivity, Fiedler vector,
spectral ordering and spectral radius of large sparse graphs by a Lanczos iteration; and the
quantities of the matrix-tree theorem and of electrical networks: the number of spanning trees,
resistance distance, effective graph resistance and the Kemeny constant. Everything is pure
Swift, on every platform, with no new package dependency. Phase 2 adds partial spectra and
spectral embedding and clustering (block methods), directed spanning arborescences, the signless
spectrum and spectral bisection.

`cases.md` (SGT-001 – SGT-217, 217 rows; SGT-205 – SGT-217 are phase 2) pins the values.
`ref.py` builds every matrix from the definitions below in exact fractions, takes spectra from
`numpy.linalg.eigvalsh`, counts spanning trees and resistances exactly (Kirchhoff determinants),
and checks rows against closed forms (complete, path, cycle, star, complete bipartite, hypercube,
grid and Petersen spectra), brute-force spanning-tree and arborescence enumeration, the
pseudoinverse, NetworkX 3.7 and SciPy 1.18.1. `--stress` adds 1,000 random multigraphs with
loops and weights (up to 7 vertices and 12 edges). `--bench` prints the baselines quoted under
Performance. Run (about 10 s; `--stress` about 15 s, `--bench` about half an hour):

`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.5.4 python3 Tests/Catalogs/SpectralGraphTheory/ref.py [--write] [--stress] [--bench]`

## Scope

**In, phase 1** (on `Graph`; the two matrices marked also on `DirectedGraph`)

| Entry point | Why |
|---|---|
| `adjacencyMatrix()` (also `DirectedGraph`) | The README row. NetworkX `adjacency_matrix`, igraph `get_adjacency_sparse`, Mathematica `AdjacencyMatrix`, Boost's `adjacency_matrix` concept |
| `laplacianMatrix()` (also `DirectedGraph`: out-degrees) | The README row. NetworkX `laplacian_matrix`, igraph `laplacian`, SciPy `csgraph.laplacian`, Mathematica `KirchhoffMatrix` |
| `normalizedLaplacianMatrix()` | The README row. NetworkX `normalized_laplacian_matrix`, igraph `laplacian(normalized="symmetric")`, SciPy `csgraph.laplacian(normed=True)` |
| `randomWalkLaplacianMatrix()` | I − D⁻¹A: igraph `laplacian(normalized="left")`, von Luxburg's L_rw, the matrix Shi–Malik spectral clustering uses. One pass, same storage |
| `signlessLaplacianMatrix()` | D + A: Cvetković–Rowlinson–Simić's signless Laplacian, the standard companion of L (bipartiteness: its least eigenvalue is 0 exactly on bipartite components). One pass |
| `adjacencySpectrum()`, `laplacianSpectrum()`, `normalizedLaplacianSpectrum()` → `[Double]` ascending | NetworkX `adjacency_spectrum`, `laplacian_spectrum`, `normalized_laplacian_spectrum`. Dense, for small graphs (O(n³)) |
| `algebraicConnectivity(normalized:tolerance:)` → `Double` | The README's spectral row. NetworkX `algebraic_connectivity`; Fiedler 1973. Sparse (Lanczos) |
| `fiedlerVector(normalized:tolerance:)` → `FiedlerVector<Self>?` | The README row. NetworkX `fiedler_vector`. `nil` when the graph is not connected |
| `spectralOrdering(normalized:tolerance:)` → `[Vertex]` | NetworkX `spectral_ordering`: the Fiedler vector's main use (envelope reduction, seriation; Barnard–Pothen–Simon) |
| `spectralRadius(tolerance:)` → `Double` | ρ(A), the largest eigenvalue magnitude (the standard term; Cvetković–Rowlinson–Simić); igraph computes it with `eigen_adjacency`. Bounds for epidemic thresholds, Hoffman/Wilf bounds in `ColoringModule`. Sparse (Lanczos) |
| `numberOfSpanningTrees()` → `Double` | NetworkX `number_of_spanning_trees`; Kirchhoff's matrix-tree theorem. `SpanningTrees`' catalog defers it here (its api.md) |
| `resistanceDistance(from:to:)` → `Double?` | NetworkX `resistance_distance`; Klein–Randić 1993. `Distances`' catalog defers it here. One Laplacian solve, not a pseudoinverse |
| `effectiveGraphResistance()` → `Double?` | NetworkX `effective_graph_resistance` (3.3+; the Kirchhoff index of Klein–Randić). `Distances` defers it here |
| `kemenyConstant()` → `Double?` | NetworkX `kemeny_constant`. `Distances` defers it here |

Every entry point has `weight:` overloads, one for `BinaryInteger` and one for
`BinaryFloatingPoint` weights (Centrality's pair), reading the weight of the edge at each
position once. `weight:` comes first on graph-wide calls (`algebraicConnectivity(weight:normalized:tolerance:)`,
as Centrality's `pageRank(weight:…)`), and after the vertices on
`resistanceDistance(from:to:weight:tolerance:)` (as `closenessCentrality(of:weight:)`).

**Phase 2** (rows pinned now where the semantics are settled: SGT-205 – SGT-217)

| Entry point | Why |
|---|---|
| `numberOfSpanningTrees(root:)` on `DirectedGraph` | NetworkX `number_of_spanning_trees(G, root=)`: arborescences directed away from the root, by Tutte's theorem on the in-degree Laplacian. Pinned (SGT-205 – SGT-210) |
| `signlessLaplacianSpectrum()` | Completes the matrix family's spectra. Pinned (SGT-211 – SGT-213) |
| `spectralBisection(normalized:tolerance:)` | NetworkX `spectral_bisection` (Newman): the two sign classes of the Fiedler vector. Pinned (SGT-214 – SGT-217) |
| `spectralEmbedding(dimensions:normalized:)` | scikit-learn `spectral_embedding`, Belkin–Niyogi Laplacian eigenmaps; `GraphDrawing`'s spectral layout (NetworkX `spectral_layout`) is its 2-D case. Needs k eigenpairs with multiplicities, so a block method (below); not pinned: only the spanned subspace is unique on degenerate spectra |
| `spectralClustering(clusterCount:normalized:using:)` | scikit-learn `SpectralClustering`, Ng–Jordan–Weiss / Shi–Malik: the embedding, then k-means++ seeded from `inout some RandomNumberGenerator` (RandomGraphs' convention). Returns `CommunityDetection`'s `Partition` |
| The k smallest or largest eigenpairs of each matrix | SciPy `eigsh(k, which=)`, igraph `eigen_adjacency`. Named when designed; LOBPCG with a Jacobi preconditioner (NetworkX's `lobpcg` method, scikit-learn's) |
| Directed: `directedLaplacianMatrix()` (Chung), complex spectra by Arnoldi | NetworkX `directed_laplacian_matrix`, `directed_combinatorial_laplacian_matrix` need the PageRank stationary vector (Centrality); a complex spectrum needs a complex result type |
| `modularityMatrix()`, Bethe Hessian | NetworkX `modularity_matrix`, `bethe_hessian_matrix`: community-detection matrices, with `CommunityDetection` |
| All-pairs resistance distances | NetworkX `resistance_distance(G)` without nodes: a dense n × n result, as `Distances`' planned `DistanceMatrix` |
| Direct solvers for eigenvector and Katz centrality; current-flow closeness and betweenness | `Centrality`'s api.md defers them here: they reuse the Lanczos engine and the Laplacian solver |

**Not planned**

| Not in phase 1 or 2 | Reason |
|---|---|
| Accelerate or LAPACK back ends | See "Platform and dependencies (decision)" |
| NetworkX `magnetic_laplacian_matrix`, `spectral_graph_forge`, `attr_matrix` | NetworkX-only, niche |
| Shift-invert (`eigsh(sigma=)`) | Needs a sparse factorization; the Gershgorin shift and preconditioned block methods cover the same eigenvalues |
| Integer matrices (NetworkX returns the dtype of the weights) | One element type, `Double`: every consumer is floating point, and an integer Laplacian of a weighted multigraph overflows silently |

## Summary

```swift
import GraphProtocols

extension Graph {
    // Matrices; rows and columns in vertex-index order (`vertices` order when the graph has no
    // indices). Each also with weight: (Edges.Index) -> W for W: BinaryInteger and
    // W: BinaryFloatingPoint, first: adjacencyMatrix(weight:), algebraicConnectivity(weight:normalized:tolerance:).
    public func adjacencyMatrix() -> SparseMatrix              // a loop adds 2 to A[v][v]
    public func laplacianMatrix() -> SparseMatrix              // D − A
    public func normalizedLaplacianMatrix() -> SparseMatrix    // D^-1/2 (D − A) D^-1/2
    public func randomWalkLaplacianMatrix() -> SparseMatrix    // D^-1 (D − A)
    public func signlessLaplacianMatrix() -> SparseMatrix      // D + A

    // Full spectra, ascending (dense; O(n³) time, O(n²) memory). maxIterations: QL/QR iterations
    // in all, nil for 30 n.
    public func adjacencySpectrum(maxIterations: Int? = nil) throws(NoConvergence) -> [Double]
    public func laplacianSpectrum(maxIterations: Int? = nil) throws(NoConvergence) -> [Double]
    public func normalizedLaplacianSpectrum(maxIterations: Int? = nil) throws(NoConvergence) -> [Double]

    // Sparse (thick-restart Lanczos; dense below 64 vertices); each also with weight: first.
    // maxIterations: products per Lanczos run, nil for the work limits under Numerics.
    public func algebraicConnectivity(normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double
    public func fiedlerVector(normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> FiedlerVector<Self>?
    public func spectralOrdering(normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> [Vertex]
    public func spectralRadius(tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double   // weight: may be negative

    // Matrix-tree theorem and electrical networks; each also with weight: (a conductance).
    // maxIterations: conjugate-gradient iterations, nil for 20,000 + 2n.
    public func numberOfSpanningTrees() -> Double
    public func resistanceDistance(from source: Vertex, to target: Vertex, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double?
    public func resistanceDistance<W>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Double?
    public func effectiveGraphResistance() -> Double?
    public func kemenyConstant() -> Double?

    // Phase 2
    public func signlessLaplacianSpectrum() -> [Double]
    public func spectralBisection(normalized: Bool = false, tolerance: Double = 1e-8) -> (negative: [Vertex], nonnegative: [Vertex])?
}

extension DirectedGraph {
    public func adjacencyMatrix() -> SparseMatrix              // A[u][v] = arcs u → v; a loop adds 1
    public func laplacianMatrix() -> SparseMatrix              // D_out − A
    // Phase 2
    public func numberOfSpanningTrees(root: Vertex) -> Double  // arborescences directed away from root
}

/// A square matrix of `Double`s in compressed sparse row form, storing exactly its nonzero entries.
@frozen public struct SparseMatrix: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var rowCount: Int { get }                 // = column count
    public var offsets: [Int] { get }                // rowCount + 1 entries, as CompressedSparseRow
    public var columns: [Int] { get }                // ascending within each row
    public var values: [Double] { get }              // aligned with `columns`; never 0
    public var nonzeroCount: Int { get }
    public subscript(row: Int, column: Int) -> Double { get }   // m[i, j], unlabelled; 0 when not stored;
                                                     // O(log row length); traps out of range
    public var pattern: CompressedSparseRow { get }  // the stored positions as a graph, O(1), sharing storage
    public static func * (matrix: SparseMatrix, vector: [Double]) -> [Double]   // traps on a wrong length
}

@frozen public struct FiedlerVector<G: Graph> {     // Sendable when G and G.Vertex are
    public let algebraicConnectivity: Double         // λ₂
    public var values: [Double] { get }              // unit length, canonical sign, index order
    public func value(of vertex: G.Vertex) -> Double // traps on a non-vertex
    public func value(ofIndex index: Int) -> Double  // traps outside 0..<vertexCount
}
```

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `adjacencyMatrix()`, `laplacianMatrix()`, `normalizedLaplacianMatrix()` | NetworkX, verbatim; Mathematica `AdjacencyMatrix` | Mathematica `KirchhoffMatrix` (the older name; "Laplacian" is what NetworkX, igraph, SciPy and the textbooks use). The method `adjacencyMatrix()` and the representation `AdjacencyMatrix` differ: one is a numeric matrix of any graph, the other a bit-matrix graph type; the doc comment of each points to the other |
| `randomWalkLaplacianMatrix()` | von Luxburg's "random walk Laplacian" L_rw; igraph `normalized="left"` | `leftNormalizedLaplacian`: igraph's argument value, not a term. NetworkX has none |
| `signlessLaplacianMatrix()` | Cvetković–Rowlinson–Simić, "signless Laplacian" | `unsignedLaplacian`, `Q-matrix`: less common |
| `adjacencySpectrum()`, `laplacianSpectrum()`, `normalizedLaplacianSpectrum()` | NetworkX, verbatim | `eigenvalues` (igraph's `eigen_adjacency`): says nothing of which matrix |
| `algebraicConnectivity`, `fiedlerVector` | NetworkX; Fiedler 1973 | |
| `normalized:` | NetworkX's `normalized=` parameter on all three | A separate `normalizedAlgebraicConnectivity()`: NetworkX's spelling is one function with a flag, and so is the meaning (the same procedure on N) |
| `spectralOrdering`, `spectralBisection`, `spectralEmbedding`, `spectralClustering` | NetworkX `spectral_ordering`, `spectral_bisection`; scikit-learn `spectral_embedding`, `SpectralClustering` | |
| `spectralRadius` | the standard term (Cvetković, Brualdi); igraph documents `eigen_adjacency` for it | `largestEigenvalue`: for a nonnegative symmetric A they are equal (Perron–Frobenius), but the radius is the named quantity |
| `numberOfSpanningTrees` | NetworkX `number_of_spanning_trees` | "complexity" τ(G) (Biggs). Swift spells counts `…Count` (`edgeCount`), but `spanningTreeCount` would be invented here; NetworkX's name reads naturally |
| `resistanceDistance(from:to:)` | NetworkX `resistance_distance`; Klein–Randić 1993 | `effectiveResistance(between:and:)`: the physics term, equally common; NetworkX's choice decides. `from:to:` as `ShortestPaths`, though the value is symmetric |
| `effectiveGraphResistance` | NetworkX 3.3+, verbatim | `kirchhoffIndex` (chemistry; Klein–Randić): a synonym, named in the doc comment only, no typealias |
| `kemenyConstant` | NetworkX, verbatim | |
| `SparseMatrix` | Eigen `SparseMatrix`, Accelerate `SparseMatrix_Double`, Julia `SparseMatrixCSC`; SciPy `csr_array` | `LaplacianMatrix` (one type per kind), `GraphMatrix`: invented; the result is a plain matrix |
| `offsets`, `columns`, `values` | `CompressedSparseRow.offsets`; SciPy `indptr`, `indices`, `data`; Eigen `outerIndexPtr`, `innerIndexPtr`, `valuePtr` | SciPy's names say less; `offsets` matches the graph type whose storage this mirrors |
| `pattern` | Eigen and SuiteSparse "sparsity pattern" | `structure` |

## Semantics

### Matrices (definitions; what every row checks)

With w(e) the weight of edge e (1 without `weight:`):

- **A** (`adjacencyMatrix`): A[u][v] = Σ w(e) over the edges e between u and v. **An undirected
  self-loop adds 2·w(e) to A[v][v]**, so row sums equal `degree(of:)` (a loop has two ends,
  `Graph`'s rule) and A = B Bᵀ − 2·diag over the unoriented incidence matrix B; this is igraph's
  default (`loops="twice"`) and the matrix `Centrality`'s eigenvector iteration already uses
  (its rows list a loop twice). On `DirectedGraph`: A[u][v] = Σ w over arcs u → v, a loop adds
  w once. Parallel edges add up (SGT-013, SGT-030, SGT-044).
- **D** = diag(row sums of A), the weighted degrees (out-degrees on `DirectedGraph`).
- **L** = D − A (`laplacianMatrix`). Self-loops cancel: L = B̃ B̃ᵀ over the oriented incidence
  matrix, in which a loop column is zero (SGT-017, SGT-043). Every library agrees on L.
- **N** = D^-1/2 L D^-1/2 (`normalizedLaplacianMatrix`), with D^-1/2 = 0 at a vertex of degree 0,
  so an isolated vertex has a zero row and column (NetworkX and SciPy agree; SGT-023). Loops
  count in D (twice), so N[v][v] = 1 − 2·loops/d(v) (SGT-018, igraph's value).
- **L_rw** = D⁻¹ L (`randomWalkLaplacianMatrix`), zero rows at degree 0 (SGT-024).
- **Q** = D + A (`signlessLaplacianMatrix`); with the loop convention, Q = B Bᵀ (a loop adds 4,
  SGT-020).
- **Weights.** Laplacian-family matrices, spectra, Fiedler quantities, counts and resistances
  require every weight finite and ≥ 0 (a trap otherwise, SGT-032 – SGT-034, SGT-084, SGT-184):
  their theorems (positive semidefiniteness, the matrix-tree theorem, Rayleigh monotonicity)
  need it. `adjacencyMatrix`, `adjacencySpectrum` and `spectralRadius` accept any finite weight
  (SGT-031); NaN and infinity trap everywhere (SGT-035). A weight-0 edge is no edge: it stores nothing (SGT-029)
  and does not connect (SGT-100, SGT-125, SGT-182). Weights are conductances, the Laplacian's
  own weights, everywhere in the module, resistance included (NetworkX's
  `invert_weight=True` default reads them as resistances; disagreements).
- **Storage.** A `SparseMatrix` stores exactly the nonzero entries, columns ascending in each
  row, so equality is mathematical and `nonzeroCount` is pinned (`nnz` in cases.md); a diagonal
  that cancels to 0 (an isolated vertex's L[v][v]) is not stored. Sums are formed in edge-position
  order within a row, then compacted; rows follow vertex indices, or `vertices` order without
  indices (Centrality's convention). Vertex indices are dense by `Graph`'s laws; a graph whose
  positions have holes (a `StableGraph` after a removal) reports no `vertexIndexBound`, so its
  vertices are numbered densely in `vertices` order and the matrix is `vertexCount` square.
- **Access.** `m[i, j]` (the subscript is unlabelled) and `m * x` trap when `i` or `j` is outside
  `0..<rowCount` or `x.count != rowCount`, as `Array` does; `FiedlerVector.value(ofIndex:)` traps
  outside `0..<vertexCount`. `FiedlerVector` is `Sendable` when `G` and `G.Vertex` are
  (`CentralityScores`' rule) and not `Equatable`: it holds the graph; compare `values`.

### Spectra and the Fiedler quantities

- Spectra are all n eigenvalues, ascending, multiplicities repeated. The empty graph has `[]`
  (NetworkX raises; SGT-047). N's spectrum is L_rw's, so there is no separate random-walk
  spectrum.
- `algebraicConnectivity` is λ₂ of L (of N with `normalized: true`), 0 when the graph is not
  connected (SGT-095, as NetworkX); **traps below two vertices** (NetworkX raises; λ₂ does not
  exist; SGT-106).
- `fiedlerVector` is a unit eigenvector of λ₂, `nil` when the graph is not connected (NetworkX
  raises; it is the mathematics, as `findCycle()`), and traps below two vertices.
- `spectralOrdering`: components in order of their least vertex index; a component of at most
  two vertices in index order; a larger one sorted ascending by its own Fiedler vector, entries
  within 10⁻⁸ · max|x| of their predecessor kept in index order (SGT-128, SGT-130). The empty
  graph gives `[]` (NetworkX raises). On a connected graph the vector is exactly
  `fiedlerVector()`'s (same computation, so the ordering is sorted by the vector a caller can
  read, degenerate λ₂ included).
- `spectralRadius` = max |λ(A)|, which for nonnegative weights is λ_max(A) (Perron–Frobenius); 0
  without edges (SGT-145, SGT-146). Negative weights are allowed, as for `adjacencyMatrix`, and
  the definition stays max |λ(A)|: the Lanczos iteration then runs on −A as well and takes the
  larger.

### Electrical quantities

- `numberOfSpanningTrees` = Σ over spanning trees of the product of their weights = any cofactor
  of L (Kirchhoff). Loops never lie on a tree (SGT-164); parallel edges each count (SGT-163). 0
  when not connected and for the empty graph (no tree has no vertex; NetworkX raises), 1 for one
  vertex. A `Double`, as NetworkX: counts pass `Int` quickly (K₂₅ has 25²³, SGT-154; an 8 × 8
  grid 1.26 · 10²⁶, SGT-162). Computed by eliminating the grounded Laplacian as Grassmann,
  Taksar and Heyman eliminate (GTH, 1985; each pivot the sum of the conductances still leaving
  its vertex, never a difference, so entrywise relative accuracy whatever the weights, O'Cinneide
  1993). A Cholesky factorization cancels instead: the path {h, 1} with h = 10¹⁶ gave 0. The
  pivots are multiplied as a significand in [1, 2) with the binary exponent kept apart (a
  logarithm in base 2, without `log`/`exp`), so it overflows only past `Double`'s range (10³⁰⁸)
  and returns `.infinity` there. **Integer weights (unweighted included) give the exact count**
  whenever it is below 2¹⁰⁰: two determinants modulo the primes 2⁶² − 57 and 2⁶² − 87 (Gaussian
  elimination in Montgomery arithmetic, `multipliedFullWidth`), combined by the Chinese
  remainder theorem and rounded once, so every count below 2⁵³ is exact and larger ones are
  correctly rounded. (The phase 1 Cholesky rounded its estimate, and 32 of 136 random graphs with
  counts between 10⁹ and 2⁵³ came out wrong.) A weight counts as an integer when it is one below
  2⁵³; otherwise, or past 2¹⁰⁰, the GTH value is returned unrounded. The catalog pins large counts
  to a relative 10⁻⁹ (SGT-154, SGT-162, SGT-168).
- `resistanceDistance(from: u, to: v)` = (e_u − e_v)ᵀ L⁺ (e_u − e_v), the effective resistance
  when each edge is a conductance w(e). 0 when u = v (SGT-172, SGT-174), returned after checking
  both are vertices and **without reading any weight** (so a negative weight elsewhere does not
  trap R(v, v)); `nil` when they lie in different components (Distances' rule for unreachable;
  NetworkX raises; SGT-173). Traps when either is not a vertex (SGT-183), `from: 7, to: 7`
  included; a `safe:` spelling is not offered (two arguments). For u ≠ v every weight is read and
  checked, also outside the component. `tolerance:` stops the conjugate-gradient solve once the
  residual's Euclidean norm is at most `tolerance` relative to the right-hand side (which has
  norm 1); since R is the energy of the solution, the error in R is of the order of the squared
  energy-norm error, far below `tolerance` · R in practice (10⁻⁴ stays within 10⁻¹ · R,
  conformance). Under a weight spread that puts `tolerance` below the residual's rounding floor
  (about ε · Σ w |x|), the solve stops when the true residual no longer halves between restarts:
  x is then as accurate as rounding allows (300 series bundles with conductances over twelve
  decades: within 10⁻⁸ of the series–parallel law).
- `effectiveGraphResistance` = Σ over unordered pairs of `resistanceDistance` = n · Σ_{i≥2} 1/λᵢ;
  `nil` when not connected (NetworkX returns ∞), 0 for zero or one vertex. Computed as
  n · tr(L_g⁻¹) − 1ᵀ L_g⁻¹ 1 for L grounded at any vertex g (here the one of largest degree), from
  the GTH factor: (I − M)⁻¹ is nonnegative, so tr(L_g⁻¹) and 1ᵀ L_g⁻¹ 1 are sums of positive terms,
  and the difference loses at most a factor n. Σ 1/λᵢ over a dense spectrum lost the relative
  accuracy: λᵢ carries an absolute error ε · λ_max.
- `kemenyConstant` = Σ_{i≥2} 1/μᵢ over N's eigenvalues: the expected steps of the random walk to
  a target drawn from the stationary distribution. The walk takes a loop with probability
  2w/d(v) (two ends), consistent with A. `nil` when not connected (NetworkX raises), 0 for zero
  or one vertex (NetworkX raises on the empty graph). Computed through the fundamental matrix in
  its resistance form: commute times are vol · R(i, j), so K = (1/2vol) Σᵢⱼ dᵢ dⱼ R(i, j) =
  vol · (Σᵢ πᵢ (L_g⁻¹)ᵢᵢ − πᵀ L_g⁻¹ π) with π = d/vol, from the same GTH factor, grounded at the
  vertex of largest degree (the difference then loses at most vol/d_g ≤ n). π rather than d keeps
  the intermediates in range for weights near `Double`'s limits.

## Numerics (decision)

### Algorithms

- **Dense spectra**: Householder tridiagonalization (EISPACK `tred2`), then for eigenvalues
  alone the root-free QL/QR iteration of Pal, Walker and Kahan (LAPACK `dsterf`: squared
  off-diagonals, no square root per rotation, blocks scaled into range), and with vectors (the
  small-n Fiedler path, the Lanczos projections) the implicit QL iteration with Wilkinson shifts
  (`tql2`, LAPACK `dsteqr`'s method), which throws `NoConvergence` if an eigenvalue takes more
  than 60 iterations (the root-free iteration after `maxIterations` in all, 30 n by default, as
  `dsterf`); with the finite entries the preconditions guarantee, neither has been reached. A matrix whose largest entry lies outside 2^±500 is
  first scaled by a power of two, exactly: Householder squares entries. O(n³) time, n² `Double`s.
  Deterministic: one thread, fixed operation order. A blocked reduction (`dsytrd` with `dlatrd`
  panels) was not added: `tred2` already runs at 11.7 GFlop/s at n = 2,000, the QL step is 8 %
  of the time, and the target below is met (see Performance).
- **λ₂, the Fiedler vector, ρ(A)**: thick-restart Lanczos (Wu–Simon 2000; mathematically
  ARPACK's implicitly restarted Lanczos, which SciPy `eigsh` and igraph wrap) with full
  reorthogonalization of each new vector against the basis: the three-term coupling first, one
  full classical Gram–Schmidt pass, and a second only when that pass left less than η = 0.717 of
  the vector (the DGKS criterion, Daniel–Gragg–Kaufman–Stewart 1976). A basis of 30 vectors
  keeps the best 12 Ritz vectors at each restart (measured: 20/8 took 3,752 products and 5.0 s on
  the 300 × 300 grid, 30/12 2,046 and 3.2 s, 40/16 1,552 and 3.0 s at more memory), and the top
  Ritz pair is tested every 5 steps, not only at a restart. The operators share the graph's rows
  (no copy): `Int32` columns, no values for an unweighted graph, A's loops left in place, and for
  L the diagonal σ − d apart (rows with loops are copied once without them).
- **Shift-invert for λ₂ (added in review).** The shifted operator σI − L needs O(√(σ/λ₂))
  products and cannot resolve λ₂ below its rounding floor ε · σ: a 1,000-vertex path with one
  edge of 10⁶ gave λ₂ 280× too large, and a 10⁵-vertex path ran past 500 s. When an upper bound
  on λ₂ (the Rayleigh quotient of the breadth-first distance from a far vertex, two sweeps) puts
  σ/λ₂ above min(0.05 · tolerance/ε, 20 n), or when the shifted run spends 4,000 + 20√n products
  or finds σ/(σ − θ) past that ratio, Lanczos runs on L⁺ instead (D^1/2 L⁺ D^1/2 for N), whose
  largest eigenvalue is 1/λ₂: each product is a conjugate-gradient solve with L grounded at the
  vertex of largest degree (below), to a residual of max(10⁻¹³, 10⁻² · tolerance), followed at
  the end by one more inverse-iteration step so that ‖Lx − λ₂x‖ ≤ tolerance · λ₂ holds for L too
  (FuzzSpectral found the Ritz vector's residual for L at λ_max · tolerance). Measured choice
  (interleaved medians): shift-invert 0.06 s against 1.2 s on the 10⁵ path, 0.03 s against
  0.34 s on G(n, p) 2,000 with weights over six decades, 0.075 s against 0.17 s on the 10 × 1,000
  grid; the shifted operator 0.07 s against 0.17 s on the 100 × 100 grid and 1.3 s against 6.8 s
  on the 300 × 300 grid, so grids (σ/λ₂ ≈ 0.8 n) stay shifted and path-like graphs (≈ 0.4 n²)
  and wide weight spreads go to shift-invert. LOBPCG with a Jacobi preconditioner was the
  alternative: it needs O(√κ(D⁻¹L)) iterations, about n on a path, where shift-invert with the
  incomplete factor below needs a few dozen products.
- **λ₂ is the Rayleigh quotient** of the final vector, Σ over edges of w (x_u − x_v)² (with x/√d
  for N): no term is negative, so it keeps its relative accuracy where σ − θ cancels. On every
  path, dense included.
- **Polynomial acceleration (measured, added).** From 5,000 vertices, when 8 restarts have not
  converged, the iteration starts again from its best Ritz vector on p(M), p the degree-10
  Chebyshev polynomial bounded by 1 on [lower bound, b], b the smallest kept Ritz value (below
  the wanted eigenvalue by interlacing; Saad, *Numerical Methods for Large Eigenvalue Problems*,
  2nd ed., ch. 7; Zhou–Saad's Chebyshev–Davidson filter). p(M) has M's eigenvectors and order
  above b, with the top spread apart, so each reorthogonalized step does the work of ten; the
  null vector is projected out after every polynomial step, and Ritz vectors are judged by their
  residual for M itself. 300 × 300 grid: 3.2 s → 1.0 s; 1000 × 1000 grid: 188–256 s → 42 s.
  While σ/λ₂ is moderate the smallest eigenvalues of L come from the largest of σI − L,
  σ = 2 · max weighted degree (Gershgorin), with no factorization; otherwise shift-invert
  (above). The known null space (the
  indicator vector of each component for L, D^1/2 times it for N) is projected out of the start
  vector and every new Lanczos vector, so λ₂ is the largest eigenvalue of the deflated operator,
  and a disconnected graph is detected by the components pass before any iteration. Below
  n = 64 (a measured threshold) the dense solver is used instead.
- **Why not LOBPCG or TraceMIN in phase 1.** NetworkX defaults to TraceMIN-PCG and offers LOBPCG;
  both need block storage and an inner solver or preconditioner, and their advantage is
  clustered and multiple eigenvalues. Phase 1 needs one eigenpair, for which Lanczos is optimal
  in matrix–vector products among Krylov methods; the baselines below compare. Phase 2's k
  eigenpairs (embedding, clustering) need a block method: LOBPCG with a Jacobi preconditioner.
- **Resistance distance**: conjugate gradients on the Laplacian grounded at `target`, run on the
  rows as they are: the grounded unknown is held at 0 and the product is (Lx)_v = Σ w (x_v − x_u)
  (a loop adds 0), so no grounded copy, no sort and no merge. Jacobi preconditioned for 300
  iterations, then (restarting from where Jacobi stopped) a modified incomplete Cholesky factor
  with no fill (MIC(0), Gustafsson 1978), eliminating in the reverse of Prim's order on a
  maximum-weight spanning tree from the ground, pivots computed GTH-style (sums of the
  conductances still leaving the vertex), so a tree factors exactly and no pivot cancels. Measured
  on a 100 × 100 grid with conductances over 10⁻⁶ … 10⁶: Jacobi alone did not converge in
  40,000 products (phase 1 stopped silently at its cap with an error of 8.6 · 10⁻⁴), IC(0) in
  breadth-first order took 26,559, MIC(0) in this order 79. On G(n, p) Jacobi converges first
  (36 products at 10⁵ vertices, where the factor costs 711), hence the switch. O(m √κ) per pair,
  no n² memory. `effectiveGraphResistance`, `kemenyConstant` and `numberOfSpanningTrees` use the
  dense GTH elimination (O(n³), less on sparse graphs: zero multipliers are skipped). Sparse
  elimination with a fill-reducing order is phase 2 if large inputs ask.
- **Work limits (decision, review; throwing decided later).** Every iterative path counts
  matrix–vector products (a conjugate-gradient iteration is one) and throws `NoConvergence`
  (`throws(NoConvergence)`, the error in `GraphProtocols` that Centrality's power iterations throw
  too) when its limit is spent, with the products spent and the residual on the tolerance's scale:
  Lanczos on σI − L 4,000 + 20√n (then shift-invert, not a failure), shift-invert 1,000, each
  solve 20,000 + 2n, ρ(A) 20,000 + 20√n; the dense spectra after 30 n QL/QR iterations. Each
  public method takes `maxIterations: Int? = nil` in place of the limit that throws (nil keeps
  the default): QL/QR iterations for a spectrum, products per Lanczos run for λ₂, the Fiedler
  vector, the ordering and ρ (a limit given also cuts the run on σI − L short; a solve inside
  shift-invert keeps 20,000 + 2n), conjugate-gradient iterations for a resistance. The budget is
  tested after every step, so a run throws with exactly the limit (a polynomial-filtered step,
  from 5,000 vertices, counts 10). Below 64 vertices λ₂ and ρ come from the dense solver, which
  does not read `maxIterations`. `nil` keeps its one meaning (not connected, different
  components), and an invalid parameter (`tolerance` ≤ 0, `maxIterations` < 1) still traps. The
  name is Eigen's (`ComputationInfo::NoConvergence`); NetworkX raises
  `PowerIterationFailedConvergence` and SciPy `ArpackNoConvergence` in the same place. In the
  measurements only a tolerance below rounding (10⁻³⁰⁰) reached a default limit; phase 1 instead
  ran on (a 10⁵ path past 500 s) or stopped silently.
- **Start vector**: a fixed one, vᵢ = SplitMix64(i)'s 53-bit uniform in [0.5, 1.5) (the counter
  i + 1 times the golden-ratio increment, then SplitMix64's finalizer), so results are
  reproducible bit for bit on one platform and build; across platforms the last bits may differ
  (fused multiply–add), which the tolerances absorb.
- **Stopping rule (relative, changed in review)**: a Ritz pair (θ, x) is accepted when
  ‖Mx − θx‖ ≤ tolerance · λ, λ the eigenvalue sought measured from the shift: σ − θ = λ₂ on
  σI − L, θ = 1/λ₂ on L⁺, θ = ρ on A. So λ₂ and ρ carry a relative error of about `tolerance`
  however the weights spread; the phase 1 rule, tolerance · σ, left λ₂ wrong by orders of
  magnitude when σ/λ₂ was large (σ/λ₂ ≈ 10¹¹ for the path with one edge of 10⁶). Default 1e-8,
  NetworkX's default. The work limits above replace the restart cap and the dense fallback.

### Determinism and degenerate eigenspaces (decision)

- **Eigenvalues** are pinned to the tolerances in cases.md: 1e-9 · max(1, |λ_max|) for dense
  results, 1e-6 · max(1, scale) for iterative ones. **Scale** is the largest |eigenvalue| of the
  matrix concerned: λ_max(L) for `algebraicConnectivity` and `fiedlerVector` (λ_max(N) ≤ 2 with
  `normalized: true`), ρ(A) for `spectralRadius`.
- **Tolerances, unified.** Matrix entries: relative 1e-12 (exact rationals up to rounding).
  Counts, effective graph resistance and the Kemeny constant: relative 1e-9, 1e-9 · max(1, value).
  Spectra: 1e-9 · max(1, |λ_max|). λ₂, ρ and resistance distance: 1e-6 · max(1, scale or R).
  Fiedler entries: 1e-5.
- **Sign**: an eigenvector is defined up to sign. The **canonical sign** makes the first entry (in
  index order) whose magnitude is at least 10⁻⁴ of the largest positive. "Largest entry positive"
  (scikit-learn's `_deterministic_vector_sign_flip`) was rejected: symmetric graphs have ties in
  magnitude with opposite signs (P₄'s ends, SGT-108), exactly where it is ambiguous. The 10⁻⁴
  threshold skips entries that are zero in exact arithmetic (P₅'s middle, SGT-109) but carry
  rounding noise. The rule is documented on `fiedlerVector` and holds for every vector the module
  returns (phase 2's `spectralEmbedding` applies it per column).
- **GraphDrawing.** Its api.md (DR-207 – DR-210, `spectralLayout()`'s x = `fiedlerVector()`) states
  the rule as "the first component of magnitude > 10⁻⁹ is positive". The two agree on every row of
  both catalogs (P₅, the 3 × 4 grid and `lcggraph(12,20,9)` all start with an entry far from 0;
  SGT-109 and SGT-113 equal DR-207's and DR-208's x), but differ when an entry that is 0 in exact
  arithmetic leads: the Lanczos result carries noise of order tolerance · λ₂ there, above
  10⁻⁹, so an absolute 10⁻⁹ threshold would let noise pick the sign. Recommendation: GraphDrawing
  adopts this relative 10⁻⁴ rule (one sentence in its api.md and its `ref.py` `spectral`), and
  `spectralLayout()` reads x from `fiedlerVector()` rather than applying its own rule.
- **Degenerate λ₂** (multiplicity k > 1: K_n, C_n, stars, hypercubes, Petersen) has no unique
  vector, even up to sign. Rows say `degenerate: λ₂ = x ×k` and pin only invariants: λ₂ and k,
  and the test checks that the result is a unit vector orthogonal to the null vector with
  residual and Rayleigh quotient within tolerance (SGT-119 – SGT-122). The vector returned is
  still deterministic (fixed start vector), so two calls agree, but which vector of the
  eigenspace comes out is not part of the contract; pinning it would freeze the start vector
  and the restart schedule. `spectralOrdering` and `spectralBisection` on such graphs are pinned
  only as "sorted by some λ₂ vector".
- **Simple λ₂ with a tiny gap**: the vector is pinned only when the gap to λ₁ and λ₃ is at least
  10⁻⁶ · scale; otherwise the row is treated as degenerate.

### Multigraphs, loops and directed graphs

Parallel edges add their weights; loops follow the conventions above (2 in A, cancel in L).
`Graph` covers `Multigraph`, `Pseudograph` and the undirected views. Directed graphs get the
two matrices in phase 1 (NetworkX's `laplacian_matrix` on a `DiGraph` uses out-degrees; igraph's
`mode="out"` default; SciPy's `csgraph.laplacian` defaults to **in**-degrees, a disagreement);
their spectra are complex (phase 2). Spectral quantities of a directed graph's symmetrization
are `digraph.undirected.…`.

## Platform and dependencies (decision)

**Pure Swift only, on every platform, in phase 1 and 2. No Accelerate, no LAPACK.**

- CI is Linux, and the package's targets are iOS, macOS and Linux. Accelerate exists only on
  Apple platforms; LAPACK on Linux would be a system library (a `systemLibrary` target and an
  `apt` package for every user), which neither SwiftPM users nor the hermetic Bazel build can
  assume. `swift-numerics` has no linear algebra.
- An Accelerate fast path would make results platform-dependent beyond the last bit for
  iterative routines (different algorithms), double the test surface (two engines, one tested
  only on macOS CI) and add `#if canImport` branches to `@inlinable` code.
- The heavy phase 1 work is sparse: matrix–vector products and vector updates, memory-bound, where
  BLAS gains little over a tight Swift loop over `UnsafeBufferPointer`s. The dense paths (full
  spectra, the spanning-tree Cholesky) are the only places LAPACK would win by blocking (2–5× at
  n ≈ 2,000 per the usual reference vs. blocked comparison); they are for small graphs.
- Revisit only if a measured dense-spectrum workload (n ≥ 2,000) is more than 3× slower than
  single-threaded `numpy.linalg.eigvalsh` (OpenBLAS LAPACK `dsyevd`, `OPENBLAS_NUM_THREADS=1`,
  the fair comparison for a one-thread solver), and then as an opt-in Apple-only fast path for
  dense spectra alone, never for the sparse engines. Re-measured in review (interleaved medians,
  random symmetric matrices): NumPy one thread 77 ms at n = 1,000 and 610–730 ms at n = 2,000;
  ours 124 ms and 930–1,030 ms, so 1.4–1.6×. The phase 1 table's 81 and 670 ms were NumPy's
  default threading.
- README edit: the row's "(Accelerate where it's available)" goes (done).

## Implementation notes (index space)

- One pass builds the weighted rows: `_runOnUndirectedRows` (`_withIncidentIndexRows` on
  UndirectedAdjacencyList, else `neighborIndices(ofIndex:)` with `incidentEdgeIndices(ofIndex:)`,
  else `_vertexNumbering()`), and on `DirectedGraph` `_withSuccessorIndexRows` (compressed sparse
  row) or the out-edge rows (Centrality's `_centralityRows`, generalized). Weights are read once
  per edge position into a `[Double]`; a weight-0 edge is left out. The rows store `Int32`
  columns and, for an unweighted graph, no values, and the same pass records Gershgorin's bound
  (the largest Σ |w| over a row), whether a weight is negative and whether a loop occurs, so ρ(A)
  needs no extra pass. A sum that overflows `Double` traps here (and in the degree and merge
  passes) rather than returning infinities.
- Only the matrices and the directed graphs sort and merge: the slots are sorted by column with
  a bucket pass (the transpose; an undirected graph's slots are symmetric, so one pass sorts
  them, a directed graph's take two) and merged (parallel edges, both ends of a loop) into the
  `SparseMatrix` arrays. O(n + m), no comparison sort. The iterative paths (Lanczos, conjugate
  gradients) and the dense ones (accumulating into the n × n array) use the rows as they are.
- The Lanczos engine runs on an operator that shares those rows: y = diag ∘ x + sign · B x, a
  gather per row, not a materialized `SparseMatrix` of L, so `algebraicConnectivity()` allocates
  the rows once plus the basis (31 · n `Double`s; 34 · n with the polynomial filter), and on the
  shift-invert path the solver (5 n) and the incomplete factor (O(n + m)).
- Weights whose Gershgorin bound lies outside 2^±500 are scaled by a power of two (exactly)
  before an iterative path, and the result scaled back (λ and ρ with the weights, R inversely, N
  and vectors not at all): the engines square and sum entries.
- `SparseMatrix` stays square (n × n, `Int` columns, public): an `incidenceMatrix()` would need a
  rectangular |V| × |E| shape it does not have. The incidence matrix of a graph is
  `IncidenceMatrixModule`'s representation; build one from the graph there.
- `SparseMatrix.pattern` wraps `offsets` and `columns` with `CompressedSparseRow`'s package
  initializer (no copy): the dependency `CompressedSparseRowModule` is added to the BUILD file.
- Vertices without indices (`AdjacencyList<String>`) are numbered once by `_vertexNumbering()`;
  `FiedlerVector.value(of:)` hashes once per lookup, as `CentralityScores.score(of:)`.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| matrices | O(n + m) | the result: n + 1 + 2 · nnz words |
| full spectra | O(n³) | n² `Double`s |
| `algebraicConnectivity`, `fiedlerVector`, `spectralOrdering`, `spectralRadius` | O((n + m) · products), products ≈ O(√(σ / gap) · log(1/tol)) on σI − L, a few dozen solves by shift-invert; O(n³) below n = 64 | 31 n `Double`s (34 n from 5,000 vertices); shift-invert adds 7 n and the incomplete factor, O(n + m) |
| `numberOfSpanningTrees` | O(n³) GTH elimination (less when sparse), and for integer weights two modular eliminations | n² `Double`s, n² `UInt64`s |
| `resistanceDistance` | O((n + m) √κ) conjugate gradients | about 9 n words, and the incomplete factor when built |
| `effectiveGraphResistance`, `kemenyConstant` | O(n³) GTH elimination and the diagonal of L_g⁻¹ | n² `Double`s |

## Performance

Baselines from `ref.py --bench` (one run on the development machine, Apple silicon, CPython 3.12,
SciPy 1.18.1 with its bundled OpenBLAS; `> 120 s` is the limit; values in parentheses are the
results; NetworkX's default method, TraceMIN-PCG):

| Input | n | m | NetworkX laplacian_matrix | csgraph.laplacian (CSR in) | eigsh λ₂ (SA, k=2) | eigsh shift 2Δ (LA on 2Δ·I − L, k=2) | NetworkX algebraic_connectivity | eigsh spectral radius (LA, k=1) | dense eigvalsh of L |
|---|---|---|---|---|---|---|---|---|---|
| grid 100×100 | 10000 | 19800 | 12.7 ms | 0.5 ms | 65.2 ms (0.00887607) | 62.4 ms (0.000986879) | 370.9 ms (0.000986879) | 51.3 ms (3.99807) | > 120 s |
| grid 300×300 | 90000 | 179400 | 115.0 ms | 3.3 ms | 3126.1 ms (0.000986879) | 2879.5 ms (0.000109661) | 7515.6 ms (0.000109661) | 1729.1 ms (3.99978) | > 120 s |
| grid 1000×1000 | 1000000 | 1998000 | 1273.1 ms | 33.5 ms | > 120 s | > 120 s | > 120 s | > 120 s | > 120 s |
| random 3-regular, 10⁴ | 10000 | 15000 | 12.6 ms | 0.4 ms | 121.9 ms (0.173098) | 131.9 ms (0.173098) | > 120 s | 10.5 ms (3) | > 120 s |
| random 3-regular, 10⁵ | 100000 | 150000 | 206.9 ms | 3.0 ms | 3242.2 ms (0.172003) | 3913.4 ms (0.172003) | > 120 s | 84.9 ms (3) | > 120 s |
| G(n, p), n = 10⁴, mean degree 10 (giant component) | 9999 | 49708 | 33.1 ms | 0.9 ms | 63.6 ms (0.739232) | 30.4 ms (0.739232) | 1905.3 ms (0.739232) | 5.8 ms (11.0541) | > 120 s |
| G(n, p), n = 10⁵, mean degree 10 (giant component) | 99997 | 499962 | 522.3 ms | 12.3 ms | 815.1 ms (0.741514) | 782.7 ms (0.741514) | 70513.6 ms (0.741514) | 47.7 ms (11.1092) | > 120 s |

[exited with code 0]

Readings: building L costs NetworkX 13 ms per 10⁴ vertices, about 40× SciPy's `csgraph.laplacian`
on a CSR input. **`eigsh(which="SA")` returns a wrong λ₂ on grids** at its default settings and
tol = 10⁻⁸ (100 × 100: 0.00888 for the true 0.000987; 300 × 300: 0.000987 for 0.000110) without
an error: ARPACK accepted a pair from the clustered low end that is not the second smallest. The
Gershgorin shift (largest of 2Δ·I − L, the phase 1 design) gets the right value at the same cost.
NetworkX's TraceMIN-PCG is right but 2–90× slower than the shifted `eigsh`, and passes 120 s on
random 3-regular graphs. Grids are the hard family: λ₂/σ is 1.2 · 10⁻⁵ at 300 × 300, and no
method finished 1000 × 1000 (10⁶ vertices) in 120 s. Dense `eigvalsh` at n = 10⁴ passed 120 s.

Targets for the Swift implementation, measured in the benchmark target on the same inputs
(SciPy `eigsh` is ARPACK, the same Fortran igraph's `eigen_adjacency` and `laplacian` spectra
call, so it stands for igraph; igraph has no Fiedler vector or algebraic connectivity):

| Measure | Target |
|---|---|
| Matrices (`laplacianMatrix()` etc.) on every input above | ≤ 2× `csgraph.laplacian` from a CSR input (O(n + m), one pass plus a per-row sort); ≥ 20× NetworkX `laplacian_matrix` |
| `algebraicConnectivity()` on random 3-regular graphs and G(n, p) (10⁴, 10⁵ vertices) | ≤ the shifted `eigsh` (ARPACK, same operator and tolerance): 0.13 s, 3.9 s, 30 ms, 0.78 s; ≥ 10× NetworkX |
| `algebraicConnectivity()` on grids 100 × 100 and 300 × 300 | correct λ₂ (unlike `eigsh(which="SA")`), within 1.5× the shifted `eigsh` (62 ms, 2.9 s) |
| grid 1000 × 1000 | finishes with the correct λ₂ (9.87 · 10⁻⁶) in under 120 s; if thick-restart Lanczos cannot, that is the trigger to add LOBPCG/TraceMIN with a preconditioner before phase 2 |
| `spectralRadius()` | ≤ 1.5× `eigsh(which="LA", k=1)`: 51 ms, 1.7 s, 11 ms, 85 ms, 6 ms, 48 ms |
| `fiedlerVector()` | the cost of `algebraicConnectivity()` plus O(n) |
| `laplacianSpectrum()` dense | within 3× `numpy.linalg.eigvalsh` (LAPACK `dsyevd`) at n = 1,000 and 2,000 (the Accelerate trigger above) |
| `resistanceDistance(from:to:)` on G(n, p) 10⁵ | ≤ one `scipy.sparse.linalg.cg` solve with a Jacobi preconditioner on the grounded Laplacian |
| Allocations | `algebraicConnectivity()`: the rows, the 31-vector basis (and 3 filter vectors) and O(1) small buffers; no allocation per iteration |

Measured (`SpectralGraphTheoryBenchmarks`, Apple silicon, release, p0 on a shared machine;
the Swift inputs are the same families, `UndirectedAdjacencyList`):

| Measure | Result | Target |
|---|---|---|
| `laplacianMatrix()` | 0.64 ms, 6 ms (grids 100², 300²); 0.53, 6 ms (3-regular 10⁴, 10⁵); 1.7, 20 ms (G(n, p) 10⁴, 10⁵) | met (1.3–2.0× `csgraph.laplacian`) |
| `algebraicConnectivity()` | 47 ms, 1.14 s (grids); 44 ms, 1.04 s (3-regular); 32, 321 ms (G(n, p)) | met (0.3–1.05× the shifted `eigsh`) |
| `algebraicConnectivity()`, review | interleaved with phase 1 on a loaded machine: grid 100² 57 ms (phase 1 47–95), 300² 1.1–3.5 s (1.4–1.6 s), 3-regular 10⁴ 47–88 ms (44–116), 10⁵ 1.4–1.8 s (0.6–1.6 s), G(n, p) 10⁴ 29–134 ms (118–129), 10⁵ 1.0–2.2 s (0.8–1.5 s). The relative rule asks a residual of tolerance · λ₂ rather than tolerance · σ, so the shifted runs take up to 1.5× more products; a 10⁵ path takes 0.06–0.14 s by shift-invert (phase 1: over 500 s) | the 10⁵-vertex targets need re-measuring on a quiet machine (`just bench`) |
| grid 1000 × 1000 | 45 s, λ₂ = 9.8695963 · 10⁻⁶ (exact 9.8695963 · 10⁻⁶); review, with the relative stopping rule: 42.7 s, λ₂ = 9.869596284 · 10⁻⁶ | met (thick restart alone: 188–256 s; the Chebyshev filter brought it under) |
| `spectralRadius()` | 23 ms, 0.64 s (grids); 6, 71 ms (3-regular); 6.8, 76 ms (G(n, p)). Review (interleaved with the phase 1 code on a loaded machine, so read the ratios): G(n, p) 10⁵ 41–160 ms against 220–610 ms (47 ms quiet, against 78), grids and 3-regular within the noise | met: the G(n, p) miss was the iteration (30 products, then a restart's worth of reorthogonalization), not the setup; the top Ritz pair is now tested every 5 steps, and the operator shares the rows (no copy, `Int32` columns, no values array unweighted) |
| `laplacianSpectrum()` | 124 ms (n = 1000), 1.96 s (n = 2000); review, random symmetric matrices interleaved with single-threaded NumPy: 124 ms against 77 ms, 0.93–1.03 s against 0.61–0.73 s | met (1.4–1.6× single-threaded `dsyevd`; the phase 1 comparison was against NumPy's threaded default) |
| `resistanceDistance` on G(n, p) 10⁵ | phase 1 87 ms; review 48–55 ms (interleaved: 87–145 ms for phase 1); SciPy's Jacobi `cg` on a prebuilt grounded Laplacian 51 ms | met: conjugate gradients run on the rows with the ground held at 0, so no grounded copy, sort or merge |

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Undirected self-loops in A | NetworkX (`adjacency_matrix`, and through it `normalized_laplacian_matrix`, `adjacency_spectrum`, `normalized_laplacian_spectrum`, `kemeny_constant`) puts 1 per loop on the diagonal and so counts a loop once in the degree; SciPy `csgraph.laplacian` ignores the diagonal entirely; igraph's default counts 2. Ours: 2 (degree rule, Centrality's rows). L agrees everywhere: loops cancel | SGT-016, SGT-018, SGT-074, SGT-076, SGT-201 |
| `algebraic_connectivity(normalized=True)`, `fiedler_vector(normalized=True)` | NetworkX drops self-loops before forming N (its `_preprocess_graph`), while its `normalized_laplacian_matrix` keeps them once: NetworkX disagrees with itself. Ours: loops in the degree | SGT-104 |
| `fiedler_vector` on two vertices | NetworkX returns `[1, -1]`, not a unit vector; ours is unit length | `--stress` |
| `algebraic_connectivity(method="lanczos")` | Seen once returning λ₃ (0.1958) for the 10 × 10 grid, whose λ₂ = 0.0979 has multiplicity 2; not reproduced on later runs (ARPACK's start vector) | SGT-092 |
| Empty graphs | NetworkX raises on `laplacian_spectrum`, `spectral_ordering`, `number_of_spanning_trees`, `effective_graph_resistance`, `kemeny_constant`. Ours: `[]`, `[]`, 0, 0, 0 | SGT-047, SGT-134, SGT-148, SGT-185, SGT-194 |
| Disconnected inputs | NetworkX: `fiedler_vector` and `kemeny_constant` raise, `resistance_distance` raises, `effective_graph_resistance` returns ∞. Ours: `nil` for all four (the result does not exist; Distances' convention) | SGT-123, SGT-173, SGT-192, SGT-203 |
| `spectral_bisection` with a zero Fiedler entry | NetworkX puts the vertex on the side of its rounding noise's sign (`v >= 0`), so P₅'s middle vertex moves between runs; ours: entries within 10⁻⁸ · max|x| of 0 join the nonnegative side, after the canonical sign | SGT-215 |
| `resistance_distance` weights | NetworkX's default `invert_weight=True` reads `weight` as a resistance (1/w in L); ours reads every weight as a conductance, as `laplacianMatrix(weight:)` does (pass `{ 1 / r($0) }`) | SGT-176 |
| `number_of_spanning_trees` | NetworkX returns `float(det(...))`, so K₅ gives 125.00000000000004; ours is exact for integer weights below 2¹⁰⁰ (modular determinants, Chinese remainder) and otherwise multiplies GTH pivots with the exponent kept apart | SGT-152 |
| SciPy `eigsh(L, k=2, which="SA")` | Returns a wrong λ₂ on the 100 × 100 and 300 × 300 grids without an error (Performance); the shifted largest-eigenvalue problem is right | `--bench` |
| Directed Laplacian | NetworkX and igraph use out-degrees; SciPy `csgraph.laplacian` defaults to in-degrees (`use_out_degree=False`) | SGT-041 |
| Isolated vertex in N | NetworkX, SciPy: N[v][v] = 0 (ours too); some texts define N = I − D^-1/2 A D^-1/2 with 1 there | SGT-023 |

## README edits proposed

- `SpectralGraphTheory` row: "On `Graph`: `adjacencyMatrix()`, `laplacianMatrix()`,
  `normalizedLaplacianMatrix()`, `randomWalkLaplacianMatrix()`, `signlessLaplacianMatrix()` (also
  the first two on `DirectedGraph`, out-degrees) as a `SparseMatrix`; `adjacencySpectrum()`,
  `laplacianSpectrum()`, `normalizedLaplacianSpectrum()` (dense); `algebraicConnectivity()`,
  `fiedlerVector()`, `spectralOrdering()`, `spectralRadius()` (thick-restart Lanczos);
  `numberOfSpanningTrees()`, `resistanceDistance(from:to:)`, `effectiveGraphResistance()`,
  `kemenyConstant()`; unweighted and weighted; pure Swift. Later (phase 2): directed spanning
  arborescences, spectral bisection, embedding and clustering (LOBPCG), partial spectra, Chung's
  directed Laplacian." Result types: `SparseMatrix`, `FiedlerVector`.
- Drop "(Accelerate where it's available)".
- Terminology rows: "D − A: Laplacian (NetworkX, igraph, SciPy); Kirchhoff matrix (Mathematica)";
  "Σ pairwise effective resistances: effective graph resistance (NetworkX); Kirchhoff index
  (chemistry)".
- BUILD: add `CompressedSparseRowModule` to the module's dependencies (for `pattern`).

## Open questions (with recommendations)

1. **Element type of `SparseMatrix`.** *Recommendation:* `Double` only (above). A generic
   `SparseMatrix<Scalar>` only if `GraphFormats`' Matrix Market reader wants integer or complex
   matrices; then this type moves to its own module in the final reuse pass.
2. **Iteration cap.** *Decided in review:* every iterative path has a work limit in products.
   *Revised:* spending it throws `NoConvergence` instead of trapping, and each method takes an
   optional `maxIterations:` (nil: the limit), as Centrality does (Numerics, "Work limits").
3. **Small-n threshold** (dense below 64 vertices): kept at 64; the Lanczos path at 64–200
   vertices takes well under a millisecond, so nothing argues for moving it.
4. **`numberOfSpanningTrees` exactness.** *Decided:* `Double`, as NetworkX, but exact (correctly
   rounded) for integer weights while the count is below 2¹⁰⁰, by two modular determinants and
   the Chinese remainder theorem. An exact count past that needs a `BigInt` the package does not
   have (IsomorphismModule's `order` made the same choice).
