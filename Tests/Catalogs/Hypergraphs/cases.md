# Hypergraphs: case catalog

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2
--with hypernetx==2.4.3 --with halp==1.0.0 python3 Tests/Catalogs/Hypergraphs/ref.py`; `--write`
regenerates this file, `--stress` adds the random hypergraphs and mutation sequences). `HG-` rows are
`UndirectedIncidenceList` (a `Hypergraph`), checked against XGI 0.10.2 `Hypergraph`, HyperNetX 2.4.3 (empty
hyperedges mapped back, since it drops them) and NetworkX 3.7 on the incidence graph. `DH-` rows are
`IncidenceList` (a `DirectedHypergraph`), checked against XGI 0.10.2 `DiHypergraph`, NetworkX 3.7 on its
directed `to_bipartite_graph`, and halp 1.0.0 `b_visit` / `f_visit`. Both are checked against the protocol
laws, the hash law and a Codable round trip.

Conventions:

* `U V [...]; E [{...}, ...]` is `UndirectedIncidenceList<String>(vertices: V, hyperedges: E)`; `D V [...];
  E [{s, …}→{t, …}, ...]` is `IncidenceList<String>(vertices: V, hyperedges: E)` with `E` a list of
  `(sources:, targets:)` pairs. `<Int>` when the labels are numbers. Calls follow, separated by `/`.
* Expected lists each call's result, then `⇒` and the final state where it matters. State: `V [v#i, …]` is
  `vertices` with each vertex's index; `E [p:…, …]` is `hyperedges` by position, each side in vertex-index
  order.
* `dual()` and `reversed` print as states (the dual's vertices are the original's hyperedge positions).
* `incidenceGraphView`, `cliqueExpansion()` and `lineGraph(s:)` print `vertices …; edges […]` with the edges in
  edge-position order (`–` undirected, `→` directed). In `incidenceGraphView`, vertex index `i` is `i` and
  hyperedge `p` is `n + p`.
* `hashes()` is the number of vertex lookups so far (a benchmark counter, not API: the Swift suite counts
  with a `Vertex` whose `hash(into:)` counts).
* `decode {…}` is `JSONDecoder().decode(_, from:)` of that JSON; `throws DecodingError.dataCorrupted (…)`
  names the re-check that failed.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before the
  trap are listed.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| HG-001 | Construction | empty | U V []; E [] | V []; E [] |
| HG-002 | Construction | isolated vertices in listed order | U V [a, b, c]; E [] | V [a#0, b#1, c#2]; E [] |
| HG-003 | Construction | vertices by first appearance in the hyperedges | U V []; E [{c, a}, {b, c}] | V [c#0, a#1, b#2]; E [0:{c, a}, 1:{c, b}] |
| HG-004 | Construction | listed vertices first, then new members | U V [z]; E [{x, z}, {z, y}] | V [z#0, x#1, y#2]; E [0:{z, x}, 1:{z, y}] |
| HG-005 | Construction | members stored in vertex-index order, not input order | U V [a, b, c]; E [{c, a, b}] / members(ofHyperedgeAt: 0) / memberIndices(ofHyperedgeAt: 0) | [a, b, c]; [0, 1, 2] ⇒ V [a#0, b#1, c#2]; E [0:{a, b, c}] |
| HG-006 | Construction | a repeated member is stored once | U V []; E [{a, b, a}] / size(ofHyperedgeAt: 0) | 2 ⇒ V [a#0, b#1]; E [0:{a, b}] |
| HG-007 | Construction | a repeated hyperedge is kept (multi-hyperedge), each its own position | U V []; E [{a, b}, {b, a}] / incidentHyperedges(of: a) / degree(of: a) | [0, 1]; 2 ⇒ V [a#0, b#1]; E [0:{a, b}, 1:{a, b}] |
| HG-008 | Construction | an empty hyperedge is kept | U V []; E [{a, b}, {}, {b, c}] / size(ofHyperedgeAt: 1) / vertexCount/hyperedgeCount | 0; 3/3 ⇒ V [a#0, b#1, c#2]; E [0:{a, b}, 1:{}, 2:{b, c}] |
| HG-009 | Construction | a singleton hyperedge | U V []; E [{a}] / degree(of: a) / neighbors(of: a) | 1; [] ⇒ V [a#0]; E [0:{a}] |
| HG-010 | Construction | a repeated vertex in the vertex list is inserted once | U V [a, a, b]; E [] / vertexCount/hyperedgeCount | 2/0 ⇒ V [a#0, b#1]; E [] |
| HG-011 | Construction | Int vertices are labels, not indices | U V [5, 3]; E [{3, 7}] / vertexIndex(of: 3) / vertex(atIndex: 2) / members(ofHyperedgeAt: 0) | 1; 7; [3, 7] ⇒ V [5#0, 3#1, 7#2]; E [0:{3, 7}] |
| HG-012 | Reads | members of each hyperedge | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / members(ofHyperedgeAt: 0) / members(ofHyperedgeAt: 1) / members(ofHyperedgeAt: 3) | [a, b, c]; [c, d]; [e] ⇒ V [a#0, b#1, c#2, d#3, e#4, f#5]; E [0:{a, b, c}, 1:{c, d}, 2:{a, b, c}, 3:{e}] |
| HG-013 | Reads | sizes | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / size(ofHyperedgeAt: 0) / size(ofHyperedgeAt: 1) / size(ofHyperedgeAt: 3) | 3; 2; 1 |
| HG-014 | Reads | incident hyperedges in ascending position | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(of: c) / incidentHyperedges(of: a) / incidentHyperedges(of: f) | [0, 1, 2]; [0, 2]; [] |
| HG-015 | Reads | degree counts each copy of a repeated hyperedge | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / degree(of: a) / degree(of: c) / degree(of: e) / degree(of: f) | 2; 3; 1; 0 |
| HG-016 | Reads | counts | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / vertexCount/hyperedgeCount | 6/4 |
| HG-017 | Reads | contains | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / contains(a) / contains(z) | true; false |
| HG-018 | Reads | contains(hyperedge:) compares member sets, any order | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / contains(hyperedge: [c, b, a]) / contains(hyperedge: [a, b]) / contains(hyperedge: [e]) / contains(hyperedge: [z]) | true; false; true; false |
| HG-019 | Reads | contains(hyperedge:) of the empty set | U V []; E [{a, b}, {}, {b, c}] / contains(hyperedge: []) | true |
| HG-020 | Reads | contains(hyperedge:) of the empty set, none stored | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / contains(hyperedge: []) | false |
| HG-021 | Reads | vertex indices round trip | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / vertexIndex(of: d) / vertex(atIndex: 3) / vertexIndex(checked: z) | 3; d; throws VertexNotFound |
| HG-022 | Reads | index-space reads hash nothing; a vertex-space read hashes once | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(ofIndex: 2) / degree(ofIndex: 2) / memberIndices(ofHyperedgeAt: 0) / hashes() / incidentHyperedges(of: c) / hashes() | [0, 1, 2]; 3; [0, 1, 2]; 0; [0, 1, 2]; 1 |
| HG-023 | Reads | checked: spellings throw for a non-vertex | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(checked: z) / degree(checked: z) / incidentHyperedges(checked: c) / degree(checked: c) / hashes() | throws VertexNotFound; throws VertexNotFound; [0, 1, 2]; 3; 4 |
| HG-024 | Reads | neighbors: vertices sharing a hyperedge, once each, in index order, never itself | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / neighbors(of: c) / neighbors(of: e) / neighbors(of: f) | [a, b, d]; []; [] |
| HG-025 | Traps | incidentHyperedges(of:) on a non-vertex | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(of: z) | **trap** (z is not a vertex of the hypergraph) |
| HG-026 | Traps | degree(of:) on a non-vertex | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / degree(of: z) | **trap** (z is not a vertex of the hypergraph) |
| HG-027 | Traps | neighbors(of:) on a non-vertex | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / neighbors(of: z) | **trap** (z is not a vertex of the hypergraph) |
| HG-028 | Traps | members(ofHyperedgeAt:) past the end | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / members(ofHyperedgeAt: 4) | **trap** (hyperedge position out of range) |
| HG-029 | Traps | members(ofHyperedgeAt:) negative | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / members(ofHyperedgeAt: -1) | **trap** (hyperedge position out of range) |
| HG-030 | Traps | vertex(atIndex:) past the end | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / vertex(atIndex: 6) | **trap** (vertex index out of range) |
| HG-031 | Traps | incidentHyperedges(ofIndex:) past the end | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(ofIndex: 6) | **trap** (vertex index out of range) |
| HG-032 | Traps | lineGraph(s: 0) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / lineGraph(s: 0) | **trap** (s must be at least 1) |
| HG-033 | Traps | sConnectedComponents(s: 0) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / sConnectedComponents(s: 0) | **trap** (s must be at least 1) |
| HG-034 | Traps | isUniform(size: -1) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / isUniform(size: -1) | **trap** (size must not be negative) |
| HG-035 | Mutation | insert a new vertex, then an existing one | U V [a]; E [] / insert(b) / insert(a) | (true, b); (false, a) ⇒ V [a#0, b#1]; E [] |
| HG-036 | Mutation | insert(hyperedge:) returns the new position and inserts missing members | U V [a]; E [{a}] / insert(hyperedge: [c, a, b]) / incidentHyperedges(of: a) | 1; [0, 1] ⇒ V [a#0, c#1, b#2]; E [0:{a}, 1:{a, c, b}] |
| HG-037 | Mutation | insert(hyperedge:) of an existing member set adds a copy | U V []; E [{a, b}] / insert(hyperedge: [b, a]) / vertexCount/hyperedgeCount | 1; 2/2 ⇒ V [a#0, b#1]; E [0:{a, b}, 1:{a, b}] |
| HG-038 | Mutation | insert(hyperedge:) of the empty set | U V [a]; E [] / insert(hyperedge: []) / size(ofHyperedgeAt: 0) | 0; 0 ⇒ V [a#0]; E [0:{}] |
| HG-039 | Mutation | insert(checked:) with every member present | U V [a, b]; E [] / insert(checked: [a, b]) | 0 ⇒ V [a#0, b#1]; E [0:{a, b}] |
| HG-040 | Mutation | insert(checked:) with a missing member: throws, nothing changes | U V [a, b]; E [] / insert(checked: [a, z]) / vertexCount/hyperedgeCount | throws VertexNotFound; 2/0 ⇒ V [a#0, b#1]; E [] |
| HG-041 | Mutation | removeAll | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / removeAll() / vertexCount/hyperedgeCount | (); 0/0 ⇒ V []; E [] |
| HG-042 | Mutation | incidence rows stay ascending under appends | U V [a, b]; E [{b}] / insert(hyperedge: [a]) / insert(hyperedge: [b, a]) / incidentHyperedges(of: b) / incidentHyperedges(of: a) | 1; 2; [0, 2]; [1, 2] ⇒ V [a#0, b#1]; E [0:{b}, 1:{a}, 2:{a, b}] |
| HG-043 | Measures | rank is the greatest size | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / rank | 3 |
| HG-044 | Measures | rank with no hyperedges is 0 | U V [a]; E [] / rank | 0 |
| HG-045 | Measures | rank with only an empty hyperedge is 0 | U V []; E [{}] / rank | 0 |
| HG-046 | Measures | isUniform(size:) | U V []; E [{a, b}, {b, c}, {c, a}] / isUniform(size: 2) / isUniform(size: 3) | true; false |
| HG-047 | Measures | not uniform: mixed sizes | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / isUniform(size: 3) | false |
| HG-048 | Measures | singletons count (XGI's is_uniform ignores them) | U V []; E [{a}, {b}] / isUniform(size: 1) / isUniform(size: 2) | true; false |
| HG-049 | Measures | no hyperedges: uniform for every size, vacuously (XGI: False) | U V [a]; E [] / isUniform(size: 0) / isUniform(size: 3) | true; true |
| HG-050 | Measures | an empty hyperedge has size 0 | U V []; E [{a, b}, {}, {b, c}] / isUniform(size: 2) | false |
| HG-051 | Measures | degree histogram (NetworkX's degree_histogram shape) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / degreeHistogram() | [1, 2, 2, 1] |
| HG-052 | Measures | hyperedge size histogram | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / hyperedgeSizeHistogram() | [0, 1, 1, 2] |
| HG-053 | Measures | histograms of the empty hypergraph are empty | U V []; E [] / degreeHistogram() / hyperedgeSizeHistogram() | []; [] |
| HG-054 | Measures | histograms with an empty hyperedge | U V []; E [{a, b}, {}, {b, c}] / degreeHistogram() / hyperedgeSizeHistogram() | [0, 2, 1]; [1, 0, 2] |
| HG-055 | Dual | vertices are hyperedge positions; hyperedge i is vertex i's incidence row | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / dual() | V [0#0, 1#1, 2#2, 3#3]; E [0:{0, 2}, 1:{0, 2}, 2:{0, 1, 2}, 3:{1}, 4:{3}, 5:{}] |
| HG-056 | Dual | an isolated vertex becomes an empty hyperedge, an empty hyperedge an isolated vertex | U V []; E [{a, b}, {}, {b, c}, {d}] / insert(z) / dual() | (true, z); V [0#0, 1#1, 2#2, 3#3]; E [0:{0}, 1:{0, 2}, 2:{2}, 3:{3}, 4:{}] |
| HG-057 | Dual | of the empty hypergraph | U V []; E [] / dual() | V []; E [] |
| HG-058 | Dual | repeated hyperedges become vertices with equal incidence rows | U V []; E [{a, b}, {a, b}] / dual() | V [0#0, 1#1]; E [0:{0, 1}, 1:{0, 1}] |
| HG-059 | Incidence graph | vertices 0..<n then n + p; edge q is the q-th incidence (XGI to_bipartite_graph numbering) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidenceGraphView | vertices 0..<10; edges [0–6, 1–6, 2–6, 2–7, 3–7, 0–8, 1–8, 2–8, 4–9] |
| HG-060 | Incidence graph | an empty hyperedge is an isolated vertex | U V []; E [{a, b}, {}, {b, c}] / incidenceGraphView | vertices 0..<6; edges [0–3, 1–3, 1–5, 2–5] |
| HG-061 | Incidence graph | repeated hyperedges are distinct vertices; the view stays simple | U V []; E [{a, b}, {a, b}] / incidenceGraphView | vertices 0..<4; edges [0–2, 1–2, 0–3, 1–3] |
| HG-062 | Clique expansion | every vertex, isolated ones too; each pair once, by index pair (XGI to_graph) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / cliqueExpansion() | vertices [a, b, c, d, e, f]; edges [a–b, a–c, b–c, c–d] |
| HG-063 | Clique expansion | singletons and empty hyperedges add no edge; no self-loops | U V []; E [{a}, {}, {a, b}] / cliqueExpansion() | vertices [a, b]; edges [a–b] |
| HG-064 | Clique expansion | a 4-member hyperedge is K4 | U V []; E [{a, b, c, d}] / cliqueExpansion() | vertices [a, b, c, d]; edges [a–b, a–c, a–d, b–c, b–d, c–d] |
| HG-065 | Line graph | s = 1: vertices 0..<m; hyperedges sharing a vertex (XGI to_line_graph, HyperNetX get_linegraph) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / lineGraph(s: 1) | vertices 0..<4; edges [0–1, 0–2, 1–2] |
| HG-066 | Line graph | s = 1, 2, 3 on overlaps of 1, 2 and 3 | U V []; E [{a, b, c, d}, {c, d, e}, {d, e, f}, {a, b, c, g}, {x, y}] / lineGraph(s: 1) / lineGraph(s: 2) / lineGraph(s: 3) | vertices 0..<5; edges [0–1, 0–2, 0–3, 1–2, 1–3]; vertices 0..<5; edges [0–1, 0–3, 1–2]; vertices 0..<5; edges [0–3] |
| HG-067 | Line graph | an empty hyperedge is an isolated vertex | U V []; E [{a, b}, {}, {b, c}] / lineGraph(s: 1) | vertices 0..<3; edges [0–2] |
| HG-068 | Line graph | repeated hyperedges are adjacent at s = their size | U V []; E [{a, b}, {a, b}] / lineGraph(s: 2) / lineGraph(s: 3) | vertices 0..<2; edges [0–1]; vertices 0..<2; edges [] |
| HG-069 | Connectivity | components by least vertex index, isolated vertices alone (XGI) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / connectedComponents() / isConnected | [[a, b, c, d], [e], [f]]; false |
| HG-070 | Connectivity | one hyperedge joins all its members | U V []; E [{a, b, c}] / connectedComponents() / isConnected | [[a, b, c]]; true |
| HG-071 | Connectivity | empty hypergraph: no components, not connected (XGI raises) | U V []; E [] / connectedComponents() / isConnected | []; false |
| HG-072 | Connectivity | an empty hyperedge joins nothing | U V [a, b]; E [{}] / connectedComponents() / isConnected | [[a], [b]]; false |
| HG-073 | Connectivity | a chain of hyperedges | U V []; E [{a, b}, {b, c}, {c, d}, {e, f}, {f, a}] / connectedComponents() / isConnected | [[a, b, c, d, e, f]]; true |
| HG-074 | s-connectivity | hyperedge s-components, s = 1, 2, 3 (HyperNetX s_components, edges=True) | U V []; E [{a, b, c, d}, {c, d, e}, {d, e, f}, {a, b, c, g}, {x, y}] / sConnectedComponents(s: 1) / sConnectedComponents(s: 2) / sConnectedComponents(s: 3) | [[0, 1, 2, 3], [4]]; [[0, 1, 2, 3], [4]]; [[0, 3], [1], [2], [4]] |
| HG-075 | s-connectivity | singletons kept (HyperNetX's s_connected_components drops them by default) | U V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / sConnectedComponents(s: 2) | [[0, 2], [1], [3]] |
| HG-076 | s-connectivity | an empty hyperedge is its own s-component (HyperNetX drops it) | U V []; E [{a, b}, {}, {b, c}] / sConnectedComponents(s: 1) | [[0, 2], [1]] |
| HG-077 | s-connectivity | vertex s-components are the dual's (HyperNetX edges=False) | U V []; E [{a, b, c, d}, {c, d, e}, {d, e, f}, {a, b, c, g}, {x, y}] / dual().sConnectedComponents(s: 1) / dual().sConnectedComponents(s: 2) / dual().sConnectedComponents(s: 3) | [[0, 1, 2, 3, 4, 5, 6], [7, 8]]; [[0, 1, 2, 3, 4], [5], [6], [7], [8]]; [[0], [1], [2], [3], [4], [5], [6], [7], [8]] |
| HG-078 | Equality | same hypergraph | U V [a]; E [{a, b}] == U V [a, b]; E [{b, a}] | true |
| HG-079 | Equality | different vertex order and hyperedge order | U V [c, b, a]; E [{a, b}, {c}] == U V [a, b, c]; E [{c}, {b, a}] | true |
| HG-080 | Equality | multiplicity matters | U V []; E [{a, b}] == U V []; E [{a, b}, {a, b}] | false |
| HG-081 | Equality | an empty hyperedge matters | U V []; E [{a, b}] == U V []; E [{a, b}, {}] | false |
| HG-082 | Equality | an isolated vertex matters | U V []; E [{a, b}] == U V [c]; E [{a, b}] | false |
| HG-083 | Equality | different member sets | U V []; E [{a, b}, {c}] == U V []; E [{a}, {b, c}] | false |
| HG-084 | Hashing | equal hypergraphs hash equal | Set([U V [c, b, a]; E [{a, b}, {c}], U V [a, b, c]; E [{c}, {b, a}]]).count | 1 |
| HG-085 | Hashing | different multiplicity | Set([U V []; E [{a, b}], U V []; E [{a, b}, {a, b}]]).count | 2 |
| HG-086 | Description | description: String(reflecting:) vertices, then hyperedges by position | U V []; E [{a, b}, {}, {b, c}] / description / debugDescription | ["a", "b", "c"]; [{"a", "b"}, {}, {"b", "c"}]; UndirectedIncidenceList<String>(vertexCount: 3, hyperedgeCount: 3, vertices: ["a", "b", "c"], hyperedges: [{"a", "b"}, {}, {"b", "c"}]) |
| HG-087 | Description | empty | U V []; E [] / description / debugDescription | []; []; UndirectedIncidenceList<String>(vertexCount: 0, hyperedgeCount: 0, vertices: [], hyperedges: []) |
| HG-088 | Description | at most 16 vertices and 16 hyperedges, then … | U V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]; E [{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}] / description | [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, …]; [{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, …] |
| HG-089 | Codable | encodes vertices in index order and hyperedges as ascending index rows | U V []; E [{a, b}, {}, {b, c}] / JSONEncoder().encode(self) | {"vertices":["a","b","c"],"hyperedges":[[0,1],[],[1,2]]} |
| HG-090 | Codable | decodes, keeping vertex order and positions | decode {"vertices":["b","a"],"hyperedges":[[0,1],[]]} | V [b#0, a#1]; E [0:{b, a}, 1:{}] |
| HG-091 | Codable | rejects a repeated vertex | decode {"vertices":["a","a"],"hyperedges":[]} | throws DecodingError.dataCorrupted (repeated vertex) |
| HG-092 | Codable | rejects a member index out of range | decode {"vertices":["a"],"hyperedges":[[1]]} | throws DecodingError.dataCorrupted (member index out of range) |
| HG-093 | Codable | rejects a repeated member inside one hyperedge | decode {"vertices":["a","b"],"hyperedges":[[0,0]]} | throws DecodingError.dataCorrupted (members not strictly ascending) |
| HG-094 | Codable | rejects members out of order (the encoder writes them ascending) | decode {"vertices":["a","b"],"hyperedges":[[1,0]]} | throws DecodingError.dataCorrupted (members not strictly ascending) |
| DH-001 | Construction | empty | D V []; E [] | V []; E [] |
| DH-002 | Construction | listed vertices first, then sources then targets of each hyperedge by first appearance | D V [z]; E [{x, z}→{y}, {w}→{x}] | V [z#0, x#1, y#2, w#3]; E [0:{z, x}→{y}, 1:{w}→{x}] |
| DH-003 | Construction | each side stored in vertex-index order | D V [a, b, c, d]; E [{c, a}→{d, b}] / sources(ofHyperedgeAt: 0) / targets(ofHyperedgeAt: 0) / sourceIndices(ofHyperedgeAt: 0) / targetIndices(ofHyperedgeAt: 0) | [a, c]; [b, d]; [0, 2]; [1, 3] ⇒ V [a#0, b#1, c#2, d#3]; E [0:{a, c}→{b, d}] |
| DH-004 | Construction | a repeated member within a side is stored once | D V []; E [{a, a}→{b, b}] | V [a#0, b#1]; E [0:{a}→{b}] |
| DH-005 | Construction | a vertex may be a source and a target of the same hyperedge (XGI allows it; Gallo et al. require disjoint sides) | D V []; E [{a, b}→{b, c}] / outHyperedges(of: b) / inHyperedges(of: b) / degree(of: b) | [0]; [0]; 2 ⇒ V [a#0, b#1, c#2]; E [0:{a, b}→{b, c}] |
| DH-006 | Construction | empty sides and the empty hyperedge are kept | D V []; E [{}→{a}, {a}→{}, {a}→{b}, {}→{}] / vertexCount/hyperedgeCount | 2/4 ⇒ V [a#0, b#1]; E [0:{}→{a}, 1:{a}→{}, 2:{a}→{b}, 3:{}→{}] |
| DH-007 | Construction | a repeated hyperedge is kept, each its own position | D V []; E [{a}→{b}, {a}→{b}] / outHyperedges(of: a) / inHyperedges(of: b) | [0, 1]; [0, 1] ⇒ V [a#0, b#1]; E [0:{a}→{b}, 1:{a}→{b}] |
| DH-008 | Reads | out- and in-hyperedges ascend by position (Gallo's forward and backward stars) | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(of: a) / inHyperedges(of: c) / outHyperedges(of: c) / inHyperedges(of: a) | [0, 4]; [0, 2, 4]; [1, 2]; [] |
| DH-009 | Reads | degrees: in + out, so a vertex on both sides of one hyperedge counts it twice (XGI's degree: once) | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outDegree(of: c) / inDegree(of: c) / degree(of: c) / degree(of: e) | 2; 3; 5; 2 |
| DH-010 | Reads | contains(sources:targets:) compares both sides as sets | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / contains(sources: [c, b], targets: [e, d]) / contains(sources: [d, e], targets: [b, c]) / contains(sources: [], targets: []) / contains(sources: [a], targets: [z]) | true; false; true; false |
| DH-011 | Reads | index-space reads hash nothing; a vertex-space read hashes once | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(ofIndex: 2) / inHyperedges(ofIndex: 2) / sourceIndices(ofHyperedgeAt: 1) / hashes() / outHyperedges(of: c) / hashes() | [1, 2]; [0, 2, 4]; [1, 2]; 0; [1, 2]; 1 |
| DH-012 | Reads | checked: spellings throw for a non-vertex | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(checked: z) / vertexIndex(checked: z) / outHyperedges(checked: a) / hashes() | throws VertexNotFound; throws VertexNotFound; [0, 4]; 3 |
| DH-013 | Traps | outHyperedges(of:) on a non-vertex | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outHyperedges(of: z) | **trap** (z is not a vertex of the hypergraph) |
| DH-014 | Traps | sources(ofHyperedgeAt:) past the end | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / sources(ofHyperedgeAt: 5) | **trap** (hyperedge position out of range) |
| DH-015 | Traps | inHyperedges(ofIndex:) past the end | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / inHyperedges(ofIndex: 5) | **trap** (vertex index out of range) |
| DH-016 | Traps | bConnectedVertices(from:) on a non-vertex | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / bConnectedVertices(from: z) | **trap** (z is not a vertex of the hypergraph) |
| DH-017 | Traps | isFConnected(from:to:) with a non-vertex | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / isFConnected(from: a, to: z) | **trap** (z is not a vertex of the hypergraph) |
| DH-018 | Mutation | insert(sources:targets:) appends, inserting missing vertices | D V [a]; E [] / insert(sources: [b, a], targets: [c]) / outHyperedges(of: a) | 0; [0] ⇒ V [a#0, b#1, c#2]; E [0:{a, b}→{c}] |
| DH-019 | Mutation | insert(checked:targets:) with every vertex present | D V [a, b]; E [] / insert(checked: [a], targets: [b]) | 0 ⇒ V [a#0, b#1]; E [0:{a}→{b}] |
| DH-020 | Mutation | insert(checked:targets:) with a missing vertex: throws, nothing changes | D V [a, b]; E [] / insert(checked: [a], targets: [z]) / vertexCount/hyperedgeCount | throws VertexNotFound; 2/0 ⇒ V [a#0, b#1]; E [] |
| DH-021 | Mutation | removeAll | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / removeAll() / vertexCount/hyperedgeCount | (); 0/0 ⇒ V []; E [] |
| DH-022 | Reversal | reversed swaps sources and targets (Gallo's symmetric image) | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / reversed | V [a#0, b#1, c#2, d#3, e#4]; E [0:{b, c}→{a}, 1:{d, e}→{b, c}, 2:{c, e}→{c}, 3:{}→{}, 4:{b, c}→{a}] |
| DH-023 | Dual | hyperedge i of the dual has sources = out-hyperedges of i, targets = in-hyperedges of i (the transpose) | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / dual() | V [0#0, 1#1, 2#2, 3#3, 4#4]; E [0:{0, 4}→{}, 1:{1}→{0, 4}, 2:{1, 2}→{0, 2, 4}, 3:{}→{1}, 4:{}→{1, 2}] |
| DH-024 | Dual | an isolated vertex becomes the empty hyperedge and back | D V [z]; E [{}→{}] / dual() | V [0#0]; E [0:{}→{}] |
| DH-025 | Incidence graph | sources → hyperedge → targets: source incidences first, then target incidences (XGI directed to_bipartite_graph) | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / incidenceGraphView | vertices 0..<10; edges [0→5, 1→6, 2→6, 2→7, 0→9, 5→1, 5→2, 6→3, 6→4, 7→2, 7→4, 9→1, 9→2] |
| DH-026 | Incidence graph | a vertex on both sides gives a 2-cycle through its hyperedge | D V []; E [{a}→{a, b}] / incidenceGraphView | vertices 0..<3; edges [0→2, 2→0, 2→1] |
| DH-027 | Components | weak components join sources and targets; isolated vertices alone | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / weaklyConnectedComponents() / isWeaklyConnected | [[a, b, c, d, e, f], [g]]; false |
| DH-028 | Components | strong components through the incidence graph: a → c → d → f → a is a cycle, b and e are not on it | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / stronglyConnectedComponents() / isStronglyConnected | [[a, c, d, f], [b], [e], [g]]; false |
| DH-029 | Components | a two-way pair is strongly connected | D V []; E [{a}→{b}, {b}→{a}] / stronglyConnectedComponents() / isStronglyConnected | [[a, b]]; true |
| DH-030 | Components | empty: no components, not connected | D V []; E [] / weaklyConnectedComponents() / isWeaklyConnected / stronglyConnectedComponents() / isStronglyConnected | []; false; []; false |
| DH-031 | B-connectivity | B-visit: a hyperedge fires once every source is reached (halp b_visit) | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / bConnectedVertices(from: a) / bConnectedVertices(from: c) / bConnectedVertices(from: e) | [a]; [c, d]; [e] |
| DH-032 | B-connectivity | isBConnected(from:to:) is weaker than connection: c is reached from a, not B-connected | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / isBConnected(from: a, to: c) / isBConnected(from: c, to: a) / isBConnected(from: a, to: a) | false; false; true |
| DH-033 | B-connectivity | a hyperedge with no sources never fires; one with no targets reaches nothing | D V []; E [{}→{a}, {a}→{}, {a}→{b}] / bConnectedVertices(from: a) / bConnectedVertices(from: b) | [a, b]; [b] |
| DH-034 | B-connectivity | from a, hyperedge 0 fires, then 1 once b and c are both reached; from c, hyperedge 2 fires although c is also its target | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / bConnectedVertices(from: a) / bConnectedVertices(from: c) | [a, b, c, d, e]; [c, e] |
| DH-035 | F-connectivity | F-visit starts at the destination t and returns every s with t F-connected to s (halp f_visit) | D V []; E [{a}→{b, c}, {b}→{d}, {c}→{d}, {d}→{e}] / fConnectedVertices(to: d) / fConnectedVertices(to: e) / fConnectedVertices(to: b) | [a, b, c, d]; [a, b, c, d, e]; [b] |
| DH-036 | F-connectivity | isFConnected(from:to:): every target of a used hyperedge must lead on to t, so a reaches b but is not F-connected to it | D V []; E [{a}→{b, c}, {b}→{d}, {c}→{d}, {d}→{e}] / isFConnected(from: a, to: d) / isFConnected(from: a, to: b) / isFConnected(from: b, to: e) | true; false; true |
| DH-037 | F-connectivity | F-visit is B-visit on the reversal: from a, then f, then d and e, then c, then b | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / fConnectedVertices(to: a) / fConnectedVertices(to: d) | [a, b, c, d, e, f]; [a, b, c, d, e, f] |
| DH-038 | Hyperedge classes | B-graph, F-graph and BF-graph (Gallo et al.; halp is_B_hypergraph) | D V [a, b, c, d, e, f, g]; E [{a, b}→{c}, {c}→{d}, {d, e}→{f}, {f}→{a}] / isBHypergraph / isFHypergraph / isBFHypergraph | true; false; true |
| DH-039 | Hyperedge classes | a general hyperarc makes it none of the three | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / isBHypergraph / isFHypergraph / isBFHypergraph | false; false; false |
| DH-040 | Hyperedge classes | no hyperedges: all three, vacuously | D V [a]; E [] / isBHypergraph / isFHypergraph / isBFHypergraph | true; true; true |
| DH-041 | Clique expansion | every vertex; an arc from each source to each target, once, no self-loops | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / cliqueExpansion() | vertices [a, b, c, d, e]; edges [a→b, a→c, b→d, b→e, c→d, c→e] |
| DH-042 | Clique expansion | empty sides add no arc | D V []; E [{}→{a}, {a}→{}, {a}→{b}] / cliqueExpansion() | vertices [a, b]; edges [a→b] |
| DH-043 | Measures | out- and in-degree histograms | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / outDegreeHistogram() / inDegreeHistogram() | [2, 1, 2]; [1, 1, 2, 1] |
| DH-044 | Measures | source- and target-size histograms (XGI tail_size, head_size) | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / sourceSizeHistogram() / targetSizeHistogram() | [1, 3, 1]; [1, 0, 4] |
| DH-045 | Measures | histograms of the empty hypergraph are empty | D V []; E [] / outDegreeHistogram() / sourceSizeHistogram() | []; [] |
| DH-046 | Equality | same hypergraph, any vertex and hyperedge order | D V [c]; E [{a}→{b, c}, {c}→{}] == D V []; E [{c}→{}, {a}→{c, b}] | true |
| DH-047 | Equality | direction matters | D V []; E [{a}→{b}] == D V []; E [{b}→{a}] | false |
| DH-048 | Equality | a vertex on both sides differs from it on one | D V []; E [{a}→{a, b}] == D V []; E [{a}→{b}] | false |
| DH-049 | Equality | multiplicity matters | D V []; E [{a}→{b}] == D V []; E [{a}→{b}, {a}→{b}] | false |
| DH-050 | Hashing | equal hypergraphs hash equal | Set([D V [c]; E [{a}→{b, c}], D V []; E [{a}→{c, b}]]).count | 1 |
| DH-051 | Description | description: vertices, then sources→targets by position | D V []; E [{a, b}→{c}, {}→{}] / description / debugDescription | ["a", "b", "c"]; [{"a", "b"}→{"c"}, {}→{}]; IncidenceList<String>(vertexCount: 3, hyperedgeCount: 2, vertices: ["a", "b", "c"], hyperedges: [{"a", "b"}→{"c"}, {}→{}]) |
| DH-052 | Codable | encodes vertices, then parallel source and target rows | D V []; E [{a, b}→{c}, {}→{a}] / JSONEncoder().encode(self) | {"vertices":["a","b","c"],"sources":[[0,1],[]],"targets":[[2],[0]]} |
| DH-053 | Codable | decodes | decode {"vertices":["a","b"],"sources":[[0],[]],"targets":[[0,1],[1]]} | V [a#0, b#1]; E [0:{a}→{a, b}, 1:{}→{b}] |
| DH-054 | Codable | rejects source and target lists of different lengths | decode {"vertices":["a"],"sources":[[0]],"targets":[]} | throws DecodingError.dataCorrupted (sources and targets differ in length) |
| DH-055 | Codable | rejects a repeated member inside one side | decode {"vertices":["a","b"],"sources":[[1,1]],"targets":[[]]} | throws DecodingError.dataCorrupted (members not strictly ascending) |
| DH-056 | Codable | rejects an index out of range | decode {"vertices":["a"],"sources":[[]],"targets":[[3]]} | throws DecodingError.dataCorrupted (member index out of range) |
| DH-057 | Reads | the other checked: reads answer a vertex and throw for a non-vertex | D V [a, b, c, d, e]; E [{a}→{b, c}, {b, c}→{d, e}, {c}→{c, e}, {}→{}, {a}→{b, c}] / inHyperedges(checked: c) / outDegree(checked: c) / inDegree(checked: c) / degree(checked: c) / degree(checked: z) / inHyperedges(checked: z) / outDegree(checked: z) / inDegree(checked: z) / hashes() | [0, 2, 4]; 2; 3; 5; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; 8 |
