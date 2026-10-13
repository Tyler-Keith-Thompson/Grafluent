# IsomorphismModule: API

Graph isomorphism, subgraph isomorphism (induced) and monomorphism (non-induced subgraph
isomorphism) between two graphs of one kind, on `Graph` and on `DirectedGraph`, with optional
vertex and edge colours, as a first mapping, a yes/no answer, or a lazy sequence of every mapping.
Subgraph problems run VF2++; isomorphism runs VF2++'s search with joint colour refinement after
every assignment. Weisfeiler–Leman colour refinement also gives a cheap invariant
(`weisfeilerLehmanGraphHash`) and per-vertex hashes. The automorphism group (generators, orbits,
order) and canonical labeling come from individualization–refinement with automorphism pruning,
which also decides the isomorphism pairs the joint search cannot.

`cases.md` (IS-001 – IS-233, 233 rows; IS-182 – IS-233 are the automorphism rows) pins the values.
`ref.py` computes every row from the definitions below by backtracking, checks rows with at most 7
target vertices against brute force over every injection, and compares every matching row of at
most 6,000 mappings, as a set of mappings, with NetworkX 3.7 (`GraphMatcher`, `DiGraphMatcher`,
`MultiGraphMatcher`, `MultiDiGraphMatcher`, and the vf2pp functions), python-igraph 1.0.0 (VF2 and
LAD) and rustworkx 0.18.1 (`vf2_mapping`), each where it supports the input. WL partitions are
compared with NetworkX's `weisfeiler_lehman_subgraph_hashes`, hash equality with
`weisfeiler_lehman_graph_hash`, and automorphism orders and orbits with igraph's
`count_automorphisms` and `automorphism_group` (whose generators must generate a group of exactly
that order). `--stress` adds 900 random graph pairs (directed, loops, parallel edges, vertex
colours; up to 6 vertices) for each of the three problems, 900 WL checks, 798 automorphism counts,
and 60 relabelled pairs of 8–29 vertices. Run:

`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1
python3 Tests/Catalogs/Isomorphism/ref.py [--write] [--stress] [--bench]`

## Scope

| Entry point | Purpose |
|---|---|
| `isIsomorphic(to:)` → `Bool` | The decision |
| `isomorphism(to:)` → `Isomorphism<Self, Other>?` | The witness; `nil` when there is none |
| `isomorphisms(to:)` → `Isomorphisms<Self, Other>`, a lazy `Sequence` | The count can be n! (`E(n)`), so it is lazy, like `maximalCliques()` |
| `isSubgraphIsomorphic(to:)`, `subgraphIsomorphism(to:)`, `subgraphIsomorphisms(to:)` | **Induced** subgraph isomorphism |
| `isMonomorphic(to:)`, `monomorphism(to:)`, `monomorphisms(to:)` | **Non-induced** subgraph isomorphism. Pattern counting (cycles, paths, matchings in IS-123 – IS-126) is this problem |
| Colours: `vertexColor:otherVertexColor:` and `edgeColor:otherEdgeColor:` overloads of all nine | Colours are `Hashable` classes, so the ordering and cutting rules, the refinement and the canonical form can use them |
| `weisfeilerLehmanGraphHash(iterations:)` → `Int`; `weisfeilerLehmanSubgraphHashes(iterations:)` → `WeisfeilerLehmanSubgraphHashes<Self>` | The same refinement is the matcher's root pruning |
| `automorphismGroup()` → `AutomorphismGroup<Self>` (generators, orbits, order), coloured overloads | Enumerating `isomorphisms(to: self)` costs the group order (25! on IS-216); the pruned search returns O(n) generators |
| `canonicalLabeling()` → `CanonicalLabeling<Self>` (a canonical index per vertex, and a `Hashable` canonical form) | Equal forms exactly when the graphs are isomorphic: deduplicating graph collections by hashing |

Related computations that are not entry points:

* Automorphisms of G: `g.isomorphisms(to: g)`, or `automorphismGroup()` for the group itself.
* An undirected pattern in a directed target: `graph.directedView` gives the symmetric reading.
* A count of mappings: `isomorphisms(to:)` is lazy and its elements are small.

## Summary

