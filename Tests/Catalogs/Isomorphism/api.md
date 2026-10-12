# IsomorphismModule: API (phases 1 and 2)

Graph isomorphism, subgraph isomorphism (induced) and monomorphism (non-induced subgraph
isomorphism) between two graphs of one kind, on `Graph` and on `DirectedGraph`, with optional
vertex and edge colours, as a first mapping, a yes/no answer, or a lazy sequence of every mapping.
Subgraph problems run VF2++; isomorphism runs VF2++'s search with joint colour refinement after
every assignment (decision below: plain VF2 times out on random regular graphs). Weisfeiler–Leman
colour refinement also gives a cheap invariant (`weisfeilerLehmanGraphHash`) and
per-vertex hashes. Phase 2 (implemented) adds the automorphism group (generators, orbits, order)
and canonical labeling by individualization–refinement with automorphism pruning, which also
decides the isomorphism pairs the joint search cannot.

`cases.md` (IS-001 – IS-233, 233 rows; IS-182 – IS-233 are phase 2) pins the values. `ref.py`
computes every row from the definitions below by backtracking, checks rows with at most 7 target
vertices against brute force over every injection, and compares every matching row of at most
6,000 mappings, as a set of mappings, with NetworkX 3.7 (`GraphMatcher`, `DiGraphMatcher`,
`MultiGraphMatcher`, `MultiDiGraphMatcher`, and the vf2pp functions), python-igraph 1.0.0 (VF2 and
LAD) and rustworkx 0.18.1 (`vf2_mapping`), each where it supports the input. WL partitions are
compared with NetworkX's `weisfeiler_lehman_subgraph_hashes`, hash equality with
`weisfeiler_lehman_graph_hash`, and automorphism orders and orbits with igraph's bliss
(`count_automorphisms`, `automorphism_group`, whose generators must generate a group of exactly
that order). `--stress` adds 900 random graph pairs (directed, loops, parallel edges, vertex
colours; up to 6 vertices) for each of the three problems against brute force and the three
libraries, 900 WL checks, 798 automorphism counts against bliss, and 60 relabelled pairs of 8–29
vertices. `--bench` prints the baseline timings quoted under Performance. Run (about 20 s; `--bench`
several minutes):

`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 python3 Tests/Catalogs/Isomorphism/ref.py [--write] [--stress] [--bench]`

## Scope

**In, phase 1**

| Entry point | Why |
|---|---|
| `isIsomorphic(to:)` → `Bool` | Every library has it: NetworkX `is_isomorphic`, igraph `isomorphic`, rustworkx `is_isomorphic`, JGraphT `isomorphismExists`, Mathematica `IsomorphicGraphQ`, Boost `isomorphism` (returns `bool`). |
| `isomorphism(to:)` → `Isomorphism<Self, Other>?` | The witness: NetworkX `vf2pp_isomorphism`, Mathematica `FindGraphIsomorphism`, Boost's `isomorphism_map`, LEMON `Vf2pp::mapping`. `nil` when there is none (README: failures that are mathematics return an optional, not a throw). |
| `isomorphisms(to:)` → `Isomorphisms<Self, Other>`, a lazy `Sequence` | NetworkX `vf2pp_all_isomorphisms` and `isomorphisms_iter` are generators, rustworkx `vf2_mapping` an iterator, JGraphT `getMappings()` an `Iterator`. The count can be n! (`E(n)`), so it is lazy, like `maximalCliques()`. The automorphisms of G are `g.isomorphisms(to: g)`. |
| `isSubgraphIsomorphic(to:)`, `subgraphIsomorphism(to:)`, `subgraphIsomorphisms(to:)` | **Induced** subgraph isomorphism: NetworkX `subgraph_is_isomorphic` / `vf2pp_subgraph_*`, Boost `vf2_subgraph_iso`, LEMON `INDUCED`, rustworkx `is_subgraph_isomorphic` (default `induced=True`), JGraphT `VF2SubgraphIsomorphismInspector`. |
| `isMonomorphic(to:)`, `monomorphism(to:)`, `monomorphisms(to:)` | **Non-induced**: NetworkX `subgraph_is_monomorphic` / `vf2pp_*monomorphism*`, Boost `vf2_subgraph_mono`, LEMON `SUBGRAPH`, igraph `subisomorphic_vf2` and `subisomorphic_lad(induced=False)`, rustworkx `induced=False`. Pattern counting (cycles, paths, matchings in IS-123 – IS-126) is this problem. |
| Colours: `vertexColor:otherVertexColor:` and `edgeColor:otherEdgeColor:` overloads of all nine | igraph `color1`/`color2`/`edge_color1`/`edge_color2`, LEMON `nodeLabels(l1, l2)`, NetworkX `node_match`/`edge_match` and vf2pp `node_label`, Boost `vertex_equivalent`/`edge_equivalent`, rustworkx `node_matcher`/`edge_matcher`. |
| `weisfeilerLehmanGraphHash(iterations:)` → `Int`; `weisfeilerLehmanSubgraphHashes(iterations:)` → `WeisfeilerLehmanSubgraphHashes<Self>` | NetworkX `weisfeiler_lehman_graph_hash` and `weisfeiler_lehman_subgraph_hashes`; JGraphT `ColorRefinementIsomorphismInspector`. The same refinement is the matcher's root pruning, so it costs no second implementation. |

