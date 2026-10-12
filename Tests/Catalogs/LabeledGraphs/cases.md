# LabeledGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3
Tests/Catalogs/LabeledGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the random
sequences). Every state is checked against a NetworkX spec keyed by label, NetworkX's
`convert_node_labels_to_integers` / `relabel_nodes` round trip, and the protocol laws.

Conventions:

* `CSR V [...]; E [...]` is `LabeledGraph<String, CompressedSparseRow>(vertices: V, edges: E)`; `M` is
  the same with `Base == AdjacencyMatrix`; `U` is `LabeledGraph<String, AdjacencyMatrix>(vertices: V, edges: E)
  .undirected`, an `UndirectedView` over the labeled graph (no `Graph` conformance of its own in phase 1).
  Calls follow, separated by `/`.
* Expected lists each call's result, then `⇒` and the final state. State: `V [l#i, …]` is `vertices` with
  each label's index (`vertexIndex(of:)`, the base vertex it names); `E [p:s→t, …]` is `edges` with the
  base's positions (`Int` for CSR, `(source, target)` for the matrix); `bounds a/b` is `vertexIndexBound` /
  `edgeIndexBound`.
* `hashes()` is the number of label lookups so far (OrderedSet lookups; a `Set` an algorithm returns
  hashes its elements on top of these). It is a benchmark counter, not API: the Swift suite checks it
  with a `Label` whose `hash(into:)` counts.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before
  the trap are listed. `throws E` is a typed throw: from `init(_:labels:)`, a `LabelingError` (no state
  follows); from a `checked:` call on a label that is not a vertex, `VertexNotFound`, changing nothing.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| LG-001 | Construction | CSR: empty | CSR V []; E [] | V []; E []; bounds 0/0 |
