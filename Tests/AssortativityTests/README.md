# Assortativity test suite

`Assortativity` holds Newman's degree, attribute and numeric assortativity coefficients, average
neighbor degree and average degree connectivity k_nn(k), reciprocity, degree histograms and
regularity, the s-metric, the unnormalized rich-club coefficients and the triadic census
(Batagelj–Mrvar). Global and local efficiency live in `Distances` and are tested in
`Tests/DistancesTests/EfficiencyTests.swift`. Each test is self-contained; the shared material is
`ReferencePseudograph`, `ReferenceDirectedMultigraph`, the karate fixture, the seeded generator and
the tags in `GrafluentTestSupport`.

## API under test

```swift
enum DegreeType { case in, out, total }
extension Graph {
    func degreeAssortativityCoefficient() -> Double?, (weight:) -> Double?
    func attributeAssortativityCoefficient<C: Hashable>(attribute: (Vertex) -> C) -> Double?
    func numericAssortativityCoefficient<W: BinaryFloatingPoint>(attribute: (Vertex) -> W) -> Double?
    func averageNeighborDegrees() / (weight:) -> AverageNeighborDegrees<DirectedView<Self>>
    func averageDegreeConnectivity() / (weight:) -> [Int: Double]
    func degreeHistogram() -> [Int], var isRegular: Bool, func isRegular(degree:) -> Bool
    func sMetric() -> Int, func richClubCoefficients() -> [Double]
}
extension DirectedGraph {
    func degreeAssortativityCoefficient(source: DegreeType = .out, target: DegreeType = .in) / (…, weight:) -> Double?
    func attributeAssortativityCoefficient(attribute:), numericAssortativityCoefficient(attribute:) -> Double?
    func averageNeighborDegrees(source: = .out, target: = .out) / (…, weight:) -> AverageNeighborDegrees<Self>
    func averageDegreeConnectivity(source: = .total, target: = .total) / (…, weight:) -> [Int: Double]
    func reciprocity() -> Double?, func triadicCensus() -> TriadicCensus
    func inDegreeHistogram() -> [Int], func outDegreeHistogram() -> [Int], var isRegular: Bool
}
extension BidirectionalDirectedGraph { func reciprocity(of:) / (checked:) -> Double? }
struct AverageNeighborDegrees<G> { averageNeighborDegree(of:) / (checked:) / (ofIndex:), values }
struct TriadicCensus { counts: [Int], static types: [String], subscript(String) -> Int }
```

## Conventions

| Question | Choice |
|---|---|
| Undirected pairs | Every edge read in both directions; a self-loop twice, as `degree(of:)` counts it; parallel copies each |
| Directed pairs | Every arc once, the tail's `source` degree against the head's `target` degree; a self-loop is one arc |
| Undefined coefficients | nil without pairs, or when every pair has the same value at one end (Pearson), or every pair is within one class (attribute) |
| Weights | Weighted degrees are sums of edge weights; neighbor degrees stay unweighted; a vertex whose weights sum to 0 averages 0, and k_nn takes the bare sum there |
| Simple graph | Reciprocity, the census and the rich club read the simple graph: loops ignored, parallel copies once |
| Empty graph | Histograms `[]`, regular, rich club `[]`, census all 0 |
| Doubles | Compared within 1e-12 of the hand values (fractions in the comments), which agree with NetworkX 3.7 |

## Files

| File | Covers |
|---|---|
| `AssortativityCoefficientTests.swift` | Stars, paths, the triangle with a pendant, regular graphs, loops, parallel edges, weights, every directed pairing, attribute and numeric coefficients, call order of the closures |
| `NeighborDegreeTests.swift` | Average neighbor degrees and k_nn, isolated vertices, multigraphs, weights (zero and cancelling sums), every directed pairing against NetworkX, directed loops |
| `ReciprocityTests.swift` | Overall and per vertex, loops, parallel arcs, complete digraphs and tournaments, a conformer without indices |
| `DegreeStatisticsTests.swift` | Histograms, regularity, the s-metric and the rich club, karate against NetworkX |
| `TriadicCensusTests.swift` | Each of the 16 types under every relabeling, the six-arc digraph against NetworkX, small graphs, multigraphs, stars |
| `AssortativityPropertyTests.swift` | PropertyBased, shrinking: every entry point against oracles over the edge list on multigraphs with loops and shuffled rows |
| `AssortativityRepresentationTests.swift` | UndirectedAdjacencyList, AdjacencyList.undirectedView, Pseudograph, AdjacencyList, CompressedSparseRow, AdjacencyMatrix, DirectedPseudograph and conformers without indices |
| `AssortativityCheckedTests.swift` | `averageNeighborDegree(checked:)` and `reciprocity(checked:)` |
| `AssortativityPreconditionTests.swift` | Exit tests: weights and values that are not finite, non-vertices, indices out of range, a negative degree, an unknown triad type |
| `Performance/AssortativityStressTests.swift` | The 10⁵ path and star, directed stars with the hub last, a random G(20 000, 10⁵) digraph, each within a minute |
