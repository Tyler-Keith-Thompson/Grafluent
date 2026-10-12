# Planarity: case catalog (PL-001 – PL-188, 188 rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 python3 Tests/Catalogs/Planarity/ref.py`; `--write` regenerates this file,
`--stress` adds random multigraphs). Every row is certified by the model in api.md, not by a
library's word: a planar answer by a rotation system over every edge that satisfies Euler's
formula, a non-planar one by a Kuratowski subgraph checked to be a subdivision of K₅ or K₃,₃.
Rows with at most 20,000 rotation systems are also decided by enumerating all of them, which
also decides whether the embedding, the faces and the face lengths are unique; larger rows use
Whitney's theorem (3-connected, after suppressing degree-2 vertices), with the connectivity from
NetworkX and python-igraph, which must agree. Rows whose blocks have at most 16 edges list
every Kuratowski subgraph (each lies in one block), so the witness and its kind are pinned exactly
where they are unique; larger blocks that are themselves a subdivision are unique too. NetworkX 3.7's
`check_planarity` must agree on every row. python-igraph 1.0.0 has no planarity test.

## Notation

**Graph**: `U:` undirected, `D:` directed (the rows call `graph.undirected`: each arc is an
edge). An optional vertex list in brackets comes first, then edges in **position order**.
`vertices` is the listed vertices, then the vertices of generators, then endpoints by first
appearance. Vertices are `Int`s.

| Token | Edges |
|---|---|
| `u-v`, `u>v`, `u=v` | one edge (`u-u` a self-loop); one arc; two parallel edges u–v |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | vertices 0..<n (or a..b) listed, every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `E(n)` | vertices 0..<n, no edges |
| `grid(r,c)` | vertices `i*c + j` listed; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: vertices 0..<2^d listed; for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `tt(k)` | the transitive tournament: vertices 0..<k listed; i>j for i < j, lexicographic |
| `nx(name)`, `nx(name,k)` | `networkx.<name>_graph(k)`: its `nodes` listed, then `edges()` in NetworkX's order |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `tri(n,s)` | stacked triangulation: vertices 0..<n listed; edges 0-1, 0-2, 1-2 and faces [(0,1,2), (0,1,2)]; for k = 3..<n, face i = LCG(s) mod (face count) = (a,b,c) gets edges a-k, b-k, c-k and becomes (a,b,k), then (b,c,k) and (a,c,k) are appended. Maximal planar, 3-connected |
| `sd(H)` | H (vertices 0..<n_H) with every edge subdivided: H's `vertices` listed, then one new vertex n_H + p per edge p; edge p = (a, b) becomes a–(n_H + p), (n_H + p)–b |
| `a..b` | every integer from a to b inclusive |

**Op** is the call on the graph. `planarEmbedding()!.x` calls `x` on the (non-`nil`)
embedding. `findKuratowskiSubgraph()` is the witness; `isPlanar` and `isOuterplanar` are
properties.

**Expected.** `faceCount` is pinned on every planar row (Euler: Σ (2 − n_c + m_c) over the
components with an edge). Face lengths are written as a multiset `{4×6}` (six faces of length 4)
and pinned only where every planar embedding has the same ones; "unique up to mirror image" marks
rows whose embedding is unique, where the faces, the clockwise orders and `face(from:alongEdgeAt:)`
are pinned as "A or B (mirror image)": the test accepts either, consistently for the whole
embedding. A clockwise order starts at the first edge of `incidentEdges(of:)`. A face is written
as a cycle of vertices from its least rotation; `face(from:alongEdgeAt:)` is the closed walk from
the given vertex. A Kuratowski subgraph is pinned (`edges` ascending, `branchVertices`) only when
it is the only one; otherwise `some … (one of #N)` says what the test checks: a valid subdivision,
and its kind where only one kind exists. `**trap**` rows are preconditions.


