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

    // Full spectra, ascending (dense; O(n³) time, O(n²) memory)
    public func adjacencySpectrum() -> [Double]
    public func laplacianSpectrum() -> [Double]
    public func normalizedLaplacianSpectrum() -> [Double]

    // Sparse (thick-restart Lanczos; dense below 64 vertices); each also with weight: first
    public func algebraicConnectivity(normalized: Bool = false, tolerance: Double = 1e-8) -> Double
    public func fiedlerVector(normalized: Bool = false, tolerance: Double = 1e-8) -> FiedlerVector<Self>?
    public func spectralOrdering(normalized: Bool = false, tolerance: Double = 1e-8) -> [Vertex]
    public func spectralRadius(tolerance: Double = 1e-8) -> Double   // weight: may be negative

    // Matrix-tree theorem and electrical networks; each also with weight: (a conductance)
    public func numberOfSpanningTrees() -> Double
    public func resistanceDistance(from source: Vertex, to target: Vertex, tolerance: Double = 1e-10) -> Double?
    public func resistanceDistance<W>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10) -> Double?
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
  grid 1.26 · 10²⁶, SGT-162). Computed by a Cholesky factorization of the grounded Laplacian,
  the pivots multiplied as a significand in [1, 2) with the binary exponent kept apart (a
  logarithm in base 2, without `log`/`exp`), so it overflows only past `Double`'s range (10³⁰⁸)
  and returns `.infinity` there. When every weight is an integer (unweighted included) a result
  below 2⁵³ is rounded to the nearest integer. **Counts near 2⁵³ are not exact**: the
  factorization carries a relative error of order n · 10⁻¹⁶, so once the count is within a few
  units of 2⁵³ (or above it) rounding may land on a neighbouring integer; the catalog pins such
  counts to a relative 10⁻⁹ (SGT-154, SGT-162, SGT-168).
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
  conformance).
- `effectiveGraphResistance` = Σ over unordered pairs of `resistanceDistance` = n · Σ_{i≥2} 1/λᵢ;
  `nil` when not connected (NetworkX returns ∞), 0 for zero or one vertex.
- `kemenyConstant` = Σ_{i≥2} 1/μᵢ over N's eigenvalues: the expected steps of the random walk to
  a target drawn from the stationary distribution. The walk takes a loop with probability
  2w/d(v) (two ends), consistent with A. `nil` when not connected (NetworkX raises), 0 for zero
  or one vertex (NetworkX raises on the empty graph).

## Numerics (decision)

### Algorithms

