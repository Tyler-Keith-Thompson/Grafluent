# StableGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1
python3 Tests/Catalogs/StableGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the random
sequences). Every Expected is the output of a port of the proposed storage, checked at every state
against a plain specification model and the DirectedGraph / BidirectionalDirectedGraph laws.

Conventions:

* Input `V [...]; E [...]` is `StableDirectedGraph(vertices: V, edges: E)`; calls follow, separated by `/`.
  Expected lists each call's result, then `⇒` and the final state.
* State: `V [v#k, …] end n` is `vertices` with each vertex's position `k` (its index in
  `vertices`), and `n` is `vertices.endIndex`; `E [p:u→v, …] end m` is `edges` with positions and
  `edges.endIndex`; `bounds a/b` is `vertexIndexBound` / `edgeIndexBound`; `out` / `in` are
  `successors` / `predecessors` zipped with `outEdges` / `inEdges` (`w@p`), empty rows omitted.
* Positions are never reused: a new vertex or edge always gets the current `endIndex`, so every
  order (vertices, edges, each out- and in-row) is position order, which is insertion order.
  Only `removeAll()` and `removeAllEdges()` reset an `endIndex`.
* `degrees(v)` is `outDegree`, `inDegree`, `degree`.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before
  the trap are listed.
* Codable payloads are `{vertices, vertexPositions, vertexEnd, edges, edgePositions, edgeEnd}`;
  `edges` are index pairs into `vertices`. Errors are `DecodingError` cases with their debug description.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| SG-001 | Construction | empty | V []; E [] | V [] end 0; E [] end 0; bounds 0/0; out -; in - |
