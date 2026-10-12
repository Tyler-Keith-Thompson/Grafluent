# IncidenceMatrix: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2
python3 Tests/Catalogs/IncidenceMatrix/ref.py`; `--write` regenerates this file, `--stress` adds the random
matrices and mutation sequences). Every state is checked against NetworkX 3.7 `incidence_matrix` (both
modes, parallel edges and self-loops included), XGI 0.10.2 `incidence_matrix` for hypergraph inputs and
`DiHypergraph` for oriented ones, the algebraic identities (B·Bᵀ = D + A, Bᵀ·B = 2I + A(L(G)), oriented
B·Bᵀ = L) and the `Hypergraph` / `DirectedHypergraph` laws.

Conventions:

* `IM n N; E [{…}, …]` is `IncidenceMatrix(vertexCount: N, hyperedges: E)`; `IncidenceMatrix(Pseudograph(…))`
  and `IncidenceMatrix(DirectedPseudograph(…))` convert a graph whose vertices are `0..<n`, one column per
  edge in `edges` order.
* `OIM n N; E [{s, …}→{t, …}, …]` is `OrientedIncidenceMatrix(vertexCount: N, hyperedges: E)` with `E` a
  list of `(sources:, targets:)` pairs; `OIM n N; A [s→t, …]` is `OrientedIncidenceMatrix(vertexCount: N,
  edges: A)` with `DirectedEdge`s, one source and one target per column.
* A state `N×M [r₀, r₁, …]` (`∅` for a row of a matrix with no columns) lists the rows: character `p` of
  row `v` is the cell (vertex `v`, column `p`), `1`/`0`, or for the oriented matrix the entry `+` (target
  only), `-` (source only), `0` (neither, or both); `columns [p:{…}→{…}]` lists each column's two planes.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before the
  trap are listed.
* `throws VertexNotFound` is what a `checked:` spelling throws for a vertex not in `0..<vertexCount` (README
  Principle 6), where the plain spelling traps; a throwing insert changes nothing.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| IM-001 | Construction | empty | IM n 0; E [] | 0×0 [] |
| IM-002 | Construction | vertices, no hyperedges | IM n 3; E [] | 3×0 [∅, ∅, ∅] |
| IM-003 | Construction | columns in input order; a repeated member is one bit | IM n 4; E [{2, 0}, {1, 1, 3}] | 4×2 [10, 01, 10, 01] |
| IM-004 | Construction | repeated and empty columns are kept | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] | 5×5 [10100, 10100, 11100, 01000, 00010] |
| IM-005 | Construction | a member out of range | IM n 2; E [{0, 2}] | **trap** (vertex out of range) |
| IM-006 | Construction | negative vertexCount | IM n -1; E [] | **trap** (vertexCount must not be negative) |
| IM-007 | From a graph | triangle (NetworkX) | IncidenceMatrix(Pseudograph(n 3; [0–1, 1–2, 0–2])) | 3×3 [101, 110, 011] |
| IM-008 | From a graph | parallel edges keep their own columns | IncidenceMatrix(Pseudograph(n 2; [0–1, 1–0])) | 2×2 [11, 11] |
| IM-009 | From a graph | a self-loop sets one bit (NetworkX: a zero column) | IncidenceMatrix(Pseudograph(n 2; [0–1, 1–1])) | 2×2 [10, 11] |
| IM-010 | From a graph | isolated vertex: a zero row | IncidenceMatrix(Pseudograph(n 3; [0–1])) | 3×1 [1, 1, 0] |
| IM-011 | From a graph | unoriented, from a digraph: both ends (NetworkX oriented=False) | IncidenceMatrix(DirectedPseudograph(n 3; [0→1, 2→1])) | 3×2 [10, 11, 01] |
| IM-012 | From a graph | unoriented, a directed self-loop sets one bit (NetworkX: zero) | IncidenceMatrix(DirectedPseudograph(n 2; [0→1, 1→1])) | 2×2 [10, 11] |
| IM-013 | From a graph | path P4: B·Bᵀ = D + A and Bᵀ·B = 2I + A(L(G)) | IncidenceMatrix(Pseudograph(n 4; [0–1, 1–2, 2–3])) | 4×3 [100, 110, 011, 001] |
| IM-014 | Reads | cells | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / [vertex: 2, hyperedge: 0] / [vertex: 3, hyperedge: 0] / [vertex: 4, hyperedge: 3] | true; false; true |
| IM-015 | Reads | members and sizes, ascending | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / members(ofHyperedgeAt: 0) / size(ofHyperedgeAt: 0) / members(ofHyperedgeAt: 4) / size(ofHyperedgeAt: 4) | [0, 1, 2]; 3; []; 0 |
| IM-016 | Reads | incident hyperedges and degrees, ascending | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(of: 2) / degree(of: 2) / incidentHyperedges(of: 4) / degree(of: 4) | [0, 1, 2]; 3; [3]; 1 |
| IM-017 | Reads | counts | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / vertexCount/hyperedgeCount | 5/5 |
| IM-018 | Reads | a zero row: degree 0 | IM n 6; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(of: 5) / degree(of: 5) | []; 0 |
| IM-019 | Traps | cell with a vertex out of range | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / [vertex: 5, hyperedge: 0] | **trap** (vertex out of range) |
| IM-020 | Traps | cell with a column out of range | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / [vertex: 0, hyperedge: 5] | **trap** (hyperedge position out of range) |
| IM-021 | Traps | members(ofHyperedgeAt:) out of range | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / members(ofHyperedgeAt: 5) | **trap** (hyperedge position out of range) |
| IM-022 | Traps | incidentHyperedges(of:) out of range | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(of: -1) | **trap** (vertex out of range) |
| IM-023 | Mutation | appendVertex adds a zero row | IM n 2; E [{0, 1}] / appendVertex() / degree(of: 2) | 2; 0 ⇒ 3×1 [1, 1, 0] |
| IM-024 | Mutation | insert(hyperedge:) appends a column, past 64 columns too | IM n 2; E [{0} × 64] / insert(hyperedge: [0, 1]) / incidentHyperedges(of: 1) / size(ofHyperedgeAt: 64) | 64; [64]; 2 |
| IM-025 | Mutation | insert(hyperedge:) of the empty set | IM n 2; E [] / insert(hyperedge: []) / size(ofHyperedgeAt: 0) | 0; 0 ⇒ 2×1 [0, 0] |
| IM-026 | Mutation | insert(hyperedge:) with a member out of range | IM n 2; E [] / insert(hyperedge: [0, 2]) | **trap** (vertex out of range) |
| IM-027 | Mutation | insert(_:intoHyperedgeAt:) sets a cell once | IM n 3; E [{0}] / insert(2, intoHyperedgeAt: 0) / insert(2, intoHyperedgeAt: 0) / size(ofHyperedgeAt: 0) / degree(of: 2) | true; false; 2; 1 ⇒ 3×1 [1, 0, 1] |
| IM-028 | Mutation | remove(_:fromHyperedgeAt:) clears a cell once; the column stays | IM n 3; E [{0, 2}] / remove(0, fromHyperedgeAt: 0) / remove(0, fromHyperedgeAt: 0) / vertexCount/hyperedgeCount | true; false; 3/1 ⇒ 3×1 [0, 0, 1] |
| IM-029 | Mutation | remove(_:fromHyperedgeAt:) out of range | IM n 3; E [{0, 2}] / remove(0, fromHyperedgeAt: 1) | **trap** (hyperedge position out of range) |
| IM-030 | Mutation | removeAll | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / removeAll() / vertexCount/hyperedgeCount | (); 0/0 ⇒ 0×0 [] |
| IM-031 | Mutation | appendVertex past 64 rows keeps every column | IM n 64; E [{63}, {0, 63}] / appendVertex() / insert(64, intoHyperedgeAt: 1) / members(ofHyperedgeAt: 1) | 64; true; [0, 63, 64] |
| IM-032 | Transpose | transposed() is the dual: rows become columns | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / transposed() | 5×5 [11100, 00110, 11100, 00001, 00000] |
| IM-033 | Transpose | of a matrix with no columns | IM n 3; E [] / transposed() | 0×3 [] |
| IM-034 | Equality | same cells | IM n 3; E [{0, 1}] == IM n 3; E [{1, 0}] | true |
| IM-035 | Equality | column order is observable | IM n 3; E [{0}, {1}] == IM n 3; E [{1}, {0}] | false |
| IM-036 | Equality | shape matters: an extra zero row | IM n 2; E [{0}] == IM n 3; E [{0}] | false |
| IM-037 | Equality | shape matters: an extra empty column | IM n 2; E [{0}] == IM n 2; E [{0}, {}] | false |
| IM-038 | Oriented, from a graph | empty | OIM n 0; A [] | 0×0 []; columns [] |
| IM-039 | Oriented, from a graph | a path: −1 at the source, +1 at the target (NetworkX oriented=True) | OIM n 3; A [0→1, 1→2] | 3×2 [-0, +-, 0+]; columns [0:{0}→{1}, 1:{1}→{2}] |
| IM-040 | Oriented, from a graph | opposite arcs are negated columns | OIM n 2; A [0→1, 1→0] | 2×2 [-+, +-]; columns [0:{0}→{1}, 1:{1}→{0}] |
| IM-041 | Oriented, from a graph | a self-loop: source and target bits at one vertex, entry 0 (NetworkX: zero column) | OIM n 2; A [0→1, 1→1] / [vertex: 1, hyperedge: 1] / sources(ofHyperedgeAt: 1) / targets(ofHyperedgeAt: 1) / outHyperedges(of: 1) / inHyperedges(of: 1) | 0; [1]; [1]; [1]; [0, 1] ⇒ 2×2 [-0, +0]; columns [0:{0}→{1}, 1:{1}→{1}] |
| IM-042 | Oriented, from a graph | parallel arcs keep their own columns | OIM n 2; A [0→1, 0→1] | 2×2 [--, ++]; columns [0:{0}→{1}, 1:{0}→{1}] |
| IM-043 | Oriented, from a graph | from an undirected graph: each edge from its stored u to v (NetworkX's edgelist order) | OrientedIncidenceMatrix(Pseudograph(n 3; [0–1, 1–2, 0–2])) | 3×3 [-0-, +-0, 0++]; columns [0:{0}→{1}, 1:{1}→{2}, 2:{0}→{2}] |
| IM-044 | Oriented, from a graph | B·Bᵀ is the Laplacian of the loopless underlying graph | OIM n 4; A [0→1, 2→1, 1→3, 3→3] / IncidenceMatrix(self) | 4×4 [1000, 1110, 0100, 0011] ⇒ 4×4 [-000, ++-0, 0-00, 00+0]; columns [0:{0}→{1}, 1:{2}→{1}, 2:{1}→{3}, 3:{3}→{3}] |
| IM-045 | Oriented hypergraph | −1 for each source, +1 for each target (Gallo et al. 1993, section 2) | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] | 4×4 [-00+, -00+, +000, 0+0-]; columns [0:{0, 1}→{2}, 1:{2}→{2, 3}, 2:{}→{}, 3:{3}→{0, 1}] |
| IM-046 | Oriented hypergraph | a vertex on both sides: entry 0, both bits kept (HyperGraphs.jl sums −1 + 1) | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / [vertex: 2, hyperedge: 1] / sources(ofHyperedgeAt: 1) / targets(ofHyperedgeAt: 1) / outHyperedges(of: 2) / inHyperedges(of: 2) | 0; [2]; [2, 3]; [1]; [0, 1] |
| IM-047 | Oriented hypergraph | degrees: in + out; the overlap counts twice | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / outDegree(of: 2) / inDegree(of: 2) / degree(of: 2) / degree(of: 3) | 1; 2; 3; 2 |
| IM-048 | Oriented hypergraph | counts | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / vertexCount/hyperedgeCount | 4/4 |
| IM-049 | Oriented hypergraph | transposed() is the dual: column v has sources = outHyperedges(of: v), targets = inHyperedges(of: v) | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / transposed() | 4×4 [--+0, 000+, 0000, ++0-]; columns [0:{0}→{3}, 1:{0}→{3}, 2:{1}→{0, 1}, 3:{3}→{1}] |
| IM-050 | Oriented hypergraph | reversed swaps the planes: every entry negated, the overlap stays 0 | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / reversed | 4×4 [+00-, +00-, -000, 0-0+]; columns [0:{2}→{0, 1}, 1:{2, 3}→{2}, 2:{}→{}, 3:{0, 1}→{3}] |
| IM-051 | Oriented hypergraph | IncidenceMatrix(self) is the union of the planes | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / IncidenceMatrix(self) | 4×4 [1001, 1001, 1100, 0101] |
| IM-052 | Oriented mutation | appendVertex then insert(sources:targets:) | OIM n 1; E [] / appendVertex() / insert(sources: [1], targets: [0]) / insert(sources: [], targets: [0, 1]) | 1; 0; 1 ⇒ 2×2 [++, -+]; columns [0:{1}→{0}, 1:{}→{0, 1}] |
| IM-053 | Oriented mutation | insert into each plane once; a source bit may join a target bit | OIM n 3; E [{0}→{1}] / insert(0, intoTargetsOfHyperedgeAt: 0) / insert(0, intoTargetsOfHyperedgeAt: 0) / insert(2, intoSourcesOfHyperedgeAt: 0) / [vertex: 0, hyperedge: 0] | true; false; true; 0 ⇒ 3×1 [0, +, -]; columns [0:{0, 2}→{0, 1}] |
| IM-054 | Oriented mutation | remove from each plane once; the column stays | OIM n 3; E [{0, 2}→{1}] / remove(0, fromSourcesOfHyperedgeAt: 0) / remove(0, fromSourcesOfHyperedgeAt: 0) / remove(1, fromTargetsOfHyperedgeAt: 0) / vertexCount/hyperedgeCount | true; false; true; 3/1 ⇒ 3×1 [0, 0, -]; columns [0:{2}→{}] |
| IM-055 | Oriented mutation | removeAll | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / removeAll() / vertexCount/hyperedgeCount | (); 0/0 ⇒ 0×0 []; columns [] |
| IM-056 | Oriented traps | insert(sources:targets:) with a vertex out of range | OIM n 2; E [] / insert(sources: [0], targets: [2]) | **trap** (vertex out of range) |
| IM-057 | Oriented traps | entry with a column out of range | OIM n 2; E [{0}→{1}] / [vertex: 0, hyperedge: 1] | **trap** (hyperedge position out of range) |
| IM-058 | Oriented traps | targets(ofHyperedgeAt:) out of range | OIM n 2; E [{0}→{1}] / targets(ofHyperedgeAt: -1) | **trap** (hyperedge position out of range) |
| IM-059 | Oriented traps | outHyperedges(of:) out of range | OIM n 2; E [{0}→{1}] / outHyperedges(of: 2) | **trap** (vertex out of range) |
| IM-060 | Equality | oriented: a vertex on both sides differs from it on neither, although both entries are 0 | OIM n 2; E [{0}→{0, 1}] == OIM n 2; E [{}→{1}] | false |
| IM-061 | Equality | oriented: two loops at different vertices differ although every entry is 0 | OIM n 2; A [0→0] == OIM n 2; A [1→1] | false |
| IM-062 | Equality | oriented: reversed arc differs | OIM n 2; A [0→1] == OIM n 2; A [1→0] | false |
| IM-063 | Equality | oriented: column order is observable | OIM n 2; E [{0}→{}, {}→{1}] == OIM n 2; E [{}→{1}, {0}→{}] | false |
| IM-064 | Reads | checked: spellings answer a vertex as the plain ones do and throw out of range | IM n 5; E [{0, 1, 2}, {2, 3}, {0, 1, 2}, {4}, {}] / incidentHyperedges(checked: 2) / degree(checked: 2) / vertexIndex(checked: 4) / incidentHyperedges(checked: 5) / degree(checked: -1) / vertexIndex(checked: 5) | [0, 1, 2]; 3; 4; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound |
| IM-065 | Mutation | insert(checked:) with every member in range appends the column | IM n 3; E [{0}] / insert(checked: [2, 0, 2]) / vertexCount/hyperedgeCount | 1; 3/2 ⇒ 3×2 [11, 00, 01] |
| IM-066 | Mutation | insert(checked:) with a member out of range: throws, nothing changes | IM n 2; E [{0}] / insert(checked: [0, 2]) / insert(checked: [-1]) / vertexCount/hyperedgeCount | throws VertexNotFound; throws VertexNotFound; 2/1 ⇒ 2×1 [1, 0] |
| IM-067 | Oriented hypergraph | checked: spellings answer a vertex as the plain ones do and throw out of range | OIM n 4; E [{0, 1}→{2}, {2}→{2, 3}, {}→{}, {3}→{0, 1}] / outHyperedges(checked: 2) / inHyperedges(checked: 2) / outDegree(checked: 2) / inDegree(checked: 2) / degree(checked: 2) / vertexIndex(checked: 3) / outHyperedges(checked: 4) / inHyperedges(checked: -1) / outDegree(checked: 4) / inDegree(checked: -1) / degree(checked: 4) / vertexIndex(checked: -1) | [1]; [0, 1]; 1; 2; 3; 3; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound |
| IM-068 | Oriented mutation | insert(checked:targets:) and insert(checked:) with every vertex in range | OIM n 3; E [] / insert(checked: [0, 1], targets: [2]) / insert(checked: 2→2) / vertexCount/hyperedgeCount | 0; 1; 3/2 ⇒ 3×2 [-0, -0, +0]; columns [0:{0, 1}→{2}, 1:{2}→{2}] |
| IM-069 | Oriented mutation | insert(checked:targets:) and insert(checked:) out of range: throw, nothing changes | OIM n 2; E [{0}→{1}] / insert(checked: [0], targets: [2]) / insert(checked: [-1], targets: []) / insert(checked: 0→2) / insert(checked: 2→0) / vertexCount/hyperedgeCount | throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; 2/1 ⇒ 2×1 [-, +]; columns [0:{0}→{1}] |
