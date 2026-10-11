# DirectedAcyclicGraphModule: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1
python3 Tests/Catalogs/DirectedAcyclicGraph/ref.py`; `--write` regenerates this file, `--stress` adds the random
sequences). Every Expected is the output of a port of the proposed wrapper over ports of the three bases,
checked at every state against the laws (the order is a permutation of the vertices, every edge goes forward)
and every witness against the graph; `--stress` also checks a NetworkX specification and a rustworkx shadow.

Conventions:

* Input `Base; V [...]; E [...]` is `DirectedAcyclicGraph<Base>(vertices: V, edges: E)`, the failable bulk
  initializer (Expected `nil` when the edges have a cycle); calls follow, separated by `/`. Expected lists each
  call's result, then `⇒` and the final state.
* State: `order [...]` is `topologicalOrder`; `V [...]` is `vertices`; `E [p:u→v, …]` is `edges` with positions.
* Bulk construction orders by Kahn's algorithm (FIFO, roots in `vertices` order): Traversal's
  `topologicalGenerations()` flattened. Later inserts maintain the order by Pearce–Kelly, a deterministic
  function of the order and the reachability sets, so it does not depend on row order.
* `insert(edge:)` returns `.inserted(p)` with the edge's position, or `.cycle(path)` where `path` is a
  `Path` from `edge.target` to `edge.source` (`[vertices] via [edge positions]`): the first path a depth-first
  search from the target finds, out-edges in `outEdges(of:)` order. A rejected edge changes nothing.
* `transitiveClosure()` / `transitiveReduction()` results are shown in braces with their own state.
* `longestPath()` is a `Path` (`[vertices] via [positions]`), `nil` for the empty graph.
* `**trap**` rows are preconditions, run as exit tests; results before the trap are listed.
* Codable rows give the payload `{base, order}` (`order` as offsets into `base.vertices`) and the decoded state
  or the `DecodingError` case.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| DAG-001 | Construction | empty | DirectedPseudograph; V []; E [] | order []; V []; E [] |
| DAG-002 | Construction | edgeless: order is vertices order | DirectedPseudograph; V [2, 0, 1]; E [] | order [2, 0, 1]; V [2, 0, 1]; E [] |
| DAG-003 | Construction | Kahn FIFO, roots in vertices order | DirectedPseudograph; V [0, 1, 2, 3]; E [3→1, 0→1, 1→2, 3→2] | order [0, 3, 1, 2]; V [0, 1, 2, 3]; E [0:3→1, 1:0→1, 2:1→2, 3:3→2] |
| DAG-004 | Construction | diamond: generations flattened | DirectedPseudograph; V []; E [0→1, 0→2, 1→3, 2→3] | order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:0→2, 2:1→3, 3:2→3] |
| DAG-005 | Construction | not the DFS order (Traversal's topologicalSort gives [3, 2, 1, 0]) | DirectedPseudograph; V [0, 1, 2, 3]; E [] | order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [] |
| DAG-006 | Construction | parallel copies kept on DirectedPseudograph | DirectedPseudograph; V []; E [0→1, 0→1, 1→2] | order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:0→1, 2:1→2] |
| DAG-007 | Construction | parallel copies collapse on AdjacencyList | AdjacencyList; V []; E [0→1, 0→1, 1→2] | order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:1→2] |
| DAG-008 | Construction | StableDirectedGraph base | StableDirectedGraph; V [5]; E [3→5, 5→4] | order [3, 5, 4]; V [5, 3, 4]; E [0:3→5, 1:5→4] |
| DAG-009 | Construction | a cycle: nil | DirectedPseudograph; V []; E [0→1, 1→2, 2→0] | nil |
| DAG-010 | Construction | a self-loop: nil | AdjacencyList; V [0, 1]; E [0→1, 1→1] | nil |
| DAG-011 | Construction | string vertices | AdjacencyList; V ["b", "a"]; E ["a"→"b", "c"→"a"] | order ["c", "a", "b"]; V ["b", "a", "c"]; E [0:"a"→"b", 1:"c"→"a"] |
| DAG-012 | Insertion | insert(_:) appends to the order | DirectedPseudograph; V [0]; E [0→1] / insert(2) / insert(0) | (true, 2); (false, 0) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→1] |
| DAG-013 | Insertion | forward edge: no reordering | DirectedPseudograph; V [0, 1, 2]; E [] / insert(edge: 0→2) / insert(edge: 1→2) | .inserted(0); .inserted(1) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→2, 1:1→2] |
| DAG-014 | Insertion | new endpoints appended, source first | DirectedPseudograph; V []; E [] / insert(edge: 7→8) / insert(edge: 9→7) | .inserted(0); .inserted(1) ⇒ order [9, 7, 8]; V [7, 8, 9]; E [0:7→8, 1:9→7] |
| DAG-015 | Insertion | new target: always forward | DirectedPseudograph; V [0, 1]; E [0→1] / insert(edge: 1→5) | .inserted(1) ⇒ order [0, 1, 5]; V [0, 1, 5]; E [0:0→1, 1:1→5] |
| DAG-016 | Insertion | new source to an old vertex reorders | DirectedPseudograph; V [0, 1]; E [0→1] / insert(edge: 5→0) | .inserted(1) ⇒ order [5, 0, 1]; V [0, 1, 5]; E [0:0→1, 1:5→0] |
| DAG-017 | Insertion | parallel copy on DirectedPseudograph: a new position | DirectedPseudograph; V [0, 1]; E [0→1] / insert(edge: 0→1) | .inserted(1) ⇒ order [0, 1]; V [0, 1]; E [0:0→1, 1:0→1] |
| DAG-018 | Insertion | existing edge on AdjacencyList: its position, nothing changes | AdjacencyList; V [0, 1, 2]; E [1→2, 0→1] / insert(edge: 0→1) | .inserted(1) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:1→2, 1:0→1] |
| DAG-019 | Insertion | StableDirectedGraph: position is edges.endIndex | StableDirectedGraph; V [0, 1]; E [0→1] / remove(edgeAt: 0) / insert(edge: 0→1) | 0→1; .inserted(1) ⇒ order [0, 1]; V [0, 1]; E [1:0→1] |
| DAG-020 | Reordering | backward edge between isolated vertices: swap | DirectedPseudograph; V [0, 1]; E [] / insert(edge: 1→0) | .inserted(0) ⇒ order [1, 0]; V [0, 1]; E [0:1→0] |
| DAG-021 | Reordering | only the affected region moves | DirectedPseudograph; V [0, 1, 2, 3, 4]; E [] / insert(edge: 3→1) | .inserted(0) ⇒ order [0, 3, 2, 1, 4]; V [0, 1, 2, 3, 4]; E [0:3→1] |
| DAG-022 | Reordering | forward set F follows the source | DirectedPseudograph; V [0, 1, 2, 3, 4]; E [1→2] / insert(edge: 3→1) | .inserted(1) ⇒ order [0, 3, 1, 4, 2]; V [0, 1, 2, 3, 4]; E [0:1→2, 1:3→1] |
| DAG-023 | Reordering | backward set B precedes the target | DirectedPseudograph; V [0, 1, 2, 3, 4]; E [2→3] / insert(edge: 3→1) | .inserted(1) ⇒ order [0, 2, 3, 4, 1]; V [0, 1, 2, 3, 4]; E [0:2→3, 1:3→1] |
| DAG-024 | Reordering | both sets; unrelated vertices in the region stay | DirectedPseudograph; V [0, 1, 2, 3, 4, 5]; E [1→2, 3→4] / insert(edge: 4→1) | .inserted(2) ⇒ order [0, 3, 4, 5, 1, 2]; V [0, 1, 2, 3, 4, 5]; E [0:1→2, 1:3→4, 2:4→1] |
| DAG-025 | Reordering | F bounded by the source's place (vertices after it do not move) | DirectedPseudograph; V [0, 1, 2, 3]; E [0→3] / insert(edge: 2→0) | .inserted(1) ⇒ order [2, 1, 0, 3]; V [0, 1, 2, 3]; E [0:0→3, 1:2→0] |
| DAG-026 | Reordering | reverse a chain one edge at a time | DirectedPseudograph; V [0, 1, 2, 3]; E [] / insert(edge: 3→2) / insert(edge: 2→1) / insert(edge: 1→0) | .inserted(0); .inserted(1); .inserted(2) ⇒ order [3, 2, 1, 0]; V [0, 1, 2, 3]; E [0:3→2, 1:2→1, 2:1→0] |
| DAG-027 | Reordering | interleaved sets: B then F take the pooled slots; 6 and 7 stay | DirectedPseudograph; V [0, 1, 2, 3, 4, 5, 6, 7]; E [0→2, 2→4, 1→3, 3→5] / insert(edge: 5→0) | .inserted(4) ⇒ order [1, 3, 6, 7, 5, 0, 2, 4]; V [0, 1, 2, 3, 4, 5, 6, 7]; E [0:0→2, 1:2→4, 2:1→3, 3:3→5, 4:5→0] |
| DAG-028 | Reordering | order independent of row order (same sets) | DirectedPseudograph; V [0, 1, 2, 3]; E [1→3, 1→2] / insert(edge: 3→0) | .inserted(2) ⇒ order [1, 3, 0, 2]; V [0, 1, 2, 3]; E [0:1→3, 1:1→2, 2:3→0] |
| DAG-029 | Reordering | incremental build, then the edge closing a five-cycle | AdjacencyList; V []; E [] / insert(edge: 2→3) / insert(edge: 0→1) / insert(edge: 3→0) / insert(edge: 1→4) / insert(edge: 4→2) | .inserted(0); .inserted(1); .inserted(2); .inserted(3); .cycle([2, 3, 0, 1, 4] via [0, 2, 1, 3]) ⇒ order [2, 3, 0, 1, 4]; V [2, 3, 0, 1, 4]; E [0:2→3, 1:0→1, 2:3→0, 3:1→4] |
| DAG-030 | Cycle witness | self-loop: [u] with no edges; nothing inserted | DirectedPseudograph; V [0]; E [] / insert(edge: 0→0) | .cycle([0] via []) ⇒ order [0]; V [0]; E [] |
| DAG-031 | Cycle witness | self-loop on a non-vertex inserts nothing | AdjacencyList; V [0]; E [] / insert(edge: 9→9) | .cycle([9] via []) ⇒ order [0]; V [0]; E [] |
| DAG-032 | Cycle witness | two-cycle: the existing edge | DirectedPseudograph; V [0, 1]; E [0→1] / insert(edge: 1→0) | .cycle([0, 1] via [0]) ⇒ order [0, 1]; V [0, 1]; E [0:0→1] |
| DAG-033 | Cycle witness | long cycle: the path from target to source | DirectedPseudograph; V []; E [0→1, 1→2, 2→3, 3→4] / insert(edge: 4→0) | .cycle([0, 1, 2, 3, 4] via [0, 1, 2, 3]) ⇒ order [0, 1, 2, 3, 4]; V [0, 1, 2, 3, 4]; E [0:0→1, 1:1→2, 2:2→3, 3:3→4] |
| DAG-034 | Cycle witness | two paths: the first depth-first path in outEdges order | DirectedPseudograph; V [0, 1, 2, 3]; E [0→2, 0→1, 1→3, 2→3] / insert(edge: 3→0) | .cycle([0, 2, 3] via [0, 3]) ⇒ order [0, 2, 1, 3]; V [0, 1, 2, 3]; E [0:0→2, 1:0→1, 2:1→3, 3:2→3] |
| DAG-035 | Cycle witness | dead branch explored first is not in the path | DirectedPseudograph; V [0, 1, 2, 3]; E [0→1, 1→2, 0→3] / insert(edge: 3→0) | .cycle([0, 3] via [2]) ⇒ order [0, 1, 3, 2]; V [0, 1, 2, 3]; E [0:0→1, 1:1→2, 2:0→3] |
| DAG-036 | Cycle witness | parallel copies: the first copy in outEdges order | DirectedPseudograph; V [0, 1]; E [0→1, 0→1] / insert(edge: 1→0) | .cycle([0, 1] via [0]) ⇒ order [0, 1]; V [0, 1]; E [0:0→1, 1:0→1] |
| DAG-037 | Cycle witness | witness positions after a swap-remove | DirectedPseudograph; V [0, 1, 2]; E [0→1, 1→2, 0→2] / remove(edgeAt: 0) / insert(edge: 2→0) | 0→1; .cycle([0, 2] via [0]) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→2, 1:1→2] |
| DAG-038 | Cycle witness | Stable positions in the witness | StableDirectedGraph; V [0, 1, 2]; E [0→1, 0→1, 1→2] / remove(edgeAt: 0) / insert(edge: 2→0) | 0→1; .cycle([0, 1, 2] via [1, 2]) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [1:0→1, 2:1→2] |
| DAG-039 | Cycle witness | rejected edge changes nothing; later insert works | AdjacencyList; V [0, 1, 2]; E [0→1, 1→2] / insert(edge: 2→0) / insert(edge: 0→2) | .cycle([0, 1, 2] via [0, 1]); .inserted(2) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:1→2, 2:0→2] |
| DAG-040 | insert(safe:) | both endpoints present: as insert(edge:) | DirectedPseudograph; V [0, 1]; E [] / insert(safe: 1→0) | .inserted(0) ⇒ order [1, 0]; V [0, 1]; E [0:1→0] |
| DAG-041 | insert(safe:) | missing endpoint: nil, nothing inserted | DirectedPseudograph; V [0]; E [] / insert(safe: 0→1) / insert(safe: 2→0) | nil; nil ⇒ order [0]; V [0]; E [] |
| DAG-042 | insert(safe:) | cycle reported through safe: | AdjacencyList; V [0, 1]; E [0→1] / insert(safe: 1→0) | .cycle([0, 1] via [0]) ⇒ order [0, 1]; V [0, 1]; E [0:0→1] |
| DAG-043 | insert(safe:) | self-loop on a vertex: cycle; on a non-vertex: nil | StableDirectedGraph; V [0]; E [] / insert(safe: 0→0) / insert(safe: 3→3) | .cycle([0] via []); nil ⇒ order [0]; V [0]; E [] |
| DAG-044 | Removal | remove(edge:) keeps the order | DirectedPseudograph; V [0, 1, 2]; E [1→0, 0→2] / remove(edge: 1→0) | 1→0 ⇒ order [1, 0, 2]; V [0, 1, 2]; E [0:0→2] |
| DAG-045 | Removal | remove(edge:) newest copy; absent: nil | DirectedPseudograph; V [0, 1]; E [0→1, 0→1] / remove(edge: 0→1) / remove(edge: 1→0) / remove(edge: 0→9) | 0→1; nil; nil ⇒ order [0, 1]; V [0, 1]; E [0:0→1] |
| DAG-046 | Removal | remove(edgeAt:) swap-moves the last edge, order kept | DirectedPseudograph; V [0, 1, 2]; E [0→1, 1→2, 0→2] / remove(edgeAt: 0) | 0→1 ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→2, 1:1→2] |
| DAG-047 | Removal | remove(edgeAt:) out of range traps | DirectedPseudograph; V [0, 1]; E [0→1] / remove(edgeAt: 1) | **trap** |
| DAG-048 | Removal | remove(edgeAt:) at a Stable hole traps | StableDirectedGraph; V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0) / remove(edgeAt: 0) | 0→1; **trap** |
| DAG-049 | Removal | remove(_:) closes the gap in the order | DirectedPseudograph; V [0, 1, 2, 3]; E [0→1, 1→2, 2→3] / remove(1) | 1 ⇒ order [0, 2, 3]; V [0, 3, 2]; E [0:2→3] |
| DAG-050 | Removal | remove(_:) follows the swap-remove (last slot moves in) | AdjacencyList; V [3, 2, 1, 0]; E [3→0, 2→0] / remove(3) / topologicalPosition(of: 0) / topologicalPosition(of: 1) | 3; 2; 1 ⇒ order [2, 1, 0]; V [0, 2, 1]; E [0:2→0] |
| DAG-051 | Removal | after the swap-remove, reordering uses the moved vertex's new slot | AdjacencyList; V [0, 1, 2, 3]; E [0→1] / remove(0) / insert(edge: 3→1) / insert(edge: 2→3) | 0; .inserted(0); .inserted(1) ⇒ order [2, 3, 1]; V [3, 1, 2]; E [0:3→1, 1:2→3] |
| DAG-052 | Removal | remove(_:) on Stable: holes, nothing renamed | StableDirectedGraph; V [0, 1, 2]; E [2→0, 0→1] / remove(2) / insert(2) | 2; (true, 2) ⇒ order [0, 1, 2]; V [0, 1, 2]; E [1:0→1] |
| DAG-053 | Removal | remove(_:) absent: nil | AdjacencyList; V [0]; E [] / remove(4) | nil ⇒ order [0]; V [0]; E [] |
| DAG-054 | Removal | removeAllEdges() keeps vertices and order | DirectedPseudograph; V [0, 1, 2]; E [] / insert(edge: 2→0) / removeAllEdges() / insert(edge: 1→2) | .inserted(0); (); .inserted(0) ⇒ order [1, 2, 0]; V [0, 1, 2]; E [0:1→2] |
| DAG-055 | Removal | removeAll() then rebuild | StableDirectedGraph; V [0, 1]; E [1→0] / removeAll() / insert(edge: 1→0) | (); .inserted(0) ⇒ order [1, 0]; V [1, 0]; E [0:1→0] |
| DAG-056 | Removal | removing an edge makes a reverse edge acceptable | DirectedPseudograph; V [0, 1]; E [0→1] / remove(edge: 0→1) / insert(edge: 1→0) | 0→1; .inserted(0) ⇒ order [1, 0]; V [0, 1]; E [0:1→0] |
| DAG-057 | Order queries | topologicalPosition(of:) | DirectedPseudograph; V [0, 1, 2]; E [2→0] / topologicalPosition(of: 2) / topologicalPosition(of: 0) / topologicalPosition(of: 1) | 1; 2; 0 ⇒ order [1, 2, 0]; V [0, 1, 2]; E [0:2→0] |
| DAG-058 | Order queries | topologicalPosition(of:) non-vertex traps | DirectedPseudograph; V [0]; E [] / topologicalPosition(of: 9) | **trap** |
| DAG-059 | Order queries | topologicalPosition(safe:) | AdjacencyList; V [0, 1]; E [1→0] / topologicalPosition(safe: 1) / topologicalPosition(safe: 9) | 0; nil ⇒ order [1, 0]; V [0, 1]; E [0:1→0] |
| DAG-060 | Order queries | topologicalOrder subscript | DirectedPseudograph; V [0, 1, 2]; E [2→1] / topologicalOrder[0] / topologicalOrder[2] | 0; 1 ⇒ order [0, 2, 1]; V [0, 1, 2]; E [0:2→1] |
| DAG-061 | Order queries | topologicalOrder subscript out of range traps | DirectedPseudograph; V [0]; E [] / topologicalOrder[1] | **trap** |
| DAG-062 | Order queries | hasPath: same vertex true | DirectedPseudograph; V [0]; E [] / hasPath(from: 0, to: 0) | true ⇒ order [0]; V [0]; E [] |
| DAG-063 | Order queries | hasPath: placed later, so false without a search | DirectedPseudograph; V [0, 1]; E [0→1] / hasPath(from: 1, to: 0) | false ⇒ order [0, 1]; V [0, 1]; E [0:0→1] |
| DAG-064 | Order queries | hasPath: placed earlier, searched within the bound | DirectedPseudograph; V [0, 1, 2, 3]; E [0→1, 1→3, 0→2] / hasPath(from: 0, to: 3) / hasPath(from: 2, to: 3) | true; false ⇒ order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:1→3, 2:0→2] |
| DAG-065 | Order queries | hasPath: non-vertex traps | DirectedPseudograph; V [0]; E [] / hasPath(from: 0, to: 9) | **trap** |
| DAG-066 | Order queries | equality ignores the order | DirectedPseudograph; V [0, 1]; E [] / insert(edge: 1→0) / remove(edge: 1→0) / == DirectedAcyclicGraph<DirectedPseudograph>(vertices: [0, 1], edges: []) | .inserted(0); 1→0; true ⇒ order [1, 0]; V [0, 1]; E [] |
| DAG-067 | Order queries | equality: different edges | AdjacencyList; V [0, 1]; E [0→1] / == DirectedAcyclicGraph<AdjacencyList>(vertices: [0, 1], edges: []) | false ⇒ order [0, 1]; V [0, 1]; E [0:0→1] |
| DAG-068 | Algorithms | transitiveClosure: chain | DirectedPseudograph; V []; E [0→1, 1→2, 2→3] / transitiveClosure() | {order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:1→2, 2:2→3, 3:0→2, 4:0→3, 5:1→3]} ⇒ order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:1→2, 2:2→3] |
| DAG-069 | Algorithms | transitiveClosure: existing edges keep their positions | DirectedPseudograph; V [0, 1, 2]; E [1→2, 0→1, 0→2] / transitiveClosure() | {order [0, 1, 2]; V [0, 1, 2]; E [0:1→2, 1:0→1, 2:0→2]} ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:1→2, 1:0→1, 2:0→2] |
| DAG-070 | Algorithms | transitiveClosure: copies kept, none added | DirectedPseudograph; V []; E [0→1, 0→1] / transitiveClosure() | {order [0, 1]; V [0, 1]; E [0:0→1, 1:0→1]} ⇒ order [0, 1]; V [0, 1]; E [0:0→1, 1:0→1] |
| DAG-071 | Algorithms | transitiveClosure: diamond plus tail | AdjacencyList; V []; E [0→1, 0→2, 1→3, 2→3, 3→4] / transitiveClosure() | {order [0, 1, 2, 3, 4]; V [0, 1, 2, 3, 4]; E [0:0→1, 1:0→2, 2:1→3, 3:2→3, 4:3→4, 5:0→3, 6:0→4, 7:1→4, 8:2→4]} ⇒ order [0, 1, 2, 3, 4]; V [0, 1, 2, 3, 4]; E [0:0→1, 1:0→2, 2:1→3, 3:2→3, 4:3→4] |
| DAG-072 | Algorithms | transitiveClosure: empty | StableDirectedGraph; V []; E [] / transitiveClosure() | {order []; V []; E []} ⇒ order []; V []; E [] |
| DAG-073 | Algorithms | transitiveReduction: drops the shortcut | DirectedPseudograph; V [0, 1, 2]; E [0→1, 1→2, 0→2] / transitiveReduction() | {order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:1→2]} ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:1→2, 2:0→2] |
| DAG-074 | Algorithms | transitiveReduction: copies collapse to the first | DirectedPseudograph; V []; E [0→1, 1→2, 0→1] / transitiveReduction() | {order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:1→2]} ⇒ order [0, 1, 2]; V [0, 1, 2]; E [0:0→1, 1:1→2, 2:0→1] |
| DAG-075 | Algorithms | transitiveReduction: closure of a chain reduces to the chain | AdjacencyList; V []; E [0→1, 0→2, 0→3, 1→2, 1→3, 2→3] / transitiveReduction() | {order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:1→2, 2:2→3]} ⇒ order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:0→2, 2:0→3, 3:1→2, 4:1→3, 5:2→3] |
| DAG-076 | Algorithms | transitiveReduction: Stable base is compacted | StableDirectedGraph; V [0, 1, 2, 3]; E [0→1, 1→2, 0→2, 2→3] / remove(1) / transitiveReduction() | 1; {order [0, 2, 3]; V [0, 2, 3]; E [0:0→2, 1:2→3]} ⇒ order [0, 2, 3]; V [0, 2, 3]; E [2:0→2, 3:2→3] |
| DAG-077 | Algorithms | transitiveReduction keeps the order | DirectedPseudograph; V [0, 1, 2]; E [] / insert(edge: 2→0) / insert(edge: 1→0) / insert(edge: 2→1) / transitiveReduction() | .inserted(0); .inserted(1); .inserted(2); {order [2, 1, 0]; V [0, 1, 2]; E [0:1→0, 1:2→1]} ⇒ order [2, 1, 0]; V [0, 1, 2]; E [0:2→0, 1:1→0, 2:2→1] |
| DAG-078 | Algorithms | longestPath: empty is nil | DirectedPseudograph; V []; E [] / longestPath() | nil ⇒ order []; V []; E [] |
| DAG-079 | Algorithms | longestPath: edgeless is the first vertex | DirectedPseudograph; V [3, 1]; E [] / longestPath() | [3] via [] ⇒ order [3, 1]; V [3, 1]; E [] |
| DAG-080 | Algorithms | longestPath: chain | AdjacencyList; V []; E [0→1, 1→2, 2→3] / longestPath() | [0, 1, 2, 3] via [0, 1, 2] ⇒ order [0, 1, 2, 3]; V [0, 1, 2, 3]; E [0:0→1, 1:1→2, 2:2→3] |
| DAG-081 | Algorithms | longestPath: ties go to the first in-edge and the first end in order | DirectedPseudograph; V [0, 1, 2, 3]; E [0→2, 1→2, 0→3] / longestPath() | [0, 3] via [2] ⇒ order [0, 1, 3, 2]; V [0, 1, 2, 3]; E [0:0→2, 1:1→2, 2:0→3] |
| DAG-082 | Algorithms | longestPath: the longer branch wins | DirectedPseudograph; V []; E [0→1, 1→2, 2→5, 0→3, 3→5] / longestPath() | [0, 1, 2, 5] via [0, 1, 2] ⇒ order [0, 1, 3, 2, 5]; V [0, 1, 2, 5, 3]; E [0:0→1, 1:1→2, 2:2→5, 3:0→3, 4:3→5] |
| DAG-083 | Algorithms | longestPath: parallel copies, the first in-edge | DirectedPseudograph; V []; E [0→1, 0→1] / longestPath() | [0, 1] via [0] ⇒ order [0, 1]; V [0, 1]; E [0:0→1, 1:0→1] |
| DAG-084 | Codable | round trip keeps the order | DirectedPseudograph; decode {base: V [0, 1, 2]; E [2→0], order: [1, 2, 0]} | order [1, 2, 0]; V [0, 1, 2]; E [0:2→0] |
| DAG-085 | Codable | cyclic base rejected | DirectedPseudograph; decode {base: V [0, 1]; E [0→1, 1→0], order: [0, 1]} | DecodingError.dataCorrupted (a cycle) |
| DAG-086 | Codable | order not a permutation rejected | DirectedPseudograph; decode {base: V [0, 1]; E [], order: [0, 0]} | DecodingError.dataCorrupted (not a permutation) |
| DAG-087 | Codable | edge going backward in the order rejected | DirectedPseudograph; decode {base: V [0, 1]; E [0→1], order: [1, 0]} | DecodingError.dataCorrupted (an edge goes backward) |
