# IsomorphismModule test suite

`IsomorphismModule` maps one graph onto another of the same kind (`Graph` or `DirectedGraph`). It
solves three problems: isomorphism, induced subgraph isomorphism and monomorphism (non-induced
subgraph isomorphism). Each is available as a yes/no answer, a first mapping, or a lazy sequence of
every mapping, and each takes optional vertex and edge colours. The module also has
Weisfeiler–Leman hashes, one for a whole graph and one per vertex.

The module also computes automorphism groups and canonical labelings. The API description
(`api.md`) is in [`Tests/Catalogs/Isomorphism/`](../Catalogs/Isomorphism/). Hashes are per process
(`Hasher`), so tests compare them within one run and never pin a value. The first mapping is not
pinned.

The suite uses only the public API, and each test is self-contained. Definitions, brute-force
models and counting formulas are written out inside the test that uses them. The only shared
material is the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
extension Graph {            // and DirectedGraph, with Other: DirectedGraph
    func isIsomorphic(to:) -> Bool;          func isomorphism(to:) -> Isomorphism<Self, Other>?;          func isomorphisms(to:) -> Isomorphisms<Self, Other>
    func isSubgraphIsomorphic(to:) -> Bool;  func subgraphIsomorphism(to:) -> Isomorphism<Self, Other>?;  func subgraphIsomorphisms(to:) -> Isomorphisms<Self, Other>
    func isMonomorphic(to:) -> Bool;         func monomorphism(to:) -> Isomorphism<Self, Other>?;         func monomorphisms(to:) -> Isomorphisms<Self, Other>
    // each also with (to:, vertexColor:, otherVertexColor:) and
    // (to:, vertexColor:, otherVertexColor:, edgeColor:, otherEdgeColor:)
    func weisfeilerLehmanGraphHash(iterations: Int = 3) -> Int                       // + (iterations:vertexColor:), (iterations:vertexColor:edgeColor:)
    func weisfeilerLehmanSubgraphHashes(iterations: Int = 3) -> WeisfeilerLehmanSubgraphHashes<Self>   // the same shapes
}
struct Isomorphism<Pattern, Target>: Hashable, CustomStringConvertible   // equal by images
    image(of:), image(checked:), preimage(of:), preimage(checked:), imageIndex(ofIndex:), images
struct Isomorphisms<Pattern, Target>: Sequence                             // lazy
struct WeisfeilerLehmanSubgraphHashes<G>
    iterations, hashes(of:), hashes(ofIndex:)                                // one hash per round 1…iterations
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Direction | The receiver is the pattern; every mapping reads pattern → target, images in the pattern's `vertices` order | IS-040, IS-114, IS-177 – IS-181 |
| Multiplicities | m(u, v), the edge colours (or the edge count) between u and v, with a loop counted once in m(u, u): equal for isomorphism and induced subgraph isomorphism, contained for monomorphism | IS-045 – IS-056, IS-104 – IS-107, IS-131 – IS-136 |
| Direction of arcs | Kept: a 2-cycle is not two parallel arcs | IS-063, IS-108, IS-137 |
| Colours | Vertex colours equal; edge colours matched as multisets per pair | IS-071 – IS-086, IS-112, IS-113, IS-141 – IS-145 |
| Empty pattern | One mapping, the empty one, in every problem; two empty graphs are isomorphic | IS-001 – IS-003, IS-101, IS-102, IS-129 |
| Order of mappings | Not pinned. Sets are compared, and a second call gives the same first mapping | IS-023, every matching row |
| Weisfeiler–Leman | Round 0 is the vertex colour; a loop is two edge ends and parallel edges count once each; out and in apart when directed; partitions pinned, hash values not | IS-147 – IS-176 |
| Preconditions | A non-vertex traps in `image(of:)`, `preimage(of:)` and `hashes(of:)`; `iterations` must be at least 0 | IS-165, IS-176, IS-178, IS-181, `extra_traps.swift` |

## How values are pinned

Each catalog row builds its graphs as `Pseudograph<Int>` or `DirectedPseudograph<Int>` with the
catalog's vertices and edges in position order, so an edge colour list is indexed by position.
The test first checks the catalog's value. Each matching row then checks the rest of its family on
the same arguments:

- the whole lazy sequence: its length is the reference model's count, no mapping appears twice
  (as `[Vertex]` and as `Isomorphism`), and every mapping meets the definition, which is
  written out in the test;
- the yes/no answer;
- the first mapping: it is valid, and a second call returns the same one.

A unique mapping is also read through every accessor. Weisfeiler–Leman rows compare hashes within
the process and pin each round's partition. A trap row runs its call in a child process (an exit
test), then runs the same setup in this process without the call.