**Phase 2** (implemented; rows IS-182 – IS-233, tested in AutomorphismGroupTests.swift)

| Entry point | Why |
|---|---|
| `automorphismGroup()` → `AutomorphismGroup<Self>` (generators, orbits, order), coloured overloads | igraph `automorphism_group` / `count_automorphisms`, Mathematica `GraphAutomorphismGroup`, Sage `automorphism_group(orbits=True)`, nauty and bliss. Enumerating `isomorphisms(to: self)` costs the group order (25! on IS-216), so this needs individualization–refinement with automorphism pruning, which returns O(n) generators. |
| `canonicalLabeling()` → `CanonicalLabeling<Self>` (a canonical index per vertex, and a `Hashable` canonical form: equal exactly when the graphs are isomorphic) | igraph `canonical_permutation`, nauty/Traces and bliss "canonical labeling" / `canonical_form`, Mathematica `CanonicalGraph`, Sage `canonical_label`. The same search as `automorphismGroup()`. Use: deduplicating graph collections by hashing. |

**Not planned, or later**

| Not in phase 1 | Reason |
|---|---|
| Predicate matching (Boost `vertex_equivalent`, NetworkX `node_match` with arbitrary functions, rustworkx `node_matcher`) | A colour (`Hashable` class) does everything an equivalence relation does, and VF2++'s ordering and cutting rules, the WL pre-refinement and phase 2's canonical form all need classes. A non-transitive predicate (NetworkX `numerical_node_match` with a tolerance) has no classes and no library can prune with it. Phase 3 only if asked for. |
| A count entry point (igraph `count_isomorphisms_vf2`, `count_subisomorphisms_vf2`) | `isomorphisms(to:)` is lazy and its elements are small (one `[Int]`). A dedicated count could skip building them; add only if a benchmark shows it matters. The automorphism count is phase 2's `order`. |
| Mixed kinds (an undirected pattern in a directed target) | Not one problem in any library; `graph.directedView` gives the symmetric reading. |
| Tree isomorphism (NetworkX `tree_isomorphism`, AHU; JGraphT `AHURootedTreeIsomorphismInspector`) | Linear time on `Tree`/`RootedTree`; belongs with `TreeAlgorithms` or `Trees`. Colour refinement already decides isomorphism of trees, so phase 1's matcher never backtracks on them. |
| Time-respecting matching (NetworkX `TimeRespectingGraphMatcher`), ISMAGS symmetry-broken subgraph enumeration, maximum common subgraph | NetworkX-only, or a different problem. |
| `could_be_isomorphic` and its fast variants | NetworkX's degree/triangle/clique invariants; `weisfeilerLehmanGraphHash` subsumes the cheap ones. |
| `Isoclass` / graph atlas indices (igraph `isoclass`) | Only for 3–4 vertex motifs; a motif module's concern. |

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

    // Weisfeiler–Leman (colour refinement); iterations ≥ 0, default 3 as NetworkX
    public func weisfeilerLehmanGraphHash(iterations: Int = 3) -> Int
    public func weisfeilerLehmanSubgraphHashes(iterations: Int = 3) -> WeisfeilerLehmanSubgraphHashes<Self>
    // and both as (iterations:vertexColor:) and (iterations:vertexColor:edgeColor:) (one graph, so no
    // `other` closures; iterations defaults to 3 there too)

    // Phase 2
    public func automorphismGroup() -> AutomorphismGroup<Self>          // + vertexColor:/edgeColor:
    public func canonicalLabeling() -> CanonicalLabeling<Self>          // + vertexColor:/edgeColor:
}
extension DirectedGraph { /* the same members, Other: DirectedGraph */ }

@frozen public struct Isomorphism<Pattern, Target> {   // members where both are Graph, or both DirectedGraph
    public func image(of vertex: Pattern.Vertex) -> Target.Vertex          // traps on a non-vertex
    public func image(checked vertex: Pattern.Vertex) throws(VertexNotFound) -> Target.Vertex     // Principle 6
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
    public func hashes(checked vertex: G.Vertex) throws(VertexNotFound) -> ArraySlice<Int>  // Principle 6
}