```swift
extension Graph {
    // Isomorphism (bijection)
    public func isIsomorphic<Other: Graph>(to other: Other) -> Bool
    public func isomorphism<Other: Graph>(to other: Other) -> Isomorphism<Self, Other>?
    public func isomorphisms<Other: Graph>(to other: Other) -> Isomorphisms<Self, Other>
    // Subgraph isomorphism (induced): self is the pattern, other the target
    public func isSubgraphIsomorphic<Other: Graph>(to other: Other) -> Bool
    public func subgraphIsomorphism<Other: Graph>(to other: Other) -> Isomorphism<Self, Other>?
    public func subgraphIsomorphisms<Other: Graph>(to other: Other) -> Isomorphisms<Self, Other>
    // Monomorphism (non-induced subgraph isomorphism)
    public func isMonomorphic<Other: Graph>(to other: Other) -> Bool
    public func monomorphism<Other: Graph>(to other: Other) -> Isomorphism<Self, Other>?
    public func monomorphisms<Other: Graph>(to other: Other) -> Isomorphisms<Self, Other>

    // Each of the nine, also with colours (closures are read once per vertex and edge at the call,
    // so they are not escaping, even for the lazy sequence):
    public func isomorphisms<Other: Graph, VertexColor: Hashable>(
        to other: Other,
        vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor
    ) -> Isomorphisms<Self, Other>
    public func isomorphisms<Other: Graph, VertexColor: Hashable, EdgeColor: Hashable>(
        to other: Other,
        vertexColor: (Vertex) -> VertexColor, otherVertexColor: (Other.Vertex) -> VertexColor,
        edgeColor: (Edges.Index) -> EdgeColor, otherEdgeColor: (Other.Edges.Index) -> EdgeColor
    ) -> Isomorphisms<Self, Other>
    // (edge colours alone: pass a constant vertex colour)

    // Weisfeiler–Leman (colour refinement); iterations ≥ 0, default 3
    public func weisfeilerLehmanGraphHash(iterations: Int = 3) -> Int
    public func weisfeilerLehmanSubgraphHashes(iterations: Int = 3) -> WeisfeilerLehmanSubgraphHashes<Self>
    // and both as (iterations:vertexColor:) and (iterations:vertexColor:edgeColor:) (one graph, so no
    // `other` closures; iterations defaults to 3 there too)

        // Automorphisms
    public func automorphismGroup() -> AutomorphismGroup<Self>          // + vertexColor:/edgeColor:
    public func canonicalLabeling() -> CanonicalLabeling<Self>
}
extension DirectedGraph { /* the same members, Other: DirectedGraph */ }

@frozen public struct Isomorphism<Pattern, Target> {   // members where both are Graph, or both DirectedGraph
    public func image(of vertex: Pattern.Vertex) -> Target.Vertex          // traps on a non-vertex
    public func image(checked vertex: Pattern.Vertex) throws(VertexNotFound) -> Target.Vertex
    public func preimage(of vertex: Target.Vertex) -> Pattern.Vertex?      // nil outside the image; traps on a non-vertex
    public func preimage(checked vertex: Target.Vertex) throws(VertexNotFound) -> Pattern.Vertex?  // nil outside the image; throws off the target
    public var inverse: Isomorphism<Target, Pattern>                      // bijections only (traps otherwise); O(n)
    public func imageIndex(ofIndex index: Int) -> Int                      // index space, O(1)
    public var images: some RandomAccessCollection<Target.Vertex>          // in pattern `vertices` order
}
extension Isomorphism: Equatable, Hashable    // by images (both graphs are not compared)
extension Isomorphism: CustomStringConvertible

public struct Isomorphisms<Pattern, Target>: Sequence { Element == Isomorphism<Pattern, Target> }

public struct WeisfeilerLehmanSubgraphHashes<G> {
    public var iterations: Int
    public func hashes(of vertex: G.Vertex) -> ArraySlice<Int>   // one per round, rounds 1...iterations
    public func hashes(ofIndex index: Int) -> ArraySlice<Int>
    public func hashes(checked vertex: G.Vertex) throws(VertexNotFound) -> ArraySlice<Int>
}

public struct AutomorphismGroup<G> {
    public var generators: [Isomorphism<G, G>]          // a generating set, not pinned
    public var orbits: AutomorphismOrbits<G.Vertex>     // RandomAccessCollection of vertex slices
    public func orbit(of vertex: G.Vertex) -> Int       // index into orbits
    public func orbit(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
        public var order: Double                            // rounded; exceeds Int for 25 isolated vertices
    public var basicOrbitLengths: [Int]                 // the stabiliser chain the search found; product = the exact order
}
public struct CanonicalLabeling<G> {
    public func canonicalIndex(of vertex: G.Vertex) -> Int
    public func canonicalIndex(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
        public var permutation: [Int]                       // permutation[i] = canonical index of vertex i
    public var form: CanonicalForm                      // Hashable, Sendable; equal ⇔ isomorphic
}

```

