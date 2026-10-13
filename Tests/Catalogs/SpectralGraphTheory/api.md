# SpectralGraphTheory: API

Graph matrices (adjacency, Laplacian, normalized, random-walk and signless Laplacians) as a
square `SparseMatrix`; full spectra of small graphs; the algebraic connectivity, Fiedler vector,
spectral ordering and spectral radius of large sparse graphs by a Lanczos iteration; and the
quantities of the matrix-tree theorem and of electrical networks: the number of spanning trees,
resistance distance, effective graph resistance and the Kemeny constant. Everything is pure
Swift, on every platform, with no package dependency beyond the library.

`cases.md` (SGT-001 – SGT-217, 217 rows) pins the values; SGT-205 – SGT-217 describe quantities
that no entry point computes and have no tests. `ref.py` builds every matrix from the definitions
below in exact fractions, takes spectra from `numpy.linalg.eigvalsh`, counts spanning trees and
resistances exactly (Kirchhoff determinants), and checks rows against closed forms (complete,
path, cycle, star, complete bipartite, hypercube, grid and Petersen spectra), brute-force
spanning-tree and arborescence enumeration, the pseudoinverse, NetworkX 3.7 and SciPy 1.18.1.
`--stress` adds 1,000 random multigraphs with loops and weights (up to 7 vertices and 12 edges).
Run:

`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.5.4 python3 Tests/Catalogs/SpectralGraphTheory/ref.py [--write] [--stress] [--bench]`

## Scope

On `Graph`; the two matrices marked also on `DirectedGraph`.

| Entry point | Purpose |
|---|---|
| `adjacencyMatrix()` (also `DirectedGraph`) | A |
| `laplacianMatrix()` (also `DirectedGraph`: out-degrees) | L = D − A |
| `normalizedLaplacianMatrix()` | N = D^-1/2 L D^-1/2 |
| `randomWalkLaplacianMatrix()` | I − D⁻¹A, von Luxburg's L_rw, the matrix Shi–Malik spectral clustering uses |
| `signlessLaplacianMatrix()` | D + A, Cvetković–Rowlinson–Simić's signless Laplacian (its least eigenvalue is 0 exactly on bipartite components) |
| `adjacencySpectrum()`, `laplacianSpectrum()`, `normalizedLaplacianSpectrum()` → `[Double]` ascending | Dense, for small graphs (O(n³)) |
| `algebraicConnectivity(normalized:tolerance:)` → `Double` | Fiedler 1973. Sparse (Lanczos) |
| `fiedlerVector(normalized:tolerance:)` → `FiedlerVector<Self>?` | `nil` when the graph is not connected |
| `spectralOrdering(normalized:tolerance:)` → `[Vertex]` | The Fiedler vector's main use (envelope reduction, seriation; Barnard–Pothen–Simon) |
| `spectralRadius(tolerance:)` → `Double` | ρ(A), the largest eigenvalue magnitude (Cvetković–Rowlinson–Simić). Sparse (Lanczos) |
| `numberOfSpanningTrees()` → `Double` | Kirchhoff's matrix-tree theorem |
| `resistanceDistance(from:to:)` → `Double?` | Klein–Randić 1993. One Laplacian solve, not a pseudoinverse |
| `effectiveGraphResistance()` → `Double?` | The Kirchhoff index of Klein–Randić |
| `kemenyConstant()` → `Double?` | The expected steps of the random walk to a stationary target |

Every entry point has `weight:` overloads, one for `BinaryInteger` and one for
`BinaryFloatingPoint` weights, reading the weight of the edge at each position once. `weight:`
comes first on graph-wide calls (`algebraicConnectivity(weight:normalized:tolerance:)`), and after
the vertices on `resistanceDistance(from:to:weight:tolerance:)`.

Spectral quantities of a directed graph's symmetrization are `digraph.undirectedView.…`. Matrix
entries are `Double`, since every consumer is floating point and an integer Laplacian of a
weighted multigraph would overflow silently.

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
}

