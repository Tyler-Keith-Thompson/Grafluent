# NamedGraphs test suite

`NamedGraphs` builds the named families as static factories on the representation types:
`complete`, `completeBipartite`, `path`, `cycle`, `star`, `wheel`, `grid`, `hypercube`, `petersen`,
`empty`, `ladder`, `circularLadder`, `barbell`, `lollipop`, `completeMultipartite`, `turan`,
`balancedTree`, `circulant`, `generalizedPetersen`, `kneser`, `windmill`, `binomialTree`,
`fullRaryTree`, `triangularLattice`, `hexagonalLattice`, `lcf`, the named graphs (`heawood`,
`moebiusKantor`, `pappus`, `desargues`, `dodecahedral`, `frucht`, `icosahedral`, `tutte`, `chvatal`,
`hoffmanSingleton`), the expanders (`margulisGabberGalil`, `chordalCycle`, `paley`), `kautz`, and `deBruijn` on the representations that allow self-loops. The API is described in `api.md` in
[`Tests/Catalogs/NamedGraphs/`](../Catalogs/NamedGraphs/). The factories live on the underscored
`_GraphConstruction` and `_DirectedGraphConstruction` protocols, so each family reaches every
conformer. Vertices are `Int`s `0..<n`, with each family's numbering fixed.

The suite uses only the public API, and each test is self-contained. Nothing is shared but the tags
in `GrafluentTestSupport`. The suite never names the underscored protocols. It calls the factories
on the concrete types.

## API under test

```swift
extension _GraphConstruction, _DirectedGraphConstruction {   // 3 undirected and 6 directed conformers
    static func complete(vertexCount:), completeBipartite(leftCount:rightCount:), path(vertexCount:),
        cycle(vertexCount:), star(vertexCount:), wheel(vertexCount:), grid(dimensions:periodic:),
        hypercube(dimension:), petersen(), empty(vertexCount:),
        ladder(rungCount:), circularLadder(rungCount:), barbell(cliqueVertexCount:pathVertexCount:),
        lollipop(cliqueVertexCount:pathVertexCount:), completeMultipartite(partSizes:),
        turan(vertexCount:partCount:), balancedTree(branchingFactor:height:),
        circulant(vertexCount:offsets:), generalizedPetersen(outerCycleLength:step:), kneser(setSize:subsetSize:),
        windmill(cliqueCount:cliqueVertexCount:), binomialTree(order:), fullRaryTree(branchingFactor:vertexCount:),
        triangularLattice(rowCount:columnCount:), hexagonalLattice(rowCount:columnCount:),
        lcf(vertexCount:shifts:repeatCount:), heawood(), moebiusKantor(), pappus(), desargues(), dodecahedral(),
        frucht(), icosahedral(), tutte(), chvatal(), hoffmanSingleton(), margulisGabberGalil(side:),
        chordalCycle(prime:), paley(prime:)
}
extension _DirectedGraphConstruction { static func kautz(alphabetSize:wordLength:) }
extension AdjacencyList, DirectedPseudograph where Vertex == Int { static func deBruijn(alphabetSize:wordLength:) }
extension Tree where Vertex == Int {
    static func path(vertexCount:), star(vertexCount:), balancedTree(branchingFactor:height:), binomialTree(order:),
        fullRaryTree(branchingFactor:vertexCount:)
}
extension BipartiteGraph where Vertex == Int { static func completeBipartite(leftCount:rightCount:) }
```

The undirected conformers are `UndirectedAdjacencyList<Int>`, `Pseudograph<Int>` and
`Multigraph<Int>`. The directed ones are `CompressedSparseRow`, `AdjacencyMatrix`,
`AdjacencyList<Int>`, `DirectedPseudograph<Int>`, `DirectedMultigraph<Int>` and
`StableDirectedGraph<Int>`.

## How values are pinned

Every catalog row runs its family on all nine conformers. The undirected form runs on the three
undirected types. The directed form runs on the six directed types, with one arc per edge along
the natural orientation (path, cycle, star, wheel; the balanced, binomial and full r-ary trees from
parent to child) or both arcs (complete, complete bipartite, complete multipartite, Turán, grid,
hypercube, Petersen, the ladders, barbell, lollipop, and the families after them). De Bruijn rows
run on `AdjacencyList<Int>` and `DirectedPseudograph<Int>`, Kautz rows on the six directed
conformers. The catalog shows one form. `swiftgen.py` takes the other from
`ref.py`'s model, which checks both against NetworkX 3.7 and igraph 1.0. Each run checks:

- the vertex and edge counts, `vertices` as `0..<n` in order, and `vertexIndex(of:)` as the identity;
- `edges` in order, written out. Undirected edges are `UndirectedEdge(u, v)` with `u < v`, sorted;
  directed edges are row-major. The order is part of the contract;
- every degree (out-degrees, and in-degrees counted from the edges), and every vertex's neighbours
  or successors;
- `contains(edge:)` for every edge and both orientations, and for one pair that is not an edge;
- that every incident or outgoing position names an edge at that vertex.

