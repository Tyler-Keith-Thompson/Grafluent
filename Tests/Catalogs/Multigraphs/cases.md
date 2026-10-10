# Multigraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3 ref.py`;
`--write` regenerates this file). Every Expected is the model's output (an exact port of the
proposed storage), and every state a row reaches is checked against the Graph laws, the class
lists, the reference conformers' rows (for freshly built graphs), and a NetworkX 3.7
MultiGraph / MultiDiGraph driven by the same calls (degrees, number_of_edges(u, v) for every pair,
self-loop count, the copy remove_edge(u, v) removes, the key order of G[u][v]).

Conventions:

* Input `Kind V [...]; E [...]` is `Kind(vertices: V, edges: E)`: vertices in order, then edges at
  positions 0, 1, … (a Multigraph / DirectedMultigraph row with a self-loop is the failable init
  returning nil). Calls follow, separated by `/`; Expected lists each call's result, then `⇒` and
  the final state.
* State: `V` is `vertices` (vertex index order); `E` is `edges` by position, each in its stored
  orientation; undirected `rows v:[w@e, …]` is `neighbors(of: v)` zipped with
  `incidentEdges(of: v)` (a self-loop twice); directed `out` / `in` are `successors` /
  `predecessors` zipped with `outEdges` / `inEdges` (empty rows omitted).
* `edges(between:and:)` / `edges(from:to:)` list positions oldest copy first; `remove(edge:)`
  removes the newest copy (NetworkX's `remove_edge(u, v)`); a removal moves the last edge into
  the hole and each row's last entry into its hole; removing a vertex moves the last slot into
  its place (UndirectedAdjacencyList's and AdjacencyList's rules).
* `degrees(v)` (directed) is `outDegree`, `inDegree`, `degree`.
* `trap` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).
* Codable payloads are `{"vertices": […], "edges": [u0, v0, u1, v1, …]}` (indices into vertices),
  the simple lists' format; errors are `DecodingError` cases with their debug description.


| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| MG-001 | Construction | empty | Pseudograph V []; E [] | V []; E []; rows - |
| MG-002 | Construction | empty | Multigraph V []; E [] | V []; E []; rows - |
| MG-003 | Construction | empty | DirectedPseudograph V []; E [] | V []; E []; out -; in - |
| MG-004 | Construction | empty | DirectedMultigraph V []; E [] | V []; E []; out -; in - |
| MG-005 | Construction | isolated vertices, repeats once | Pseudograph V [0, 1, 1, 2]; E [] | V [0, 1, 2]; E []; rows 0:[] 1:[] 2:[] |
| MG-006 | Construction | endpoints appended in first-appearance order | Pseudograph V []; E [2–0, 1–2] | V [2, 0, 1]; E [2–0, 1–2]; rows 2:[0@0, 1@1] 0:[2@0] 1:[2@1] |
| MG-007 | Construction | listed vertices first, then new endpoints | Pseudograph V [5]; E [3–5, 5–4] | V [5, 3, 4]; E [3–5, 5–4]; rows 5:[3@0, 4@1] 3:[5@0] 4:[5@1] |
| MG-008 | Construction | string vertices | Pseudograph V ["a", "b"]; E ["a"–"b", "b"–"c"] | V ["a", "b", "c"]; E ["a"–"b", "b"–"c"]; rows "a":["b"@0] "b":["a"@0, "c"@1] "c":["b"@1] |
| MG-009 | Construction | directed endpoints in first-appearance order | DirectedPseudograph V []; E [2→0, 1→2] | V [2, 0, 1]; E [2→0, 1→2]; out 2:[0@0] 1:[2@1]; in 2:[1@1] 0:[2@0] |
| MG-010 | Construction | multigraph with no loop builds | Multigraph V []; E [0–1, 1–0] | V [0, 1]; E [0–1, 1–0]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-011 | Construction | multigraph with a loop is nil | Multigraph V []; E [0–1, 1–1] | init nil (self-loop) |
| MG-012 | Construction | directed multigraph with a loop is nil | DirectedMultigraph V []; E [0→0] | init nil (self-loop) |
| MG-013 | Construction | directed multigraph, opposite arcs | DirectedMultigraph V []; E [0→1, 1→0] | V [0, 1]; E [0→1, 1→0]; out 0:[1@0] 1:[0@1]; in 0:[1@1] 1:[0@0] |
| MG-014 | Construction | builder: same as vertices + edges | Pseudograph V [9]; E [0–1, 0–1] | V [9, 0, 1]; E [0–1, 0–1]; rows 9:[] 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-015 | Parallel | two copies, both orientations kept | Pseudograph V []; E [0–1, 1–0]; edges(between: 0, and: 1) / edges(between: 1, and: 0) / edgeCount(between: 0, and: 1) | [0, 1] / [0, 1] / 2 ⇒ V [0, 1]; E [0–1, 1–0]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-016 | Parallel | three copies | Pseudograph V []; E [0–1, 0–1, 0–1]; edges(between: 0, and: 1) / edgeCount(between: 1, and: 0) / degree(of: 0) / degree(of: 1) | [0, 1, 2] / 3 / 3 / 3 ⇒ V [0, 1]; E [0–1, 0–1, 0–1]; rows 0:[1@0, 1@1, 1@2] 1:[0@0, 0@1, 0@2] |
| MG-017 | Parallel | copies interleaved with other edges | Pseudograph V []; E [0–1, 1–2, 0–1, 2–0, 1–0]; edges(between: 0, and: 1) / edges(between: 1, and: 2) / edges(between: 0, and: 2) / edgeCount(between: 0, and: 1) | [0, 2, 4] / [1] / [3] / 3 ⇒ V [0, 1, 2]; E [0–1, 1–2, 0–1, 2–0, 1–0]; rows 0:[1@0, 1@2, 2@3, 1@4] 1:[0@0, 2@1, 0@2, 0@4] 2:[1@1, 0@3] |
| MG-018 | Parallel | absent pair: empty, 0, false | Pseudograph V [0, 1, 2]; E [0–1]; edges(between: 0, and: 2) / edgeCount(between: 0, and: 2) / contains(edge: UndirectedEdge(0, 2)) | [] / 0 / false ⇒ V [0, 1, 2]; E [0–1]; rows 0:[1@0] 1:[0@0] 2:[] |
| MG-019 | Parallel | non-vertex: empty, 0, false, no trap | Pseudograph V [0, 1]; E [0–1]; edges(between: 0, and: 9) / edgeCount(between: 9, and: 9) / contains(edge: UndirectedEdge(9, 0)) | [] / 0 / false ⇒ V [0, 1]; E [0–1]; rows 0:[1@0] 1:[0@0] |
| MG-020 | Parallel | directed copies are directional | DirectedPseudograph V []; E [0→1, 0→1, 1→0]; edges(from: 0, to: 1) / edges(from: 1, to: 0) / edgeCount(from: 0, to: 1) / edgeCount(from: 1, to: 0) / contains(edge: DirectedEdge(from: 1, to: 0)) | [0, 1] / [2] / 2 / 1 / true ⇒ V [0, 1]; E [0→1, 0→1, 1→0]; out 0:[1@0, 1@1] 1:[0@2]; in 0:[1@2] 1:[0@0, 0@1] |
| MG-021 | Parallel | directed non-vertex | DirectedPseudograph V [0]; E []; edges(from: 0, to: 7) / edgeCount(from: 7, to: 0) / contains(edge: DirectedEdge(from: 7, to: 7)) | [] / 0 / false ⇒ V [0]; E []; out -; in - |
| MG-022 | Parallel | multigraph copies | Multigraph V []; E [0–1, 0–1, 1–2]; edges(between: 1, and: 0) / edgeCount(between: 0, and: 1) | [0, 1] / 2 ⇒ V [0, 1, 2]; E [0–1, 0–1, 1–2]; rows 0:[1@0, 1@1] 1:[0@0, 0@1, 2@2] 2:[1@2] |
| MG-023 | Parallel | directed multigraph copies | DirectedMultigraph V []; E [0→1, 0→1, 1→0, 1→0]; edges(from: 1, to: 0) / edgeCount(from: 0, to: 1) | [2, 3] / 2 ⇒ V [0, 1]; E [0→1, 0→1, 1→0, 1→0]; out 0:[1@0, 1@1] 1:[0@2, 0@3]; in 0:[1@2, 1@3] 1:[0@0, 0@1] |
| MG-024 | Parallel | ten copies | Pseudograph V []; E [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1]; edgeCount(between: 0, and: 1) / degree(of: 0) | 10 / 10 ⇒ V [0, 1]; E [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1]; rows 0:[1@0, 1@1, 1@2, 1@3, 1@4, 1@5, 1@6, 1@7, 1@8, 1@9] 1:[0@0, 0@1, 0@2, 0@3, 0@4, 0@5, 0@6, 0@7, 0@8, 0@9] |
| MG-025 | Parallel | string copies | Pseudograph V []; E ["a"–"b", "b"–"a", "a"–"b"]; edges(between: "b", and: "a") | [0, 1, 2] ⇒ V ["a", "b"]; E ["a"–"b", "b"–"a", "a"–"b"]; rows "a":["b"@0, "b"@1, "b"@2] "b":["a"@0, "a"@1, "a"@2] |
| MG-026 | Loops | one loop: listed twice in its row, degree 2 | Pseudograph V []; E [0–0]; degree(of: 0) / edges(between: 0, and: 0) / edgeCount(between: 0, and: 0) | 2 / [0] / 1 ⇒ V [0]; E [0–0]; rows 0:[0@0, 0@0] |
| MG-027 | Loops | two loops | Pseudograph V []; E [0–0, 0–0]; degree(of: 0) / edges(between: 0, and: 0) / edgeCount(between: 0, and: 0) | 4 / [0, 1] / 2 ⇒ V [0]; E [0–0, 0–0]; rows 0:[0@0, 0@0, 0@1, 0@1] |
| MG-028 | Loops | loop beside an edge | Pseudograph V []; E [0–1, 0–0, 1–0]; degree(of: 0) / degree(of: 1) / edges(between: 0, and: 0) | 4 / 2 / [1] ⇒ V [0, 1]; E [0–1, 0–0, 1–0]; rows 0:[1@0, 0@1, 0@1, 1@2] 1:[0@0, 0@2] |
| MG-029 | Loops | loop on an isolated listed vertex | Pseudograph V [0, 1]; E [1–1]; degree(of: 0) / degree(of: 1) | 0 / 2 ⇒ V [0, 1]; E [1–1]; rows 0:[] 1:[1@0, 1@0] |
| MG-030 | Loops | directed loop: once out, once in | DirectedPseudograph V []; E [0→0]; degrees(0) / edges(from: 0, to: 0) | out 1 in 1 degree 2 / [0] ⇒ V [0]; E [0→0]; out 0:[0@0]; in 0:[0@0] |
| MG-031 | Loops | directed two loops and an arc | DirectedPseudograph V []; E [0→0, 0→1, 0→0]; degrees(0) / degrees(1) / edgeCount(from: 0, to: 0) | out 3 in 2 degree 5 / out 0 in 1 degree 1 / 2 ⇒ V [0, 1]; E [0→0, 0→1, 0→0]; out 0:[0@0, 1@1, 0@2]; in 0:[0@0, 0@2] 1:[0@1] |
| MG-032 | Loops | multigraph insert loop traps | Multigraph V [0]; E []; insert(edge: UndirectedEdge(0, 0)) | trap (self-loop in a Multigraph) |
| MG-033 | Loops | multigraph insert loop with new vertex traps | Multigraph V []; E []; insert(edge: UndirectedEdge(5, 5)) | trap (self-loop in a Multigraph) |
| MG-034 | Loops | directed multigraph insert loop traps | DirectedMultigraph V [0, 1]; E [0→1]; insert(edge: DirectedEdge(from: 1, to: 1)) | trap (self-loop in a DirectedMultigraph) |
| MG-035 | Degrees | degrees count copies | Pseudograph V []; E [0–1, 0–1, 0–2]; degree(of: 0) / degree(of: 1) / degree(of: 2) | 3 / 2 / 1 ⇒ V [0, 1, 2]; E [0–1, 0–1, 0–2]; rows 0:[1@0, 1@1, 2@2] 1:[0@0, 0@1] 2:[0@2] |
| MG-036 | Degrees | sum is twice the edge count with loops | Pseudograph V []; E [0–0, 0–1, 1–1, 1–1]; degree(of: 0) / degree(of: 1) | 3 / 5 ⇒ V [0, 1]; E [0–0, 0–1, 1–1, 1–1]; rows 0:[0@0, 0@0, 1@1] 1:[0@1, 1@2, 1@2, 1@3, 1@3] |
| MG-037 | Degrees | isolated vertex 0 | Pseudograph V [0, 1]; E []; degree(of: 0) | 0 ⇒ V [0, 1]; E []; rows 0:[] 1:[] |
| MG-038 | Degrees | directed degrees | DirectedPseudograph V []; E [0→1, 0→1, 1→0, 2→0]; degrees(0) / degrees(1) / degrees(2) | out 2 in 2 degree 4 / out 1 in 2 degree 3 / out 1 in 0 degree 1 ⇒ V [0, 1, 2]; E [0→1, 0→1, 1→0, 2→0]; out 0:[1@0, 1@1] 1:[0@2] 2:[0@3]; in 0:[1@2, 2@3] 1:[0@0, 0@1] |
| MG-039 | Degrees | degree of a non-vertex traps | Pseudograph V [0]; E []; degree(of: 1) | trap (not a vertex) |
| MG-040 | Degrees | directed degree of a non-vertex traps | DirectedPseudograph V [0]; E []; degrees(1) | trap (not a vertex) |
| MG-041 | Degrees | multigraph degrees | Multigraph V []; E [0–1, 1–0, 1–2]; degree(of: 0) / degree(of: 1) / degree(of: 2) | 2 / 3 / 1 ⇒ V [0, 1, 2]; E [0–1, 1–0, 1–2]; rows 0:[1@0, 1@1] 1:[0@0, 0@1, 2@2] 2:[1@2] |
| MG-042 | Rows | rows in insertion order, u end then v end | Pseudograph V []; E [0–1, 2–0, 0–0, 1–2] | V [0, 1, 2]; E [0–1, 2–0, 0–0, 1–2]; rows 0:[1@0, 2@1, 0@2, 0@2] 1:[0@0, 2@3] 2:[0@1, 1@3] |
| MG-043 | Rows | loop's two ends adjacent in its row | Pseudograph V []; E [0–1, 1–1, 1–2] | V [0, 1, 2]; E [0–1, 1–1, 1–2]; rows 0:[1@0] 1:[0@0, 1@1, 1@1, 2@2] 2:[1@2] |
| MG-044 | Rows | directed rows: out by position, in by position | DirectedPseudograph V []; E [0→1, 1→0, 0→1, 1→1, 2→1] | V [0, 1, 2]; E [0→1, 1→0, 0→1, 1→1, 2→1]; out 0:[1@0, 1@2] 1:[0@1, 1@3] 2:[1@4]; in 0:[1@1] 1:[0@0, 0@2, 1@3, 2@4] |
| MG-045 | Rows | edge stored in given orientation | Pseudograph V []; E [1–0, 0–1] | V [1, 0]; E [1–0, 0–1]; rows 1:[0@0, 0@1] 0:[1@0, 1@1] |
| MG-046 | Rows | star of copies | Pseudograph V []; E [0–1, 0–2, 0–1, 0–3, 0–2] | V [0, 1, 2, 3]; E [0–1, 0–2, 0–1, 0–3, 0–2]; rows 0:[1@0, 2@1, 1@2, 3@3, 2@4] 1:[0@0, 0@2] 2:[0@1, 0@4] 3:[0@3] |
| MG-047 | Insert | positions 0, 1, 2 for copies | Pseudograph V []; E []; insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(1, 0)) | 0 / 1 / 2 ⇒ V [0, 1]; E [0–1, 0–1, 1–0]; rows 0:[1@0, 1@1, 1@2] 1:[0@0, 0@1, 0@2] |
| MG-048 | Insert | inserting endpoints | Pseudograph V [0]; E []; insert(edge: UndirectedEdge(1, 2)) / insert(edge: UndirectedEdge(0, 1)) | 0 / 1 ⇒ V [0, 1, 2]; E [1–2, 0–1]; rows 0:[1@1] 1:[2@0, 0@1] 2:[1@0] |
| MG-049 | Insert | insert loop | Pseudograph V []; E []; insert(edge: UndirectedEdge(3, 3)) / insert(edge: UndirectedEdge(3, 3)) | 0 / 1 ⇒ V [3]; E [3–3, 3–3]; rows 3:[3@0, 3@0, 3@1, 3@1] |
| MG-050 | Insert | insert vertex twice | Pseudograph V []; E []; insert(0) / insert(0) / insert(1) | inserted true / inserted false / inserted true ⇒ V [0, 1]; E []; rows 0:[] 1:[] |
| MG-051 | Insert | directed inserts | DirectedPseudograph V []; E []; insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 1, to: 0)) / insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 0, to: 0)) | 0 / 1 / 2 / 3 ⇒ V [0, 1]; E [0→1, 1→0, 0→1, 0→0]; out 0:[1@0, 1@2, 0@3] 1:[0@1]; in 0:[1@1, 0@3] 1:[0@0, 0@2] |
| MG-052 | Insert | multigraph inserts | Multigraph V []; E []; insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(1, 0)) | 0 / 1 ⇒ V [0, 1]; E [0–1, 1–0]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-053 | Insert | directed multigraph inserts | DirectedMultigraph V []; E []; insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 0, to: 1)) | 0 / 1 ⇒ V [0, 1]; E [0→1, 0→1]; out 0:[1@0, 1@1]; in 1:[0@0, 0@1] |
| MG-054 | Insert | insert after removal reuses the end position | Pseudograph V []; E [0–1, 1–2, 2–0]; remove(edgeAt: 0) / insert(edge: UndirectedEdge(0, 1)) | 0–1 / 2 ⇒ V [0, 1, 2]; E [2–0, 1–2, 0–1]; rows 0:[2@0, 1@2] 1:[2@1, 0@2] 2:[1@1, 0@0] |
| MG-055 | Remove edge | newest copy of three (last position) | Pseudograph V []; E [0–1, 0–1, 0–1]; remove(edge: UndirectedEdge(0, 1)) | 0–1 ⇒ V [0, 1]; E [0–1, 0–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-056 | Remove edge | newest copy not at the last position | Pseudograph V []; E [0–1, 0–1, 1–2]; remove(edge: UndirectedEdge(0, 1)) | 0–1 ⇒ V [0, 1, 2]; E [0–1, 1–2]; rows 0:[1@0] 1:[0@0, 2@1] 2:[1@1] |
| MG-057 | Remove edge | orientation-free, returns stored orientation | Pseudograph V []; E [1–0, 0–1, 2–1]; remove(edge: UndirectedEdge(1, 0)) | 0–1 ⇒ V [1, 0, 2]; E [1–0, 2–1]; rows 1:[0@0, 2@1] 0:[1@0] 2:[1@1] |
| MG-058 | Remove edge | absent pair returns nil, no change | Pseudograph V []; E [0–1]; remove(edge: UndirectedEdge(0, 2)) / remove(edge: UndirectedEdge(0, 9)) | nil / nil ⇒ V [0, 1]; E [0–1]; rows 0:[1@0] 1:[0@0] |
| MG-059 | Remove edge | remove until gone | Pseudograph V []; E [0–1, 0–1]; remove(edge: UndirectedEdge(0, 1)) / remove(edge: UndirectedEdge(0, 1)) / remove(edge: UndirectedEdge(0, 1)) | 0–1 / 0–1 / nil ⇒ V [0, 1]; E []; rows 0:[] 1:[] |
| MG-060 | Remove edge | newest after a re-insert | Pseudograph V []; E [0–1, 0–1, 1–2]; remove(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(0, 1)) / edges(between: 0, and: 1) / remove(edge: UndirectedEdge(1, 0)) | 0–1 / 2 / [0, 2] / 0–1 ⇒ V [0, 1, 2]; E [0–1, 1–2]; rows 0:[1@0] 1:[0@0, 2@1] 2:[1@1] |
| MG-061 | Remove edge | loop copies | Pseudograph V []; E [0–0, 0–1, 0–0]; remove(edge: UndirectedEdge(0, 0)) / degree(of: 0) | 0–0 / 3 ⇒ V [0, 1]; E [0–0, 0–1]; rows 0:[0@0, 0@0, 1@1] 1:[0@1] |
| MG-062 | Remove edge | directed newest copy | DirectedPseudograph V []; E [0→1, 1→0, 0→1, 1→2]; remove(edge: DirectedEdge(from: 0, to: 1)) | 0→1 ⇒ V [0, 1, 2]; E [0→1, 1→0, 1→2]; out 0:[1@0] 1:[0@1, 2@2]; in 0:[1@1] 1:[0@0] 2:[1@2] |
| MG-063 | Remove edge | directed opposite arc absent | DirectedPseudograph V []; E [0→1]; remove(edge: DirectedEdge(from: 1, to: 0)) | nil ⇒ V [0, 1]; E [0→1]; out 0:[1@0]; in 1:[0@0] |
| MG-064 | Remove edge | directed loop | DirectedPseudograph V []; E [0→0, 0→1, 0→0]; remove(edge: DirectedEdge(from: 0, to: 0)) | 0→0 ⇒ V [0, 1]; E [0→0, 0→1]; out 0:[0@0, 1@1]; in 0:[0@0] 1:[0@1] |
| MG-065 | Remove edge | copies order survives the move of the last edge | Pseudograph V []; E [0–1, 2–3, 0–1, 0–1, 2–3]; remove(edgeAt: 0) / edges(between: 0, and: 1) / edges(between: 2, and: 3) / remove(edge: UndirectedEdge(0, 1)) / edges(between: 0, and: 1) | 0–1 / [2, 3] / [1, 0] / 0–1 / [2] ⇒ V [0, 1, 2, 3]; E [2–3, 2–3, 0–1]; rows 0:[1@2] 1:[0@2] 2:[3@1, 3@0] 3:[2@1, 2@0] |
| MG-066 | Remove edge | multigraph | Multigraph V []; E [0–1, 1–2, 0–1]; remove(edge: UndirectedEdge(1, 0)) | 0–1 ⇒ V [0, 1, 2]; E [0–1, 1–2]; rows 0:[1@0] 1:[0@0, 2@1] 2:[1@1] |
| MG-067 | Remove edge | directed multigraph | DirectedMultigraph V []; E [0→1, 1→2, 0→1]; remove(edge: DirectedEdge(from: 0, to: 1)) | 0→1 ⇒ V [0, 1, 2]; E [0→1, 1→2]; out 0:[1@0] 1:[2@1]; in 1:[0@0] 2:[1@1] |
| MG-068 | Remove at | first position: last edge moves in | Pseudograph V []; E [0–1, 1–2, 2–0]; remove(edgeAt: 0) | 0–1 ⇒ V [0, 1, 2]; E [2–0, 1–2]; rows 0:[2@0] 1:[2@1] 2:[1@1, 0@0] |
| MG-069 | Remove at | last position: nothing moves | Pseudograph V []; E [0–1, 1–2, 2–0]; remove(edgeAt: 2) | 2–0 ⇒ V [0, 1, 2]; E [0–1, 1–2]; rows 0:[1@0] 1:[0@0, 2@1] 2:[1@1] |
| MG-070 | Remove at | a chosen copy, not the newest | Pseudograph V []; E [0–1, 0–1, 0–1]; remove(edgeAt: 0) / edges(between: 0, and: 1) | 0–1 / [1, 0] ⇒ V [0, 1]; E [0–1, 0–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-071 | Remove at | middle copy | Pseudograph V []; E [0–1, 0–1, 0–1]; remove(edgeAt: 1) / edges(between: 0, and: 1) | 0–1 / [0, 1] ⇒ V [0, 1]; E [0–1, 0–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-072 | Remove at | loop, both ends leave the row | Pseudograph V []; E [0–1, 0–0, 0–2]; remove(edgeAt: 1) | 0–0 ⇒ V [0, 1, 2]; E [0–1, 0–2]; rows 0:[1@0, 2@1] 1:[0@0] 2:[0@1] |
| MG-073 | Remove at | loop moved into the hole | Pseudograph V []; E [0–1, 1–2, 1–1]; remove(edgeAt: 0) | 0–1 ⇒ V [0, 1, 2]; E [1–1, 1–2]; rows 0:[] 1:[1@0, 2@1, 1@0] 2:[1@1] |
| MG-074 | Remove at | loop with swapped ends | Pseudograph V []; E [0–0, 0–1, 0–0]; remove(edgeAt: 0) / remove(edgeAt: 0) | 0–0 / 0–0 ⇒ V [0, 1]; E [0–1]; rows 0:[1@0] 1:[0@0] |
| MG-075 | Remove at | out of range traps | Pseudograph V []; E [0–1]; remove(edgeAt: 1) | trap (edge position out of range) |
| MG-076 | Remove at | negative traps | Pseudograph V []; E [0–1]; remove(edgeAt: -1) | trap (edge position out of range) |
| MG-077 | Remove at | empty graph traps | Pseudograph V [0]; E []; remove(edgeAt: 0) | trap (edge position out of range) |
| MG-078 | Remove at | directed first position | DirectedPseudograph V []; E [0→1, 1→2, 2→0, 0→1]; remove(edgeAt: 0) | 0→1 ⇒ V [0, 1, 2]; E [0→1, 1→2, 2→0]; out 0:[1@0] 1:[2@1] 2:[0@2]; in 0:[2@2] 1:[0@0] 2:[1@1] |
| MG-079 | Remove at | directed loop moved | DirectedPseudograph V []; E [0→1, 1→1, 1→1]; remove(edgeAt: 0) | 0→1 ⇒ V [0, 1]; E [1→1, 1→1]; out 1:[1@1, 1@0]; in 1:[1@0, 1@1] |
| MG-080 | Remove at | directed out of range traps | DirectedPseudograph V []; E []; remove(edgeAt: 0) | trap (edge position out of range) |
| MG-081 | Remove at | every position from the front | Pseudograph V []; E [0–1, 0–1, 1–1, 1–2]; remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0) | 0–1 / 1–2 / 1–1 / 0–1 ⇒ V [0, 1, 2]; E []; rows 0:[] 1:[] 2:[] |
| MG-082 | Remove at | every position from the back | Pseudograph V []; E [0–1, 0–1, 1–1, 1–2]; remove(edgeAt: 3) / remove(edgeAt: 2) / remove(edgeAt: 1) / remove(edgeAt: 0) | 1–2 / 1–1 / 0–1 / 0–1 ⇒ V [0, 1, 2]; E []; rows 0:[] 1:[] 2:[] |
| MG-083 | Remove at | directed every position from the front | DirectedPseudograph V []; E [0→1, 1→0, 1→1, 0→1]; remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0) / remove(edgeAt: 0) | 0→1 / 0→1 / 1→1 / 1→0 ⇒ V [0, 1]; E []; out -; in - |
| MG-084 | Remove all copies | three copies among others | Pseudograph V []; E [0–1, 1–2, 0–1, 2–0, 1–0]; removeAllEdges(between: 0, and: 1) | 3 ⇒ V [0, 1, 2]; E [2–0, 1–2]; rows 0:[2@0] 1:[2@1] 2:[1@1, 0@0] |
| MG-085 | Remove all copies | absent pair: 0 | Pseudograph V []; E [0–1]; removeAllEdges(between: 0, and: 2) / removeAllEdges(between: 5, and: 6) | 0 / 0 ⇒ V [0, 1]; E [0–1]; rows 0:[1@0] 1:[0@0] |
| MG-086 | Remove all copies | loops | Pseudograph V []; E [0–0, 0–1, 0–0, 0–0]; removeAllEdges(between: 0, and: 0) / degree(of: 0) | 3 / 1 ⇒ V [0, 1]; E [0–1]; rows 0:[1@0] 1:[0@0] |
| MG-087 | Remove all copies | directed one direction only | DirectedPseudograph V []; E [0→1, 1→0, 0→1, 1→0]; removeAllEdges(from: 0, to: 1) | 2 ⇒ V [0, 1]; E [1→0, 1→0]; out 1:[0@1, 0@0]; in 0:[1@1, 1@0] |
| MG-088 | Remove all copies | multigraph | Multigraph V []; E [1–0, 0–1, 1–2]; removeAllEdges(between: 0, and: 1) | 2 ⇒ V [1, 0, 2]; E [1–2]; rows 1:[2@0] 0:[] 2:[1@0] |
| MG-089 | Remove all copies | keeps both vertices | Pseudograph V []; E [0–1, 0–1]; removeAllEdges(between: 1, and: 0) | 2 ⇒ V [0, 1]; E []; rows 0:[] 1:[] |
| MG-090 | Remove vertex | last slot moves into the hole | Pseudograph V []; E [0–1, 1–2, 2–0, 0–1]; remove(0) | 0 ⇒ V [2, 1]; E [1–2]; rows 2:[1@0] 1:[2@0] |
| MG-091 | Remove vertex | last vertex: nothing moves | Pseudograph V []; E [0–1, 1–2, 2–0]; remove(2) | 2 ⇒ V [0, 1]; E [0–1]; rows 0:[1@0] 1:[0@0] |
| MG-092 | Remove vertex | removes every copy | Pseudograph V []; E [0–1, 0–1, 1–2]; remove(1) | 1 ⇒ V [0, 2]; E []; rows 0:[] 2:[] |
| MG-093 | Remove vertex | removes its loops | Pseudograph V []; E [0–0, 0–1, 0–0, 1–2]; remove(0) | 0 ⇒ V [2, 1]; E [1–2]; rows 2:[1@0] 1:[2@0] |
| MG-094 | Remove vertex | moved vertex has loops and copies | Pseudograph V []; E [0–1, 2–2, 2–1, 1–2, 2–2]; remove(0) / edges(between: 1, and: 2) / edges(between: 2, and: 2) | 0 / [2, 3] / [1, 0] ⇒ V [2, 1]; E [2–2, 2–2, 2–1, 1–2]; rows 2:[2@1, 2@1, 1@2, 1@3, 2@0, 2@0] 1:[2@3, 2@2] |
| MG-095 | Remove vertex | non-vertex returns nil | Pseudograph V [0]; E []; remove(1) | nil ⇒ V [0]; E []; rows 0:[] |
| MG-096 | Remove vertex | copies between survivors keep order | Pseudograph V []; E [1–2, 0–1, 1–2, 0–2, 1–2]; remove(0) / edges(between: 1, and: 2) | 0 / [0, 2, 1] ⇒ V [1, 2]; E [1–2, 1–2, 1–2]; rows 1:[2@0, 2@1, 2@2] 2:[1@0, 1@2, 1@1] |
| MG-097 | Remove vertex | isolated | Pseudograph V [0, 1, 2]; E [1–2]; remove(0) | 0 ⇒ V [2, 1]; E [1–2]; rows 2:[1@0] 1:[2@0] |
| MG-098 | Remove vertex | directed: last slot moves in | DirectedPseudograph V []; E [0→1, 1→2, 2→0, 2→1, 1→2]; remove(0) | 0 ⇒ V [2, 1]; E [1→2, 1→2, 2→1]; out 2:[1@2] 1:[2@1, 2@0]; in 2:[1@1, 1@0] 1:[2@2] |
| MG-099 | Remove vertex | directed with loops on the moved vertex | DirectedPseudograph V []; E [0→1, 2→2, 2→1, 1→2, 2→2]; remove(0) / edges(from: 2, to: 2) | 0 / [1, 0] ⇒ V [2, 1]; E [2→2, 2→2, 2→1, 1→2]; out 2:[2@1, 1@2, 2@0] 1:[2@3]; in 2:[2@1, 1@3, 2@0] 1:[2@2] |
| MG-100 | Remove vertex | directed removes its loops | DirectedPseudograph V []; E [0→0, 0→1, 1→0, 0→0]; remove(0) | 0 ⇒ V [1]; E []; out -; in - |
| MG-101 | Remove vertex | directed non-vertex | DirectedPseudograph V []; E [0→1]; remove(3) | nil ⇒ V [0, 1]; E [0→1]; out 0:[1@0]; in 1:[0@0] |
| MG-102 | Remove vertex | multigraph | Multigraph V []; E [0–1, 1–2, 0–2, 1–2]; remove(0) | 0 ⇒ V [2, 1]; E [1–2, 1–2]; rows 2:[1@1, 1@0] 1:[2@0, 2@1] |
| MG-103 | Remove vertex | directed multigraph | DirectedMultigraph V []; E [0→1, 1→2, 2→0, 1→2]; remove(1) | 1 ⇒ V [0, 2]; E [2→0]; out 2:[0@0]; in 0:[2@0] |
| MG-104 | Remove vertex | every vertex | Pseudograph V []; E [0–1, 1–1, 1–2, 2–0]; remove(0) / remove(1) / remove(2) | 0 / 1 / 2 ⇒ V []; E []; rows - |
| MG-105 | Sequence | insert, remove, insert | Pseudograph V []; E []; insert(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(1, 2)) / insert(edge: UndirectedEdge(0, 1)) / remove(edge: UndirectedEdge(0, 1)) / insert(edge: UndirectedEdge(2, 2)) / remove(edgeAt: 0) / edges(between: 0, and: 1) | 0 / 1 / 2 / 0–1 / 2 / 0–1 / [] ⇒ V [0, 1, 2]; E [2–2, 1–2]; rows 0:[] 1:[2@1] 2:[1@1, 2@0, 2@0] |
| MG-106 | Sequence | copies around vertex removal | Pseudograph V []; E [0–1, 1–2, 0–1, 2–3, 3–0, 1–2]; remove(2) / insert(edge: UndirectedEdge(1, 3)) / insert(edge: UndirectedEdge(1, 3)) / remove(edge: UndirectedEdge(3, 1)) / edges(between: 0, and: 1) / edges(between: 1, and: 3) | 2 / 3 / 4 / 1–3 / [0, 2] / [3] ⇒ V [0, 1, 3]; E [0–1, 3–0, 0–1, 1–3]; rows 0:[1@0, 1@2, 3@1] 1:[0@0, 0@2, 3@3] 3:[0@1, 1@3] |
| MG-107 | Sequence | loops and swaps | Pseudograph V []; E [0–0, 1–1, 0–1, 0–0, 1–1]; remove(edgeAt: 0) / remove(edgeAt: 0) / remove(1) / edges(between: 0, and: 0) | 0–0 / 1–1 / 1 / [0] ⇒ V [0]; E [0–0]; rows 0:[0@0, 0@0] |
| MG-108 | Sequence | directed sequence | DirectedPseudograph V []; E []; insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 1, to: 0)) / insert(edge: DirectedEdge(from: 0, to: 1)) / insert(edge: DirectedEdge(from: 1, to: 1)) / remove(edge: DirectedEdge(from: 0, to: 1)) / remove(0) / insert(edge: DirectedEdge(from: 1, to: 2)) / insert(edge: DirectedEdge(from: 2, to: 1)) | 0 / 1 / 2 / 3 / 0→1 / 0 / 1 / 2 ⇒ V [1, 2]; E [1→1, 1→2, 2→1]; out 1:[1@0, 2@1] 2:[1@2]; in 1:[1@0, 2@2] 2:[1@1] |
| MG-109 | Sequence | removeAllEdges keeps vertices | Pseudograph V []; E [0–1, 0–1, 1–1]; removeAllEdges() / insert(edge: UndirectedEdge(1, 0)) | () / 0 ⇒ V [0, 1]; E [1–0]; rows 0:[1@0] 1:[0@0] |
| MG-110 | Sequence | removeAll | DirectedPseudograph V []; E [0→1, 0→1]; removeAll() / insert(edge: DirectedEdge(from: 5, to: 6)) | () / 0 ⇒ V [5, 6]; E [5→6]; out 5:[6@0]; in 6:[5@0] |
| MG-111 | Sequence | strings | Pseudograph V []; E ["a"–"b", "b"–"c", "a"–"b", "c"–"c"]; remove("a") / insert(edge: UndirectedEdge("c", "b")) / remove(edge: UndirectedEdge("b", "c")) | "a" / 2 / "c"–"b" ⇒ V ["c", "b"]; E ["c"–"c", "b"–"c"]; rows "c":["b"@1, "c"@0, "c"@0] "b":["c"@1] |
| MG-112 | Sequence | re-insert removed vertex | Pseudograph V []; E [0–1, 0–1]; remove(0) / insert(edge: UndirectedEdge(0, 1)) / edges(between: 0, and: 1) | 0 / 0 / [0] ⇒ V [1, 0]; E [0–1]; rows 1:[0@0] 0:[1@0] |
| MG-113 | Sequence | directed multigraph sequence | DirectedMultigraph V []; E [0→1, 1→0, 0→1]; remove(edgeAt: 0) / insert(edge: DirectedEdge(from: 2, to: 0)) / remove(1) / edges(from: 2, to: 0) | 0→1 / 2 / 1 / [0] ⇒ V [0, 2]; E [2→0]; out 2:[0@0]; in 0:[2@0] |
| MG-114 | Sequence | multigraph sequence | Multigraph V []; E [0–1, 1–2, 2–0, 0–1]; removeAllEdges(between: 0, and: 1) / insert(edge: UndirectedEdge(0, 2)) / remove(2) | 2 / 2 / 2 ⇒ V [0, 1]; E []; rows 0:[] 1:[] |
| MG-115 | Equality | same edges, other order | Pseudograph V [] E [0–1, 0–1, 1–2] vs V [] E [1–2, 0–1, 1–0] | == true; equal hashes |
| MG-116 | Equality | copy count differs | Pseudograph V [] E [0–1, 0–1] vs V [] E [0–1] | == false |
| MG-117 | Equality | orientation ignored | Pseudograph V [] E [0–1] vs V [] E [1–0] | == true; equal hashes |
| MG-118 | Equality | isolated vertex differs | Pseudograph V [2] E [0–1] vs V [] E [0–1] | == false |
| MG-119 | Equality | vertex order ignored | Pseudograph V [0, 1, 2] E [] vs V [2, 1, 0] E [] | == true; equal hashes |
| MG-120 | Equality | loop count differs | Pseudograph V [] E [0–0] vs V [] E [0–0, 0–0] | == false |
| MG-121 | Equality | after removal equal to fresh | Pseudograph V [] E [0–1, 1–2, 0–1] then remove(edgeAt: 0) vs V [] E [1–2, 0–1] | == true; equal hashes |
| MG-122 | Equality | directed orientation matters | DirectedPseudograph V [] E [0→1] vs V [] E [1→0] | == false |
| MG-123 | Equality | directed copies | DirectedPseudograph V [] E [0→1, 0→1, 1→0] vs V [] E [1→0, 0→1, 0→1] | == true; equal hashes |
| MG-124 | Equality | directed copy count differs | DirectedPseudograph V [] E [0→1, 1→0] vs V [] E [0→1, 0→1] | == false |
| MG-125 | Equality | empty graphs | Pseudograph V [] E [] vs V [] E [] | == true; equal hashes |
| MG-126 | Equality | multigraph same edges | Multigraph V [] E [0–1, 1–0] vs V [] E [0–1, 0–1] | == true; equal hashes |
| MG-127 | Equality | same edge multiset, different pairs | Pseudograph V [] E [0–1, 2–3] vs V [] E [0–2, 1–3] | == false |
| MG-128 | Equality | strings | Pseudograph V [] E ["a"–"b", "b"–"a"] vs V [] E ["b"–"a", "a"–"b"] | == true; equal hashes |
| MG-129 | Codable | round trip keeps vertex order and positions | Pseudograph V [] E [0–1, 0–1, 1–1] | encodes {"vertices":[0,1],"edges":[0,1,0,1,1,1]}; decodes to V [0, 1]; E [0–1, 0–1, 1–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1, 1@2, 1@2] |
| MG-130 | Codable | round trip keeps vertex order and positions | Pseudograph V [3] E [0–1] | encodes {"vertices":[3,0,1],"edges":[1,2]}; decodes to V [3, 0, 1]; E [0–1]; rows 3:[] 0:[1@0] 1:[0@0] |
| MG-131 | Codable | round trip keeps vertex order and positions | Pseudograph V [] E [0–1, 1–2, 0–1, 2–2] then remove(edgeAt: 0) | encodes {"vertices":[0,1,2],"edges":[2,2,1,2,0,1]}; decodes to V [0, 1, 2]; E [2–2, 1–2, 0–1]; rows 0:[1@2] 1:[2@1, 0@2] 2:[2@0, 2@0, 1@1] |
| MG-132 | Codable | round trip keeps vertex order and positions | Pseudograph V ["a", "b"] E ["b"–"a", "a"–"b"] | encodes {"vertices":["a","b"],"edges":[1,0,0,1]}; decodes to V ["a", "b"]; E ["b"–"a", "a"–"b"]; rows "a":["b"@0, "b"@1] "b":["a"@0, "a"@1] |
| MG-133 | Codable | round trip keeps vertex order and positions | Multigraph V [] E [0–1, 1–0] | encodes {"vertices":[0,1],"edges":[0,1,1,0]}; decodes to V [0, 1]; E [0–1, 1–0]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-134 | Codable | round trip keeps vertex order and positions | DirectedPseudograph V [] E [0→1, 0→1, 1→0, 1→1] | encodes {"vertices":[0,1],"edges":[0,1,0,1,1,0,1,1]}; decodes to V [0, 1]; E [0→1, 0→1, 1→0, 1→1]; out 0:[1@0, 1@1] 1:[0@2, 1@3]; in 0:[1@2] 1:[0@0, 0@1, 1@3] |
| MG-135 | Codable | round trip keeps vertex order and positions | DirectedMultigraph V [] E [0→1, 0→1] | encodes {"vertices":[0,1],"edges":[0,1,0,1]}; decodes to V [0, 1]; E [0→1, 0→1]; out 0:[1@0, 1@1]; in 1:[0@0, 0@1] |
| MG-136 | Codable | round trip keeps vertex order and positions | Pseudograph V [] E [] | encodes {"vertices":[],"edges":[]}; decodes to V []; E []; rows - |
| MG-137 | Codable | copies accepted | Pseudograph decode {"vertices":[0,1],"edges":[0,1,0,1]} | V [0, 1]; E [0–1, 0–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-138 | Codable | loops accepted | Pseudograph decode {"vertices":[0],"edges":[0,0,0,0]} | V [0]; E [0–0, 0–0]; rows 0:[0@0, 0@0, 0@1, 0@1] |
| MG-139 | Codable | loop rejected | Multigraph decode {"vertices":[0],"edges":[0,0]} | dataCorrupted(Self-loop) |
| MG-140 | Codable | directed loop rejected | DirectedMultigraph decode {"vertices":[0,1],"edges":[0,1,1,1]} | dataCorrupted(Self-loop) |
| MG-141 | Codable | directed loop accepted | DirectedPseudograph decode {"vertices":[0],"edges":[0,0]} | V [0]; E [0→0]; out 0:[0@0]; in 0:[0@0] |
| MG-142 | Codable | odd length | Pseudograph decode {"vertices":[0,1],"edges":[0]} | dataCorrupted(Edge list has odd length) |
| MG-143 | Codable | repeated vertex | Pseudograph decode {"vertices":[0,0],"edges":[]} | dataCorrupted(Repeated vertex) |
| MG-144 | Codable | endpoint out of range | Pseudograph decode {"vertices":[0,1],"edges":[0,2]} | dataCorrupted(Edge endpoint out of range) |
| MG-145 | Codable | negative endpoint | Pseudograph decode {"vertices":[0,1],"edges":[-1,0]} | dataCorrupted(Edge endpoint out of range) |
| MG-146 | Codable | endpoint with no vertices | DirectedPseudograph decode {"vertices":[],"edges":[0,0]} | dataCorrupted(Edge endpoint out of range) |
| MG-147 | Codable | missing vertices | Pseudograph decode {"edges":[]} | keyNotFound(vertices) |
| MG-148 | Codable | missing edges | DirectedPseudograph decode {"vertices":[]} | keyNotFound(edges) |
| MG-149 | Codable | string vertices | Pseudograph decode {"vertices":["a","b"],"edges":[1,0,0,1]} | V ["a", "b"]; E ["b"–"a", "a"–"b"]; rows "a":["b"@0, "b"@1] "b":["a"@0, "a"@1] |
| MG-150 | Codable | directed copies accepted | DirectedMultigraph decode {"vertices":[0,1],"edges":[0,1,0,1,1,0]} | V [0, 1]; E [0→1, 0→1, 1→0]; out 0:[1@0, 1@1] 1:[0@2]; in 0:[1@2] 1:[0@0, 0@1] |
| MG-151 | Codable | UndirectedAdjacencyList payload decodes as Pseudograph | Pseudograph decode {"vertices":[0,1],"edges":[0,1,1,1]} | V [0, 1]; E [0–1, 1–1]; rows 0:[1@0] 1:[0@0, 1@1, 1@1] |
| MG-152 | Codable | Pseudograph payload with copies fails as UndirectedAdjacencyList | UndirectedAdjacencyList decode {"vertices":[0,1],"edges":[0,1,1,0]} | dataCorrupted(Repeated edge) |
| MG-153 | Codable | AdjacencyList payload with a loop fails as DirectedMultigraph | DirectedMultigraph decode {"vertices":[0],"edges":[0,0]} | dataCorrupted(Self-loop) |
| MG-154 | Description | description and debugDescription | Pseudograph V [] E [0–1, 0–1, 1–1] | [0, 1]; [0–1, 0–1, 1–1] ‖ Pseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [0, 1], edges: [0–1, 0–1, 1–1]) |
| MG-155 | Description | description and debugDescription | DirectedPseudograph V [] E [0→1, 0→1, 1→1] | [0, 1]; [0→1, 0→1, 1→1] ‖ DirectedPseudograph<Int>(vertexCount: 2, edgeCount: 3, vertices: [0, 1], edges: [0→1, 0→1, 1→1]) |
| MG-156 | Description | description and debugDescription | Pseudograph V [] E [] | []; [] ‖ Pseudograph<Int>(vertexCount: 0, edgeCount: 0, vertices: [], edges: []) |
| MG-157 | Description | description and debugDescription | Multigraph V ["a"] E ["a"–"b", "b"–"a"] | ["a", "b"]; ["a"–"b", "b"–"a"] ‖ Multigraph<String>(vertexCount: 2, edgeCount: 2, vertices: ["a", "b"], edges: ["a"–"b", "b"–"a"]) |
| MG-158 | Description | description and debugDescription | DirectedMultigraph V [] E [0→1, 1→0] | [0, 1]; [0→1, 1→0] ‖ DirectedMultigraph<Int>(vertexCount: 2, edgeCount: 2, vertices: [0, 1], edges: [0→1, 1→0]) |
| MG-159 | Description | description and debugDescription | Pseudograph V [] E [0–1 × 17] | [0, 1]; [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, …] ‖ Pseudograph<Int>(vertexCount: 2, edgeCount: 17, vertices: [0, 1], edges: [0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, 0–1, …]) |
| MG-160 | Conversion | UndirectedAdjacencyList(g): first copy wins | Pseudograph V [3] E [0–1, 1–0, 1–1, 1–1, 1–2] | V [3, 0, 1, 2]; E [0–1, 1–1, 1–2]; rows 3:[] 0:[1@0] 1:[0@0, 1@1, 1@1, 2@2] 2:[1@2] |
| MG-161 | Conversion | UndirectedAdjacencyList(g): orientation of the first copy | Pseudograph V [] E [1–0, 0–1] | V [1, 0]; E [1–0]; rows 1:[0@0] 0:[1@0] |
| MG-162 | Conversion | UndirectedAdjacencyList(g) after removal | Pseudograph V [] E [0–1, 1–2, 0–1, 2–0] then remove(edgeAt: 0) | V [0, 1, 2]; E [2–0, 1–2, 0–1]; rows 0:[2@0, 1@2] 1:[2@1, 0@2] 2:[0@0, 1@1] |
| MG-163 | Conversion | AdjacencyList(g): first copy wins | DirectedPseudograph V [] E [0→1, 1→0, 0→1, 0→0, 0→0] | V [0, 1]; E [0→1, 1→0, 0→0]; out 0:[1@0, 0@2] 1:[0@1]; in 0:[1@1, 0@2] 1:[0@0] |
| MG-164 | Conversion | UndirectedAdjacencyList(multigraph) | Multigraph V [] E [0–1, 0–1, 2–1] | V [0, 1, 2]; E [0–1, 2–1]; rows 0:[1@0] 1:[0@0, 2@1] 2:[1@1] |
| MG-165 | Conversion | AdjacencyList(directedMultigraph) | DirectedMultigraph V [2] E [0→1, 0→1] | V [2, 0, 1]; E [0→1]; out 0:[1@0]; in 1:[0@0] |
| MG-166 | Conversion | Pseudograph(ual): positions kept, rows by position | UndirectedAdjacencyList E [0–1, 0–2, 0–3, 1–2] then remove(edge: 0–1) = V [0, 1, 2, 3]; E [1–2, 0–2, 0–3]; rows 0:[3@2, 2@1] 1:[2@0] 2:[0@1, 1@0] 3:[0@2] | V [0, 1, 2, 3]; E [1–2, 0–2, 0–3]; rows 0:[2@1, 3@2] 1:[2@0] 2:[1@0, 0@1] 3:[0@2] |
| MG-167 | Conversion | DirectedPseudograph(adjacencyList): positions kept, rows by position | AdjacencyList E [0→1, 1→1, 1→0, 2→1] then remove(edge: 0→1) = V [0, 1, 2]; E [2→1, 1→1, 1→0]; out 1:[1@1, 0@2] 2:[1@0]; in 0:[1@2] 1:[2@0, 1@1] | V [0, 1, 2]; E [2→1, 1→1, 1→0]; out 1:[1@1, 0@2] 2:[1@0]; in 0:[1@2] 1:[2@0, 1@1] |
| MG-168 | Conversion | Multigraph(ual) with a loop is nil | UndirectedAdjacencyList E [0–1, 1–1] | nil |
| MG-169 | Conversion | Multigraph(ual) without loops | UndirectedAdjacencyList E [0–1, 1–2] | V [0, 1, 2]; E [0–1, 1–2]; rows 0:[1@0] 1:[0@0, 2@1] 2:[1@1] |
| MG-170 | Conversion | Multigraph(pseudograph), no loops | Pseudograph E [0–1, 0–1, 1–2] | V [0, 1, 2]; E [0–1, 0–1, 1–2]; rows 0:[1@0, 1@1] 1:[0@0, 0@1, 2@2] 2:[1@2] |
| MG-171 | Conversion | Multigraph(pseudograph) with a loop is nil | Pseudograph E [0–1, 1–1] | nil |
| MG-172 | Conversion | Pseudograph(multigraph): the same value | Multigraph V [7] E [0–1, 0–1] | V [7, 0, 1]; E [0–1, 0–1]; rows 7:[] 0:[1@0, 1@1] 1:[0@0, 0@1] |
| MG-173 | Conversion | Pseudograph(digraph.undirected): opposite arcs become copies | DirectedPseudograph E [0→1, 1→0, 1→1] | V [0, 1]; E [0–1, 1–0, 1–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1, 1@2, 1@2] |
| MG-174 | Conversion | DirectedPseudograph(graph.directed): two arcs per edge, a loop's two arcs | Pseudograph E [0–1, 0–1, 1–1] | V [0, 1]; E [0→1, 1→0, 0→1, 1→0, 1→1, 1→1]; out 0:[1@0, 1@2] 1:[0@1, 0@3, 1@4, 1@5]; in 0:[1@1, 1@3] 1:[0@0, 0@2, 1@4, 1@5] |
| MG-175 | Conversion | DirectedMultigraph(graph.directed) with a loop is nil | Pseudograph E [0–1, 0–1, 1–1] | nil |
| MG-176 | Conversion | DirectedMultigraph(directedPseudograph) with a loop is nil | DirectedPseudograph E [0→1, 0→1, 1→1] | nil |
| MG-177 | Conversion | DirectedPseudograph(directedMultigraph) | DirectedMultigraph E [0→1, 0→1] | V [0, 1]; E [0→1, 0→1]; out 0:[1@0, 1@1]; in 1:[0@0, 0@1] |
| MG-178 | Conversion | Pseudograph(pseudograph) returns it unchanged (rows included) | Pseudograph E [0–1, 1–2, 0–1, 2–2] then remove(edgeAt: 0) | V [0, 1, 2]; E [2–2, 1–2, 0–1]; rows 0:[1@2] 1:[0@2, 2@1] 2:[1@1, 2@0, 2@0] |
| MG-179 | Trap | degree(of:) non-vertex | Pseudograph degree(of: 5) | trap |
| MG-180 | Trap | neighbors(of:) non-vertex | Pseudograph neighbors(of: 5) | trap |
| MG-181 | Trap | incidentEdges(of:) non-vertex | Pseudograph incidentEdges(of: 5) | trap |
| MG-182 | Trap | vertexIndex(of:) non-vertex | Pseudograph vertexIndex(of: 5) | trap |
| MG-183 | Trap | oppositeVertex non-endpoint | Pseudograph oppositeVertex(to: 2, acrossEdgeAt: 0) with E [0–1] | trap |
| MG-184 | Trap | oppositeVertex position out of range | Pseudograph oppositeVertex(to: 0, acrossEdgeAt: 1) with E [0–1] | trap |
| MG-185 | Trap | edges[p] out of range | Pseudograph edges[1] with E [0–1] | trap |
| MG-186 | Trap | source(ofEdgeAt:) out of range | DirectedPseudograph source(ofEdgeAt: 1) with E [0→1] | trap |
| MG-187 | Trap | successors(of:) non-vertex | DirectedPseudograph successors(of: 5) | trap |
| MG-188 | Trap | predecessors(of:) non-vertex | DirectedPseudograph predecessors(of: 5) | trap |
| MG-189 | Trap | inDegree(of:) non-vertex | DirectedPseudograph inDegree(of: 5) | trap |
| MG-190 | Trap | reserveCapacity negative vertices | Pseudograph reserveCapacity(vertexCount: -1, edgeCount: 0) | trap |
| MG-191 | Trap | reserveCapacity negative edges | DirectedMultigraph reserveCapacity(vertexCount: 0, edgeCount: -1) | trap |
| MG-192 | Trap | DirectedMultigraph remove(edgeAt:) out of range | DirectedMultigraph remove(edgeAt: 2) with E [0→1, 0→1] | trap |