// Phase 2
public struct AutomorphismGroup<G> {
    public var generators: [Isomorphism<G, G>]          // a generating set, not pinned
    public var orbits: AutomorphismOrbits<G.Vertex>     // RandomAccessCollection of vertex slices
    public func orbit(of vertex: G.Vertex) -> Int       // index into orbits
    public func orbit(checked vertex: G.Vertex) throws(VertexNotFound) -> Int  // Principle 6
    public var order: Double                            // nauty grpsize, bliss get_group_size_approx
    public var basicOrbitLengths: [Int]                 // the stabiliser chain the search found; product = the exact order
}
public struct CanonicalLabeling<G> {
    public func canonicalIndex(of vertex: G.Vertex) -> Int
    public func canonicalIndex(checked vertex: G.Vertex) throws(VertexNotFound) -> Int  // Principle 6
    public var permutation: [Int]                       // igraph's convention: permutation[i] = canonical index of vertex i
    public var form: CanonicalForm                      // Hashable, Sendable; equal ⇔ isomorphic
}
// Implemented: canonicalLabeling() without colours. The coloured overloads need colour values in
// the form (Hashable is not enough to order colour classes canonically: Comparable & Sendable
// colours would be), so they wait for a use.
```

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `isIsomorphic(to:)` | NetworkX `is_isomorphic`, rustworkx `is_isomorphic`, Mathematica `IsomorphicGraphQ`, igraph `isomorphic` | JGraphT `isomorphismExists`: a Swift `Bool` property reads `is…`. |
| `isomorphism(to:)`, `isomorphisms(to:)` | NetworkX `vf2pp_isomorphism`, `vf2pp_all_isomorphisms`, `isomorphisms_iter`; Mathematica `FindGraphIsomorphism` | igraph `get_isomorphisms_vf2` and NetworkX's `vf2pp_` prefix name the algorithm; Swift names the noun it returns (as `maximalCliques()`). |
| `subgraphIsomorphism…` = **induced**, `monomorphism…` = **non-induced** | NetworkX (`subgraph_is_isomorphic` vs `subgraph_is_monomorphic`, `vf2pp_subgraph_isomorphism` vs `vf2pp_monomorphism`) and Boost (`vf2_subgraph_iso` vs `vf2_subgraph_mono`) agree | LEMON calls the non-induced kind `SUBGRAPH`, igraph's `subisomorphic_vf2` is non-induced despite its name, and Ullmann, LAD and Glasgow call it "subgraph isomorphism". Two libraries name both kinds and agree, so their pair is the one that cannot be misread. `induced: Bool` (rustworkx, igraph LAD) was rejected: the two problems have different results, prunings and costs, and a Boolean flag would hide which one a call site solves. |
| `to:` and the receiver as the domain | Boost `vf2_subgraph_iso(small, large)`, LEMON `vf2pp(g1, g2)` (g1 into g2), igraph `get_subisomorphisms_vf2` (pattern-indexed lists), the definition f: V(G) → V(H) | NetworkX's `GraphMatcher(G1, G2)` and rustworkx `vf2_mapping(first, second)` take the **target first** and map target → pattern. `g.isSubgraphIsomorphic(to: h)` is NetworkX's `GraphMatcher(h, g).subgraph_is_isomorphic()`. Every mapping here reads in one direction, from the receiver. |
| `Isomorphism` (also for subgraph and monomorphism results) | README's result type; "subgraph isomorphism" for both kinds in the literature: the mapping is an isomorphism from the pattern onto a (possibly non-induced) subgraph of the target | `VertexMapping`, `GraphMapping` (JGraphT): JGraphT's name, but "mapping" alone says nothing; a second type for monomorphisms would duplicate every member. |
| `image(of:)`, `preimage(of:)`, `images` | function terminology; Boost's `isomorphism_map` is a property map v ↦ f(v) | A subscript (NetworkX's `dict[v]`): one spelling only, and `image(of:)` follows `color(of:)`, `community(of:)`. `mapping`, `correspondence` (JGraphT `getVertexCorrespondence(v, forward)`). |
| `vertexColor:` / `otherVertexColor:`, `edgeColor:` / `otherEdgeColor:` | igraph `color1`, `color2`, `edge_color1`, `edge_color2`; bliss, nauty ("vertex-coloured graphs"); the literature (colour refinement, coloured graph isomorphism) | "label" (NetworkX vf2pp `node_label`, LEMON `nodeLabels`) collides with `LabeledGraph`, where the label *is* the vertex. A colour here is any `Hashable` class, not a proper colouring (`ColoringModule.Coloring`), which the doc comment states. Two closures because the graphs have different vertex and edge types (igraph's and LEMON's pairs). |
| `weisfeilerLehmanGraphHash`, `weisfeilerLehmanSubgraphHashes` | NetworkX, verbatim | `colorRefinement` (Grohe's term; JGraphT `ColorRefinementAlgorithm`): the stable partition is internal in phase 1. |
| `automorphismGroup()`, `orbits`, `generators`, `order` | igraph `automorphism_group`, Mathematica `GraphAutomorphismGroup`, Sage, nauty (`orbits`, `grpsize`), group theory | igraph `count_automorphisms`: `order` is the group-theory term and one call gives everything. |
| `basicOrbitLengths` | computational group theory (base and strong generating set: basic orbits Δ⁽ⁱ⁾, Seress; GAP, Sage) | nauty/bliss report only the (approximate) product. |
| `canonicalLabeling()`, `CanonicalForm` | nauty/Traces "canonical labelling", bliss `canonical_form`, igraph `canonical_permutation`, Mathematica `CanonicalGraph` | |

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

So parallel edges and self-loops count everywhere (IS-045 – IS-056, IS-104 – IS-107,
IS-131 – IS-136): a loop is an edge, a simple pattern edge cannot be induced on a parallel pair
(IS-106) but is contained in it (IS-133). This is NetworkX's multigraph matchers' reading (and
igraph VF2's where it supports the input); vertex colours must be equal, not compatible, and
edge colours are matched as multisets per pair (NetworkX `categorical_multiedge_match`).
Undirected and directed graphs are separate overloads; a directed mapping preserves arc
direction, so a 2-cycle is not two parallel arcs (IS-063).

The empty mapping is a mapping: two empty graphs are isomorphic (IS-001 – IS-003), and an empty
pattern has exactly one subgraph isomorphism and monomorphism into any target (IS-101, IS-102,
IS-129). NetworkX's GraphMatcher, igraph and rustworkx agree; NetworkX's vf2pp functions return
none (disagreements).

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
constant, so the hash is an invariant, not a fingerprint to trust against an adversary. On a directed graph the out- and in-multisets are kept apart. A self-loop
contributes its vertex twice (it has two ends, Graph's counting rule), and parallel edges count
once each (IS-160, IS-161, IS-174). `weisfeilerLehmanGraphHash(iterations: k)` hashes the colour
histograms of rounds 1 … k (round 0's histogram is the vertex count and the colour sizes,
IS-152, IS-153); `weisfeilerLehmanSubgraphHashes(iterations: k)` gives each vertex its colours
after rounds 1 … k. Isomorphic graphs hash equal; the converse fails (C6 against 2C3,
strongly regular pairs, CFI pairs: IS-147 – IS-149).

**Hash values are not pinned and not stable across processes.** Colours are arbitrary `Hashable`
values, and Swift's `Hasher` is seeded per process, so the hash is equal for equal inputs within
one run (as `hashValue`; `SWIFT_DETERMINISTIC_HASHING` makes it reproducible). NetworkX's hex
digests are stable but come from `str()` of its labels; matching them would need blake2b and
NetworkX's string forms. Rows pin equality between two graphs and the partitions, which are
library-independent; on simple graphs both equal NetworkX's at the same `iterations` (k ≥ 2,
checked on every row and in `--stress`).

### Automorphism group and canonical labeling (phase 2)

`orbits` are classes of vertices, each in `vertices` order, ordered by first vertex (as
`Partition`); `order` and `orbits` are pinned (IS-182 – IS-233; IS-216's order, 25!, exceeds
`Int`). `generators` are not pinned: bliss's own depend on its splitting heuristic, as igraph's
documentation says. Tests check each generator is an automorphism and that they generate a group
whose orbits are `orbits`, and that `basicOrbitLengths` multiply to `order`. Canonical labelings are not pinned
either (they depend on refinement and target-cell choices); tests check that isomorphic inputs
(relabelled copies) give equal `form`s and non-isomorphic rows give different ones.

## Determinism (decision)

**Pinned:** every yes/no answer, every count, the set of all mappings on small rows, a mapping
wherever it is unique (IS-032, IS-034, IS-061, IS-114, IS-145, and the accessor rows), WL
equalities and partitions, automorphism orders and orbits.

**Not pinned: which mapping comes first, and the order of `isomorphisms(to:)`.** Rows with
several mappings write `some (one of #N)`; the test checks the mapping against the definition and
that a second call gives the same one (the search is deterministic: no randomness, ties by index).
Pinning the first mapping would cost nothing at run time but would freeze the matching order and
candidate order of VF2++ (which NetworkX itself breaks ties for by dictionary order), so any later
improvement (a different root, Glasgow-style domains for hard subgraph instances, a phase 2 switch
to canonical forms for `isIsomorphic(to:)`) would change test values without changing
correctness. The libraries do not agree on a first mapping either: igraph and rustworkx (with
`id_order=True`) search in index order, NetworkX vf2pp in its own order. Lexicographically least
mappings (by index) would be a pinnable rule, but only an index-order search finds them first, and
that search is the slow one (VF2 without VF2++'s ordering).

## Algorithms (decision)

**Phase 1: subgraph isomorphism and monomorphism by VF2++ (Jüttner–Madarasi 2018); isomorphism by
VF2++'s order with joint colour refinement after every assignment (individualization–refinement
matching).**

- **Why VF2++.** It is VF2 (Cordella et al. 2004) with a matching order computed once (BFS from
  the rarest-coloured, highest-degree vertex; within a level, most connections to the vertices
  already ordered, then degree, then colour rarity) and cutting rules counted per colour class.
  Its paper measures it orders of magnitude faster than VF2 on the same inputs, and it is what
  NetworkX (≥ 3.2) and LEMON ship. It keeps O(n) state per search level and is lazy by
  construction (each solution is a leaf).
- **Why not VF2++ alone for isomorphism.** The baselines below settle it: on a random 3-regular
  graph with 1,000 vertices and a relabelled copy, NetworkX vf2pp, igraph VF2 and rustworkx VF2 all
  run past 30 s, while igraph's bliss answers in 11 ms. Degrees and colour classes give a regular
  graph one class, so a VF2-family matcher guesses blindly, deep into the search. Refinement fixes
  this: after the matcher assigns u ↦ x, give u and x a fresh colour and refine G and H jointly to
  the equitable partition. Isomorphisms that extend the partial mapping preserve the refined
  colours, so this is sound; a cell whose sizes differ in G and H prunes the branch at once; and on
  random regular graphs one or two assignments make every cell a singleton. This is the
  individualization–refinement step of nauty/bliss/Traces without their automorphism pruning or
  canonical form, so phase 2 reuses the same partition-refinement engine (cells as ranges of one
  array, splitting by neighbour counts, an undo trail for backtracking). Every leaf is still a
  mapping, so `isomorphisms(to:)` enumerates exactly as before (the counts in cases.md do not
  depend on the algorithm). Without any assignment, the root refinement alone decides trees, most
  random graphs and graphs with distinct classes (IS-043, IS-069 have one mapping).
- **Subgraph problems keep plain VF2++.** Refinement is not preserved by injections (a pattern
  vertex's degree is only a lower bound), so only degree and colour filters and VF2++'s cutting
  rules apply.
- **Not chosen for phase 1.** VF3 (Carletti et al. 2017) and VF3-Light: better than VF2++ on
  large dense subgraph instances, with a probability-based order that needs more preprocessing;
  RI (Bonnici et al. 2013): a static order close to VF2++'s, best on sparse labelled biological
  graphs; Glasgow (McCreesh–Prosser–Trimble 2020): constraint programming with bitset domains and
  supplemental graphs, the strongest solver on hard subgraph instances but a much larger
  implementation; LAD (Solnon 2010, igraph): all-different filtering, good for hard non-induced
  instances. All are candidates for a phase 3 switch inside the same entry points if benchmarks on
  hard subgraph instances ask for it.
- **Where phase 1 lost.** Without automorphism pruning, a non-isomorphic pair that refinement
  cannot separate (CFI pairs, IS-041; strongly regular pairs, IS-029; disjoint unions of equal
  components against unions with one component changed) made the search visit every branch: 33 s
  on Latin-square graphs of Z₂₄ against Z₂ × Z₁₂, 11 s on a twisted CFI pair over a base of 40, past
  30 s on 5 · K3,3 against 4 · K3,3 plus a prism (bliss: 50 ms, 5 ms, under 2 ms). Phase 2 fixed it.

**Phase 2 (implemented): automorphism pruning and canonical labeling** (McKay–Piperno 2014,
nauty/Traces; Junttila–Kaski 2007, bliss) on the phase 1 refinement engine, run on one graph
(`AutomorphismSearch.swift`). The refinement is made label-invariant (touched cells split in
position order) and records each node's events (running hashes of its splits); a node's invariant
is its path's event sequences, compared lexicographically. The first leaf fixes the base; a later
leaf whose path has the first path's events gives an automorphism when the permutation between the
two leaves keeps every edge (checked edge by edge), and the search jumps back to where the paths
part. Orbit pruning at every node uses the generators that fix the node's individualized vertices
(union–find over the target cell, smallest vertex first). Without canonical labeling a node whose
events part from the first path's is abandoned at the first differing event (bliss's early abort),
which is what makes random regular graphs cheap; with it, the canonical leaf is the greatest by
(events along the path, certificate = the graph relabelled by the leaf), nodes already less than
the best are abandoned, and a leaf equal to the best gives an automorphism. Target cell: the first
largest non-singleton cell (measured against first smallest: equal on CFI and random regular, first
largest better on Latin-square graphs). Generators are kept only when they join orbits at their
level of the stabiliser chain (at most n − 1, a strong generating set), and `order` is the exact
product of the basic orbit lengths rounded once to `Double`.

`isIsomorphic(to:)` keeps the phase 1 joint search, now with a budget (64 + 2n nodes, and at most
one subtree below the first level exhausted without a leaf: the sign that refinement is not
telling branches apart; with four, Latin-square pairs spent 30 ms there before the fallback). Over budget, the pair is decided by canonical labeling: component by
component when either graph is disconnected (bliss's component recursion: components pair off by
size, then by certificate), else the whole graphs. Random regular graphs stay with the joint search,
which beats two canonical labelings there (a wrong assignment fails at once). Every further element
of `isomorphisms(to:)` is the first mapping composed with an automorphism of G, enumerated from the
stabiliser chain (O(n) per mapping). A triangle-count root invariant was considered for disjoint
unions and not added: the component recursion already decides them in under a millisecond.

**Bounding a search.** The joint search, the canonical searches behind `isIsomorphic(to:)`, the
enumeration and the subgraph searches check `Task.isCancelled` (every 256 nodes, every element,
every 4,096 steps); a cancelled task ends the sequence, so the decision returns false and the first
mapping nil. `automorphismGroup()` and `canonicalLabeling()` run to completion. Families that stay
exponential for every individualization–refinement solver: Miyazaki graphs and other rigid CFI-gadget
constructions, where neither refinement nor automorphisms prune.

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
- The search runs on an explicit stack (no recursion), with `~Copyable` scratch buffers, per the
  performance notes; the iterator of `Isomorphisms` is the suspended stack.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| set-up (all matching entry points) | O(n + m) to build rows and colour ids; for isomorphism, the root refinement O((n + m) log n) (Hopcroft-style splitting, smaller half first) | O(n + m), plus n_H² / 8 bytes for the bit matrix when n_H ≤ 4,096 |
| `isIsomorphic`, `isomorphism`, first element of `isomorphisms` | exponential in the worst case (as every practical algorithm; graph isomorphism is quasi-polynomial, Babai 2016, with no practical implementation); per search node one incremental refinement, O((n + m) log n) at worst and usually far less | O(n + m) undo trail, O(n) per level |
| subgraph isomorphism, monomorphism | NP-complete; VF2++ is exponential in the pattern size | O(n_G) per level |
| each further mapping of a sequence | the search between two leaves | — |
| `weisfeilerLehmanGraphHash`, `weisfeilerLehmanSubgraphHashes` | O(k (n + m)) for k iterations | O(n + m) (k n for the subgraph hashes) |
| `automorphismGroup`, `canonicalLabeling` (phase 2) | exponential in the worst case (Miyazaki graphs); near-linear refinement per node | O(n + m) plus O(n) per tree level and the generators |

## Performance

Baselines from `ref.py --bench` (Apple silicon, CPython 3.12, `> 30 s` is the timeout; the
machine was shared, so read the slow columns as orders of magnitude). Cases: `rrgD-N` a random
D-regular graph against a relabelled copy, `grid100`, `paleyQ`, `srg16` (Shrikhande against
rook(4)), `cfiN` (CFI over a random cubic base of N against a relabelled copy; `t`: the twisted
partner), `lsgN` (the Latin-square graph of Z_N against a relabelled copy; `t`: against
Z₂ × Z_(N/2)), `unionc6` (20 hexagons against 19 and two triangles), `unionk33` (20 · K3,3
against 19 · K3,3 and a prism):

| Case | NetworkX vf2pp | igraph VF2 | rustworkx VF2 | Automorphisms (bliss) |
|---|---|---|---|---|
| rrg3-1000 | > 30 s | > 30 s | > 30 s | 1 |
| rrg3-10000 | > 30 s | > 30 s | > 30 s | 1 |
| rrg10-1000 | > 30 s | > 30 s | > 30 s | 1 |
| grid100 | > 30 s | > 30 s | > 30 s | 8 |
| paley101 | 26.5 ms | 1.7 ms | 2.3 ms | 5050 |
| paley401 | > 30 s | 656.2 ms | 3531.2 ms | 80200 |
| srg16 | 3.3 ms | 0.3 ms | 0.4 ms | 192 |
| cfi10 | 465.9 ms | 4.7 ms | 3.7 ms | 128 |
| cfi10t | 7523.1 ms | 359.2 ms | 339.1 ms | 128 |
| cfi20 | 48.2 ms | 5.2 ms | 10.9 ms | 4096 |
| cfi20t | 25468.3 ms | > 30 s | > 30 s | 4096 |
| cfi40 | > 30 s | > 30 s | > 30 s | 4194304 |
| cfi40t | > 30 s | > 30 s | > 30 s | 4194304 |
| lsg16 | > 30 s | 3230.1 ms | 4521.8 ms | 12288 |
| lsg16t | > 30 s | > 30 s | > 30 s | 12288 |
| lsg24 | > 30 s | > 30 s | > 30 s | 27648 |
| lsg24t | > 30 s | > 30 s | > 30 s | 27648 |
| unionc6 | > 30 s | > 30 s | > 30 s | 9327162384492722424337957734989168640000 |
| unionk33 | > 30 s | > 30 s | > 30 s | 34101583473900979588646299272539039458037999484272640000 |

The Swift implementation on the same edge lists (exported by `ref.py --export
Benchmarks/Data/Isomorphism`, read by `IsomorphismBenchmarks`) against bliss through python-igraph
1.0.0, the best of five runs each (bliss's times include igraph's Python call). Two measures, not
to be mixed: **decision** (`isIsomorphic(to:)`, against `isomorphic_bliss`, which computes two
canonical labelings) and **canonical labeling** or **automorphism group** of one graph (against
`canonical_permutation` and `count_automorphisms`). The decision's joint search usually needs no
canonical labeling at all, which is why it can beat bliss's decision by more than its canonical
labeling beats bliss's.

| Case | Answer | `isIsomorphic(to:)` (decision) | bliss `isomorphic_bliss` (decision) | `canonicalLabeling()` of G | bliss `canonical_permutation` of G | `automorphismGroup()` of G | bliss `count_automorphisms` of G |
|---|---|---|---|---|---|---|---|
| rrg3-1000 | true | 1.31 ms | 15.40 ms | 2.19 ms | 4.40 ms | 0.93 ms | 3.50 ms |
| rrg3-10000 | true | 86.3 ms | 1752.70 ms | 73.7 ms | 1014.10 ms | 51.1 ms | 1088.00 ms |
| rrg10-1000 | true | 5.16 ms | 31.70 ms | 5.77 ms | 9.30 ms | 3.84 ms | 6.40 ms |
| grid100 | true | 3.30 ms | 11.50 ms | 3.83 ms | 4.40 ms | 3.03 ms | 4.30 ms |
| paley101 | true | 0.16 ms | 1.10 ms | 0.23 ms | 0.60 ms | 0.16 ms | 0.60 ms |
| paley401 | true | 3.38 ms | 19.30 ms | 3.49 ms | 7.80 ms | 1.59 ms | 7.60 ms |
| srg16 | false | 0.06 ms | < 0.1 ms | 0.03 ms | < 0.1 ms | 0.02 ms | < 0.1 ms |
| cfi10 | true | 0.02 ms | 0.40 ms | 0.19 ms | 0.20 ms | 0.12 ms | 0.10 ms |
| cfi10t | false | 0.38 ms | 0.40 ms | 0.19 ms | 0.50 ms | 0.12 ms | 0.10 ms |
| cfi20 | true | 0.13 ms | 0.90 ms | 0.60 ms | 0.40 ms | 0.27 ms | 0.30 ms |
| cfi20t | false | 1.45 ms | 1.10 ms | 0.62 ms | 0.40 ms | 0.27 ms | 0.30 ms |
| cfi40 | true | 0.32 ms | 4.50 ms | 2.07 ms | 1.80 ms | 0.91 ms | 1.20 ms |
| cfi40t | false | 4.14 ms | 5.10 ms | 2.06 ms | 1.80 ms | 0.89 ms | 1.30 ms |
| lsg16 | true | 0.50 ms | 7.90 ms | 2.30 ms | 3.20 ms | 1.40 ms | 3.00 ms |
| lsg16t | false | 8.87 ms | 9.10 ms | 2.30 ms | 3.10 ms | 1.41 ms | 3.00 ms |
| lsg24 | true | 1.76 ms | 26.70 ms | 9.03 ms | 11.00 ms | 5.07 ms | 11.00 ms |
| lsg24t | false | 31.4 ms | 75.20 ms | 9.01 ms | 11.00 ms | 5.08 ms | 11.00 ms |
| unionc6 | false | 0.09 ms | 5.30 ms | 2.28 ms | 0.40 ms | 2.15 ms | 0.40 ms |
| unionk33 | false | 0.53 ms | 2.20 ms | 5.12 ms | 0.90 ms | 4.81 ms | 0.90 ms |

Readings. Decisions are within 1.3× of bliss's on every case and faster on most: random regular
graphs 6–20× faster (the joint search refutes a wrong assignment at once), Latin-square pairs
2.4×, twisted CFI at base 40 1.2×. Canonical labeling and the automorphism group are within 2× of
bliss except on the two disjoint unions (2–5 ms against 0.4–0.9 ms: bliss recurses on components,
ours only inside the decision). Phase 1 took 33 s on `lsg24t`, 11.4 s on `cfi40t`, and past 30 s
on 5 · K3,3 against 4 · K3,3 and a prism.

Targets for the Swift implementation, measured in the benchmark target against the same inputs:

| Measure | Target |
|---|---|
| Random 3- and 10-regular graphs, 1,000 and 10,000 vertices, relabelled (the root refinement gives one class) | decision within 2× bliss's decision, canonical labeling and automorphism group within 2–3× bliss's (met: faster than bliss) |
| Non-regular inputs (grid 100 × 100, random sparse graphs) | the root refinement decides them: within 3× one refinement pass; ≤ igraph VF2 and rustworkx |
| Subgraph and monomorphism counts (IS-093 – IS-146 shapes, scaled: C4/C5/P4 in random graphs with 10⁴ edges) | ≤ igraph VF2 and rustworkx; within 2× igraph LAD on non-induced counts |
| Paley(101), Paley(401), the Shrikhande/rook pair | within 2× igraph bliss (met) |
| CFI graphs over random cubic bases (10, 20, 40 base vertices), twisted and untwisted; Latin-square pairs (16, 24); disjoint unions | within 2× igraph bliss on `automorphismGroup()` and on the yes/no answer (met, except the automorphism group and canonical labeling of disjoint unions: 5×) |
| Miyazaki graphs (the bliss/Traces benchmark family) | within 3× bliss up to 1,000 vertices. Not measured yet: `ref.py` does not generate them |
| `weisfeilerLehmanGraphHash(iterations: 3)` on 10⁶ edges | ≥ 50× NetworkX (pure Python), O(m) |
| Allocations per extra element of `isomorphisms(to:)` | one `[Int]` (the images) |

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Empty graphs, empty pattern | NetworkX 3.7 `vf2pp_is_isomorphic(∅, ∅)` is `False`, `vf2pp_isomorphism` returns `None`, `vf2pp_all_*` yield nothing, `vf2pp_subgraph_is_isomorphic(G, ∅)` is `False`; NetworkX `GraphMatcher`, igraph and rustworkx give the empty mapping. Ours: the empty mapping | IS-001 – IS-003, IS-101, IS-102, IS-129; 615 `--stress` cases |
| `weisfeiler_lehman_graph_hash(G, iterations=1)` without attributes | NetworkX 3.7 starts from degree labels and subtracts one iteration, so at 1 it hashes an empty history: every graph gets the same digest (`P4` and the star, IS-151). Ours: round 1 is the degree histogram | IS-151, IS-154 |
| `weisfeiler_lehman_graph_hash(iterations=0)` | NetworkX raises `ValueError`; ours hashes the colour histogram (vertex count and colour sizes) | IS-152, IS-153 |
| WL on multigraphs and loops | NetworkX raises on multigraphs (`not_implemented_for("multigraph")`) and sees a loop's vertex once (`G.neighbors`); ours counts edge ends | IS-160, IS-161, IS-174 |
| igraph `subisomorphic_vf2` | a **monomorphism** test despite the name (P3 in K3 is `True`; IS-087 against IS-117); `subisomorphic_lad` takes `induced=` (default `False`) | IS-087, IS-117 |
| igraph VF2 and self-loops | "The VF2 algorithm does not support graphs with loop edges" (error). LAD accepts loops but disagrees with the definition on them (K1 into a looped vertex counted as induced, IS-104; 33 `--stress` cases) | IS-104 |
| igraph VF2 and parallel edges | accepted, but wrong with edge colours on a parallel pair (IS-083: 0 mappings for 2) and on 1 `--stress` case without colours; LAD rejects multi-edges | IS-083 |
| Mapping direction | NetworkX `GraphMatcher(G1, G2)` subgraph mappings and rustworkx `vf2_mapping(first, second, subgraph=True)` map target → pattern; igraph `get_isomorphisms_vf2` lists map the *other* graph's vertices into this one's; igraph `get_subisomorphisms_*`, Boost and LEMON map pattern → target. Ours: always receiver → argument | `ref.py` inverts each |
| Automorphism count type | igraph returns an exact Python `int` (25! for `E(25)`); nauty and bliss a floating approximation. Ours: `order: Double` plus exact `basicOrbitLengths` | IS-216 |

## README edits proposed

- `IsomorphismModule` row: "On `Graph` and `DirectedGraph`: `isIsomorphic(to:)`, `isomorphism(to:)`,
  `isomorphisms(to:)` (lazy), the induced `subgraphIsomorphism…` and non-induced `monomorphism…`
  families (VF2++; isomorphism with joint colour refinement after every assignment), each with
  vertex and edge colours;
  `weisfeilerLehmanGraphHash`, `weisfeilerLehmanSubgraphHashes`. Phase 2: `automorphismGroup()`,
  `canonicalLabeling()` (individualization–refinement)." Result types: `Isomorphism` (pattern →
  target, also for subgraph mappings), `Isomorphisms`, `WeisfeilerLehmanSubgraphHashes`;
  phase 2 `AutomorphismGroup`, `CanonicalLabeling`.