extension DirectedGraph {
    public func adjacencyMatrix() -> SparseMatrix              // A[u][v] = arcs u → v; a loop adds 1
        public func laplacianMatrix() -> SparseMatrix              // D_out − A
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
    public func value(checked vertex: G.Vertex) throws(VertexNotFound) -> Double  // throws instead
    public func value(ofIndex index: Int) -> Double  // traps outside 0..<vertexCount
}
```

## Semantics

### Matrices (definitions; what every row checks)

With w(e) the weight of edge e (1 without `weight:`):

- **A** (`adjacencyMatrix`): A[u][v] = Σ w(e) over the edges e between u and v. **An undirected
  self-loop adds 2·w(e) to A[v][v]**, so row sums equal `degree(of:)` (a loop has two ends,
  `Graph`'s rule) and A = B Bᵀ − 2·diag over the unoriented incidence matrix B, the matrix
  `Centrality`'s eigenvector iteration uses (its rows list a loop twice). On `DirectedGraph`:
  A[u][v] = Σ w over arcs u → v, a loop adds w once. Parallel edges add up (SGT-013, SGT-030,
  SGT-044).
- **D** = diag(row sums of A), the weighted degrees (out-degrees on `DirectedGraph`).
- **L** = D − A (`laplacianMatrix`). Self-loops cancel: L = B̃ B̃ᵀ over the oriented incidence
  matrix, in which a loop column is zero (SGT-017, SGT-043).
- **N** = D^-1/2 L D^-1/2 (`normalizedLaplacianMatrix`), with D^-1/2 = 0 at a vertex of degree 0,
  so an isolated vertex has a zero row and column (SGT-023). Loops count in D (twice), so
  N[v][v] = 1 − 2·loops/d(v) (SGT-018).
- **L_rw** = D⁻¹ L (`randomWalkLaplacianMatrix`), zero rows at degree 0 (SGT-024).
- **Q** = D + A (`signlessLaplacianMatrix`); with the loop convention, Q = B Bᵀ (a loop adds 4,
  SGT-020).
- **Weights.** Laplacian-family matrices, spectra, Fiedler quantities, counts and resistances
  require every weight finite and ≥ 0 (a trap otherwise, SGT-032 – SGT-034, SGT-084, SGT-184): their
  theorems (positive semidefiniteness, the matrix-tree theorem, Rayleigh monotonicity) need it.
  `adjacencyMatrix`, `adjacencySpectrum` and `spectralRadius` accept any finite weight (SGT-031);
  NaN and infinity trap everywhere (SGT-035). A weight-0 edge is no edge: it stores nothing
  (SGT-029) and does not connect (SGT-100, SGT-125, SGT-182). Weights are conductances, the
  Laplacian's own weights, everywhere in the module, resistance included.
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
  (SGT-047). N's spectrum is L_rw's, so there is no separate random-walk spectrum.
- `algebraicConnectivity` is λ₂ of L (of N with `normalized: true`), 0 when the graph is not
  connected (SGT-095); **traps below two vertices** (λ₂ does not exist; SGT-106).
- `fiedlerVector` is a unit eigenvector of λ₂, `nil` when the graph is not connected, and traps
  below two vertices.
- `spectralOrdering`: components in order of their least vertex index; a component of at most
  two vertices in index order; a larger one sorted ascending by its own Fiedler vector, entries
  within 10⁻⁸ · max|x| of their predecessor kept in index order (SGT-128, SGT-130). The empty
  graph gives `[]`. On a connected graph the vector is exactly
  `fiedlerVector()`'s (same computation, so the ordering is sorted by the vector a caller can
  read, degenerate λ₂ included).
- `spectralRadius` = max |λ(A)|, which for nonnegative weights is λ_max(A) (Perron–Frobenius); 0
  without edges (SGT-145, SGT-146). Negative weights are allowed, as for `adjacencyMatrix`, and
  the definition stays max |λ(A)|: the Lanczos iteration then runs on −A as well and takes the
  larger.

### Electrical quantities

- `numberOfSpanningTrees` = Σ over spanning trees of the product of their weights = any cofactor
  of L (Kirchhoff). Loops never lie on a tree (SGT-164); parallel edges each count (SGT-163). 0
  when not connected and for the empty graph (no tree has no vertex), 1 for one vertex. A
  `Double`: counts pass `Int` quickly (K₂₅ has 25²³, SGT-154; an 8 × 8
  grid 1.26 · 10²⁶, SGT-162). Computed by eliminating the grounded Laplacian as Grassmann,
  Taksar and Heyman eliminate (GTH, 1985; each pivot the sum of the conductances still leaving
  its vertex, never a difference, so entrywise relative accuracy whatever the weights, O'Cinneide
  1993). The pivots are multiplied as a significand in [1, 2) with the binary exponent kept apart (a
  logarithm in base 2, without `log`/`exp`), so it overflows only past `Double`'s range (10³⁰⁸)
  and returns `.infinity` there. **Integer weights (unweighted included) give the exact count**
  whenever it is below 2¹⁰⁰: two determinants modulo the primes 2⁶² − 57 and 2⁶² − 87 (Gaussian
  elimination in Montgomery arithmetic, `multipliedFullWidth`), combined by the Chinese
  remainder theorem and rounded once, so every count below 2⁵³ is exact and larger ones are
  correctly rounded. A weight counts as an integer when it is one below
  2⁵³; otherwise, or past 2¹⁰⁰, the GTH value is returned unrounded. The catalog pins large counts
  to a relative 10⁻⁹ (SGT-154, SGT-162, SGT-168).
- `resistanceDistance(from: u, to: v)` = (e_u − e_v)ᵀ L⁺ (e_u − e_v), the effective resistance when
  each edge is a conductance w(e). 0 when u = v (SGT-172, SGT-174), returned after checking both are
  vertices and **without reading any weight** (so a negative weight elsewhere does not trap R(v,
  v)); `nil` when they lie in different components (Distances' rule for unreachable; SGT-173). Traps
  when either is not a vertex (SGT-183), `from: 7, to: 7` included. For u ≠ v every weight is read
  and checked, also outside the component. `tolerance:` stops the conjugate-gradient solve once the
  residual's Euclidean norm is at most `tolerance` relative to the right-hand side (which has norm
  1); since R is the energy of the solution, the error in R is of the order of the squared
  energy-norm error, far below `tolerance` · R in practice. Under a weight spread that puts
  `tolerance` below the residual's rounding floor (about ε · Σ w |x|), the solve stops when the true
  residual no longer halves between restarts: x is then as accurate as rounding allows.
- `effectiveGraphResistance` = Σ over unordered pairs of `resistanceDistance` = n · Σ_{i≥2} 1/λᵢ;
  `nil` when not connected, 0 for zero or one vertex. Computed as
  n · tr(L_g⁻¹) − 1ᵀ L_g⁻¹ 1 for L grounded at any vertex g (here the one of largest degree), from
  the GTH factor: (I − M)⁻¹ is nonnegative, so tr(L_g⁻¹) and 1ᵀ L_g⁻¹ 1 are sums of positive terms,
  and the difference loses at most a factor n. (Σ 1/λᵢ over a dense spectrum would not keep
  relative accuracy: λᵢ carries an absolute error ε · λ_max.)
- `kemenyConstant` = Σ_{i≥2} 1/μᵢ over N's eigenvalues: the expected steps of the random walk to
  a target drawn from the stationary distribution. The walk takes a loop with probability
  2w/d(v) (two ends), consistent with A. `nil` when not connected, 0 for zero
  or one vertex. Computed through the fundamental matrix in
  its resistance form: commute times are vol · R(i, j), so K = (1/2vol) Σᵢⱼ dᵢ dⱼ R(i, j) =
  vol · (Σᵢ πᵢ (L_g⁻¹)ᵢᵢ − πᵀ L_g⁻¹ π) with π = d/vol, from the same GTH factor, grounded at the
  vertex of largest degree (the difference then loses at most vol/d_g ≤ n). π rather than d keeps
  the intermediates in range for weights near `Double`'s limits.

## Numerics

### Algorithms

- **Dense spectra**: Householder tridiagonalization (`tred2`, Martin, Reinsch and Wilkinson),
  then for eigenvalues alone the root-free QL/QR iteration of Pal, Walker and Kahan (squared
  off-diagonals, no square root per rotation, blocks scaled into range), and with vectors (the
  small-n Fiedler path, the Lanczos projections) the implicit QL iteration with Wilkinson shifts
  (`tql2`), which throws `NoConvergence` if an eigenvalue takes more than 60 iterations (the
  root-free iteration after `maxIterations` in all, 30 n by default). A matrix whose largest entry
  lies outside 2^±500 is first scaled by a power of two, exactly. O(n³) time, n² `Double`s.
  Deterministic: one thread, fixed operation order.
- **λ₂, the Fiedler vector, ρ(A)**: thick-restart Lanczos (Wu–Simon 2000) with full
  reorthogonalization of each new vector against the basis: the three-term coupling first, one
  full classical Gram–Schmidt pass, and a second only when that pass left less than η = 0.717 of
  the vector (the DGKS criterion, Daniel–Gragg–Kaufman–Stewart 1976). A basis of 30 vectors keeps
  the best 12 Ritz vectors at each restart, and the top Ritz pair is tested every 5 steps. The
  operators share the graph's rows (no copy): `Int32` columns, no values for an unweighted graph,
  A's loops left in place, and for L the diagonal σ − d apart.
- **The shifted operator.** While σ/λ₂ is moderate the smallest eigenvalues of L come from the
  largest of σI − L, σ = 2 · max weighted degree (Gershgorin), with no factorization. The known
  null space (the indicator vector of each component for L, D^1/2 times it for N) is projected out
  of the start vector and every new Lanczos vector, so λ₂ is the largest eigenvalue of the
  deflated operator, and a disconnected graph is detected by the components pass before any
  iteration. Below n = 64 the dense solver is used instead.
- **Shift-invert for λ₂.** The shifted operator needs O(√(σ/λ₂)) products and cannot resolve λ₂
  below its rounding floor ε · σ. When an upper bound on λ₂ (the Rayleigh quotient of the
  breadth-first distance from a far vertex, two sweeps) puts σ/λ₂ above min(0.05 · tolerance/ε,
  20 n), or when the shifted run spends 4,000 + 20√n products or finds σ/(σ − θ) past that ratio,
  Lanczos runs on L⁺ instead (D^1/2 L⁺ D^1/2 for N), whose largest eigenvalue is 1/λ₂: each
  product is a conjugate-gradient solve with L grounded at the vertex of largest degree (below),
  to a residual of max(10⁻¹³, 10⁻² · tolerance), followed at the end by one more inverse-iteration
  step so that ‖Lx − λ₂x‖ ≤ tolerance · λ₂ holds for L too. Grids (σ/λ₂ ≈ 0.8 n) stay on the
  shifted operator; path-like graphs (≈ 0.4 n²) and wide weight spreads go to shift-invert.
- **λ₂ is the Rayleigh quotient** of the final vector, Σ over edges of w (x_u − x_v)² (with x/√d
  for N): no term is negative, so it keeps its relative accuracy where σ − θ cancels.
- **Polynomial acceleration.** From 5,000 vertices, when 8 restarts have not converged, the
  iteration starts again from its best Ritz vector on p(M), p the degree-10 Chebyshev polynomial
  bounded by 1 on [lower bound, b], b the smallest kept Ritz value (Saad, *Numerical Methods for
  Large Eigenvalue Problems*, 2nd ed., ch. 7; Zhou–Saad's Chebyshev–Davidson filter). p(M) has
  M's eigenvectors and order above b, with the top spread apart; the null vector is projected out
  after every polynomial step, and Ritz vectors are judged by their residual for M itself.
- **Resistance distance**: conjugate gradients on the Laplacian grounded at `target`, run on the
  rows as they are: the grounded unknown is held at 0 and the product is (Lx)_v = Σ w (x_v − x_u)
  (a loop adds 0). Jacobi preconditioned for 300 iterations, then (restarting from where Jacobi
  stopped) a modified incomplete Cholesky factor with no fill (MIC(0), Gustafsson 1978),
  eliminating in the reverse of Prim's order on a maximum-weight spanning tree from the ground,
  pivots computed GTH-style (sums of the conductances still leaving the vertex), so a tree factors
  exactly and no pivot cancels. O(m √κ) per pair, no n² memory. `effectiveGraphResistance`,
  `kemenyConstant` and `numberOfSpanningTrees` use the dense GTH elimination (O(n³), less on
  sparse graphs: zero multipliers are skipped).
- **Work limits.** Every iterative path counts matrix–vector products (a conjugate-gradient
  iteration is one) and throws `NoConvergence` (the error in `GraphProtocols` that Centrality's
  power iterations throw too) when its limit is spent, with the products spent and the residual on
  the tolerance's scale: Lanczos on σI − L 4,000 + 20√n (then shift-invert, not a failure),
  shift-invert 1,000, each solve 20,000 + 2n, ρ(A) 20,000 + 20√n; the dense spectra after 30 n
  QL/QR iterations. Each public method takes `maxIterations: Int? = nil` in place of the limit
  that throws (nil keeps the default): QL/QR iterations for a spectrum, products per Lanczos run
  for λ₂, the Fiedler vector, the ordering and ρ (a limit given also cuts the run on σI − L short;
  a solve inside shift-invert keeps 20,000 + 2n), conjugate-gradient iterations for a resistance.
  The budget is tested after every step, so a run throws with exactly the limit (a
  polynomial-filtered step counts 10). Below 64 vertices λ₂ and ρ come from the dense solver,
  which does not read `maxIterations`. `nil` keeps its one meaning (not connected, different
  components), and an invalid parameter (`tolerance` ≤ 0, `maxIterations` < 1) traps.
- **Start vector**: a fixed one, vᵢ = SplitMix64(i)'s 53-bit uniform in [0.5, 1.5) (the counter
  i + 1 times the golden-ratio increment, then SplitMix64's finalizer), so results are
  reproducible bit for bit on one platform and build; across platforms the last bits may differ
  (fused multiply–add), which the tolerances absorb.
- **Stopping rule (relative)**: a Ritz pair (θ, x) is accepted when ‖Mx − θx‖ ≤ tolerance · λ, λ
  the eigenvalue sought measured from the shift: σ − θ = λ₂ on σI − L, θ = 1/λ₂ on L⁺, θ = ρ on A.
  So λ₂ and ρ carry a relative error of about `tolerance` however the weights spread. Default
  1e-8.

### Determinism and degenerate eigenspaces

- **Eigenvalues** are pinned to the tolerances in cases.md: 1e-9 · max(1, |λ_max|) for dense
  results, 1e-6 · max(1, scale) for iterative ones. **Scale** is the largest |eigenvalue| of the
  matrix concerned: λ_max(L) for `algebraicConnectivity` and `fiedlerVector` (λ_max(N) ≤ 2 with
  `normalized: true`), ρ(A) for `spectralRadius`.
- **Tolerances, unified.** Matrix entries: relative 1e-12 (exact rationals up to rounding).
  Counts, effective graph resistance and the Kemeny constant: relative 1e-9, 1e-9 · max(1, value).
  Spectra: 1e-9 · max(1, |λ_max|). λ₂, ρ and resistance distance: 1e-6 · max(1, scale or R).
  Fiedler entries: 1e-5.
- **Sign**: an eigenvector is defined up to sign. The **canonical sign** makes the first entry (in
  index order) whose magnitude is at least 10⁻⁴ of the largest positive. A largest-entry rule would
  be ambiguous on symmetric graphs, whose entries tie in magnitude with opposite signs (P₄'s ends,
  SGT-108). The 10⁻⁴ threshold skips entries that are zero in exact arithmetic (P₅'s middle,
  SGT-109) but carry rounding noise. The rule is documented on `fiedlerVector` and holds for every
  vector the module returns.
- **GraphDrawing**'s `spectralLayout()` reads its x coordinate from `fiedlerVector()` (DR-207 –
  DR-210; SGT-109 and SGT-113 equal DR-207's and DR-208's x).
- **Degenerate λ₂** (multiplicity k > 1: K_n, C_n, stars, hypercubes, Petersen) has no unique
  vector, even up to sign. Rows say `degenerate: λ₂ = x ×k` and pin only invariants: λ₂ and k,
  and the test checks that the result is a unit vector orthogonal to the null vector with
  residual and Rayleigh quotient within tolerance (SGT-119 – SGT-122). The vector returned is
  still deterministic (fixed start vector), so two calls agree, but which vector of the
  eigenspace comes out is not part of the contract. `spectralOrdering` on such graphs is pinned
  only as "sorted by some λ₂ vector".
- **Simple λ₂ with a tiny gap**: the vector is pinned only when the gap to λ₁ and λ₃ is at least
  10⁻⁶ · scale; otherwise the row is treated as degenerate.

### Multigraphs, loops and directed graphs

Parallel edges add their weights; loops follow the conventions above (2 in A, cancel in L). `Graph`
covers `Multigraph`, `Pseudograph` and the undirected views. Directed graphs get the two matrices
(the Laplacian with out-degrees). Spectral quantities of a directed graph's symmetrization are
`digraph.undirectedView.…`.

## Implementation notes (index space)

- One pass builds the weighted rows: `_runOnUndirectedRows` (`_withIncidentIndexRows` on
  UndirectedAdjacencyList, else `neighborIndices(ofIndex:)` with `incidentEdgeIndices(ofIndex:)`,
  else `_vertexNumbering()`), and on `DirectedGraph` `_withSuccessorIndexRows` (compressed sparse
  row) or the out-edge rows. Weights are read once
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
- `SparseMatrix` is square (n × n, `Int` columns). The incidence matrix of a graph is
  `IncidenceMatrixModule`'s representation.
- `SparseMatrix.pattern` wraps `offsets` and `columns` with `CompressedSparseRow`'s package
  initializer (no copy).
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

