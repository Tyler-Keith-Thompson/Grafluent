# Similarity test suite

`Similarity` scores pairs of vertices: the neighborhood measures of link prediction (common
neighbors, Jaccard, Sørensen–Dice, cosine, Adamic–Adar, resource allocation, preferential
attachment) on `Graph`, and SimRank on `Graph` and `DirectedGraph`. Directed graphs reach the
neighborhood measures through `digraph.undirectedView`. The suite uses only the public API, and
each test is self-contained; the shared material is `ReferencePseudograph`,
`ReferenceDirectedMultigraph`, the seeded generator and the tags in `GrafluentTestSupport`.
Conformers private to a file model representations the package does not have: rows shuffled, no
vertex indices.

## API under test

```swift
extension Graph {
    func commonNeighborCount(of: Vertex, and: Vertex) -> Int          // |Γ(u) ∩ Γ(v)|
    func jaccardCoefficient(of:and:) -> Double                        // ∩ / ∪, 0 when ∪ is empty
    func diceCoefficient(of:and:) -> Double                           // 2∩ / (|Γ(u)| + |Γ(v)|), 0 when both are empty
    func cosineSimilarity(of:and:) -> Double                          // ∩ / √(|Γ(u)| |Γ(v)|), 0 when either is empty
    func adamicAdarIndex(of:and:) -> Double                           // Σ 1 / ln |Γ(w)| over w ∈ ∩
    func resourceAllocationIndex(of:and:) -> Double                   // Σ 1 / |Γ(w)| over w ∈ ∩
    func preferentialAttachmentScore(of:and:) -> Int                  // |Γ(u)| · |Γ(v)|
    // each also (checked:and:) throws(VertexNotFound), and plural (of: some Sequence<(Vertex, Vertex)>)
    // and (checked:) for many pairs, one score per pair in order
    func simRankSimilarity(importanceFactor: Double = 0.9, tolerance: Double = 1e-4, maxIterations: Int = 1000)
        throws(NoConvergence) -> SimRankSimilarity<DirectedView<Self>>
}
extension DirectedGraph {
    func simRankSimilarity(importanceFactor:tolerance:maxIterations:) throws(NoConvergence) -> SimRankSimilarity<Self>
}
struct SimRankSimilarity<G: DirectedGraph>
    func similarity(of:and:) -> Double, func similarity(checked:and:) throws(VertexNotFound) -> Double
    func similarity(ofIndex:andIndex:) -> Double
```

## Conventions

| Question | Choice | Tests |
|---|---|---|
| Which neighborhoods | Γ(x): the vertices other than x sharing an edge with x, in the simple graph. Self-loops are ignored, parallel edges count once | `selfLoopsIgnored`, `parallelEdgesOnce`, `multigraphRows`, the property tests |
| A pair | Ordered, but every measure is symmetric. The two vertices may be equal or adjacent; adjacency puts each in the other's Γ, which the union counts | `adjacentPair`, `samePair` |
| Empty neighborhoods | 0 for every ratio (no NaN); Adamic–Adar is +∞ when `u == v` has a neighbor of degree 1 | `isolatedVertex`, `singleVertex`, `samePair` |
| Doubles | Compared exactly: each ratio is one documented expression, and the sums add in ascending vertex index (position in `vertices` without vertex indices) in the many-pair spelling and in the one-pair spelling with vertex indices | `everyPairEqualsSingles`, `measuresAgainstSets` |
| SimRank's I(x) | In-neighbors (directed) or neighbors (undirected) as a set: parallel edges once, a self-loop's vertex its own in-neighbor | `selfLoops`, `parallelEdges` |
| SimRank's stopping rule | After the first step whose largest change is below `tolerance`; `NoConvergence` reports `maxIterations` and that last change | `noConvergence`, `edgelessOneStep` |
| SimRank's result | Symmetric exactly, 1 on the diagonal, in [0, 1] | `invariants` |

The speed-reliant tests are in `Performance/`: a 10⁵ star whose pairs would cost O(n) each if the
marks were cleared per pair or the hub's row read again within a run, the many-pair spellings on
G(10⁵, 5·10⁵), SimRank on an even 600-cycle, and (optimized builds only) Jaccard and Adamic–Adar
timed against hand-written stamped loops over the same rows.