| SG-002 | Construction | isolated vertices, repeat inserted once | V [0, 1, 1, 2]; E [] | V [0#0, 1#1, 2#2] end 3; E [] end 0; bounds 3/0; out -; in - |
| SG-003 | Construction | endpoints in first-appearance order | V []; E [2→0, 1→2] | V [2#0, 0#1, 1#2] end 3; E [0:2→0, 1:1→2] end 2; bounds 3/2; out 2:[0@0] 1:[2@1]; in 2:[1@1] 0:[2@0] |
| SG-004 | Construction | listed vertices first, then new endpoints | V [5]; E [3→5, 5→4] | V [5#0, 3#1, 4#2] end 3; E [0:3→5, 1:5→4] end 2; bounds 3/2; out 5:[4@1] 3:[5@0]; in 5:[3@0] 4:[5@1] |
| SG-005 | Construction | parallel copies and self-loops kept | V []; E [0→1, 0→1, 1→1, 1→0] | V [0#0, 1#1] end 2; E [0:0→1, 1:0→1, 2:1→1, 3:1→0] end 4; bounds 2/4; out 0:[1@0, 1@1] 1:[1@2, 0@3]; in 0:[1@3] 1:[0@0, 0@1, 1@2] |
| SG-006 | Construction | string vertices | V ["a", "b"]; E ["a"→"b", "b"→"c"] | V ["a"#0, "b"#1, "c"#2] end 3; E [0:"a"→"b", 1:"b"→"c"] end 2; bounds 3/2; out "a":["b"@0] "b":["c"@1]; in "b":["a"@0] "c":["b"@1] |
| SG-007 | Insertion | insert(_:) returns inserted and member | V [0]; E [] / insert(1) / insert(0) | (true, 1); (false, 0) ⇒ V [0#0, 1#1] end 2; E [] end 0; bounds 2/0; out -; in - |
| SG-008 | Insertion | insert(edge:) returns edges.endIndex | V [0, 1]; E [0→1] / insert(edge: 1→0) / insert(edge: 0→1) | 1; 2 ⇒ V [0#0, 1#1] end 2; E [0:0→1, 1:1→0, 2:0→1] end 3; bounds 2/3; out 0:[1@0, 1@2] 1:[0@1]; in 0:[1@1] 1:[0@0, 0@2] |
| SG-009 | Insertion | insert(edge:) inserts missing endpoints | V []; E [] / insert(edge: 7→8) / insert(edge: 8→9) | 0; 1 ⇒ V [7#0, 8#1, 9#2] end 3; E [0:7→8, 1:8→9] end 2; bounds 3/2; out 7:[8@0] 8:[9@1]; in 8:[7@0] 9:[8@1] |
| SG-010 | Insertion | self-loop: once in out-row, once in in-row | V [0]; E [] / insert(edge: 0→0) / degrees(0) | 0; [1, 1, 2] ⇒ V [0#0] end 1; E [0:0→0] end 1; bounds 1/1; out 0:[0@0]; in 0:[0@0] |
| SG-011 | Edge removal | remove(edgeAt:) leaves a hole; no move | V [0, 1, 2]; E [0→1, 0→2, 1→2] / remove(edgeAt: 0) | 0→1 ⇒ V [0#0, 1#1, 2#2] end 3; E [1:0→2, 2:1→2] end 3; bounds 3/nil; out 0:[2@1] 1:[2@2]; in 2:[0@1, 1@2] |
| SG-012 | Edge removal | middle hole keeps both neighbours' positions | V [0, 1, 2]; E [0→1, 0→2, 0→1] / remove(edgeAt: 1) | 0→2 ⇒ V [0#0, 1#1, 2#2] end 3; E [0:0→1, 2:0→1] end 3; bounds 3/nil; out 0:[1@0, 1@2]; in 1:[0@0, 0@2] |
| SG-013 | Edge removal | last position removed: end stays | V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 1) | 1→0 ⇒ V [0#0, 1#1] end 2; E [0:0→1] end 2; bounds 2/nil; out 0:[1@0]; in 1:[0@0] |
| SG-014 | Edge removal | new edge after a hole gets a fresh position | V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) / insert(edge: 1→1) | 0→1; 2 ⇒ V [0#0, 1#1] end 2; E [1:1→0, 2:1→1] end 3; bounds 2/nil; out 1:[0@1, 1@2]; in 0:[1@1] 1:[1@2] |
| SG-015 | Edge removal | removed position never returns | V [0, 1]; E [0→1] / remove(edgeAt: 0) / insert(edge: 0→1) / remove(edgeAt: 1) / insert(edge: 0→1) | 0→1; 1; 0→1; 2 ⇒ V [0#0, 1#1] end 2; E [2:0→1] end 3; bounds 2/nil; out 0:[1@2]; in 1:[0@2] |
| SG-016 | Edge removal | remove(edge:) removes the newest copy | V [0, 1]; E [0→1, 1→0, 0→1] / remove(edge: 0→1) | 0→1 ⇒ V [0#0, 1#1] end 2; E [0:0→1, 1:1→0] end 3; bounds 2/nil; out 0:[1@0] 1:[0@1]; in 0:[1@1] 1:[0@0] |
| SG-017 | Edge removal | remove(edge:) twice | V [0, 1]; E [0→1, 0→1, 0→1] / remove(edge: 0→1) / remove(edge: 0→1) | 0→1; 0→1 ⇒ V [0#0, 1#1] end 2; E [0:0→1] end 3; bounds 2/nil; out 0:[1@0]; in 1:[0@0] |
| SG-018 | Edge removal | remove(edge:) absent copy: nil | V [0, 1]; E [0→1] / remove(edge: 1→0) | nil ⇒ V [0#0, 1#1] end 2; E [0:0→1] end 1; bounds 2/1; out 0:[1@0]; in 1:[0@0] |
| SG-019 | Edge removal | remove(edge:) non-vertex: nil, no insert | V [0]; E [] / remove(edge: 0→9) | nil ⇒ V [0#0] end 1; E [] end 0; bounds 1/0; out -; in - |
| SG-020 | Edge removal | remove(edge:) self-loop | V [0]; E [0→0, 0→0] / remove(edge: 0→0) | 0→0 ⇒ V [0#0] end 1; E [0:0→0] end 2; bounds 1/nil; out 0:[0@0]; in 0:[0@0] |
| SG-021 | Edge removal | removeAllEdges(from:to:) keeps reverse copies | V [0, 1]; E [0→1, 1→0, 0→1, 0→0] / removeAllEdges(from: 0, to: 1) | 2 ⇒ V [0#0, 1#1] end 2; E [1:1→0, 3:0→0] end 4; bounds 2/nil; out 0:[0@3] 1:[0@1]; in 0:[1@1, 0@3] |
| SG-022 | Edge removal | removeAllEdges(from:to:) none: 0 | V [0, 1]; E [0→1] / removeAllEdges(from: 1, to: 0) / removeAllEdges(from: 3, to: 4) | 0; 0 ⇒ V [0#0, 1#1] end 2; E [0:0→1] end 1; bounds 2/1; out 0:[1@0]; in 1:[0@0] |
| SG-023 | Edge removal | row order kept across removals | V [0, 1, 2, 3]; E [0→1, 0→2, 0→3, 0→1, 0→2] / remove(edgeAt: 1) / remove(edgeAt: 3) / insert(edge: 0→3) | 0→2; 0→1; 5 ⇒ V [0#0, 1#1, 2#2, 3#3] end 4; E [0:0→1, 2:0→3, 4:0→2, 5:0→3] end 6; bounds 4/nil; out 0:[1@0, 3@2, 2@4, 3@5]; in 1:[0@0] 2:[0@4] 3:[0@2, 0@5] |
| SG-024 | Edge removal | in-row order kept across removals | V [0, 1, 2, 3]; E [1→0, 2→0, 3→0, 1→0] / remove(edgeAt: 0) / insert(edge: 2→0) | 1→0; 4 ⇒ V [0#0, 1#1, 2#2, 3#3] end 4; E [1:2→0, 2:3→0, 3:1→0, 4:2→0] end 5; bounds 4/nil; out 1:[0@3] 2:[0@1, 0@4] 3:[0@2]; in 0:[2@1, 3@2, 1@3, 2@4] |
| SG-025 | Edge removal | remove every edge one by one: bounds stay nil | V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) / remove(edgeAt: 1) | 0→1; 1→0 ⇒ V [0#0, 1#1] end 2; E [] end 2; bounds 2/nil; out -; in - |
| SG-026 | Vertex removal | isolated vertex: vertex hole | V [0, 1, 2]; E [] / remove(1) | 1 ⇒ V [0#0, 2#2] end 3; E [] end 0; bounds nil/0; out -; in - |
| SG-027 | Vertex removal | vertex with edges: its edges become holes | V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2] / remove(1) | 1 ⇒ V [0#0, 2#2] end 3; E [2:2→0, 3:0→2] end 4; bounds nil/nil; out 0:[2@3] 2:[0@2]; in 0:[2@2] 2:[0@3] |
| SG-028 | Vertex removal | self-loops and copies at the vertex | V [0, 1]; E [0→0, 0→1, 1→0, 0→0, 1→1] / remove(0) | 0 ⇒ V [1#1] end 2; E [4:1→1] end 5; bounds nil/nil; out 1:[1@4]; in 1:[1@4] |
| SG-029 | Vertex removal | absent: nil | V [0]; E [] / remove(5) | nil ⇒ V [0#0] end 1; E [] end 0; bounds 1/0; out -; in - |
| SG-030 | Vertex removal | re-inserted vertex goes last (insertion order) | V [0, 1, 2]; E [] / remove(0) / insert(0) | 0; (true, 0) ⇒ V [1#1, 2#2, 0#3] end 4; E [] end 0; bounds nil/0; out -; in - |
| SG-031 | Vertex removal | re-inserted vertex gets a fresh position | V [0, 1, 2]; E [0→1] / remove(1) / insert(1) / insert(edge: 0→1) | 1; (true, 1); 1 ⇒ V [0#0, 2#2, 1#3] end 4; E [1:0→1] end 2; bounds nil/nil; out 0:[1@1]; in 1:[0@1] |
| SG-032 | Vertex removal | insert(edge:) re-creates a removed endpoint at the end | V [0, 1, 2]; E [0→1] / remove(0) / insert(edge: 0→2) | 0; 1 ⇒ V [1#1, 2#2, 0#3] end 4; E [1:0→2] end 2; bounds nil/nil; out 0:[2@1]; in 2:[0@1] |
| SG-033 | Vertex removal | remove all vertices: empty, ends kept | V [0, 1]; E [0→1] / remove(0) / remove(1) | 0; 1 ⇒ V [] end 2; E [] end 1; bounds nil/nil; out -; in - |
| SG-034 | Vertex removal | neighbours' rows keep order | V [0, 1, 2, 3]; E [0→1, 0→2, 0→3, 2→0, 3→0] / remove(2) | 2 ⇒ V [0#0, 1#1, 3#3] end 4; E [0:0→1, 2:0→3, 4:3→0] end 5; bounds nil/nil; out 0:[1@0, 3@2] 3:[0@4]; in 0:[3@4] 1:[0@0] 3:[0@2] |
| SG-035 | Interleaving | insert/remove/insert edges and vertices | V [0, 1, 2]; E [0→1, 1→2] / insert(edge: 2→0) / remove(1) / insert(3) / insert(edge: 3→0) / remove(edgeAt: 2) / insert(edge: 0→0) | 2; 1; (true, 3); 3; 2→0; 4 ⇒ V [0#0, 2#2, 3#3] end 4; E [3:3→0, 4:0→0] end 5; bounds nil/nil; out 0:[0@4] 3:[0@3]; in 0:[3@3, 0@4] |
| SG-036 | Interleaving | churn on one pair | V [0, 1]; E [] / insert(edge: 0→1) / insert(edge: 0→1) / remove(edge: 0→1) / insert(edge: 0→1) / remove(edgeAt: 0) / insert(edge: 1→0) | 0; 1; 0→1; 2; 0→1; 3 ⇒ V [0#0, 1#1] end 2; E [2:0→1, 3:1→0] end 4; bounds 2/nil; out 0:[1@2] 1:[0@3]; in 0:[1@3] 1:[0@2] |
| SG-037 | Interleaving | remove and re-add the same vertex twice | V [0, 1]; E [0→1] / remove(1) / insert(edge: 0→1) / remove(1) / insert(edge: 1→0) | 1; 1; 1; 2 ⇒ V [0#0, 1#3] end 4; E [2:1→0] end 3; bounds nil/nil; out 1:[0@2]; in 0:[1@2] |
| SG-038 | Interleaving | FlowNavigation: replace a screen keeps others' edge ids | V ["root", "a", "b"]; E ["root"→"a", "root"→"b", "a"→"b"] / remove("a") / insert(edge: "root"→"c") / insert(edge: "c"→"b") / outEdges(of: "root") | "a"; 3; 4; [1, 3] ⇒ V ["root"#0, "b"#2, "c"#3] end 4; E [1:"root"→"b", 3:"root"→"c", 4:"c"→"b"] end 5; bounds nil/nil; out "root":["b"@1, "c"@3] "c":["b"@4]; in "b":["root"@1, "c"@4] "c":["root"@3] |
| SG-039 | Interleaving | removeAllEdges() resets edge positions | V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) / removeAllEdges() / insert(edge: 1→0) | 0→1; nil; 0 ⇒ V [0#0, 1#1] end 2; E [0:1→0] end 1; bounds 2/1; out 1:[0@0]; in 0:[1@0] (the one way an edge position comes back; see open question 4) |
| SG-040 | Interleaving | removeAll() resets both | V [0, 1]; E [0→1] / remove(0) / removeAll() / insert(edge: 5→6) | 0; nil; 0 ⇒ V [5#0, 6#1] end 2; E [0:5→6] end 1; bounds 2/1; out 5:[6@0]; in 6:[5@0] |
| SG-041 | Queries | successors/outEdges/inEdges in insertion order | V [0, 1, 2]; E [0→2, 0→1, 2→0, 0→2] / successors(of: 0) / outEdges(of: 0) / inEdges(of: 2) | [2, 1, 2]; [0, 1, 3]; [0, 3] ⇒ V [0#0, 1#1, 2#2] end 3; E [0:0→2, 1:0→1, 2:2→0, 3:0→2] end 4; bounds 3/4; out 0:[2@0, 1@1, 2@3] 2:[0@2]; in 0:[2@2] 1:[0@1] 2:[0@0, 0@3] |
| SG-042 | Queries | edges(from:to:) oldest first, skips holes | V [0, 1]; E [0→1, 0→1, 1→0, 0→1] / remove(edgeAt: 1) / edges(from: 0, to: 1) | 0→1; [0, 3] ⇒ V [0#0, 1#1] end 2; E [0:0→1, 2:1→0, 3:0→1] end 4; bounds 2/nil; out 0:[1@0, 1@3] 1:[0@2]; in 0:[1@2] 1:[0@0, 0@3] |
| SG-043 | Queries | edges(from:to:) non-vertex: empty | V [0]; E [] / edges(from: 0, to: 9) | [] ⇒ V [0#0] end 1; E [] end 0; bounds 1/0; out -; in - |
| SG-044 | Queries | contains / contains(edge:) after removal | V [0, 1]; E [0→1] / remove(edgeAt: 0) / contains(edge: 0→1) / remove(1) / contains(1) / contains(edge: 0→1) | 0→1; false; 1; false; false ⇒ V [0#0] end 2; E [] end 1; bounds nil/nil; out -; in - |
| SG-045 | Queries | degrees after removals | V [0, 1, 2]; E [0→1, 1→0, 0→0, 2→0] / remove(edgeAt: 1) / degrees(0) | 1→0; [2, 2, 4] ⇒ V [0#0, 1#1, 2#2] end 3; E [0:0→1, 2:0→0, 3:2→0] end 4; bounds 3/nil; out 0:[1@0, 0@2] 2:[0@3]; in 0:[0@2, 2@3] 1:[0@0] |
| SG-046 | Queries | edges.indices.contains: live, hole, past end | V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0) / edges.indices.contains(0) / edges.indices.contains(1) / edges.indices.contains(2) / edges.indices.contains(-1) | 0→1; false; true; false; false ⇒ V [0#0, 1#1] end 2; E [1:0→1] end 2; bounds 2/nil; out 0:[1@1]; in 1:[0@1] |
| SG-047 | Queries | vertices.indices.contains: live, hole | V [0, 1]; E [] / remove(0) / vertices.indices.contains(0) / vertices.indices.contains(1) | 0; false; true ⇒ V [1#1] end 2; E [] end 0; bounds nil/0; out -; in - |
| SG-048 | Queries | vertices[p] and edges[p] at live positions | V [0, 1, 2]; E [0→1, 1→2] / remove(0) / vertices[1] / edges[1] | 0; 1; 1→2 ⇒ V [1#1, 2#2] end 3; E [1:1→2] end 2; bounds nil/nil; out 1:[2@1]; in 2:[1@1] |
| SG-049 | Queries | source(ofEdgeAt:) live | V [0, 1]; E [1→0] / source(ofEdgeAt: 0) | 1 ⇒ V [0#0, 1#1] end 2; E [0:1→0] end 1; bounds 2/1; out 1:[0@0]; in 0:[1@0] |
| SG-050 | Traps | successors(of:) non-vertex | V [0]; E [] / successors(of: 9) | **trap** |
| SG-051 | Traps | outEdges(of:) removed vertex | V [0, 1]; E [0→1] / remove(0) / outEdges(of: 0) | 0; **trap** |
| SG-052 | Traps | inEdges(of:) non-vertex | V [0]; E [] / inEdges(of: 9) | **trap** |
| SG-053 | Traps | remove(edgeAt:) hole | V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0) / remove(edgeAt: 0) | 0→1; **trap** |
| SG-054 | Traps | remove(edgeAt:) past end | V [0, 1]; E [0→1] / remove(edgeAt: 1) | **trap** |
| SG-055 | Traps | remove(edgeAt:) negative | V [0, 1]; E [0→1] / remove(edgeAt: -1) | **trap** |
| SG-056 | Traps | source(ofEdgeAt:) hole | V [0, 1]; E [0→1] / remove(edgeAt: 0) / source(ofEdgeAt: 0) | 0→1; **trap** |
| SG-057 | Traps | edges[p] hole | V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) / edges[0] | 0→1; **trap** |
| SG-058 | Traps | vertices[p] hole | V [0, 1]; E [] / remove(0) / vertices[0] | 0; **trap** |
| SG-059 | Traps | vertex(atIndex:) with vertex holes | V [0, 1, 2]; E [] / vertex(atIndex: 2) / remove(0) / vertex(atIndex: 0) | 2; 0; **trap** |
| SG-060 | Traps | vertexIndex(of:) with vertex holes | V [0, 1]; E [] / vertexIndex(of: 1) / remove(0) / vertexIndex(of: 1) | 1; 0; **trap** |
| SG-061 | Traps | edgeIndex(of:) with edge holes | V [0, 1]; E [0→1, 1→0] / edgeIndex(of: 1) / remove(edgeAt: 0) / edgeIndex(of: 1) | 1; 0→1; **trap** |
| SG-062 | Conformance | edge removal alone keeps vertex indices | V [0, 1]; E [0→1] / remove(edgeAt: 0) / vertexIndex(of: 1) / edgeIndex(of: 0) | 0→1; 1; **trap** |
| SG-063 | Traps | vertex(atIndex:) past bound | V [0, 1]; E [] / vertex(atIndex: 2) | **trap** |
| SG-064 | Traps | index(after:) at endIndex | V [0]; E [0→0] / edges.index(after: edges.endIndex) | **trap** |
| SG-065 | Traps | reserveCapacity negative | V []; E [] / reserveCapacity(vertexCount: -1, edgeCount: 0) | **trap** |
| SG-066 | Conformance | no holes: dense indices, slot = index | V [0, 1, 2]; E [0→1, 2→1] / vertexIndex(of: 2) / vertex(atIndex: 1) / edgeIndex(of: 1) | 2; 1; 1 ⇒ V [0#0, 1#1, 2#2] end 3; E [0:0→1, 1:2→1] end 2; bounds 3/2; out 0:[1@0] 2:[1@1]; in 1:[0@0, 2@1] |
| SG-067 | Conformance | vertex hole: vertexIndexBound nil, edges still indexed | V [0, 1, 2]; E [0→1] / remove(2) | 2 ⇒ V [0#0, 1#1] end 3; E [0:0→1] end 1; bounds nil/1; out 0:[1@0]; in 1:[0@0] |
| SG-068 | Conformance | edge hole only: edgeIndexBound nil, vertices indexed | V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) | 0→1 ⇒ V [0#0, 1#1] end 2; E [1:1→0] end 2; bounds 2/nil; out 1:[0@1]; in 0:[1@1] |
| SG-069 | Conformance | vertex numbering with holes: live vertices 0..<n in order | V [0, 1, 2, 3]; E [] / remove(1) / insert(1) / vertex numbering | 1; (true, 1); [0, 2, 3, 1] ⇒ V [0#0, 2#2, 3#3, 1#4] end 5; E [] end 0; bounds nil/0; out -; in - (what _listedVertices / _VertexIdentifiers produce when vertexIndexBound is nil) |
| SG-070 | Conformance | BFS follows outEdges order across removals | V [0, 1, 2, 3]; E [0→3, 0→1, 0→2, 1→2, 3→2] / remove(edgeAt: 0) / insert(edge: 0→3) / breadthFirstSearch(from: 0) | 0→3; 5; [0, 1, 2, 3] ⇒ V [0#0, 1#1, 2#2, 3#3] end 4; E [1:0→1, 2:0→2, 3:1→2, 4:3→2, 5:0→3] end 6; bounds 4/nil; out 0:[1@1, 2@2, 3@5] 1:[2@3] 3:[2@4]; in 1:[0@1] 2:[0@2, 1@3, 3@4] 3:[0@5] |
| SG-071 | Conformance | BFS after vertex removal | V [0, 1, 2, 3]; E [0→1, 1→2, 0→3, 3→2] / remove(1) / breadthFirstSearch(from: 0) | 1; [0, 3, 2] ⇒ V [0#0, 2#2, 3#3] end 4; E [2:0→3, 3:3→2] end 4; bounds nil/nil; out 0:[3@2] 3:[2@3]; in 2:[3@3] 3:[0@2] |
| SG-072 | Conformance | compacting conversion to DirectedPseudograph | V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2] / remove(1) / insert(edge: 2→2) / DirectedPseudograph(g) | 1; 4; V [0, 2]; E [0:2→0, 1:0→2, 2:2→2] (from [2, 3, 4]) ⇒ V [0#0, 2#2] end 3; E [2:2→0, 3:0→2, 4:2→2] end 5; bounds nil/nil; out 0:[2@3] 2:[0@2, 2@4]; in 0:[2@2] 2:[0@3, 2@4] |
| SG-073 | Conformance | compacting conversion without holes is positional | V [0, 1]; E [0→1, 1→1] / DirectedPseudograph(g) | V [0, 1]; E [0:0→1, 1:1→1] (from [0, 1]) ⇒ V [0#0, 1#1] end 2; E [0:0→1, 1:1→1] end 2; bounds 2/2; out 0:[1@0] 1:[1@1]; in 1:[0@0, 1@1] |
| SG-074 | Conformance | init(_:) from DirectedPseudograph | StableDirectedGraph(DirectedPseudograph(V [2, 0]; E [2→0, 0→0, 2→0])) | V [2#0, 0#1] end 2; E [0:2→0, 1:0→0, 2:2→0] end 3; bounds 2/3; out 2:[0@0, 0@2] 0:[0@1]; in 0:[2@0, 0@1, 2@2] |
| SG-075 | Conformance | init(_:) from a StableDirectedGraph keeps holes | StableDirectedGraph(g) where g = V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) | V [0#0, 1#1] end 2; E [1:1→0] end 2; bounds 2/nil; out 1:[0@1]; in 0:[1@1] |
| SG-076 | Conformance | undirected view keeps positions and nil bounds | (V [0, 1, 2]; E [0→1, 1→2] / remove(edgeAt: 0)).undirected | edges [1:1–2]; incidentEdges(of: 1) [1]; incidentEdges(of: 0) []; vertexIndexBound 3; edgeIndexBound nil |
| SG-077 | Conformance | algorithms on a holed graph match the compacted copy | for each of stronglyConnectedComponents, topologicalSort, shortestPaths (weights by position): on g and on DirectedPseudograph(g) | equal results, edge positions mapped through the conversion's position list |
| SG-078 | Equality and hashing | positions do not matter | V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0)  ==  V [0, 1]; E [0→1] | true; equal hashes |
| SG-079 | Equality and hashing | vertex holes do not matter | V [9, 0]; E [] / remove(9) / insert(1)  ==  V [0, 1]; E [] | true |
| SG-080 | Equality and hashing | copies count | V [0, 1]; E [0→1, 0→1]  ==  V [0, 1]; E [0→1] | false |
| SG-081 | Equality and hashing | orientation counts | V [0, 1]; E [0→1]  ==  V [0, 1]; E [1→0] | false |
| SG-082 | Codable | encode keeps positions and ends | V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→0] / remove(1) / insert(3) | {"vertices":[0,2,3],"vertexPositions":[0,2,3],"vertexEnd":4,"edges":[1,0,0,0],"edgePositions":[2,3],"edgeEnd":4} |
| SG-083 | Codable | round trip keeps the next fresh positions | decode(encode(g)) for the graph above / insert(4) / insert(edge: 4→0) | V [0#0, 2#2, 3#3, 4#4] end 5; E [2:2→0, 3:0→0, 4:4→0] end 5; bounds nil/nil; out 0:[0@3] 2:[0@2] 4:[0@4]; in 0:[2@2, 0@3, 4@4] |
| SG-084 | Codable | empty | V []; E [] | {"vertices":[],"vertexPositions":[],"vertexEnd":0,"edges":[],"edgePositions":[],"edgeEnd":0} |
| SG-085 | Codable | all holes round trip | V [0]; E [0→0, 0→0] / remove(edgeAt: 0) / remove(edgeAt: 1) / remove(0) | {"vertices":[],"vertexPositions":[],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":2} ⇒ V [] end 1; E [] end 2; bounds nil/nil; out -; in - |
| SG-086 | Codable | odd edge list | {"vertices":[0,1],"vertexPositions":[0,1],"vertexEnd":2,"edges":[0],"edgePositions":[0],"edgeEnd":1} | dataCorrupted(edges): Edge list has odd length |
| SG-087 | Codable | repeated vertex | {"vertices":[0,0],"vertexPositions":[0,1],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0} | dataCorrupted(vertices): Repeated vertex |
| SG-088 | Codable | vertex positions count | {"vertices":[0,1],"vertexPositions":[0],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0} | dataCorrupted(vertexPositions): Count differs from vertices |
| SG-089 | Codable | vertex positions not increasing | {"vertices":[0,1],"vertexPositions":[1,0],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0} | dataCorrupted(vertexPositions): Positions not increasing within vertexEnd |
| SG-090 | Codable | vertex position past end | {"vertices":[0],"vertexPositions":[3],"vertexEnd":3,"edges":[],"edgePositions":[],"edgeEnd":0} | dataCorrupted(vertexPositions): Positions not increasing within vertexEnd |
| SG-091 | Codable | edge endpoint out of range | {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,1],"edgePositions":[0],"edgeEnd":1} | dataCorrupted(edges): Edge endpoint out of range |
| SG-092 | Codable | edge positions count | {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[],"edgeEnd":1} | dataCorrupted(edgePositions): Count differs from edges |
| SG-093 | Codable | edge positions repeated | {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0,0,0],"edgePositions":[1,1],"edgeEnd":2} | dataCorrupted(edgePositions): Positions not increasing within edgeEnd |
| SG-094 | Codable | edge position past end | {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[2],"edgeEnd":2} | dataCorrupted(edgePositions): Positions not increasing within edgeEnd |
| SG-095 | Description | description lists live vertices and edges | V [0, 1, 2]; E [0→1, 1→2] / remove(edgeAt: 0) | [0, 1, 2]; [1→2] |
| SG-096 | Description | debugDescription | V [0, 1]; E [0→1] / remove(0) | StableDirectedGraph<Int>(vertexCount: 1, edgeCount: 0, vertices: [1], edges: []) |
| SG-097 | Edge removal | removeAllEdges(from:where:) sees only the vertex's out-row, oldest first | V [0, 1, 2]; E [0→1, 0→2, 1→2, 0→1, 0→0] / removeAllEdges(from: 0, where: { [0, 2, 3, 4].contains($0) }) / remove(edgeAt: 1) / insert(edge: 0→2) | 3; 0→2; 5 ⇒ V [0#0, 1#1, 2#2] end 3; E [2:1→2, 5:0→2] end 6; bounds 3/nil; out 0:[2@5] 1:[2@2]; in 2:[1@2, 0@5] |
| SG-098 | Edge removal | removeAllEdges(from:where:) non-vertex or nothing chosen: 0 | V [0, 1]; E [0→1] / removeAllEdges(from: 9, where: { [0].contains($0) }) / removeAllEdges(from: 0, where: { _ in false }) | 0; 0 ⇒ V [0#0, 1#1] end 2; E [0:0→1] end 1; bounds 2/1; out 0:[1@0]; in 1:[0@0] |
| SG-099 | Edge removal | removeAllEdges(from:where:) self-loops and in-edges | V [0, 1]; E [1→0, 0→0, 0→1, 0→0] / removeAllEdges(from: 0, where: { [1, 2].contains($0) }) / remove(edgeAt: 3) / insert(edge: 0→0) | 2; 0→0; 4 ⇒ V [0#0, 1#1] end 2; E [0:1→0, 4:0→0] end 5; bounds 2/nil; out 0:[0@4] 1:[0@0]; in 0:[1@0, 0@4] |
| SG-100 | Edge removal | removeAllEdges(from:to:) one pass over the shorter row | V [0, 1, 2]; E [0→1, 0→2, 0→2, 2→1, 0→1, 0→2] / removeAllEdges(from: 0, to: 1) / remove(edgeAt: 3) / insert(edge: 2→1) | 2; 2→1; 6 ⇒ V [0#0, 1#1, 2#2] end 3; E [1:0→2, 2:0→2, 5:0→2, 6:2→1] end 7; bounds 3/nil; out 0:[2@1, 2@2, 2@5] 2:[1@6]; in 1:[2@6] 2:[0@1, 0@2, 0@5] |
| SG-101 | Edge removal | removeAllEdges(where:) over every edge | V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2, 1→1] / removeAllEdges(where: { [1, 3, 4].contains($0) }) / insert(edge: 1→1) | 3; 5 ⇒ V [0#0, 1#1, 2#2] end 3; E [0:0→1, 2:2→0, 5:1→1] end 6; bounds 3/nil; out 0:[1@0] 1:[1@5] 2:[0@2]; in 0:[2@2] 1:[0@0, 1@5] |
| SG-102 | Edge removal | removeAllEdges(where:) with a vertex hole | V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2] / remove(1) / removeAllEdges(where: { _ in false }) / removeAllEdges(where: { [3].contains($0) }) | 1; 0; 1 ⇒ V [0#0, 2#2] end 3; E [2:2→0] end 4; bounds nil/nil; out 2:[0@2]; in 0:[2@2] |
| SG-103 | Insertion | insert(safe:) with both endpoints: the new position | V [0, 1]; E [0→1] / insert(safe: 1→0) / insert(safe: 1→1) | 1; 2 ⇒ V [0#0, 1#1] end 2; E [0:0→1, 1:1→0, 2:1→1] end 3; bounds 2/3; out 0:[1@0] 1:[0@1, 1@2]; in 0:[1@1] 1:[0@0, 1@2] |
| SG-104 | Insertion | insert(safe:) with a missing endpoint: nil, nothing changes | V [0, 1]; E [0→0] / insert(safe: 0→9) / insert(safe: 9→0) / insert(safe: 9→9) / remove(1) / insert(safe: 0→1) | nil; nil; nil; 1; nil ⇒ V [0#0] end 2; E [0:0→0] end 1; bounds nil/1; out 0:[0@0]; in 0:[0@0] |
| SG-105 | Queries | safe: lookups on a vertex | V [0, 1, 2]; E [0→1, 2→0, 0→0] / successors(safe: 0) / predecessors(safe: 0) / outEdges(safe: 0) / inEdges(safe: 0) / outDegree(safe: 0) / inDegree(safe: 0) | [1, 0]; [2, 0]; [0, 2]; [1, 2]; 2; 2 ⇒ V [0#0, 1#1, 2#2] end 3; E [0:0→1, 1:2→0, 2:0→0] end 3; bounds 3/3; out 0:[1@0, 0@2] 2:[0@1]; in 0:[2@1, 0@2] 1:[0@0] |
| SG-106 | Queries | safe: lookups on a removed vertex or a non-vertex: nil | V [0, 1]; E [0→1] / remove(1) / successors(safe: 1) / predecessors(safe: 1) / outEdges(safe: 9) / inEdges(safe: 1) / outDegree(safe: 1) / inDegree(safe: 9) | 1; nil; nil; nil; nil; nil; nil ⇒ V [0#0] end 2; E [] end 1; bounds nil/nil; out -; in - |
| SG-107 | Queries | descendants(safe:) and ancestors(safe:) | V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3] / descendants(safe: 1) / ancestors(safe: 3) / remove(0) / descendants(safe: 1) / descendants(safe: 0) / ancestors(safe: 9) | [0, 2, 3]; [0, 1, 2]; 0; [2, 3]; nil; nil ⇒ V [1#1, 2#2, 3#3] end 4; E [1:1→2, 3:2→3] end 4; bounds nil/nil; out 1:[2@1] 2:[3@3]; in 2:[1@1] 3:[2@3] |
| SG-108 | Codable | vertexEnd far past the payload | {"vertices":[],"vertexPositions":[],"vertexEnd":4611686018427387903,"edges":[],"edgePositions":[],"edgeEnd":0} | dataCorrupted(vertexEnd): End leaves too many holes |
| SG-109 | Codable | edgeEnd far past the payload | {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":9223372036854775807} | dataCorrupted(edgeEnd): End leaves too many holes |
| SG-110 | Codable | vertexEnd one hole past the bound | {"vertices":[0],"vertexPositions":[0],"vertexEnd":65554,"edges":[],"edgePositions":[],"edgeEnd":0} | dataCorrupted(vertexEnd): End leaves too many holes |
| SG-111 | Codable | edgeEnd one hole past the bound | {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[0],"edgeEnd":65554} | dataCorrupted(edgeEnd): End leaves too many holes |
| SG-112 | Codable | ends at the bound decode | {"vertices":[0],"vertexPositions":[0],"vertexEnd":65553,"edges":[0,0],"edgePositions":[0],"edgeEnd":65553} | V [0#0] end 65553; E [0:0→0] end 65553; bounds nil/nil; out 0:[0@0]; in 0:[0@0] |
