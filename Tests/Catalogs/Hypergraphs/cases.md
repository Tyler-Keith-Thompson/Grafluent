# Hypergraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2
--with hypernetx==2.4.3 python3 Tests/Catalogs/Hypergraphs/ref.py`; `--write` regenerates this file,
`--stress` adds the random hypergraphs and mutation sequences). Every state is checked against XGI 0.10.2,
HyperNetX 2.4.3 (empty hyperedges mapped back, since it drops them), NetworkX 3.7 on the incidence graph,
and the `HypergraphProtocol` laws.

Conventions:

* `H V [...]; E [{...}, ...]` is `Hypergraph<String>(vertices: V, hyperedges: E)` (`Hypergraph<Int>` when
  the labels are numbers). Calls follow, separated by `/`.
* Expected lists each call's result, then `⇒` and the final state where it matters. State: `V [v#i, …]` is
  `vertices` with each vertex's index; `E [p:{…}, …]` is `hyperedges` by position, members in vertex-index order.
* A `dual()` result prints as a state over `Int` vertices (hyperedge positions of the original).
* `incidenceGraph` prints `N vertices; [u–v, …]` in edge-index order: vertex index `i` is `i`, hyperedge `p`
  is `n + p`. `cliqueExpansion()` prints labeled pairs; `lineGraph(s:)` prints position pairs. All in
  edge-position order.
* `hashes()` is the number of vertex lookups so far (a benchmark counter, not API: the Swift suite counts
  with a `Vertex` whose `hash(into:)` counts).
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before the
  trap are listed.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| HG-001 | Construction | empty | H V []; E [] | V []; E [] |
| HG-002 | Construction | isolated vertices in listed order | H V [a, b, c]; E [] | V [a#0, b#1, c#2]; E [] |
| HG-003 | Construction | vertices by first appearance in the hyperedges | H V []; E [{c, a}, {b, c}] | V [c#0, a#1, b#2]; E [0:{c, a}, 1:{c, b}] |
| HG-004 | Construction | listed vertices first, then new members | H V [z]; E [{x, z}, {z, y}] | V [z#0, x#1, y#2]; E [0:{z, x}, 1:{z, y}] |
| HG-005 | Construction | members stored in vertex-index order, not input order | H V [a, b, c]; E [{c, a, b}] / members(ofHyperedgeAt: 0) / memberIndices(ofHyperedgeAt: 0) | [a, b, c]; [0, 1, 2] ⇒ V [a#0, b#1, c#2]; E [0:{a, b, c}] |
| HG-006 | Construction | a repeated member is stored once | H V []; E [{a, b, a}] / size(ofHyperedgeAt: 0) | 2 ⇒ V [a#0, b#1]; E [0:{a, b}] |
| HG-007 | Construction | a repeated hyperedge is kept (multi-hyperedge), each its own position | H V []; E [{a, b}, {b, a}] / incidentHyperedges(of: a) / degree(of: a) | [0, 1]; 2 ⇒ V [a#0, b#1]; E [0:{a, b}, 1:{a, b}] |
| HG-008 | Construction | an empty hyperedge is kept | H V []; E [{a, b}, {}, {b, c}] / size(ofHyperedgeAt: 1) / vertexCount/hyperedgeCount | 0; 3/3 ⇒ V [a#0, b#1, c#2]; E [0:{a, b}, 1:{}, 2:{b, c}] |
| HG-009 | Construction | a singleton hyperedge | H V []; E [{a}] / degree(of: a) / neighbors(of: a) | 1; [] ⇒ V [a#0]; E [0:{a}] |
| HG-010 | Construction | a repeated vertex in the vertex list is inserted once | H V [a, a, b]; E [] / vertexCount/hyperedgeCount | 2/0 ⇒ V [a#0, b#1]; E [] |
| HG-011 | Construction | Int vertices are labels, not indices | H V [5, 3]; E [{3, 7}] / vertexIndex(of: 3) / vertex(atIndex: 2) / members(ofHyperedgeAt: 0) | 1; 7; [3, 7] ⇒ V [5#0, 3#1, 7#2]; E [0:{3, 7}] |
| HG-012 | Reads | members of each hyperedge | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / members(ofHyperedgeAt: 0) / members(ofHyperedgeAt: 1) / members(ofHyperedgeAt: 3) | [a, b, c]; [c, d]; [e] ⇒ V [a#0, b#1, c#2, d#3, e#4, f#5]; E [0:{a, b, c}, 1:{c, d}, 2:{a, b, c}, 3:{e}] |
| HG-013 | Reads | sizes | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / size(ofHyperedgeAt: 0) / size(ofHyperedgeAt: 1) / size(ofHyperedgeAt: 3) | 3; 2; 1 |
| HG-014 | Reads | incident hyperedges in ascending position | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(of: c) / incidentHyperedges(of: a) / incidentHyperedges(of: f) | [0, 1, 2]; [0, 2]; [] |
| HG-015 | Reads | degree counts each copy of a repeated hyperedge | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / degree(of: a) / degree(of: c) / degree(of: e) / degree(of: f) | 2; 3; 1; 0 |
| HG-016 | Reads | counts | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / vertexCount/hyperedgeCount | 6/4 |
| HG-017 | Reads | contains | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / contains(a) / contains(z) | true; false |
| HG-018 | Reads | contains(hyperedge:) compares member sets, any order | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / contains(hyperedge: [c, b, a]) / contains(hyperedge: [a, b]) / contains(hyperedge: [e]) / contains(hyperedge: [z]) | true; false; true; false |
| HG-019 | Reads | contains(hyperedge:) of the empty set | H V []; E [{a, b}, {}, {b, c}] / contains(hyperedge: []) | true |
| HG-020 | Reads | contains(hyperedge:) of the empty set, none stored | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / contains(hyperedge: []) | false |
| HG-021 | Reads | vertex indices round trip | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / vertexIndex(of: d) / vertex(atIndex: 3) / vertexIndex(safe: z) | 3; d; nil |
| HG-022 | Reads | index-space reads hash nothing; a vertex-space read hashes once | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(ofIndex: 2) / degree(ofIndex: 2) / memberIndices(ofHyperedgeAt: 0) / hashes() / incidentHyperedges(of: c) / hashes() | [0, 1, 2]; 3; [0, 1, 2]; 0; [0, 1, 2]; 1 |
| HG-023 | Reads | safe: spellings return nil for a non-vertex | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(safe: z) / degree(safe: z) / incidentHyperedges(safe: c) / degree(safe: c) / hashes() | nil; nil; [0, 1, 2]; 3; 4 |
| HG-024 | Reads | neighbors: vertices sharing a hyperedge, once each, in index order, never itself | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / neighbors(of: c) / neighbors(of: e) / neighbors(of: f) | [a, b, d]; []; [] |
| HG-025 | Traps | incidentHyperedges(of:) on a non-vertex | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(of: z) | **trap** (z is not a vertex of the hypergraph) |
| HG-026 | Traps | degree(of:) on a non-vertex | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / degree(of: z) | **trap** (z is not a vertex of the hypergraph) |
| HG-027 | Traps | neighbors(of:) on a non-vertex | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / neighbors(of: z) | **trap** (z is not a vertex of the hypergraph) |
| HG-028 | Traps | members(ofHyperedgeAt:) past the end | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / members(ofHyperedgeAt: 4) | **trap** (hyperedge position out of range) |
| HG-029 | Traps | members(ofHyperedgeAt:) negative | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / members(ofHyperedgeAt: -1) | **trap** (hyperedge position out of range) |
| HG-030 | Traps | vertex(atIndex:) past the end | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / vertex(atIndex: 6) | **trap** (vertex index out of range) |
| HG-031 | Traps | incidentHyperedges(ofIndex:) past the end | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidentHyperedges(ofIndex: 6) | **trap** (vertex index out of range) |
| HG-032 | Traps | lineGraph(s: 0) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / lineGraph(s: 0) | **trap** (s must be at least 1) |
| HG-033 | Traps | sConnectedComponents(s: 0) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / sConnectedComponents(s: 0) | **trap** (s must be at least 1) |
| HG-034 | Traps | isUniform(size: -1) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / isUniform(size: -1) | **trap** (size must not be negative) |
| HG-035 | Mutation | insert a new vertex, then an existing one | H V [a]; E [] / insert(b) / insert(a) | (true, b); (false, a) ⇒ V [a#0, b#1]; E [] |
| HG-036 | Mutation | insert(hyperedge:) returns the new position and inserts missing members | H V [a]; E [{a}] / insert(hyperedge: [c, a, b]) / incidentHyperedges(of: a) | 1; [0, 1] ⇒ V [a#0, c#1, b#2]; E [0:{a}, 1:{a, c, b}] |
| HG-037 | Mutation | insert(hyperedge:) of an existing member set adds a copy | H V []; E [{a, b}] / insert(hyperedge: [b, a]) / vertexCount/hyperedgeCount | 1; 2/2 ⇒ V [a#0, b#1]; E [0:{a, b}, 1:{a, b}] |
| HG-038 | Mutation | insert(hyperedge:) of the empty set | H V [a]; E [] / insert(hyperedge: []) / size(ofHyperedgeAt: 0) | 0; 0 ⇒ V [a#0]; E [0:{}] |
| HG-039 | Mutation | insert(safe:) with every member present | H V [a, b]; E [] / insert(safe: [a, b]) | 0 ⇒ V [a#0, b#1]; E [0:{a, b}] |
| HG-040 | Mutation | insert(safe:) with a missing member: nil, nothing changes | H V [a, b]; E [] / insert(safe: [a, z]) / vertexCount/hyperedgeCount | nil; 2/0 ⇒ V [a#0, b#1]; E [] |
| HG-041 | Mutation | removeAll | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / removeAll() / vertexCount/hyperedgeCount | (); 0/0 ⇒ V []; E [] |
| HG-042 | Mutation | incidence rows stay ascending under appends | H V [a, b]; E [{b}] / insert(hyperedge: [a]) / insert(hyperedge: [b, a]) / incidentHyperedges(of: b) / incidentHyperedges(of: a) | 1; 2; [0, 2]; [1, 2] ⇒ V [a#0, b#1]; E [0:{b}, 1:{a}, 2:{a, b}] |
| HG-043 | Measures | rank is the greatest size | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / rank | 3 |
| HG-044 | Measures | rank with no hyperedges is 0 | H V [a]; E [] / rank | 0 |
| HG-045 | Measures | rank with only an empty hyperedge is 0 | H V []; E [{}] / rank | 0 |
| HG-046 | Measures | isUniform(size:) | H V []; E [{a, b}, {b, c}, {c, a}] / isUniform(size: 2) / isUniform(size: 3) | true; false |
| HG-047 | Measures | not uniform: mixed sizes | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / isUniform(size: 3) | false |
| HG-048 | Measures | singletons count (XGI's is_uniform ignores them) | H V []; E [{a}, {b}] / isUniform(size: 1) / isUniform(size: 2) | true; false |
| HG-049 | Measures | no hyperedges: uniform for every size, vacuously (XGI: False) | H V [a]; E [] / isUniform(size: 0) / isUniform(size: 3) | true; true |
| HG-050 | Measures | an empty hyperedge has size 0 | H V []; E [{a, b}, {}, {b, c}] / isUniform(size: 2) | false |
| HG-051 | Measures | degree histogram (NetworkX's degree_histogram shape) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / degreeHistogram() | [1, 2, 2, 1] |
| HG-052 | Measures | hyperedge size histogram | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / hyperedgeSizeHistogram() | [0, 1, 1, 2] |
| HG-053 | Measures | histograms of the empty hypergraph are empty | H V []; E [] / degreeHistogram() / hyperedgeSizeHistogram() | []; [] |
| HG-054 | Measures | histograms with an empty hyperedge | H V []; E [{a, b}, {}, {b, c}] / degreeHistogram() / hyperedgeSizeHistogram() | [0, 2, 1]; [1, 0, 2] |
| HG-055 | Dual | vertices are hyperedge positions; hyperedge i is vertex i's incidence row | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / dual() | V [0#0, 1#1, 2#2, 3#3]; E [0:{0, 2}, 1:{0, 2}, 2:{0, 1, 2}, 3:{1}, 4:{3}, 5:{}] |
| HG-056 | Dual | an isolated vertex becomes an empty hyperedge, an empty hyperedge an isolated vertex | H V []; E [{a, b}, {}, {b, c}, {d}] / insert(z) / dual() | (true, z); V [0#0, 1#1, 2#2, 3#3]; E [0:{0}, 1:{0, 2}, 2:{2}, 3:{3}, 4:{}] |
| HG-057 | Dual | of the empty hypergraph | H V []; E [] / dual() | V []; E [] |
| HG-058 | Dual | repeated hyperedges become vertices with equal incidence rows | H V []; E [{a, b}, {a, b}] / dual() | V [0#0, 1#1]; E [0:{0, 1}, 1:{0, 1}] |
| HG-059 | Incidence graph | vertices 0..<n then n + p; edge k is the k-th incidence (XGI to_bipartite_graph numbering) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / incidenceGraph() | 10 vertices; [0–6, 1–6, 2–6, 2–7, 3–7, 0–8, 1–8, 2–8, 4–9] |
| HG-060 | Incidence graph | an empty hyperedge is an isolated vertex | H V []; E [{a, b}, {}, {b, c}] / incidenceGraph() | 6 vertices; [0–3, 1–3, 1–5, 2–5] |
| HG-061 | Incidence graph | repeated hyperedges are distinct vertices; the view stays simple | H V []; E [{a, b}, {a, b}] / incidenceGraph() | 4 vertices; [0–2, 1–2, 0–3, 1–3] |
| HG-062 | Clique expansion | each pair once, sorted by index pair (XGI to_graph) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / cliqueExpansion() | [a–b, a–c, b–c, c–d] |
| HG-063 | Clique expansion | singletons and empty hyperedges add no edge; no self-loops | H V []; E [{a}, {}, {a, b}] / cliqueExpansion() | [a–b] |
| HG-064 | Clique expansion | a 4-member hyperedge is K4 | H V []; E [{a, b, c, d}] / cliqueExpansion() | [a–b, a–c, a–d, b–c, b–d, c–d] |
| HG-065 | Line graph | s = 1: hyperedges sharing a vertex (XGI to_line_graph, HyperNetX get_linegraph) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / lineGraph(s: 1) | [0–1, 0–2, 1–2] |
| HG-066 | Line graph | s = 1, 2, 3 on overlaps of 1, 2 and 3 | H V []; E [{a, b, c, d}, {c, d, e}, {d, e, f}, {a, b, c, g}, {x, y}] / lineGraph(s: 1) / lineGraph(s: 2) / lineGraph(s: 3) | [0–1, 0–2, 0–3, 1–2, 1–3]; [0–1, 0–3, 1–2]; [0–3] |
| HG-067 | Line graph | an empty hyperedge is isolated | H V []; E [{a, b}, {}, {b, c}] / lineGraph(s: 1) | [0–2] |
| HG-068 | Line graph | repeated hyperedges are adjacent at s = their size | H V []; E [{a, b}, {a, b}] / lineGraph(s: 2) / lineGraph(s: 3) | [0–1]; [] |
| HG-069 | Connectivity | components by least vertex index, isolated vertices alone (XGI) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / connectedComponents() / isConnected | [[a, b, c, d], [e], [f]]; false |
| HG-070 | Connectivity | one hyperedge joins all its members | H V []; E [{a, b, c}] / connectedComponents() / isConnected | [[a, b, c]]; true |
| HG-071 | Connectivity | empty hypergraph: no components, not connected (XGI raises) | H V []; E [] / connectedComponents() / isConnected | []; false |
| HG-072 | Connectivity | an empty hyperedge joins nothing | H V [a, b]; E [{}] / connectedComponents() / isConnected | [[a], [b]]; false |
| HG-073 | Connectivity | a chain of hyperedges | H V []; E [{a, b}, {b, c}, {c, d}, {e, f}, {f, a}] / connectedComponents() / isConnected | [[a, b, c, d, e, f]]; true |
| HG-074 | s-connectivity | hyperedge s-components, s = 1, 2, 3 (HyperNetX s_components, edges=True) | H V []; E [{a, b, c, d}, {c, d, e}, {d, e, f}, {a, b, c, g}, {x, y}] / sConnectedComponents(s: 1) / sConnectedComponents(s: 2) / sConnectedComponents(s: 3) | [[0, 1, 2, 3], [4]]; [[0, 1, 2, 3], [4]]; [[0, 3], [1], [2], [4]] |
| HG-075 | s-connectivity | singletons kept (HyperNetX's s_connected_components drops them by default) | H V [a, b, c, d, e, f]; E [{a, b, c}, {c, d}, {a, b, c}, {e}] / sConnectedComponents(s: 2) | [[0, 2], [1], [3]] |
| HG-076 | s-connectivity | an empty hyperedge is its own s-component (HyperNetX drops it) | H V []; E [{a, b}, {}, {b, c}] / sConnectedComponents(s: 1) | [[0, 2], [1]] |
| HG-077 | s-connectivity | vertex s-components are the dual's (HyperNetX edges=False) | H V []; E [{a, b, c, d}, {c, d, e}, {d, e, f}, {a, b, c, g}, {x, y}] / dual().sConnectedComponents(s: 1) / dual().sConnectedComponents(s: 2) / dual().sConnectedComponents(s: 3) | [[0, 1, 2, 3, 4, 5, 6], [7, 8]]; [[0, 1, 2, 3, 4], [5], [6], [7], [8]]; [[0], [1], [2], [3], [4], [5], [6], [7], [8]] |
| HG-078 | Equality | same hypergraph | H V [a]; E [{a, b}] == H V [a, b]; E [{b, a}] | true |
| HG-079 | Equality | different vertex order and hyperedge order | H V [c, b, a]; E [{a, b}, {c}] == H V [a, b, c]; E [{c}, {b, a}] | true |
| HG-080 | Equality | multiplicity matters | H V []; E [{a, b}] == H V []; E [{a, b}, {a, b}] | false |
| HG-081 | Equality | an empty hyperedge matters | H V []; E [{a, b}] == H V []; E [{a, b}, {}] | false |
| HG-082 | Equality | an isolated vertex matters | H V []; E [{a, b}] == H V [c]; E [{a, b}] | false |
| HG-083 | Equality | different member sets | H V []; E [{a, b}, {c}] == H V []; E [{a}, {b, c}] | false |
| HG-084 | Hashing | equal hypergraphs hash equal | Set([H V [c, b, a]; E [{a, b}, {c}], H V [a, b, c]; E [{c}, {b, a}]]).count | 1 |
| HG-085 | Hashing | different multiplicity | Set([H V []; E [{a, b}], H V []; E [{a, b}, {a, b}]]).count | 2 |