## Semantics

### Definitions (what every row checks)

For a mapping f from the pattern G to the target H, write m(u, v) for the **multiset of edge
colours** between u and v (the number of edges between them when there are no colours; for a
self-loop, u = v; on a directed graph, arcs from u to v):

- **isomorphism**: f is a bijection, colour(u) = otherColor(f(u)) for every u, and
  m_G(u, v) = m_H(f(u), f(v)) for every ordered pair (u, v), u = v included;
- **subgraph isomorphism** (induced): f is an injection with the same two conditions;
- **monomorphism**: f is an injection, vertex colours are equal, and m_G(u, v) ⊆ m_H(f(u), f(v))
  as multisets.

So parallel edges and self-loops count everywhere (IS-045 – IS-056, IS-104 – IS-107, IS-131 –
IS-136): a loop is an edge, a simple pattern edge cannot be induced on a parallel pair (IS-106) but
is contained in it (IS-133). Vertex colours must be equal, not compatible, and edge colours are
matched as multisets per pair. Undirected and directed graphs are separate overloads; a directed
mapping preserves arc direction, so a 2-cycle is not two parallel arcs (IS-063).

The empty mapping is a mapping: two empty graphs are isomorphic (IS-001 – IS-003), and an empty
pattern has exactly one subgraph isomorphism and monomorphism into any target (IS-101, IS-102,
IS-129).

### Results

- A mapping is written as `images` in the pattern's `vertices` order (IS-040: the images are
  target vertices, not indices). `preimage(of:)` is `nil` for a target vertex outside the image of
  a subgraph mapping (IS-180) and traps for a vertex not in the target (IS-181). `image(of:)` traps
  for a non-vertex (IS-178); `image(checked:)` throws `VertexNotFound` instead, and
  `preimage(checked:)` throws it for a vertex not in the target.
- `Isomorphism` holds the two graphs (as `Coloring` holds its graph) and the image indices as one
  `[Int]`. `Equatable`/`Hashable` compare the images, so tests compare whole sequences as sets.
- `Isomorphisms` is a lazy `Sequence`: the iterator owns the search state (the partial mapping,
  the candidate cursors, the matching order). Asking for the first element costs what
  `isomorphism(to:)` costs. It is a `Sequence`, not a `Collection`: the search is one pass.

### Weisfeiler–Leman