| LG-002 | Construction | CSR: isolated vertices in listed order | CSR V [a, b, c]; E [] | V [a#0, b#1, c#2]; E []; bounds 3/0 |
| LG-003 | Construction | CSR: labels in first-appearance order | CSR V []; E [c→a, b→c] | V [c#0, a#1, b#2]; E [0:c→a, 1:b→c]; bounds 3/2 |
| LG-004 | Construction | CSR: listed vertices first, then new endpoints | CSR V [z]; E [x→z, z→y] | V [z#0, x#1, y#2]; E [0:z→y, 1:x→z]; bounds 3/2 |
| LG-005 | Construction | CSR: repeated label and repeated edge stored once | CSR V [a, a, b]; E [a→b, a→b] | V [a#0, b#1]; E [0:a→b]; bounds 2/1 |
| LG-006 | Construction | CSR: self-loop kept | CSR V []; E [a→a, a→b] | V [a#0, b#1]; E [0:a→a, 1:a→b]; bounds 2/2 |
| LG-007 | Construction | M: empty | M V []; E [] | V []; E []; bounds 0/nil |
| LG-008 | Construction | M: isolated vertices in listed order | M V [a, b, c]; E [] | V [a#0, b#1, c#2]; E []; bounds 3/nil |
| LG-009 | Construction | M: labels in first-appearance order | M V []; E [c→a, b→c] | V [c#0, a#1, b#2]; E [(0,1):c→a, (2,0):b→c]; bounds 3/nil |
| LG-010 | Construction | M: listed vertices first, then new endpoints | M V [z]; E [x→z, z→y] | V [z#0, x#1, y#2]; E [(0,2):z→y, (1,0):x→z]; bounds 3/nil |
| LG-011 | Construction | M: repeated label and repeated edge stored once | M V [a, a, b]; E [a→b, a→b] | V [a#0, b#1]; E [(0,1):a→b]; bounds 2/nil |
| LG-012 | Construction | M: self-loop kept | M V []; E [a→a, a→b] | V [a#0, b#1]; E [(0,0):a→a, (0,1):a→b]; bounds 2/nil |
| LG-013 | Construction | CSR: positions are row-major in index order, not input order | CSR V []; E [d→a, b→c, a→d, c→b] | V [d#0, a#1, b#2, c#3]; E [0:d→a, 1:a→d, 2:b→c, 3:c→b]; bounds 4/4 |
| LG-014 | Construction | M: positions are (source, target) cells, row-major | M V []; E [d→a, b→c, a→d, c→b] | V [d#0, a#1, b#2, c#3]; E [(0,1):d→a, (1,0):a→d, (2,3):b→c, (3,2):c→b]; bounds 4/nil |
| LG-015 | Construction | CSR(_ graph:): vertices in graph.vertices order, parallel edges collapsed | CSR(_ DirectedPseudograph(vertices: [p, q, r], edges: [r→p, q→r, r→p])) | V [p#0, q#1, r#2]; E [0:q→r, 1:r→p]; bounds 3/2 |
| LG-016 | Base init | CSR base, labels name indices | LabeledGraph(CompressedSparseRow(vertexCount: 3, edges: [0→1, 1→2]), labels: [x, y, z]) | V [x#0, y#1, z#2]; E [0:x→y, 1:y→z]; bounds 3/2 |
| LG-017 | Base init | matrix base | LabeledGraph(AdjacencyMatrix(vertexCount: 2, edges: [1→0]), labels: [u, v]) | V [u#0, v#1]; E [(1,0):v→u]; bounds 2/nil |
| LG-018 | Base init | too few labels | LabeledGraph(CompressedSparseRow(vertexCount: 3), labels: [x, y]) | throws LabelingError.labelCountMismatch(labelCount: 2, vertexCount: 3) |
| LG-019 | Base init | too many labels | LabeledGraph(CompressedSparseRow(vertexCount: 1), labels: [x, y]) | throws LabelingError.labelCountMismatch(labelCount: 2, vertexCount: 1) |
| LG-020 | Base init | duplicate label | LabeledGraph(CompressedSparseRow(vertexCount: 2), labels: [x, x]) | throws LabelingError.duplicateLabel(position: 1) |
| LG-021 | Base init | base vertices not 0..<n | LabeledGraph(AdjacencyList<Int>(vertices: [5, 6]), labels: [x, y]) | throws LabelingError.baseVerticesNotInIndexOrder |
| LG-022 | Base init | base vertices 0..<n out of index order | LabeledGraph(AdjacencyList<Int>(vertices: [1, 0]), labels: [x, y]) | throws LabelingError.baseVerticesNotInIndexOrder |
| LG-023 | Base init | base with holes (vertexIndexBound nil) | LabeledGraph(StableDirectedGraph<Int> after remove(1) of [0, 1, 2], labels: [x, y]) | throws LabelingError.baseNotDenselyIndexed |
| LG-024 | Base init | empty base, no labels | LabeledGraph(AdjacencyMatrix(), labels: []) | V []; E []; bounds 0/nil |
| LG-025 | Reads | CSR: successors and outEdges in index order | CSR V []; E [a→b, a→c, b→c, c→a] / successors(a) / outEdges(a) / outDegree(a) / successors(b) | [b, c]; [0, 1]; 2; [c] ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:a→c, 2:b→c, 3:c→a]; bounds 3/4 |
| LG-026 | Reads | CSR: contains | CSR V []; E [a→b, a→c, b→c, c→a] / contains(a) / contains(q) / contains(edge: a→b) / contains(edge: b→a) / contains(edge: a→q) / contains(edge: q→q) | true; false; true; false; false; false ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:a→c, 2:b→c, 3:c→a]; bounds 3/4 |
| LG-027 | Reads | CSR: index conversions | CSR V []; E [a→b, a→c, b→c, c→a] / vertexIndex(c) / vertex(atIndex: 1) / vertexIndex(checked: q) / vertexIndex(checked: b) | 2; b; throws VertexNotFound; 1 ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:a→c, 2:b→c, 3:c→a]; bounds 3/4 |
| LG-028 | Reads | CSR: successorIndices(ofIndex:) forwards the base | CSR V []; E [a→b, a→c, b→c, c→a] / successorIndices(ofIndex: 0) / successorIndices(ofIndex: 2) | [1, 2]; [0] ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:a→c, 2:b→c, 3:c→a]; bounds 3/4 |
| LG-029 | Reads | CSR: checked variants | CSR V []; E [a→b, a→c, b→c, c→a] / successors(checked: q) / outEdges(checked: q) / outDegree(checked: q) / successors(checked: c) / outEdges(checked: a) / outDegree(checked: a) | throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; [a]; [0, 1]; 2 ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:a→c, 2:b→c, 3:c→a]; bounds 3/4 |
| LG-030 | Traps | CSR: successors of a non-vertex | CSR V []; E [a→b, a→c, b→c, c→a] / successors(q) | **trap** (q is not a vertex of the graph) |
| LG-031 | Traps | CSR: outDegree of a non-vertex | CSR V []; E [a→b, a→c, b→c, c→a] / outDegree(q) | **trap** (q is not a vertex of the graph) |
| LG-032 | Traps | CSR: vertexIndex of a non-vertex | CSR V []; E [a→b, a→c, b→c, c→a] / vertexIndex(q) | **trap** (q is not a vertex of the graph) |
| LG-033 | Traps | CSR: vertex(atIndex:) out of range | CSR V []; E [a→b, a→c, b→c, c→a] / vertex(atIndex: 3) | **trap** (index 3 out of range) |
| LG-034 | Traps | CSR: vertex(atIndex:) negative | CSR V []; E [a→b, a→c, b→c, c→a] / vertex(atIndex: -1) | **trap** (index -1 out of range) |
| LG-035 | Reads | M: successors and outEdges in index order | M V []; E [a→b, a→c, b→c, c→a] / successors(a) / outEdges(a) / outDegree(a) / successors(b) | [b, c]; [(0,1), (0,2)]; 2; [c] ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-036 | Reads | M: contains | M V []; E [a→b, a→c, b→c, c→a] / contains(a) / contains(q) / contains(edge: a→b) / contains(edge: b→a) / contains(edge: a→q) / contains(edge: q→q) | true; false; true; false; false; false ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-037 | Reads | M: index conversions | M V []; E [a→b, a→c, b→c, c→a] / vertexIndex(c) / vertex(atIndex: 1) / vertexIndex(checked: q) / vertexIndex(checked: b) | 2; b; throws VertexNotFound; 1 ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-038 | Reads | M: successorIndices(ofIndex:) forwards the base | M V []; E [a→b, a→c, b→c, c→a] / successorIndices(ofIndex: 0) / successorIndices(ofIndex: 2) | [1, 2]; [0] ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-039 | Reads | M: checked variants | M V []; E [a→b, a→c, b→c, c→a] / successors(checked: q) / outEdges(checked: q) / outDegree(checked: q) / successors(checked: c) / outEdges(checked: a) / outDegree(checked: a) | throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; [a]; [(0,1), (0,2)]; 2 ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-040 | Traps | M: successors of a non-vertex | M V []; E [a→b, a→c, b→c, c→a] / successors(q) | **trap** (q is not a vertex of the graph) |
| LG-041 | Traps | M: outDegree of a non-vertex | M V []; E [a→b, a→c, b→c, c→a] / outDegree(q) | **trap** (q is not a vertex of the graph) |
| LG-042 | Traps | M: vertexIndex of a non-vertex | M V []; E [a→b, a→c, b→c, c→a] / vertexIndex(q) | **trap** (q is not a vertex of the graph) |
| LG-043 | Traps | M: vertex(atIndex:) out of range | M V []; E [a→b, a→c, b→c, c→a] / vertex(atIndex: 3) | **trap** (index 3 out of range) |
| LG-044 | Traps | M: vertex(atIndex:) negative | M V []; E [a→b, a→c, b→c, c→a] / vertex(atIndex: -1) | **trap** (index -1 out of range) |
| LG-045 | Reads | CSR: edges[p], source, target, edgeIndex | CSR V []; E [a→b, a→c, b→c, c→a] / edges[2] / source(ofEdgeAt: 3) / target(ofEdgeAt: 3) / edgeIndex(of: 1) | b→c; c; a; 1 ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:a→c, 2:b→c, 3:c→a]; bounds 3/4 |
| LG-046 | Traps | CSR: edge position out of range | CSR V []; E [a→b, a→c, b→c, c→a] / source(ofEdgeAt: 4) | **trap** (edge position out of range) |
| LG-047 | Reads | M: edges[p], source, target at a cell position | M V []; E [a→b, a→c, b→c, c→a] / edges[(2,0)] / source(ofEdgeAt: (0,1)) / target(ofEdgeAt: (0,1)) | c→a; a; b ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-048 | Traps | M: edgeIndex (matrix has no edge indices) | M V []; E [a→b, a→c, b→c, c→a] / edgeIndex(of: (0,1)) | **trap** (AdjacencyMatrix has no edge indices; check edgeIndexBound first) |
| LG-049 | Traps | M: edge position that is not an edge | M V []; E [a→b, a→c, b→c, c→a] / source(ofEdgeAt: (1,0)) | **trap** (no edge at position) |
| LG-050 | Reads | M: predecessors, inEdges, degrees | M V []; E [a→b, a→c, b→c, c→a] / predecessors(c) / inEdges(c) / inDegree(c) / degree(c) / predecessorIndices(ofIndex: 2) | [a, b]; [(0,2), (1,2)]; 2; 3; [0, 1] ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-051 | Reads | M: bidirectional checked variants | M V []; E [a→b, a→c, b→c, c→a] / predecessors(checked: q) / inEdges(checked: q) / inDegree(checked: q) / degree(checked: q) / predecessors(checked: c) / inEdges(checked: c) / inDegree(checked: a) / degree(checked: c) | throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; [a, b]; [(0,2), (1,2)]; 1; 3 ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,2):b→c, (2,0):c→a]; bounds 3/nil |
| LG-052 | Traps | M: predecessors of a non-vertex | M V []; E [a→b, a→c, b→c, c→a] / predecessors(q) | **trap** (q is not a vertex of the graph) |
| LG-053 | Reads | M: a self-loop counts in both rows | M V []; E [a→a, a→b] / successors(a) / predecessors(a) / degree(a) | [a, b]; [a]; 3 ⇒ V [a#0, b#1]; E [(0,0):a→a, (0,1):a→b]; bounds 2/nil |
| LG-054 | Boundary | index-space reads do not hash | CSR V []; E [a→b, b→c, c→d, d→e] / successorIndices(ofIndex: 0) / vertex(atIndex: 4) / edges[3] / hashes() | [1]; e; d→e; 0 ⇒ V [a#0, b#1, c#2, d#3, e#4]; E [0:a→b, 1:b→c, 2:c→d, 3:d→e]; bounds 5/4 |
| LG-055 | Boundary | a label-space read hashes once, not per successor | CSR V []; E [a→b, b→c, c→d, d→e] / successors(a) / hashes() | [b]; 1 ⇒ V [a#0, b#1, c#2, d#3, e#4]; E [0:a→b, 1:b→c, 2:c→d, 3:d→e]; bounds 5/4 |
| LG-056 | Boundary | descendants: one lookup, plus one hash per vertex inserted into the returned Set | CSR V []; E [a→b, b→c, c→d, d→e] / descendants(a) / hashes() | {b, c, d, e}; 1 ⇒ V [a#0, b#1, c#2, d#3, e#4]; E [0:a→b, 1:b→c, 2:c→d, 3:d→e]; bounds 5/4 |
| LG-057 | Boundary | topologicalSort hashes nothing | CSR V []; E [a→b, b→c, c→d, d→e] / topologicalSort() / hashes() | [a, b, c, d, e]; 0 ⇒ V [a#0, b#1, c#2, d#3, e#4]; E [0:a→b, 1:b→c, 2:c→d, 3:d→e]; bounds 5/4 |
| LG-058 | Boundary | topologicalSort is the base's, mapped through labels | CSR V []; E [b→a, c→a, c→b] / topologicalSort() | [c, b, a] ⇒ V [b#0, a#1, c#2]; E [0:b→a, 1:c→b, 2:c→a]; bounds 3/3 |
| LG-059 | Boundary | topologicalSort of a cyclic graph | CSR V []; E [a→b, b→a, c→a] / topologicalSort() / descendants(c) | nil; {a, b} ⇒ V [a#0, b#1, c#2]; E [0:a→b, 1:b→a, 2:c→a]; bounds 3/3 |
| LG-060 | Boundary | descendants of an isolated vertex | M V [s]; E [a→b, b→c] / descendants(s) / descendants(a) | {}; {b, c} ⇒ V [s#0, a#1, b#2, c#3]; E [(1,2):a→b, (2,3):b→c]; bounds 4/nil |
| LG-061 | Traps | descendants of a non-vertex | M V [s]; E [a→b, b→c] / descendants(q) | **trap** (q is not a vertex of the graph) |
| LG-062 | Undirected | neighbors are successors then predecessors | U V []; E [a→b, c→a, b→c] / neighbors(a) / incidentEdges(a) / degree(a) / neighborIndices(ofIndex: 0) | [b, c]; [(0,1), (2,0)]; 2; [1, 2] ⇒ V [a#0, b#1, c#2]; E [(0,1):{a,b}, (1,2):{b,c}, (2,0):{c,a}]; bounds 3/nil |
| LG-063 | Undirected | oppositeVertex | U V []; E [a→b, c→a, b→c] / oppositeVertex(to: a, acrossEdgeAt: (0,1)) / oppositeVertex(to: b, acrossEdgeAt: (0,1)) | b; a ⇒ V [a#0, b#1, c#2]; E [(0,1):{a,b}, (1,2):{b,c}, (2,0):{c,a}]; bounds 3/nil |
| LG-064 | Traps | oppositeVertex of a non-endpoint | U V []; E [a→b, c→a, b→c] / oppositeVertex(to: c, acrossEdgeAt: (0,1)) | **trap** (c is not an endpoint of the edge at (0, 1)) |
| LG-065 | Undirected | contains(edge:) either orientation | U V []; E [a→b, c→a, b→c] / contains(edge: b→a) / contains(edge: a→b) / contains(edge: a→q) | true; true; false ⇒ V [a#0, b#1, c#2]; E [(0,1):{a,b}, (1,2):{b,c}, (2,0):{c,a}]; bounds 3/nil |
| LG-066 | Undirected | label-space reads through the view hash twice; index-space reads not at all | U V []; E [a→b, c→a, b→c] / neighbors(b) / hashes() / neighborIndices(ofIndex: 1) / hashes() | [c, a]; 2; [2, 0]; 2 ⇒ V [a#0, b#1, c#2]; E [(0,1):{a,b}, (1,2):{b,c}, (2,0):{c,a}]; bounds 3/nil |
| LG-067 | Traps | neighbors of a non-vertex | U V []; E [a→b, c→a, b→c] / neighbors(q) | **trap** (q is not a vertex of the graph) |
| LG-068 | Undirected | opposite arcs stay parallel; a loop appears twice | U V []; E [a→b, b→a, a→a] / neighbors(a) / degree(a) / degree(b) | [a, b, a, b]; 4; 2 ⇒ V [a#0, b#1]; E [(0,0):{a,a}, (0,1):{a,b}, (1,0):{b,a}]; bounds 2/nil |
| LG-069 | Mutation | insert a new label appends a vertex | M V [a, b]; E [a→b] / insert(c) | (true, c) ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b]; bounds 3/nil |
| LG-070 | Mutation | insert an existing label | M V [a, b]; E [a→b] / insert(a) | (false, a) ⇒ V [a#0, b#1]; E [(0,1):a→b]; bounds 2/nil |
| LG-071 | Mutation | insert(edge:) between existing labels | M V [a, b]; E [a→b] / insert(edge: b→a) | (true, b→a) ⇒ V [a#0, b#1]; E [(0,1):a→b, (1,0):b→a]; bounds 2/nil |
| LG-072 | Mutation | insert(edge:) repeated | M V [a, b]; E [a→b] / insert(edge: a→b) | (false, a→b) ⇒ V [a#0, b#1]; E [(0,1):a→b]; bounds 2/nil |
| LG-073 | Mutation | insert(edge:) inserts missing endpoints, source first | M V [a, b]; E [a→b] / insert(edge: d→c) | (true, d→c) ⇒ V [a#0, b#1, d#2, c#3]; E [(0,1):a→b, (2,3):d→c]; bounds 4/nil |
| LG-074 | Mutation | insert(edge:) self-loop on a new label | M V [a, b]; E [a→b] / insert(edge: z→z) | (true, z→z) ⇒ V [a#0, b#1, z#2]; E [(0,1):a→b, (2,2):z→z]; bounds 3/nil |
| LG-075 | Mutation | insert(checked:) with both endpoints | M V [a, b]; E [a→b] / insert(checked: b→b) | (true, b→b) ⇒ V [a#0, b#1]; E [(0,1):a→b, (1,1):b→b]; bounds 2/nil |
| LG-076 | Mutation | insert(checked:) with a missing endpoint throws, changing nothing | M V [a, b]; E [a→b] / insert(checked: a→q) / insert(checked: q→a) | throws VertexNotFound; throws VertexNotFound ⇒ V [a#0, b#1]; E [(0,1):a→b]; bounds 2/nil |
| LG-077 | Mutation | remove(edge:) | M V [a, b]; E [a→b] / remove(edge: a→b) / remove(edge: a→b) | a→b; nil ⇒ V [a#0, b#1]; E []; bounds 2/nil |
| LG-078 | Mutation | remove(edge:) with a missing endpoint returns nil | M V [a, b]; E [a→b] / remove(edge: a→q) | nil ⇒ V [a#0, b#1]; E [(0,1):a→b]; bounds 2/nil |
| LG-079 | Mutation | removeAllEdges keeps labels | M V [a, b]; E [a→b] / removeAllEdges() | () ⇒ V [a#0, b#1]; E []; bounds 2/nil |
| LG-080 | Mutation | removeAll clears labels and base | M V [a, b]; E [a→b] / removeAll() / insert(b) | (); (true, b) ⇒ V [b#0]; E []; bounds 1/nil |
| LG-081 | Mutation | labels after growth keep their indices | M V [a, b]; E [a→b] / insert(edge: c→a) / insert(d) / vertexIndex(d) / successorIndices(ofIndex: 2) | (true, c→a); (true, d); 3; [0] ⇒ V [a#0, b#1, c#2, d#3]; E [(0,1):a→b, (2,0):c→a]; bounds 4/nil |
| LG-082 | Mutation | removeEdges(from:) clears a row, keeping the vertex | M V [a, b, c]; E [a→b, a→c, b→a, a→a, c→b] / removeEdges(from: a) / removeEdges(from: a) | 3; 0 ⇒ V [a#0, b#1, c#2]; E [(1,0):b→a, (2,1):c→b]; bounds 3/nil |
| LG-083 | Mutation | removeEdges(to:) clears a column, keeping the vertex | M V [a, b, c]; E [a→b, a→c, b→a, a→a, c→b] / removeEdges(to: a) | 2 ⇒ V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (2,1):c→b]; bounds 3/nil |
| LG-084 | Mutation | removeEdges(incidentTo:) clears both, a self-loop counted once | M V [a, b, c]; E [a→b, a→c, b→a, a→a, c→b] / removeEdges(incidentTo: a) / removeEdges(incidentTo: c) | 4; 1 ⇒ V [a#0, b#1, c#2]; E []; bounds 3/nil |
| LG-085 | Builder | CSR: bare labels first, wherever written, then endpoints by first appearance | CSR { c→a; z; b→c; a→c; y } | V [z#0, y#1, c#2, a#3, b#4]; E [0:c→a, 1:a→c, 2:b→c]; bounds 5/3 |
| LG-086 | Builder | M: bare labels first, wherever written, then endpoints by first appearance | M { c→a; z; b→c; a→c; y } | V [z#0, y#1, c#2, a#3, b#4]; E [(2,3):c→a, (3,2):a→c, (4,2):b→c]; bounds 5/nil |
| LG-087 | Transpose | CSR: every edge reversed, the same labels at the same indices, no hash | CSR V [s]; E [a→b, a→c, b→c, c→a] / transposed() / hashes() | (); 0 ⇒ V [s#0, a#1, b#2, c#3]; E [0:a→c, 1:b→a, 2:c→a, 3:c→b]; bounds 4/4 |
| LG-088 | Transpose | CSR: a self-loop stays, opposite arcs swap rows | CSR V []; E [a→a, a→b, b→a] / transposed() / successors(a) / successors(b) / transposed() | (); [a, b]; [a]; () ⇒ V [a#0, b#1]; E [0:a→a, 1:a→b, 2:b→a]; bounds 2/3 |
| LG-089 | Equality | same labels, same order | CSR V []; E [a→b] == CSR V [a, b]; E [a→b] | true |
| LG-090 | Equality | same labeled graph, different index assignment | CSR V [b, a]; E [a→b] == CSR V [a, b]; E [a→b] | true |
| LG-091 | Equality | different label sets | CSR V [a, b]; E [] == CSR V [a, c]; E [] | false |
| LG-092 | Equality | different edges | CSR V []; E [a→b] == CSR V []; E [b→a] | false |
| LG-093 | Equality | matrix, different index assignment | M V [c]; E [a→c, c→a] == M V [a]; E [c→a, a→c] | true |
| LG-094 | Hashing | same labeled graph, different index assignment | Set([CSR V [c, b, a]; E [a→b, b→c], CSR V [b]; E [b→c, a→b]]).count | 1 |
| LG-095 | Hashing | matrix, opposite arcs, different index assignment | Set([M V [b]; E [a→b, b→a, a→a], M V [a]; E [b→a, a→b, a→a]]).count | 1 |
| LG-096 | Hashing | different edges | Set([CSR V [a, b]; E [a→b], CSR V [a, b]; E [b→a]]).count | 2 |
| LG-097 | Mutation | removeEdges(checkedFrom:) / (checkedTo:) / (checkedIncidentTo:) as the trapping ones | M V [a, b, c]; E [a→b, a→c, b→a, a→a, c→b] / removeEdges(checkedFrom: b) / removeEdges(checkedTo: b) / removeEdges(checkedIncidentTo: c) | 1; 2; 1 ⇒ V [a#0, b#1, c#2]; E [(0,0):a→a]; bounds 3/nil |
| LG-098 | Mutation | removeEdges(checkedFrom:) / (checkedTo:) / (checkedIncidentTo:) of a missing label throw, changing nothing | M V [a, b, c]; E [a→b, a→c, b→a, a→a, c→b] / removeEdges(checkedFrom: q) / removeEdges(checkedTo: q) / removeEdges(checkedIncidentTo: q) | throws VertexNotFound; throws VertexNotFound; throws VertexNotFound ⇒ V [a#0, b#1, c#2]; E [(0,0):a→a, (0,1):a→b, (0,2):a→c, (1,0):b→a, (2,1):c→b]; bounds 3/nil |
