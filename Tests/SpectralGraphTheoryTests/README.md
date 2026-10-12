# SpectralGraphTheory test suite

`SpectralGraphTheory` builds the matrices of a graph and computes their spectral quantities. It
covers the adjacency, Laplacian, normalized, random-walk and signless Laplacian matrices as a
`SparseMatrix`, and the full spectra of A, L and N. On large sparse graphs it gives the algebraic
connectivity, the Fiedler vector, the spectral ordering and the spectral radius by Lanczos. It also
gives the spanning-tree count, resistance distance, effective graph resistance and the Kemeny
constant. The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/SpectralGraphTheory/`](../Catalogs/SpectralGraphTheory/), phase 1), written before
the implementation existed. Its open questions are decided as recommended:

- pure Swift, with no Accelerate or LAPACK;
- the new `SparseMatrix` type, with `Double` elements only;
- the relative sign rule: the first entry of magnitude at least 1e-4 of the largest is positive.

The suite uses only the public API, and each test is self-contained. The only shared material is
the `ReferencePseudograph` and `ReferenceDirectedMultigraph` conformers, the seeded generator and
the tags in `GrafluentTestSupport`. One file-private conformer models a representation the package
does not have: String vertices with no indices.

## API under test

```swift
extension Graph {               // each also with weight: (Edges.Index) -> W, W: BinaryInteger or BinaryFloatingPoint
    func adjacencyMatrix() -> SparseMatrix, laplacianMatrix(), normalizedLaplacianMatrix(),
         randomWalkLaplacianMatrix(), signlessLaplacianMatrix()
    func adjacencySpectrum(maxIterations:) throws(NoConvergence) -> [Double], laplacianSpectrum(maxIterations:),
         normalizedLaplacianSpectrum(maxIterations:)                                                // ascending
    func algebraicConnectivity(weight:normalized:tolerance:maxIterations:) throws(NoConvergence) -> Double   // traps below 2 vertices
    func fiedlerVector(weight:normalized:tolerance:maxIterations:) throws(NoConvergence) -> FiedlerVector<Self>?   // nil when not connected
    func spectralOrdering(weight:normalized:tolerance:maxIterations:) throws(NoConvergence) -> [Vertex]
    func spectralRadius(weight:tolerance:maxIterations:) throws(NoConvergence) -> Double
    func numberOfSpanningTrees(weight:) -> Double
    func resistanceDistance(from:to:weight:tolerance:maxIterations:) throws(NoConvergence) -> Double?  // nil across components
    func effectiveGraphResistance(weight:) -> Double?, kemenyConstant(weight:) -> Double?
}
extension DirectedGraph { func adjacencyMatrix(weight:), laplacianMatrix(weight:) }                 // out-degrees
struct SparseMatrix: Equatable, Hashable, Sendable, CustomStringConvertible
    rowCount, offsets, columns, values, nonzeroCount, subscript(_ row: Int, _ column: Int), pattern, static *