The catalog-row files are every file except `IsomorphismConformanceTests.swift`,
`IsomorphismPropertyTests.swift`, `Performance/IsomorphismStressTests.swift` and
`IsomorphismHardFamiliesTests.swift`. `swiftgen.py` generates them
from `cases.md`. It sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/Isomorphism/`](../Catalogs/Isomorphism/):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 python3 Tests/Catalogs/Isomorphism/swiftgen.py --phase2
```

The generator first checks that `ref.py` reproduces `cases.md` byte for byte. That run re-checks
every row against brute force and against NetworkX, igraph and rustworkx. The generator then
re-derives each value it writes from `ref.py`'s model and asserts that it matches the catalog cell.
The precondition file also takes the hand-written exit tests in `extra_traps.swift`. `--phase2`
writes the automorphism-group rows (IS-182 – IS-233) as `AutomorphismGroupTests.swift`; without
it that file is left alone. Those tests pin `order` and `orbits`, check that the
product of `basicOrbitLengths` is the order, and check that every generator is an automorphism
whose orbits are `orbits`.

## Hand-written files

- **Conformance.** Seeded random graphs go through every representation that can hold them:
  - undirected: `Pseudograph`, `UndirectedAdjacencyList`, `Multigraph`, and the `undirectedView`
    views of `AdjacencyMatrix`, `AdjacencyList` and `LabeledGraph<String, AdjacencyMatrix>`;
  - directed: `DirectedPseudograph`, `AdjacencyList`, `CompressedSparseRow`, `AdjacencyMatrix`,
    `DirectedMultigraph`, and `LabeledGraph<String, _>` over both bases.

  Each representation is tried alone and mixed with others (pattern in one, target in another).
  Every problem's set of mappings, read back as indices, must equal the reference's, and the yes/no
  answers and first mappings must agree. Multigraphs with edge colours go through
  `DirectedPseudograph.undirectedView` as well. An undirected graph's `directedView` view must have
  the same mappings. Relabelled copies (permuted vertices, shuffled edge positions, `String` names,
  a shuffled vertex order) move every mapping by the relabelling, and colours move with them.
  Weisfeiler–Leman hashes, whole and per vertex, must be equal across representations and copies.
  The file also covers `Isomorphism`'s equality and hashing by images, a sequence that repeats on
  every pass with independent iterators, laziness (the first mappings of `E(40)` onto itself and of
  `K₁₂`), and colour closures read at most once per vertex and edge, at the call.
- **Properties** (swift-property-based, with shrinking). Random pseudographs and directed
  pseudographs on up to 6 vertices, with parallel edges, self-loops and optional colours, are
  checked against a brute-force model that tries every injection. Each problem's sequence must be
  exactly the model's set: complete, with no duplicates, induced mappings among the monomorphisms,
  colours kept. The isomorphism target is a relabelled copy, so positive answers are common.
  Weisfeiler–Leman partitions are checked against colour refinement written out, and relabelled
  copies must hash equal, vertex by vertex.
- **Stress** (a one-minute limit each, meant to take seconds in a debug build). These inputs give
  colour refinement a single class, so only refinement after every assignment finishes them in
  time:
  - random 3- and 10-regular graphs on 1 000 vertices against relabelled copies. On the cubic
    graph the full sequence must have as many mappings as the graph has automorphisms. A
    degree-preserving switch that changes the triangle count gives a certain non-isomorphic
    partner;
  - the 40 × 40 grid (exactly 8 mappings) and torus;
  - 40 relabelled random graphs on 8 – 29 vertices;
  - triangle, path and 4-cycle counts in a random graph, against counting formulas;
  - a 500-vertex digraph;
  - Weisfeiler–Leman on 10⁵ edges.
- **Hard families** (`IsomorphismHardFamiliesTests.swift`, the same limits, each also asserting
  under 10 s on a clock). The inputs that defeat a matcher without automorphism pruning: 20
  hexagons against 19 and two triangles, 20 copies of K3,3 against 19 and a prism (with the
  order 20! · 12²⁰ of the hexagons' group); Latin-square graphs of Z₁₆ and Z₂ × Z₈; twisted CFI
  over a random cubic base of 40 (order divisible by 2²¹); non-isomorphic random 3-regular (2 000)
  and 10-regular (1 000) pairs. Also an iterator copied in the middle of each kind of sequence,
  cancellation (a cancelled task ends the sequences early), `inverse` and `preimage(checked:)`, and
  canonical forms of relabelled copies, loops, parallel edges and digraphs. The edge-colour check
  at a joint-search leaf is not pinned by a test: it fails only when two different colour
  multisets have equal 64-bit weight sums, and the code documents it as defensive.
