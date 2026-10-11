# IsomorphismModule: case catalog (IS-001 – IS-233, 233 rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 --with rustworkx==0.18.1 python3 Tests/Catalogs/Isomorphism/ref.py`; `--write`
regenerates this file, `--stress` adds random graphs). The model enumerates every mapping from the
definitions in api.md; rows with at most 7 target vertices are also checked against brute force
over every injection, and every matching row with at most 6,000 mappings is compared, as a set of
mappings, with NetworkX 3.7 (`GraphMatcher` and its directed and multigraph kinds, and the vf2pp
functions), python-igraph 1.0.0 (VF2 and LAD) and rustworkx 0.18.1 (`vf2_mapping`), each where it
supports the input. Disagreements are in api.md. Weisfeiler–Leman partitions are compared with
NetworkX's `weisfeiler_lehman_subgraph_hashes` and hash equality with its
`weisfeiler_lehman_graph_hash` on simple undirected rows. Automorphism group orders and orbits
come from enumeration and python-igraph's bliss, which must agree.

## Notation

**Graph**: `U:` undirected, `D:` directed. An optional vertex list in brackets comes first, then
edges in **position order**. `vertices` is the listed vertices, then the vertices of generators,
then endpoints by first appearance. Vertices are `Int`s.

| Token | Edges |
|---|---|
| `u-v`, `u>v`, `u=v` | one edge; one arc; two parallel edges u–v |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)` | vertices 0..<n listed, every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `E(n)` | vertices 0..<n, no edges |
| `grid(r,c)` | vertices `i*c + j` listed; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: vertices 0..<2^d listed; for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `paley(q)` | vertices 0..<q listed; i–j for i < j when j − i is a nonzero square mod q (q prime, q ≡ 1 mod 4) |
| `tpaley(q)` | vertices 0..<q listed; i>j for every ordered pair when j − i is a nonzero square mod q (q ≡ 3 mod 4) |
| `tt(k)` | the transitive tournament: vertices 0..<k listed; i>j for i < j, lexicographic |
| `rook(k)` | K_k □ K_k: vertices `i*k + j` listed; a–b for a < b in one row or one column, lexicographic |
| `shrikhande` | the Cayley graph of Z4 × Z4 with connection set ±(1,0), ±(0,1), ±(1,1); vertex `4i + j` is (i, j); a–b for a < b, lexicographic |
| `cfi(B)`, `cfi~(B)` | the Cai–Fürer–Immerman graph over the base B (written in this notation); `~` twists B's first edge. Per base vertex v in index order: one middle vertex per even subset S of v's incident edges (as a bitmask over v's incidences in position order, ascending), then a(v, j, 0), a(v, j, 1) for each incidence j. Edges: per v, per S, per j, S–a(v, j, [j ∈ S]); then per base edge (u, w) in position order, a(u, j, i)–a(w, j′, i ⊕ t) for i = 0, 1, t = 1 only on the twisted edge |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `… ~map(a,b)` | the same graph relabelled: vertex x becomes (a·x + b) mod n (gcd(a, n) = 1), edges in the same positions, vertices 0..<n listed |
| `a..b` | every integer from a to b inclusive |

**Op** is the call `G.op(to: H)` (G is the pattern, the domain of every mapping), or `G.op` for
one-graph rows. `vertexColor: G [..] H [..]` passes `vertexColor:` (G's colours, in `vertices`
order) and `otherVertexColor:` (H's); `edgeColor:` likewise by edge position. `.count` is the
length of the lazy sequence. An `isomorphisms(to:)`-style op without `.count` is the whole sequence,
written as a set: **the order of the sequence is not pinned**, only its elements. `image(of:) after
isomorphism(to:)` runs the call, then the accessor on its result (those rows have exactly one
mapping).

**Expected.** A mapping is written as its images in G's `vertices` order: `[2, 0]` maps G's first
vertex to H's vertex 2. `some (one of #N)` means a mapping is returned and is not pinned: the test
checks it with the definition and checks that a second call returns the same one. `nil` is no
mapping. `#N` is a count. Weisfeiler–Leman partitions list, for each round r, the classes of
vertices with equal hashes, each class in `vertices` order, classes by their first vertex.
Hashes themselves are not pinned (api.md). `**trap**` rows are preconditions.


| ID | Group | Case | G (pattern) | H (target) | Op | Expected |
|---|---|---|---|---|---|---|
| IS-001 | Isomorphism | empty graphs: the empty mapping | `U:` | `U:` | `isIsomorphic(to:)` | true |
| IS-002 | Isomorphism | empty graphs: one mapping, the empty one | `U:` | `U:` | `isomorphisms(to:)` | {[]} |
| IS-003 | Isomorphism | empty graphs: isomorphism(to:) is the empty mapping | `U:` | `U:` | `isomorphism(to:)` | [] |
| IS-004 | Isomorphism | one vertex each | `U: [0]` | `U: [7]` | `isomorphism(to:)` | [7] |
| IS-005 | Isomorphism | different vertex counts | `U: [0]` | `U: [0, 1]` | `isIsomorphic(to:)` | false |
| IS-006 | Isomorphism | same vertex count, different edge counts | `U: P(0,1,2)` | `U: [0, 1, 2] 0-1` | `isIsomorphic(to:)` | false |
| IS-007 | Isomorphism | path against star, same counts, degrees differ | `U: P(0,1,2,3)` | `U: S(0;1..3)` | `isIsomorphic(to:)` | false |
| IS-008 | Isomorphism | C6 against two triangles: same degrees, 1-WL equal | `U: C(0,1,2,3,4,5)` | `U: C(0,1,2), C(3,4,5)` | `isIsomorphic(to:)` | false |
| IS-009 | Isomorphism | C6 against two triangles: no mapping | `U: C(0,1,2,3,4,5)` | `U: C(0,1,2), C(3,4,5)` | `isomorphism(to:)` | nil |
| IS-010 | Isomorphism | C6 against a relabelled C6 | `U: C(0,1,2,3,4,5)` | `U: C(0,1,2,3,4,5) ~map(5,2)` | `isomorphisms(to:).count` | #12 |
| IS-011 | Isomorphism | C4: all eight | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `isomorphisms(to:)` | {[0, 1, 2, 3], [0, 3, 2, 1], [1, 0, 3, 2], [1, 2, 3, 0], [2, 1, 0, 3], [2, 3, 0, 1], [3, 0, 1, 2], [3, 2, 1, 0]} |
| IS-012 | Isomorphism | P3 onto a relabelled P3: both | `U: P(0,1,2)` | `U: P(1,0,2)` | `isomorphisms(to:)` | {[1, 0, 2], [2, 0, 1]} |
| IS-013 | Isomorphism | path P5 | `U: P(0,1,2,3,4)` | `U: P(0,1,2,3,4) ~map(2,1)` | `isomorphisms(to:).count` | #2 |
| IS-014 | Isomorphism | K4 | `U: K(4)` | `U: K(4)` | `isomorphisms(to:).count` | #24 |
| IS-015 | Isomorphism | K5 | `U: K(5)` | `U: K(5) ~map(2,3)` | `isomorphisms(to:).count` | #120 |
| IS-016 | Isomorphism | K3,3 | `U: KB(0..2;3..5)` | `U: KB(0..2;3..5) ~map(5,1)` | `isomorphisms(to:).count` | #72 |
| IS-017 | Isomorphism | star K1,5 | `U: S(0;1..5)` | `U: S(5;0..4)` | `isomorphisms(to:).count` | #120 |
| IS-018 | Isomorphism | five isolated vertices | `U: E(5)` | `U: E(5)` | `isomorphisms(to:).count` | #120 |
| IS-019 | Isomorphism | grid 3x3 | `U: grid(3,3)` | `U: grid(3,3) ~map(2,0)` | `isomorphisms(to:).count` | #8 |
| IS-020 | Isomorphism | cube Q3 | `U: Q(3)` | `U: Q(3) ~map(3,1)` | `isomorphisms(to:).count` | #48 |
| IS-021 | Isomorphism | hypercube Q4 | `U: Q(4)` | `U: Q(4) ~map(5,3)` | `isomorphisms(to:).count` | #384 |
| IS-022 | Isomorphism | Petersen | `U: nx(petersen)` | `U: nx(petersen) ~map(3,4)` | `isomorphisms(to:).count` | #120 |
| IS-023 | Isomorphism | Petersen: some mapping | `U: nx(petersen)` | `U: nx(petersen) ~map(3,4)` | `isomorphism(to:)` | some (one of #120) |
| IS-024 | Isomorphism | Heawood | `U: nx(heawood)` | `U: nx(heawood) ~map(3,5)` | `isomorphisms(to:).count` | #336 |
| IS-025 | Isomorphism | Möbius–Kantor | `U: nx(moebius_kantor)` | `U: nx(moebius_kantor) ~map(5,7)` | `isomorphisms(to:).count` | #96 |
| IS-026 | Isomorphism | Desargues against the dodecahedron: both cubic on 20 vertices | `U: nx(desargues)` | `U: nx(dodecahedral)` | `isIsomorphic(to:)` | false |
| IS-027 | Isomorphism | dodecahedron | `U: nx(dodecahedral)` | `U: nx(dodecahedral) ~map(3,7)` | `isomorphisms(to:).count` | #120 |
| IS-028 | Isomorphism | Paley(13) | `U: paley(13)` | `U: paley(13) ~map(2,5)` | `isomorphisms(to:).count` | #78 |
| IS-029 | Isomorphism | Shrikhande against the 4x4 rook's graph: both srg(16,6,2,2) | `U: shrikhande` | `U: rook(4)` | `isIsomorphic(to:)` | false |
| IS-030 | Isomorphism | Shrikhande | `U: shrikhande` | `U: shrikhande ~map(3,1)` | `isomorphisms(to:).count` | #192 |
| IS-031 | Isomorphism | 4x4 rook's graph | `U: rook(4)` | `U: rook(4) ~map(5,2)` | `isomorphisms(to:).count` | #1152 |
| IS-032 | Isomorphism | Frucht (asymmetric): the one mapping | `U: nx(frucht)` | `U: nx(frucht) ~map(5,1)` | `isomorphism(to:)` | [1, 6, 11, 4, 9, 2, 7, 0, 5, 10, 3, 8] |
| IS-033 | Isomorphism | Frucht onto itself: only the identity | `U: nx(frucht)` | `U: nx(frucht)` | `isomorphisms(to:)` | {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]} |
| IS-034 | Isomorphism | asymmetric tree on 7 vertices: the one mapping | `U: P(0,1,2,3,4,5), 2-6` | `U: P(6,5,4,3,2,1), 4-0` | `isomorphism(to:)` | [6, 5, 4, 3, 2, 1, 0] |
| IS-035 | Isomorphism | two trees with one degree sequence | `U: P(0,1,2,3,4), 1-5` | `U: P(0,1,2,3,4), 2-5` | `isIsomorphic(to:)` | false |
| IS-036 | Isomorphism | karate club against a relabelling | `U: nx(karate_club)` | `U: nx(karate_club) ~map(5,3)` | `isomorphisms(to:).count` | #480 |
| IS-037 | Isomorphism | isolated vertex kept: K2 + K1 | `U: [0, 1, 2] 0-1` | `U: [0, 1, 2] 2-1` | `isomorphisms(to:)` | {[1, 2, 0], [2, 1, 0]} |
| IS-038 | Isomorphism | disconnected: 2K2 against P3 + K1 | `U: 0-1, 2-3` | `U: [0, 1, 2, 3] 0-1, 1-2` | `isIsomorphic(to:)` | false |
| IS-039 | Isomorphism | disconnected: 2C3 + K1 against a relabelling | `U: [6] C(0,1,2), C(3,4,5)` | `U: [0] C(1,2,3), C(4,5,6)` | `isomorphisms(to:).count` | #72 |
| IS-040 | Isomorphism | vertex names: images are target vertices, in pattern `vertices` order | `U: [5, 9, 7] 5-9` | `U: [2, 0, 4] 4-2` | `isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` | [2, 4, 0] |
| IS-041 | Isomorphism | CFI over K4 against its twisted copy: 1-WL equal, not isomorphic | `U: cfi(K(4))` | `U: cfi~(K(4))` | `isIsomorphic(to:)` | false |
| IS-042 | Isomorphism | CFI over K4 against a relabelling | `U: cfi(K(4))` | `U: cfi(K(4)) ~map(7,3)` | `isomorphisms(to:).count` | #192 |
| IS-043 | Isomorphism | random graph lcg(12,24,1) against a relabelling | `U: lcg(12,24,1)` | `U: lcg(12,24,1) ~map(5,7)` | `isomorphisms(to:).count` | #1 |
| IS-044 | Isomorphism | lcg(12,24,1) against lcg(12,24,2) | `U: lcg(12,24,1)` | `U: lcg(12,24,2)` | `isIsomorphic(to:)` | false |
| IS-045 | Loops and parallel edges | loop at the end of an edge, either end | `U: 0-0, 0-1` | `U: 1-1, 0-1` | `isomorphism(to:)` | [1, 0] |
| IS-046 | Loops and parallel edges | a loop counts 2: degrees (2,1,1) both, still not isomorphic | `U: 0-0, 1-2` | `U: P(0,1,2)` | `isIsomorphic(to:)` | false |
| IS-047 | Loops and parallel edges | loop against no loop | `U: [0] 0-0` | `U: [0]` | `isIsomorphic(to:)` | false |
| IS-048 | Loops and parallel edges | two loops against one | `U: 0-0, 0-0` | `U: 0-0, 1-1` | `isIsomorphic(to:)` | false |
| IS-049 | Loops and parallel edges | two loops on one vertex against two loops on one vertex | `U: 0-0, 0-0, 0-1` | `U: 0-1, 1-1, 1-1` | `isomorphism(to:)` | [1, 0] |
| IS-050 | Loops and parallel edges | parallel pair moves to the other edge | `U: 0=1, 1-2` | `U: 0-1, 1=2` | `isomorphism(to:)` | [2, 1, 0] |
| IS-051 | Loops and parallel edges | parallel pair against a path: same degrees | `U: 0=1, 2-3` | `U: P(0,1,2,3)` | `isIsomorphic(to:)` | false |
| IS-052 | Loops and parallel edges | multiplicity 3 against 2 + 1 elsewhere | `U: 0=1, 0-1` | `U: 0=1, 1-2` | `isIsomorphic(to:)` | false |
| IS-053 | Loops and parallel edges | doubled triangle | `U: 0=1, 1=2, 2=0` | `U: 0=1, 1=2, 2=0` | `isomorphisms(to:).count` | #6 |
| IS-054 | Loops and parallel edges | doubled C4 | `U: 0=1, 1=2, 2=3, 3=0` | `U: 0=1, 1=2, 2=3, 3=0` | `isomorphisms(to:).count` | #8 |
| IS-055 | Loops and parallel edges | bouquet: one vertex, three loops | `U: 0-0, 0-0, 0-0` | `U: 0-0, 0-0, 0-0` | `isomorphisms(to:)` | {[0]} |
| IS-056 | Loops and parallel edges | loops and parallel edges together | `U: 0-0, 0=1, 1-2, 2-2` | `U: 2-2, 2=1, 1-0, 0-0` | `isomorphisms(to:)` | {[2, 1, 0]} |
| IS-057 | Directed | out-path against in-star: same counts | `D: 0>1, 1>2` | `D: 0>1, 2>1` | `isIsomorphic(to:)` | false |
| IS-058 | Directed | directed C3 against itself | `D: C(0,1,2)` | `D: C(0,1,2)` | `isomorphisms(to:)` | {[0, 1, 2], [1, 2, 0], [2, 0, 1]} |
| IS-059 | Directed | directed C3 against its reverse | `D: C(0,1,2)` | `D: C(2,1,0)` | `isomorphisms(to:)` | {[2, 1, 0], [1, 0, 2], [0, 2, 1]} |
| IS-060 | Directed | directed C3 against the transitive tournament | `D: C(0,1,2)` | `D: tt(3)` | `isIsomorphic(to:)` | false |
| IS-061 | Directed | transitive tournament on 5: only one | `D: tt(5)` | `D: tt(5) ~map(2,1)` | `isomorphism(to:)` | [1, 3, 0, 2, 4] |
| IS-062 | Directed | Paley tournament on 7 | `D: tpaley(7)` | `D: tpaley(7) ~map(3,2)` | `isomorphisms(to:).count` | #21 |
| IS-063 | Directed | 2-cycle against two parallel arcs | `D: 0>1, 1>0` | `D: 0>1, 0>1` | `isIsomorphic(to:)` | false |
| IS-064 | Directed | 2-cycle against itself | `D: 0>1, 1>0` | `D: 0>1, 1>0` | `isomorphisms(to:)` | {[0, 1], [1, 0]} |
| IS-065 | Directed | same out-degrees, in-degrees differ | `D: 0>1, 0>2, 1>2` | `D: 0>1, 0>2, 2>0` | `isIsomorphic(to:)` | false |
| IS-066 | Directed | loop at the tail against loop at the head | `D: 0>0, 0>1` | `D: 1>1, 0>1` | `isomorphism(to:)` | nil |
| IS-067 | Directed | directed loop moves across the arc | `D: 0>0, 0>1` | `D: 1>1, 1>0` | `isomorphism(to:)` | [1, 0] |
| IS-068 | Directed | orientations of C4: alternating against cyclic | `D: 0>1, 2>1, 2>3, 0>3` | `D: C(0,1,2,3)` | `isIsomorphic(to:)` | false |
| IS-069 | Directed | random digraph lcg(10,25,3) against a relabelling | `D: lcg(10,25,3)` | `D: lcg(10,25,3) ~map(3,4)` | `isomorphisms(to:).count` | #1 |
| IS-070 | Directed | directed multigraph: three parallel arcs | `D: 0>1, 0>1, 0>1` | `D: 1>0, 1>0, 1>0` | `isomorphism(to:)` | [1, 0] |
| IS-071 | Colours | C4, colours r r b b against r b r b | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `isIsomorphic(to:) vertexColor: G [r,r,b,b] H [r,b,r,b]` | false |
| IS-072 | Colours | C4, colours r r b b against b r r b | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `isomorphisms(to:) vertexColor: G [r,r,b,b] H [b,r,r,b]` | {[1, 2, 3, 0], [2, 1, 0, 3]} |
| IS-073 | Colours | colour class sizes differ | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `isIsomorphic(to:) vertexColor: G [r,r,r,b] H [r,r,b,b]` | false |
| IS-074 | Colours | a colour missing from the target | `U: K(3)` | `U: K(3)` | `isIsomorphic(to:) vertexColor: G [r,r,g] H [r,r,b]` | false |
| IS-075 | Colours | Petersen with one vertex coloured: its stabiliser | `U: nx(petersen)` | `U: nx(petersen)` | `isomorphisms(to:).count vertexColor: G [x,o,o,o,o,o,o,o,o,o] H [x,o,o,o,o,o,o,o,o,o]` | #12 |
| IS-076 | Colours | Petersen, the coloured vertex elsewhere | `U: nx(petersen)` | `U: nx(petersen)` | `isomorphisms(to:).count vertexColor: G [x,o,o,o,o,o,o,o,o,o] H [o,o,o,o,o,o,o,x,o,o]` | #12 |
| IS-077 | Colours | uniform colours change nothing | `U: nx(petersen)` | `U: nx(petersen) ~map(3,4)` | `isomorphisms(to:).count vertexColor: G [0,0,0,0,0,0,0,0,0,0] H [0,0,0,0,0,0,0,0,0,0]` | #120 |
| IS-078 | Colours | distinct colours: at most one mapping | `U: K(4)` | `U: K(4)` | `isomorphisms(to:) vertexColor: G [a,b,c,d] H [d,c,b,a]` | {[3, 2, 1, 0]} |
| IS-079 | Colours | edge colours on C4: a a b b against a b a b | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `isIsomorphic(to:) edgeColor: G [a,a,b,b] H [a,b,a,b]` | false |
| IS-080 | Colours | edge colours on C4: a a b b against b a a b | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `isomorphisms(to:) edgeColor: G [a,a,b,b] H [b,a,a,b]` | {[1, 2, 3, 0], [3, 2, 1, 0]} |
| IS-081 | Colours | edge colours on a triangle: one of each | `U: C(0,1,2)` | `U: C(0,1,2)` | `isomorphisms(to:) edgeColor: G [a,b,c] H [c,a,b]` | {[1, 2, 0]} |
| IS-082 | Colours | parallel pair: colours {a, b} against {a, a} | `U: 0=1` | `U: 0=1` | `isIsomorphic(to:) edgeColor: G [a,b] H [a,a]` | false |
| IS-083 | Colours | parallel pair: colours {a, b} against {b, a} | `U: 0=1` | `U: 0=1` | `isomorphisms(to:) edgeColor: G [a,b] H [b,a]` | {[0, 1], [1, 0]} |
| IS-084 | Colours | loop colours | `U: 0-0, 0-1, 1-1` | `U: 0-0, 0-1, 1-1` | `isomorphisms(to:) edgeColor: G [a,c,b] H [b,c,a]` | {[1, 0]} |
| IS-085 | Colours | vertex and edge colours together | `U: P(0,1,2)` | `U: P(0,1,2)` | `isomorphisms(to:) vertexColor: G [r,b,r] H [r,b,r] edgeColor: G [x,y] H [y,x]` | {[2, 1, 0]} |
| IS-086 | Colours | directed: arc colours | `D: C(0,1,2)` | `D: C(0,1,2)` | `isomorphisms(to:) edgeColor: G [a,a,b] H [a,b,a]` | {[2, 0, 1]} |
| IS-087 | Subgraph isomorphism (induced) | P3 in K3: every image has the third edge | `U: P(0,1,2)` | `U: K(3)` | `isSubgraphIsomorphic(to:)` | false |
| IS-088 | Subgraph isomorphism (induced) | K2 in P4: each edge, both ways | `U: P(0,1)` | `U: P(0,1,2,3)` | `subgraphIsomorphisms(to:)` | {[0, 1], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2]} |
| IS-089 | Subgraph isomorphism (induced) | two isolated vertices in P4: non-adjacent pairs | `U: E(2)` | `U: P(0,1,2,3)` | `subgraphIsomorphisms(to:)` | {[0, 2], [0, 3], [1, 3], [2, 0], [3, 0], [3, 1]} |
| IS-090 | Subgraph isomorphism (induced) | C4 in K4: never induced | `U: C(0,1,2,3)` | `U: K(4)` | `subgraphIsomorphisms(to:).count` | #0 |
| IS-091 | Subgraph isomorphism (induced) | 2K2 in P4: the middle edge is in the way | `U: 0-1, 2-3` | `U: P(0,1,2,3)` | `subgraphIsomorphisms(to:).count` | #0 |
| IS-092 | Subgraph isomorphism (induced) | K3 in Petersen (girth 5) | `U: K(3)` | `U: nx(petersen)` | `isSubgraphIsomorphic(to:)` | false |
| IS-093 | Subgraph isomorphism (induced) | C5 in Petersen: 12 five-cycles, 10 ways each | `U: C(0,1,2,3,4)` | `U: nx(petersen)` | `subgraphIsomorphisms(to:).count` | #120 |
| IS-094 | Subgraph isomorphism (induced) | P3 in Petersen | `U: P(0,1,2)` | `U: nx(petersen)` | `subgraphIsomorphisms(to:).count` | #60 |
| IS-095 | Subgraph isomorphism (induced) | C6 in Petersen | `U: C(0,1,2,3,4,5)` | `U: nx(petersen)` | `subgraphIsomorphisms(to:).count` | #120 |
| IS-096 | Subgraph isomorphism (induced) | K4 in K6 | `U: K(4)` | `U: K(6)` | `subgraphIsomorphisms(to:).count` | #360 |
| IS-097 | Subgraph isomorphism (induced) | C4 in Q3: the six faces | `U: C(0,1,2,3)` | `U: Q(3)` | `subgraphIsomorphisms(to:).count` | #48 |
| IS-098 | Subgraph isomorphism (induced) | P4 in grid 3x3 | `U: P(0,1,2,3)` | `U: grid(3,3)` | `subgraphIsomorphisms(to:).count` | #48 |
| IS-099 | Subgraph isomorphism (induced) | claw K1,3 in grid 4x4 | `U: S(0;1..3)` | `U: grid(4,4)` | `subgraphIsomorphisms(to:).count` | #144 |
| IS-100 | Subgraph isomorphism (induced) | pattern larger than target | `U: K(3)` | `U: K(2)` | `isSubgraphIsomorphic(to:)` | false |
| IS-101 | Subgraph isomorphism (induced) | empty pattern: the empty mapping | `U:` | `U: P(0,1,2)` | `subgraphIsomorphisms(to:)` | {[]} |
| IS-102 | Subgraph isomorphism (induced) | empty pattern, empty target | `U:` | `U:` | `subgraphIsomorphisms(to:).count` | #1 |
| IS-103 | Subgraph isomorphism (induced) | a whole graph is its own induced subgraph | `U: nx(petersen)` | `U: nx(petersen)` | `subgraphIsomorphisms(to:).count` | #120 |
| IS-104 | Subgraph isomorphism (induced) | K1 into a vertex with a loop: the loop is induced | `U: [0]` | `U: 0-0, 0-1` | `subgraphIsomorphisms(to:)` | {[1]} |
| IS-105 | Subgraph isomorphism (induced) | loop pattern into a loop target | `U: 0-0` | `U: 0-0, 0-1` | `subgraphIsomorphisms(to:)` | {[0]} |
| IS-106 | Subgraph isomorphism (induced) | K2 into a parallel pair: multiplicity must be equal | `U: 0-1` | `U: 0=1` | `isSubgraphIsomorphic(to:)` | false |
| IS-107 | Subgraph isomorphism (induced) | parallel pair into a parallel pair | `U: 0=1` | `U: 0=1, 1-2` | `subgraphIsomorphisms(to:)` | {[0, 1], [1, 0]} |
| IS-108 | Subgraph isomorphism (induced) | directed: arc into a 2-cycle | `D: 0>1` | `D: 0>1, 1>0` | `isSubgraphIsomorphic(to:)` | false |
| IS-109 | Subgraph isomorphism (induced) | directed: out-path in directed C3 | `D: 0>1, 1>2` | `D: C(0,1,2)` | `isSubgraphIsomorphic(to:)` | false |
| IS-110 | Subgraph isomorphism (induced) | directed: out-path in directed C4 | `D: 0>1, 1>2` | `D: C(0,1,2,3)` | `subgraphIsomorphisms(to:).count` | #4 |
| IS-111 | Subgraph isomorphism (induced) | directed: arc in the transitive tournament on 4 | `D: 0>1` | `D: tt(4)` | `subgraphIsomorphisms(to:).count` | #6 |
| IS-112 | Subgraph isomorphism (induced) | coloured: red–blue edges in a coloured path | `U: P(0,1)` | `U: P(0,1,2,3)` | `subgraphIsomorphisms(to:) vertexColor: G [r,b] H [r,b,b,r]` | {[0, 1], [3, 2]} |
| IS-113 | Subgraph isomorphism (induced) | coloured edges: an a-edge in C4 | `U: P(0,1)` | `U: C(0,1,2,3)` | `subgraphIsomorphisms(to:) edgeColor: G [a] H [a,b,a,b]` | {[0, 1], [1, 0], [2, 3], [3, 2]} |
| IS-114 | Subgraph isomorphism (induced) | subgraphIsomorphism(to:): the unique one | `U: P(0,1,2)` | `U: [9] P(5,6,7), 9-5` | `subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]` | [9, 5, 6] |
| IS-115 | Subgraph isomorphism (induced) | subgraphIsomorphism(to:): none | `U: K(3)` | `U: nx(petersen)` | `subgraphIsomorphism(to:)` | nil |
| IS-116 | Subgraph isomorphism (induced) | random target lcg(14,30,5): P4 | `U: P(0,1,2,3)` | `U: lcg(14,30,5)` | `subgraphIsomorphisms(to:).count` | #70 |
| IS-117 | Monomorphism (non-induced) | P3 in K3 | `U: P(0,1,2)` | `U: K(3)` | `monomorphisms(to:)` | {[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]} |
| IS-118 | Monomorphism (non-induced) | two isolated vertices in P4: every ordered pair | `U: E(2)` | `U: P(0,1,2,3)` | `monomorphisms(to:).count` | #12 |
| IS-119 | Monomorphism (non-induced) | C4 in K4: three 4-cycles, 8 ways each | `U: C(0,1,2,3)` | `U: K(4)` | `monomorphisms(to:).count` | #24 |
| IS-120 | Monomorphism (non-induced) | 2K2 in P4 | `U: 0-1, 2-3` | `U: P(0,1,2,3)` | `monomorphisms(to:)` | {[0, 1, 2, 3], [0, 1, 3, 2], [1, 0, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [2, 3, 1, 0], [3, 2, 0, 1], [3, 2, 1, 0]} |
| IS-121 | Monomorphism (non-induced) | C5 in Petersen: same as induced (girth 5) | `U: C(0,1,2,3,4)` | `U: nx(petersen)` | `monomorphisms(to:).count` | #120 |
| IS-122 | Monomorphism (non-induced) | C4 in K3,3 | `U: C(0,1,2,3)` | `U: KB(0..2;3..5)` | `monomorphisms(to:).count` | #72 |
| IS-123 | Monomorphism (non-induced) | Hamiltonian cycles: C8 in Q3 | `U: C(0,1,2,3,4,5,6,7)` | `U: Q(3)` | `monomorphisms(to:).count` | #96 |
| IS-124 | Monomorphism (non-induced) | Hamiltonian paths: P10 in Petersen | `U: P(0,1,2,3,4,5,6,7,8,9)` | `U: nx(petersen)` | `monomorphisms(to:).count` | #240 |
| IS-125 | Monomorphism (non-induced) | spanning: C10 in Petersen (not Hamiltonian) | `U: C(0,1,2,3,4,5,6,7,8,9)` | `U: nx(petersen)` | `isMonomorphic(to:)` | false |
| IS-126 | Monomorphism (non-induced) | perfect matchings: 3K2 in K3,3 | `U: 0-1, 2-3, 4-5` | `U: KB(0..2;3..5)` | `monomorphisms(to:).count` | #288 |
| IS-127 | Monomorphism (non-induced) | K4 in K6 | `U: K(4)` | `U: K(6)` | `monomorphisms(to:).count` | #360 |
| IS-128 | Monomorphism (non-induced) | K4 in grid | `U: K(4)` | `U: grid(3,3)` | `isMonomorphic(to:)` | false |
| IS-129 | Monomorphism (non-induced) | empty pattern | `U:` | `U: K(3)` | `monomorphisms(to:)` | {[]} |
| IS-130 | Monomorphism (non-induced) | pattern larger than target | `U: E(3)` | `U: K(2)` | `isMonomorphic(to:)` | false |
| IS-131 | Monomorphism (non-induced) | K1 into a loop vertex: allowed | `U: [0]` | `U: [0] 0-0` | `monomorphisms(to:)` | {[0]} |
| IS-132 | Monomorphism (non-induced) | loop pattern into a vertex without a loop | `U: 0-0` | `U: 0-1` | `isMonomorphic(to:)` | false |
| IS-133 | Monomorphism (non-induced) | K2 into a parallel pair: one copy is enough | `U: 0-1` | `U: 0=1` | `monomorphisms(to:)` | {[0, 1], [1, 0]} |
| IS-134 | Monomorphism (non-induced) | parallel pair into a single edge | `U: 0=1` | `U: 0-1` | `isMonomorphic(to:)` | false |
| IS-135 | Monomorphism (non-induced) | triple edge into a double edge | `U: 0=1, 0-1` | `U: 0=1` | `isMonomorphic(to:)` | false |
| IS-136 | Monomorphism (non-induced) | double edge into a triple edge | `U: 0=1` | `U: 0=1, 0-1` | `monomorphisms(to:)` | {[0, 1], [1, 0]} |
| IS-137 | Monomorphism (non-induced) | directed: arc into a 2-cycle | `D: 0>1` | `D: 0>1, 1>0` | `monomorphisms(to:)` | {[0, 1], [1, 0]} |
| IS-138 | Monomorphism (non-induced) | directed: out-path in directed C3 | `D: 0>1, 1>2` | `D: C(0,1,2)` | `monomorphisms(to:)` | {[0, 1, 2], [1, 2, 0], [2, 0, 1]} |
| IS-139 | Monomorphism (non-induced) | directed: 2-cycle into the transitive tournament | `D: 0>1, 1>0` | `D: tt(4)` | `isMonomorphic(to:)` | false |
| IS-140 | Monomorphism (non-induced) | directed: directed triangles in tpaley(7) | `D: C(0,1,2)` | `D: tpaley(7)` | `monomorphisms(to:).count` | #42 |
| IS-141 | Monomorphism (non-induced) | coloured edges: multiset containment | `U: 0=1` | `U: 0=1, 0-1` | `monomorphisms(to:) edgeColor: G [a,b] H [a,a,b]` | {[0, 1], [1, 0]} |
| IS-142 | Monomorphism (non-induced) | coloured edges: a colour missing | `U: 0=1` | `U: 0=1, 0-1` | `isMonomorphic(to:) edgeColor: G [a,b] H [a,a,c]` | false |
| IS-143 | Monomorphism (non-induced) | coloured vertices | `U: P(0,1)` | `U: K(3)` | `monomorphisms(to:) vertexColor: G [r,r] H [r,b,r]` | {[0, 2], [2, 0]} |
| IS-144 | Monomorphism (non-induced) | monomorphism(to:): none | `U: C(0,1,2,3)` | `U: nx(petersen)` | `monomorphism(to:)` | nil |
| IS-145 | Monomorphism (non-induced) | monomorphism(to:): the unique one | `U: P(0,1,2)` | `U: K(3)` | `monomorphism(to:) vertexColor: G [a,b,c] H [c,a,b]` | [1, 2, 0] |
| IS-146 | Monomorphism (non-induced) | random target lcg(14,30,5): C4 | `U: C(0,1,2,3)` | `U: lcg(14,30,5)` | `monomorphisms(to:).count` | #120 |
| IS-147 | Weisfeiler–Leman | C6 against 2C3: never distinguished | `U: C(0,1,2,3,4,5)` | `U: C(0,1,2), C(3,4,5)` | `weisfeilerLehmanGraphHash(iterations: 3)` | equal |
| IS-148 | Weisfeiler–Leman | Shrikhande against rook(4): never distinguished | `U: shrikhande` | `U: rook(4)` | `weisfeilerLehmanGraphHash(iterations: 3)` | equal |
| IS-149 | Weisfeiler–Leman | CFI against twisted CFI: never distinguished | `U: cfi(K(4))` | `U: cfi~(K(4))` | `weisfeilerLehmanGraphHash(iterations: 5)` | equal |
| IS-150 | Weisfeiler–Leman | isomorphic graphs: equal | `U: nx(petersen)` | `U: nx(petersen) ~map(3,4)` | `weisfeilerLehmanGraphHash(iterations: 3)` | equal |
| IS-151 | Weisfeiler–Leman | P4 against the star: degrees differ in round 1 | `U: P(0,1,2,3)` | `U: S(0;1..3)` | `weisfeilerLehmanGraphHash(iterations: 1)` | different |
| IS-152 | Weisfeiler–Leman | zero rounds: only the vertex count | `U: P(0,1,2,3)` | `U: S(0;1..3)` | `weisfeilerLehmanGraphHash(iterations: 0)` | equal |
| IS-153 | Weisfeiler–Leman | zero rounds, different vertex counts | `U: E(3)` | `U: E(4)` | `weisfeilerLehmanGraphHash(iterations: 0)` | different |
| IS-154 | Weisfeiler–Leman | two trees, one degree sequence: equal after 1 round | `U: P(0,1,2,3,4), 1-5` | `U: P(0,1,2,3,4), 2-5` | `weisfeilerLehmanGraphHash(iterations: 1)` | equal |
| IS-155 | Weisfeiler–Leman | two trees, one degree sequence: different after 2 | `U: P(0,1,2,3,4), 1-5` | `U: P(0,1,2,3,4), 2-5` | `weisfeilerLehmanGraphHash(iterations: 2)` | different |
| IS-156 | Weisfeiler–Leman | decalin against bicyclopentyl (NetworkX docstring) | `U: P(0,1,2,3,4,5,6,7,8,9), 0-5, 4-9` | `U: C(0,1,2,3,4), C(5,6,7,8,9), 0-5` | `weisfeilerLehmanGraphHash(iterations: 3)` | equal |
| IS-157 | Weisfeiler–Leman | decalin against bicyclopentyl with element colours | `U: P(0,1,2,3,4,5,6,7,8,9), 0-5, 4-9` | `U: C(0,1,2,3,4), C(5,6,7,8,9), 0-5` | `weisfeilerLehmanGraphHash(iterations: 3) edgeColor: G [s,s,s,s,s,s,s,s,s,d,s] H [s,s,s,s,s,s,s,s,s,s,d]` | different |
| IS-158 | Weisfeiler–Leman | vertex colours separate C4 colourings | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `weisfeilerLehmanGraphHash(iterations: 2) vertexColor: G [r,r,b,b] H [r,b,r,b]` | different |
| IS-159 | Weisfeiler–Leman | edge colours separate C4 colourings | `U: C(0,1,2,3)` | `U: C(0,1,2,3)` | `weisfeilerLehmanGraphHash(iterations: 2) edgeColor: G [a,a,b,b] H [a,b,a,b]` | different |
| IS-160 | Weisfeiler–Leman | parallel pair against P4: degrees equal, neighbours not | `U: 0=1, 2-3` | `U: P(0,1,2,3)` | `weisfeilerLehmanGraphHash(iterations: 2)` | different |
| IS-161 | Weisfeiler–Leman | a loop counts as two edge ends | `U: 0-0, 1-2` | `U: P(0,1,2)` | `weisfeilerLehmanGraphHash(iterations: 1)` | equal |
| IS-162 | Weisfeiler–Leman | a loop: degrees equal, neighbours not | `U: 0-0, 1-2` | `U: P(0,1,2)` | `weisfeilerLehmanGraphHash(iterations: 2)` | different |
| IS-163 | Weisfeiler–Leman | directed: out-path against in-star | `D: 0>1, 1>2` | `D: 0>1, 2>1` | `weisfeilerLehmanGraphHash(iterations: 1)` | different |
| IS-164 | Weisfeiler–Leman | directed: C3 against its reverse | `D: C(0,1,2)` | `D: C(2,1,0)` | `weisfeilerLehmanGraphHash(iterations: 3)` | equal |
| IS-165 | Weisfeiler–Leman | negative iterations | `U: K(2)` | `U: K(2)` | `weisfeilerLehmanGraphHash(iterations: -1)` | **trap** (iterations must be at least 0) |
| IS-166 | Weisfeiler–Leman | P5 partitions | `U: P(0,1,2,3,4)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 3)` | r1: {0,4} {1,2,3}; r2: {0,4} {1,3} {2}; r3: {0,4} {1,3} {2} |
| IS-167 | Weisfeiler–Leman | tree partitions | `U: P(0,1,2,3,4), 1-5` | — | `weisfeilerLehmanSubgraphHashes(iterations: 3)` | r1: {0,4,5} {1} {2,3}; r2: {0,5} {1} {2} {3} {4}; r3: {0,5} {1} {2} {3} {4} |
| IS-168 | Weisfeiler–Leman | Petersen: one class from round 1 on | `U: nx(petersen)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 2)` | r1: {0,1,2,3,4,5,6,7,8,9}; r2: {0,1,2,3,4,5,6,7,8,9} |
| IS-169 | Weisfeiler–Leman | Frucht: refinement stops short of the orbits | `U: nx(frucht)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 4)` | r1: {0,1,2,3,4,5,6,7,8,9,10,11}; r2: {0,1,2,3,4,5,6,7,8,9,10,11}; r3: {0,1,2,3,4,5,6,7,8,9,10,11}; r4: {0,1,2,3,4,5,6,7,8,9,10,11} |
| IS-170 | Weisfeiler–Leman | karate club, three rounds | `U: nx(karate_club)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 3)` | r1: {0} {1} {2} {3,31} {4,10,19,24,25,28} {5,6,7,27,29,30} {8,13,23} {9,12,14,15,16,17,18,20,21,22,26} {11} {32} {33}; r2: {0} {1} {2} {3} {4,10} {5,6} {7} {8} {9} {11} {12} {13} {14,15,18,20,22} {16} {17,21} {19} {23} {24} {25} {26} {27} {28} {29} {30} {31} {32} {33}; r3: {0} {1} {2} {3} {4,10} {5,6} {7} {8} {9} {11} {12} {13} {14,15,18,20,22} {16} {17,21} {19} {23} {24} {25} {26} {27} {28} {29} {30} {31} {32} {33} |
| IS-171 | Weisfeiler–Leman | vertex colours start the refinement | `U: P(0,1,2,3,4)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 2) vertexColor: G [a,b,a,a,a]` | r1: {0} {1} {2} {3} {4}; r2: {0} {1} {2} {3} {4} |
| IS-172 | Weisfeiler–Leman | edge colours | `U: C(0,1,2,3)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 2) edgeColor: G [a,a,b,b]` | r1: {0,2} {1} {3}; r2: {0,2} {1} {3} |
| IS-173 | Weisfeiler–Leman | directed: in- and out-neighbours both count | `D: 0>1, 2>1, 1>3` | — | `weisfeilerLehmanSubgraphHashes(iterations: 2)` | r1: {0,2} {1} {3}; r2: {0,2} {1} {3} |
| IS-174 | Weisfeiler–Leman | loops and parallel edges | `U: 0-0, 0-1, 1=2, 2-3` | — | `weisfeilerLehmanSubgraphHashes(iterations: 2)` | r1: {0,1,2} {3}; r2: {0,1} {2} {3} |
| IS-175 | Weisfeiler–Leman | zero rounds: no hashes | `U: P(0,1,2)` | — | `weisfeilerLehmanSubgraphHashes(iterations: 0)` | (no rounds) |
| IS-176 | Weisfeiler–Leman | negative iterations | `U: P(0,1,2)` | — | `weisfeilerLehmanSubgraphHashes(iterations: -1)` | **trap** (iterations must be at least 0) |
| IS-177 | Isomorphism value | image(of:) a pattern vertex | `U: [5, 9, 7] 5-9` | `U: [2, 0, 4] 4-2` | `image(of: 7) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` | 0 |
| IS-178 | Isomorphism value | image(of:) a vertex not in the pattern | `U: [5, 9, 7] 5-9` | `U: [2, 0, 4] 4-2` | `image(of: 3) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` | **trap** (3 is not a vertex of the pattern) |
| IS-179 | Isomorphism value | preimage(of:) a target vertex | `U: [5, 9, 7] 5-9` | `U: [2, 0, 4] 4-2` | `preimage(of: 2) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` | 5 |
| IS-180 | Isomorphism value | preimage(of:) a target vertex outside the image | `U: P(0,1,2)` | `U: [9] P(5,6,7), 9-5` | `preimage(of: 7) after subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]` | nil |
| IS-181 | Isomorphism value | preimage(of:) a vertex not in the target | `U: P(0,1,2)` | `U: [9] P(5,6,7), 9-5` | `preimage(of: 3) after subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]` | **trap** (3 is not a vertex of the target) |
| IS-182 | Phase 2: automorphismGroup | empty graph: order | `U:` | — | `automorphismGroup().order` | 1 |
| IS-183 | Phase 2: automorphismGroup | empty graph: orbits | `U:` | — | `automorphismGroup().orbits` | (none) |
| IS-184 | Phase 2: automorphismGroup | K1: order | `U: [0]` | — | `automorphismGroup().order` | 1 |
| IS-185 | Phase 2: automorphismGroup | K1: orbits | `U: [0]` | — | `automorphismGroup().orbits` | {0} |
| IS-186 | Phase 2: automorphismGroup | P5: order | `U: P(0,1,2,3,4)` | — | `automorphismGroup().order` | 2 |
| IS-187 | Phase 2: automorphismGroup | P5: orbits | `U: P(0,1,2,3,4)` | — | `automorphismGroup().orbits` | {0,4} {1,3} {2} |
| IS-188 | Phase 2: automorphismGroup | K2,3: order | `U: KB(0..1;2..4)` | — | `automorphismGroup().order` | 12 |
| IS-189 | Phase 2: automorphismGroup | K2,3: orbits | `U: KB(0..1;2..4)` | — | `automorphismGroup().orbits` | {0,1} {2,3,4} |
| IS-190 | Phase 2: automorphismGroup | K3,3: order | `U: KB(0..2;3..5)` | — | `automorphismGroup().order` | 72 |
| IS-191 | Phase 2: automorphismGroup | K3,3: orbits | `U: KB(0..2;3..5)` | — | `automorphismGroup().orbits` | {0,3,4,5,1,2} |
| IS-192 | Phase 2: automorphismGroup | Petersen: order | `U: nx(petersen)` | — | `automorphismGroup().order` | 120 |
| IS-193 | Phase 2: automorphismGroup | Petersen: orbits | `U: nx(petersen)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9} |
| IS-194 | Phase 2: automorphismGroup | Frucht: order | `U: nx(frucht)` | — | `automorphismGroup().order` | 1 |
| IS-195 | Phase 2: automorphismGroup | Frucht: orbits | `U: nx(frucht)` | — | `automorphismGroup().orbits` | {0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10} {11} |
| IS-196 | Phase 2: automorphismGroup | Heawood: order | `U: nx(heawood)` | — | `automorphismGroup().order` | 336 |
| IS-197 | Phase 2: automorphismGroup | Heawood: orbits | `U: nx(heawood)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9,10,11,12,13} |
| IS-198 | Phase 2: automorphismGroup | Q3: order | `U: Q(3)` | — | `automorphismGroup().order` | 48 |
| IS-199 | Phase 2: automorphismGroup | Q3: orbits | `U: Q(3)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7} |
| IS-200 | Phase 2: automorphismGroup | Q5: order | `U: Q(5)` | — | `automorphismGroup().order` | 3840 |
| IS-201 | Phase 2: automorphismGroup | Q5: orbits | `U: Q(5)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31} |
| IS-202 | Phase 2: automorphismGroup | Shrikhande: order | `U: shrikhande` | — | `automorphismGroup().order` | 192 |
| IS-203 | Phase 2: automorphismGroup | Shrikhande: orbits | `U: shrikhande` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15} |
| IS-204 | Phase 2: automorphismGroup | rook(4): order | `U: rook(4)` | — | `automorphismGroup().order` | 1152 |
| IS-205 | Phase 2: automorphismGroup | rook(4): orbits | `U: rook(4)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15} |
| IS-206 | Phase 2: automorphismGroup | Paley(13): order | `U: paley(13)` | — | `automorphismGroup().order` | 78 |
| IS-207 | Phase 2: automorphismGroup | Paley(13): orbits | `U: paley(13)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9,10,11,12} |
| IS-208 | Phase 2: automorphismGroup | Paley(29): order | `U: paley(29)` | — | `automorphismGroup().order` | 406 |
| IS-209 | Phase 2: automorphismGroup | Paley(29): orbits | `U: paley(29)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28} |
| IS-210 | Phase 2: automorphismGroup | karate club: order | `U: nx(karate_club)` | — | `automorphismGroup().order` | 480 |
| IS-211 | Phase 2: automorphismGroup | karate club: orbits | `U: nx(karate_club)` | — | `automorphismGroup().orbits` | {0} {1} {2} {3} {4,10} {5,6} {7} {8} {9} {11} {12} {13} {14,15,18,20,22} {16} {17,21} {19} {23} {24} {25} {26} {27} {28} {29} {30} {31} {32} {33} |
| IS-212 | Phase 2: automorphismGroup | Tutte graph: order | `U: nx(tutte)` | — | `automorphismGroup().order` | 3 |
| IS-213 | Phase 2: automorphismGroup | Tutte graph: orbits | `U: nx(tutte)` | — | `automorphismGroup().orbits` | {0} {1,2,3} {4,11,19} {5,12,20} {6,13,21} {7,15,23} {8,16,24} {9,17,25} {10,18,26} {14,22,27} {28,34,40} {29,35,41} {30,36,42} {31,37,43} {33,39,45} {38,44,32} |
| IS-214 | Phase 2: automorphismGroup | Hoffman–Singleton: order | `U: nx(hoffman_singleton)` | — | `automorphismGroup().order` | 252000 |
| IS-215 | Phase 2: automorphismGroup | Les Misérables: order | `U: nx(les_miserables)` | — | `automorphismGroup().order` | 3344302080000 |
| IS-216 | Phase 2: automorphismGroup | 25 isolated vertices: order | `U: E(25)` | — | `automorphismGroup().order` | 15511210043330985984000000 |
| IS-217 | Phase 2: automorphismGroup | CFI over K4: order | `U: cfi(K(4))` | — | `automorphismGroup().order` | 192 |
| IS-218 | Phase 2: automorphismGroup | CFI over K4: orbits | `U: cfi(K(4))` | — | `automorphismGroup().orbits` | {0,1,2,3,10,11,12,13,20,21,22,23,30,31,32,33} {4,5,6,7,8,9,14,15,16,17,18,19,24,25,26,27,28,29,34,35,36,37,38,39} |
| IS-219 | Phase 2: automorphismGroup | twisted CFI over K4: order | `U: cfi~(K(4))` | — | `automorphismGroup().order` | 192 |
| IS-220 | Phase 2: automorphismGroup | twisted CFI over K4: orbits | `U: cfi~(K(4))` | — | `automorphismGroup().orbits` | {0,1,2,3,10,11,12,13,20,21,22,23,30,31,32,33} {4,5,6,7,8,9,14,15,16,17,18,19,24,25,26,27,28,29,34,35,36,37,38,39} |
| IS-221 | Phase 2: automorphismGroup | directed C3: order | `D: C(0,1,2)` | — | `automorphismGroup().order` | 3 |
| IS-222 | Phase 2: automorphismGroup | directed C3: orbits | `D: C(0,1,2)` | — | `automorphismGroup().orbits` | {0,1,2} |
| IS-223 | Phase 2: automorphismGroup | Paley tournament 7: order | `D: tpaley(7)` | — | `automorphismGroup().order` | 21 |
| IS-224 | Phase 2: automorphismGroup | Paley tournament 7: orbits | `D: tpaley(7)` | — | `automorphismGroup().orbits` | {0,1,2,3,4,5,6} |
| IS-225 | Phase 2: automorphismGroup | transitive tournament 5: order | `D: tt(5)` | — | `automorphismGroup().order` | 1 |
| IS-226 | Phase 2: automorphismGroup | transitive tournament 5: orbits | `D: tt(5)` | — | `automorphismGroup().orbits` | {0} {1} {2} {3} {4} |
| IS-227 | Phase 2: automorphismGroup | Les Misérables: orbits | `U: nx(les_miserables)` | — | `automorphismGroup().orbits` | {Napoleon,CountessDeLo,Geborand,Champtercier,Cravatte,Count,OldMan} {Myriel} {MlleBaptistine,MmeMagloire} {Valjean} {Labarre,MmeDeR,Isabeau,Gervais,Scaufflaire} {Marguerite} {Listolier,Fameuil,Blacheville,Favourite,Dahlia,Zephine} {Tholomyes} {Fantine} {MmeThenardier} {Thenardier} {Cosette} {Javert} {Fauchelevent} {Bamatabois} {Perpetue} {Simplice} {Woman1} {Judge,Champmathieu,Brevet,Chenildieu,Cochepaille} {Pontmercy} {Boulatruelle} {Eponine} {Anzelma} {Woman2,Toussaint} {MotherInnocent} {Gribier} {MmeBurgon} {Jondrette} {Gavroche} {Gillenormand} {Magnon} {MlleGillenormand} {MmePontmercy} {MlleVaubois} {LtGillenormand} {Marius} {BaronessT} {Mabeuf} {Enjolras} {Combeferre,Feuilly} {Prouvaire} {Courfeyrac} {Bahorel,Joly} {Bossuet} {Grantaire} {MotherPlutarch} {Gueulemer,Babet} {Claquesous} {Montparnasse} {Child1,Child2} {Brujon} {MmeHucheloup} |
| IS-228 | Phase 2: automorphismGroup | Petersen, one vertex coloured: order | `U: nx(petersen)` | — | `automorphismGroup().order vertexColor: G [x,o,o,o,o,o,o,o,o,o]` | 12 |
| IS-229 | Phase 2: automorphismGroup | Petersen, one vertex coloured: orbits | `U: nx(petersen)` | — | `automorphismGroup().orbits vertexColor: G [x,o,o,o,o,o,o,o,o,o]` | {0} {1,4,5} {2,3,6,7,8,9} |
| IS-230 | Phase 2: automorphismGroup | C4 with edge colours a a b b: order | `U: C(0,1,2,3)` | — | `automorphismGroup().order edgeColor: G [a,a,b,b]` | 2 |
| IS-231 | Phase 2: automorphismGroup | doubled edge and a pendant: order | `U: 0=1, 1-2` | — | `automorphismGroup().order` | 1 |
| IS-232 | Phase 2: automorphismGroup | loops break symmetry: orbits | `U: 0-0, C(0,1,2,3)` | — | `automorphismGroup().orbits` | {0} {1,3} {2} |
| IS-233 | Phase 2: automorphismGroup | bouquet of three loops: order | `U: 0-0, 0-0, 0-0` | — | `automorphismGroup().order` | 1 |

233 rows.
