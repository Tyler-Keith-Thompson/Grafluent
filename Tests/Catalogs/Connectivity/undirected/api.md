# Connectivity, undirected half: proposed API

Scope: connected components of an undirected `Graph`, bridges, articulation points, biconnected
components (blocks), bi-edge-connected (2-edge-connected) components, the block–cut tree, and the
predicates `isConnected`, `hasBridges`, `isBiconnected`, `isBiEdgeConnected`. Everything is on
`Graph`; nothing new is on `DirectedGraph` (it already has `weaklyConnectedComponents()`). A
bidirectional digraph reaches all of it through `.undirected`.

Out of scope, and where it goes: vertex and edge connectivity κ(G), λ(G), k-connectivity tests,
minimum vertex and edge cuts, `k_edge_components` for k ≥ 3, Gomory–Hu trees (all **Flows**:
they need max-flow; NetworkX `node_connectivity`, `edge_connectivity`, `minimum_node_cut`, JGraphT
`KConnectivityFlowAlgorithm`, igraph `vertex_connectivity`); NetworkX `local_bridges` (a
shortest-path notion with spans and weights, not a cut, so not here); `chain_decomposition`
(NetworkX's internal route to bridges, not a result anyone else exposes); `bridges(root:)` and
`node_connected_component` (a component of one vertex is `components[components.component(of: v)]`,
or a breadth-first search from `Traversal`); dynamic connectivity (JGraphT
`TreeDynamicConnectivity`); igraph's `cohesive_blocks`.

## Summary

```swift
extension Graph {
    // Components
    func connectedComponents() -> Components<DirectedView<Self>>
    var isConnected: Bool

    // Bridges and articulation points
    func bridges() -> [Edges.Index]                       // ascending position
    var hasBridges: Bool
    func articulationPoints() -> [Vertex]                 // vertices order

    // Blocks
    func biconnectedComponents() -> BiconnectedComponents<Self>
    var isBiconnected: Bool

    // 2-edge-connected components
    func biEdgeConnectedComponents() -> Components<DirectedView<Self>>
    var isBiEdgeConnected: Bool

    // Block–cut tree
    func blockCutTree() -> BlockCutTree<Self>
}

@frozen
struct BiconnectedComponents<G: Graph>: RandomAccessCollection   // Index == Int, Indices == Range<Int>
        // Equatable; Sendable where G, G.Vertex, G.Edges.Index are; CustomStringConvertible
    subscript(position: Int) -> ArraySlice<G.Edges.Index>         // a block's edges, ascending position
    func vertices(ofComponentAt position: Int) -> ArraySlice<G.Vertex>   // vertices order
    func component(ofEdgeAt position: G.Edges.Index) -> Int?      // nil for a self-loop
    func components(containing vertex: G.Vertex) -> ArraySlice<Int>     // ascending; empty when none

@frozen
struct BlockCutTree<G: Graph>
        // Equatable; Sendable as above
    let blocks: BiconnectedComponents<G>
    let articulationPoints: [G.Vertex]                            // vertices order
    func articulationPoints(ofBlock block: Int) -> ArraySlice<Int>       // indices into articulationPoints, ascending
    func blocks(ofArticulationPoint point: Int) -> ArraySlice<Int>       // block positions, ascending
    func node(of vertex: G.Vertex) -> Node?
    var edgeCount: Int
    @frozen enum Node: Hashable, Sendable { case block(Int), articulationPoint(Int) }
```

## Names

The README rule: the names the major libraries share, familiar ones first; the mathematical
term only when there is no common one.

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `connectedComponents()` | NetworkX `connected_components`, Boost `connected_components`, igraph `igraph_connected_components`, petgraph `connected_components` (a count), LEMON `connectedComponents`, JGraphT `connectedSets` | — |
| `isConnected` | NetworkX `is_connected`, JGraphT `isConnected`, igraph `igraph_is_connected`, LEMON `connected` | — |
| `bridges()` | NetworkX `bridges`, JGraphT `getBridges`, igraph `igraph_bridges`, petgraph `algo::bridges`, rustworkx `bridges` | "cut edges" (LEMON `biEdgeConnectedCutEdges`, the mathematical term) |
| `hasBridges` | NetworkX `has_bridges` | — |
| `articulationPoints()` | NetworkX `articulation_points`, Boost `articulation_points`, igraph `igraph_articulation_points`, petgraph `articulation_points`, rustworkx | "cutpoints" (JGraphT `getCutpoints`), "cut nodes" (LEMON), "cut vertices" (the mathematical term, and the README's module row, which should change) |
| `biconnectedComponents()`, `BiconnectedComponents` | Boost `biconnected_components`, NetworkX `biconnected_components` / `biconnected_component_edges`, igraph `igraph_biconnected_components`, rustworkx | "blocks" (JGraphT `getBlocks`, the mathematical term) is used in documentation and in `BlockCutTree` |
| `isBiconnected` | NetworkX `is_biconnected`, JGraphT `isBiconnected`, igraph `igraph_is_biconnected` | LEMON `biNodeConnected` |
| `biEdgeConnectedComponents()`, `isBiEdgeConnected` | LEMON `biEdgeConnectedComponents`, `biEdgeConnected` | NetworkX `bridge_components` (in `connectivity.edge_kcomponents`, not top level; reads as "the components of the bridges"), `k_edge_components(G, k=2)` (the general k belongs to Flows), "2-edge-connected" (cannot start a Swift identifier). It pairs with `biconnectedComponents()` the way LEMON's two names pair |
| `blockCutTree()`, `BlockCutTree` | JGraphT `BlockCutpointGraph` ("also known as a block-cut tree" in its documentation); the term in the literature (Harary) | `BlockCutpointGraph`: ours is not a `Graph` conformer, and it is a tree per component |
| `component(ofEdgeAt:)` | the `…EdgeAt` of `Graph.oppositeVertex(to:acrossEdgeAt:)` | — |
| `components(containing:)` | JGraphT `getBlocks(vertex)` | — |
| `node(of:)` | JGraphT `BlockCutpointGraph.getBlock(vertex)` (the cut point's own node, else its block) | — |

Terminology rows for the README:

| Concept | Name in Grafluent | Used by | Mathematical term |
|---|---|---|---|
| Edge whose removal adds a component | bridge, `bridges()` | NetworkX, JGraphT, igraph, petgraph | cut edge, isthmus |
| Vertex whose removal adds a component | articulation point, `articulationPoints()` | NetworkX, Boost, igraph, petgraph | cut vertex |
| Maximal biconnected subgraph | biconnected component, `biconnectedComponents()` | NetworkX, Boost, igraph | block |
| Maximal set joined by two edge-disjoint paths | bi-edge-connected component, `biEdgeConnectedComponents()` | LEMON (NetworkX: bridge component) | 2-edge-connected component |

## Result types

### Connected and 2-edge-connected components: `Components<DirectedView<Self>>`

Both are vertex partitions, which is exactly what `Components` is: a `RandomAccessCollection` of
vertex slices with an O(1) `component(of:)` that uses the graph's own vertex indices. `Components`
is generic over a `DirectedGraph`; `DirectedView<Self>` has the same vertices and forwards
`vertexIndexBound`, `vertexIndex(of:)` and `vertex(atIndex:)`, so the result keeps an O(1) copy of
`self.directed` and looks vertices up exactly as the directed results do. Precedent: the `Graph`
overloads in ShortestPaths return `ShortestPathTree<DirectedView<Self>, W>`.

- `connectedComponents() == directed.weaklyConnectedComponents()`, order included (CN-360,
  CN-398). The implementation is its own loop over the undirected rows (each edge once, not as
  two arcs), but the value is identical, so users can move between them.
- Rejected: a new `UndirectedComponents<G: Graph>` (a second type with the same API), and making
  `Components` generic over a lookup protocol both protocols refine (a public generic parameter
  cannot be constrained by a package protocol, and a public one would be invented vocabulary).
  The cost of reuse is a type name that mentions `DirectedView`; a `typealias` is not worth adding.

### Blocks: `BiconnectedComponents<G>`, a collection of edge sets

Blocks share vertices, so the only partition is of the edges: Boost (`ComponentMap` on edges),
LEMON (`biNodeConnectedComponents` fills an edge map) and igraph (`component_edges`) all make the
edge partition primary, and NetworkX offers it as `biconnected_component_edges`. So `Element` is
`ArraySlice<G.Edges.Index>` (positions, which tell parallel edges apart); the vertex sets that
NetworkX's `biconnected_components` returns are `vertices(ofComponentAt:)`.

- The slices keep the indices of the flat storage, as `Components` (CN-44): use `first`, iteration
  or `Array(_:)`.
- It holds a copy of the graph, as `Components` does, so `component(ofEdgeAt:)` and
  `components(containing:)` use `edgeIndex(of:)` and `vertexIndex(of:)` instead of hashing. Without
  edge indices it keeps a `[G.Edges.Index: Int]` (positions are `Hashable` by the protocol).
- `components(containing: v)`: one block for a vertex that is not an articulation point and has a
  non-loop edge; two or more for an articulation point; none for an isolated vertex or one whose
  only edges are self-loops. Stored per vertex number, total size Σ|V(B)| = n − c + #blocks.
- `==` compares the blocks' edges and vertex lists in order, not the graph.

### `BlockCutTree<G>`

The forest with a node per block and per articulation point, and an edge between a block and
each articulation point it contains (JGraphT `BlockCutpointGraph`; Harary's block-cutpoint tree).
Nodes are numbered: blocks are `0..<blocks.count` in `blocks` order, articulation points are
`0..<articulationPoints.count` in `vertices` order. Adjacency is two CSR slices:
`articulationPoints(ofBlock:)` and `blocks(ofArticulationPoint:)`, each ascending, so every tree
edge is listed once from each side, and `edgeCount` is their common total.

- It is a forest: one tree per connected component that has a non-loop edge. An isolated vertex
  is no node (it is in no block), and JGraphT's own test law, "the block–cut graph has as many
  components as the graph", silently assumes there is none (CN-358 states the corrected law).
- Not a `Graph` conformer: its node type would be an enum, and nothing in the library needs to
  traverse it yet. When `Trees` exists, it can offer a `Forest` view. Not a `CompressedSparseRow`
  either (CSR is directed-only and has no `.undirected`).
- `node(of: v)` is `.articulationPoint(i)` for an articulation point, `.block(b)` for a vertex in
  exactly one block, and `nil` for a vertex in none. Path questions ("which articulation points
  separate u and v") are a walk between `node(of: u)` and `node(of: v)`.

## Conventions

| Question | Choice | Libraries |
|---|---|---|
| Empty graph | Not connected, not biconnected, not bi-edge-connected; no components, bridges, points or blocks (CN-200) | igraph (since 0.9), JGraphT; NetworkX raises `NetworkXPointlessConcept` for `is_connected`; LEMON says connected, bi-node- and bi-edge-connected. Grafluent's directed half already says "not connected", so `isConnected == (connectedComponents().count == 1)` for every graph |
| K₁ | Connected; not biconnected; not bi-edge-connected; no block; one 2-edge-connected component (CN-201) | NetworkX, igraph, JGraphT: not biconnected; NetworkX `is_k_edge_connected(K₁, 2)` false. LEMON: biNodeConnected and biEdgeConnected |
| K₂ | Biconnected (one block, one edge); not bi-edge-connected; its edge is a bridge (CN-203) | All five agree on biconnected; igraph notes "some authors" disagree |
| Isolated vertices | Their own connected and 2-edge-connected component; **in no block**, so not a block–cut tree node; a graph with one block and an isolated vertex is not biconnected (CN-269, CN-330) | NetworkX, Boost, igraph (documented), LEMON (counts 0 blocks for K₁), JGraphT (no block is built when the edge stack is empty), rustworkx: all agree |
| Parallel edges | Edges with identity: a parallel pair is never a bridge, and both copies are in the same block. A bundle of parallel edges between two vertices with no other edges is one block on two vertices, biconnected and bi-edge-connected (CN-281). They never change articulation points (CN-361) | igraph and LEMON (bi-edge) track the incoming edge, as here. NetworkX `bridges` collapses to a simple graph and drops multi-edges afterwards; JGraphT post-filters bridges by multiplicity; **rustworkx reports both copies of a doubled edge as bridges**; **Boost never labels the parallel copy of a tree edge** (probe: `0-1 0-1` gives labels `0, unset`); NetworkX's block functions see only the collapsed graph |
| Self-loops | Never a bridge; never make (or unmake) an articulation point; **in no block**: `component(ofEdgeAt:)` is `nil`, and the blocks partition the non-loop edges. A vertex whose only edges are loops is in no block (CN-280, CN-284 – CN-289) | igraph: in no block (`component_edges` keeps `nei < vert`). **LEMON: a loop is a block of its own and its vertex a cut node** (probe: `0-0 0-1` gives 2 blocks, 1 cut node, not biNodeConnected; a lone loop is "1 cut node"), Bondy–Murty's "separating vertex". NetworkX and rustworkx: in the block of the tree edge that entered the vertex, so search-dependent. JGraphT: blocks are induced subgraphs, so the loop is in every block at its vertex. Boost: labelled with the next block popped, or never labelled at a search root (probe). The choice here is the only one that is search-independent and keeps "every block is biconnected" and "articulation point ⇔ in two blocks" true |
| `.undirected` on a digraph | Each arc is an edge, so opposite arcs are parallel and never bridges (CN-296). For NetworkX's `to_undirected` reading (opposite arcs merged), build an `UndirectedAdjacencyList`, which collapses repeats | JGraphT `AsUndirectedGraph` keeps both, as here |
| `isBiconnected` | n ≥ 2, connected, no articulation point. Not `biconnectedComponents().count == 1`, which isolated vertices break (igraph says the same) | NetworkX, igraph, JGraphT |
| `isBiEdgeConnected` | n ≥ 2, connected, no bridge: λ(G) ≥ 2. So a doubled K₂ is, K₂ and K₁ are not. A bowtie is bi-edge-connected but not biconnected (CN-305); a biconnected graph is bi-edge-connected unless it is a K₂ (CN-369) | NetworkX `is_k_edge_connected(G, 2)`; LEMON says K₁ is |

## Orders, and what they cost

Every order is canonical: it depends on `vertices` order and edge positions only, never on the
search, so tests pin values exactly on every representation and the reference needs no search.

| Result | Order | Cost of promising it |
|---|---|---|
| `connectedComponents()`, `biEdgeConnectedComponents()` | By first vertex in `vertices` order, members in `vertices` order (as `weaklyConnectedComponents()`) | A breadth-first labelling in vertex order gives it directly; the 2-edge-connected labels are relabelled in one O(n) pass |
| `bridges()` | Ascending position (NetworkX lists them in `edges()` order too) | With edge indices, a bit per edge index scanned in order (by the edge-order law that is position order); without, sorting the ≤ n − 1 bridges by `Edges.Index` (`Comparable` as a `Collection.Index`) |
| `articulationPoints()` | `vertices` order (NetworkX, Boost: search finish order; petgraph: a `HashSet`) | A bit per vertex scanned in order: free |
| Blocks | By their smallest edge position; each block's edges ascending; its vertices in `vertices` order | One pass over the edge labels in edge-index order, numbering blocks as first met, then a counting sort: O(m), no comparison sort. Without edge indices, one pass over `edges.indices` with a dictionary lookup each. The search's completion order (Boost, NetworkX, igraph) is not offered: it differs between libraries and from ours on CN-319, and nothing needs it |
| Block–cut tree adjacency | Ascending on both sides | The same counting sort |

## Algorithm

One iterative depth-first search (Hopcroft and Tarjan 1973; Tarjan 1972 for the low points;
Tarjan 1974 for bridges) computes bridges, articulation points, blocks and 2-edge-connected
components; each entry point keeps only the state it needs. No recursion anywhere: a 10⁵-deep path
(CN-370) and a 10⁶-deep one (benchmarks) run in an explicit frame stack. JGraphT's
`BiconnectivityInspector` is recursive and overflows on long paths.

**Skip the parent edge, not the parent vertex.** When the search scans `v`'s incident edges, it
skips exactly one end: the one whose edge is `parentEdge[v]`, the tree edge it arrived by. A
parallel copy of that edge is a different edge, so it is seen as a back edge to the parent, lowers
`low[v]` to `disc[parent]`, and so the tree edge is not a bridge and the copy goes into the block.
Skipping the parent *vertex* (Boost, NetworkX's `_biconnected_dfs`, petgraph, rustworkx, JGraphT)
is harmless for articulation points but wrong for bridges and for edge blocks in multigraphs; ref.py
plants it and 27 catalog rows fail (CN-217 – CN-219, CN-222, CN-223, CN-244, CN-281, CN-291, CN-292, …).

```
for root in vertex numbers 0..<n where disc[root] == unvisited:
    disc[root] = low[root] = t; t += 1; push frame (root, its incident row)
    while let top = frames.last:
        if let (w, e) = next (neighbor, edge) of top.v:     // zip(neighborIndices, incidentEdgeIndices)
            if w == v { continue }                           // a self-loop: nothing, ever
            if e == parentEdge[v] { continue }               // the one end we came in by
            if disc[w] == unvisited:                         // tree edge
                parentEdge[w] = e; disc[w] = low[w] = t; t += 1
                edgeStack.push(e); vertexStack.push(w); push frame (w, …)
                if v == root { rootChildren += 1 }
            else if disc[w] < disc[v]:                       // back edge, seen from its lower end
                edgeStack.push(e); low[v] = min(low[v], disc[w])
            // disc[w] > disc[v]: the same back edge seen from its upper end; already counted
        else:
            pop; guard let p = frames.last?.v else break
            low[p] = min(low[p], low[v])
            if low[v] > disc[p]: parentEdge[v] is a bridge;
                                 pop vertexStack through v → one 2-edge-connected component
            if low[v] >= disc[p]: if p != root, p is an articulation point;
                                  pop edgeStack through parentEdge[v] → one block
    if rootChildren >= 2 { root is an articulation point }
    the rest of vertexStack → the root's 2-edge-connected component
```

A back edge is pushed exactly once, from its lower end, so no edge needs a "seen" mark; a
self-loop is never pushed, which is the "in no block" convention for free.

**Index space.** With vertex indices (every representation but plain conformers), the state is
arrays by vertex index: `disc`, `low`, `parentEdge`, an articulation bit, and the frame stack of
`(v, Zip2Sequence<NeighborIndices, IncidentEdgeIndices>.Iterator)`. With edge indices too
(`UndirectedAdjacencyList`, `ReferencePseudograph`, `AdjacencyList.undirected`), `parentEdge`,
the edge stack, bridge bits and block labels are `Int` edge indices, so nothing is hashed and
results map back to positions through one `positions[edgeIndex]` array gathered from the rows
(as SpanningTrees' `_rankedEdges` does). With vertex indices only (`AdjacencyMatrix.undirected`,
whose positions are cells), the rows are `neighborIndices(ofIndex:)` zipped with
`incidentEdges(ofIndex:)`: `parentEdge` holds positions (`Edges.Index?`), compared with `==`,
and block labels go in a `[Edges.Index: Int]`. Without vertex indices, vertices are numbered by
one pass over `vertices` into a dictionary (as `_DenseVertices`), and each neighbor is looked up
once per edge end. Edge indices are therefore an optimization for marking and labelling, not a
requirement: parent-edge identity only needs position equality, which the protocol guarantees
("an edge's position in `edges` is its identity").

A package hook giving integer row cursors (`_withIncidentIndexRows`, the undirected
`_withSuccessorIndexRows`) is a benchmark question (CN-B13), not part of the API.

**Early exits.** `hasBridges` and `isBiEdgeConnected` stop at the first bridge (a bridge is known
as soon as its lower end finishes); `isBiconnected` stops at the first articulation point, or when
the root gets a second child, and checks that the first search reached every vertex;
`isConnected` stops once n − 1 unions succeed (union–find, as `isWeaklyConnected`) or a search from
the first vertex reaches n vertices.

**Connected components** are a breadth-first labelling (or union–find over the rows, as
`weaklyConnectedComponents()`; CN-B11 decides) and never run the full search.

## Complexity

| Entry point | Time | Extra space |
|---|---|---|
| `connectedComponents()`, `isConnected` | O(n + m) | O(n) |
| `bridges()`, `hasBridges`, `articulationPoints()`, `isBiconnected`, `isBiEdgeConnected` | O(n + m) | O(n) (no edge stack) |
| `biconnectedComponents()`, `blockCutTree()` | O(n + m) | O(n + m) (edge stack, labels, per-vertex block lists) |
| `biEdgeConnectedComponents()` | O(n + m) | O(n) |
| `component(ofEdgeAt:)` | O(1) after `edgeIndex(of:)`; one hash without edge indices | — |
| `components(containing:)`, `node(of:)` | O(1) after `vertexIndex(of:)`; one hash without vertex indices | — |

On an indexed graph no entry point hashes a vertex (CN-395); queries hash only their argument, and
only on a representation whose `vertexIndex(of:)` hashes.

## Files

`Sources/Connectivity/ConnectedComponents.swift` (`connectedComponents`, `isConnected`),
`Biconnectivity.swift` (the search, `bridges`, `hasBridges`, `articulationPoints`,
`isBiconnected`, `biEdgeConnectedComponents`, `isBiEdgeConnected`),
`BiconnectedComponents.swift`, `BlockCutTree.swift`. No new module dependencies. The module row
in the README becomes: "… dominators; on `Graph`: connected components, bridges, articulation
points, biconnected and bi-edge-connected components, the block–cut tree", with "vertex and edge
connectivity" moved to Flows.

Test files, by catalog section: `ConnectedComponentsTests.swift` (§A, §G), `BridgesTests.swift`
(§B), `BlocksTests.swift` (§C, §E, §F), `UndirectedMultigraphTests.swift` (§D),
`UndirectedRepresentationTests.swift` (§H), `UndirectedPropertyTests.swift` (§I),
`UndirectedStressTests.swift` (§J), `UndirectedConformanceTests.swift` (§K).
