# Walks test suite

`Walks` is vocabulary: `Walk`, `Trail`, `Path`, `Circuit` and `Cycle`, each generic over
`Vertex: Hashable` and `Edge: Hashable` (the graph's `Edges.Index`, the edge position), each
storing its vertices and the positions of the edges between them. An open walk (Walk, Trail, Path)
stores `length + 1` vertices; a closed one (Circuit, Cycle) stores `length` vertices without a
repeated start, edge `i` joining vertex `i` and vertex `(i + 1) % count`. The invariants are
enforced by construction. The tests were written before the implementation, from the proposed API
(`api.md`). The suite uses only the public API and is self-contained per test; shared material is
the `ReferenceDirectedMultigraph` and `ReferencePseudograph` test conformers, `MinimalSequence`,
`LifetimeTracked` and the seeded generator in `GrafluentTestSupport`.

## API under test

```swift
struct Walk<Vertex: Hashable, Edge: Hashable>      // also Trail, Path: RandomAccessCollection of Vertex, Index == Int
    init(vertex: Vertex)                            // the trivial walk
    init?(vertices: [Vertex], edges: [Edge])        // intrinsic check; wrong count shape traps
    init?<G: DirectedGraph>(vertices:edges:in: G)   // plus graph validity; never traps on counts or missing vertices
    init?<G: Graph>(vertices:edges:in: G)
    init?<G: DirectedGraph>(_ vertices: some Sequence<Vertex>, in: G)   // picks edges in outEdges order
    init?<G: Graph>(_ vertices: some Sequence<Vertex>, in: G)           // picks edges in incidentEdges order
    var vertices: [Vertex], edges: [Edge], length: Int
    var source: Vertex, target: Vertex, isTrivial: Bool
    var isClosed: Bool                              // Walk and Trail
    func reversed() -> Self
    func weight<W: AdditiveArithmetic, E: Error>(_: (Edge) throws(E) -> W) throws(E) -> W
    func appending(_: Walk) -> Walk                 // Walk only; precondition target == other.source
    mutating func append(_: Walk)
struct Circuit<Vertex, Edge>                        // also Cycle: RandomAccessCollection, count == length >= 1
    init?(vertices:edges:), init?(vertices:edges:in:), init?(_:in:)     // cyclic lists, no repeated start
    var vertices, edges, length; func reversed() -> Self; func weight(_:)

// Conversions, as initializers
Trail(_: Path), Walk(_: Trail), Walk(_: Path), Circuit(_: Cycle)                         // total
Walk(_: Circuit), Walk(_: Cycle), Trail(_: Circuit), Trail(_: Cycle)                      // total, start repeated
Trail?(_: Walk), Path?(_: Walk), Path?(_: Trail), Circuit?(_: Walk), Circuit?(_: Trail),
Cycle?(_: Walk), Cycle?(_: Trail), Cycle?(_: Circuit)                                     // failable

// Every type: Hashable; Codable and Sendable when Vertex and Edge are;
// CustomStringConvertible and CustomDebugStringConvertible
```

## Conventions

| Question | Choice | Why |
|---|---|---|
| Length | Counts edges; the trivial walk has length 0 and one vertex | West, Bondy & Murty, JGraphT `getLength`, LEMON `length()` |
| Empty walk | None: an empty vertex list is `nil` from every graph initializer, and a trap from the intrinsic one (WK-107, WK-127, WK-1302) | Swift has `Optional` for "no walk"; NetworkX's `is_path(G, [])` is True |
| Closed | `isClosed` is true for the trivial walk (West), but a circuit or cycle needs length ≥ 1 (Bondy & Murty, WK-213) | api.md |
| Self-loops and parallel edges | The positions are part of the value: walks over the same vertices through different parallel copies are unequal (WK-502, WK-507, WK-514); a loop is a 1-cycle, a parallel pair a 2-cycle, a single undirected edge is no 2-cycle (WK-215, WK-513, WK-605) | NetworkX `simple_cycles` lists vertices only and so merges them (WK-512) |
| Vertices-only initializers | Walk and Path take the first edge in `outEdges(of:)` / `incidentEdges(of:)` order; Trail, Circuit and Cycle the first unused one, which finds a trail exactly when one exists (WK-510) | api.md |
| Undirected orientation | The vertex sequence orients each edge; in `g.directed` the arc's `reversed` flag must match the step (WK-405, WK-604) | api.md |
| Equality | Exact for open walks (WK-712); up to rotation, never reflection, for circuits and cycles, with a rotation-invariant hash (WK-701 – WK-716) | api.md; JGraphT is exact, NetworkX compares undirected cycles up to reflection |
| `reversed()` | Open walks: both sequences reversed; circuits and cycles keep the start: `[v0] + v[1...].reversed()`, edges reversed. Over a digraph the result is a walk of the converse (WK-1002, WK-1010) | api.md |
| Weight | Sums the closure over the edges taken, in stored order, from `.zero`; typed throws rethrown (WK-906) | NetworkX's `path_weight` guesses the lightest parallel edge (WK-901) |
| Codable | `{"vertices": [...], "edges": [...]}` in the stored rotation; decoding re-validates and throws `DecodingError.dataCorrupted` (WK-1104) | api.md |
| Description | `description` as `Array`'s, at most 16 vertices then `…`; `debugDescription` is `Type(vertices: [...], edges: [...])` | `GraphDescription`; WK-1107 extends the debug form to `Cycle` and `Walk` |

## How values are pinned

Every fixture is written inline in its test on the `ReferenceDirectedMultigraph` or
`ReferencePseudograph`, whose edge positions are list indices and whose out- and incident-edge
orders are position order, so every picked edge is exact. `AdjacencyList` and
`UndirectedAdjacencyList` stand in for NetworkX's simple `DiGraph` and `Graph` (WK-121 – WK-125);
`AdjacencyMatrix` and `CompressedSparseRow`, whose positions are not list indices, are checked by
the step law and by reading positions back from the graph (WK-401). Expected values come from the
catalog's reference (`ref.py`: a Python model of the types, brute force over every choice of
parallel edges and every rotation, checked against NetworkX 3.7) and are held as plain literals.
Randomized tests (seeded, `.randomized`) and the PropertyBased checks write their brute-force
oracles inside the test.

