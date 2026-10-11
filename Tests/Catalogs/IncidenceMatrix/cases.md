# IncidenceMatrix: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2
python3 Tests/Catalogs/IncidenceMatrix/ref.py`; `--write` regenerates this file, `--stress` adds the random
matrices and mutation sequences). Every state is checked against NetworkX 3.7 `incidence_matrix` (both
modes, parallel edges and self-loops included), XGI 0.10.2 `incidence_matrix` for hypergraph inputs, the
algebraic identities (B·Bᵀ = D + A, Bᵀ·B = 2I + A(L(G)), oriented B·Bᵀ = L) and the protocol laws.

Conventions:

* `IM n N; E [{…}, …]` is `IncidenceMatrix(vertexCount: N, hyperedges: E)`; `IncidenceMatrix(Pseudograph(…))`
  and `IncidenceMatrix(DirectedPseudograph(…))` convert a graph whose vertices are `0..<n`, one column per
  edge in `edges` order. `OIM n N; E [s→t, …]` is `OrientedIncidenceMatrix(vertexCount: N, edges: E)`.
* A state `N×M [r₀, r₁, …]` (`∅` for a row of a matrix with no columns) lists the rows: character `p` of row `v` is the cell (vertex `v`, column `p`),
  `1`/`0`, or for the oriented matrix `+` (target), `-` (source), `0`; `columns [p:s→t]` lists each column's
  stored ends.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before the
  trap are listed.

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
| IM-038 | Oriented | empty | OIM n 0; E [] | 0×0 []; columns [] |
| IM-039 | Oriented | a path: −1 at the source, +1 at the target (NetworkX oriented=True) | OIM n 3; E [0→1, 1→2] | 3×2 [-0, +-, 0+]; columns [0:0→1, 1:1→2] |
| IM-040 | Oriented | opposite arcs are negated columns | OIM n 2; E [0→1, 1→0] | 2×2 [-+, +-]; columns [0:0→1, 1:1→0] |
| IM-041 | Oriented | a self-loop is a zero column, its ends still recorded (NetworkX: zero) | OIM n 2; E [0→1, 1→1] / [vertex: 1, edge: 1] / source(ofEdgeAt: 1) / target(ofEdgeAt: 1) / outEdges(of: 1) / inEdges(of: 1) | 0; 1; 1; [1]; [0, 1] ⇒ 2×2 [-0, +0]; columns [0:0→1, 1:1→1] |
| IM-042 | Oriented | parallel arcs keep their own columns | OIM n 2; E [0→1, 0→1] | 2×2 [--, ++]; columns [0:0→1, 1:0→1] |
| IM-043 | Oriented | from an undirected graph: each edge from its stored u to v (NetworkX's edgelist order) | OrientedIncidenceMatrix(Pseudograph(n 3; [0–1, 1–2, 0–2])) | 3×3 [-0-, +-0, 0++]; columns [0:0→1, 1:1→2, 2:0→2] |
| IM-044 | Oriented | B·Bᵀ is the Laplacian of the loopless underlying graph | OIM n 4; E [0→1, 2→1, 1→3, 3→3] / IncidenceMatrix(self) | 4×4 [1000, 1110, 0100, 0011] ⇒ 4×4 [-000, ++-0, 0-00, 00+0]; columns [0:0→1, 1:2→1, 2:1→3, 3:3→3] |
| IM-045 | Oriented | reads | OIM n 3; E [0→1, 1→2, 2→0, 0→2] / [vertex: 0, edge: 0] / [vertex: 1, edge: 0] / [vertex: 2, edge: 0] / outEdges(of: 0) / inEdges(of: 2) / source(ofEdgeAt: 3) / target(ofEdgeAt: 3) | -1; 1; 0; [0, 3]; [1, 3]; 0; 2 |
| IM-046 | Oriented | appendVertex then insert(edge:) | OIM n 1; E [] / appendVertex() / insert(edge: 1→0) / insert(edge: 0→0) | 1; 0; 1 ⇒ 2×2 [+0, -0]; columns [0:1→0, 1:0→0] |
| IM-047 | Oriented | insert(edge:) with an endpoint out of range | OIM n 2; E [] / insert(edge: 0→2) | **trap** (vertex out of range) |
| IM-048 | Oriented | entry with a column out of range | OIM n 2; E [0→1] / [vertex: 0, edge: 1] | **trap** (edge position out of range) |
| IM-049 | Oriented | removeAll | OIM n 2; E [0→1] / removeAll() / vertexCount/edgeCount | (); 0/0 ⇒ 0×0 []; columns [] |
| IM-050 | Equality | oriented: two loops at different vertices differ although every entry is 0 | OIM n 2; E [0→0] == OIM n 2; E [1→1] | false |
| IM-051 | Equality | oriented: reversed arc differs | OIM n 2; E [0→1] == OIM n 2; E [1→0] | false |