Round 0 colours every vertex by its `vertexColor` (all equal without one). Round r replaces a
vertex's colour by the pair (its colour, the multiset of (edge colour, neighbour colour) over its
edge ends). The multiset is hashed as two lanes of keyed additive 64-bit mixes of its elements (the
key from `Hasher`), O(1) per element, not by sorting; additive lanes are not collision-resistant
against inputs built to collide, and under `SWIFT_DETERMINISTIC_HASHING` the key is a fixed
constant, so the hash is an invariant, not a fingerprint to trust against an adversary. On a
directed graph the out- and in-multisets are kept apart. A self-loop contributes its vertex twice
(it has two ends, Graph's counting rule), and parallel edges count once each (IS-160, IS-161,
IS-174). `weisfeilerLehmanGraphHash(iterations: k)` hashes the colour histograms of rounds 1 … k
(round 0's histogram is the vertex count and the colour sizes, IS-152, IS-153);
`weisfeilerLehmanSubgraphHashes(iterations: k)` gives each vertex its colours after rounds 1 … k.
Isomorphic graphs hash equal; the converse fails (C6 against 2C3, strongly regular pairs, CFI pairs:
IS-147 – IS-149).

**Hash values are not pinned and not stable across processes.** Colours are arbitrary `Hashable`
values, and Swift's `Hasher` is seeded per process, so the hash is equal for equal inputs within
one run (as `hashValue`; `SWIFT_DETERMINISTIC_HASHING` makes it reproducible). Rows pin equality
between two graphs and the partitions; `ref.py` checks the partitions against NetworkX's at the
same `iterations` on simple graphs (k ≥ 2).

### Automorphism group and canonical labeling

`orbits` are classes of vertices, each in `vertices` order, ordered by first vertex (as
`Partition`); `order` and `orbits` are pinned (IS-182 – IS-233; IS-216's order, 25!, exceeds `Int`).
`generators` are not pinned (they depend on the search's choices). Tests check each generator is an
automorphism and that they generate a group whose orbits are `orbits`, and that `basicOrbitLengths`
multiply to `order`. Canonical labelings are not pinned either (they depend on refinement and
target-cell choices); tests check that isomorphic inputs (relabelled copies) give equal `form`s and
non-isomorphic rows give different ones.

## Determinism

**Pinned:** every yes/no answer, every count, the set of all mappings on small rows, a mapping
wherever it is unique (IS-032, IS-034, IS-061, IS-114, IS-145, and the accessor rows), WL
equalities and partitions, automorphism orders and orbits.

**Not pinned: which mapping comes first, and the order of `isomorphisms(to:)`.** Rows with
several mappings write `some (one of #N)`; the test checks the mapping against the definition and
that a second call gives the same one (the search is deterministic: no randomness, ties by index).
The first mapping depends on the matching order and candidate order of the search, which may
change without changing correctness.

## Algorithms

**Subgraph isomorphism and monomorphism by VF2++ (Jüttner–Madarasi 2018); isomorphism by VF2++'s
order with joint colour refinement after every assignment (individualization–refinement
matching).**

- **VF2++** is VF2 (Cordella et al. 2004) with a matching order computed once (BFS from the
  rarest-coloured, highest-degree vertex; within a level, most connections to the vertices already
  ordered, then degree, then colour rarity) and cutting rules counted per colour class. It keeps
  O(n) state per search level and is lazy by construction (each solution is a leaf).
- **Isomorphism adds refinement.** Degrees and colour classes give a regular graph one class, so
  a VF2-family matcher alone guesses blindly, deep into the search. After the matcher assigns
  u ↦ x, u and x get a fresh colour and G and H are refined jointly to the equitable partition.
  Isomorphisms that extend the partial mapping preserve the refined colours, so this is sound; a
  cell whose sizes differ in G and H prunes the branch at once; and on random regular graphs one or
  two assignments make every cell a singleton. Every leaf is still a mapping, so
  `isomorphisms(to:)` enumerates exactly. Without any assignment, the root refinement alone decides
  trees, most random graphs and graphs with distinct classes (IS-043, IS-069 have one mapping).
- **Subgraph problems use plain VF2++.** Refinement is not preserved by injections (a pattern
  vertex's degree is only a lower bound), so only degree and colour filters and VF2++'s cutting
  rules apply.
- Without automorphism pruning, a non-isomorphic pair that refinement cannot separate (CFI pairs,
  IS-041; strongly regular pairs, IS-029; disjoint unions of equal components against unions with
  one component changed) would make the search visit every branch. Those pairs go to canonical
  labeling (below).

**Automorphism pruning and canonical labeling** (McKay–Piperno 2014; Junttila–Kaski 2007) on the
same refinement engine, run on one graph
(`AutomorphismSearch.swift`). The refinement is made label-invariant (touched cells split in
position order) and records each node's events (running hashes of its splits); a node's invariant
is its path's event sequences, compared lexicographically. The first leaf fixes the base; a later
leaf whose path has the first path's events gives an automorphism when the permutation between the
two leaves keeps every edge (checked edge by edge), and the search jumps back to where the paths
part. Orbit pruning at every node uses the generators that fix the node's individualized vertices
(union–find over the target cell, smallest vertex first). Without canonical labeling a node whose
events part from the first path's is abandoned at the first differing event (early abort),
which is what makes random regular graphs cheap; with it, the canonical leaf is the greatest by
(events along the path, certificate = the graph relabelled by the leaf), nodes already less than
the best are abandoned, and a leaf equal to the best gives an automorphism. Target cell: the first
largest non-singleton cell. Generators are kept only when they join orbits at their
level of the stabiliser chain (at most n − 1, a strong generating set), and `order` is the exact
product of the basic orbit lengths rounded once to `Double`.

`isIsomorphic(to:)` runs the joint search with a budget (64 + 2n nodes, and at most one subtree
below the first level exhausted without a leaf: the sign that refinement is not telling branches
apart). Over budget, the pair is decided by canonical labeling: component by component when either
graph is disconnected (component recursion: components pair off by size, then by certificate), else
the whole graphs. Random regular graphs stay with the joint search (a wrong assignment fails at
once). Every further element of `isomorphisms(to:)` is the first mapping composed with an
automorphism of G, enumerated from the stabiliser chain (O(n) per mapping).

**Bounding a search.** The joint search, the canonical searches behind `isIsomorphic(to:)`, the
enumeration and the subgraph searches check `Task.isCancelled` (every 256 nodes, every element,
every 4,096 steps); a cancelled task ends the sequence, so the decision returns false and the first
mapping nil. `automorphismGroup()` and `canonicalLabeling()` run to completion. Families that stay
exponential for every individualization–refinement solver: Miyazaki graphs and other rigid
CFI-gadget constructions, where neither refinement nor automorphisms prune.

## Implementation notes (index space)

- Number the vertices through the protocol: `vertexIndexBound` (then `vertexIndex(of:)` and
  `vertex(atIndex:)`), or `_vertexNumbering()` when there are no indices.
- Build one compact internal adjacency per graph, once per call: rows of (neighbour, multiplicity
  or edge-colour multiset id) sorted by neighbour, from `_withSuccessorIndexRows` (compressed sparse
  row), `_withIncidentIndexRows` (`UndirectedAdjacencyList`), or `successorIndices(ofIndex:)` /
  `neighborIndices(ofIndex:)`. `endpointIndices(ofEdgeAt:)` reads edge colours' endpoints without
  hashing (the undirected view of a `LabeledGraph`); `degree(ofIndex:)` gives degrees without the
  rows. Directed matching also needs in-rows, built from the out-rows (O(n + m)); no
  `BidirectionalDirectedGraph` requirement.
- Adjacency tests are O(1) through a bit matrix when the target has at most 4,096 vertices
  (2 MiB), otherwise a binary search in the sorted row; multiplicity and colour checks happen only
  when the input has parallel edges, loops or edge colours (one flag, checked once).
- Colour closures are evaluated once per vertex and edge into dense class ids (a dictionary over
  the colours), so they are non-escaping and the lazy sequence holds only integers.
- The search runs on an explicit stack (no recursion), with `~Copyable` scratch buffers; the
  iterator of `Isomorphisms` is the suspended stack.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| set-up (all matching entry points) | O(n + m) to build rows and colour ids; for isomorphism, the root refinement O((n + m) log n) (Hopcroft-style splitting, smaller half first) | O(n + m), plus n_H² / 8 bytes for the bit matrix when n_H ≤ 4,096 |
| `isIsomorphic`, `isomorphism`, first element of `isomorphisms` | exponential in the worst case; per search node one incremental refinement, O((n + m) log n) at worst and usually far less | O(n + m) undo trail, O(n) per level |
| subgraph isomorphism, monomorphism | NP-complete; VF2++ is exponential in the pattern size | O(n_G) per level |
| each further mapping of a sequence | the search between two leaves | — |
| `weisfeilerLehmanGraphHash`, `weisfeilerLehmanSubgraphHashes` | O(k (n + m)) for k iterations | O(n + m) (k n for the subgraph hashes) |
| `automorphismGroup`, `canonicalLabeling` | exponential in the worst case (Miyazaki graphs); near-linear refinement per node | O(n + m) plus O(n) per tree level and the generators |