## Files

| File | Covers |
|---|---|
| `WalkConstructionTests.swift` | §1: the intrinsic, checked and vertices-only initializers; LEMON and JGraphT validity cases; NetworkX `is_path` agreement and disagreements; one-pass sequences |
| `WalkInvariantTests.swift` | §2: each type's invariant; figure eight, digon, 1-cycle; seeded brute force that paths have distinct edges and that only undirected 2-cycles repeat one |
| `WalkCollectionTests.swift` | §3: elements, indices, `first`/`last`, consecutive pairs, the RandomAccessCollection laws for every type |
| `WalkEdgeTests.swift` | §4: the step law on the reference graphs, `AdjacencyMatrix` and `CompressedSparseRow`; undirected orientation; `g.directed` arcs |
| `WalkMultigraphTests.swift` | §5: parallel edges and self-loops; first and first-unused picking; seeded brute force for WK-510 |
| `UndirectedWalkTests.swift` | §6: both directions of a triangle, no reflection, there-and-back, `g.directed` 2-cycles, NetworkX's cycle counts |
| `WalkEqualityTests.swift` | §7: rotation equality and hashing, figure-eight rotations, seeded brute force for WK-711, `Set` and `Dictionary` |
| `WalkConversionTests.swift` | §8: total and failable conversions, round trips |
| `WalkWeightTests.swift` | §9: weights of parallel edges, floating-point rotation, typed throws, JGraphT's reverse path |
| `WalkReversalTests.swift` | §10: reversal over `Graph`, `DirectedGraph` and `g.directed`, concatenation, `append` |
| `WalkCodableTests.swift` | §11: JSON shape, round trips, re-validation on decode, description and debugDescription, `Sendable`, lifetimes |
| `WalkPreconditionTests.swift` | §13: exit tests for the count shape, `appending` mismatches and subscripts past the end; positions out of range give `nil` (WK-1305) |
| `WalkReviewTests.swift` | §14: added after planting bugs: a path may not repeat an edge position, cycles of different lengths that start alike differ, cycles that differ only in their edges hash apart, every type's weight counts every edge |
| `WalkPropertyTests.swift` | PropertyBased checks that shrink: circuit and cycle equality and hashing under every rotation and perturbation; `Walk`/`Trail`/`Path(_:in:)` against brute force, directed and undirected |

## Case IDs

Case IDs (WK-101 … WK-1306) refer to the catalog (`cases.md`), harvested from JGraphT
(`GraphWalkTest`), LEMON (`path_test`), NetworkX (`test_ispath`, `test_pathweight`,
`simple_cycles`, `find_cycle`) and the graph-theory texts. Each test's name starts with its IDs.

| Cases | Section | File |
|---|---|---|
| WK-101 – WK-130 | 1. Construction and validation | `WalkConstructionTests.swift` (WK-112's trap inline as an exit test) |
| WK-201 – WK-215 | 2. Invariants per type | `WalkInvariantTests.swift` (WK-207 as an exit test) |
| WK-301 – WK-309 | 3. Collection behaviour | `WalkCollectionTests.swift` |
| WK-401 – WK-405 | 4. Edges and orientation | `WalkEdgeTests.swift` |
| WK-501 – WK-515 | 5. Multigraphs and self-loops | `WalkMultigraphTests.swift`; WK-510 also in `WalkPropertyTests.swift` |
| WK-601 – WK-607 | 6. Undirected graphs | `UndirectedWalkTests.swift` |
| WK-701 – WK-716 | 7. Equality and hashing | `WalkEqualityTests.swift`; WK-701 and WK-711 also in `WalkPropertyTests.swift` |
| WK-801 – WK-810 | 8. Conversions | `WalkConversionTests.swift` |
| WK-901 – WK-907 | 9. Weight | `WalkWeightTests.swift` |
| WK-1001 – WK-1010 | 10. Reversal and concatenation | `WalkReversalTests.swift` |
| WK-1101 – WK-1110 | 11. Codable, description, Sendable | `WalkCodableTests.swift` |
| WK-1201 – WK-1215 | 12. Migration of existing APIs | not tested here: the `ShortestPaths` and `Traversal` results become walk types in their own suites |
| WK-1301 – WK-1306 | 13. Preconditions | `WalkPreconditionTests.swift` |
| WK-1401 – WK-1404 | 14. Review cases | `WalkReviewTests.swift` |

## Not tested

| Case | Why |
|---|---|
| WK-1201 – WK-1215 | The migration of `ShortestPathTree.path(to:)`, `dijkstraShortestPath`, `findNegativeCycle`, `findCycle` and `bidirectionalShortestPath` to walk types is tested in `ShortestPathsTests` and `TraversalTests`; this target does not depend on those modules |
| WK-306's swift-algorithms `adjacentPairs()` | `Algorithms` is not a dependency of this target; the same pairs are checked with `zip(w, w.dropFirst())` |
| WK-1008's "append does not copy a uniquely referenced buffer" | A performance property, for the benchmarks; the result equality is tested |
| WK-1109's negative half (`Walk<NonSendableVertex, Int>` is not `Sendable`) | Not building is not expressible as a test; the positive half is tested |
| The `package` unchecked initializer (`init(_uncheckedVertices:edges:)`) | Not public API |