Three rows are too large to write out: K60, the 100 × 100 grid and Q10. Their edges are instead
checked as sorted, in range and following the family's rule, with every degree from its formula.
The `Tree` and `BipartiteGraph` rows run on their own type, and the bipartite rows also check
`left`, `right` and `side(of:)`.

A trap row runs its call as an exit test on every conformer the rule covers. "One rule on every
type" means all nine conformers. NG-011, whose n(n − 1) overflows only for the directed count, runs
on the directed conformers only, so that no implementation tries to build 2^63 undirected edges.
Some rows add sibling traps: a negative left side, `Tree.star(0)`, `grid(dimensions: [],
periodic: true)` and `Tree.path(-1)`. A valid neighbour of the call then runs in this process.

The catalog-row files are every file except `NamedGraphPropertyTests.swift`,
`LatticeFamilyPropertyTests.swift` and `BulkConstructionTests.swift`. `swiftgen.py` generated them from `cases.md`; it sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/NamedGraphs/`](../Catalogs/NamedGraphs/):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/NamedGraphs/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it parses each row's call
(the catalog writes valid Swift), rebuilds both forms on the model, and asserts that the model's
summary is the row's cell. Only then does it write the test.

## Hand-written files

### Bulk construction

`BulkConstructionTests.swift` covers what the catalog's generic checks do not read:
`AdjacencyMatrix`'s in-degrees; the in-rows, incident edges and row order of a generated
`AdjacencyList`, `DirectedPseudograph`, `DirectedMultigraph`, `UndirectedAdjacencyList`,
`Pseudograph` and `Multigraph` against the same graph inserted edge by edge, through a fixed script
of insertions (parallel copies and a loop where allowed) and removals of edges and vertices;
`BipartiteGraph.completeBipartite`'s sides after removals; and `balancedTree` with branching
factor 0 and height `Int.max`, which must stop after the root.

### Properties

`NamedGraphPropertyTests.swift` uses swift-property-based, with shrinking. Each family is checked
over a range of sizes against its definition in api.md, which the test writes out:

- complete graphs up to 40 vertices;
- complete bipartite graphs up to 9 + 9 vertices, with the `BipartiteGraph` sides;
- paths, cycles, stars and wheels up to 50 vertices, with connectivity, `Tree.path` and `Tree.star`;
- grids of one to three dimensions of length 0 to 5, periodic or not, against the coordinate
  definition, the count and degree laws, and connectivity;
- hypercubes up to Q9;
- Petersen as a strongly regular (10, 3, 0, 1) graph in its fixed numbering;
- empty graphs;
- ladders and circular ladders up to 30 rungs, against the rails-and-rungs definition;
- barbells and lollipops with cliques of 2 to 9 and paths of 0 to 8, with connectivity;
- complete multipartite graphs of up to 5 parts of up to 5, adjacency exactly across parts, and two
  parts equal to `completeBipartite` on both kinds;
- Turán graphs up to 25 vertices, their part sizes and Turán's edge bound;
- balanced trees with r ≤ 4 and h ≤ 5, the parent rule and every degree, and `Tree.balancedTree`;
- equality with the same graph built edge by edge, and mutation after a build.

`LatticeFamilyPropertyTests.swift` does the same for the later families, each against its
definition written out in the test: circulant graphs up to 30 vertices with random offsets,
generalized Petersen graphs up to GP(30, k) (cubic, the prism at k = 1, Petersen at GP(5, 2)),
Kneser graphs up to KG(9, k) against subsets as bit masks, windmills, binomial trees up to B₁₁ (the
C(k, d) vertices at depth d), full r-ary trees (and `balancedTree` when the last level is full), de
Bruijn and Kautz graphs against their words, triangular and hexagonal lattices by Euler's formula,
their degree bounds and connectivity (the honeycomb 2-coloured), LCF graphs against their chords,
and the named graphs by order, size, regularity, girth, bipartiteness, the icosahedron's two
triangles per edge and Hoffman–Singleton's strong regularity (50, 7, 0, 1); the expanders against their
four steps, their inverses and their squares, Paley's self-complementarity and the Paley tournament's one arc per pair.

Every property builds the conformers of its kind and requires the same edges in the same order.

## Planted bugs

Each bug below, planted one at a time, fails the listed tests.

| Planted bug | Caught by |
|---|---|
| A periodic dimension of length 2 wraps | NG-060, grid property |
| Grids numbered with the first dimension fastest | NG-053, NG-059, NG-060, NG-063, grid property |
| `hypercube(dimension: 0)` is the null graph | NG-069 (and the hypercube property when it draws d = 0) |
| `completeBipartite`'s directed form with one arc per edge | NG-014 – NG-017 and the bipartite property |
| The wheel's rim closed as 1 → n − 1 | NG-045 – NG-049, NG-089, NG-090 and the wheel property |
| `cycle` accepts 2 vertices | NG-036, NG-037 |
| Petersen's inner pentagram drawn as a pentagon (the prism graph) | NG-077, NG-078, Petersen property |
| Edges left in construction order | 29 tests, among them NG-030 – NG-033 and the grid rows |
| `Tree.star` with its hub last | NG-042 and the star property |