- **Dense spectra**: Householder tridiagonalization, then the implicit symmetric QL iteration
  with Wilkinson shifts (EISPACK `tql1`/`tql2`, LAPACK `dsteqr`'s method), eigenvalues only;
  `eigh`-style vectors for the small-n path of the Fiedler vector. O(n³) time, n² `Double`s.
  Deterministic: one thread, fixed operation order.
- **λ₂, the Fiedler vector, ρ(A)**: thick-restart Lanczos (Wu–Simon 2000; mathematically
  ARPACK's implicitly restarted Lanczos, which SciPy `eigsh` and igraph wrap) with full
  reorthogonalization of each new vector against the basis (classical Gram–Schmidt applied twice,
  Daniel–Gragg–Kaufman–Stewart; in the implementation, the three-term coupling first, then one
  full classical Gram–Schmidt pass), a basis of 30 vectors keeping the best 12 Ritz vectors at
  each restart (measured: 20/8 took 3,752 products and 5.0 s on the 300 × 300 grid, 30/12 2,046
  and 3.2 s, 40/16 1,552 and 3.0 s at more memory).
- **Polynomial acceleration (measured, added).** From 5,000 vertices, when 4 restarts have not
  converged, the iteration starts again from its best Ritz vector on p(M), p the degree-10
  Chebyshev polynomial bounded by 1 on [lower bound, b], b the smallest kept Ritz value (below
  the wanted eigenvalue by interlacing; Saad, *Numerical Methods for Large Eigenvalue Problems*,
  2nd ed., ch. 7; Zhou–Saad's Chebyshev–Davidson filter). p(M) has M's eigenvectors and order
  above b, with the top spread apart, so each reorthogonalized step does the work of ten; the
  null vector is projected out after every polynomial step, and Ritz vectors are judged by their
  residual for M itself. 300 × 300 grid: 3.2 s → 1.0 s; 1000 × 1000 grid: 188–256 s → 42 s. The smallest eigenvalues of L come from the largest of σI − L, σ = 2 · max weighted
  degree (Gershgorin), so no factorization (shift-invert) is needed. The known null space (the
  indicator vector of each component for L, D^1/2 times it for N) is projected out of the start
  vector and every new Lanczos vector, so λ₂ is the largest eigenvalue of the deflated operator,
  and a disconnected graph is detected by the components pass before any iteration. Below
  n = 64 (a measured threshold) the dense solver is used instead.
- **Why not LOBPCG or TraceMIN in phase 1.** NetworkX defaults to TraceMIN-PCG and offers LOBPCG;
  both need block storage and an inner solver or preconditioner, and their advantage is
  clustered and multiple eigenvalues. Phase 1 needs one eigenpair, for which Lanczos is optimal
  in matrix–vector products among Krylov methods; the baselines below compare. Phase 2's k
  eigenpairs (embedding, clustering) need a block method: LOBPCG with a Jacobi preconditioner.
- **Resistance distance**: conjugate gradients on the Laplacian grounded at `target` (row and
  column removed) restricted to the component, Jacobi preconditioned, from zero, solving for
  `source`'s column: O(m √κ) per pair, no n² memory. `effectiveGraphResistance` and
  `kemenyConstant` use the dense spectrum (n · Σ 1/λᵢ); `numberOfSpanningTrees` a dense
  Cholesky (O(n³)). Sparse Cholesky with a fill-reducing order is phase 2 if large inputs ask.
- **Start vector**: a fixed one, vᵢ = SplitMix64(i)'s 53-bit uniform in [0.5, 1.5) (the counter
  i + 1 times the golden-ratio increment, then SplitMix64's finalizer), so results are
  reproducible bit for bit on one platform and build; across platforms the last bits may differ
  (fused multiply–add), which the tolerances absorb.
- **Stopping rule**: a Ritz pair (θ, x) is accepted when ‖Mx − θx‖ ≤ tolerance · σ, σ the
  Gershgorin bound (for `spectralRadius`, Gershgorin's bound on |λ(A)|, max over rows of Σ|A|) (SciPy `eigsh`'s `tol` and NetworkX's `tol` are relative the same way);
  default 1e-8, NetworkX's default. Lanczos with full reorthogonalization over at most n
  directions terminates; the restart loop is capped at max(100, n) restarts, after which the
  dense solver runs when n ≤ 4,096, and otherwise the best Ritz pair is returned (documented,
  no `nil`: unlike Centrality's power iterations, Lanczos does not fail to converge on a
  symmetric matrix, it only slows on clustered spectra).

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
  arithmetic leads: the Lanczos result carries noise of order tolerance · σ ≈ 10⁻⁸ there, above
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
  `numpy.linalg.eigvalsh` (OpenBLAS/Accelerate LAPACK `dsyevd`), and then as an opt-in Apple-only
  fast path for dense spectra alone, never for the sparse engines.
- README edit: the row's "(Accelerate where it's available)" goes (done).

## Implementation notes (index space)

- One pass builds the weighted rows: `_runOnUndirectedRows` (`_withIncidentIndexRows` on
  UndirectedAdjacencyList, else `neighborIndices(ofIndex:)` with `incidentEdgeIndices(ofIndex:)`,
  else `_vertexNumbering()`), and on `DirectedGraph` `_withSuccessorIndexRows` (compressed sparse
  row) or the out-edge rows (Centrality's `_centralityRows`, generalized). Weights are read once
  per edge position into a `[Double]`. The slots are then sorted by column with a bucket pass
  (the transpose; an undirected graph's slots are symmetric, so one pass sorts them, a directed
  graph's take two) and merged (parallel edges, both ends of a loop) into the `SparseMatrix`
  arrays. O(n + m), no comparison sort.
- The Lanczos engine runs on an operator built from the merged rows: the shifted diagonal apart
  and the off-diagonal entries in compressed sparse rows (y = diag ∘ x + B x, a gather per row),
  not on a materialized `SparseMatrix` of L, so `algebraicConnectivity()` allocates the rows and
  the operator once plus the basis (31 · n `Double`s; 34 · n with the polynomial filter).
- `SparseMatrix.pattern` wraps `offsets` and `columns` with `CompressedSparseRow`'s package
  initializer (no copy): the dependency `CompressedSparseRowModule` is added to the BUILD file.
- Vertices without indices (`AdjacencyList<String>`) are numbered once by `_vertexNumbering()`;
  `FiedlerVector.value(of:)` hashes once per lookup, as `CentralityScores.score(of:)`.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| matrices | O(n + m) | the result: n + 1 + 2 · nnz words |
| full spectra | O(n³) | n² `Double`s |
| `algebraicConnectivity`, `fiedlerVector`, `spectralOrdering`, `spectralRadius` | O((n + m) · iterations), iterations ≈ O(√(σ / gap) · log(1/tol)) for Lanczos; O(n³) below n = 64 | 31 n `Double`s (34 n from 5,000 vertices) |
| `numberOfSpanningTrees` | O(n³) dense Cholesky | n² `Double`s |
| `resistanceDistance` | O((n + m) √κ) conjugate gradients | 5 n `Double`s |
| `effectiveGraphResistance`, `kemenyConstant` | O(n³) (the dense spectrum) | n² `Double`s |

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
| grid 1000 × 1000 | 45 s, λ₂ = 9.8695963 · 10⁻⁶ (exact 9.8695963 · 10⁻⁶) | met (thick restart alone: 188–256 s; the Chebyshev filter brought it under) |
| `spectralRadius()` | 23 ms, 0.64 s (grids); 6, 71 ms (3-regular); 6.8, 76 ms (G(n, p)) | met except G(n, p) 10⁵: 1.6× (`eigsh` 48 ms); the iteration takes 30 products, the rest is copying the rows and building the operator |
| `laplacianSpectrum()` | 124 ms (n = 1000), 1.96 s (n = 2000); NumPy `eigvalsh` 81, 670 ms on this machine | met (1.5×, 2.9×), so no Accelerate path |
| `resistanceDistance` on G(n, p) 10⁵ | 87 ms; SciPy's Jacobi `cg` on a prebuilt grounded Laplacian 51 ms | **missed**, 1.7×: the call reads the graph, finds the component and grounds L, which SciPy's timing leaves out |

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
| `number_of_spanning_trees` | NetworkX returns `float(det(...))`, so K₅ gives 125.00000000000004; ours multiplies Cholesky pivots with the exponent kept apart and rounds to the nearest integer when every weight is an integer and the count is below 2⁵³ | SGT-152 |
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
2. **Iteration cap.** *Recommendation:* no `maxIterations:` parameter and no `nil` on
   non-convergence (above); reconsider if the grid benchmarks show the restart cap reached.
3. **Small-n threshold** (dense below 64 vertices): kept at 64; the Lanczos path at 64–200
   vertices takes well under a millisecond, so nothing argues for moving it.
4. **`numberOfSpanningTrees` exactness.** *Recommendation:* `Double`, as NetworkX. An exact
   `BigInt` count needs a dependency the package does not have (IsomorphismModule's `order` made
   the same choice).