| ID | Group | Case | Graph | Op | Expected |
|---|---|---|---|---|---|
| PL-001 | Test | empty graph | `U:` | `isPlanar` | true |
| PL-002 | Test | one vertex | `U: [0]` | `isPlanar` | true |
| PL-003 | Test | isolated vertices | `U: E(5)` | `isPlanar` | true |
| PL-004 | Test | one edge | `U: 0-1` | `isPlanar` | true |
| PL-005 | Test | K4 | `U: K(4)` | `isPlanar` | true |
| PL-006 | Test | K5 | `U: K(5)` | `isPlanar` | false |
| PL-007 | Test | K5 minus an edge | `U: [0..4] 0-1, 0-2, 0-3, 0-4, 1-2, 1-3, 1-4, 2-3, 2-4` | `isPlanar` | true |
| PL-008 | Test | K3,3 | `U: KB(0..2;3..5)` | `isPlanar` | false |
| PL-009 | Test | K3,3 minus an edge | `U: 0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4` | `isPlanar` | true |
| PL-010 | Test | K2,5 | `U: KB(0..1;2..6)` | `isPlanar` | true |
| PL-011 | Test | K3,5 contains K3,3 | `U: KB(0..2;3..7)` | `isPlanar` | false |
| PL-012 | Test | K6 | `U: K(6)` | `isPlanar` | false |
| PL-013 | Test | K8: more than 3n - 6 edges | `U: K(8)` | `isPlanar` | false |
| PL-014 | Test | K4,4 | `U: KB(0..3;4..7)` | `isPlanar` | false |
| PL-015 | Test | Petersen graph | `U: nx(petersen)` | `isPlanar` | false |
| PL-016 | Test | dodecahedron | `U: nx(dodecahedral)` | `isPlanar` | true |
| PL-017 | Test | icosahedron | `U: nx(icosahedral)` | `isPlanar` | true |
| PL-018 | Test | octahedron | `U: nx(octahedral)` | `isPlanar` | true |
| PL-019 | Test | cube Q3 | `U: Q(3)` | `isPlanar` | true |
| PL-020 | Test | hypercube Q4 | `U: Q(4)` | `isPlanar` | false |
| PL-021 | Test | Heawood graph | `U: nx(heawood)` | `isPlanar` | false |
| PL-022 | Test | Desargues graph | `U: nx(desargues)` | `isPlanar` | false |
| PL-023 | Test | Möbius–Kantor graph | `U: nx(moebius_kantor)` | `isPlanar` | false |
| PL-024 | Test | Pappus graph | `U: nx(pappus)` | `isPlanar` | false |
| PL-025 | Test | Frucht graph | `U: nx(frucht)` | `isPlanar` | true |
| PL-026 | Test | Tutte graph | `U: nx(tutte)` | `isPlanar` | true |
| PL-027 | Test | truncated tetrahedron | `U: nx(truncated_tetrahedron)` | `isPlanar` | true |
| PL-028 | Test | truncated cube | `U: nx(truncated_cube)` | `isPlanar` | true |
| PL-029 | Test | Chvátal graph | `U: nx(chvatal)` | `isPlanar` | false |
| PL-030 | Test | house with a cross | `U: nx(house_x)` | `isPlanar` | true |
| PL-031 | Test | Wagner graph (Möbius ladder M8) | `U: C(0..7), 0-4, 1-5, 2-6, 3-7` | `isPlanar` | false |
| PL-032 | Test | wheel W7 | `U: nx(wheel,7)` | `isPlanar` | true |
| PL-033 | Test | prism C5 × K2 | `U: nx(circular_ladder,5)` | `isPlanar` | true |
| PL-034 | Test | grid 4 × 5 | `U: grid(4,5)` | `isPlanar` | true |
| PL-035 | Test | K5 with every edge subdivided | `U: sd(K(5))` | `isPlanar` | false |
| PL-036 | Test | K3,3 with every edge subdivided | `U: sd(KB(0..2;3..5))` | `isPlanar` | false |
| PL-037 | Test | path | `U: P(0..9)` | `isPlanar` | true |
| PL-038 | Test | cycle | `U: C(0..9)` | `isPlanar` | true |
| PL-039 | Test | star | `U: S(0;1..20)` | `isPlanar` | true |
| PL-040 | Test | stacked triangulation (maximal planar) | `U: tri(30,1)` | `isPlanar` | true |
| PL-041 | Test | maximal planar plus one edge | `U: tri(30,1), 3-4` | `isPlanar` | false |
| PL-042 | Test | K4 and a disjoint K4 | `U: K(4), K(4..7)` | `isPlanar` | true |
| PL-043 | Test | K4 and a disjoint K5 | `U: K(4), K(4..8)` | `isPlanar` | false |
| PL-044 | Test | K5 with a pendant path | `U: K(5), 4-5, 5-6` | `isPlanar` | false |
| PL-045 | Test | two K5s sharing a vertex | `U: K(5), K(4..8)` | `isPlanar` | false |
| PL-046 | Test | chain of K4 blocks | `U: K(4), K(3..6), K(6..9)` | `isPlanar` | true |
| PL-047 | Test | random sparse graph | `U: lcg(30,45,3)` | `isPlanar` | false |
| PL-048 | Test | random graph, average degree 4 | `U: lcg(30,60,7)` | `isPlanar` | false |
| PL-049 | Inputs | one self-loop | `U: 0-0` | `isPlanar` | true |
| PL-050 | Inputs | two loops and an edge | `U: 0-0, 0-0, 0-1` | `isPlanar` | true |
| PL-051 | Inputs | four parallel edges | `U: 0=1, 0=1` | `isPlanar` | true |
| PL-052 | Inputs | K5 with a loop at every vertex | `U: K(5), 0-0, 1-1, 2-2, 3-3, 4-4` | `isPlanar` | false |
| PL-053 | Inputs | K3,3 with every edge doubled | `U: 0=3, 0=4, 0=5, 1=3, 1=4, 1=5, 2=3, 2=4, 2=5` | `isPlanar` | false |
| PL-054 | Inputs | K4 with a loop and a parallel pair | `U: K(4), 0-0, 1=2` | `isPlanar` | true |
| PL-055 | Inputs | directed K5 (transitive tournament) | `D: tt(5)` | `undirected.isPlanar` | false |
| PL-056 | Inputs | directed K4 | `D: tt(4)` | `undirected.isPlanar` | true |
| PL-057 | Inputs | a 2-cycle: two parallel edges underneath | `D: 0>1, 1>0` | `undirected.isPlanar` | true |
| PL-058 | Inputs | directed K3,3 | `D: KB(0..2;3..5)` | `undirected.isPlanar` | false |
| PL-059 | Inputs | directed K3,3, some arcs reversed | `D: 0>3, 4>0, 0>5, 3>1, 1>4, 5>1, 2>3, 2>4, 5>2` | `undirected.isPlanar` | false |
| PL-060 | Inputs | directed: 2-cycle embedding | `D: 0>1, 1>0, 1>2` | `undirected.planarEmbedding()` | faceCount 2; face lengths {4, 2}; unique up to mirror image |
| PL-061 | Inputs | directed K5: witness | `D: tt(5)` | `undirected.findKuratowskiSubgraph()` | K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4] |
| PL-062 | Embedding | empty graph | `U:` | `planarEmbedding()` | faceCount 0; no faces |
| PL-063 | Embedding | one vertex | `U: [0]` | `planarEmbedding()` | faceCount 0; no faces |
| PL-064 | Embedding | one edge | `U: 0-1` | `planarEmbedding()` | faceCount 1; face lengths {2}; unique up to mirror image |
| PL-065 | Embedding | path | `U: P(0..3)` | `planarEmbedding()` | faceCount 1; face lengths {6}; unique up to mirror image |
| PL-066 | Embedding | star | `U: S(0;1..4)` | `planarEmbedding()` | faceCount 1; face lengths {8} |
| PL-067 | Embedding | tree | `U: 0-1, 0-2, 1-3, 1-4, 2-5` | `planarEmbedding()` | faceCount 1; face lengths {10}; unique up to mirror image |
| PL-068 | Embedding | cycle | `U: C(0..4)` | `planarEmbedding()` | faceCount 2; face lengths {5×2}; unique up to mirror image |
| PL-069 | Embedding | triangle with a pendant edge | `U: C(0..2), 0-3` | `planarEmbedding()` | faceCount 2; face lengths {5, 3}; unique up to mirror image |
| PL-070 | Embedding | bowtie: two triangles at a cut vertex | `U: C(0..2), C(0,3,4)` | `planarEmbedding()` | faceCount 3; face lengths {6, 3×2} |
| PL-071 | Embedding | diamond (K4 minus an edge) | `U: nx(diamond)` | `planarEmbedding()` | faceCount 3; face lengths {4, 3×2}; unique up to mirror image |
| PL-072 | Embedding | K4 | `U: K(4)` | `planarEmbedding()` | faceCount 4; face lengths {3×4}; unique up to mirror image |
| PL-073 | Embedding | K2,3 | `U: KB(0..1;2..4)` | `planarEmbedding()` | faceCount 3; face lengths {4×3}; unique up to mirror image |
| PL-074 | Embedding | K5 minus an edge | `U: [0..4] 0-1, 0-2, 0-3, 0-4, 1-2, 1-3, 1-4, 2-3, 2-4` | `planarEmbedding()` | faceCount 6; face lengths {3×6}; unique up to mirror image |
| PL-075 | Embedding | octahedron | `U: nx(octahedral)` | `planarEmbedding()` | faceCount 8; face lengths {3×8}; unique up to mirror image |
| PL-076 | Embedding | cube | `U: Q(3)` | `planarEmbedding()` | faceCount 6; face lengths {4×6}; unique up to mirror image |
| PL-077 | Embedding | dodecahedron | `U: nx(dodecahedral)` | `planarEmbedding()` | faceCount 12; face lengths {5×12}; unique up to mirror image |
| PL-078 | Embedding | icosahedron | `U: nx(icosahedral)` | `planarEmbedding()` | faceCount 20; face lengths {3×20}; unique up to mirror image |
| PL-079 | Embedding | wheel W6 | `U: nx(wheel,6)` | `planarEmbedding()` | faceCount 6; face lengths {5, 3×5}; unique up to mirror image |
| PL-080 | Embedding | prism C4 × K2 | `U: nx(circular_ladder,4)` | `planarEmbedding()` | faceCount 6; face lengths {4×6}; unique up to mirror image |
| PL-081 | Embedding | grid 3 × 4 | `U: grid(3,4)` | `planarEmbedding()` | faceCount 7; face lengths {10, 4×6}; unique up to mirror image |
| PL-082 | Embedding | Frucht graph | `U: nx(frucht)` | `planarEmbedding()` | faceCount 8; face lengths {7, 6, 5×2, 4, 3×3}; unique up to mirror image |
| PL-083 | Embedding | Tutte graph | `U: nx(tutte)` | `planarEmbedding()` | faceCount 25; face lengths {10×3, 9, 5×15, 4×6}; unique up to mirror image |
| PL-084 | Embedding | house with a cross | `U: nx(house_x)` | `planarEmbedding()` | faceCount 5; face lengths {4, 3×4} |
| PL-085 | Embedding | K5 subdivided: no embedding | `U: sd(K(5))` | `planarEmbedding()` | nil |
| PL-086 | Embedding | K5: no embedding | `U: K(5)` | `planarEmbedding()` | nil |
| PL-087 | Embedding | two disjoint triangles | `U: C(0..2), C(3..5)` | `planarEmbedding()` | faceCount 4; face lengths {3×4}; unique up to mirror image |
| PL-088 | Embedding | K4 and isolated vertices | `U: [9, 8] K(4)` | `planarEmbedding()` | faceCount 4; face lengths {3×4}; unique up to mirror image |
| PL-089 | Embedding | two parallel edges | `U: 0=1` | `planarEmbedding()` | faceCount 2; face lengths {2×2}; unique up to mirror image |
| PL-090 | Embedding | three parallel edges | `U: 0=1, 0-1` | `planarEmbedding()` | faceCount 3; face lengths {2×3}; unique up to mirror image |
| PL-091 | Embedding | one loop | `U: 0-0` | `planarEmbedding()` | faceCount 2; face lengths {1×2}; unique up to mirror image |
| PL-092 | Embedding | two loops at one vertex | `U: 0-0, 0-0` | `planarEmbedding()` | faceCount 3; face lengths {2, 1×2} |
| PL-093 | Embedding | loop and an edge | `U: 0-0, 0-1` | `planarEmbedding()` | faceCount 2; face lengths {3, 1}; unique up to mirror image |
| PL-094 | Embedding | triangle with a doubled edge | `U: C(0..2), 0-1` | `planarEmbedding()` | faceCount 3; face lengths {3×2, 2}; unique up to mirror image |
| PL-095 | Embedding | K4 with a loop and a parallel pair | `U: K(4), 0-0, 1=2` | `planarEmbedding()` | faceCount 7; face lengths not pinned (not unique) |
| PL-096 | Embedding | stacked triangulation | `U: tri(8,2)` | `planarEmbedding()` | faceCount 12; face lengths {3×12}; unique up to mirror image |
| PL-097 | Faces | triangle | `U: C(0..2)` | `planarEmbedding()!.faces` | {(0 1 2), (0 2 1)} |
| PL-098 | Faces | square | `U: C(0..3)` | `planarEmbedding()!.faces` | {(0 1 2 3), (0 3 2 1)} |
| PL-099 | Faces | path: one face | `U: P(0..2)` | `planarEmbedding()!.faces` | {(0 1 2 1)} |
| PL-100 | Faces | star: one face | `U: S(0;1..3)` | `planarEmbedding()!.faces` | {(0 1 0 2 0 3)}; or every face reversed (the mirror image) |
| PL-101 | Faces | K4 | `U: K(4)` | `planarEmbedding()!.faces` | {(0 1 2), (0 2 3), (0 3 1), (1 3 2)}; or every face reversed (the mirror image) |
| PL-102 | Faces | wheel W5 | `U: nx(wheel,5)` | `planarEmbedding()!.faces` | {(0 1 2), (0 2 3), (0 3 4), (0 4 1), (1 4 3 2)}; or every face reversed (the mirror image) |
| PL-103 | Faces | cube | `U: Q(3)` | `planarEmbedding()!.faces` | {(0 1 3 2), (0 2 6 4), (0 4 5 1), (1 5 7 3), (2 3 7 6), (4 6 7 5)}; or every face reversed (the mirror image) |
| PL-104 | Faces | octahedron | `U: nx(octahedral)` | `planarEmbedding()!.faces` | {(0 1 2), (0 2 4), (0 3 1), (0 4 3), (1 3 5), (1 5 2), (2 5 4), (3 4 5)}; or every face reversed (the mirror image) |
| PL-105 | Faces | prism C3 × K2 | `U: nx(circular_ladder,3)` | `planarEmbedding()!.faces` | {(0 1 2), (0 2 5 3), (0 3 4 1), (1 4 5 2), (3 5 4)}; or every face reversed (the mirror image) |
| PL-106 | Faces | stacked triangulation | `U: tri(7,4)` | `planarEmbedding()!.faces` | {(0 1 2), (0 2 6), (0 3 4), (0 4 1), (0 6 3), (1 3 2), (1 4 5), (1 5 3), (2 3 6), (3 5 4)}; or every face reversed (the mirror image) |
| PL-107 | Faces | theta graph: three paths from 0 to 1 | `U: P(0,2,1), P(0,3,1), P(0,4,1)` | `planarEmbedding()!.faces` | {(0 2 1 3), (0 3 1 4), (0 4 1 2)}; or every face reversed (the mirror image) |
| PL-108 | Rotation | K4, vertex 0 | `U: K(4)` | `planarEmbedding()!.clockwiseNeighbors(of: 0)` | [1, 3, 2] or [1, 2, 3] (mirror image) |
| PL-109 | Rotation | K4, vertex 0, edges | `U: K(4)` | `planarEmbedding()!.clockwiseIncidentEdges(of: 0)` | [0, 2, 1] or [0, 1, 2] (mirror image) |
| PL-110 | Rotation | wheel hub | `U: nx(wheel,6)` | `planarEmbedding()!.clockwiseNeighbors(of: 0)` | [1, 5, 4, 3, 2] or [1, 2, 3, 4, 5] (mirror image) |
| PL-111 | Rotation | wheel rim vertex | `U: nx(wheel,6)` | `planarEmbedding()!.clockwiseNeighbors(of: 3)` | [0, 4, 2] or [0, 2, 4] (mirror image) |
| PL-112 | Rotation | path middle | `U: P(0..2)` | `planarEmbedding()!.clockwiseNeighbors(of: 1)` | [0, 2] |
| PL-113 | Rotation | isolated vertex: empty | `U: [0..2] 0-1` | `planarEmbedding()!.clockwiseNeighbors(of: 2)` | [] |
| PL-114 | Rotation | triangle with a doubled edge, vertex 0 | `U: C(0..2), 0-1` | `planarEmbedding()!.clockwiseIncidentEdges(of: 0)` | [0, 3, 2] or [0, 2, 3] (mirror image) |
| PL-115 | Rotation | loop: its position twice | `U: 0-0` | `planarEmbedding()!.clockwiseIncidentEdges(of: 0)` | [0, 0] |
| PL-116 | Rotation | labels: vertices are not indices | `U: [7, 3, 5] 7-3, 3-5, 5-7` | `planarEmbedding()!.clockwiseNeighbors(of: 3)` | [7, 5] |
| PL-117 | Rotation | not a vertex | `U: K(4)` | `planarEmbedding()!.clockwiseNeighbors(of: 9)` | **trap** (9 is not a vertex) |
| PL-118 | Rotation | not a vertex, checked: | `U: K(4)` | `planarEmbedding()!.clockwiseNeighbors(checked: 9)` | throws VertexNotFound |
| PL-119 | Rotation | a vertex, checked: | `U: K(4)` | `planarEmbedding()!.clockwiseNeighbors(checked: 0)` | [1, 3, 2] or [1, 2, 3] (mirror image) |
| PL-120 | Rotation | K4: face right of 0 → 1 | `U: K(4)` | `planarEmbedding()!.face(from: 0, alongEdgeAt: 0)` | vertices [0, 1, 3, 0], edges [0, 4, 2]; or vertices [0, 1, 2, 0], edges [0, 3, 1] (mirror image) |
| PL-121 | Rotation | K4: face right of 1 → 0 | `U: K(4)` | `planarEmbedding()!.face(from: 1, alongEdgeAt: 0)` | vertices [1, 0, 2, 1], edges [0, 1, 3]; or vertices [1, 0, 3, 1], edges [0, 2, 4] (mirror image) |
| PL-122 | Rotation | path: the one face | `U: P(0..2)` | `planarEmbedding()!.face(from: 0, alongEdgeAt: 0)` | vertices [0, 1, 2, 1, 0], edges [0, 1, 1, 0] |
| PL-123 | Rotation | square: inner and outer | `U: C(0..3)` | `planarEmbedding()!.face(from: 0, alongEdgeAt: 0)` | vertices [0, 1, 2, 3, 0], edges [0, 1, 2, 3] |
| PL-124 | Rotation | square: the other side | `U: C(0..3)` | `planarEmbedding()!.face(from: 1, alongEdgeAt: 0)` | vertices [1, 0, 3, 2, 1], edges [0, 3, 2, 1] |
| PL-125 | Rotation | loop: the face inside | `U: 0-0` | `planarEmbedding()!.face(from: 0, alongEdgeAt: 0)` | vertices [0, 0], edges [0] |
| PL-126 | Rotation | cube: a square face | `U: Q(3)` | `planarEmbedding()!.face(from: 0, alongEdgeAt: 0)` | vertices [0, 1, 5, 4, 0], edges [0, 4, 8, 2]; or vertices [0, 1, 3, 2, 0], edges [0, 3, 5, 1] (mirror image) |
| PL-127 | Rotation | edge not at the vertex | `U: K(4)` | `planarEmbedding()!.face(from: 3, alongEdgeAt: 0)` | **trap** (edge 0 is not incident to 3) |
| PL-128 | Rotation | faceCount, isolated vertices only | `U: E(3)` | `planarEmbedding()!.faceCount` | 0 |
| PL-129 | Rotation | faceCount, forest | `U: P(0..3), P(4..6)` | `planarEmbedding()!.faceCount` | 2 |
| PL-130 | Rotation | faceCount, grid 10 × 10 | `U: grid(10,10)` | `planarEmbedding()!.faceCount` | 82 |
| PL-131 | Kuratowski | planar: nil | `U: K(4)` | `findKuratowskiSubgraph()` | nil |
| PL-132 | Kuratowski | empty: nil | `U:` | `findKuratowskiSubgraph()` | nil |
| PL-133 | Kuratowski | K5 | `U: K(5)` | `findKuratowskiSubgraph()` | K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4] |
| PL-134 | Kuratowski | K3,3 | `U: KB(0..2;3..5)` | `findKuratowskiSubgraph()` | K₃,₃: edges [0, 1, 2, 3, 4, 5, 6, 7, 8]; branch vertices [0, 1, 2, 3, 4, 5] |
| PL-135 | Kuratowski | K5 subdivided | `U: sd(K(5))` | `findKuratowskiSubgraph()` | K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]; branch vertices [0, 1, 2, 3, 4] |
| PL-136 | Kuratowski | K3,3 subdivided | `U: sd(KB(0..2;3..5))` | `findKuratowskiSubgraph()` | K₃,₃: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]; branch vertices [0, 1, 2, 3, 4, 5] |
| PL-137 | Kuratowski | K5 with a pendant path | `U: K(5), 4-5, 5-6` | `findKuratowskiSubgraph()` | K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4] |
| PL-138 | Kuratowski | K4 and a disjoint K5 | `U: K(4), K(4..8)` | `findKuratowskiSubgraph()` | K₅: edges [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; branch vertices [4, 5, 6, 7, 8] |
| PL-139 | Kuratowski | K5 with loops | `U: K(5), 0-0, 1-1, 2-2, 3-3, 4-4` | `findKuratowskiSubgraph()` | K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4] |
| PL-140 | Kuratowski | K3,3 with every edge doubled | `U: 0=3, 0=4, 0=5, 1=3, 1=4, 1=5, 2=3, 2=4, 2=5` | `findKuratowskiSubgraph()` | some K₃,₃ subdivision (not unique; the graph has no K₅ subdivision) |
| PL-141 | Kuratowski | K3,3 plus an edge inside a side | `U: KB(0..2;3..5), 0-1` | `findKuratowskiSubgraph()` | K₃,₃: edges [0, 1, 2, 3, 4, 5, 6, 7, 8]; branch vertices [0, 1, 2, 3, 4, 5] |
| PL-142 | Kuratowski | K6: both kinds | `U: K(6)` | `findKuratowskiSubgraph()` | some K₅ or K₃,₃ subdivision (one of 76; kind not pinned) |
| PL-143 | Kuratowski | K3,4 | `U: KB(0..2;3..6)` | `findKuratowskiSubgraph()` | some K₃,₃ subdivision (one of 4; the graph has no K₅ subdivision) |
| PL-144 | Kuratowski | Petersen graph | `U: nx(petersen)` | `findKuratowskiSubgraph()` | some K₃,₃ subdivision (one of 25; the graph has no K₅ subdivision) |
| PL-145 | Kuratowski | Wagner graph | `U: C(0..7), 0-4, 1-5, 2-6, 3-7` | `findKuratowskiSubgraph()` | some K₃,₃ subdivision (one of 4; the graph has no K₅ subdivision) |
| PL-146 | Kuratowski | Heawood graph | `U: nx(heawood)` | `findKuratowskiSubgraph()` | some K₃,₃ subdivision (not unique; the graph has no K₅ subdivision) |
| PL-147 | Kuratowski | K4,4 | `U: KB(0..3;4..7)` | `findKuratowskiSubgraph()` | some K₃,₃ subdivision (one of 160; the graph has no K₅ subdivision) |
| PL-148 | Kuratowski | Q4 | `U: Q(4)` | `findKuratowskiSubgraph()` | some K₅ or K₃,₃ subdivision (not unique; kind not pinned) |
| PL-149 | Kuratowski | maximal planar plus one edge | `U: tri(30,1), 3-4` | `findKuratowskiSubgraph()` | some K₅ or K₃,₃ subdivision (not unique; kind not pinned) |
| PL-150 | Kuratowski | two K5s sharing a vertex | `U: K(5), K(4..8)` | `findKuratowskiSubgraph()` | some K₅ subdivision (one of 2; the graph has no K₃,₃ subdivision) |
| PL-151 | Kuratowski | K5 with vertices out of order | `U: [4, 2, 0, 3, 1] K(5)` | `findKuratowskiSubgraph()` | K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [4, 2, 0, 3, 1] |
| PL-152 | Outerplanar | empty | `U:` | `isOuterplanar` | true |
| PL-153 | Outerplanar | one vertex | `U: [0]` | `isOuterplanar` | true |
| PL-154 | Outerplanar | triangle | `U: K(3)` | `isOuterplanar` | true |
| PL-155 | Outerplanar | K4 | `U: K(4)` | `isOuterplanar` | false |
| PL-156 | Outerplanar | K2,3 | `U: KB(0..1;2..4)` | `isOuterplanar` | false |
| PL-157 | Outerplanar | cycle | `U: C(0..5)` | `isOuterplanar` | true |
| PL-158 | Outerplanar | tree | `U: 0-1, 0-2, 1-3, 1-4, 2-5` | `isOuterplanar` | true |
| PL-159 | Outerplanar | fan: maximal outerplanar | `U: P(1..5), S(0;1..5)` | `isOuterplanar` | true |
| PL-160 | Outerplanar | wheel W5 | `U: nx(wheel,5)` | `isOuterplanar` | false |
| PL-161 | Outerplanar | diamond | `U: nx(diamond)` | `isOuterplanar` | true |
| PL-162 | Outerplanar | ladder 2 × 5 | `U: grid(2,5)` | `isOuterplanar` | true |
| PL-163 | Outerplanar | grid 3 × 3 | `U: grid(3,3)` | `isOuterplanar` | false |
| PL-164 | Outerplanar | triangle and a disjoint K4 | `U: K(3), K(3..6)` | `isOuterplanar` | false |
| PL-165 | Outerplanar | K5: not planar either | `U: K(5)` | `isOuterplanar` | false |
| PL-166 | Outerplanar | loops and parallel edges | `U: 0=1, 1-2, 2-0, 0-0` | `isOuterplanar` | true |
| PL-167 | Outerplanar | K2,3 subdivided | `U: sd(KB(0..1;2..4))` | `isOuterplanar` | false |
| PL-168 | Outerplanar | directed K4 | `D: tt(4)` | `undirected.isOuterplanar` | false |
| PL-169 | Scale | grid 30 × 30 | `U: grid(30,30)` | `isPlanar` | true |
| PL-170 | Scale | grid 30 × 30 | `U: grid(30,30)` | `planarEmbedding()` | faceCount 842; face lengths {116, 4×841}; unique up to mirror image |
| PL-171 | Scale | stacked triangulation, 1,000 vertices | `U: tri(1000,3)` | `isPlanar` | true |
| PL-172 | Scale | stacked triangulation, 1,000 vertices | `U: tri(1000,3)` | `planarEmbedding()` | faceCount 1996; face lengths {3×1996}; unique up to mirror image |
| PL-173 | Scale | stacked triangulation, 300 vertices, plus an edge | `U: tri(300,3), 5-200` | `isPlanar` | false |
| PL-174 | Scale | stacked triangulation, 300 vertices, plus an edge | `U: tri(300,3), 5-200` | `findKuratowskiSubgraph()` | some K₅ or K₃,₃ subdivision (not unique; kind not pinned) |
| PL-175 | Scale | random sparse graph, 1,000 vertices | `U: lcg(1000,1100,5)` | `isPlanar` | false |
| PL-176 | Scale | random graph, 200 vertices, 600 edges | `U: lcg(200,600,9)` | `findKuratowskiSubgraph()` | some K₅ or K₃,₃ subdivision (not unique; kind not pinned) |
| PL-177 | Scale | tree, 2,000 vertices | `U: P(0..999), S(0;1000..1999)` | `planarEmbedding()` | faceCount 1; face lengths {3998} |
| PL-178 | Phase 2: dual | K4 is self-dual | `U: K(4)` | `planarEmbedding()!.dualGraph()` | 4 vertices, 6 edges (0 loops); degrees [3, 3, 3, 3]; isomorphic to `U: K(4)` |
| PL-179 | Phase 2: dual | cube → octahedron | `U: Q(3)` | `planarEmbedding()!.dualGraph()` | 6 vertices, 12 edges (0 loops); degrees [4, 4, 4, 4, 4, 4]; isomorphic to `U: nx(octahedral)` |
| PL-180 | Phase 2: dual | octahedron → cube | `U: nx(octahedral)` | `planarEmbedding()!.dualGraph()` | 8 vertices, 12 edges (0 loops); degrees [3, 3, 3, 3, 3, 3, 3, 3]; isomorphic to `U: Q(3)` |
| PL-181 | Phase 2: dual | dodecahedron → icosahedron | `U: nx(dodecahedral)` | `planarEmbedding()!.dualGraph()` | 12 vertices, 30 edges (0 loops); degrees [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; isomorphic to `U: nx(icosahedral)` |
| PL-182 | Phase 2: dual | wheel is self-dual | `U: nx(wheel,6)` | `planarEmbedding()!.dualGraph()` | 6 vertices, 10 edges (0 loops); degrees [5, 3, 3, 3, 3, 3]; isomorphic to `U: nx(wheel,6)` |
| PL-183 | Phase 2: dual | cycle → two vertices, parallel edges | `U: C(0..4)` | `planarEmbedding()!.dualGraph()` | 2 vertices, 5 edges (0 loops); degrees [5, 5]; isomorphic to `U: 0=1, 0=1, 0-1` |
| PL-184 | Phase 2: dual | tree → one vertex with loops | `U: P(0..3)` | `planarEmbedding()!.dualGraph()` | 1 vertex, 3 edges (3 loops); degrees [6]; isomorphic to `U: 0-0, 0-0, 0-0` |
| PL-185 | Phase 2: dual | loop → one edge | `U: 0-0` | `planarEmbedding()!.dualGraph()` | 2 vertices, 1 edge (0 loops); degrees [1, 1]; isomorphic to `U: 0-1` |
| PL-186 | Phase 2: dual | two parallel edges → two parallel edges | `U: 0=1` | `planarEmbedding()!.dualGraph()` | 2 vertices, 2 edges (0 loops); degrees [2, 2]; isomorphic to `U: 0=1` |
| PL-187 | Phase 2: dual | triangle with a pendant edge | `U: C(0..2), 0-3` | `planarEmbedding()!.dualGraph()` | 2 vertices, 4 edges (1 loop); degrees [5, 3]; isomorphic to `U: 0=1, 0-1, 1-1` |
| PL-188 | Phase 2: dual | stacked triangulation → cubic | `U: tri(8,2)` | `planarEmbedding()!.dualGraph()` | 12 vertices, 18 edges (0 loops); degrees [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] |

188 rows.