- Terminology rows: "Mapping onto an induced subgraph / onto a subgraph: subgraph isomorphism /
  monomorphism (NetworkX, Boost); mathematical: induced subgraph isomorphism / subgraph
  isomorphism (Ullmann)". "Vertex and edge classes a mapping must preserve: colour (igraph, bliss,
  nauty); NetworkX, LEMON: label".
- The module needs only `GraphProtocols`, as its BUILD file says now.

## Settled in the phase 1 implementation

- The Weisfeiler–Leman colour overloads are `(iterations:vertexColor:)` and
  `(iterations:vertexColor:edgeColor:)`, on both protocols, for both the graph hash and the
  subgraph hashes.
- `weisfeilerLehmanSubgraphHashes` are invariant under isomorphism vertex by vertex: an
  isomorphism f gives `hashes(of: f(v))` on the target equal to `hashes(of: v)` on the pattern
  (same colours, within one process).
- Colour closures are read at most once per vertex and edge, at the call (exactly once each in
  the implementation); iterating a sequence reads none.
- `isomorphism(to:)` is not promised to be the first element of `isomorphisms(to:)`. In phase 1 it
  is (both run the same search), but a later dispatch (phase 2's canonical forms) may change that.
- Every open question below is decided as recommended.

## Open questions (with recommendations)

1. **Overload count.** Nine entry points × three colour shapes × two protocols is 54 thin
   `@inlinable` wrappers over one engine. *Recommendation:* accept it; the alternative (an options
   value, or colours as `[C]` side arrays) is invented API. Edge colours alone pass a constant
   vertex colour (`vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }`).
2. **`order` type.** *Recommendation:* `Double` plus `basicOrbitLengths: [Int]` (exact product),
   rather than a big-integer type the package does not have. Revisit if swift-numerics' big
   integers land.
3. **Hash stability.** *Recommendation:* per-process (`Hasher`), documented; a stable 128-bit
   variant for uncoloured graphs only if someone needs hashes persisted.
4. **First mapping.** *Recommendation:* not pinned (Determinism). Revisit only if a caller needs
   reproducible mappings across library versions, in which case pin "lexicographically least by
   index" behind a separate, slower entry point.
5. **Phase 2 dispatch.** Decided (Algorithms): the joint search runs first under a budget, canonical
   forms decide what it cannot; random regular pairs stay with the joint search, which beats two
   canonical labelings there.
