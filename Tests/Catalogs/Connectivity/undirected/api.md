# Connectivity, undirected half: API

Connected components of an undirected `Graph`, bridges, articulation points, biconnected
components (blocks), bi-edge-connected (2-edge-connected) components, the block–cut tree, and the
predicates `isConnected`, `hasBridges`, `isBiconnected` and `isBiEdgeConnected`. Everything is on
`Graph`; `DirectedGraph` has `weaklyConnectedComponents()`. A bidirectional digraph reaches all of
it through `.undirectedView`. Vertex and edge connectivity, minimum cuts and Gomory–Hu trees are in
Flows.

## Public API

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
    func component(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> Int?
    func components(checkedContaining vertex: G.Vertex) throws(VertexNotFound) -> ArraySlice<Int>

@frozen
struct BlockCutTree<G: Graph>
        // Equatable; Sendable as above
    let blocks: BiconnectedComponents<G>
    let articulationPoints: [G.Vertex]                            // vertices order
    func articulationPoints(ofBlock block: Int) -> ArraySlice<Int>       // indices into articulationPoints, ascending
    func blocks(ofArticulationPoint point: Int) -> ArraySlice<Int>       // block positions, ascending
    func node(of vertex: G.Vertex) -> Node?
    func node(checked vertex: G.Vertex) throws(VertexNotFound) -> Node?
    var edgeCount: Int
    @frozen enum Node: Hashable, Sendable { case block(Int), articulationPoint(Int) }
```

## Result types

### Connected and 2-edge-connected components: `Components<DirectedView<Self>>`

Both are vertex partitions, so they use `Components`: a `RandomAccessCollection` of vertex slices
with an O(1) `component(of:)` that uses the graph's own vertex indices. `DirectedView<Self>` has the
same vertices and forwards the vertex indices, so the result keeps an O(1) copy of
`self.directedView` and looks vertices up as the directed results do.

`connectedComponents() == directedView.weaklyConnectedComponents()`, order included (CN-360,
CN-398).

### Blocks: `BiconnectedComponents<G>`, a collection of edge sets

Blocks share vertices, so the partition is of the edges. `Element` is `ArraySlice<G.Edges.Index>`
(positions, which tell parallel edges apart); a block's vertices are `vertices(ofComponentAt:)`.

- The slices keep the indices of the flat storage, as `Components` (CN-44): use `first`, iteration
  or `Array(_:)`.
- It holds a copy of the graph, so `component(ofEdgeAt:)` and `components(containing:)` use
  `edgeIndex(of:)` and `vertexIndex(of:)`. Without edge indices it keeps a
  `[G.Edges.Index: Int]`.
- `components(containing: v)`: one block for a vertex that is not an articulation point and has a
  non-loop edge; two or more for an articulation point; none for an isolated vertex or one whose
  only edges are self-loops.
- `==` compares the blocks' edges and vertex lists in order, not the graph.

### `BlockCutTree<G>`

The forest with a node per block and per articulation point, and an edge between a block and each
articulation point it contains (Harary's block-cutpoint tree). Blocks are `0..<blocks.count` in
`blocks` order; articulation points are `0..<articulationPoints.count` in `vertices` order.
`articulationPoints(ofBlock:)` and `blocks(ofArticulationPoint:)` are each ascending, so every tree
edge is listed once from each side, and `edgeCount` is their common total.

- It is a forest: one tree per connected component that has a non-loop edge. An isolated vertex is
  no node (it is in no block), so the forest can have fewer trees than the graph has components
  (CN-358).
- `node(of: v)` is `.articulationPoint(i)` for an articulation point, `.block(b)` for a vertex in
  exactly one block, and `nil` for a vertex in none.

## Conventions

| Question | Rule |
|---|---|
| Empty graph | Not connected, not biconnected, not bi-edge-connected; no components, bridges, points or blocks (CN-200). So `isConnected == (connectedComponents().count == 1)` for every graph |
| K₁ | Connected; not biconnected; not bi-edge-connected; no block; one 2-edge-connected component (CN-201) |
| K₂ | Biconnected (one block, one edge); not bi-edge-connected; its edge is a bridge (CN-203) |
| Isolated vertices | Their own connected and 2-edge-connected component; in no block, so not a block–cut tree node; a graph with one block and an isolated vertex is not biconnected (CN-269, CN-330) |
| Parallel edges | Edges with identity: a parallel pair is never a bridge, and both copies are in the same block. A bundle of parallel edges between two vertices with no other edges is one block on two vertices, biconnected and bi-edge-connected (CN-281). They never change articulation points (CN-361) |
| Self-loops | Never a bridge; never make an articulation point; in no block, so `component(ofEdgeAt:)` is `nil` and the blocks partition the non-loop edges. A vertex whose only edges are loops is in no block (CN-280, CN-284 – CN-289). This keeps "every block is biconnected" and "articulation point ⇔ in two blocks" true, independent of the search |
| `.undirectedView` on a digraph | Each arc is an edge, so opposite arcs are parallel and never bridges (CN-296). To merge opposite arcs, build an `UndirectedAdjacencyList`, which collapses repeats |
| `isBiconnected` | n ≥ 2, connected, no articulation point. Not `biconnectedComponents().count == 1`, which isolated vertices break |
| `isBiEdgeConnected` | n ≥ 2, connected, no bridge: λ(G) ≥ 2. So a doubled K₂ is, K₂ and K₁ are not. A bowtie is bi-edge-connected but not biconnected (CN-305); a biconnected graph is bi-edge-connected unless it is a K₂ (CN-369) |

## Orders

Every order depends on `vertices` order and edge positions only, never on the search, so tests pin
values exactly on every representation.

| Result | Order |
|---|---|
| `connectedComponents()`, `biEdgeConnectedComponents()` | By first vertex in `vertices` order, members in `vertices` order (as `weaklyConnectedComponents()`) |
| `bridges()` | Ascending position |
| `articulationPoints()` | `vertices` order |
| Blocks | By their smallest edge position; each block's edges ascending; its vertices in `vertices` order |
| Block–cut tree adjacency | Ascending on both sides |

## Algorithm

One iterative depth-first search (Hopcroft and Tarjan 1973; Tarjan 1972 for the low points;
Tarjan 1974 for bridges) computes bridges, articulation points, blocks and 2-edge-connected
components; each entry point keeps only the state it needs. It keeps an explicit frame stack, so a
10⁵-deep path (CN-370) runs inside a `Task`.

The search skips the parent edge, not the parent vertex. When it scans `v`'s incident edges, it
skips exactly the end whose edge is the tree edge it arrived by. A parallel copy of that edge is a
different edge, so it is a back edge to the parent: it lowers `low[v]` to `disc[parent]`, the tree
edge is not a bridge, and the copy goes into the block. Skipping the parent vertex instead is wrong
for bridges and edge blocks in multigraphs; ref.py plants that mistake and 27 catalog rows fail
(CN-217 – CN-219, CN-222, CN-223, CN-244, CN-281, CN-291, CN-292, …).

```
for root in vertex numbers 0..<n where disc[root] == unvisited:
    disc[root] = low[root] = t; t += 1; push frame (root, its incident row)
    while let top = frames.last:
        if let (w, e) = next (neighbor, edge) of top.v:
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

A back edge is pushed exactly once, from its lower end, so no edge needs a "seen" mark; a self-loop
is never pushed, so it is in no block.

With vertex indices the state is arrays by vertex index. With edge indices too, parent edges, the
edge stack and labels are `Int` edge indices and nothing is hashed. With vertex indices only (for
example `AdjacencyMatrix.undirectedView`, whose positions are cells), parent edges are positions
compared with `==`, and block labels go in a `[Edges.Index: Int]`. Without vertex indices, vertices
are numbered by one pass over `vertices` into a dictionary, and each neighbor is looked up once per
edge end.

`hasBridges` and `isBiEdgeConnected` stop at the first bridge; `isBiconnected` stops at the first
articulation point and checks that the first search reached every vertex; `isConnected` stops once
n − 1 unions succeed.

Connected components are union–find over the rows and never run the full search.

## Complexity

| Entry point | Time | Extra space |
|---|---|---|
| `connectedComponents()`, `isConnected` | O(n + m α(n)) | O(n) |
| `bridges()`, `hasBridges`, `articulationPoints()`, `isBiconnected`, `isBiEdgeConnected` | O(n + m) | O(n) (no edge stack) |
| `biconnectedComponents()`, `blockCutTree()` | O(n + m) | O(n + m) (edge stack, labels, per-vertex block lists) |
| `biEdgeConnectedComponents()` | O(n + m) | O(n) |
| `component(ofEdgeAt:)` | O(1) after `edgeIndex(of:)`; one hash without edge indices | — |
| `components(containing:)`, `node(of:)` | O(1) after `vertexIndex(of:)`; one hash without vertex indices | — |

On an indexed graph no entry point hashes a vertex (CN-395); queries hash only their argument, and
only on a representation whose `vertexIndex(of:)` hashes.