struct FiedlerVector<G: Graph> { algebraicConnectivity, values, value(of:), value(ofIndex:) }
struct NoConvergence: Error, Hashable, Sendable { iterations, residual }                            // GraphProtocols
```

Every `maxIterations:` is `Int? = nil`, nil meaning the method's default limit (30 n QL/QR
iterations for a dense spectrum, 1,000 shift-invert products for λ₂, 20,000 + 20√n products for ρ,
20,000 + 2n conjugate-gradient iterations for a resistance).

api.md does not say where `weight:` goes in the argument list. The tests put it first, as
Centrality does (`algebraicConnectivity(weight:normalized:tolerance:)`), and after the vertices in
`resistanceDistance(from:to:weight:tolerance:)`, as `closenessCentrality(of:weight:)` does. The
subscript is `subscript(row: Int, column: Int)` exactly as api.md writes it, so in Swift it is
called `matrix[i, j]`, without labels.

## Conventions

| Question | Choice | Cases |
|---|---|---|
| A | An undirected loop adds 2w to A[v][v] (its two ends), a directed loop w; parallel edges add up | SGT-013, SGT-016, SGT-021, SGT-042, SGT-044 |
| L, N, L_rw, Q | L = D − A with loops cancelling; N = D^-1/2 L D^-1/2 and L_rw = D⁻¹L with zero rows at degree 0; Q = D + A; directed L over out-degrees | SGT-017 – SGT-024, SGT-041 |
| Storage | Exactly the nonzero entries, columns ascending in each row; a weight-0 edge stores nothing | SGT-002, SGT-022, SGT-029 |
| Rows | In vertex-index order, or `vertices` order without indices | SGT-011, conformance |
| Weights | Finite everywhere; ≥ 0 for every Laplacian-family call; read once per position | SGT-031 – SGT-035, extra traps, conformance |
| λ₂ | 0 when not connected (weight-0 edges do not connect); traps below two vertices | SGT-095, SGT-100, SGT-106 |
| Iteration limits | `NoConvergence` with the iterations spent (exactly `maxIterations` below 5,000 vertices) and a residual above the tolerance; nil keeps the default limits; below 64 vertices λ₂ and ρ are dense and do not read the limit; `maxIterations` < 1 traps | no-convergence, accuracy |
| Fiedler vector | Unit, canonical sign (relative 1e-4 rule); nil when not connected | SGT-108 – SGT-125, canonical sign |
| Ordering | Components by least index; ≤ 2 vertices in index order; ties within 1e-8 · max\|x\| in index order | SGT-127 – SGT-134 |
| Counts | 0 empty or disconnected, 1 for one vertex; exact (correctly rounded) for integer weights below 2¹⁰⁰; `.infinity` past `Double` | SGT-148 – SGT-168, stress, accuracy |
| Electrical | Weights are conductances; R(v, v) = 0; nil across components; 0 for n ≤ 1 | SGT-169 – SGT-204 |

## How values are pinned

The catalog-row files are every file except `CanonicalSignTests.swift`,
`SpectralAccuracyTests.swift`, `SpectralConformanceTests.swift`, `SpectralNoConvergenceTests.swift`,
`SpectralPropertyTests.swift` and `Performance/SpectralStressTests.swift`.
`swiftgen.py` generated them from `cases.md`. It sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/SpectralGraphTheory/`](../Catalogs/SpectralGraphTheory/):

```
uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.5.4 python3 Tests/Catalogs/SpectralGraphTheory/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-evaluates each phase 1
row on the model at full precision, asserts that the value renders to the catalog cell, and writes
one `@Test` per row. With `--phase2` it also writes `SpectralPhase2Tests.swift`, the 13 rows
SGT-205 – SGT-217, for when phase 2 lands. Each graph is the catalog's, on the reference conformer,
with every vertex listed in `vertices` order and the edges in position order. Weights are `[Int]`
when every weight is an integer, so that the `BinaryInteger` overload is exercised, and `[Double]`
otherwise.

| Result | Pinned as | Tolerance (cases.md) |
|---|---|---|
| Matrix | Exact `offsets` and `columns`, stored `values`, no stored zero, `pattern`; every entry by subscript when n ≤ 8, else trace, Σ and Σ² | relative 1e-12 for entries, 1e-9 for the sums |
| Spectrum | Every value, ascending | 1e-9 · max(1, \|λ_max\|) |
| λ₂, spectral radius | The value; exactly 0 when not connected or without edges | 1e-6 · max(1, scale), scale the largest \|eigenvalue\| of the matrix |
| Fiedler vector, simple λ₂ | λ₂, every entry, unit length, `value(of:)` = `value(ofIndex:)` = `values[i]` | 1e-5 per entry |
| Fiedler vector, degenerate λ₂ | λ₂, its multiplicity in the full spectrum, unit length, orthogonality to the null vector, ‖Mx − λ₂x‖, the Rayleigh quotient | 1e-6 · scale |
| Ordering | The exact list; for `(ties: …)` rows a permutation, sorted by the returned Fiedler vector, keeping every catalog pair whose model entries differ by more than 1e-4 | |
| Spanning-tree count | Integer-valued when unweighted, relative to the value | 1e-9 relative (counts are "dense results") |
| Resistance distance | The value; exactly 0 or nil | 1e-6 · max(1, R) |
| Effective graph resistance, Kemeny constant | The value; exactly 0 or nil | 1e-9 · max(1, value) |

A trap row runs the faulting call in a child process (an exit test). The same setup then runs in
this process without the fault, with valid weights or two vertices, and its result is checked, so
the trap comes from the fault and not from the setup. The precondition file also takes the
hand-written exit tests in `extra_traps.swift`:

- negative weights on every Laplacian-family entry point;
- NaN and infinity everywhere, with `Float` weights too;
- a negative weight outside the component a call reads;
- fewer than two vertices;
- a non-vertex source;
- `FiedlerVector` lookups;
- `SparseMatrix` out-of-range entries and a vector of the wrong length.

## Hand-written files

- **Canonical sign.** The relative 1e-4 rule against an absolute threshold. P₅ with the third
  weight 1.00001 lists its middle vertex first: that entry is real but 3 · 10⁻⁶ of the largest, so
  under an absolute 1e-9 threshold it would pick the opposite sign. P₅ and P₆₅ list their exactly-0
  middle vertex first, on the dense and the Lanczos paths, on L and on N.
- **Conformance.** Seeded simple graphs with loops on `Pseudograph`, `UndirectedAdjacencyList`,
  `AdjacencyList.undirectedView` and String vertices without indices. Every entry point is checked
  against the reference: matrices with ==, weights as exact quarters by endpoint. Directed A and L
  on `AdjacencyList`, `CompressedSparseRow` and `AdjacencyMatrix`. `graph.directedView` has the graph's
  A and L. `digraph.undirectedView` is the multigraph of its arcs. The file also checks SparseMatrix
  equality and hashing, bitwise determinism on both paths, the `tolerance:` parameter (λ₂ and ρ
  relative to themselves, the Fiedler residual within tolerance · λ₂), `Sendable`, and that every
  weighted entry point reads each position exactly once.
- **Accuracy under weight spread** (added in review; each test failed on the phase 1 code).
  References that keep their relative accuracy:
  - weighted λ₂ on random graphs of 64 to 500 vertices, weights log-uniform over five decades,
    against the dense λ₂ (relative 10⁻⁹ on L, 10⁻⁷ on N, whose dense form rounds more);
  - paths with one edge of 10⁶ or 10¹², and with conductances over twelve decades, against power
    iteration on the path's explicit grounded inverse: λ₂ and every Fiedler entry, and the
    residual ‖Lx − λ₂x‖ within 10⁻⁷ · λ₂ (a FuzzSpectral finding);
  - barbells (two cliques joined by a path), against the dense λ₂, on L and on N;
  - spanning-tree counts: {h, 1} is h up to 10³⁰⁰ (Cholesky gave 0 at 10¹⁶); 16 counts between
    10¹³ and 2⁵³ exactly equal to `ref.py`'s exact determinant (simple graphs, and multigraphs
    with loops and integer weights); K₂₀, K₂₁ and a weighted 5-cycle past 2⁶², correctly rounded;
  - N, its spectrum, λ₂ of N and the Kemeny constant with weights 10²⁰⁰, 10³⁰⁰ and 10⁻³⁰⁰ equal to
    the unweighted ones; dense spectra at 10^±200 and 10^±300 equal to c times the unit ones;
  - the effective graph resistance and the Kemeny constant on weighted paths against
    Σ r(k + 1)(n − k − 1) and (1/2vol) Σ dᵢdⱼR(i, j), relative 10⁻¹²;
  - resistance across 300 series bundles of parallel two-edge paths with conductances over twelve
    decades, against the series–parallel law;
  - scale invariance at c = 10^±150 (property-based and on the Lanczos paths): λ₂(cw) = cλ₂(w),
    N(cw) = N(w), τ(cw) = c^(n−1) τ(w), R(cw) = R(w)/c;
  - traps: sums that overflow `Double`; and the work limits, which throw `NoConvergence`: a
    tolerance of 10⁻³⁰⁰ runs Lanczos on A and by shift-invert out of products, exactly 20,160 and
    1,000.
- **Properties** (swift-property-based, with shrinking). The graphs are random multigraphs with
  loops and integer weights, 0 included, with vertices listed in a seeded order. The properties
  are:
  - L = D − A, N, L_rw and Q entry by entry, with storage exactly the nonzeros;
  - row sums of L are 0, and xᵀLx = Σ w(x_u − x_v)² exactly, so L is positive semidefinite;
  - the spectra are ascending, L's and N's are nonnegative, N's is at most 2, each sums to its
    trace, A's squares sum to Σ A², and ρ = max |λ(A)|;
  - the Fiedler pair has a small residual and Rayleigh quotient λ₂, λ₂ = spectrum[1], and λ₂ is 0
    with a nil vector exactly when the graph is disconnected;
  - the matrix-tree count equals brute-force spanning-tree enumeration;
  - resistance is a metric: 0 on the diagonal, symmetric, and it obeys the triangle inequality;
    it sums to the effective graph resistance;
  - the series and parallel laws hold on paths of bundles of parallel edges;
  - the Fiedler vector is orthogonal to 1 (or to D^1/2 · 1 on N) and follows the sign rule;
  - the ordering sorts by the Fiedler vector when λ₂ is simple, and lists components by least
    index.
- **NoConvergence** (`SpectralNoConvergenceTests.swift`). Every entry point that iterates throws it
  with a tiny `maxIterations`, every overload: the dense spectra with exactly the limit and an
  off-diagonal entry above rounding; λ₂, the Fiedler vector and the ordering by shift-invert (a
  path of 200) after one product, and on a 10 × 10 grid, where a limit given cuts the shifted run
  short; ρ after one product, with signed weights too; resistance after exactly 1, 2 and 10
  conjugate-gradient iterations. A larger limit answers bit for bit as the default does. Below 64
  vertices, and for components of at most two, the limit is not read. `maxIterations` < 1 traps.
- **Stress**, each with a one-minute limit:
  - the 100 × 100 grid: λ₂ = 2 − 2cos(π/100), which is double, where SciPy's `eigsh(which="SA")`
    returns 0.00888; ρ = 4cos(π/101);
  - the 120 × 30 grid: λ₂ is simple, so the Fiedler vector is cos(π(i + ½)/120) by row and the
    ordering goes row block by row block;
  - a random 3-regular multigraph on 10⁴ vertices, the union of three random perfect matchings:
    λ₂ within 0.03 of 3 − 2√2 (Alon–Boppana and Friedman), ρ = 3, residuals, N = L/3;
  - K₃₀ and K₁₄₀ spanning-tree counts against n^(n−2), and K₂₀₀ giving infinity;
  - resistances on C₂₀₀₀ and on a weighted binary tree of 2¹⁴ − 1 vertices;
  - K₂₀₀'s effective graph resistance and Kemeny constant;
  - the matrices of the 300 × 300 grid.

## Validation

The suite was run against a Swift model of the API, written outside the repository and built with
Bazel in a scratch copy of the workspace. The model uses dense Jacobi below 64 vertices, Lanczos
with full reorthogonalization on σI − L with the null space deflated above that, Cholesky for the
counts and conjugate gradients for resistances. Every test passed. The suite was then run against
23 planted bugs in that model, and each one failed tests:

| Planted bug | Caught by |
|---|---|
| Explicit zeros stored (weight 0, cancelled diagonals) | SGT-002, SGT-022, SGT-023, matrix property, extra traps |
| No negative-weight check | SGT-032, SGT-084, SGT-184, extra traps |
| An undirected loop adds w, not 2w, to A | SGT-016 – SGT-019, matrix property, `graph.directedView` |
| Directed L over in-degrees | SGT-041, SGT-043, SGT-045, SGT-046, directed conformance |
| Weight-0 edges connect components | SGT-125, SGT-182, eigen-residual and ordering properties |
| No canonical sign | Fiedler rows, canonical sign, grid stress |
| Absolute 1e-9 sign threshold (GraphDrawing's rule) | canonical sign: the insignificant first entry |
| λ₃ returned as λ₂ | Fiedler and λ₂ rows (and a crash on two vertices) |
| λ₁ (0) returned as λ₂ | most λ₂ and Fiedler rows, properties |
| Lanczos without deflating the null vector | SGT-092, grid and random-regular stress, P₆₅ |
| Fiedler vector not unit length | Fiedler rows, canonical sign, stress |
| Components ordered by size | ordering-by-components property |
| Ordering descending | SGT-127 – SGT-129, grid stress, P₆₅ |
| ρ as the smallest \|λ\| | SGT-135, SGT-137, SGT-139, SGT-141, spectra property |
| The empty graph has one spanning tree | SGT-148, matrix-tree property |
| Loops kept on L's diagonal for the count | SGT-164, matrix-tree property |
| Resistance inverted (1/R) | SGT-169 onward, metric and series–parallel properties, stress |
| Effective graph resistance ∞ instead of nil | SGT-192, metric property, conformance |
| No trap below two vertices | SGT-106, SGT-107, extra traps |
| Kemeny constant from L instead of N | SGT-197 – SGT-200, K₂₀₀ stress |
| The weight closure read twice | weight-reading conformance |
| Unindexed graphs numbered in reverse | String-vertex conformance |
| `normalized: true` computed on L | SGT-101 – SGT-104, random-regular stress |
